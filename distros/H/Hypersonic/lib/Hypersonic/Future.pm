package Hypersonic::Future;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

# High-performance JIT-compiled Future for async operations
# Serves as the foundation for all async in Hypersonic:
# - DB operations (thread pool)
# - HTTP client (UA::Async)
# - Timers, file I/O, etc.

use XS::JIT::Builder;
use Hypersonic::JIT::Util;

# Future states
use constant {
    STATE_PENDING   => 0,
    STATE_DONE      => 1,
    STATE_FAILED    => 2,
    STATE_CANCELLED => 3,
};

# Callback types (bitmask)
use constant {
    CB_DONE   => 1,
    CB_FAIL   => 2,
    CB_CANCEL => 4,
    CB_READY  => 7,  # CB_DONE | CB_FAIL | CB_CANCEL
};

# Object slots (array-based for performance)
use constant {
    SLOT_ID       => 0,
    SLOT_STATE    => 1,
    SLOT_RESULT   => 2,
    SLOT_FAILURE  => 3,
    SLOT_LABEL    => 4,
};

# Configuration
use constant {
    MAX_FUTURES            => 65536,
    MAX_CALLBACKS          => 16,
    MAX_SUBFUTURES         => 256,
    THREADPOOL_SIZE        => 8,
    THREADPOOL_QUEUE_SIZE  => 4096,
};

# Export constants
use Exporter 'import';
our @EXPORT_OK = qw(
    STATE_PENDING STATE_DONE STATE_FAILED STATE_CANCELLED
    CB_DONE CB_FAIL CB_CANCEL CB_READY
    SLOT_ID SLOT_STATE SLOT_RESULT SLOT_FAILURE SLOT_LABEL
    MAX_FUTURES MAX_CALLBACKS MAX_SUBFUTURES
);

# JIT compilation state - our so submodules can check
our $COMPILED = 0;
my $MODULE_NAME;

#############################################################################
# XS Function Registry
#############################################################################

sub get_xs_functions {
    return {
        # Lifecycle - direct method binding (no Perl wrappers)
        'Hypersonic::Future::_new'        => { source => 'xs_future_new', is_xs_native => 1 },
        'Hypersonic::Future::_new_done'   => { source => 'xs_future_new_done', is_xs_native => 1 },
        'Hypersonic::Future::_new_fail'   => { source => 'xs_future_new_fail', is_xs_native => 1 },
        'Hypersonic::Future::done'        => { source => 'xs_future_done', is_xs_native => 1 },
        'Hypersonic::Future::fail'        => { source => 'xs_future_fail', is_xs_native => 1 },
        'Hypersonic::Future::cancel'      => { source => 'xs_future_cancel', is_xs_native => 1 },

        # State inspection - direct XS, custom ops registered for compile-time optimization
        'Hypersonic::Future::is_ready'    => { source => 'xs_future_is_ready', is_xs_native => 1 },
        'Hypersonic::Future::is_done'     => { source => 'xs_future_is_done', is_xs_native => 1 },
        'Hypersonic::Future::is_failed'   => { source => 'xs_future_is_failed', is_xs_native => 1 },
        'Hypersonic::Future::is_cancelled'=> { source => 'xs_future_is_cancelled', is_xs_native => 1 },

        # Result access - direct XS
        'Hypersonic::Future::result'      => { source => 'xs_future_result', is_xs_native => 1 },
        'Hypersonic::Future::failure'     => { source => 'xs_future_failure', is_xs_native => 1 },

        # Callbacks - direct XS
        'Hypersonic::Future::on_ready'    => { source => 'xs_future_on_ready', is_xs_native => 1 },
        'Hypersonic::Future::on_done'     => { source => 'xs_future_on_done', is_xs_native => 1 },
        'Hypersonic::Future::on_fail'     => { source => 'xs_future_on_fail', is_xs_native => 1 },
        'Hypersonic::Future::on_cancel'   => { source => 'xs_future_on_cancel', is_xs_native => 1 },

        # Sequencing - direct XS
        'Hypersonic::Future::then'        => { source => 'xs_future_then', is_xs_native => 1 },
        'Hypersonic::Future::catch'       => { source => 'xs_future_catch', is_xs_native => 1 },
        'Hypersonic::Future::finally'     => { source => 'xs_future_finally', is_xs_native => 1 },

        # Convergent - direct XS
        'Hypersonic::Future::needs_all'   => { source => 'xs_future_needs_all', is_xs_native => 1 },
        'Hypersonic::Future::needs_any'   => { source => 'xs_future_needs_any', is_xs_native => 1 },
        'Hypersonic::Future::wait_all'    => { source => 'xs_future_wait_all', is_xs_native => 1 },
        'Hypersonic::Future::wait_any'    => { source => 'xs_future_wait_any', is_xs_native => 1 },

        # Thread pool - direct XS
        'Hypersonic::Future::submit'      => { source => 'xs_future_submit', is_xs_native => 1 },
        'Hypersonic::Future::poll'        => { source => 'xs_future_poll', is_xs_native => 1 },

        # Notification - direct XS
        'Hypersonic::Future::get_notify_fd'  => { source => 'xs_future_get_notify_fd', is_xs_native => 1 },
        'Hypersonic::Future::process_ready'  => { source => 'xs_future_process_ready', is_xs_native => 1 },

        # Cleanup
        'Hypersonic::Future::DESTROY'     => { source => 'xs_future_destroy', is_xs_native => 1 },

        # Custom op registration
        'Hypersonic::Future::_register_ops' => { source => 'xs_register_custom_ops', is_xs_native => 1 },
    };
}

#############################################################################
# C Code Generation - Main Entry Point
#############################################################################

sub generate_c_code {
    my ($class, $builder, $opts) = @_;

    $opts //= {};
    my $max_futures = $opts->{max_futures} // MAX_FUTURES;
    my $max_callbacks = $opts->{max_callbacks} // MAX_CALLBACKS;
    my $inline = Hypersonic::JIT::Util->inline_keyword;

    # PERL_VERSION_* macros are already provided by XS::JIT preamble
    # No need to emit them here

    # System includes via centralized utility
    Hypersonic::JIT::Util->add_standard_includes($builder,
        qw(unistd fcntl threading eventfd));

    # Defines
    $builder->line("#define MAX_FUTURES $max_futures")
            ->line("#define MAX_CALLBACKS $max_callbacks")
            ->blank
            ->line('#define FUTURE_STATE_PENDING   0')
            ->line('#define FUTURE_STATE_DONE      1')
            ->line('#define FUTURE_STATE_FAILED    2')
            ->line('#define FUTURE_STATE_CANCELLED 3')
            ->blank
            ->line('#define FUTURE_CB_DONE   1')
            ->line('#define FUTURE_CB_FAIL   2')
            ->line('#define FUTURE_CB_CANCEL 4')
            ->line('#define FUTURE_CB_READY  7')
            ->blank;

    # Callback struct
    $builder->line('typedef struct FutureCallback {')
            ->line('    int type;')
            ->line('    SV *code;')
            ->line('    int target_slot;')
            ->line('} FutureCallback;')
            ->blank;

    # FutureContext struct
    $builder->line('typedef struct FutureContext {')
            ->line('    int state;')
            ->line('    int in_use;')
            ->line('    int refcount;')
            ->line('    SV **result_values;')
            ->line('    int result_count;')
            ->line('    char *fail_message;')
            ->line('    char *fail_category;')
            ->line('    FutureCallback callbacks[MAX_CALLBACKS];')
            ->line('    int callback_count;')
            ->line('    int cancel_target;')
            ->line('    /* For convergent futures */')
            ->line('    int *subfuture_slots;')
            ->line('    int subfuture_count;')
            ->line('    int subfutures_pending;')
            ->line('    int convergent_mode;  /* 0=none, 1=needs_all, 2=needs_any */')
            ->line('} FutureContext;')
            ->blank;

    # Registry
    $builder->line('static FutureContext future_registry[MAX_FUTURES];')
            ->line('static int future_freelist[MAX_FUTURES];')
            ->line('static int future_freelist_count = 0;')
            ->line('static int future_freelist_initialized = 0;')
            ->blank;

    # Helper functions
    $class->_gen_helpers($builder);

    # XS functions
    $class->_gen_xs_functions($builder);

    # Custom ops for zero-overhead method calls
    $class->_gen_custom_ops($builder);
}

sub _gen_custom_ops {
    my ($class, $builder) = @_;

    # Generate pp functions for custom ops
    # These bypass all Perl method dispatch overhead

    # pp_future_is_done - direct state check
    $builder->line('static OP* pp_future_is_done(pTHX) {')
            ->line('    dSP;')
            ->line('    SV* self = TOPs;')
            ->line('    int slot = SvIV(SvRV(self));')
            ->line('    SETs(boolSV(future_registry[slot].state == FUTURE_STATE_DONE));')
            ->line('    return NORMAL;')
            ->line('}')
            ->blank;

    # pp_future_is_ready
    $builder->line('static OP* pp_future_is_ready(pTHX) {')
            ->line('    dSP;')
            ->line('    SV* self = TOPs;')
            ->line('    int slot = SvIV(SvRV(self));')
            ->line('    SETs(boolSV(future_registry[slot].state != FUTURE_STATE_PENDING));')
            ->line('    return NORMAL;')
            ->line('}')
            ->blank;

    # pp_future_is_failed
    $builder->line('static OP* pp_future_is_failed(pTHX) {')
            ->line('    dSP;')
            ->line('    SV* self = TOPs;')
            ->line('    int slot = SvIV(SvRV(self));')
            ->line('    SETs(boolSV(future_registry[slot].state == FUTURE_STATE_FAILED));')
            ->line('    return NORMAL;')
            ->line('}')
            ->blank;

    # pp_future_is_cancelled
    $builder->line('static OP* pp_future_is_cancelled(pTHX) {')
            ->line('    dSP;')
            ->line('    SV* self = TOPs;')
            ->line('    int slot = SvIV(SvRV(self));')
            ->line('    SETs(boolSV(future_registry[slot].state == FUTURE_STATE_CANCELLED));')
            ->line('    return NORMAL;')
            ->line('}')
            ->blank;

    # XOP declarations
    $builder->xop_declare('future_is_done_xop', 'pp_future_is_done', 'future is_done')
            ->xop_declare('future_is_ready_xop', 'pp_future_is_ready', 'future is_ready')
            ->xop_declare('future_is_failed_xop', 'pp_future_is_failed', 'future is_failed')
            ->xop_declare('future_is_cancelled_xop', 'pp_future_is_cancelled', 'future is_cancelled')
            ->blank;

    # Call checkers
    $builder->ck_start('ck_future_is_done')
            ->ck_preamble
            ->ck_build_unop('pp_future_is_done', '0')
            ->ck_end;

    $builder->ck_start('ck_future_is_ready')
            ->ck_preamble
            ->ck_build_unop('pp_future_is_ready', '0')
            ->ck_end;

    $builder->ck_start('ck_future_is_failed')
            ->ck_preamble
            ->ck_build_unop('pp_future_is_failed', '0')
            ->ck_end;

    $builder->ck_start('ck_future_is_cancelled')
            ->ck_preamble
            ->ck_build_unop('pp_future_is_cancelled', '0')
            ->ck_end;

    # Register checkers function
    # cv_set_call_checker requires Perl 5.14+ - check at JIT time, not C compile time
    $builder->xs_function('xs_register_custom_ops')
            ->xs_preamble
            ->line('register_xop_future_is_done_xop(aTHX);')
            ->line('register_xop_future_is_ready_xop(aTHX);')
            ->line('register_xop_future_is_failed_xop(aTHX);')
            ->line('register_xop_future_is_cancelled_xop(aTHX);');

    # JIT optimization: only emit cv_set_call_checker code if Perl >= 5.14
    # This eliminates dead code from the generated C file on older Perls
    if ($] >= 5.014000) {
        $builder->line('{')
                ->line('    CV *custom_cv;')
                ->line('    custom_cv = get_cv("Hypersonic::Future::is_done", 0);')
                ->line('    if (custom_cv) cv_set_call_checker(custom_cv, S_ck_ck_future_is_done, &PL_sv_undef);')
                ->line('    custom_cv = get_cv("Hypersonic::Future::is_ready", 0);')
                ->line('    if (custom_cv) cv_set_call_checker(custom_cv, S_ck_ck_future_is_ready, &PL_sv_undef);')
                ->line('    custom_cv = get_cv("Hypersonic::Future::is_failed", 0);')
                ->line('    if (custom_cv) cv_set_call_checker(custom_cv, S_ck_ck_future_is_failed, &PL_sv_undef);')
                ->line('    custom_cv = get_cv("Hypersonic::Future::is_cancelled", 0);')
                ->line('    if (custom_cv) cv_set_call_checker(custom_cv, S_ck_ck_future_is_cancelled, &PL_sv_undef);')
                ->line('}');
    }

    $builder->xs_return('0')
            ->xs_end;
}

sub _gen_helpers {
    my ($class, $builder) = @_;
    my $inline = Hypersonic::JIT::Util->inline_keyword;

    # Forward declarations
    $builder->line('static void future_convergent_check(int parent_slot, int child_slot, int mask);')
            ->blank;

    # Freelist init - called once
    $builder->line("static $inline void future_freelist_init(void) {")
            ->line('    int i;')
            ->line('    if (future_freelist_initialized) return;')
            ->line('    for (i = MAX_FUTURES - 1; i >= 0; i--) {')
            ->line('        future_freelist[future_freelist_count++] = i;')
            ->line('    }')
            ->line('    future_freelist_initialized = 1;')
            ->line('}')
            ->blank;

    # Alloc slot - hot path optimized
    $builder->line("static $inline int future_alloc_slot(void) {")
            ->line('    if (!future_freelist_initialized) future_freelist_init();')
            ->line('    if (future_freelist_count > 0) {')
            ->line('        int slot = future_freelist[--future_freelist_count];')
            ->line('        FutureContext *ctx = &future_registry[slot];')
            ->line('        /* Minimal init - only 5 fields needed for basic pending future */')
            ->line('        ctx->in_use = 1;')
            ->line('        ctx->state = FUTURE_STATE_PENDING;')
            ->line('        ctx->refcount = 0;')
            ->line('        ctx->callback_count = 0;')
            ->line('        ctx->cancel_target = -1;')
            ->line('        /* These are only accessed after checking state/count, lazy init */')
            ->line('        /* result_values, fail_message, subfuture_slots set when used */')
            ->line('        return slot;')
            ->line('    }')
            ->line('    return -1;')
            ->line('}')
            ->blank;

    # Free slot
    $builder->line('static void future_free_slot(int slot) {')
            ->line('    int i;')
            ->line('    if (slot < 0 || slot >= MAX_FUTURES) return;')
            ->line('    FutureContext *ctx = &future_registry[slot];')
            ->line('    if (!ctx->in_use) return;')
            ->line('    if (ctx->result_values) {')
            ->line('        for (i = 0; i < ctx->result_count; i++) {')
            ->line('            if (ctx->result_values[i]) SvREFCNT_dec(ctx->result_values[i]);')
            ->line('        }')
            ->line('        free(ctx->result_values);')
            ->line('        ctx->result_values = NULL;')
            ->line('        ctx->result_count = 0;')
            ->line('    }')
            ->line('    if (ctx->fail_message) { free(ctx->fail_message); ctx->fail_message = NULL; }')
            ->line('    if (ctx->fail_category) { free(ctx->fail_category); ctx->fail_category = NULL; }')
            ->line('    for (i = 0; i < ctx->callback_count; i++) {')
            ->line('        if (ctx->callbacks[i].code) SvREFCNT_dec(ctx->callbacks[i].code);')
            ->line('    }')
            ->line('    if (ctx->subfuture_slots) { free(ctx->subfuture_slots); ctx->subfuture_slots = NULL; }')
            ->line('    ctx->subfuture_count = 0;')
            ->line('    ctx->subfutures_pending = 0;')
            ->line('    ctx->convergent_mode = 0;')
            ->line('    ctx->in_use = 0;')
            ->line('    if (future_freelist_count < MAX_FUTURES) {')
            ->line('        future_freelist[future_freelist_count++] = slot;')
            ->line('    }')
            ->line('}')
            ->blank;

    # Invoke callbacks - NOT static so Pool.pm can access
    $builder->line('void future_invoke_callbacks(int slot, int mask) {')
            ->line('    int i, j;')
            ->line('    FutureContext *ctx = &future_registry[slot];')
            ->line('    for (i = 0; i < ctx->callback_count; i++) {')
            ->line('        FutureCallback *cb = &ctx->callbacks[i];')
            ->line('        if (!(cb->type & mask)) continue;')
            ->line('        if (cb->target_slot >= 0) {')
            ->line('            FutureContext *target = &future_registry[cb->target_slot];')
            ->line('            /* Decrement refcount since callback is firing */')
            ->line('            target->refcount--;')
            ->line('            if (target->in_use && target->state == FUTURE_STATE_PENDING) {')
            ->line('                if (cb->code && cb->type == FUTURE_CB_READY) {')
            ->line('                    /* finally: call code, then propagate original state */')
            ->line('                    dSP;')
            ->line('                    ENTER; SAVETMPS;')
            ->line('                    PUSHMARK(SP);')
            ->line('                    PUTBACK;')
            ->line('                    call_sv(cb->code, G_DISCARD);')
            ->line('                    FREETMPS; LEAVE;')
            ->line('                    /* Propagate original state */')
            ->line('                    target->state = ctx->state;')
            ->line('                    if (ctx->state == FUTURE_STATE_DONE && ctx->result_count > 0) {')
            ->line('                        target->result_values = (SV **)malloc(ctx->result_count * sizeof(SV *));')
            ->line('                        for (j = 0; j < ctx->result_count; j++) {')
            ->line('                            target->result_values[j] = SvREFCNT_inc(ctx->result_values[j]);')
            ->line('                        }')
            ->line('                        target->result_count = ctx->result_count;')
            ->line('                    } else if (ctx->state == FUTURE_STATE_FAILED) {')
            ->line('                        if (ctx->fail_message) target->fail_message = strdup(ctx->fail_message);')
            ->line('                        if (ctx->fail_category) target->fail_category = strdup(ctx->fail_category);')
            ->line('                    }')
            ->line('                    future_invoke_callbacks(cb->target_slot, mask);')
            ->line('                } else if (cb->code) {')
            ->line('                    /* then/catch: call transform callback, use result for target */')
            ->line('                    dSP;')
            ->line('                    ENTER; SAVETMPS;')
            ->line('                    PUSHMARK(SP);')
            ->line('                    if (mask & FUTURE_CB_DONE) {')
            ->line('                        for (j = 0; j < ctx->result_count; j++) XPUSHs(ctx->result_values[j]);')
            ->line('                    } else if (mask & FUTURE_CB_FAIL) {')
            ->line('                        if (ctx->fail_message) XPUSHs(sv_2mortal(newSVpv(ctx->fail_message, 0)));')
            ->line('                        if (ctx->fail_category) XPUSHs(sv_2mortal(newSVpv(ctx->fail_category, 0)));')
            ->line('                    }')
            ->line('                    PUTBACK;')
            ->line('                    int count = call_sv(cb->code, G_ARRAY);')
            ->line('                    SPAGAIN;')
            ->line('                    if (count > 0) {')
            ->line('                        target->result_values = (SV **)malloc(count * sizeof(SV *));')
            ->line('                        for (j = count - 1; j >= 0; j--) target->result_values[j] = SvREFCNT_inc(POPs);')
            ->line('                        target->result_count = count;')
            ->line('                    }')
            ->line('                    target->state = FUTURE_STATE_DONE;')
            ->line('                    PUTBACK;')
            ->line('                    FREETMPS; LEAVE;')
            ->line('                    future_invoke_callbacks(cb->target_slot, FUTURE_CB_DONE);')
            ->line('                } else {')
            ->line('                    /* No code: check for convergent or propagate state directly */')
            ->line('                    if (target->convergent_mode > 0) {')
            ->line('                        /* This is a convergent future - use convergent check */')
            ->line('                        future_convergent_check(cb->target_slot, slot, mask);')
            ->line('                    } else if (mask & FUTURE_CB_DONE) {')
            ->line('                        target->state = FUTURE_STATE_DONE;')
            ->line('                        if (ctx->result_count > 0) {')
            ->line('                            target->result_values = (SV **)malloc(ctx->result_count * sizeof(SV *));')
            ->line('                            for (j = 0; j < ctx->result_count; j++) {')
            ->line('                                target->result_values[j] = SvREFCNT_inc(ctx->result_values[j]);')
            ->line('                            }')
            ->line('                            target->result_count = ctx->result_count;')
            ->line('                        }')
            ->line('                        future_invoke_callbacks(cb->target_slot, FUTURE_CB_DONE);')
            ->line('                    } else if (mask & FUTURE_CB_FAIL) {')
            ->line('                        target->state = FUTURE_STATE_FAILED;')
            ->line('                        if (ctx->fail_message) target->fail_message = strdup(ctx->fail_message);')
            ->line('                        if (ctx->fail_category) target->fail_category = strdup(ctx->fail_category);')
            ->line('                        future_invoke_callbacks(cb->target_slot, FUTURE_CB_FAIL);')
            ->line('                    } else if (mask & FUTURE_CB_CANCEL) {')
            ->line('                        target->state = FUTURE_STATE_CANCELLED;')
            ->line('                        future_invoke_callbacks(cb->target_slot, FUTURE_CB_CANCEL);')
            ->line('                    }')
            ->line('                }')
            ->line('            }')
            ->line('        } else if (cb->code) {')
            ->line('            /* No target: just call callback */')
            ->line('            dSP;')
            ->line('            ENTER; SAVETMPS;')
            ->line('            PUSHMARK(SP);')
            ->line('            if (mask & FUTURE_CB_DONE) {')
            ->line('                for (j = 0; j < ctx->result_count; j++) {')
            ->line('                    XPUSHs(ctx->result_values[j]);')
            ->line('                }')
            ->line('            } else if (mask & FUTURE_CB_FAIL) {')
            ->line('                if (ctx->fail_message) XPUSHs(sv_2mortal(newSVpv(ctx->fail_message, 0)));')
            ->line('                if (ctx->fail_category) XPUSHs(sv_2mortal(newSVpv(ctx->fail_category, 0)));')
            ->line('            }')
            ->line('            PUTBACK;')
            ->line('            call_sv(cb->code, G_DISCARD);')
            ->line('            FREETMPS; LEAVE;')
            ->line('        }')
            ->line('    }')
            ->line('}')
            ->blank;

    # Convergent helper - called when a subfuture resolves
    $builder->line('static void future_convergent_check(int parent_slot, int child_slot, int mask) {')
            ->line('    int i;')
            ->line('    FutureContext *parent = &future_registry[parent_slot];')
            ->line('    FutureContext *child = &future_registry[child_slot];')
            ->line('    if (parent->state != FUTURE_STATE_PENDING) return;')
            ->line('    if (parent->convergent_mode == 1) {')
            ->line('        /* needs_all: all must succeed, first fail fails all */')
            ->line('        if (mask & FUTURE_CB_FAIL) {')
            ->line('            parent->state = FUTURE_STATE_FAILED;')
            ->line('            if (child->fail_message) parent->fail_message = strdup(child->fail_message);')
            ->line('            if (child->fail_category) parent->fail_category = strdup(child->fail_category);')
            ->line('            future_invoke_callbacks(parent_slot, FUTURE_CB_FAIL);')
            ->line('        } else if (mask & FUTURE_CB_CANCEL) {')
            ->line('            parent->state = FUTURE_STATE_CANCELLED;')
            ->line('            future_invoke_callbacks(parent_slot, FUTURE_CB_CANCEL);')
            ->line('        } else {')
            ->line('            parent->subfutures_pending--;')
            ->line('            if (parent->subfutures_pending == 0) {')
            ->line('                /* All done - collect results as flat list */')
            ->line('                int count = parent->subfuture_count;')
            ->line('                parent->result_values = (SV**)malloc(count * sizeof(SV*));')
            ->line('                parent->result_count = 0;')
            ->line('                for (i = 0; i < count; i++) {')
            ->line('                    FutureContext *sub = &future_registry[parent->subfuture_slots[i]];')
            ->line('                    if (sub->result_count > 0) {')
            ->line('                        parent->result_values[parent->result_count++] = SvREFCNT_inc(sub->result_values[0]);')
            ->line('                    }')
            ->line('                }')
            ->line('                parent->state = FUTURE_STATE_DONE;')
            ->line('                future_invoke_callbacks(parent_slot, FUTURE_CB_DONE);')
            ->line('            }')
            ->line('        }')
            ->line('    } else if (parent->convergent_mode == 2) {')
            ->line('        /* needs_any: first success wins, all fail to fail */')
            ->line('        if (mask & FUTURE_CB_DONE) {')
            ->line('            parent->state = FUTURE_STATE_DONE;')
            ->line('            if (child->result_count > 0) {')
            ->line('                parent->result_values = (SV**)malloc(child->result_count * sizeof(SV*));')
            ->line('                for (i = 0; i < child->result_count; i++) {')
            ->line('                    parent->result_values[i] = SvREFCNT_inc(child->result_values[i]);')
            ->line('                }')
            ->line('                parent->result_count = child->result_count;')
            ->line('            }')
            ->line('            future_invoke_callbacks(parent_slot, FUTURE_CB_DONE);')
            ->line('        } else {')
            ->line('            parent->subfutures_pending--;')
            ->line('            if (parent->subfutures_pending == 0) {')
            ->line('                /* All failed - propagate last failure */')
            ->line('                parent->state = FUTURE_STATE_FAILED;')
            ->line('                if (child->fail_message) parent->fail_message = strdup(child->fail_message);')
            ->line('                if (child->fail_category) parent->fail_category = strdup(child->fail_category);')
            ->line('                future_invoke_callbacks(parent_slot, FUTURE_CB_FAIL);')
            ->line('            }')
            ->line('        }')
            ->line('    }')
            ->line('}')
            ->blank;
}

sub _gen_xs_functions {
    my ($class, $builder) = @_;

    # xs_future_new
    $builder->xs_function('xs_future_new')
            ->xs_preamble
            ->line('int slot = future_alloc_slot();')
            ->line('if (slot < 0) croak("Future registry full");')
            ->line('SV *slot_sv = newSViv(slot);')
            ->line('SV *self_ref = newRV_noinc(slot_sv);')
            ->line('sv_bless(self_ref, gv_stashpv("Hypersonic::Future", GV_ADD));')
            ->line('future_registry[slot].refcount = 1;')
            ->line('ST(0) = sv_2mortal(self_ref);')
            ->xs_return('1')
            ->xs_end;

    # xs_future_new_done - create already-done future in one call
    $builder->xs_function('xs_future_new_done')
            ->xs_preamble
            ->line('int i;')
            ->line('int slot = future_alloc_slot();')
            ->line('if (slot < 0) croak("Future registry full");')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('int value_count = items - 1;')
            ->line('if (value_count > 0) {')
            ->line('    ctx->result_values = (SV **)malloc(value_count * sizeof(SV *));')
            ->line('    for (i = 0; i < value_count; i++) {')
            ->line('        ctx->result_values[i] = SvREFCNT_inc(ST(i + 1));')
            ->line('    }')
            ->line('    ctx->result_count = value_count;')
            ->line('}')
            ->line('ctx->state = FUTURE_STATE_DONE;')
            ->line('SV *slot_sv = newSViv(slot);')
            ->line('SV *self_ref = newRV_noinc(slot_sv);')
            ->line('sv_bless(self_ref, gv_stashpv("Hypersonic::Future", GV_ADD));')
            ->line('ctx->refcount = 1;')
            ->line('ST(0) = sv_2mortal(self_ref);')
            ->xs_return('1')
            ->xs_end;

    # xs_future_new_fail - create already-failed future in one call
    $builder->xs_function('xs_future_new_fail')
            ->xs_preamble
            ->line('if (items < 2) croak("Usage: Hypersonic::Future->new_fail($message, [$category])");')
            ->line('int slot = future_alloc_slot();')
            ->line('if (slot < 0) croak("Future registry full");')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('STRLEN msg_len;')
            ->line('const char *msg = SvPV(ST(1), msg_len);')
            ->line('ctx->fail_message = (char *)malloc(msg_len + 1);')
            ->line('memcpy(ctx->fail_message, msg, msg_len);')
            ->line('ctx->fail_message[msg_len] = \'\\0\';')
            ->line('if (items > 2 && SvOK(ST(2))) {')
            ->line('    STRLEN cat_len;')
            ->line('    const char *cat = SvPV(ST(2), cat_len);')
            ->line('    ctx->fail_category = (char *)malloc(cat_len + 1);')
            ->line('    memcpy(ctx->fail_category, cat, cat_len);')
            ->line('    ctx->fail_category[cat_len] = \'\\0\';')
            ->line('}')
            ->line('ctx->state = FUTURE_STATE_FAILED;')
            ->line('SV *slot_sv = newSViv(slot);')
            ->line('SV *self_ref = newRV_noinc(slot_sv);')
            ->line('sv_bless(self_ref, gv_stashpv("Hypersonic::Future", GV_ADD));')
            ->line('ctx->refcount = 1;')
            ->line('ST(0) = sv_2mortal(self_ref);')
            ->xs_return('1')
            ->xs_end;

    # xs_future_done
    $builder->xs_function('xs_future_done')
            ->xs_preamble
            ->line('int i;')
            ->line('if (items < 1) croak("Usage: $future->done(@values)");')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('if (ctx->state != FUTURE_STATE_PENDING) croak("Future already resolved");')
            ->line('int value_count = items - 1;')
            ->line('if (value_count > 0) {')
            ->line('    ctx->result_values = (SV **)malloc(value_count * sizeof(SV *));')
            ->line('    for (i = 0; i < value_count; i++) {')
            ->line('        ctx->result_values[i] = SvREFCNT_inc(ST(i + 1));')
            ->line('    }')
            ->line('}')
            ->line('ctx->result_count = value_count;')
            ->line('ctx->state = FUTURE_STATE_DONE;')
            ->line('future_invoke_callbacks(slot, FUTURE_CB_DONE);')
            ->line('ST(0) = ST(0);')
            ->xs_return('1')
            ->xs_end;

    # xs_future_fail
    $builder->xs_function('xs_future_fail')
            ->xs_preamble
            ->line('if (items < 2) croak("Usage: $future->fail($message, [$category])");')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('if (ctx->state != FUTURE_STATE_PENDING) croak("Future already resolved");')
            ->line('STRLEN msg_len;')
            ->line('const char *msg = SvPV(ST(1), msg_len);')
            ->line('ctx->fail_message = (char *)malloc(msg_len + 1);')
            ->line('memcpy(ctx->fail_message, msg, msg_len);')
            ->line('ctx->fail_message[msg_len] = \'\\0\';')
            ->line('if (items > 2 && SvOK(ST(2))) {')
            ->line('    STRLEN cat_len;')
            ->line('    const char *cat = SvPV(ST(2), cat_len);')
            ->line('    ctx->fail_category = (char *)malloc(cat_len + 1);')
            ->line('    memcpy(ctx->fail_category, cat, cat_len);')
            ->line('    ctx->fail_category[cat_len] = \'\\0\';')
            ->line('}')
            ->line('ctx->state = FUTURE_STATE_FAILED;')
            ->line('future_invoke_callbacks(slot, FUTURE_CB_FAIL);')
            ->line('ST(0) = ST(0);')
            ->xs_return('1')
            ->xs_end;

    # xs_future_cancel
    $builder->xs_function('xs_future_cancel')
            ->xs_preamble
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('if (ctx->state != FUTURE_STATE_PENDING) { ST(0) = ST(0); XSRETURN(1); }')
            ->line('ctx->state = FUTURE_STATE_CANCELLED;')
            ->line('future_invoke_callbacks(slot, FUTURE_CB_CANCEL);')
            ->line('ST(0) = ST(0);')
            ->xs_return('1')
            ->xs_end;

    # State checks
    $builder->xs_function('xs_future_is_ready')
            ->xs_preamble
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('ST(0) = boolSV(future_registry[slot].state != FUTURE_STATE_PENDING);')
            ->xs_return('1')
            ->xs_end;

    $builder->xs_function('xs_future_is_done')
            ->xs_preamble
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('ST(0) = boolSV(future_registry[slot].state == FUTURE_STATE_DONE);')
            ->xs_return('1')
            ->xs_end;

    $builder->xs_function('xs_future_is_failed')
            ->xs_preamble
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('ST(0) = boolSV(future_registry[slot].state == FUTURE_STATE_FAILED);')
            ->xs_return('1')
            ->xs_end;

    $builder->xs_function('xs_future_is_cancelled')
            ->xs_preamble
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('ST(0) = boolSV(future_registry[slot].state == FUTURE_STATE_CANCELLED);')
            ->xs_return('1')
            ->xs_end;

    # Result access
    $builder->xs_function('xs_future_result')
            ->xs_preamble
            ->line('int i;')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('if (ctx->state != FUTURE_STATE_DONE) croak("Future is not done");')
            ->line('SP -= items;')
            ->line('for (i = 0; i < ctx->result_count; i++) {')
            ->line('    XPUSHs(ctx->result_values[i]);')
            ->line('}')
            ->line('PUTBACK;')
            ->line('return;')
            ->xs_end;

    $builder->xs_function('xs_future_failure')
            ->xs_preamble
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('if (ctx->state != FUTURE_STATE_FAILED) croak("Future is not failed");')
            ->line('SP -= items;')
            ->line('if (ctx->fail_message) XPUSHs(sv_2mortal(newSVpv(ctx->fail_message, 0)));')
            ->line('else XPUSHs(&PL_sv_undef);')
            ->line('if (ctx->fail_category) XPUSHs(sv_2mortal(newSVpv(ctx->fail_category, 0)));')
            ->line('PUTBACK;')
            ->line('return;')
            ->xs_end;

    # Callbacks
    $builder->xs_function('xs_future_on_ready')
            ->xs_preamble
            ->line('if (items != 2) croak("Usage: $future->on_ready($code)");')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('SV *code = ST(1);')
            ->line('if (ctx->state != FUTURE_STATE_PENDING) {')
            ->line('    dSP;')
            ->line('    ENTER; SAVETMPS;')
            ->line('    PUSHMARK(SP);')
            ->line('    XPUSHs(ST(0));')
            ->line('    PUTBACK;')
            ->line('    call_sv(code, G_DISCARD);')
            ->line('    FREETMPS; LEAVE;')
            ->line('} else if (ctx->callback_count < MAX_CALLBACKS) {')
            ->line('    FutureCallback *cb = &ctx->callbacks[ctx->callback_count++];')
            ->line('    cb->type = FUTURE_CB_READY;')
            ->line('    cb->code = SvREFCNT_inc(code);')
            ->line('    cb->target_slot = -1;')
            ->line('}')
            ->line('ST(0) = ST(0);')
            ->xs_return('1')
            ->xs_end;

    $builder->xs_function('xs_future_on_done')
            ->xs_preamble
            ->line('int i;')
            ->line('if (items != 2) croak("Usage: $future->on_done($code)");')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('SV *code = ST(1);')
            ->line('if (ctx->state == FUTURE_STATE_DONE) {')
            ->line('    dSP;')
            ->line('    ENTER; SAVETMPS;')
            ->line('    PUSHMARK(SP);')
            ->line('    for (i = 0; i < ctx->result_count; i++) XPUSHs(ctx->result_values[i]);')
            ->line('    PUTBACK;')
            ->line('    call_sv(code, G_DISCARD);')
            ->line('    FREETMPS; LEAVE;')
            ->line('} else if (ctx->state == FUTURE_STATE_PENDING && ctx->callback_count < MAX_CALLBACKS) {')
            ->line('    FutureCallback *cb = &ctx->callbacks[ctx->callback_count++];')
            ->line('    cb->type = FUTURE_CB_DONE;')
            ->line('    cb->code = SvREFCNT_inc(code);')
            ->line('    cb->target_slot = -1;')
            ->line('}')
            ->line('ST(0) = ST(0);')
            ->xs_return('1')
            ->xs_end;

    $builder->xs_function('xs_future_on_fail')
            ->xs_preamble
            ->line('if (items != 2) croak("Usage: $future->on_fail($code)");')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('SV *code = ST(1);')
            ->line('if (ctx->state == FUTURE_STATE_FAILED) {')
            ->line('    dSP;')
            ->line('    ENTER; SAVETMPS;')
            ->line('    PUSHMARK(SP);')
            ->line('    if (ctx->fail_message) XPUSHs(sv_2mortal(newSVpv(ctx->fail_message, 0)));')
            ->line('    if (ctx->fail_category) XPUSHs(sv_2mortal(newSVpv(ctx->fail_category, 0)));')
            ->line('    PUTBACK;')
            ->line('    call_sv(code, G_DISCARD);')
            ->line('    FREETMPS; LEAVE;')
            ->line('} else if (ctx->state == FUTURE_STATE_PENDING && ctx->callback_count < MAX_CALLBACKS) {')
            ->line('    FutureCallback *cb = &ctx->callbacks[ctx->callback_count++];')
            ->line('    cb->type = FUTURE_CB_FAIL;')
            ->line('    cb->code = SvREFCNT_inc(code);')
            ->line('    cb->target_slot = -1;')
            ->line('}')
            ->line('ST(0) = ST(0);')
            ->xs_return('1')
            ->xs_end;

    $builder->xs_function('xs_future_on_cancel')
            ->xs_preamble
            ->line('if (items != 2) croak("Usage: $future->on_cancel($code)");')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('SV *code = ST(1);')
            ->line('if (ctx->state == FUTURE_STATE_CANCELLED) {')
            ->line('    dSP;')
            ->line('    ENTER; SAVETMPS;')
            ->line('    PUSHMARK(SP);')
            ->line('    PUTBACK;')
            ->line('    call_sv(code, G_DISCARD);')
            ->line('    FREETMPS; LEAVE;')
            ->line('} else if (ctx->state == FUTURE_STATE_PENDING && ctx->callback_count < MAX_CALLBACKS) {')
            ->line('    FutureCallback *cb = &ctx->callbacks[ctx->callback_count++];')
            ->line('    cb->type = FUTURE_CB_CANCEL;')
            ->line('    cb->code = SvREFCNT_inc(code);')
            ->line('    cb->target_slot = -1;')
            ->line('}')
            ->line('ST(0) = ST(0);')
            ->xs_return('1')
            ->xs_end;

    # Sequencing: then
    $builder->xs_function('xs_future_then')
            ->xs_preamble
            ->line('int i;')
            ->line('if (items != 2) croak("Usage: $future->then($code)");')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('SV *code = ST(1);')
            ->line('int new_slot = future_alloc_slot();')
            ->line('if (new_slot < 0) croak("Future registry full");')
            ->line('FutureContext *new_ctx = &future_registry[new_slot];')
            ->line('new_ctx->cancel_target = slot;')
            ->line('/* Keep parent alive while child exists (for chaining) */')
            ->line('ctx->refcount++;')
            ->line('if (ctx->state == FUTURE_STATE_DONE) {')
            ->line('    dSP;')
            ->line('    ENTER; SAVETMPS;')
            ->line('    PUSHMARK(SP);')
            ->line('    for (i = 0; i < ctx->result_count; i++) XPUSHs(ctx->result_values[i]);')
            ->line('    PUTBACK;')
            ->line('    int count = call_sv(code, G_ARRAY);')
            ->line('    SPAGAIN;')
            ->line('    if (count > 0) {')
            ->line('        new_ctx->result_values = (SV **)malloc(count * sizeof(SV *));')
            ->line('        for (i = count - 1; i >= 0; i--) new_ctx->result_values[i] = SvREFCNT_inc(POPs);')
            ->line('        new_ctx->result_count = count;')
            ->line('    }')
            ->line('    new_ctx->state = FUTURE_STATE_DONE;')
            ->line('    PUTBACK;')
            ->line('    FREETMPS; LEAVE;')
            ->line('} else if (ctx->state == FUTURE_STATE_FAILED) {')
            ->line('    new_ctx->state = FUTURE_STATE_FAILED;')
            ->line('    if (ctx->fail_message) new_ctx->fail_message = strdup(ctx->fail_message);')
            ->line('    if (ctx->fail_category) new_ctx->fail_category = strdup(ctx->fail_category);')
            ->line('} else if (ctx->state == FUTURE_STATE_CANCELLED) {')
            ->line('    new_ctx->state = FUTURE_STATE_CANCELLED;')
            ->line('} else {')
            ->line('    if (ctx->callback_count < MAX_CALLBACKS - 1) {')
            ->line('        FutureCallback *cb = &ctx->callbacks[ctx->callback_count++];')
            ->line('        cb->type = FUTURE_CB_DONE;')
            ->line('        cb->code = SvREFCNT_inc(code);')
            ->line('        cb->target_slot = new_slot;')
            ->line('        FutureCallback *fail_cb = &ctx->callbacks[ctx->callback_count++];')
            ->line('        fail_cb->type = FUTURE_CB_FAIL | FUTURE_CB_CANCEL;')
            ->line('        fail_cb->code = NULL;')
            ->line('        fail_cb->target_slot = new_slot;')
            ->line('        /* Keep child alive until parent resolves */')
            ->line('        new_ctx->refcount++;')
            ->line('    }')
            ->line('}')
            ->line('SV *new_slot_sv = newSViv(new_slot);')
            ->line('SV *new_ref = newRV_noinc(new_slot_sv);')
            ->line('sv_bless(new_ref, gv_stashpv("Hypersonic::Future", GV_ADD));')
            ->line('/* refcount already 1 from alloc_slot for Perl ref */')
            ->line('ST(0) = sv_2mortal(new_ref);')
            ->xs_return('1')
            ->xs_end;

    # Sequencing: catch
    $builder->xs_function('xs_future_catch')
            ->xs_preamble
            ->line('int i;')
            ->line('if (items != 2) croak("Usage: $future->catch($code)");')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('SV *code = ST(1);')
            ->line('int new_slot = future_alloc_slot();')
            ->line('if (new_slot < 0) croak("Future registry full");')
            ->line('FutureContext *new_ctx = &future_registry[new_slot];')
            ->line('new_ctx->cancel_target = slot;')
            ->line('/* Keep parent alive while child exists (for chaining) */')
            ->line('ctx->refcount++;')
            ->line('if (ctx->state == FUTURE_STATE_FAILED) {')
            ->line('    dSP;')
            ->line('    ENTER; SAVETMPS;')
            ->line('    PUSHMARK(SP);')
            ->line('    if (ctx->fail_message) XPUSHs(sv_2mortal(newSVpv(ctx->fail_message, 0)));')
            ->line('    if (ctx->fail_category) XPUSHs(sv_2mortal(newSVpv(ctx->fail_category, 0)));')
            ->line('    PUTBACK;')
            ->line('    int count = call_sv(code, G_ARRAY);')
            ->line('    SPAGAIN;')
            ->line('    if (count > 0) {')
            ->line('        new_ctx->result_values = (SV **)malloc(count * sizeof(SV *));')
            ->line('        for (i = count - 1; i >= 0; i--) new_ctx->result_values[i] = SvREFCNT_inc(POPs);')
            ->line('        new_ctx->result_count = count;')
            ->line('    }')
            ->line('    new_ctx->state = FUTURE_STATE_DONE;')
            ->line('    PUTBACK;')
            ->line('    FREETMPS; LEAVE;')
            ->line('} else if (ctx->state == FUTURE_STATE_DONE) {')
            ->line('    new_ctx->state = FUTURE_STATE_DONE;')
            ->line('    if (ctx->result_count > 0) {')
            ->line('        new_ctx->result_values = (SV **)malloc(ctx->result_count * sizeof(SV *));')
            ->line('        for (i = 0; i < ctx->result_count; i++) new_ctx->result_values[i] = SvREFCNT_inc(ctx->result_values[i]);')
            ->line('        new_ctx->result_count = ctx->result_count;')
            ->line('    }')
            ->line('} else if (ctx->state == FUTURE_STATE_CANCELLED) {')
            ->line('    new_ctx->state = FUTURE_STATE_CANCELLED;')
            ->line('} else {')
            ->line('    if (ctx->callback_count < MAX_CALLBACKS - 1) {')
            ->line('        FutureCallback *cb = &ctx->callbacks[ctx->callback_count++];')
            ->line('        cb->type = FUTURE_CB_FAIL;')
            ->line('        cb->code = SvREFCNT_inc(code);')
            ->line('        cb->target_slot = new_slot;')
            ->line('        FutureCallback *done_cb = &ctx->callbacks[ctx->callback_count++];')
            ->line('        done_cb->type = FUTURE_CB_DONE | FUTURE_CB_CANCEL;')
            ->line('        done_cb->code = NULL;')
            ->line('        done_cb->target_slot = new_slot;')
            ->line('        /* Keep child alive until parent resolves */')
            ->line('        new_ctx->refcount++;')
            ->line('    }')
            ->line('}')
            ->line('SV *new_slot_sv = newSViv(new_slot);')
            ->line('SV *new_ref = newRV_noinc(new_slot_sv);')
            ->line('sv_bless(new_ref, gv_stashpv("Hypersonic::Future", GV_ADD));')
            ->line('/* refcount already 1 from alloc_slot for Perl ref */')
            ->line('ST(0) = sv_2mortal(new_ref);')
            ->xs_return('1')
            ->xs_end;

    # Sequencing: finally
    $builder->xs_function('xs_future_finally')
            ->xs_preamble
            ->line('int i;')
            ->line('if (items != 2) croak("Usage: $future->finally($code)");')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('FutureContext *ctx = &future_registry[slot];')
            ->line('SV *code = ST(1);')
            ->line('int new_slot = future_alloc_slot();')
            ->line('if (new_slot < 0) croak("Future registry full");')
            ->line('FutureContext *new_ctx = &future_registry[new_slot];')
            ->line('new_ctx->cancel_target = slot;')
            ->line('/* Keep parent alive while child exists (for chaining) */')
            ->line('ctx->refcount++;')
            ->line('if (ctx->state != FUTURE_STATE_PENDING) {')
            ->line('    dSP;')
            ->line('    ENTER; SAVETMPS;')
            ->line('    PUSHMARK(SP);')
            ->line('    PUTBACK;')
            ->line('    call_sv(code, G_DISCARD);')
            ->line('    FREETMPS; LEAVE;')
            ->line('    new_ctx->state = ctx->state;')
            ->line('    if (ctx->state == FUTURE_STATE_DONE && ctx->result_count > 0) {')
            ->line('        new_ctx->result_values = (SV **)malloc(ctx->result_count * sizeof(SV *));')
            ->line('        for (i = 0; i < ctx->result_count; i++) new_ctx->result_values[i] = SvREFCNT_inc(ctx->result_values[i]);')
            ->line('        new_ctx->result_count = ctx->result_count;')
            ->line('    } else if (ctx->state == FUTURE_STATE_FAILED) {')
            ->line('        if (ctx->fail_message) new_ctx->fail_message = strdup(ctx->fail_message);')
            ->line('        if (ctx->fail_category) new_ctx->fail_category = strdup(ctx->fail_category);')
            ->line('    }')
            ->line('} else {')
            ->line('    if (ctx->callback_count < MAX_CALLBACKS) {')
            ->line('        FutureCallback *cb = &ctx->callbacks[ctx->callback_count++];')
            ->line('        cb->type = FUTURE_CB_READY;')
            ->line('        cb->code = SvREFCNT_inc(code);')
            ->line('        cb->target_slot = new_slot;')
            ->line('        /* Keep child alive until parent resolves */')
            ->line('        new_ctx->refcount++;')
            ->line('    }')
            ->line('}')
            ->line('SV *new_slot_sv = newSViv(new_slot);')
            ->line('SV *new_ref = newRV_noinc(new_slot_sv);')
            ->line('sv_bless(new_ref, gv_stashpv("Hypersonic::Future", GV_ADD));')
            ->line('/* refcount already 1 from alloc_slot for Perl ref */')
            ->line('ST(0) = sv_2mortal(new_ref);')
            ->xs_return('1')
            ->xs_end;

    # Convergent: needs_all - all must succeed
    $builder->xs_function('xs_future_needs_all')
            ->xs_preamble
            ->line('int i;')
            ->line('if (items < 2) croak("Usage: Hypersonic::Future->needs_all(@futures)");')
            ->line('int new_slot = future_alloc_slot();')
            ->line('if (new_slot < 0) croak("Future registry full");')
            ->line('FutureContext *ctx = &future_registry[new_slot];')
            ->line('int count = items - 1;')
            ->line('ctx->subfuture_slots = (int*)malloc(count * sizeof(int));')
            ->line('ctx->subfuture_count = count;')
            ->line('ctx->subfutures_pending = count;')
            ->line('ctx->convergent_mode = 1;')
            ->line('int all_done = 1;')
            ->line('for (i = 0; i < count; i++) {')
            ->line('    SV *sub_sv = ST(i + 1);')
            ->line('    if (!sv_isobject(sub_sv)) croak("needs_all: argument %d is not a Future", i+1);')
            ->line('    int sub_slot = SvIV(SvRV(sub_sv));')
            ->line('    ctx->subfuture_slots[i] = sub_slot;')
            ->line('    FutureContext *sub = &future_registry[sub_slot];')
            ->line('    if (sub->state == FUTURE_STATE_PENDING) {')
            ->line('        all_done = 0;')
            ->line('        /* Register callback on subfuture */')
            ->line('        if (sub->callback_count < MAX_CALLBACKS) {')
            ->line('            FutureCallback *cb = &sub->callbacks[sub->callback_count++];')
            ->line('            cb->type = FUTURE_CB_READY;')
            ->line('            cb->code = NULL;')
            ->line('            cb->target_slot = new_slot;')
            ->line('            ctx->refcount++;')
            ->line('        }')
            ->line('    } else if (sub->state == FUTURE_STATE_FAILED) {')
            ->line('        ctx->state = FUTURE_STATE_FAILED;')
            ->line('        if (sub->fail_message) ctx->fail_message = strdup(sub->fail_message);')
            ->line('        if (sub->fail_category) ctx->fail_category = strdup(sub->fail_category);')
            ->line('        break;')
            ->line('    } else if (sub->state == FUTURE_STATE_CANCELLED) {')
            ->line('        ctx->state = FUTURE_STATE_CANCELLED;')
            ->line('        break;')
            ->line('    } else {')
            ->line('        ctx->subfutures_pending--;')
            ->line('    }')
            ->line('}')
            ->line('if (ctx->state == FUTURE_STATE_PENDING && all_done) {')
            ->line('    /* All already done - collect results as flat list */')
            ->line('    ctx->result_values = (SV**)malloc(count * sizeof(SV*));')
            ->line('    ctx->result_count = 0;')
            ->line('    for (i = 0; i < count; i++) {')
            ->line('        FutureContext *sub = &future_registry[ctx->subfuture_slots[i]];')
            ->line('        if (sub->result_count > 0) {')
            ->line('            ctx->result_values[ctx->result_count++] = SvREFCNT_inc(sub->result_values[0]);')
            ->line('        }')
            ->line('    }')
            ->line('    ctx->state = FUTURE_STATE_DONE;')
            ->line('}')
            ->line('SV *slot_sv = newSViv(new_slot);')
            ->line('SV *self_ref = newRV_noinc(slot_sv);')
            ->line('sv_bless(self_ref, gv_stashpv("Hypersonic::Future", GV_ADD));')
            ->line('/* refcount already 1 from alloc_slot for Perl ref */')
            ->line('ST(0) = sv_2mortal(self_ref);')
            ->xs_return('1')
            ->xs_end;

    # Convergent: needs_any - first success wins
    $builder->xs_function('xs_future_needs_any')
            ->xs_preamble
            ->line('int i, j;')
            ->line('if (items < 2) croak("Usage: Hypersonic::Future->needs_any(@futures)");')
            ->line('int new_slot = future_alloc_slot();')
            ->line('if (new_slot < 0) croak("Future registry full");')
            ->line('FutureContext *ctx = &future_registry[new_slot];')
            ->line('int count = items - 1;')
            ->line('ctx->subfuture_slots = (int*)malloc(count * sizeof(int));')
            ->line('ctx->subfuture_count = count;')
            ->line('ctx->subfutures_pending = count;')
            ->line('ctx->convergent_mode = 2;')
            ->line('for (i = 0; i < count; i++) {')
            ->line('    SV *sub_sv = ST(i + 1);')
            ->line('    if (!sv_isobject(sub_sv)) croak("needs_any: argument %d is not a Future", i+1);')
            ->line('    int sub_slot = SvIV(SvRV(sub_sv));')
            ->line('    ctx->subfuture_slots[i] = sub_slot;')
            ->line('    FutureContext *sub = &future_registry[sub_slot];')
            ->line('    if (sub->state == FUTURE_STATE_DONE) {')
            ->line('        /* First success - use it */')
            ->line('        if (sub->result_count > 0) {')
            ->line('            ctx->result_values = (SV**)malloc(sub->result_count * sizeof(SV*));')
            ->line('            for (j = 0; j < sub->result_count; j++) {')
            ->line('                ctx->result_values[j] = SvREFCNT_inc(sub->result_values[j]);')
            ->line('            }')
            ->line('            ctx->result_count = sub->result_count;')
            ->line('        }')
            ->line('        ctx->state = FUTURE_STATE_DONE;')
            ->line('        break;')
            ->line('    } else if (sub->state == FUTURE_STATE_PENDING) {')
            ->line('        /* Register callback on subfuture */')
            ->line('        if (sub->callback_count < MAX_CALLBACKS) {')
            ->line('            FutureCallback *cb = &sub->callbacks[sub->callback_count++];')
            ->line('            cb->type = FUTURE_CB_READY;')
            ->line('            cb->code = NULL;')
            ->line('            cb->target_slot = new_slot;')
            ->line('            ctx->refcount++;')
            ->line('        }')
            ->line('    } else {')
            ->line('        ctx->subfutures_pending--;')
            ->line('    }')
            ->line('}')
            ->line('if (ctx->state == FUTURE_STATE_PENDING && ctx->subfutures_pending == 0) {')
            ->line('    /* All failed - propagate last failure */')
            ->line('    FutureContext *last = &future_registry[ctx->subfuture_slots[count-1]];')
            ->line('    ctx->state = FUTURE_STATE_FAILED;')
            ->line('    if (last->fail_message) ctx->fail_message = strdup(last->fail_message);')
            ->line('    if (last->fail_category) ctx->fail_category = strdup(last->fail_category);')
            ->line('}')
            ->line('SV *slot_sv = newSViv(new_slot);')
            ->line('SV *self_ref = newRV_noinc(slot_sv);')
            ->line('sv_bless(self_ref, gv_stashpv("Hypersonic::Future", GV_ADD));')
            ->line('/* refcount already 1 from alloc_slot for Perl ref */')
            ->line('ST(0) = sv_2mortal(self_ref);')
            ->xs_return('1')
            ->xs_end;

    # wait_all and wait_any are aliases that also wait synchronously
    # For now, they just return the convergent future (async behavior)
    $builder->xs_function('xs_future_wait_all')
            ->xs_preamble
            ->line('int i;')
            ->line('/* Same as needs_all for now */')
            ->line('if (items < 2) croak("Usage: Hypersonic::Future->wait_all(@futures)");')
            ->line('int new_slot = future_alloc_slot();')
            ->line('if (new_slot < 0) croak("Future registry full");')
            ->line('FutureContext *ctx = &future_registry[new_slot];')
            ->line('int count = items - 1;')
            ->line('ctx->subfuture_slots = (int*)malloc(count * sizeof(int));')
            ->line('ctx->subfuture_count = count;')
            ->line('ctx->subfutures_pending = count;')
            ->line('ctx->convergent_mode = 1;')
            ->line('int all_done = 1;')
            ->line('for (i = 0; i < count; i++) {')
            ->line('    SV *sub_sv = ST(i + 1);')
            ->line('    if (!sv_isobject(sub_sv)) croak("wait_all: argument %d is not a Future", i+1);')
            ->line('    int sub_slot = SvIV(SvRV(sub_sv));')
            ->line('    ctx->subfuture_slots[i] = sub_slot;')
            ->line('    FutureContext *sub = &future_registry[sub_slot];')
            ->line('    if (sub->state == FUTURE_STATE_PENDING) {')
            ->line('        all_done = 0;')
            ->line('        if (sub->callback_count < MAX_CALLBACKS) {')
            ->line('            FutureCallback *cb = &sub->callbacks[sub->callback_count++];')
            ->line('            cb->type = FUTURE_CB_READY;')
            ->line('            cb->code = NULL;')
            ->line('            cb->target_slot = new_slot;')
            ->line('            ctx->refcount++;')
            ->line('        }')
            ->line('    } else if (sub->state != FUTURE_STATE_DONE) {')
            ->line('        ctx->state = sub->state;')
            ->line('        if (sub->fail_message) ctx->fail_message = strdup(sub->fail_message);')
            ->line('        if (sub->fail_category) ctx->fail_category = strdup(sub->fail_category);')
            ->line('        break;')
            ->line('    } else {')
            ->line('        ctx->subfutures_pending--;')
            ->line('    }')
            ->line('}')
            ->line('if (ctx->state == FUTURE_STATE_PENDING && all_done) {')
            ->line('    /* All already done - collect results as flat list */')
            ->line('    ctx->result_values = (SV**)malloc(count * sizeof(SV*));')
            ->line('    ctx->result_count = 0;')
            ->line('    for (i = 0; i < count; i++) {')
            ->line('        FutureContext *sub = &future_registry[ctx->subfuture_slots[i]];')
            ->line('        if (sub->result_count > 0) {')
            ->line('            ctx->result_values[ctx->result_count++] = SvREFCNT_inc(sub->result_values[0]);')
            ->line('        }')
            ->line('    }')
            ->line('    ctx->state = FUTURE_STATE_DONE;')
            ->line('}')
            ->line('SV *slot_sv = newSViv(new_slot);')
            ->line('SV *self_ref = newRV_noinc(slot_sv);')
            ->line('sv_bless(self_ref, gv_stashpv("Hypersonic::Future", GV_ADD));')
            ->line('/* refcount already 1 from alloc_slot for Perl ref */')
            ->line('ST(0) = sv_2mortal(self_ref);')
            ->xs_return('1')
            ->xs_end;

    $builder->xs_function('xs_future_wait_any')
            ->xs_preamble
            ->line('int i, j;')
            ->line('/* Same as needs_any for now */')
            ->line('if (items < 2) croak("Usage: Hypersonic::Future->wait_any(@futures)");')
            ->line('int new_slot = future_alloc_slot();')
            ->line('if (new_slot < 0) croak("Future registry full");')
            ->line('FutureContext *ctx = &future_registry[new_slot];')
            ->line('int count = items - 1;')
            ->line('ctx->subfuture_slots = (int*)malloc(count * sizeof(int));')
            ->line('ctx->subfuture_count = count;')
            ->line('ctx->subfutures_pending = count;')
            ->line('ctx->convergent_mode = 2;')
            ->line('for (i = 0; i < count; i++) {')
            ->line('    SV *sub_sv = ST(i + 1);')
            ->line('    if (!sv_isobject(sub_sv)) croak("wait_any: argument %d is not a Future", i+1);')
            ->line('    int sub_slot = SvIV(SvRV(sub_sv));')
            ->line('    ctx->subfuture_slots[i] = sub_slot;')
            ->line('    FutureContext *sub = &future_registry[sub_slot];')
            ->line('    if (sub->state == FUTURE_STATE_DONE) {')
            ->line('        if (sub->result_count > 0) {')
            ->line('            ctx->result_values = (SV**)malloc(sub->result_count * sizeof(SV*));')
            ->line('            for (j = 0; j < sub->result_count; j++) {')
            ->line('                ctx->result_values[j] = SvREFCNT_inc(sub->result_values[j]);')
            ->line('            }')
            ->line('            ctx->result_count = sub->result_count;')
            ->line('        }')
            ->line('        ctx->state = FUTURE_STATE_DONE;')
            ->line('        break;')
            ->line('    } else if (sub->state == FUTURE_STATE_PENDING) {')
            ->line('        if (sub->callback_count < MAX_CALLBACKS) {')
            ->line('            FutureCallback *cb = &sub->callbacks[sub->callback_count++];')
            ->line('            cb->type = FUTURE_CB_READY;')
            ->line('            cb->code = NULL;')
            ->line('            cb->target_slot = new_slot;')
            ->line('            ctx->refcount++;')
            ->line('        }')
            ->line('    } else {')
            ->line('        ctx->subfutures_pending--;')
            ->line('    }')
            ->line('}')
            ->line('if (ctx->state == FUTURE_STATE_PENDING && ctx->subfutures_pending == 0) {')
            ->line('    FutureContext *last = &future_registry[ctx->subfuture_slots[count-1]];')
            ->line('    ctx->state = FUTURE_STATE_FAILED;')
            ->line('    if (last->fail_message) ctx->fail_message = strdup(last->fail_message);')
            ->line('    if (last->fail_category) ctx->fail_category = strdup(last->fail_category);')
            ->line('}')
            ->line('SV *slot_sv = newSViv(new_slot);')
            ->line('SV *self_ref = newRV_noinc(slot_sv);')
            ->line('sv_bless(self_ref, gv_stashpv("Hypersonic::Future", GV_ADD));')
            ->line('/* refcount already 1 from alloc_slot for Perl ref */')
            ->line('ST(0) = sv_2mortal(self_ref);')
            ->xs_return('1')
            ->xs_end;

    # Placeholder thread pool functions
    $builder->xs_function('xs_future_submit')
            ->xs_preamble
            ->line('croak("Thread pool not yet implemented");')
            ->xs_return('0')
            ->xs_end;

    $builder->xs_function('xs_future_poll')
            ->xs_preamble
            ->line('croak("Thread pool not yet implemented");')
            ->xs_return('0')
            ->xs_end;

    $builder->xs_function('xs_future_get_notify_fd')
            ->xs_preamble
            ->line('ST(0) = sv_2mortal(newSViv(-1));')
            ->xs_return('1')
            ->xs_end;

    $builder->xs_function('xs_future_process_ready')
            ->xs_preamble
            ->line('ST(0) = sv_2mortal(newSViv(0));')
            ->xs_return('1')
            ->xs_end;

    # DESTROY
    $builder->xs_function('xs_future_destroy')
            ->xs_preamble
            ->line('int i;')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('if (slot >= 0 && slot < MAX_FUTURES) {')
            ->line('    FutureContext *ctx = &future_registry[slot];')
            ->line('    if (ctx->in_use) {')
            ->line('        ctx->refcount--;')
            ->line('        if (ctx->refcount <= 0) {')
            ->line('            /* Decrement refcounts of targets in unfired callbacks */')
            ->line('            for (i = 0; i < ctx->callback_count; i++) {')
            ->line('                FutureCallback *cb = &ctx->callbacks[i];')
            ->line('                if (cb->target_slot >= 0 && cb->target_slot < MAX_FUTURES) {')
            ->line('                    FutureContext *target = &future_registry[cb->target_slot];')
            ->line('                    if (target->in_use) {')
            ->line('                        target->refcount--;')
            ->line('                        if (target->refcount <= 0) future_free_slot(cb->target_slot);')
            ->line('                    }')
            ->line('                }')
            ->line('            }')
            ->line('            /* Decrement parent refcount if we had a cancel_target (chained child) */')
            ->line('            if (ctx->cancel_target >= 0 && ctx->cancel_target < MAX_FUTURES) {')
            ->line('                FutureContext *parent = &future_registry[ctx->cancel_target];')
            ->line('                if (parent->in_use) {')
            ->line('                    parent->refcount--;')
            ->line('                    if (parent->refcount <= 0) future_free_slot(ctx->cancel_target);')
            ->line('                }')
            ->line('            }')
            ->line('            future_free_slot(slot);')
            ->line('        }')
            ->line('    }')
            ->line('}')
            ->xs_return('0')
            ->xs_end;
}


#############################################################################
# Compilation
#############################################################################

sub compile {
    my ($class, %opts) = @_;

    return 1 if $COMPILED;

    require XS::JIT;

    my $cache_dir = $opts{cache_dir} // '_hypersonic_cache/future';
    $MODULE_NAME = 'Hypersonic::Future::XS_' . $$;

    my $builder = XS::JIT::Builder->new;

    # Generate Future code
    $class->generate_c_code($builder, \%opts);

    # Collect functions from Future
    my %functions = %{ $class->get_xs_functions };

    # Include Pool - Future compilation always includes Pool
    require Hypersonic::Future::Pool;
    Hypersonic::Future::Pool->generate_c_code($builder, \%opts);
    %functions = (%functions, %{ Hypersonic::Future::Pool->get_xs_functions });
    $Hypersonic::Future::Pool::COMPILED = 1;

    my $code = $builder->code;

    XS::JIT->compile(
        code      => $code,
        name      => $MODULE_NAME,
        cache_dir => $cache_dir,
        functions => \%functions,
    );

    # Register custom ops to replace method calls at compile time
    $class->_register_ops();
    Hypersonic::Future::Pool->_register_ops();

    # Install direct XS function aliases - eliminates Perl wrapper overhead
    no warnings 'redefine';
    *new = \&_new;
    *new_done = \&_new_done;
    *new_fail = \&_new_fail;

    $COMPILED = 1;
    return 1;
}

#############################################################################
# Minimal Perl API - triggers compilation on first use
# After compile(), these subs are replaced with direct XS bindings
#############################################################################

sub new {
    my $class = shift;
    $class->compile;
    # compile() replaces *new with *_new, so call it again
    return $class->new(@_);
}

sub new_done {
    my $class = shift;
    $class->compile;
    return $class->new_done(@_);
}

sub new_fail {
    my $class = shift;
    $class->compile;
    return $class->new_fail(@_);
}

1;

__END__

=head1 NAME

Hypersonic::Future - High-performance JIT-compiled Future for async operations

=head1 SYNOPSIS

    use Hypersonic::Future;

    # Create a pending future
    my $f = Hypersonic::Future->new;

    # Resolve with values
    $f->done('result', 'data');

    # Or fail
    $f->fail('Error message', 'category');

    # Chaining
    my $f2 = $f->then(sub {
        my @results = @_;
        return process(@results);
    })->catch(sub {
        my ($error, $category) = @_;
        warn "Error: $error";
        return 'default';
    })->finally(sub {
        cleanup();
    });

=head1 DESCRIPTION

C<Hypersonic::Future> is a high-performance Future implementation using
JIT-compiled XS code.

=cut

=head1 BENCHMARK

	======================================================================
	Future Benchmark: Future::XS vs Hypersonic::Future
	======================================================================

	Compiling Hypersonic::Future JIT...
	JIT compilation complete.

	Running each test for 2 CPU seconds...
	(Set BENCH_TIME env var to change)

	Future::XS version: 0.15
	Hypersonic::Future version: 0.06

	----------------------------------------------------------------------
	Test 1: new() - Create pending future
	----------------------------------------------------------------------
				Rate         Future::XS Hypersonic::Future
	Future::XS         6120900/s                 --               -28%
	Hypersonic::Future 8461824/s                38%                 --

	----------------------------------------------------------------------
	Test 2: new() + done() - Create and resolve
	----------------------------------------------------------------------
				Rate         Future::XS Hypersonic::Future
	Future::XS         3261265/s                 --               -52%
	Hypersonic::Future 6796324/s               108%                 --

	----------------------------------------------------------------------
	Test 3: new() + fail() - Create and fail
	----------------------------------------------------------------------
				Rate         Future::XS Hypersonic::Future
	Future::XS         2929449/s                 --               -53%
	Hypersonic::Future 6167596/s               111%                 --

	----------------------------------------------------------------------
	Test 4: is_ready() + is_done() - State checks (resolved)
	----------------------------------------------------------------------
				 Rate         Future::XS Hypersonic::Future
	Future::XS         10586581/s                 --               -29%
	Hypersonic::Future 14908664/s                41%                 --

	----------------------------------------------------------------------
	Test 5: result() - Get result value
	----------------------------------------------------------------------
				 Rate         Future::XS Hypersonic::Future
	Future::XS         10674557/s                 --               -22%
	Hypersonic::Future 13736799/s                29%                 --

	----------------------------------------------------------------------
	Test 6: done() with multiple values (5 args)
	----------------------------------------------------------------------
				Rate         Future::XS Hypersonic::Future
	Future::XS         2705464/s                 --               -55%
	Hypersonic::Future 6002047/s               122%                 --

	----------------------------------------------------------------------
	Test 7: is_failed() - Check failed state
	----------------------------------------------------------------------
				 Rate         Future::XS Hypersonic::Future
	Future::XS          9700482/s                 --               -34%
	Hypersonic::Future 14750291/s                52%                 --

	----------------------------------------------------------------------
	Test 8: failure() - Get failure reason
	----------------------------------------------------------------------
				 Rate         Future::XS Hypersonic::Future
	Future::XS          7323752/s                 --               -36%
	Hypersonic::Future 11436124/s                56%                 --

	======================================================================
	Hypersonic::Future Only Tests (callback operations)
	======================================================================
	(Future::XS 0.15 has wrap_cb issues with callbacks)

	----------------------------------------------------------------------
	Test 9: then() - Chain transformation [Hypersonic only]
	----------------------------------------------------------------------
	Hypersonic::Future:  3 wallclock secs ( 2.06 usr +  0.01 sys =  2.07 CPU) @ 2986523.67/s (n=6182104)

	----------------------------------------------------------------------
	Test 10: on_done() + done() - Callback [Hypersonic only]
	----------------------------------------------------------------------
	Hypersonic::Future:  2 wallclock secs ( 2.54 usr +  0.03 sys =  2.57 CPU) @ 2142030.74/s (n=5505019)

	----------------------------------------------------------------------
	Test 11: then()->catch()->finally() [Hypersonic only]
	----------------------------------------------------------------------
	Hypersonic::Future: 1415799/s (10000 iterations in 0.01 seconds)

	======================================================================
	Benchmark complete!
	======================================================================
