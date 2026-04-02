package Hypersonic::Future::Pool;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use XS::JIT::Builder;
use Hypersonic::Future qw(MAX_FUTURES);
use Hypersonic::JIT::Util;

# Thread pool configuration
use constant {
    MAX_POOLS           => 256,
    DEFAULT_WORKERS     => 8,
    DEFAULT_QUEUE_SIZE  => 4096,
    OP_TYPE_CODE        => 1,
    OP_TYPE_DB_QUERY    => 2,
    OP_TYPE_DB_EXECUTE  => 3,
    POOL_STATE_UNINITIALIZED => 0,
    POOL_STATE_RUNNING       => 1,
    POOL_STATE_SHUTDOWN      => 2,
};

use Exporter 'import';
our @EXPORT_OK = qw(
    MAX_POOLS DEFAULT_WORKERS DEFAULT_QUEUE_SIZE
    OP_TYPE_CODE OP_TYPE_DB_QUERY OP_TYPE_DB_EXECUTE
    POOL_STATE_UNINITIALIZED POOL_STATE_RUNNING POOL_STATE_SHUTDOWN
);

# JIT state - our so Future.pm can set it
our $COMPILED = 0;

sub get_xs_functions {
    return {
        # Lifecycle - instance methods (extract slot from $$self)
        'Hypersonic::Future::Pool::new'            => { source => 'xs_pool_new', is_xs_native => 1 },
        'Hypersonic::Future::Pool::init'           => { source => 'xs_pool_init', is_xs_native => 1 },
        'Hypersonic::Future::Pool::shutdown'       => { source => 'xs_pool_shutdown', is_xs_native => 1 },
        'Hypersonic::Future::Pool::DESTROY'        => { source => 'xs_pool_destroy', is_xs_native => 1 },

        # Operations - instance methods (direct XS, no Perl wrappers)
        'Hypersonic::Future::Pool::submit'         => { source => 'xs_pool_submit', is_xs_native => 1 },
        'Hypersonic::Future::Pool::process_ready'  => { source => 'xs_pool_process_ready', is_xs_native => 1 },

        # State inspection - will have custom OPs
        'Hypersonic::Future::Pool::is_initialized' => { source => 'xs_pool_is_initialized', is_xs_native => 1 },
        'Hypersonic::Future::Pool::pending_count'  => { source => 'xs_pool_pending_count', is_xs_native => 1 },
        'Hypersonic::Future::Pool::get_notify_fd'  => { source => 'xs_pool_get_notify_fd', is_xs_native => 1 },
        'Hypersonic::Future::Pool::workers'        => { source => 'xs_pool_workers', is_xs_native => 1 },
        'Hypersonic::Future::Pool::slot'           => { source => 'xs_pool_slot', is_xs_native => 1 },

        # Global pool helpers (class methods)
        'Hypersonic::Future::Pool::init_global'    => { source => 'xs_pool_init_global', is_xs_native => 1 },
        'Hypersonic::Future::Pool::shutdown_global' => { source => 'xs_pool_shutdown_global', is_xs_native => 1 },
        'Hypersonic::Future::Pool::default_pool'   => { source => 'xs_pool_default_pool', is_xs_native => 1 },

        # Slot-based helpers for event loop (class methods)
        'Hypersonic::Future::Pool::_get_notify_fd_slot'  => { source => 'xs_pool_get_notify_fd_slot', is_xs_native => 1 },
        'Hypersonic::Future::Pool::_process_ready_slot'  => { source => 'xs_pool_process_ready_slot', is_xs_native => 1 },

        # Custom op registration
        'Hypersonic::Future::Pool::_register_ops'  => { source => 'xs_pool_register_ops', is_xs_native => 1 },
    };
}

sub generate_c_code {
    my ($class, $builder, $opts) = @_;

    $opts //= {};
    my $max_pools = $opts->{max_pools} // MAX_POOLS;
    my $inline = Hypersonic::JIT::Util->inline_keyword;

    # PERL_VERSION_* macros are already provided by XS::JIT preamble
    # No need to emit them here

    # System includes via centralized utility
    Hypersonic::JIT::Util->add_standard_includes($builder,
        qw(unistd fcntl threading));

    # Platform-specific eventfd (Linux only)
    Hypersonic::JIT::Util->add_platform_eventfd($builder);

    # Defines
    $builder->line("#define MAX_POOLS $max_pools")
            ->line('#define POOL_STATE_UNINITIALIZED 0')
            ->line('#define POOL_STATE_RUNNING 1')
            ->line('#define POOL_STATE_SHUTDOWN 2')
            ->line('#define OP_TYPE_CODE 1')
            ->line('#define OP_TYPE_DB_QUERY 2')
            ->line('#define OP_TYPE_DB_EXECUTE 3')
            ->blank;

    # ThreadPoolOp - a queued operation
    $builder->line('typedef struct ThreadPoolOp {')
            ->line('    int op_type;')
            ->line('    int future_slot;')
            ->line('    int pool_slot;           /* Which pool owns this op */')
            ->line('    SV *code;                /* For CODE type: coderef to execute */')
            ->line('    SV *args;                /* Arrayref of arguments */')
            ->line('    SV *result;              /* Result after execution */')
            ->line('    char *error;             /* Error message if failed */')
            ->line('    int completed;           /* 1 when done */')
            ->line('    struct ThreadPoolOp *next;')
            ->line('} ThreadPoolOp;')
            ->blank;

    # PoolContext - per-pool state (mirrors FutureContext pattern)
    $builder->line('typedef struct PoolContext {')
            ->line('    int state;               /* POOL_STATE_* */')
            ->line('    int in_use;              /* Slot allocation flag */')
            ->line('    int workers;             /* Number of worker threads */')
            ->line('    int queue_size;          /* Max queue depth */')
            ->line('    pthread_t *threads;      /* Dynamic array of worker handles */')
            ->line('    pthread_mutex_t mutex;')
            ->line('    pthread_cond_t cond;')
            ->line('    pthread_cond_t done_cond;')
            ->line('    ThreadPoolOp *queue_head;')
            ->line('    ThreadPoolOp *queue_tail;')
            ->line('    ThreadPoolOp *completed_head;')
            ->line('    ThreadPoolOp *completed_tail;')
            ->line('    int queue_count;')
            ->line('    int completed_count;')
            ->line('    int notify_fd;')
            ->line('#if !USE_EVENTFD')
            ->line('    int notify_pipe[2];')
            ->line('#endif')
            ->line('} PoolContext;')
            ->blank;

    # Pool registry and freelist (like future_registry)
    $builder->line('static PoolContext pool_registry[MAX_POOLS];')
            ->line('static int pool_freelist[MAX_POOLS];')
            ->line('static int pool_freelist_count = 0;')
            ->line('static int pool_freelist_initialized = 0;')
            ->line('static int default_pool_slot = -1;  /* Global default pool */')
            ->blank;

    # Freelist init
    $builder->line("static $inline void pool_freelist_init(void) {")
            ->line('    int i;')
            ->line('    if (pool_freelist_initialized) return;')
            ->line('    for (i = MAX_POOLS - 1; i >= 0; i--) {')
            ->line('        pool_freelist[pool_freelist_count++] = i;')
            ->line('    }')
            ->line('    pool_freelist_initialized = 1;')
            ->line('}')
            ->blank;

    # Alloc slot
    $builder->line("static $inline int pool_alloc_slot(void) {")
            ->line('    if (!pool_freelist_initialized) pool_freelist_init();')
            ->line('    if (pool_freelist_count > 0) {')
            ->line('        int slot = pool_freelist[--pool_freelist_count];')
            ->line('        PoolContext *ctx = &pool_registry[slot];')
            ->line('        memset(ctx, 0, sizeof(PoolContext));')
            ->line('        ctx->in_use = 1;')
            ->line('        ctx->state = POOL_STATE_UNINITIALIZED;')
            ->line('        return slot;')
            ->line('    }')
            ->line('    return -1;')
            ->line('}')
            ->blank;

    # Free slot
    $builder->line('static void pool_free_slot(int slot) {')
            ->line('    if (slot < 0 || slot >= MAX_POOLS) return;')
            ->line('    PoolContext *ctx = &pool_registry[slot];')
            ->line('    if (!ctx->in_use) return;')
            ->line('    if (ctx->threads) {')
            ->line('        free(ctx->threads);')
            ->line('        ctx->threads = NULL;')
            ->line('    }')
            ->line('    ctx->in_use = 0;')
            ->line('    if (pool_freelist_count < MAX_POOLS) {')
            ->line('        pool_freelist[pool_freelist_count++] = slot;')
            ->line('    }')
            ->line('}')
            ->blank;

    # Helper: signal completion for a specific pool
    $builder->line('static void pool_signal_completion_slot(int slot) {')
            ->line('    PoolContext *pool = &pool_registry[slot];')
            ->line('#if USE_EVENTFD')
            ->line('    uint64_t val = 1;')
            ->line('    write(pool->notify_fd, &val, sizeof(val));')
            ->line('#else')
            ->line('    char c = 1;')
            ->line('    write(pool->notify_pipe[1], &c, 1);')
            ->line('#endif')
            ->line('}')
            ->blank;

    # Helper: clear notification for a specific pool
    $builder->line('static void pool_clear_notification_slot(int slot) {')
            ->line('    PoolContext *pool = &pool_registry[slot];')
            ->line('#if USE_EVENTFD')
            ->line('    uint64_t val;')
            ->line('    read(pool->notify_fd, &val, sizeof(val));')
            ->line('#else')
            ->line('    char buf[64];')
            ->line('    while (read(pool->notify_pipe[0], buf, sizeof(buf)) > 0) {}')
            ->line('#endif')
            ->line('}')
            ->blank;

    # Helper: get notify_fd for a pool slot (for event loop integration)
    $builder->line('static int pool_get_notify_fd_slot(int slot) {')
            ->line('    if (slot < 0 || slot >= MAX_POOLS) return -1;')
            ->line('    PoolContext *pool = &pool_registry[slot];')
            ->line('    if (pool->state != POOL_STATE_RUNNING) return -1;')
            ->line('    return pool->notify_fd;')
            ->line('}')
            ->blank;

    # Helper: process ready operations for a pool slot (for event loop integration)
    # This is a simplified version that just clears notification - actual processing
    # should be done via XS to properly handle Perl callbacks
    $builder->line('static void pool_process_ready_slot(int slot) {')
            ->line('    if (slot < 0 || slot >= MAX_POOLS) return;')
            ->line('    PoolContext *pool = &pool_registry[slot];')
            ->line('    if (pool->state != POOL_STATE_RUNNING) return;')
            ->line('    pool_clear_notification_slot(slot);')
            ->line('}')
            ->blank;

    # Worker thread function - takes pool_slot as argument
    # Fixed: wait while NOT shutdown AND no work (handles UNINITIALIZED state too)
    $builder->line('static void* pool_worker_fn(void *arg) {')
            ->line('    int pool_slot = (int)(intptr_t)arg;')
            ->line('    PoolContext *pool = &pool_registry[pool_slot];')
            ->line('    while (1) {')
            ->line('        ThreadPoolOp *op = NULL;')
            ->line('        pthread_mutex_lock(&pool->mutex);')
            ->line('        /* Wait while not shutdown and no work available */')
            ->line('        while (pool->state != POOL_STATE_SHUTDOWN && !pool->queue_head) {')
            ->line('            pthread_cond_wait(&pool->cond, &pool->mutex);')
            ->line('        }')
            ->line('        /* Exit if shutdown and queue empty */')
            ->line('        if (pool->state == POOL_STATE_SHUTDOWN && !pool->queue_head) {')
            ->line('            pthread_mutex_unlock(&pool->mutex);')
            ->line('            break;')
            ->line('        }')
            ->line('        /* Dequeue */')
            ->line('        op = pool->queue_head;')
            ->line('        pool->queue_head = op->next;')
            ->line('        if (!pool->queue_head) pool->queue_tail = NULL;')
            ->line('        pool->queue_count--;')
            ->line('        op->next = NULL;')
            ->line('        /* Move to completed queue */')
            ->line('        if (pool->completed_tail) {')
            ->line('            pool->completed_tail->next = op;')
            ->line('        } else {')
            ->line('            pool->completed_head = op;')
            ->line('        }')
            ->line('        pool->completed_tail = op;')
            ->line('        pool->completed_count++;')
            ->line('        pthread_mutex_unlock(&pool->mutex);')
            ->line('        /* Notify main thread */')
            ->line('        pool_signal_completion_slot(pool_slot);')
            ->line('    }')
            ->line('    return NULL;')
            ->line('}')
            ->blank;

    # Generate custom OPs for hot-path methods (disabled for debugging)
    # $class->_gen_custom_ops($builder);

    # Generate XS functions
    $class->_gen_xs_functions($builder);

    # Placeholder _register_ops that does nothing
    $builder->xs_function('xs_pool_register_ops')
            ->xs_preamble
            ->xs_return('0')
            ->xs_end;
}

sub _gen_custom_ops {
    my ($class, $builder) = @_;

    # Custom OP: pp_pool_is_initialized
    $builder->line('static OP* pp_pool_is_initialized(pTHX) {')
            ->line('    dSP;')
            ->line('    SV* self = TOPs;')
            ->line('    int slot = SvIV(SvRV(self));')
            ->line('    SETs(boolSV(pool_registry[slot].state == POOL_STATE_RUNNING));')
            ->line('    return NORMAL;')
            ->line('}')
            ->blank;

    # Custom OP: pp_pool_pending_count
    $builder->line('static OP* pp_pool_pending_count(pTHX) {')
            ->line('    dSP;')
            ->line('    SV* self = TOPs;')
            ->line('    int slot = SvIV(SvRV(self));')
            ->line('    PoolContext *pool = &pool_registry[slot];')
            ->line('    pthread_mutex_lock(&pool->mutex);')
            ->line('    int count = pool->queue_count + pool->completed_count;')
            ->line('    pthread_mutex_unlock(&pool->mutex);')
            ->line('    SETs(sv_2mortal(newSViv(count)));')
            ->line('    return NORMAL;')
            ->line('}')
            ->blank;

    # XOP declarations
    $builder->xop_declare('pool_is_initialized_xop', 'pp_pool_is_initialized', 'pool is_initialized')
            ->xop_declare('pool_pending_count_xop', 'pp_pool_pending_count', 'pool pending_count');

    # Call checkers - generate the S_ck_ck_* functions
    $builder->ck_start('ck_pool_is_initialized')
            ->ck_preamble
            ->ck_build_unop('pp_pool_is_initialized', '0')
            ->ck_end;

    $builder->ck_start('ck_pool_pending_count')
            ->ck_preamble
            ->ck_build_unop('pp_pool_pending_count', '0')
            ->ck_end;

    # Call checker registration function
    # cv_set_call_checker requires Perl 5.14+ - check at JIT time, not C compile time
    $builder->xs_function('xs_pool_register_ops')
            ->xs_preamble
            ->line('register_xop_pool_is_initialized_xop(aTHX);')
            ->line('register_xop_pool_pending_count_xop(aTHX);');

    # JIT optimization: only emit cv_set_call_checker code if Perl >= 5.14
    # This eliminates dead code from the generated C file on older Perls
    if ($] >= 5.014000) {
        $builder->line('{')
                ->line('    CV *cv;')
                ->line('    cv = get_cv("Hypersonic::Future::Pool::is_initialized", 0);')
                ->line('    if (cv) cv_set_call_checker(cv, S_ck_ck_pool_is_initialized, &PL_sv_undef);')
                ->line('    cv = get_cv("Hypersonic::Future::Pool::pending_count", 0);')
                ->line('    if (cv) cv_set_call_checker(cv, S_ck_ck_pool_pending_count, &PL_sv_undef);')
                ->line('}');
    }

    $builder->xs_return('0')
            ->xs_end;
}

sub _gen_xs_functions {
    my ($class, $builder) = @_;

    # XS: new - allocate slot and return blessed IV ref
    # Usage: Pool->new() or Pool->new(workers => N, queue_size => N)
    $builder->xs_function('xs_pool_new')
            ->xs_preamble
            ->line('int workers = 8;      /* default */')
            ->line('int queue_size = 4096; /* default */')
            ->line('/* Parse named parameters */')
            ->line('int i;')
            ->line('for (i = 1; i < items - 1; i += 2) {')
            ->line('    const char *key = SvPV_nolen(ST(i));')
            ->line('    SV *val = ST(i + 1);')
            ->line('    if (strEQ(key, "workers")) workers = SvIV(val);')
            ->line('    else if (strEQ(key, "queue_size")) queue_size = SvIV(val);')
            ->line('}')
            ->line('int slot = pool_alloc_slot();')
            ->line('if (slot < 0) croak("Pool registry full (max %d pools)", MAX_POOLS);')
            ->line('PoolContext *ctx = &pool_registry[slot];')
            ->line('ctx->workers = workers;')
            ->line('ctx->queue_size = queue_size;')
            ->line('SV *slot_sv = newSViv(slot);')
            ->line('SV *self_ref = newRV_noinc(slot_sv);')
            ->line('sv_bless(self_ref, gv_stashpv("Hypersonic::Future::Pool", GV_ADD));')
            ->line('ST(0) = sv_2mortal(self_ref);')
            ->xs_return('1')
            ->xs_end;

    # XS: init - initialize the pool (instance method)
    $builder->xs_function('xs_pool_init')
            ->xs_preamble
            ->line('int i;')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('PoolContext *pool = &pool_registry[slot];')
            ->line('if (pool->state == POOL_STATE_RUNNING) {')
            ->line('    ST(0) = sv_2mortal(newSViv(1));')
            ->line('    XSRETURN(1);')
            ->line('}')
            ->line('pthread_mutex_init(&pool->mutex, NULL);')
            ->line('pthread_cond_init(&pool->cond, NULL);')
            ->line('pthread_cond_init(&pool->done_cond, NULL);')
            ->line('#if USE_EVENTFD')
            ->line('pool->notify_fd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);')
            ->line('if (pool->notify_fd < 0) croak("eventfd() failed");')
            ->line('#else')
            ->line('if (pipe(pool->notify_pipe) < 0) croak("pipe() failed");')
            ->line('fcntl(pool->notify_pipe[0], F_SETFL, O_NONBLOCK);')
            ->line('fcntl(pool->notify_pipe[1], F_SETFL, O_NONBLOCK);')
            ->line('pool->notify_fd = pool->notify_pipe[0];')
            ->line('#endif')
            ->line('pool->threads = (pthread_t*)malloc(pool->workers * sizeof(pthread_t));')
            ->line('if (!pool->threads) croak("malloc failed for threads");')
            ->line('pool->state = POOL_STATE_RUNNING;  /* Set BEFORE creating threads */')
            ->line('for (i = 0; i < pool->workers; i++) {')
            ->line('    if (pthread_create(&pool->threads[i], NULL, pool_worker_fn, (void*)(intptr_t)slot) != 0) {')
            ->line('        croak("pthread_create failed");')
            ->line('    }')
            ->line('}')
            ->line('ST(0) = sv_2mortal(newSViv(1));')
            ->xs_return('1')
            ->xs_end;

    # XS: shutdown - shutdown the pool (instance method)
    $builder->xs_function('xs_pool_shutdown')
            ->xs_preamble
            ->line('int i;')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('PoolContext *pool = &pool_registry[slot];')
            ->line('if (pool->state != POOL_STATE_RUNNING) {')
            ->line('    ST(0) = sv_2mortal(newSViv(0));')
            ->line('    XSRETURN(1);')
            ->line('}')
            ->line('pthread_mutex_lock(&pool->mutex);')
            ->line('pool->state = POOL_STATE_SHUTDOWN;')
            ->line('pthread_cond_broadcast(&pool->cond);')
            ->line('pthread_mutex_unlock(&pool->mutex);')
            ->line('for (i = 0; i < pool->workers; i++) {')
            ->line('    pthread_join(pool->threads[i], NULL);')
            ->line('}')
            ->line('#if USE_EVENTFD')
            ->line('close(pool->notify_fd);')
            ->line('#else')
            ->line('close(pool->notify_pipe[0]);')
            ->line('close(pool->notify_pipe[1]);')
            ->line('#endif')
            ->line('pthread_mutex_destroy(&pool->mutex);')
            ->line('pthread_cond_destroy(&pool->cond);')
            ->line('pthread_cond_destroy(&pool->done_cond);')
            ->line('ST(0) = sv_2mortal(newSViv(1));')
            ->xs_return('1')
            ->xs_end;

    # XS: DESTROY - cleanup on destruction
    # Skip cleanup during global destruction (PL_dirty) - let OS clean up threads
    $builder->xs_function('xs_pool_destroy')
            ->xs_preamble
            ->line('int i;')
            ->line('/* Skip during global destruction - pthread_join can hang/crash */')
            ->line('if (PL_dirty) XSRETURN(0);')
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('if (slot >= 0 && slot < MAX_POOLS) {')
            ->line('    PoolContext *pool = &pool_registry[slot];')
            ->line('    if (pool->in_use && pool->state == POOL_STATE_RUNNING) {')
            ->line('        /* Auto-shutdown on destruction */')
            ->line('        pthread_mutex_lock(&pool->mutex);')
            ->line('        pool->state = POOL_STATE_SHUTDOWN;')
            ->line('        pthread_cond_broadcast(&pool->cond);')
            ->line('        pthread_mutex_unlock(&pool->mutex);')
            ->line('        for (i = 0; i < pool->workers; i++) {')
            ->line('            pthread_join(pool->threads[i], NULL);')
            ->line('        }')
            ->line('#if USE_EVENTFD')
            ->line('        close(pool->notify_fd);')
            ->line('#else')
            ->line('        close(pool->notify_pipe[0]);')
            ->line('        close(pool->notify_pipe[1]);')
            ->line('#endif')
            ->line('        pthread_mutex_destroy(&pool->mutex);')
            ->line('        pthread_cond_destroy(&pool->cond);')
            ->line('        pthread_cond_destroy(&pool->done_cond);')
            ->line('    }')
            ->line('    pool_free_slot(slot);')
            ->line('}')
            ->xs_return('0')
            ->xs_end;

    # XS: submit - queue an operation (instance method)
    # Usage: $pool->submit($future, $code, $args_aref)
    # $future can be a Future object or an integer slot
    $builder->xs_function('xs_pool_submit')
            ->xs_preamble
            ->line('if (items < 3) croak("Usage: $pool->submit($future, $code, $args_aref)");')
            ->line('int pool_slot = SvIV(SvRV(ST(0)));')
            ->line('PoolContext *pool = &pool_registry[pool_slot];')
            ->line('if (pool->state != POOL_STATE_RUNNING) croak("Pool not initialized");')
            ->line('/* Extract future slot - accept Future object or integer */')
            ->line('int future_slot;')
            ->line('SV *future_sv = ST(1);')
            ->line('if (SvROK(future_sv) && sv_derived_from(future_sv, "Hypersonic::Future")) {')
            ->line('    future_slot = SvIV(SvRV(future_sv));')
            ->line('} else {')
            ->line('    future_slot = SvIV(future_sv);')
            ->line('}')
            ->line('SV *code = ST(2);')
            ->line('SV *args = (items > 3) ? ST(3) : NULL;')
            ->line('ThreadPoolOp *op = (ThreadPoolOp*)calloc(1, sizeof(ThreadPoolOp));')
            ->line('if (!op) croak("malloc failed");')
            ->line('op->op_type = OP_TYPE_CODE;')
            ->line('op->future_slot = future_slot;')
            ->line('op->pool_slot = pool_slot;')
            ->line('op->code = SvREFCNT_inc(code);')
            ->line('if (args) op->args = SvREFCNT_inc(args);')
            ->line('pthread_mutex_lock(&pool->mutex);')
            ->line('if (pool->queue_tail) {')
            ->line('    pool->queue_tail->next = op;')
            ->line('} else {')
            ->line('    pool->queue_head = op;')
            ->line('}')
            ->line('pool->queue_tail = op;')
            ->line('pool->queue_count++;')
            ->line('pthread_cond_signal(&pool->cond);')
            ->line('pthread_mutex_unlock(&pool->mutex);')
            ->line('ST(0) = sv_2mortal(newSViv(1));')
            ->xs_return('1')
            ->xs_end;

    # XS: process_ready - process completed ops (instance method)
    $builder->xs_function('xs_pool_process_ready')
            ->xs_preamble
            ->line('int i;')
            ->line('int pool_slot = SvIV(SvRV(ST(0)));')
            ->line('PoolContext *pool = &pool_registry[pool_slot];')
            ->line('if (pool->state != POOL_STATE_RUNNING) { ST(0) = sv_2mortal(newSViv(0)); XSRETURN(1); }')
            ->line('pool_clear_notification_slot(pool_slot);')
            ->line('int processed = 0;')
            ->line('while (1) {')
            ->line('    ThreadPoolOp *op = NULL;')
            ->line('    pthread_mutex_lock(&pool->mutex);')
            ->line('    if (pool->completed_head) {')
            ->line('        op = pool->completed_head;')
            ->line('        pool->completed_head = op->next;')
            ->line('        if (!pool->completed_head) pool->completed_tail = NULL;')
            ->line('        pool->completed_count--;')
            ->line('    }')
            ->line('    pthread_mutex_unlock(&pool->mutex);')
            ->line('    if (!op) break;')
            ->line('    /* Execute the code in main Perl thread */')
            ->line('    dSP;')
            ->line('    ENTER; SAVETMPS;')
            ->line('    PUSHMARK(SP);')
            ->line('    if (op->args && SvROK(op->args)) {')
            ->line('        AV *args_av = (AV*)SvRV(op->args);')
            ->line('        int len = av_len(args_av) + 1;')
            ->line('        for (i = 0; i < len; i++) {')
            ->line('            SV **elem = av_fetch(args_av, i, 0);')
            ->line('            if (elem) XPUSHs(*elem);')
            ->line('        }')
            ->line('    }')
            ->line('    PUTBACK;')
            ->line('    int count = call_sv(op->code, G_EVAL | G_ARRAY);')
            ->line('    SPAGAIN;')
            ->line('    SV *errsv = ERRSV;')
            ->line('    /* Access future registry directly */')
            ->line('    extern FutureContext future_registry[];')
            ->line('    extern void future_invoke_callbacks(int, int);')
            ->line('    FutureContext *ctx = &future_registry[op->future_slot];')
            ->line('    if (SvTRUE(errsv)) {')
            ->line('        STRLEN len;')
            ->line('        const char *msg = SvPV(errsv, len);')
            ->line('        ctx->fail_message = (char*)malloc(len + 1);')
            ->line('        memcpy(ctx->fail_message, msg, len);')
            ->line('        ctx->fail_message[len] = 0;')
            ->line('        ctx->state = FUTURE_STATE_FAILED;')
            ->line('        while (count-- > 0) POPs;')
            ->line('        PUTBACK;')
            ->line('        FREETMPS; LEAVE;')
            ->line('        future_invoke_callbacks(op->future_slot, FUTURE_CB_FAIL);')
            ->line('    } else if (count > 0) {')
            ->line('        ctx->result_values = (SV**)malloc(count * sizeof(SV*));')
            ->line('        for (i = count - 1; i >= 0; i--) {')
            ->line('            ctx->result_values[i] = SvREFCNT_inc(POPs);')
            ->line('        }')
            ->line('        ctx->result_count = count;')
            ->line('        ctx->state = FUTURE_STATE_DONE;')
            ->line('        PUTBACK;')
            ->line('        FREETMPS; LEAVE;')
            ->line('        future_invoke_callbacks(op->future_slot, FUTURE_CB_DONE);')
            ->line('    } else {')
            ->line('        ctx->state = FUTURE_STATE_DONE;')
            ->line('        PUTBACK;')
            ->line('        FREETMPS; LEAVE;')
            ->line('        future_invoke_callbacks(op->future_slot, FUTURE_CB_DONE);')
            ->line('    }')
            ->line('    if (op->code) SvREFCNT_dec(op->code);')
            ->line('    if (op->args) SvREFCNT_dec(op->args);')
            ->line('    free(op);')
            ->line('    processed++;')
            ->line('}')
            ->line('ST(0) = sv_2mortal(newSViv(processed));')
            ->xs_return('1')
            ->xs_end;

    # XS: is_initialized (instance method - also has custom OP)
    $builder->xs_function('xs_pool_is_initialized')
            ->xs_preamble
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('ST(0) = boolSV(pool_registry[slot].state == POOL_STATE_RUNNING);')
            ->xs_return('1')
            ->xs_end;

    # XS: pending_count (instance method - also has custom OP)
    $builder->xs_function('xs_pool_pending_count')
            ->xs_preamble
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('PoolContext *pool = &pool_registry[slot];')
            ->line('if (pool->state != POOL_STATE_RUNNING) { ST(0) = sv_2mortal(newSViv(0)); XSRETURN(1); }')
            ->line('pthread_mutex_lock(&pool->mutex);')
            ->line('int count = pool->queue_count + pool->completed_count;')
            ->line('pthread_mutex_unlock(&pool->mutex);')
            ->line('ST(0) = sv_2mortal(newSViv(count));')
            ->xs_return('1')
            ->xs_end;

    # XS: get_notify_fd (instance method)
    $builder->xs_function('xs_pool_get_notify_fd')
            ->xs_preamble
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('PoolContext *pool = &pool_registry[slot];')
            ->line('if (pool->state != POOL_STATE_RUNNING) { ST(0) = sv_2mortal(newSViv(-1)); XSRETURN(1); }')
            ->line('ST(0) = sv_2mortal(newSViv(pool->notify_fd));')
            ->xs_return('1')
            ->xs_end;

    # XS: workers (instance method)
    $builder->xs_function('xs_pool_workers')
            ->xs_preamble
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('ST(0) = sv_2mortal(newSViv(pool_registry[slot].workers));')
            ->xs_return('1')
            ->xs_end;

    # XS: slot (instance method - returns the slot number)
    $builder->xs_function('xs_pool_slot')
            ->xs_preamble
            ->line('int slot = SvIV(SvRV(ST(0)));')
            ->line('ST(0) = sv_2mortal(newSViv(slot));')
            ->xs_return('1')
            ->xs_end;

    # XS: get_notify_fd_slot (class method for event loop)
    $builder->xs_function('xs_pool_get_notify_fd_slot')
            ->xs_preamble
            ->line('if (items < 2) croak("Usage: Pool->_get_notify_fd_slot($slot)");')
            ->line('int slot = SvIV(ST(1));')
            ->line('if (slot < 0 || slot >= MAX_POOLS) { ST(0) = sv_2mortal(newSViv(-1)); XSRETURN(1); }')
            ->line('PoolContext *pool = &pool_registry[slot];')
            ->line('if (pool->state != POOL_STATE_RUNNING) { ST(0) = sv_2mortal(newSViv(-1)); XSRETURN(1); }')
            ->line('ST(0) = sv_2mortal(newSViv(pool->notify_fd));')
            ->xs_return('1')
            ->xs_end;

    # XS: process_ready_slot (class method for event loop)
    $builder->xs_function('xs_pool_process_ready_slot')
            ->xs_preamble
            ->line('int i;')
            ->line('if (items < 2) croak("Usage: Pool->_process_ready_slot($slot)");')
            ->line('int pool_slot = SvIV(ST(1));')
            ->line('if (pool_slot < 0 || pool_slot >= MAX_POOLS) { ST(0) = sv_2mortal(newSViv(0)); XSRETURN(1); }')
            ->line('PoolContext *pool = &pool_registry[pool_slot];')
            ->line('if (pool->state != POOL_STATE_RUNNING) { ST(0) = sv_2mortal(newSViv(0)); XSRETURN(1); }')
            ->line('pool_clear_notification_slot(pool_slot);')
            ->line('int processed = 0;')
            ->line('while (1) {')
            ->line('    ThreadPoolOp *op = NULL;')
            ->line('    pthread_mutex_lock(&pool->mutex);')
            ->line('    if (pool->completed_head) {')
            ->line('        op = pool->completed_head;')
            ->line('        pool->completed_head = op->next;')
            ->line('        if (!pool->completed_head) pool->completed_tail = NULL;')
            ->line('        pool->completed_count--;')
            ->line('    }')
            ->line('    pthread_mutex_unlock(&pool->mutex);')
            ->line('    if (!op) break;')
            ->line('    dSP;')
            ->line('    ENTER; SAVETMPS;')
            ->line('    PUSHMARK(SP);')
            ->line('    if (op->args && SvROK(op->args)) {')
            ->line('        AV *args_av = (AV*)SvRV(op->args);')
            ->line('        int len = av_len(args_av) + 1;')
            ->line('        for (i = 0; i < len; i++) {')
            ->line('            SV **elem = av_fetch(args_av, i, 0);')
            ->line('            if (elem) XPUSHs(*elem);')
            ->line('        }')
            ->line('    }')
            ->line('    PUTBACK;')
            ->line('    int count = call_sv(op->code, G_EVAL | G_ARRAY);')
            ->line('    SPAGAIN;')
            ->line('    SV *errsv = ERRSV;')
            ->line('    extern FutureContext future_registry[];')
            ->line('    extern void future_invoke_callbacks(int, int);')
            ->line('    FutureContext *ctx = &future_registry[op->future_slot];')
            ->line('    if (SvTRUE(errsv)) {')
            ->line('        STRLEN len;')
            ->line('        const char *msg = SvPV(errsv, len);')
            ->line('        ctx->fail_message = (char*)malloc(len + 1);')
            ->line('        memcpy(ctx->fail_message, msg, len);')
            ->line('        ctx->fail_message[len] = 0;')
            ->line('        ctx->state = FUTURE_STATE_FAILED;')
            ->line('        while (count-- > 0) POPs;')
            ->line('        PUTBACK;')
            ->line('        FREETMPS; LEAVE;')
            ->line('        future_invoke_callbacks(op->future_slot, FUTURE_CB_FAIL);')
            ->line('    } else if (count > 0) {')
            ->line('        ctx->result_values = (SV**)malloc(count * sizeof(SV*));')
            ->line('        for (i = count - 1; i >= 0; i--) {')
            ->line('            ctx->result_values[i] = SvREFCNT_inc(POPs);')
            ->line('        }')
            ->line('        ctx->result_count = count;')
            ->line('        ctx->state = FUTURE_STATE_DONE;')
            ->line('        PUTBACK;')
            ->line('        FREETMPS; LEAVE;')
            ->line('        future_invoke_callbacks(op->future_slot, FUTURE_CB_DONE);')
            ->line('    } else {')
            ->line('        ctx->state = FUTURE_STATE_DONE;')
            ->line('        PUTBACK;')
            ->line('        FREETMPS; LEAVE;')
            ->line('        future_invoke_callbacks(op->future_slot, FUTURE_CB_DONE);')
            ->line('    }')
            ->line('    if (op->code) SvREFCNT_dec(op->code);')
            ->line('    if (op->args) SvREFCNT_dec(op->args);')
            ->line('    free(op);')
            ->line('    processed++;')
            ->line('}')
            ->line('ST(0) = sv_2mortal(newSViv(processed));')
            ->xs_return('1')
            ->xs_end;

    # XS: init_global - create/init default pool (class method)
    # Usage: Pool->init_global() or Pool->init_global(workers => N)
    $builder->xs_function('xs_pool_init_global')
            ->xs_preamble
            ->line('/* If default pool exists and is running, return it */')
            ->line('if (default_pool_slot >= 0) {')
            ->line('    PoolContext *pool = &pool_registry[default_pool_slot];')
            ->line('    if (pool->in_use && pool->state == POOL_STATE_RUNNING) {')
            ->line('        SV *slot_sv = newSViv(default_pool_slot);')
            ->line('        SV *self_ref = newRV_noinc(slot_sv);')
            ->line('        sv_bless(self_ref, gv_stashpv("Hypersonic::Future::Pool", GV_ADD));')
            ->line('        ST(0) = sv_2mortal(self_ref);')
            ->line('        XSRETURN(1);')
            ->line('    }')
            ->line('}')
            ->line('/* Parse named parameters */')
            ->line('int workers = 8;')
            ->line('int queue_size = 4096;')
            ->line('int i;')
            ->line('for (i = 1; i < items - 1; i += 2) {')
            ->line('    const char *key = SvPV_nolen(ST(i));')
            ->line('    SV *val = ST(i + 1);')
            ->line('    if (strEQ(key, "workers")) workers = SvIV(val);')
            ->line('    else if (strEQ(key, "queue_size")) queue_size = SvIV(val);')
            ->line('}')
            ->line('/* Allocate slot */')
            ->line('int slot = pool_alloc_slot();')
            ->line('if (slot < 0) croak("Pool registry full (max %d pools)", MAX_POOLS);')
            ->line('default_pool_slot = slot;')
            ->line('PoolContext *pool = &pool_registry[slot];')
            ->line('pool->workers = workers;')
            ->line('pool->queue_size = queue_size;')
            ->line('/* Initialize pool */')
            ->line('pthread_mutex_init(&pool->mutex, NULL);')
            ->line('pthread_cond_init(&pool->cond, NULL);')
            ->line('pthread_cond_init(&pool->done_cond, NULL);')
            ->line('#if USE_EVENTFD')
            ->line('pool->notify_fd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);')
            ->line('if (pool->notify_fd < 0) croak("eventfd() failed");')
            ->line('#else')
            ->line('if (pipe(pool->notify_pipe) < 0) croak("pipe() failed");')
            ->line('fcntl(pool->notify_pipe[0], F_SETFL, O_NONBLOCK);')
            ->line('fcntl(pool->notify_pipe[1], F_SETFL, O_NONBLOCK);')
            ->line('pool->notify_fd = pool->notify_pipe[0];')
            ->line('#endif')
            ->line('pool->threads = (pthread_t*)malloc(pool->workers * sizeof(pthread_t));')
            ->line('if (!pool->threads) croak("malloc failed for threads");')
            ->line('pool->state = POOL_STATE_RUNNING;')
            ->line('for (i = 0; i < pool->workers; i++) {')
            ->line('    if (pthread_create(&pool->threads[i], NULL, pool_worker_fn, (void*)(intptr_t)slot) != 0) {')
            ->line('        croak("pthread_create failed");')
            ->line('    }')
            ->line('}')
            ->line('SV *slot_sv = newSViv(slot);')
            ->line('SV *self_ref = newRV_noinc(slot_sv);')
            ->line('sv_bless(self_ref, gv_stashpv("Hypersonic::Future::Pool", GV_ADD));')
            ->line('ST(0) = sv_2mortal(self_ref);')
            ->xs_return('1')
            ->xs_end;

    # XS: shutdown_global - shutdown default pool (class method)
    $builder->xs_function('xs_pool_shutdown_global')
            ->xs_preamble
            ->line('int i;')
            ->line('if (default_pool_slot < 0) {')
            ->line('    ST(0) = sv_2mortal(newSViv(0));')
            ->line('    XSRETURN(1);')
            ->line('}')
            ->line('PoolContext *pool = &pool_registry[default_pool_slot];')
            ->line('if (pool->state != POOL_STATE_RUNNING) {')
            ->line('    ST(0) = sv_2mortal(newSViv(0));')
            ->line('    XSRETURN(1);')
            ->line('}')
            ->line('pthread_mutex_lock(&pool->mutex);')
            ->line('pool->state = POOL_STATE_SHUTDOWN;')
            ->line('pthread_cond_broadcast(&pool->cond);')
            ->line('pthread_mutex_unlock(&pool->mutex);')
            ->line('for (i = 0; i < pool->workers; i++) {')
            ->line('    pthread_join(pool->threads[i], NULL);')
            ->line('}')
            ->line('#if USE_EVENTFD')
            ->line('close(pool->notify_fd);')
            ->line('#else')
            ->line('close(pool->notify_pipe[0]);')
            ->line('close(pool->notify_pipe[1]);')
            ->line('#endif')
            ->line('pthread_mutex_destroy(&pool->mutex);')
            ->line('pthread_cond_destroy(&pool->cond);')
            ->line('pthread_cond_destroy(&pool->done_cond);')
            ->line('pool_free_slot(default_pool_slot);')
            ->line('default_pool_slot = -1;')
            ->line('ST(0) = sv_2mortal(newSViv(1));')
            ->xs_return('1')
            ->xs_end;

    # XS: default_pool - get default pool (class method)
    $builder->xs_function('xs_pool_default_pool')
            ->xs_preamble
            ->line('if (default_pool_slot < 0) {')
            ->line('    ST(0) = &PL_sv_undef;')
            ->line('    XSRETURN(1);')
            ->line('}')
            ->line('PoolContext *pool = &pool_registry[default_pool_slot];')
            ->line('if (!pool->in_use) {')
            ->line('    ST(0) = &PL_sv_undef;')
            ->line('    XSRETURN(1);')
            ->line('}')
            ->line('SV *slot_sv = newSViv(default_pool_slot);')
            ->line('SV *self_ref = newRV_noinc(slot_sv);')
            ->line('sv_bless(self_ref, gv_stashpv("Hypersonic::Future::Pool", GV_ADD));')
            ->line('ST(0) = sv_2mortal(self_ref);')
            ->xs_return('1')
            ->xs_end;
}

sub compile {
    my ($class, %opts) = @_;

    return 1 if $COMPILED;

    # Pool is compiled together with Future - just call Future's compile
    Hypersonic::Future->compile(%opts);

    return 1;
}

# All methods are XS - see get_xs_functions:
# new, init, shutdown, DESTROY
# submit, process_ready
# is_initialized, pending_count, get_notify_fd, workers, slot
# init_global, shutdown_global, default_pool

1;

__END__

=head1 NAME

Hypersonic::Future::Pool - Thread pool for async operations (OO interface)

=head1 SYNOPSIS

    use Hypersonic::Future::Pool;
    use Hypersonic::Future;

    # Create multiple pools with different configurations
    my $fast_pool = Hypersonic::Future::Pool->new(workers => 8);
    my $slow_pool = Hypersonic::Future::Pool->new(workers => 2);

    # Initialize pools
    $fast_pool->init;
    $slow_pool->init;

    # Submit work to specific pools
    my $f1 = Hypersonic::Future->new;
    my $f2 = Hypersonic::Future->new;

    $fast_pool->submit($f1, sub { quick_operation() });
    $slow_pool->submit($f2, sub { slow_operation() });

    # Check pool status (custom OPs - zero dispatch overhead)
    say "Fast pool pending: " . $fast_pool->pending_count;
    say "Slow pool initialized: " . $slow_pool->is_initialized;

    # Process completed work (in event loop)
    my $fd = $fast_pool->get_notify_fd;
    # When fd is readable:
    $fast_pool->process_ready;

    # Cleanup
    $fast_pool->shutdown;
    $slow_pool->shutdown;

    # Or use backward-compatible class methods
    Hypersonic::Future::Pool->init_global(workers => 4);
    my $pool = Hypersonic::Future::Pool->default_pool;

=head1 DESCRIPTION

C<Hypersonic::Future::Pool> provides thread pools for offloading blocking
operations. Each pool has its own worker threads, notify fd, and queues.

Objects are blessed references to integer slots in a C registry, following
the same pattern as C<Hypersonic::Future>. Hot-path methods like
C<is_initialized> and C<pending_count> use custom OPs for zero dispatch
overhead.

=head1 METHODS

=head2 new(%opts)

Create a new pool. Options:

=over 4

=item workers => N

Number of worker threads (default: 8)

=item queue_size => N

Maximum queue depth (default: 4096)

=back

=head2 init

Initialize the pool (start worker threads).

=head2 shutdown

Shutdown the pool (stop worker threads).

=head2 submit($future, $code, $args)

Submit work to be executed. The code runs in the main thread when a
worker signals completion.

=head2 process_ready

Process completed operations, invoking Future callbacks.

=head2 is_initialized

Check if pool is running. Uses custom OP.

=head2 pending_count

Get count of pending operations. Uses custom OP.

=head2 get_notify_fd

Get the file descriptor for event loop integration.

=head2 workers

Get the number of worker threads.

=head2 slot

Get the internal slot number (for event loop integration).

=cut
