#include "bootstrap.h"
#include "parser_core.h"
#include "parser_graphqlperl_runtime.h"
#include "parser_shared_ast.h"
#include "parser_ast_runtime.h"
#include "parser_ir_runtime.h"
#include "schema_compiler.h"
#include "validation.h"
static SV *gql_runtime_vm_empty_args_sv(pTHX);
static SV *gql_runtime_vm_named_coderef_sv(pTHX_ const char *name);
#include "vm_runtime.h"

static SV *gql_runtime_vm_global_empty_args_sv = NULL;
static SV *gql_runtime_vm_global_identity_callback_sv = NULL;
static HV *gql_runtime_vm_outcome_stash = NULL;
static HV *gql_runtime_vm_promise_xs_stash = NULL;

/* Recycled resolve/reject callback pairs for armed pending entries. Each
 * newXS + magic attach costs more than the entry bookkeeping it drives, so
 * fired pairs park here (holding one refcount per CV) and the next arm
 * reuses them with fresh ctx fields. Bounded; overflow pairs just die with
 * their promise. Process-lifetime, like the identity callback above. */
#define GQL_VM_PENDING_CB_POOL_MAX 128
static SV *gql_runtime_vm_pending_cb_pool_resolve[GQL_VM_PENDING_CB_POOL_MAX];
static SV *gql_runtime_vm_pending_cb_pool_reject[GQL_VM_PENDING_CB_POOL_MAX];
static IV gql_runtime_vm_pending_cb_pool_count = 0;

/* Promises on the hot path are exactly Promise::XS::Promise (the stash
 * compare above gates them), so then() always resolves to the same CV;
 * cache it and skip call_method's per-call method lookup. */
static CV *gql_runtime_vm_promise_xs_then_cv = NULL;

static CV *
gql_runtime_vm_promise_xs_then_cv_get(pTHX)
{
  if (!gql_runtime_vm_promise_xs_then_cv) {
    GV *gv = gv_fetchmethod_autoload(
      gv_stashpvs("Promise::XS::Promise", GV_ADD), "then", 0
    );
    if (gv && GvCV(gv)) {
      gql_runtime_vm_promise_xs_then_cv = GvCV(gv);
      SvREFCNT_inc_simple_void_NN((SV *)gql_runtime_vm_promise_xs_then_cv);
    }
  }
  return gql_runtime_vm_promise_xs_then_cv;
}

/* Outcome handles are internal-only and blessed exactly into their class,
 * so an exact stash-pointer compare replaces sv_derived_from's ISA hash
 * lookups on the per-field hot path. */
static int
gql_runtime_vm_sv_is_outcome(pTHX_ SV *sv)
{
  SV *rv;
  if (!sv || !SvROK(sv)) {
    return 0;
  }
  rv = SvRV(sv);
  if (!SvOBJECT(rv)) {
    return 0;
  }
  if (!gql_runtime_vm_outcome_stash) {
    gql_runtime_vm_outcome_stash = gv_stashpvs("GraphQL::Houtou::Runtime::Outcome", GV_ADD);
  }
  return SvSTASH(rv) == gql_runtime_vm_outcome_stash;
}

/* Promise::XS constructors bless exactly into Promise::XS::Promise, so the
 * stash compare answers the common case; blessed values of another class
 * fall back to sv_derived_from to keep subclass semantics. */
static int
gql_runtime_vm_sv_is_promise_xs(pTHX_ SV *sv)
{
  SV *rv;
  if (!sv || !SvROK(sv)) {
    return 0;
  }
  rv = SvRV(sv);
  if (!SvOBJECT(rv)) {
    return 0;
  }
  if (!gql_runtime_vm_promise_xs_stash) {
    gql_runtime_vm_promise_xs_stash = gv_stashpvs("Promise::XS::Promise", GV_ADD);
  }
  if (SvSTASH(rv) == gql_runtime_vm_promise_xs_stash) {
    return 1;
  }
  return sv_derived_from(sv, "Promise::XS::Promise");
}

static SV *gql_runtime_vm_global_wrap_object_outcome_callback_sv = NULL;
static SV *gql_runtime_vm_global_wrap_list_outcome_callback_sv = NULL;
static SV *gql_runtime_vm_global_promise_xs_flatten_all_callback_sv = NULL;

#define GQL_VM_PROMISE_BACKEND_NONE 0
#define GQL_VM_PROMISE_BACKEND_PROMISE_XS 1

static SV *
gql_runtime_vm_empty_args_sv(pTHX)
{
  if (!gql_runtime_vm_global_empty_args_sv) {
    gql_runtime_vm_global_empty_args_sv = newRV_noinc((SV *)newHV());
  }
  return SvREFCNT_inc_simple_NN(gql_runtime_vm_global_empty_args_sv);
}

static SV *
gql_runtime_vm_wrap_object_outcome_callback_sv(pTHX)
{
  if (gql_runtime_vm_global_wrap_object_outcome_callback_sv) {
    return SvREFCNT_inc_simple_NN(gql_runtime_vm_global_wrap_object_outcome_callback_sv);
  }
  return gql_runtime_vm_named_coderef_sv(
    aTHX_ "GraphQL::Houtou::XS::VM::wrap_object_outcome_callback_xs"
  );
}

static SV *
gql_runtime_vm_identity_callback_sv(pTHX)
{
  if (gql_runtime_vm_global_identity_callback_sv) {
    return SvREFCNT_inc_simple_NN(gql_runtime_vm_global_identity_callback_sv);
  }
  return gql_runtime_vm_named_coderef_sv(
    aTHX_ "GraphQL::Houtou::XS::VM::identity_callback_xs"
  );
}

static SV *
gql_runtime_vm_promise_xs_flatten_all_callback_sv(pTHX)
{
  if (gql_runtime_vm_global_promise_xs_flatten_all_callback_sv) {
    return SvREFCNT_inc_simple_NN(gql_runtime_vm_global_promise_xs_flatten_all_callback_sv);
  }
  return gql_runtime_vm_named_coderef_sv(
    aTHX_ "GraphQL::Houtou::XS::VM::promise_xs_flatten_all_callback_xs"
  );
}

static HV *
gql_runtime_vm_expect_hashref(pTHX_ SV *sv, const char *what)
{
  if (!sv || !SvOK(sv) || !SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV) {
    croak("%s must be a hash reference", what);
  }
  return (HV *)SvRV(sv);
}

static AV *
gql_runtime_vm_expect_arrayref(pTHX_ SV *sv, const char *what)
{
  if (!sv || !SvOK(sv) || !SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV) {
    croak("%s must be an array reference", what);
  }
  return (AV *)SvRV(sv);
}

static SV *
gql_runtime_vm_new_handle_sv(pTHX_ const char *pkg, void *ptr)
{
  SV *inner = newSVuv(PTR2UV(ptr));
  SV *rv = newRV_noinc(inner);
  return sv_bless(rv, gv_stashpv(pkg, GV_ADD));
}

static SV *
gql_runtime_vm_exec_state_materialize_response_sv(
  pTHX_ gql_runtime_vm_exec_state_handle_t *s,
  SV *data_sv
)
{
  HV *response_hv = newHV();
  hv_store(response_hv, "data", 4, data_sv ? newSVsv(data_sv) : newSV(0), 0);
  if (s && s->writer && s->writer->error_record_count > 0) {
    hv_store(
      response_hv,
      "errors",
      6,
      gql_runtime_vm_writer_materialize_errors_sv(aTHX_ s->writer),
      0
    );
  }
  return newRV_noinc((SV *)response_hv);
}

static SV *
gql_runtime_vm_fast_response_sv(
  pTHX_
  SV *data_sv,
  const gql_runtime_vm_writer_t *writer
)
{
  HV *response_hv = newHV();
  hv_store(response_hv, "data", 4, data_sv ? data_sv : newSV(0), 0);
  if (writer && writer->error_record_count > 0) {
    hv_store(
      response_hv,
      "errors",
      6,
      gql_runtime_vm_writer_materialize_errors_sv(aTHX_ writer),
      0
    );
  }
  return newRV_noinc((SV *)response_hv);
}

typedef struct {
  UV refcount;
  gql_runtime_vm_block_frame_t *frame;
  gql_runtime_vm_writer_t *writer;
  SV *state_sv;
} gql_runtime_vm_pending_merge_t;

typedef struct {
  SV *state_sv;
  gql_runtime_vm_block_frame_t *frame;
  IV entry_index;
  /* The resolve and reject arms of one then() share this ctx; the pair is
   * pooled for reuse once either arm fires (a settled promise never fires
   * the other). cv_refcnt counts the CVs still holding the ctx; the CV
   * pointers are borrowed - the CVs' own refcounts govern their lifetime. */
  SV *resolve_cv;
  SV *reject_cv;
  U8 cv_refcnt;
} gql_runtime_vm_pending_callback_ctx_t;

typedef struct {
  gql_runtime_vm_list_pending_t *pending;
  SV *state_sv;
  IV index;
} gql_runtime_vm_list_pending_callback_ctx_t;


typedef struct {
  gql_runtime_vm_path_frame_t *path_frame;
} gql_runtime_vm_error_callback_ctx_t;

typedef struct {
  SV *state_sv;
  gql_runtime_vm_path_frame_t *path_frame;
  IV child_block_index;
  /* For items of an abstract-typed list the member block is picked per
   * item once it settles; both pointers are borrowed from the execution
   * plan, which outlives the request. NULL for plain object lists. */
  const gql_runtime_vm_native_op_t *op;
  const gql_runtime_vm_native_slot_t *slot;
} gql_runtime_vm_list_item_child_ctx_t;

typedef struct {
  gql_runtime_vm_pending_merge_t *merge;
} gql_runtime_vm_finalize_callback_ctx_t;


typedef struct {
  SV *state_sv;
  IV block_index;
  IV next_op_index;
  SV *source_sv;
  gql_runtime_vm_path_frame_t *base_path_ptr;
  gql_runtime_vm_block_frame_t *frame;
  gql_runtime_vm_field_frame_t *saved_field_frame;
  gql_runtime_vm_cursor_t cursor_snapshot;
} gql_runtime_vm_serial_mutation_ctx_t;

static SV *gql_runtime_vm_exec_state_execute_block_sync_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, SV *block, IV block_index, SV *source, SV *base_path);
static gql_runtime_vm_outcome_t *gql_runtime_vm_exec_state_execute_current_op_sync_now(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s);
static SV *gql_runtime_vm_state_type_by_name_sv(pTHX_ gql_runtime_vm_exec_state_handle_t *s, SV *type_name_sv);
static gql_runtime_vm_native_runtime_t *gql_runtime_vm_native_runtime_from_runtime_schema_sv(pTHX_ SV *runtime_schema);
static gql_runtime_vm_native_runtime_t *gql_runtime_vm_exec_state_native_runtime(pTHX_ gql_runtime_vm_exec_state_handle_t *s);
static SV *gql_runtime_vm_exec_state_execute_block_async_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, IV block_index, SV *source, SV *base_path);
static SV *gql_runtime_vm_exec_state_execute_block_async_path_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, IV block_index, SV *source, gql_runtime_vm_path_frame_t *base_path_ptr, U8 return_pending_handle);
static SV *gql_runtime_vm_exec_state_resolve_current_value_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, SV *source_sv, gql_runtime_vm_path_frame_t *path_frame, SV **error_out);
static SV *gql_runtime_vm_exec_state_complete_async_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, gql_runtime_vm_path_frame_t *path_frame, IV block_index, IV slot_index, IV op_index, SV *resolved_sv, gql_runtime_vm_outcome_t **outcome_out);
static SV *gql_runtime_vm_exec_state_complete_current_native_async_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, gql_runtime_vm_path_frame_t *path_frame, const gql_runtime_vm_native_op_t *op, const gql_runtime_vm_native_slot_t *slot, SV *resolved_sv, gql_runtime_vm_outcome_t **outcome_out);
static SV *gql_runtime_vm_exec_state_execute_current_op_async_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, gql_runtime_vm_outcome_t **outcome_out);
static SV *gql_runtime_vm_apply_runtime_directives_nonfatal(pTHX_ gql_runtime_vm_exec_state_t *state, SV *source, SV *resolved, SV **error_out);
static CV *gql_runtime_vm_directive_runtime_apply_cv(pTHX);
static CV *gql_runtime_vm_directive_runtime_materialize_cv(pTHX);
static CV *gql_runtime_vm_directive_runtime_program_materialize_cv(pTHX);
static SV *gql_runtime_vm_new_lazy_info_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, SV *path_frame);
static SV *gql_runtime_vm_new_lazy_info_for_path_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, gql_runtime_vm_path_frame_t *path_frame);
static SV *gql_runtime_vm_new_outcome_handle_sv(pTHX_ U8 kind_code, SV *value, SV *error_records);
static SV *gql_runtime_vm_lookup_type_object_by_name_sv(pTHX_ SV *runtime_schema, const char *type_name);
static SV *gql_runtime_vm_lookup_slot_type_object_sv(pTHX_ const gql_runtime_vm_native_runtime_t *runtime, SV *runtime_schema, const gql_runtime_vm_native_slot_t *slot);
static SV *gql_runtime_vm_direct_slot_type_object_sv(const gql_runtime_vm_native_runtime_t *runtime, const gql_runtime_vm_native_slot_t *slot);
static SV *gql_runtime_vm_state_current_return_type_sv(pTHX_ gql_runtime_vm_exec_state_handle_t *s, SV *op_sv, SV *slot_sv);
static SV *gql_runtime_vm_state_return_type_for_slot_sv(pTHX_ gql_runtime_vm_exec_state_handle_t *s, const gql_runtime_vm_native_slot_t *slot);
static SV *gql_runtime_vm_exec_state_resolve_runtime_type_for_slot_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, const gql_runtime_vm_native_slot_t *slot, SV *resolved_sv, gql_runtime_vm_path_frame_t *path_frame, SV **error_out);
static SV *gql_runtime_vm_build_current_args_sv(pTHX_ gql_runtime_vm_exec_state_t *state);
static IV gql_runtime_vm_find_abstract_child_block_index(const gql_runtime_vm_native_op_t *op, const char *type_name);
static const char *gql_runtime_vm_type_name_from_sv(pTHX_ SV *type_sv);
static SV *gql_runtime_vm_snapshot_scalarish_value_sv(pTHX_ SV *value);
static gql_runtime_vm_path_frame_t *gql_runtime_vm_new_result_path_frame(pTHX_ gql_runtime_vm_path_frame_t *parent, const gql_runtime_vm_native_slot_t *slot);
static SV *gql_runtime_vm_new_error_callback_sv(pTHX_ gql_runtime_vm_path_frame_t *path_frame);
static SV *gql_runtime_vm_new_list_item_child_callback_sv(pTHX_ SV *state_sv, gql_runtime_vm_path_frame_t *path_frame, IV child_block_index, const gql_runtime_vm_native_op_t *op, const gql_runtime_vm_native_slot_t *slot);
static IV gql_runtime_vm_abstract_list_item_block_index(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, const gql_runtime_vm_native_op_t *op, const gql_runtime_vm_native_slot_t *slot, SV *item_sv, gql_runtime_vm_path_frame_t *item_path, SV **error_out);
static XS(gql_runtime_vm_xs_list_item_child_callback);
static gql_runtime_vm_pending_callback_ctx_t *gql_runtime_vm_new_pending_callback_pair(pTHX_ SV *state_sv, gql_runtime_vm_block_frame_t *frame, IV entry_index, SV **resolve_rv_out, SV **reject_rv_out);
static SV *gql_runtime_vm_new_finalize_callback_sv(pTHX_ gql_runtime_vm_pending_merge_t *merge);
static SV *gql_runtime_vm_call_then_promise_xs_sv(pTHX_ SV *promise_sv, SV *callback_sv, SV *error_callback_sv, gql_runtime_vm_path_frame_t *path_frame);
static SV *gql_runtime_vm_call_all_promise_xs_sv(pTHX_ AV *values_av, gql_runtime_vm_path_frame_t *path_frame);
static SV *gql_runtime_vm_call_callback_scalar_sv(pTHX_ SV *callback_sv, SV *arg_sv, gql_runtime_vm_path_frame_t *path_frame);
static SV *gql_runtime_vm_call_then_promise_for_state_sv(pTHX_ const gql_runtime_vm_exec_state_handle_t *s, SV *promise_sv, SV *callback_sv, SV *error_callback_sv, gql_runtime_vm_path_frame_t *path_frame);
static IV gql_runtime_vm_select_abstract_child_block_fast(pTHX_ gql_runtime_vm_exec_state_t *state, SV *value, SV **error_out);
static SV *gql_runtime_vm_response_json_from_native_sv(pTHX_ const gql_runtime_vm_writer_t *writer, const gql_runtime_vm_native_value_t *value);
static SV *gql_runtime_vm_response_json_from_data_sv(pTHX_ const gql_runtime_vm_writer_t *writer, SV *data_sv);
static int gql_runtime_vm_slot_uses_native_fast_abi(const gql_runtime_vm_native_slot_t *slot);
static int gql_runtime_vm_slot_uses_explicit_generic_fast_abi(const gql_runtime_vm_native_slot_t *slot);
static SV *gql_runtime_vm_execute_block_fast_sv(pTHX_ gql_runtime_vm_exec_state_t *state, IV block_index, SV *source);
static SV *gql_runtime_vm_fast_lane_guard_promise_sv(pTHX_ gql_runtime_vm_exec_state_t *state, SV *resolved);

/* Shared by the mid-lane detection sites and the top-level croak so the
 * deferred error keeps the exact wording tests and users rely on. */
#define GQL_RUNTIME_VM_FAST_LANE_PROMISE_ERROR \
  "a resolver returned a Promise::XS promise in the synchronous fast lane; build the runtime with async => 1 (or pass on_stall) so requests start on the async lane"
static SV *gql_runtime_vm_promise_xs_new_deferred_sv(pTHX);
static SV *gql_runtime_vm_promise_xs_deferred_promise_sv(pTHX_ SV *deferred_sv);
static void gql_runtime_vm_promise_xs_deferred_resolve_sv(pTHX_ SV *deferred_sv, SV *value_sv);
static void gql_runtime_vm_async_scheduler_enqueue_frame(gql_runtime_vm_exec_state_handle_t *s, gql_runtime_vm_block_frame_t *frame);
static void gql_runtime_vm_async_scheduler_arm_frame(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, gql_runtime_vm_block_frame_t *frame);
static void gql_runtime_vm_async_scheduler_drain(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s);
static void gql_runtime_vm_record_nonnull_violation(pTHX_ gql_runtime_vm_writer_t *writer, const char *parent_type_name, const char *field_name, gql_runtime_vm_path_frame_t *path_frame);
static void gql_runtime_vm_async_scheduler_resolve_frame(pTHX_ gql_runtime_vm_exec_state_handle_t *s, gql_runtime_vm_block_frame_t *frame);
static SV *gql_runtime_vm_exec_state_execute_block_serial_mutation_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, IV block_index, SV *source, gql_runtime_vm_path_frame_t *base_path_ptr);
static void gql_runtime_vm_execute_serial_mutation_steps(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, gql_runtime_vm_serial_mutation_ctx_t *ctx, U8 *all_sync_out, SV **sync_result_out);
static SV *gql_runtime_vm_new_serial_mutation_step_callback_sv(pTHX_ gql_runtime_vm_serial_mutation_ctx_t *ctx);
static XS(gql_runtime_vm_xs_serial_mutation_step_callback);
static void gql_runtime_vm_push_pending_block_frame(pTHX_ gql_runtime_vm_block_frame_t *frame, const char *result_name_pv, STRLEN result_name_len, gql_runtime_vm_path_frame_t *path_frame, gql_runtime_vm_block_frame_t *child_frame, IV block_index, IV slot_index, IV op_index);
static void gql_runtime_vm_push_pending_list_pending(pTHX_ gql_runtime_vm_block_frame_t *frame, const char *result_name_pv, STRLEN result_name_len, gql_runtime_vm_path_frame_t *path_frame, gql_runtime_vm_list_pending_t *list_pending, IV block_index, IV slot_index, IV op_index);
static void gql_runtime_vm_native_list_store_at(pTHX_ gql_runtime_vm_native_value_t *value, IV index, gql_runtime_vm_native_value_t *child);
static gql_runtime_vm_native_value_t *gql_runtime_vm_native_value_from_list_pending_sv(pTHX_ SV *value_sv);
static gql_runtime_vm_list_pending_t *gql_runtime_vm_expect_list_pending(pTHX_ SV *self);
static SV *gql_runtime_vm_wrap_list_pending_sv(pTHX_ gql_runtime_vm_list_pending_t *pending);
static int gql_runtime_vm_is_list_pending_value_sv(SV *value);
static SV *gql_runtime_vm_list_pending_handle_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, AV *values_av, gql_runtime_vm_path_frame_t *path_frame);
static XS(gql_runtime_vm_xs_pending_callback);
static XS(gql_runtime_vm_xs_pending_reject_callback);
static XS(gql_runtime_vm_xs_list_pending_callback);
static XS(gql_runtime_vm_xs_error_callback);
static XS(gql_runtime_vm_xs_finalize_callback);

static void
gql_runtime_vm_cursor_incref(gql_runtime_vm_cursor_t *cursor)
{
  if (cursor) {
    cursor->refcount++;
  }
}

static void
gql_runtime_vm_cursor_decref(pTHX_ gql_runtime_vm_cursor_t *cursor)
{
  if (!cursor) {
    return;
  }
  if (--cursor->refcount > 0) {
    return;
  }
  Safefree(cursor);
}

static void
gql_runtime_vm_free_field_frame(pTHX_ gql_runtime_vm_field_frame_t *frame)
{
  if (!frame) {
    return;
  }
  if (--frame->refcount > 0) {
    return;
  }
  SvREFCNT_dec(frame->source);
  gql_runtime_vm_path_frame_decref(frame->path_frame);
  if (frame->resolved_value) {
    SvREFCNT_dec(frame->resolved_value);
  }
  gql_runtime_vm_outcome_decref(aTHX_ frame->outcome);
  if (frame->storage_is_stack) {
    Zero(frame, 1, gql_runtime_vm_field_frame_t);
    return;
  }
  Safefree(frame);
}

static void
gql_runtime_vm_free_block_frame(pTHX_ gql_runtime_vm_block_frame_t *frame)
{
  if (!frame) {
    return;
  }
  if (--frame->refcount > 0) {
    return;
  }
  gql_runtime_vm_block_frame_live_count--;
  gql_runtime_vm_native_value_destroy(aTHX_ frame->values_value);
  gql_runtime_vm_block_frame_clear_pending(aTHX_ frame);
  if (frame->deferred_sv) {
    SvREFCNT_dec(frame->deferred_sv);
  }
  if (frame->promise_sv) {
    SvREFCNT_dec(frame->promise_sv);
  }
  if (frame->parent_frame) {
    gql_runtime_vm_free_block_frame(aTHX_ frame->parent_frame);
  }
  if (gql_runtime_vm_block_frame_pool_count < GQL_RUNTIME_VM_BLOCK_FRAME_POOL_MAX) {
    frame->parent_frame = gql_runtime_vm_block_frame_pool_head;
    gql_runtime_vm_block_frame_pool_head = frame;
    gql_runtime_vm_block_frame_pool_count++;
    return;
  }
  Safefree(frame->pending_entries);
  Safefree(frame);
}

static void
gql_runtime_vm_writer_incref(gql_runtime_vm_writer_t *writer)
{
  if (writer) {
    writer->refcount++;
  }
}

static void
gql_runtime_vm_writer_decref(pTHX_ gql_runtime_vm_writer_t *writer)
{
  if (!writer) {
    return;
  }
  if (--writer->refcount > 0) {
    return;
  }
  while (writer->error_record_count > 0) {
    gql_runtime_vm_error_record_decref(aTHX_ writer->error_records[--writer->error_record_count]);
  }
  Safefree(writer->error_records);
  Safefree(writer);
}

static void
gql_runtime_vm_pending_merge_incref(gql_runtime_vm_pending_merge_t *merge)
{
  if (merge) {
    merge->refcount++;
  }
}

static void
gql_runtime_vm_list_pending_incref(gql_runtime_vm_list_pending_t *pending)
{
  if (pending) {
    pending->refcount++;
  }
}

static void
gql_runtime_vm_pending_merge_decref(pTHX_ gql_runtime_vm_pending_merge_t *merge)
{
  if (!merge) {
    return;
  }
  if (--merge->refcount > 0) {
    return;
  }
  gql_runtime_vm_free_block_frame(aTHX_ merge->frame);
  gql_runtime_vm_writer_decref(aTHX_ merge->writer);
  if (merge->state_sv) {
    SvREFCNT_dec(merge->state_sv);
  }
  Safefree(merge);
}

static void
gql_runtime_vm_list_pending_decref(pTHX_ gql_runtime_vm_list_pending_t *pending)
{
  if (!pending) {
    return;
  }
  if (--pending->refcount > 0) {
    return;
  }
  if (pending->owner_frame) {
    gql_runtime_vm_free_block_frame(aTHX_ pending->owner_frame);
  }
  if (pending->values_value) {
    gql_runtime_vm_native_value_destroy(aTHX_ pending->values_value);
  }
  Safefree(pending);
}

static int
gql_runtime_vm_pending_callback_ctx_free(pTHX_ SV *sv, MAGIC *mg)
{
  gql_runtime_vm_pending_callback_ctx_t *ctx = mg && mg->mg_ptr
    ? INT2PTR(gql_runtime_vm_pending_callback_ctx_t *, mg->mg_ptr)
    : NULL;
  if (ctx) {
    /* The ctx is shared by the pair's two CVs; members go with the last
     * one (a recycle may have dropped them already - the fields are
     * NULLed then). */
    if (ctx->cv_refcnt > 0) {
      ctx->cv_refcnt--;
    }
    if (ctx->cv_refcnt == 0) {
      if (ctx->state_sv) {
        SvREFCNT_dec(ctx->state_sv);
      }
      if (ctx->frame) {
        gql_runtime_vm_free_block_frame(aTHX_ ctx->frame);
      }
      Safefree(ctx);
    }
    mg->mg_ptr = NULL;
  }
  if (sv && SvTYPE(sv) == SVt_PVCV) {
    CvXSUBANY((CV *)sv).any_ptr = NULL;
  }
  return 0;
}

static int
gql_runtime_vm_list_pending_callback_ctx_free(pTHX_ SV *sv, MAGIC *mg)
{
  gql_runtime_vm_list_pending_callback_ctx_t *ctx = mg && mg->mg_ptr
    ? INT2PTR(gql_runtime_vm_list_pending_callback_ctx_t *, mg->mg_ptr)
    : NULL;
  if (ctx) {
    SvREFCNT_dec(ctx->state_sv);
    gql_runtime_vm_list_pending_decref(aTHX_ ctx->pending);
    Safefree(ctx);
    mg->mg_ptr = NULL;
  }
  if (sv && SvTYPE(sv) == SVt_PVCV) {
    CvXSUBANY((CV *)sv).any_ptr = NULL;
  }
  return 0;
}

static int
gql_runtime_vm_error_callback_ctx_free(pTHX_ SV *sv, MAGIC *mg)
{
  gql_runtime_vm_error_callback_ctx_t *ctx = mg && mg->mg_ptr
    ? INT2PTR(gql_runtime_vm_error_callback_ctx_t *, mg->mg_ptr)
    : NULL;
  if (ctx) {
    gql_runtime_vm_path_frame_decref(ctx->path_frame);
    Safefree(ctx);
    mg->mg_ptr = NULL;
  }
  if (sv && SvTYPE(sv) == SVt_PVCV) {
    CvXSUBANY((CV *)sv).any_ptr = NULL;
  }
  return 0;
}

static int
gql_runtime_vm_list_item_child_ctx_free(pTHX_ SV *sv, MAGIC *mg)
{
  gql_runtime_vm_list_item_child_ctx_t *ctx = mg && mg->mg_ptr
    ? INT2PTR(gql_runtime_vm_list_item_child_ctx_t *, mg->mg_ptr)
    : NULL;
  if (ctx) {
    SvREFCNT_dec(ctx->state_sv);
    gql_runtime_vm_path_frame_decref(ctx->path_frame);
    Safefree(ctx);
    mg->mg_ptr = NULL;
  }
  if (sv && SvTYPE(sv) == SVt_PVCV) {
    CvXSUBANY((CV *)sv).any_ptr = NULL;
  }
  return 0;
}

static int
gql_runtime_vm_finalize_callback_ctx_free(pTHX_ SV *sv, MAGIC *mg)
{
  gql_runtime_vm_finalize_callback_ctx_t *ctx = mg && mg->mg_ptr
    ? INT2PTR(gql_runtime_vm_finalize_callback_ctx_t *, mg->mg_ptr)
    : NULL;
  if (ctx) {
    gql_runtime_vm_pending_merge_decref(aTHX_ ctx->merge);
    Safefree(ctx);
    mg->mg_ptr = NULL;
  }
  if (sv && SvTYPE(sv) == SVt_PVCV) {
    CvXSUBANY((CV *)sv).any_ptr = NULL;
  }
  return 0;
}

static MGVTBL gql_runtime_vm_pending_callback_ctx_vtbl = {
  NULL,
  NULL,
  NULL,
  NULL,
  gql_runtime_vm_pending_callback_ctx_free
#if PERL_VERSION_GE(5, 15, 0)
  ,NULL
  ,NULL
  ,NULL
#endif
};

static MGVTBL gql_runtime_vm_list_pending_callback_ctx_vtbl = {
  NULL,
  NULL,
  NULL,
  NULL,
  gql_runtime_vm_list_pending_callback_ctx_free
#if PERL_VERSION_GE(5, 15, 0)
  ,NULL
  ,NULL
  ,NULL
#endif
};

static MGVTBL gql_runtime_vm_error_callback_ctx_vtbl = {
  NULL,
  NULL,
  NULL,
  NULL,
  gql_runtime_vm_error_callback_ctx_free
#if PERL_VERSION_GE(5, 15, 0)
  ,NULL
  ,NULL
  ,NULL
#endif
};

static MGVTBL gql_runtime_vm_list_item_child_ctx_vtbl = {
  NULL,
  NULL,
  NULL,
  NULL,
  gql_runtime_vm_list_item_child_ctx_free
#if PERL_VERSION_GE(5, 15, 0)
  ,NULL
  ,NULL
  ,NULL
#endif
};

static MGVTBL gql_runtime_vm_finalize_callback_ctx_vtbl = {
  NULL,
  NULL,
  NULL,
  NULL,
  gql_runtime_vm_finalize_callback_ctx_free
#if PERL_VERSION_GE(5, 15, 0)
  ,NULL
  ,NULL
  ,NULL
#endif
};

static int
gql_runtime_vm_serial_mutation_ctx_free(pTHX_ SV *sv, MAGIC *mg)
{
  gql_runtime_vm_serial_mutation_ctx_t *ctx = mg && mg->mg_ptr
    ? INT2PTR(gql_runtime_vm_serial_mutation_ctx_t *, mg->mg_ptr)
    : NULL;
  PERL_UNUSED_VAR(sv);
  if (!ctx) {
    return 0;
  }
  if (ctx->state_sv) {
    SvREFCNT_dec(ctx->state_sv);
    ctx->state_sv = NULL;
  }
  if (ctx->source_sv) {
    SvREFCNT_dec(ctx->source_sv);
    ctx->source_sv = NULL;
  }
  if (ctx->base_path_ptr) {
    gql_runtime_vm_path_frame_decref(ctx->base_path_ptr);
    ctx->base_path_ptr = NULL;
  }
  if (ctx->frame) {
    gql_runtime_vm_free_block_frame(aTHX_ ctx->frame);
    ctx->frame = NULL;
  }
  gql_runtime_vm_cursor_destroy_copy(aTHX_ &ctx->cursor_snapshot);
  Safefree(ctx);
  return 0;
}

static MGVTBL gql_runtime_vm_serial_mutation_ctx_vtbl = {
  NULL,
  NULL,
  NULL,
  NULL,
  gql_runtime_vm_serial_mutation_ctx_free
#if PERL_VERSION_GE(5, 15, 0)
  ,NULL
  ,NULL
  ,NULL
#endif
};

static void
gql_runtime_vm_attach_callback_magic_ptr(pTHX_ SV *sv, MGVTBL *vtbl, void *ptr)
{
  MAGIC *mg;

  if (!sv || !vtbl || !ptr) {
    return;
  }

  sv_magicext(sv, NULL, PERL_MAGIC_ext, vtbl, NULL, 0);
  mg = mg_findext(sv, PERL_MAGIC_ext, vtbl);
  if (!mg) {
    croak("failed to attach runtime callback state");
  }
  mg->mg_ptr = PTR2IV(ptr) ? INT2PTR(char *, ptr) : NULL;
}

static SV *
gql_runtime_vm_wrap_block_frame_sv(pTHX_ gql_runtime_vm_block_frame_t *frame)
{
  if (!frame) {
    return newSVsv(&PL_sv_undef);
  }
  frame->refcount++;
  return gql_runtime_vm_new_handle_sv(aTHX_ "GraphQL::Houtou::Runtime::BlockFrame", frame);
}

static int
gql_runtime_vm_is_block_frame_value_sv(SV *value)
{
  return value && SvOK(value) && SvROK(value)
    && sv_derived_from(value, "GraphQL::Houtou::Runtime::BlockFrame");
}

static SV *
gql_runtime_vm_wrap_list_pending_sv(pTHX_ gql_runtime_vm_list_pending_t *pending)
{
  if (!pending) {
    return newSVsv(&PL_sv_undef);
  }
  gql_runtime_vm_list_pending_incref(pending);
  return gql_runtime_vm_new_handle_sv(aTHX_ "GraphQL::Houtou::Runtime::ListPending", pending);
}

static int
gql_runtime_vm_is_list_pending_value_sv(SV *value)
{
  return value && SvOK(value) && SvROK(value)
    && sv_derived_from(value, "GraphQL::Houtou::Runtime::ListPending");
}

static void *
gql_runtime_vm_expect_handle_ptr(pTHX_ SV *self, const char *what)
{
  SV *inner;
  if (!self || !SvROK(self)) {
    croak("%s must be a handle reference", what);
  }
  inner = SvRV(self);
  if (!SvIOK(inner) || SvUV(inner) == 0) {
    croak("%s handle is no longer valid", what);
  }
  return INT2PTR(void *, SvUV(inner));
}

static gql_runtime_vm_cursor_t *
gql_runtime_vm_expect_cursor(pTHX_ SV *self)
{
  return (gql_runtime_vm_cursor_t *)gql_runtime_vm_expect_handle_ptr(aTHX_ self, "cursor");
}

static gql_runtime_vm_field_frame_t *
gql_runtime_vm_expect_field_frame(pTHX_ SV *self)
{
  return (gql_runtime_vm_field_frame_t *)gql_runtime_vm_expect_handle_ptr(aTHX_ self, "field frame");
}

static gql_runtime_vm_path_frame_t *
gql_runtime_vm_expect_path_frame(pTHX_ SV *self)
{
  return (gql_runtime_vm_path_frame_t *)gql_runtime_vm_expect_handle_ptr(aTHX_ self, "path frame");
}

static gql_runtime_vm_block_frame_t *
gql_runtime_vm_expect_block_frame(pTHX_ SV *self)
{
  return (gql_runtime_vm_block_frame_t *)gql_runtime_vm_expect_handle_ptr(aTHX_ self, "block frame");
}

static gql_runtime_vm_list_pending_t *
gql_runtime_vm_expect_list_pending(pTHX_ SV *self)
{
  return (gql_runtime_vm_list_pending_t *)gql_runtime_vm_expect_handle_ptr(aTHX_ self, "list pending");
}

static gql_runtime_vm_error_record_t *
gql_runtime_vm_expect_error_record(pTHX_ SV *self)
{
  return (gql_runtime_vm_error_record_t *)gql_runtime_vm_expect_handle_ptr(aTHX_ self, "error record");
}

static gql_runtime_vm_outcome_t *
gql_runtime_vm_expect_outcome(pTHX_ SV *self)
{
  return (gql_runtime_vm_outcome_t *)gql_runtime_vm_expect_handle_ptr(aTHX_ self, "outcome");
}

static gql_runtime_vm_writer_t *
gql_runtime_vm_expect_writer(pTHX_ SV *self)
{
  return (gql_runtime_vm_writer_t *)gql_runtime_vm_expect_handle_ptr(aTHX_ self, "writer");
}

static gql_runtime_vm_exec_state_handle_t *
gql_runtime_vm_expect_exec_state_handle(pTHX_ SV *self)
{
  return (gql_runtime_vm_exec_state_handle_t *)gql_runtime_vm_expect_handle_ptr(aTHX_ self, "exec state");
}

static gql_runtime_vm_native_runtime_t *gql_runtime_vm_exec_state_native_runtime(pTHX_ gql_runtime_vm_exec_state_handle_t *s);


static SV *
gql_runtime_vm_wrap_outcome_sv(pTHX_ gql_runtime_vm_outcome_t *outcome)
{
  SV *inner;
  SV *rv;

  if (!outcome) {
    return newSVsv(&PL_sv_undef);
  }
  gql_runtime_vm_outcome_incref(outcome);
  /* Outcome handles are created once per field on the async lane; bless
   * against the cached stash instead of re-resolving the package name. */
  if (!gql_runtime_vm_outcome_stash) {
    gql_runtime_vm_outcome_stash = gv_stashpvs("GraphQL::Houtou::Runtime::Outcome", GV_ADD);
  }
  inner = newSVuv(PTR2UV(outcome));
  rv = newRV_noinc(inner);
  return sv_bless(rv, gql_runtime_vm_outcome_stash);
}

static gql_runtime_vm_outcome_t *
gql_runtime_vm_new_outcome_from_owned_native_value_struct(
  pTHX_
  U8 kind_code,
  gql_runtime_vm_native_value_t *value
)
{
  gql_runtime_vm_outcome_t *outcome;

  outcome = gql_runtime_vm_outcome_pool_get(aTHX);
  outcome->refcount = 1;
  outcome->kind_code = kind_code;
  outcome->value = value ? value : gql_runtime_vm_new_native_value_scalar(aTHX_ &PL_sv_undef);
  outcome->error_record_count = 0;
  outcome->error_records = NULL;

  return outcome;
}

static SV *
gql_runtime_vm_new_outcome_from_owned_native_value_handle_sv(
  pTHX_
  U8 kind_code,
  gql_runtime_vm_native_value_t *value
)
{
  gql_runtime_vm_outcome_t *outcome =
    gql_runtime_vm_new_outcome_from_owned_native_value_struct(aTHX_ kind_code, value);
  SV *ret = gql_runtime_vm_wrap_outcome_sv(aTHX_ outcome);
  gql_runtime_vm_outcome_decref(aTHX_ outcome);
  return ret;
}

static SV *
gql_runtime_vm_wrap_path_frame_sv(pTHX_ gql_runtime_vm_path_frame_t *path_frame)
{
  if (!path_frame) {
    return newSVsv(&PL_sv_undef);
  }
  path_frame->refcount++;
  return gql_runtime_vm_new_handle_sv(aTHX_ "GraphQL::Houtou::Runtime::PathFrame", path_frame);
}

static gql_runtime_vm_path_frame_t *
gql_runtime_vm_new_path_frame_struct(pTHX_ gql_runtime_vm_path_frame_t *parent, SV *key)
{
  gql_runtime_vm_path_frame_t *frame;
  frame = gql_runtime_vm_path_frame_pool_get(aTHX);
  frame->refcount = 1;
  if (parent) {
    frame->parent = parent;
    frame->parent->refcount++;
  }
  if (key && SvOK(key)) {
    if (SvIOK(key) && !SvROK(key)) {
      frame->key_kind = 1;
      frame->key_iv = SvIV(key);
    } else {
      STRLEN len;
      const char *pv = SvPV(key, len);
      frame->key_kind = 2;
      Newx(frame->key_pv, len + 1, char);
      Copy(pv, frame->key_pv, len, char);
      frame->key_pv[len] = '\0';
      frame->key_pv_len = len;
    }
  }
  return frame;
}

static gql_runtime_vm_path_frame_t *
gql_runtime_vm_new_path_frame_struct_pvn_borrowed(
  pTHX_
  gql_runtime_vm_path_frame_t *parent,
  const char *key_pv,
  STRLEN key_len
)
{
  gql_runtime_vm_path_frame_t *frame;
  frame = gql_runtime_vm_path_frame_pool_get(aTHX);
  frame->refcount = 1;
  if (parent) {
    frame->parent = parent;
    frame->parent->refcount++;
  }
  if (key_pv && key_len > 0) {
    frame->key_kind = 2;
    frame->key_pv = (char *)key_pv;
    frame->key_pv_len = key_len;
    frame->key_pv_borrowed = 1;
  }
  return frame;
}

static SV *
gql_runtime_vm_new_path_frame_handle(pTHX_ SV *parent, SV *key)
{
  gql_runtime_vm_path_frame_t *parent_ptr = NULL;
  gql_runtime_vm_path_frame_t *frame;
  if (parent && SvOK(parent) && SvROK(parent) && SvIOK(SvRV(parent)) && SvUV(SvRV(parent)) != 0) {
    parent_ptr = INT2PTR(gql_runtime_vm_path_frame_t *, SvUV(SvRV(parent)));
  }
  frame = gql_runtime_vm_new_path_frame_struct(aTHX_ parent_ptr, key);
  return gql_runtime_vm_new_handle_sv(aTHX_ "GraphQL::Houtou::Runtime::PathFrame", frame);
}

static gql_runtime_vm_block_frame_t *
gql_runtime_vm_new_block_frame_struct(pTHX)
{
  gql_runtime_vm_block_frame_t *frame;
  frame = gql_runtime_vm_block_frame_pool_get(aTHX);
  frame->refcount = 1;
  frame->values_value = gql_runtime_vm_new_native_value_object();
  frame->pending_count = 0;
  frame->pending_unresolved = 0;
  frame->parent_frame = NULL;
  frame->parent_entry_index = -1;
  frame->deferred_sv = NULL;
  frame->promise_sv = NULL;
  frame->queued = 0;
  frame->deferred_resolves_response = 0;
  return frame;
}

static gql_runtime_vm_field_frame_t *
gql_runtime_vm_new_field_frame_struct(pTHX_ SV *source, gql_runtime_vm_path_frame_t *path_frame)
{
  gql_runtime_vm_field_frame_t *frame;
  Newxz(frame, 1, gql_runtime_vm_field_frame_t);
  frame->refcount = 1;
  frame->source = SvREFCNT_inc_simple_NN(source ? source : &PL_sv_undef);
  if (path_frame) {
    frame->path_frame = path_frame;
    frame->path_frame->refcount++;
  }
  frame->resolved_value = NULL;
  frame->outcome = NULL;
  frame->source_is_runtime_owned = 0;
  frame->storage_is_stack = 0;
  return frame;
}

static gql_runtime_vm_field_frame_t *
gql_runtime_vm_init_stack_field_frame(
  pTHX_
  gql_runtime_vm_field_frame_t *frame,
  SV *source,
  gql_runtime_vm_path_frame_t *path_frame
)
{
  if (!frame) {
    return NULL;
  }
  Zero(frame, 1, gql_runtime_vm_field_frame_t);
  frame->refcount = 1;
  frame->storage_is_stack = 1;
  frame->source = SvREFCNT_inc_simple_NN(source ? source : &PL_sv_undef);
  if (path_frame) {
    frame->path_frame = path_frame;
    frame->path_frame->refcount++;
  }
  frame->source_is_runtime_owned = 0;
  return frame;
}

/*
 * Croak-safety net for the stack-allocated field frames used by the block
 * execution loops. A die() escaping from resolver or input-coercion code
 * longjmps past the loops' normal restore, which would leave
 * state->field_frame pointing into a dead C stack frame; ExecState DESTROY
 * would later free garbage read from that dead stack (observed as
 * "Attempt to free unreferenced scalar ... during global destruction"
 * followed by SIGSEGV). The guard is registered on Perl's save stack, so it
 * fires during die unwinding while this C stack is still live: it releases
 * the in-flight frame and restores the saved one. The loops disarm it on
 * their normal exits.
 */
typedef struct {
  gql_runtime_vm_exec_state_handle_t *state;
  gql_runtime_vm_field_frame_t *saved_field_frame;
} gql_runtime_vm_field_frame_guard_t;

static void
gql_runtime_vm_field_frame_guard_fire(pTHX_ void *ptr)
{
  gql_runtime_vm_field_frame_guard_t *guard = (gql_runtime_vm_field_frame_guard_t *)ptr;
  gql_runtime_vm_exec_state_handle_t *state = guard ? guard->state : NULL;
  if (state) {
    if (state->field_frame && state->field_frame != guard->saved_field_frame) {
      gql_runtime_vm_free_field_frame(aTHX_ state->field_frame);
    }
    state->field_frame = guard->saved_field_frame;
  }
  Safefree(guard);
}

static gql_runtime_vm_field_frame_guard_t *
gql_runtime_vm_arm_field_frame_guard(
  pTHX_
  gql_runtime_vm_exec_state_handle_t *state,
  gql_runtime_vm_field_frame_t *saved_field_frame
)
{
  gql_runtime_vm_field_frame_guard_t *guard;
  Newxz(guard, 1, gql_runtime_vm_field_frame_guard_t);
  guard->state = state;
  guard->saved_field_frame = saved_field_frame;
  SAVEDESTRUCTOR_X(gql_runtime_vm_field_frame_guard_fire, guard);
  return guard;
}

static void
gql_runtime_vm_leave_field_now(pTHX_ gql_runtime_vm_exec_state_handle_t *s)
{
  if (!s) {
    return;
  }
  gql_runtime_vm_free_field_frame(aTHX_ s->field_frame);
  s->field_frame = NULL;
}

static gql_runtime_vm_outcome_t *
gql_runtime_vm_new_error_outcome_struct_for_path(pTHX_ SV *message_sv, gql_runtime_vm_path_frame_t *path_frame)
{
  SV *clean_message_sv = message_sv ? newSVsv(message_sv) : newSVsv(&PL_sv_undef);
  gql_runtime_vm_error_record_t *record;
  gql_runtime_vm_outcome_t *outcome;

  if (clean_message_sv && SvOK(clean_message_sv)) {
    STRLEN len;
    char *pv = SvPV(clean_message_sv, len);
    while (len > 0 && (pv[len - 1] == '\n' || pv[len - 1] == '\r')) {
      len--;
    }
    sv_setpvn(clean_message_sv, pv, len);
  }

  record = gql_runtime_vm_new_error_record_struct_for_path(aTHX_ clean_message_sv, path_frame);
  SvREFCNT_dec(clean_message_sv);

  outcome = gql_runtime_vm_outcome_pool_get(aTHX);
  outcome->refcount = 1;
  outcome->kind_code = GQL_VM_KIND_SCALAR;
  outcome->value = gql_runtime_vm_new_native_value_scalar(aTHX_ &PL_sv_undef);
  outcome->error_record_count = 1;
  Newxz(outcome->error_records, 1, gql_runtime_vm_error_record_t *);
  outcome->error_records[0] = record;
  return outcome;
}

static SV *
gql_runtime_vm_new_error_outcome_for_path_sv(
  pTHX_
  SV *message_sv,
  gql_runtime_vm_path_frame_t *path_frame
)
{
  gql_runtime_vm_outcome_t *outcome =
    gql_runtime_vm_new_error_outcome_struct_for_path(aTHX_ message_sv, path_frame);
  SV *ret = gql_runtime_vm_wrap_outcome_sv(aTHX_ outcome);
  gql_runtime_vm_outcome_decref(aTHX_ outcome);
  return ret;
}

static void
gql_runtime_vm_consume_current_outcome_now(pTHX_ gql_runtime_vm_exec_state_handle_t *s, gql_runtime_vm_outcome_t *outcome)
{
  gql_runtime_vm_block_frame_t *frame;
  gql_runtime_vm_writer_t *writer;
  const gql_runtime_vm_native_slot_t *native_slot;
  const char *result_name_pv = NULL;

  if (!s || !outcome || !s->frame || !s->writer) {
    gql_runtime_vm_leave_field_now(aTHX_ s);
    return;
  }

  frame = s->frame;
  writer = s->writer;
  /* Program slot, not effective slot: response keys carry the alias. */
  native_slot = s->cursor ? gql_runtime_vm_cursor_current_native_slot(s->cursor) : NULL;
  if (native_slot && native_slot->result_name && *native_slot->result_name) {
    result_name_pv = native_slot->result_name;
  }

  /* No detour through field_frame->outcome: nothing reads it back, and
   * leave_field_now would drop the reference three lines later anyway.
   * Keeping the caller as sole owner also lets the consume below transfer
   * the native subtree instead of cloning it. */
  {
    /* Capture null-ness before consume transfers the value away. */
    int vnull = gql_runtime_vm_native_value_is_null(outcome->value);
    int carries = outcome->null_carries_error || outcome->error_record_count > 0;
    gql_runtime_vm_consume_outcome_native_object(
      aTHX_ frame->values_value,
      result_name_pv ? result_name_pv : "",
      result_name_pv ? 1 : 0,
      outcome,
      writer
    );
    /* Non-Null propagation (spec 6.4.4) for a synchronously completed
     * field: a null in a non-null position nulls this frame. */
    if (vnull && native_slot && native_slot->return_type_kind_code == 8) {
      if (!carries) {
        const gql_runtime_vm_native_block_t *parent_block =
          s->cursor ? gql_runtime_vm_cursor_current_native_block(s->cursor) : NULL;
        gql_runtime_vm_record_nonnull_violation(
          aTHX_ writer,
          parent_block ? parent_block->type_name : NULL,
          native_slot->field_name,
          s->field_frame ? s->field_frame->path_frame : NULL
        );
      }
      frame->self_nulled = 1;
    }
  }
  gql_runtime_vm_leave_field_now(aTHX_ s);
}

static void
gql_runtime_vm_consume_current_result_now(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, SV *result_sv)
{
  gql_runtime_vm_block_frame_t *frame;
  gql_runtime_vm_list_pending_t *list_pending = NULL;
  const gql_runtime_vm_native_slot_t *native_slot;
  gql_runtime_vm_block_frame_t *child_frame = NULL;
  const char *result_name_pv = NULL;
  STRLEN result_name_len = 0;

  if (!s) {
    return;
  }

  if (result_sv && SvOK(result_sv) && gql_runtime_vm_sv_is_outcome(aTHX_ result_sv)) {
    gql_runtime_vm_consume_current_outcome_now(aTHX_ s, gql_runtime_vm_expect_outcome(aTHX_ result_sv));
    return;
  }

  frame = s->frame;
  /* Program slot, not effective slot: pending entry keys carry the alias. */
  native_slot = s->cursor ? gql_runtime_vm_cursor_current_native_slot(s->cursor) : NULL;
  if (native_slot && native_slot->result_name && *native_slot->result_name) {
    result_name_pv = native_slot->result_name;
    result_name_len = (STRLEN)strlen(result_name_pv);
  }
  if (frame && result_name_pv && result_name_len > 0
      && result_sv && SvOK(result_sv)
      && gql_runtime_vm_is_block_frame_value_sv(result_sv)) {
    child_frame = gql_runtime_vm_expect_block_frame(aTHX_ result_sv);
    gql_runtime_vm_push_pending_block_frame(
      aTHX_
      frame,
      result_name_pv,
      result_name_len,
      s->field_frame ? s->field_frame->path_frame : NULL,
      child_frame,
      s->cursor ? s->cursor->block_index : -1,
      s->cursor ? s->cursor->slot_index : -1,
      s->cursor ? s->cursor->op_index : -1
    );
    if (s->promise_backend_code == GQL_VM_PROMISE_BACKEND_PROMISE_XS
        && child_frame
        && child_frame->pending_unresolved == 0) {
      gql_runtime_vm_async_scheduler_enqueue_frame(s, child_frame);
      if (!s->async_scheduler_draining) {
        gql_runtime_vm_async_scheduler_drain(aTHX_ state_sv, s);
      }
    }
    gql_runtime_vm_leave_field_now(aTHX_ s);
    return;
  }
  if (frame && result_name_pv && result_name_len > 0
      && result_sv && SvOK(result_sv)
      && gql_runtime_vm_is_list_pending_value_sv(result_sv)) {
    list_pending = gql_runtime_vm_expect_list_pending(aTHX_ result_sv);
    gql_runtime_vm_push_pending_list_pending(
      aTHX_
      frame,
      result_name_pv,
      result_name_len,
      s->field_frame ? s->field_frame->path_frame : NULL,
      list_pending,
      s->cursor ? s->cursor->block_index : -1,
      s->cursor ? s->cursor->slot_index : -1,
      s->cursor ? s->cursor->op_index : -1
    );
    gql_runtime_vm_leave_field_now(aTHX_ s);
    return;
  }
  if (frame && result_name_pv && result_name_len > 0 && result_sv && SvOK(result_sv)) {
    gql_runtime_vm_block_frame_push_pending_pvn_with_meta(
      aTHX_ frame,
      result_name_pv,
      result_name_len,
      1,
      result_sv,
      GQL_VM_PENDING_PROMISE_SV,
      NULL,
      -1,
      -1,
      -1
    );
  }
  gql_runtime_vm_leave_field_now(aTHX_ s);
}

static SV *
gql_runtime_vm_block_frame_finalize_sv(
  pTHX_
  gql_runtime_vm_block_frame_t *frame,
  U8 promise_backend_code,
  gql_runtime_vm_writer_t *writer,
  SV *state_sv,
  U8 return_pending_handle
);

static SV *
gql_runtime_vm_finalize_current_block_now(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, SV *snapshot, U8 return_pending_handle)
{
  gql_runtime_vm_block_frame_t *frame;
  gql_runtime_vm_block_frame_t *completed_frame;
  SV *result;
  U8 scheduler_owned = 0;

  if (!s || !s->frame) {
    return newSVsv(&PL_sv_undef);
  }

  frame = s->frame;
  completed_frame = frame;
  if (s->promise_backend_code == GQL_VM_PROMISE_BACKEND_PROMISE_XS) {
    if (frame->pending_count > 0) {
      frame->deferred_resolves_response = (frame == s->response_frame) ? 1 : 0;
      scheduler_owned = 1;
    }
    result = gql_runtime_vm_block_frame_finalize_sv(
      aTHX_
      frame,
      s->promise_backend_code,
      s->writer,
      state_sv,
      return_pending_handle
    );
  } else {
    result = frame->self_nulled
      ? newSVsv(&PL_sv_undef)
      : gql_runtime_vm_native_value_materialize_sv(aTHX_ frame->values_value);
  }

  if (s->cursor && snapshot && SvOK(snapshot)) {
    gql_runtime_vm_cursor_restore_sv(aTHX_ s->cursor, snapshot);
  }

  if (s->frame_stack_count > 0) {
    s->frame_stack_count--;
    s->frame_stack[s->frame_stack_count] = NULL;
  }
  if (!scheduler_owned) {
    gql_runtime_vm_free_block_frame(aTHX_ completed_frame);
  }
  s->frame = s->frame_stack_count > 0 ? s->frame_stack[s->frame_stack_count - 1] : NULL;

  return result;
}

static SV *
gql_runtime_vm_block_frame_finalize_sv(
  pTHX_
  gql_runtime_vm_block_frame_t *frame,
  U8 promise_backend_code,
  gql_runtime_vm_writer_t *writer,
  SV *state_sv,
  U8 return_pending_handle
)
{
  IV i;
  AV *pending_av;
  SV *aggregate;
  gql_runtime_vm_block_frame_t next_pending;
  gql_runtime_vm_exec_state_handle_t *exec_state =
    (state_sv && SvOK(state_sv)) ? gql_runtime_vm_expect_exec_state_handle(aTHX_ state_sv) : NULL;

  /* return_pending_handle modes:
   *   0 - legacy: materialize an SV tree on sync completion, hand out the
   *       frame promise when pendings remain (public exec-state API).
   *   1 - full handles: native outcome on sync completion, raw block-frame
   *       handle when pendings remain.
   *   2 - native-first hot path: native outcome on sync completion (no
   *       materialize/reconvert round trip), but still a promise when
   *       pendings remain so the existing then-wrap machinery applies. */
  if (!frame) {
    return newSVsv(&PL_sv_undef);
  }
  if (frame->pending_count == 0) {
    /* Non-Null propagation: a violated frame completes as null (the
     * error is already recorded), not as its partial object. */
    if (frame->self_nulled) {
      if (return_pending_handle) {
        gql_runtime_vm_outcome_t *o =
          gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_SCALAR, &PL_sv_undef, &PL_sv_undef);
        SV *ret;
        o->null_carries_error = 1;
        ret = gql_runtime_vm_wrap_outcome_sv(aTHX_ o);
        gql_runtime_vm_outcome_decref(aTHX_ o);
        return ret;
      }
      return newSVsv(&PL_sv_undef);
    }
    if (return_pending_handle) {
      SV *ret = gql_runtime_vm_new_outcome_from_owned_native_value_handle_sv(
        aTHX_
        GQL_VM_KIND_OBJECT,
        frame->values_value
      );
      frame->values_value = NULL;
      return ret;
    }
    return gql_runtime_vm_native_value_materialize_sv(aTHX_ frame->values_value);
  }
  if (promise_backend_code != GQL_VM_PROMISE_BACKEND_PROMISE_XS) {
    croak("pending async runtime blocks require Promise::XS");
  }
  if (exec_state) {
    SV *ret_sv;
    U8 saved_draining = exec_state->async_scheduler_draining;
    U8 resolve_response = frame->deferred_resolves_response ? 1 : 0;
    U8 return_promise = (resolve_response || return_pending_handle != 1) ? 1 : 0;
    U8 armed = 0;

    /* Response frame at the top level: try to complete the request inside
     * this call before paying for the deferred. Arm first; if every
     * pending settled during arm (preresolved promises), drain now and
     * hand the parked response back directly - no deferred/promise pair,
     * no then(materialize) chain (resolve_frame stashes it on the exec
     * state). A drain that merely uncovers the next pending wave falls
     * through to the promise path below. Only the parentless response
     * frame may be armed before taking a reference: its resolve path
     * cannot free it while it still has pendings. */
    if (resolve_response && !frame->deferred_sv && !saved_draining) {
      exec_state->async_scheduler_draining = 1;
      gql_runtime_vm_async_scheduler_arm_frame(aTHX_ state_sv, exec_state, frame);
      exec_state->async_scheduler_draining = saved_draining;
      armed = 1;

      if (frame->pending_unresolved == 0) {
        gql_runtime_vm_async_scheduler_enqueue_frame(exec_state, frame);
        gql_runtime_vm_async_scheduler_drain(aTHX_ state_sv, exec_state);
        if (exec_state->completed_response_sv) {
          return newSVsv(&PL_sv_undef);
        }
      }
    }

    if (return_promise && !frame->deferred_sv) {
      frame->deferred_sv = gql_runtime_vm_promise_xs_new_deferred_sv(aTHX);
      frame->promise_sv = gql_runtime_vm_promise_xs_deferred_promise_sv(aTHX_ frame->deferred_sv);
    }
    ret_sv = return_promise
      ? (frame->promise_sv ? newSVsv(frame->promise_sv) : newSVsv(&PL_sv_undef))
      : gql_runtime_vm_wrap_block_frame_sv(aTHX_ frame);

    if (!armed) {
      exec_state->async_scheduler_draining = 1;
      gql_runtime_vm_async_scheduler_arm_frame(aTHX_ state_sv, exec_state, frame);
      exec_state->async_scheduler_draining = saved_draining;
    }

    if (return_promise && frame->pending_unresolved == 0) {
      gql_runtime_vm_async_scheduler_enqueue_frame(exec_state, frame);
      if (!exec_state->async_scheduler_draining) {
        gql_runtime_vm_async_scheduler_drain(aTHX_ state_sv, exec_state);
      }
    }
    return ret_sv;
  }

  Zero(&next_pending, 1, gql_runtime_vm_block_frame_t);
  for (i = 0; i < frame->pending_count; i++) {
    if (frame->pending_entries[i].payload_kind == GQL_VM_PENDING_OUTCOME_PTR) {
      gql_runtime_vm_consume_outcome_native_object(
        aTHX_
        frame->values_value,
        frame->pending_entries[i].result_name_pv,
        frame->pending_entries[i].result_name_pv_borrowed,
        frame->pending_entries[i].payload.outcome_ptr,
        writer
      );
    } else {
      gql_runtime_vm_block_frame_push_pending_pvn_with_meta(
        aTHX_
        &next_pending,
        frame->pending_entries[i].result_name_pv,
        frame->pending_entries[i].result_name_len,
        frame->pending_entries[i].result_name_pv_borrowed,
        frame->pending_entries[i].payload.promise_sv,
        frame->pending_entries[i].payload_kind,
        frame->pending_entries[i].path_frame,
        frame->pending_entries[i].block_index,
        frame->pending_entries[i].slot_index,
        frame->pending_entries[i].op_index
      );
    }
  }
  gql_runtime_vm_block_frame_clear_pending(aTHX_ frame);
  /* clear_pending retains the array for pooled reuse; this frame swaps in
   * the rebuilt one instead, so the old buffer must go now. */
  Safefree(frame->pending_entries);
  frame->pending_entries = next_pending.pending_entries;
  frame->pending_count = next_pending.pending_count;
  frame->pending_capacity = next_pending.pending_capacity;

  if (frame->pending_count == 0) {
    return gql_runtime_vm_native_value_materialize_sv(aTHX_ frame->values_value);
  }

  pending_av = newAV();
  for (i = 0; i < frame->pending_count; i++) {
    if (frame->pending_entries[i].payload_kind == GQL_VM_PENDING_PROMISE_SV
        || frame->pending_entries[i].payload_kind == GQL_VM_PENDING_PROMISE_RESOLVED_VALUE_SV
        || frame->pending_entries[i].payload_kind == GQL_VM_PENDING_PROMISE_GENERIC_VALUE_SV) {
      av_push(
        pending_av,
        newSVsv(
          frame->pending_entries[i].payload.promise_sv
            ? frame->pending_entries[i].payload.promise_sv
            : &PL_sv_undef
        )
      );
    } else {
      av_push(pending_av, newSVsv(&PL_sv_undef));
    }
  }
  aggregate = gql_runtime_vm_call_all_promise_xs_sv(aTHX_ pending_av, NULL);
  SvREFCNT_dec((SV *)pending_av);

  if (aggregate && SvOK(aggregate) && gql_runtime_vm_sv_is_outcome(aTHX_ aggregate)) {
    return aggregate;
  }

  {
    gql_runtime_vm_pending_merge_t *merge;
    SV *callback_sv;
    SV *retval;

    Newxz(merge, 1, gql_runtime_vm_pending_merge_t);
    merge->refcount = 1;
    merge->frame = frame;
    frame->refcount++;
    merge->writer = writer;
    gql_runtime_vm_writer_incref(writer);
    merge->state_sv = state_sv ? SvREFCNT_inc_simple_NN(state_sv) : NULL;
    callback_sv = gql_runtime_vm_new_finalize_callback_sv(aTHX_ merge);
    gql_runtime_vm_pending_merge_decref(aTHX_ merge);

    retval = gql_runtime_vm_call_then_promise_xs_sv(aTHX_ aggregate, callback_sv, NULL, NULL);

    SvREFCNT_dec(aggregate);
    SvREFCNT_dec(callback_sv);
    return retval;
  }
}

static SV *
gql_runtime_vm_fetch_hash_entry_sv(pTHX_ HV *hv, const char *key, I32 keylen)
{
  SV **svp = hv_fetch(hv, key, keylen, 0);
  return (svp && SvOK(*svp)) ? *svp : NULL;
}

static const char *
gql_runtime_vm_fetch_hash_entry_pv(pTHX_ HV *hv, const char *key, I32 keylen)
{
  SV *sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ hv, key, keylen);
  return sv ? SvPV_nolen(sv) : NULL;
}

static int
gql_runtime_vm_is_promise_xs_value_sv(SV *value)
{
  return gql_runtime_vm_sv_is_promise_xs(aTHX_ value);
}

static int
gql_runtime_vm_is_promise_value_for_state_sv(
  pTHX_
  const gql_runtime_vm_exec_state_handle_t *s,
  SV *value
)
{
  if (!value || !SvOK(value)) {
    return 0;
  }
  if (s && s->promise_backend_code == GQL_VM_PROMISE_BACKEND_PROMISE_XS) {
    return gql_runtime_vm_is_promise_xs_value_sv(value);
  }
  return 0;
}

static SV *
gql_runtime_vm_call_callback_scalar_sv(
  pTHX_
  SV *callback_sv,
  SV *arg_sv,
  gql_runtime_vm_path_frame_t *path_frame
)
{
  dSP;
  SV *ret = NULL;

  if (!callback_sv || !SvOK(callback_sv)) {
    return newSVsv(&PL_sv_undef);
  }

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  XPUSHs(arg_sv ? arg_sv : &PL_sv_undef);
  PUTBACK;
  call_sv(callback_sv, G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && SP > PL_stack_base) {
    SV *stack_ret = POPs;
    ret = stack_ret ? newSVsv(stack_ret) : newSVsv(&PL_sv_undef);
  } else if (SP > PL_stack_base) {
    (void)POPs;
  }
  if (SvTRUE(ERRSV)) {
    ret = gql_runtime_vm_new_error_outcome_for_path_sv(
      aTHX_
      ERRSV,
      path_frame
    );
    sv_setsv(ERRSV, &PL_sv_undef);
  }
  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret ? ret : newSVsv(&PL_sv_undef);
}

static SV *
gql_runtime_vm_named_coderef_sv(pTHX_ const char *name)
{
  CV *cv = name ? get_cv(name, 0) : NULL;
  return cv ? newRV_inc((SV *)cv) : newSVsv(&PL_sv_undef);
}

static void
gql_runtime_vm_async_scheduler_enqueue_frame(gql_runtime_vm_exec_state_handle_t *s, gql_runtime_vm_block_frame_t *frame)
{
  if (!s || !frame || frame->queued) {
    return;
  }
  if (s->async_ready_frame_count == s->async_ready_frame_capacity) {
    IV new_cap = s->async_ready_frame_capacity ? s->async_ready_frame_capacity * 2 : 4;
    Renew(s->async_ready_frames, new_cap, gql_runtime_vm_block_frame_t *);
    s->async_ready_frame_capacity = new_cap;
  }
  s->async_ready_frames[s->async_ready_frame_count++] = frame;
  frame->queued = 1;
}

static void
gql_runtime_vm_async_pending_entry_store_outcome(
  pTHX_
  gql_runtime_vm_pending_entry_t *entry,
  SV *outcome_sv
)
{
  gql_runtime_vm_outcome_t *outcome_ptr;

  if (!entry || !outcome_sv || !SvOK(outcome_sv)) {
    return;
  }

  outcome_ptr = gql_runtime_vm_expect_outcome(aTHX_ outcome_sv);
  gql_runtime_vm_outcome_incref(outcome_ptr);

  if (entry->payload_kind == GQL_VM_PENDING_OUTCOME_PTR) {
    gql_runtime_vm_outcome_decref(aTHX_ entry->payload.outcome_ptr);
  } else if (entry->payload.promise_sv) {
    SvREFCNT_dec(entry->payload.promise_sv);
  }

  entry->payload_kind = GQL_VM_PENDING_OUTCOME_PTR;
  entry->payload.outcome_ptr = outcome_ptr;
  entry->state_code = GQL_VM_PENDING_STATE_READY_OUTCOME;
}

static void
gql_runtime_vm_async_pending_entry_store_outcome_ptr(
  pTHX_
  gql_runtime_vm_pending_entry_t *entry,
  gql_runtime_vm_outcome_t *outcome_ptr
)
{
  if (!entry || !outcome_ptr) {
    return;
  }

  gql_runtime_vm_outcome_incref(outcome_ptr);

  if (entry->payload_kind == GQL_VM_PENDING_OUTCOME_PTR) {
    gql_runtime_vm_outcome_decref(aTHX_ entry->payload.outcome_ptr);
  } else if (entry->payload_kind == GQL_VM_PENDING_BLOCK_FRAME_PTR) {
    gql_runtime_vm_free_block_frame(aTHX_ entry->payload.block_frame_ptr);
  } else if (entry->payload_kind == GQL_VM_PENDING_LIST_PENDING_PTR) {
    gql_runtime_vm_list_pending_decref(aTHX_ entry->payload.list_pending_ptr);
  } else if (entry->payload.promise_sv) {
    SvREFCNT_dec(entry->payload.promise_sv);
  }

  entry->payload_kind = GQL_VM_PENDING_OUTCOME_PTR;
  entry->payload.outcome_ptr = outcome_ptr;
  entry->state_code = GQL_VM_PENDING_STATE_READY_OUTCOME;
}

static void
gql_runtime_vm_async_pending_entry_store_sv(
  pTHX_
  gql_runtime_vm_pending_entry_t *entry,
  SV *value_sv
)
{
  SV *copied_sv;

  if (!entry) {
    return;
  }

  copied_sv = gql_runtime_vm_snapshot_scalarish_value_sv(
    aTHX_
    value_sv ? value_sv : &PL_sv_undef
  );

  if (entry->payload_kind == GQL_VM_PENDING_OUTCOME_PTR) {
    gql_runtime_vm_outcome_decref(aTHX_ entry->payload.outcome_ptr);
  } else if (entry->payload.promise_sv) {
    SvREFCNT_dec(entry->payload.promise_sv);
  }

  entry->payload.promise_sv = copied_sv;
  entry->state_code = GQL_VM_PENDING_STATE_READY_SV;
}

static void
gql_runtime_vm_native_list_store_at(
  pTHX_
  gql_runtime_vm_native_value_t *value,
  IV index,
  gql_runtime_vm_native_value_t *child
)
{
  gql_runtime_vm_native_list_t *list;
  IV i;

  if (!value || value->kind_code != GQL_VM_NATIVE_VALUE_LIST || index < 0 || !child) {
    return;
  }

  list = &value->list;
  if (index >= list->capacity) {
    IV new_capacity = list->capacity ? list->capacity : 8;
    while (index >= new_capacity) {
      new_capacity *= 2;
    }
    Renew(list->items, new_capacity, gql_runtime_vm_native_value_t *);
    for (i = list->capacity; i < new_capacity; i++) {
      list->items[i] = NULL;
    }
    list->capacity = new_capacity;
  }

  if (list->items[index]) {
    gql_runtime_vm_native_value_destroy(aTHX_ list->items[index]);
  }
  list->items[index] = child;
  if (index >= list->count) {
    list->count = index + 1;
  }
}

static gql_runtime_vm_native_value_t *
gql_runtime_vm_native_value_from_list_pending_sv(pTHX_ SV *value_sv)
{
  if (value_sv && SvOK(value_sv) && gql_runtime_vm_sv_is_outcome(aTHX_ value_sv)) {
    gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_expect_outcome(aTHX_ value_sv);
    return gql_runtime_vm_native_value_clone(aTHX_ outcome ? outcome->value : NULL);
  }
  return gql_runtime_vm_native_value_from_sv(aTHX_ value_sv ? value_sv : &PL_sv_undef);
}

/* Terminal conversion for freshly completed list items: the caller's AV
 * holds the only handle to each item outcome, so a sole-owner native
 * subtree is transferred rather than cloned. Promise resolution values go
 * through gql_runtime_vm_native_value_from_list_pending_sv instead - those
 * SVs can be aliased by the promise that produced them. */
static gql_runtime_vm_native_value_t *
gql_runtime_vm_native_value_take_completed_item_sv(pTHX_ SV *value_sv)
{
  if (value_sv && SvOK(value_sv) && gql_runtime_vm_sv_is_outcome(aTHX_ value_sv)) {
    gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_expect_outcome(aTHX_ value_sv);
    if (outcome && outcome->refcount == 1 && outcome->value) {
      gql_runtime_vm_native_value_t *taken = outcome->value;
      outcome->value = NULL;
      return taken;
    }
    return gql_runtime_vm_native_value_clone(aTHX_ outcome ? outcome->value : NULL);
  }
  return gql_runtime_vm_native_value_from_sv(aTHX_ value_sv ? value_sv : &PL_sv_undef);
}

static void
gql_runtime_vm_push_pending_block_frame(
  pTHX_
  gql_runtime_vm_block_frame_t *frame,
  const char *result_name_pv,
  STRLEN result_name_len,
  gql_runtime_vm_path_frame_t *path_frame,
  gql_runtime_vm_block_frame_t *child_frame,
  IV block_index,
  IV slot_index,
  IV op_index
)
{
  gql_runtime_vm_pending_entry_t *entry;

  if (!frame || !child_frame || !result_name_pv || result_name_len == 0) {
    return;
  }

  entry = gql_runtime_vm_block_frame_push_pending_entry_with_meta(
    aTHX_
    frame,
    result_name_pv,
    result_name_len,
    1,
    path_frame,
    block_index,
    slot_index,
    op_index
  );
  if (!entry) {
    return;
  }

  entry->payload_kind = GQL_VM_PENDING_BLOCK_FRAME_PTR;
  entry->state_code = GQL_VM_PENDING_STATE_WAITING_ARMED;
  entry->payload.block_frame_ptr = child_frame;
  entry->payload.block_frame_ptr->refcount++;
  frame->pending_unresolved++;

  child_frame->parent_frame = frame;
  child_frame->parent_frame->refcount++;
  child_frame->parent_entry_index = frame->pending_count - 1;
}

static void
gql_runtime_vm_push_pending_list_pending(
  pTHX_
  gql_runtime_vm_block_frame_t *frame,
  const char *result_name_pv,
  STRLEN result_name_len,
  gql_runtime_vm_path_frame_t *path_frame,
  gql_runtime_vm_list_pending_t *list_pending,
  IV block_index,
  IV slot_index,
  IV op_index
)
{
  gql_runtime_vm_pending_entry_t *entry;

  if (!frame || !list_pending || !result_name_pv || result_name_len == 0) {
    return;
  }

  entry = gql_runtime_vm_block_frame_push_pending_entry_with_meta(
    aTHX_
    frame,
    result_name_pv,
    result_name_len,
    1,
    path_frame,
    block_index,
    slot_index,
    op_index
  );
  if (!entry) {
    return;
  }

  entry->payload_kind = GQL_VM_PENDING_LIST_PENDING_PTR;
  entry->state_code = GQL_VM_PENDING_STATE_WAITING_ARMED;
  entry->payload.list_pending_ptr = list_pending;
  gql_runtime_vm_list_pending_incref(list_pending);
  frame->pending_unresolved++;

  if (list_pending->owner_frame) {
    gql_runtime_vm_free_block_frame(aTHX_ list_pending->owner_frame);
  }
  list_pending->owner_frame = frame;
  list_pending->owner_frame->refcount++;
}

static gql_runtime_vm_pending_callback_ctx_t *
gql_runtime_vm_new_pending_callback_pair(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_block_frame_t *frame,
  IV entry_index,
  SV **resolve_rv_out,
  SV **reject_rv_out
)
{
  gql_runtime_vm_pending_callback_ctx_t *ctx;

  if (gql_runtime_vm_pending_cb_pool_count > 0) {
    IV n = --gql_runtime_vm_pending_cb_pool_count;
    SV *resolve_cv = gql_runtime_vm_pending_cb_pool_resolve[n];
    SV *reject_cv = gql_runtime_vm_pending_cb_pool_reject[n];

    gql_runtime_vm_pending_cb_pool_resolve[n] = NULL;
    gql_runtime_vm_pending_cb_pool_reject[n] = NULL;
    ctx = INT2PTR(
      gql_runtime_vm_pending_callback_ctx_t *,
      CvXSUBANY((CV *)resolve_cv).any_ptr
    );
    ctx->state_sv = state_sv ? SvREFCNT_inc_simple_NN(state_sv) : NULL;
    ctx->frame = frame;
    if (ctx->frame) {
      ctx->frame->refcount++;
    }
    ctx->entry_index = entry_index;
    /* The pool's CV refcounts transfer into the returned RVs. */
    *resolve_rv_out = newRV_noinc(resolve_cv);
    *reject_rv_out = newRV_noinc(reject_cv);
    return ctx;
  }

  {
    CV *resolve_cv;
    CV *reject_cv;

    Newxz(ctx, 1, gql_runtime_vm_pending_callback_ctx_t);
    ctx->state_sv = state_sv ? SvREFCNT_inc_simple_NN(state_sv) : NULL;
    ctx->frame = frame;
    if (ctx->frame) {
      ctx->frame->refcount++;
    }
    ctx->entry_index = entry_index;
    ctx->cv_refcnt = 2;

    resolve_cv = newXS(NULL, gql_runtime_vm_xs_pending_callback, __FILE__);
    CvXSUBANY(resolve_cv).any_ptr = ctx;
    gql_runtime_vm_attach_callback_magic_ptr(aTHX_ (SV *)resolve_cv, &gql_runtime_vm_pending_callback_ctx_vtbl, ctx);
    reject_cv = newXS(NULL, gql_runtime_vm_xs_pending_reject_callback, __FILE__);
    CvXSUBANY(reject_cv).any_ptr = ctx;
    gql_runtime_vm_attach_callback_magic_ptr(aTHX_ (SV *)reject_cv, &gql_runtime_vm_pending_callback_ctx_vtbl, ctx);
    ctx->resolve_cv = (SV *)resolve_cv;
    ctx->reject_cv = (SV *)reject_cv;

    *resolve_rv_out = newRV_noinc((SV *)resolve_cv);
    *reject_rv_out = newRV_noinc((SV *)reject_cv);
    return ctx;
  }
}

/* One arm fired: the promise has settled, so the other arm can never
 * fire. Drop the ctx's references now (parked callbacks must not keep the
 * exec state alive) and park the pair for the next arm to reuse. */
static void
gql_runtime_vm_pending_callback_pair_recycle(
  pTHX_
  gql_runtime_vm_pending_callback_ctx_t *ctx
)
{
  if (!ctx) {
    return;
  }
  if (ctx->state_sv) {
    SvREFCNT_dec(ctx->state_sv);
    ctx->state_sv = NULL;
  }
  if (ctx->frame) {
    gql_runtime_vm_free_block_frame(aTHX_ ctx->frame);
    ctx->frame = NULL;
  }
  ctx->entry_index = -1;
  if (ctx->resolve_cv && ctx->reject_cv && ctx->cv_refcnt == 2
      && gql_runtime_vm_pending_cb_pool_count < GQL_VM_PENDING_CB_POOL_MAX) {
    gql_runtime_vm_pending_cb_pool_resolve[gql_runtime_vm_pending_cb_pool_count] =
      SvREFCNT_inc_simple_NN(ctx->resolve_cv);
    gql_runtime_vm_pending_cb_pool_reject[gql_runtime_vm_pending_cb_pool_count] =
      SvREFCNT_inc_simple_NN(ctx->reject_cv);
    gql_runtime_vm_pending_cb_pool_count++;
  }
}

static void
gql_runtime_vm_async_scheduler_resolve_frame(
  pTHX_
  gql_runtime_vm_exec_state_handle_t *s,
  gql_runtime_vm_block_frame_t *frame
)
{
  SV *data_sv = NULL;
  SV *resolved_sv;
  IV i;

  if (!frame) {
    return;
  }

  if (s) {
    for (i = 0; i < s->async_ready_frame_count; i++) {
      if (s->async_ready_frames[i] == frame) {
        s->async_ready_frames[i] = NULL;
      }
    }
  }
  frame->queued = 0;

  if (frame->parent_frame && frame->parent_entry_index >= 0) {
    gql_runtime_vm_pending_entry_t *entry = NULL;
    gql_runtime_vm_outcome_t *outcome = NULL;

    if (frame->parent_entry_index < frame->parent_frame->pending_count) {
      entry = &frame->parent_frame->pending_entries[frame->parent_entry_index];
    } else {
      /* Adoption re-pushes relink parent_entry_index, so this must not
       * happen; if it does, the child's result would vanish from the
       * response - make it loud instead of silent. */
      warn("GraphQL::Houtou: async child frame resolved with out-of-range parent entry index %" IVdf "; its result is dropped",
           frame->parent_entry_index);
    }

    if (frame->self_nulled) {
      /* A non-null field of this frame was null: the frame resolves to
       * null (the originating error is already recorded), and the null
       * keeps propagating to this frame's own parent. */
      outcome = gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_SCALAR, &PL_sv_undef, &PL_sv_undef);
      outcome->null_carries_error = 1;
    } else {
      outcome = gql_runtime_vm_new_outcome_from_owned_native_value_struct(
        aTHX_
        GQL_VM_KIND_OBJECT,
        frame->values_value
      );
      frame->values_value = NULL;
    }

    if (entry) {
      gql_runtime_vm_async_pending_entry_store_outcome_ptr(aTHX_ entry, outcome);
    }

    if (frame->parent_frame->pending_unresolved > 0) {
      frame->parent_frame->pending_unresolved--;
    }
    if (frame->parent_frame->pending_unresolved == 0) {
      /* A parent still on the exec stack is mid-block-loop; enqueuing it
       * now would let the drain resolve (and free) it under the loop's
       * feet. Its own finalize arms the READY entries and enqueues. */
      U8 parent_executing = 0;
      if (s) {
        IV fi;
        for (fi = 0; fi < s->frame_stack_count; fi++) {
          if (s->frame_stack[fi] == frame->parent_frame) {
            parent_executing = 1;
            break;
          }
        }
      }
      if (!parent_executing) {
        gql_runtime_vm_async_scheduler_enqueue_frame(s, frame->parent_frame);
      }
    }

    gql_runtime_vm_outcome_decref(aTHX_ outcome);
    gql_runtime_vm_free_block_frame(aTHX_ frame);
    return;
  }

  /* Non-Null propagation reached the operation root: data is null (spec
   * 6.4.4). Drop the partial object so both response tails emit null. */
  if (frame->self_nulled && frame->values_value) {
    gql_runtime_vm_native_value_destroy(aTHX_ frame->values_value);
    frame->values_value = NULL;
  }

  if (frame->deferred_resolves_response && s->response_json_mode) {
    resolved_sv = gql_runtime_vm_response_json_from_native_sv(
      aTHX_ s->writer, frame->values_value
    );
  } else {
    data_sv = gql_runtime_vm_native_value_materialize_sv(aTHX_ frame->values_value);
    resolved_sv = data_sv;
    if (frame->deferred_resolves_response) {
      resolved_sv = gql_runtime_vm_exec_state_materialize_response_sv(aTHX_ s, data_sv);
      SvREFCNT_dec(data_sv);
    }
  }

  if (frame->deferred_sv && SvOK(frame->deferred_sv)) {
    gql_runtime_vm_promise_xs_deferred_resolve_sv(aTHX_ frame->deferred_sv, resolved_sv);
    SvREFCNT_dec(resolved_sv);
  } else if (frame->deferred_resolves_response) {
    /* No deferred was ever created: the request is completing inside the
     * original execute call. Park the finished response (envelope or JSON
     * per json_mode) on the exec state for the entry point to return. */
    if (s->completed_response_sv) {
      SvREFCNT_dec(s->completed_response_sv);
    }
    s->completed_response_sv = resolved_sv;
  } else {
    SvREFCNT_dec(resolved_sv);
  }
  if (frame->deferred_sv) {
    SvREFCNT_dec(frame->deferred_sv);
    frame->deferred_sv = NULL;
  }
  if (s->response_frame == frame) {
    s->response_frame = NULL;
  }
  if (frame->promise_sv) {
    SvREFCNT_dec(frame->promise_sv);
    frame->promise_sv = NULL;
  }
  gql_runtime_vm_free_block_frame(aTHX_ frame);
}

static void
gql_runtime_vm_async_scheduler_arm_frame(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  gql_runtime_vm_block_frame_t *frame
)
{
  IV i;

  if (!s || !frame) {
    return;
  }

  frame->pending_unresolved = 0;
  for (i = 0; i < frame->pending_count; i++) {
    gql_runtime_vm_pending_entry_t *entry = &frame->pending_entries[i];

    if (entry->state_code == GQL_VM_PENDING_STATE_WAITING_ARMED) {
      if (entry->payload_kind == GQL_VM_PENDING_LIST_PENDING_PTR
          && entry->payload.list_pending_ptr
          && entry->payload.list_pending_ptr->unresolved_count == 0) {
        continue;
      }
      frame->pending_unresolved++;
      continue;
    }
    if (entry->state_code != GQL_VM_PENDING_STATE_WAITING_UNARMED) {
      continue;
    }

    entry->state_code = GQL_VM_PENDING_STATE_WAITING_ARMED;
    frame->pending_unresolved++;

    {
      SV *callback_sv;
      /* The reject arm settles the entry directly: promises land here
       * unnormalized (then_complete pushes the user promise itself), and
       * an outcome returned into the discarded derived promise would be
       * lost, deadlocking the frame. */
      SV *error_callback_sv;
      gql_runtime_vm_pending_callback_ctx_t *pair_ctx =
        gql_runtime_vm_new_pending_callback_pair(
          aTHX_ state_sv, frame, i, &callback_sv, &error_callback_sv
        );
      SV *ret;

      /* Record the armed context so a process_frame re-push can retarget
       * its entry_index when this entry moves in the rebuilt array. */
      entry->armed_resolve_ctx = pair_ctx;
      entry->armed_reject_ctx = pair_ctx;

      ret = gql_runtime_vm_call_then_promise_for_state_sv(
        aTHX_
        s,
        entry->payload.promise_sv,
        callback_sv,
        error_callback_sv,
        entry->path_frame
      );

      SvREFCNT_dec(callback_sv);
      SvREFCNT_dec(error_callback_sv);

      if (ret && SvOK(ret) && gql_runtime_vm_sv_is_outcome(aTHX_ ret)) {
        gql_runtime_vm_async_pending_entry_store_outcome(aTHX_ entry, ret);
        if (frame->pending_unresolved > 0) {
          frame->pending_unresolved--;
        }
      }
      if (ret) {
        SvREFCNT_dec(ret);
      }
    }
  }
}

/* Record the spec's "Cannot return null for non-nullable field
 * Parent.field." error at `path_frame` on the async lane's writer. */
static void
gql_runtime_vm_record_nonnull_violation(
  pTHX_
  gql_runtime_vm_writer_t *writer,
  const char *parent_type_name,
  const char *field_name,
  gql_runtime_vm_path_frame_t *path_frame
)
{
  SV *msg_sv;
  gql_runtime_vm_outcome_t *err;
  IV j;

  if (!writer) {
    return;
  }
  msg_sv = newSVpvf(
    "Cannot return null for non-nullable field %s.%s.",
    parent_type_name ? parent_type_name : "(unknown)",
    field_name ? field_name : "(unknown)"
  );
  err = gql_runtime_vm_new_error_outcome_struct_for_path(aTHX_ msg_sv, path_frame);
  SvREFCNT_dec(msg_sv);
  if (err) {
    for (j = 0; j < err->error_record_count; j++) {
      gql_runtime_vm_writer_push_error_record(writer, err->error_records[j]);
    }
    gql_runtime_vm_outcome_decref(aTHX_ err);
  }
}

/* Non-Null list items ([T!]) for a list settled through the list_pending
 * machinery: a null item nulls the whole list. Records one error per null
 * item (with the item index in its path) and converts the outcome to a
 * null that carries its error, so the field-level check below propagates
 * it without stacking another message. */
static void
gql_runtime_vm_outcome_enforce_list_item_nonnull(
  pTHX_
  gql_runtime_vm_exec_state_handle_t *s,
  const gql_runtime_vm_pending_entry_t *entry,
  gql_runtime_vm_outcome_t *outcome
)
{
  const gql_runtime_vm_native_block_t *block;
  const gql_runtime_vm_native_slot_t *slot;
  int violated = 0;
  IV i;

  if (!s || !s->native_program || !outcome || !outcome->value
      || outcome->value->kind_code != GQL_VM_NATIVE_VALUE_LIST) {
    return;
  }
  if (entry->block_index < 0 || entry->block_index >= s->native_program->block_count) {
    return;
  }
  block = &s->native_program->blocks[entry->block_index];
  if (entry->slot_index < 0 || entry->slot_index >= block->slot_count) {
    return;
  }
  slot = &block->slots[entry->slot_index];
  if (!slot->item_non_null) {
    return;
  }

  for (i = 0; i < outcome->value->list.count; i++) {
    if (!gql_runtime_vm_native_value_is_null(outcome->value->list.items[i])) {
      continue;
    }
    violated = 1;
    {
      SV *item_key = newSViv(i);
      gql_runtime_vm_path_frame_t *item_path =
        gql_runtime_vm_new_path_frame_struct(aTHX_ entry->path_frame, item_key);
      gql_runtime_vm_record_nonnull_violation(
        aTHX_ s->writer, block->type_name, slot->field_name, item_path
      );
      gql_runtime_vm_path_frame_decref(item_path);
      SvREFCNT_dec(item_key);
    }
  }
  if (violated) {
    gql_runtime_vm_native_value_destroy(aTHX_ outcome->value);
    outcome->value = NULL;
    outcome->kind_code = GQL_VM_KIND_SCALAR;
    outcome->null_carries_error = 1;
  }
}

/* Non-Null propagation for the async lane (spec 6.4.4). After a field
 * value is stored into `frame`, if the field position is non-null and the
 * value is null, record "Cannot return null" (unless the null already
 * carried an error) and mark the frame to resolve as null. `entry` locates
 * the field's slot in native_program->blocks and carries its response
 * path. */
static void
gql_runtime_vm_frame_field_enforce_nonnull(
  pTHX_
  gql_runtime_vm_exec_state_handle_t *s,
  gql_runtime_vm_block_frame_t *frame,
  const gql_runtime_vm_pending_entry_t *entry,
  int value_is_null,
  int null_carries_error
)
{
  const gql_runtime_vm_native_block_t *block;
  const gql_runtime_vm_native_slot_t *slot;

  if (!value_is_null || !s || !s->native_program || !frame) {
    return;
  }
  if (entry->block_index < 0 || entry->block_index >= s->native_program->block_count) {
    return;
  }
  block = &s->native_program->blocks[entry->block_index];
  if (entry->slot_index < 0 || entry->slot_index >= block->slot_count) {
    return;
  }
  slot = &block->slots[entry->slot_index];
  if (slot->return_type_kind_code != 8) {
    return;
  }
  if (!null_carries_error) {
    gql_runtime_vm_record_nonnull_violation(
      aTHX_ s->writer, block->type_name, slot->field_name, entry->path_frame
    );
  }
  frame->self_nulled = 1;
}

static void
gql_runtime_vm_async_scheduler_process_frame(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  gql_runtime_vm_block_frame_t *frame
)
{
  while (frame) {
    IV i;
    gql_runtime_vm_block_frame_t next_pending;

    if (frame->pending_count == 0) {
      gql_runtime_vm_async_scheduler_resolve_frame(aTHX_ s, frame);
      return;
    }

    Zero(&next_pending, 1, gql_runtime_vm_block_frame_t);
    for (i = 0; i < frame->pending_count; i++) {
      gql_runtime_vm_pending_entry_t *entry = &frame->pending_entries[i];

      if (entry->state_code == GQL_VM_PENDING_STATE_WAITING_UNARMED
          || entry->state_code == GQL_VM_PENDING_STATE_WAITING_ARMED) {
        if (entry->payload_kind == GQL_VM_PENDING_LIST_PENDING_PTR
            && entry->payload.list_pending_ptr
            && entry->payload.list_pending_ptr->unresolved_count == 0) {
          /* ready list pending entries are consumed below */
        } else
        if (entry->payload_kind == GQL_VM_PENDING_BLOCK_FRAME_PTR) {
          gql_runtime_vm_pending_entry_t *next_entry =
            gql_runtime_vm_block_frame_push_pending_entry_with_meta(
              aTHX_
              &next_pending,
              entry->result_name_pv,
              entry->result_name_len,
              entry->result_name_pv_borrowed,
              entry->path_frame,
              entry->block_index,
              entry->slot_index,
              entry->op_index
            );
          next_entry->payload_kind = GQL_VM_PENDING_BLOCK_FRAME_PTR;
          next_entry->state_code = entry->state_code;
          next_entry->payload.block_frame_ptr = entry->payload.block_frame_ptr;
          next_entry->payload.block_frame_ptr->refcount++;
          next_entry->payload.block_frame_ptr->parent_entry_index = next_pending.pending_count - 1;
        } else if (entry->payload_kind == GQL_VM_PENDING_LIST_PENDING_PTR) {
          gql_runtime_vm_pending_entry_t *next_entry =
            gql_runtime_vm_block_frame_push_pending_entry_with_meta(
              aTHX_
              &next_pending,
              entry->result_name_pv,
              entry->result_name_len,
              entry->result_name_pv_borrowed,
              entry->path_frame,
              entry->block_index,
              entry->slot_index,
              entry->op_index
            );
          next_entry->payload_kind = GQL_VM_PENDING_LIST_PENDING_PTR;
          next_entry->state_code = entry->state_code;
          next_entry->payload.list_pending_ptr = entry->payload.list_pending_ptr;
          gql_runtime_vm_list_pending_incref(next_entry->payload.list_pending_ptr);
        } else {
          gql_runtime_vm_pending_entry_t *moved;
          gql_runtime_vm_block_frame_push_pending_pvn_with_meta(
            aTHX_
            &next_pending,
            entry->result_name_pv,
            entry->result_name_len,
            entry->result_name_pv_borrowed,
            entry->payload.promise_sv,
            entry->payload_kind,
            entry->path_frame,
            entry->block_index,
            entry->slot_index,
            entry->op_index
          );
          moved = &next_pending.pending_entries[next_pending.pending_count - 1];
          moved->state_code = entry->state_code;
          /* An armed entry's then-callbacks hold its index by value; the
           * rebuilt array compacts consumed entries away, so retarget the
           * contexts or a later settle lands on a stale index and the
           * value is silently dropped (frame deadlocks). */
          moved->armed_resolve_ctx = entry->armed_resolve_ctx;
          moved->armed_reject_ctx = entry->armed_reject_ctx;
          if (moved->armed_resolve_ctx) {
            ((gql_runtime_vm_pending_callback_ctx_t *)moved->armed_resolve_ctx)->entry_index =
              next_pending.pending_count - 1;
          }
          if (moved->armed_reject_ctx) {
            ((gql_runtime_vm_pending_callback_ctx_t *)moved->armed_reject_ctx)->entry_index =
              next_pending.pending_count - 1;
          }
        }
        if (!(entry->payload_kind == GQL_VM_PENDING_LIST_PENDING_PTR
              && entry->payload.list_pending_ptr
              && entry->payload.list_pending_ptr->unresolved_count == 0)) {
          continue;
        }
      }

      if (entry->payload_kind == GQL_VM_PENDING_LIST_PENDING_PTR) {
        gql_runtime_vm_outcome_t *outcome;

        if (!entry->payload.list_pending_ptr
            || entry->payload.list_pending_ptr->unresolved_count > 0
            || !entry->payload.list_pending_ptr->values_value) {
          gql_runtime_vm_pending_entry_t *next_entry =
            gql_runtime_vm_block_frame_push_pending_entry_with_meta(
              aTHX_
              &next_pending,
              entry->result_name_pv,
              entry->result_name_len,
              entry->result_name_pv_borrowed,
              entry->path_frame,
              entry->block_index,
              entry->slot_index,
              entry->op_index
            );
          next_entry->payload_kind = GQL_VM_PENDING_LIST_PENDING_PTR;
          next_entry->state_code = GQL_VM_PENDING_STATE_WAITING_ARMED;
          next_entry->payload.list_pending_ptr = entry->payload.list_pending_ptr;
          gql_runtime_vm_list_pending_incref(next_entry->payload.list_pending_ptr);
          continue;
        }

        outcome = gql_runtime_vm_new_outcome_from_owned_native_value_struct(
          aTHX_
          GQL_VM_KIND_LIST,
          entry->payload.list_pending_ptr->values_value
        );
        entry->payload.list_pending_ptr->values_value = NULL;
        gql_runtime_vm_outcome_enforce_list_item_nonnull(aTHX_ s, entry, outcome);
        {
          int vnull = gql_runtime_vm_native_value_is_null(outcome->value);
          int carries = outcome->null_carries_error || outcome->error_record_count > 0;
          gql_runtime_vm_consume_outcome_native_object(
            aTHX_
            frame->values_value,
            entry->result_name_pv,
            entry->result_name_pv_borrowed,
            outcome,
            s->writer
          );
          gql_runtime_vm_frame_field_enforce_nonnull(aTHX_ s, frame, entry, vnull, carries);
        }
        gql_runtime_vm_outcome_decref(aTHX_ outcome);
        continue;
      }

      if (entry->state_code == GQL_VM_PENDING_STATE_READY_OUTCOME
          || entry->payload_kind == GQL_VM_PENDING_OUTCOME_PTR) {
        int vnull = entry->payload.outcome_ptr
          && gql_runtime_vm_native_value_is_null(entry->payload.outcome_ptr->value);
        int carries = entry->payload.outcome_ptr
          && (entry->payload.outcome_ptr->null_carries_error
              || entry->payload.outcome_ptr->error_record_count > 0);
        gql_runtime_vm_consume_outcome_native_object(
          aTHX_
          frame->values_value,
          entry->result_name_pv,
          entry->result_name_pv_borrowed,
          entry->payload.outcome_ptr,
          s->writer
        );
        gql_runtime_vm_frame_field_enforce_nonnull(aTHX_ s, frame, entry, vnull, carries);
        continue;
      }

      if (entry->payload_kind == GQL_VM_PENDING_PROMISE_RESOLVED_VALUE_SV) {
        gql_runtime_vm_outcome_t *completed_outcome = NULL;
        SV *completed_sv = gql_runtime_vm_exec_state_complete_async_sv(
          aTHX_
          state_sv,
          s,
          entry->path_frame,
          entry->block_index,
          entry->slot_index,
          entry->op_index,
          entry->payload.promise_sv,
          &completed_outcome
        );

        if (completed_outcome) {
          int vnull = gql_runtime_vm_native_value_is_null(completed_outcome->value);
          int carries = completed_outcome->null_carries_error
            || completed_outcome->error_record_count > 0;
          gql_runtime_vm_consume_outcome_native_object(
            aTHX_
            frame->values_value,
            entry->result_name_pv,
            entry->result_name_pv_borrowed,
            completed_outcome,
            s->writer
          );
          gql_runtime_vm_frame_field_enforce_nonnull(aTHX_ s, frame, entry, vnull, carries);
          gql_runtime_vm_outcome_decref(aTHX_ completed_outcome);
        } else if (completed_sv && SvOK(completed_sv) && gql_runtime_vm_sv_is_outcome(aTHX_ completed_sv)) {
          gql_runtime_vm_outcome_t *co = gql_runtime_vm_expect_outcome(aTHX_ completed_sv);
          int vnull = gql_runtime_vm_native_value_is_null(co->value);
          int carries = co->null_carries_error || co->error_record_count > 0;
          gql_runtime_vm_consume_outcome_native_object(
            aTHX_
            frame->values_value,
            entry->result_name_pv,
            entry->result_name_pv_borrowed,
            co,
            s->writer
          );
          gql_runtime_vm_frame_field_enforce_nonnull(aTHX_ s, frame, entry, vnull, carries);
        } else if (completed_sv && SvOK(completed_sv)
                   && gql_runtime_vm_is_block_frame_value_sv(completed_sv)) {
          /* Mode 1: completion produced a pending child block. Link it into
           * the rebuilt pending array so the child's resolve_frame notifies
           * this frame directly - no promise in between. */
          gql_runtime_vm_block_frame_t *child_frame =
            gql_runtime_vm_expect_block_frame(aTHX_ completed_sv);
          gql_runtime_vm_pending_entry_t *next_entry =
            gql_runtime_vm_block_frame_push_pending_entry_with_meta(
              aTHX_
              &next_pending,
              entry->result_name_pv,
              entry->result_name_len,
              entry->result_name_pv_borrowed,
              entry->path_frame,
              entry->block_index,
              entry->slot_index,
              entry->op_index
            );
          next_entry->payload_kind = GQL_VM_PENDING_BLOCK_FRAME_PTR;
          next_entry->state_code = GQL_VM_PENDING_STATE_WAITING_ARMED;
          next_entry->payload.block_frame_ptr = child_frame;
          child_frame->refcount++;
          if (child_frame->parent_frame) {
            gql_runtime_vm_free_block_frame(aTHX_ child_frame->parent_frame);
          }
          child_frame->parent_frame = frame;
          frame->refcount++;
          child_frame->parent_entry_index = next_pending.pending_count - 1;
          if (child_frame->pending_unresolved == 0) {
            gql_runtime_vm_async_scheduler_enqueue_frame(s, child_frame);
          }
        } else if (completed_sv && SvOK(completed_sv)
                   && gql_runtime_vm_is_list_pending_value_sv(completed_sv)) {
          /* A late-resolving list field whose items pend again (child
           * blocks queueing loads) completes to a list-pending handle.
           * Adopt it like consume_current_result_now does; treating it as
           * a promise breaks the response. */
          gql_runtime_vm_list_pending_t *list_pending =
            gql_runtime_vm_expect_list_pending(aTHX_ completed_sv);
          gql_runtime_vm_pending_entry_t *next_entry =
            gql_runtime_vm_block_frame_push_pending_entry_with_meta(
              aTHX_
              &next_pending,
              entry->result_name_pv,
              entry->result_name_len,
              entry->result_name_pv_borrowed,
              entry->path_frame,
              entry->block_index,
              entry->slot_index,
              entry->op_index
            );
          next_entry->payload_kind = GQL_VM_PENDING_LIST_PENDING_PTR;
          next_entry->state_code = GQL_VM_PENDING_STATE_WAITING_ARMED;
          next_entry->payload.list_pending_ptr = list_pending;
          gql_runtime_vm_list_pending_incref(list_pending);
          if (list_pending->owner_frame) {
            gql_runtime_vm_free_block_frame(aTHX_ list_pending->owner_frame);
          }
          list_pending->owner_frame = frame;
          frame->refcount++;
        } else if (completed_sv && SvOK(completed_sv)) {
          gql_runtime_vm_block_frame_push_pending_pvn_with_meta(
            aTHX_
            &next_pending,
            entry->result_name_pv,
            entry->result_name_len,
            entry->result_name_pv_borrowed,
            completed_sv,
            GQL_VM_PENDING_PROMISE_SV,
            NULL,
            -1,
            -1,
            -1
          );
        }
        if (completed_sv) {
          SvREFCNT_dec(completed_sv);
        }
        continue;
      }

      if (entry->payload_kind == GQL_VM_PENDING_PROMISE_GENERIC_VALUE_SV
          || entry->payload_kind == GQL_VM_PENDING_PROMISE_SV) {
        int vnull = !entry->payload.promise_sv || !SvOK(entry->payload.promise_sv);
        gql_runtime_vm_consume_value_native_object(
          aTHX_
          frame->values_value,
          entry->result_name_pv,
          entry->result_name_pv_borrowed,
          entry->payload.promise_sv
        );
        /* A settled leaf value: a plain null in a non-null position needs
         * the error (nothing produced one upstream). */
        gql_runtime_vm_frame_field_enforce_nonnull(aTHX_ s, frame, entry, vnull, 0);
      }
    }

    gql_runtime_vm_block_frame_clear_pending(aTHX_ frame);
    /* clear_pending retains the array for pooled reuse; this frame swaps in
     * the rebuilt one instead, so the old buffer must go now. */
    Safefree(frame->pending_entries);
    frame->pending_entries = next_pending.pending_entries;
    frame->pending_count = next_pending.pending_count;
    frame->pending_capacity = next_pending.pending_capacity;
    frame->pending_unresolved = 0;

    if (frame->pending_count == 0) {
      gql_runtime_vm_async_scheduler_resolve_frame(aTHX_ s, frame);
      return;
    }

    gql_runtime_vm_async_scheduler_arm_frame(aTHX_ state_sv, s, frame);
    if (frame->pending_unresolved > 0) {
      return;
    }
  }
}

static void
gql_runtime_vm_async_scheduler_drain(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s
)
{
  if (!s || s->async_scheduler_draining) {
    return;
  }

  s->async_scheduler_draining = 1;
  while (s->async_ready_frame_count > 0) {
    gql_runtime_vm_block_frame_t *frame =
      s->async_ready_frames[--s->async_ready_frame_count];
    s->async_ready_frames[s->async_ready_frame_count] = NULL;
    if (!frame) {
      continue;
    }
    frame->queued = 0;
    gql_runtime_vm_async_scheduler_process_frame(aTHX_ state_sv, s, frame);
  }
  s->async_scheduler_draining = 0;
}

static SV *
gql_runtime_vm_pending_merge_resolve_sv(pTHX_ gql_runtime_vm_pending_merge_t *state, SV *resolved)
{
  AV *resolved_av = gql_runtime_vm_expect_arrayref(aTHX_ resolved, "resolved outcomes");
  SSize_t i;
  gql_runtime_vm_block_frame_t next_pending;
  U8 enqueued_ready_child = 0;
  gql_runtime_vm_exec_state_handle_t *exec_state =
    (state && state->state_sv) ? gql_runtime_vm_expect_exec_state_handle(aTHX_ state->state_sv) : NULL;

  Zero(&next_pending, 1, gql_runtime_vm_block_frame_t);

  for (i = 0; i <= av_len(resolved_av) && i < state->frame->pending_count; i++) {
    SV **outcome_svp = av_fetch(resolved_av, i, 0);
    gql_runtime_vm_pending_entry_t *entry = &state->frame->pending_entries[i];
    SV *resolved_sv = (outcome_svp && *outcome_svp) ? *outcome_svp : &PL_sv_undef;

    if (entry->payload_kind == GQL_VM_PENDING_PROMISE_GENERIC_VALUE_SV) {
      if (SvOK(resolved_sv) && !gql_runtime_vm_sv_is_outcome(aTHX_ resolved_sv)) {
        gql_runtime_vm_consume_value_native_object(
          aTHX_
          state->frame->values_value,
          entry->result_name_pv,
          entry->result_name_pv_borrowed,
          resolved_sv
        );
      } else {
        gql_runtime_vm_consume_outcome_native_object(
          aTHX_
          state->frame->values_value,
          entry->result_name_pv,
          entry->result_name_pv_borrowed,
          gql_runtime_vm_expect_outcome(aTHX_ resolved_sv),
          state->writer
        );
      }
    } else if (entry->payload_kind == GQL_VM_PENDING_PROMISE_RESOLVED_VALUE_SV) {
      if (SvOK(resolved_sv) && gql_runtime_vm_sv_is_outcome(aTHX_ resolved_sv)) {
        gql_runtime_vm_consume_outcome_native_object(
          aTHX_
          state->frame->values_value,
          entry->result_name_pv,
          entry->result_name_pv_borrowed,
          gql_runtime_vm_expect_outcome(aTHX_ resolved_sv),
          state->writer
        );
      } else {
        gql_runtime_vm_outcome_t *completed_outcome = NULL;
        SV *completed_sv;

        if (!exec_state || !state->state_sv) {
          croak("pending async completion requires an exec state");
        }
        completed_sv = gql_runtime_vm_exec_state_complete_async_sv(
          aTHX_
          state->state_sv,
          exec_state,
          entry->path_frame,
          entry->block_index,
          entry->slot_index,
          entry->op_index,
          resolved_sv,
          &completed_outcome
        );
        if (completed_outcome) {
          gql_runtime_vm_consume_outcome_native_object(
            aTHX_
            state->frame->values_value,
            entry->result_name_pv,
            entry->result_name_pv_borrowed,
            completed_outcome,
            state->writer
          );
          gql_runtime_vm_outcome_decref(aTHX_ completed_outcome);
        } else if (completed_sv && SvOK(completed_sv) && gql_runtime_vm_sv_is_outcome(aTHX_ completed_sv)) {
          gql_runtime_vm_consume_outcome_native_object(
            aTHX_
            state->frame->values_value,
            entry->result_name_pv,
            entry->result_name_pv_borrowed,
            gql_runtime_vm_expect_outcome(aTHX_ completed_sv),
            state->writer
          );
        } else if (completed_sv && SvOK(completed_sv)
                   && gql_runtime_vm_is_block_frame_value_sv(completed_sv)) {
          /* Mode 1: completion produced a pending child block; link it to
           * this frame like the scheduler's resolved-value branch does. */
          gql_runtime_vm_block_frame_t *child_frame =
            gql_runtime_vm_expect_block_frame(aTHX_ completed_sv);
          gql_runtime_vm_pending_entry_t *next_entry =
            gql_runtime_vm_block_frame_push_pending_entry_with_meta(
              aTHX_
              &next_pending,
              entry->result_name_pv,
              entry->result_name_len,
              entry->result_name_pv_borrowed,
              entry->path_frame,
              entry->block_index,
              entry->slot_index,
              entry->op_index
            );
          next_entry->payload_kind = GQL_VM_PENDING_BLOCK_FRAME_PTR;
          next_entry->state_code = GQL_VM_PENDING_STATE_WAITING_ARMED;
          next_entry->payload.block_frame_ptr = child_frame;
          child_frame->refcount++;
          if (child_frame->parent_frame) {
            gql_runtime_vm_free_block_frame(aTHX_ child_frame->parent_frame);
          }
          child_frame->parent_frame = state->frame;
          state->frame->refcount++;
          child_frame->parent_entry_index = next_pending.pending_count - 1;
          if (child_frame->pending_unresolved == 0) {
            /* Drain happens after the pending swap below: resolve_frame
             * writes into the parent's installed entry array. */
            gql_runtime_vm_async_scheduler_enqueue_frame(exec_state, child_frame);
            enqueued_ready_child = 1;
          }
        } else if (completed_sv && SvOK(completed_sv)
                   && gql_runtime_vm_is_list_pending_value_sv(completed_sv)) {
          /* Same adoption as the scheduler's resolved-value branch. */
          gql_runtime_vm_list_pending_t *list_pending =
            gql_runtime_vm_expect_list_pending(aTHX_ completed_sv);
          gql_runtime_vm_pending_entry_t *next_entry =
            gql_runtime_vm_block_frame_push_pending_entry_with_meta(
              aTHX_
              &next_pending,
              entry->result_name_pv,
              entry->result_name_len,
              entry->result_name_pv_borrowed,
              entry->path_frame,
              entry->block_index,
              entry->slot_index,
              entry->op_index
            );
          next_entry->payload_kind = GQL_VM_PENDING_LIST_PENDING_PTR;
          next_entry->state_code = GQL_VM_PENDING_STATE_WAITING_ARMED;
          next_entry->payload.list_pending_ptr = list_pending;
          gql_runtime_vm_list_pending_incref(list_pending);
          if (list_pending->owner_frame) {
            gql_runtime_vm_free_block_frame(aTHX_ list_pending->owner_frame);
          }
          list_pending->owner_frame = state->frame;
          state->frame->refcount++;
        } else if (completed_sv && SvOK(completed_sv)) {
          gql_runtime_vm_block_frame_push_pending_pvn_with_meta(
            aTHX_
            &next_pending,
            entry->result_name_pv,
            entry->result_name_len,
            entry->result_name_pv_borrowed,
            completed_sv,
            GQL_VM_PENDING_PROMISE_SV,
            NULL,
            -1,
            -1,
            -1
          );
        }
        if (completed_sv) {
          SvREFCNT_dec(completed_sv);
        }
      }
    } else if (entry->payload_kind == GQL_VM_PENDING_PROMISE_SV) {
      if (SvOK(resolved_sv) && gql_runtime_vm_sv_is_outcome(aTHX_ resolved_sv)) {
        gql_runtime_vm_consume_outcome_native_object(
          aTHX_
          state->frame->values_value,
          entry->result_name_pv,
          entry->result_name_pv_borrowed,
          gql_runtime_vm_expect_outcome(aTHX_ resolved_sv),
          state->writer
        );
      } else {
        gql_runtime_vm_consume_value_native_object(
          aTHX_
          state->frame->values_value,
          entry->result_name_pv,
          entry->result_name_pv_borrowed,
          resolved_sv
        );
      }
    }
  }

  gql_runtime_vm_block_frame_clear_pending(aTHX_ state->frame);
  /* clear_pending retains the array for pooled reuse; this frame swaps in
   * the rebuilt one instead, so the old buffer must go now. */
  Safefree(state->frame->pending_entries);
  state->frame->pending_entries = next_pending.pending_entries;
  state->frame->pending_count = next_pending.pending_count;
  state->frame->pending_capacity = next_pending.pending_capacity;

  if (enqueued_ready_child && exec_state && !exec_state->async_scheduler_draining) {
    gql_runtime_vm_async_scheduler_drain(aTHX_ state->state_sv, exec_state);
  }

  if (state->frame->pending_count > 0) {
    return gql_runtime_vm_block_frame_finalize_sv(
      aTHX_
      state->frame,
      GQL_VM_PROMISE_BACKEND_PROMISE_XS,
      state->writer,
      state->state_sv,
      0
    );
  }
  return gql_runtime_vm_native_value_materialize_sv(aTHX_ state->frame->values_value);
}

static XS(gql_runtime_vm_xs_pending_callback)
{
  dVAR;
  dXSARGS;
  gql_runtime_vm_pending_callback_ctx_t *ctx = INT2PTR(
    gql_runtime_vm_pending_callback_ctx_t *,
    CvXSUBANY(cv).any_ptr
  );
  SV *resolved_sv = &PL_sv_undef;
  SV *tmp_resolved = NULL;
  gql_runtime_vm_exec_state_handle_t *state = NULL;
  gql_runtime_vm_pending_entry_t *entry = NULL;

  if (!ctx || !ctx->state_sv || !ctx->frame) {
    XSRETURN_UNDEF;
  }

  if (items == 1) {
    resolved_sv = ST(0) ? ST(0) : &PL_sv_undef;
  } else if (items > 1) {
    AV *resolved_av = newAV();
    I32 i;
    for (i = 0; i < items; i++) {
      av_push(resolved_av, newSVsv(ST(i) ? ST(i) : &PL_sv_undef));
    }
    tmp_resolved = newRV_noinc((SV *)resolved_av);
    resolved_sv = tmp_resolved;
  }
  state = gql_runtime_vm_expect_exec_state_handle(aTHX_ ctx->state_sv);
  if (ctx->entry_index < 0 || ctx->entry_index >= ctx->frame->pending_count) {
    if (tmp_resolved) {
      SvREFCNT_dec(tmp_resolved);
    }
    XSRETURN_UNDEF;
  }

  entry = &ctx->frame->pending_entries[ctx->entry_index];
  if (SvOK(resolved_sv) && gql_runtime_vm_sv_is_outcome(aTHX_ resolved_sv)) {
    gql_runtime_vm_async_pending_entry_store_outcome(aTHX_ entry, resolved_sv);
  } else {
    gql_runtime_vm_async_pending_entry_store_sv(aTHX_ entry, resolved_sv);
  }

  if (ctx->frame->pending_unresolved > 0) {
    ctx->frame->pending_unresolved--;
  }
  if (ctx->frame->pending_unresolved == 0) {
    gql_runtime_vm_async_scheduler_enqueue_frame(state, ctx->frame);
    if (!state->async_scheduler_draining) {
      gql_runtime_vm_async_scheduler_drain(aTHX_ ctx->state_sv, state);
    }
  }

  if (tmp_resolved) {
    SvREFCNT_dec(tmp_resolved);
  }
  /* Last: nothing below may touch ctx once the pair is parked. */
  gql_runtime_vm_pending_callback_pair_recycle(aTHX_ ctx);
  XSRETURN_UNDEF;
}

/* Rejection arm for a directly-subscribed pending entry. The entry holds
 * the user promise itself (no normalizing then() in between), so the
 * rejection reason arrives raw here: convert it into an error outcome for
 * the entry's path and settle the entry exactly like the resolve arm. */
static XS(gql_runtime_vm_xs_pending_reject_callback)
{
  dVAR;
  dXSARGS;
  gql_runtime_vm_pending_callback_ctx_t *ctx = INT2PTR(
    gql_runtime_vm_pending_callback_ctx_t *,
    CvXSUBANY(cv).any_ptr
  );
  SV *reason_sv = items > 0 && ST(0) ? ST(0) : &PL_sv_undef;
  gql_runtime_vm_exec_state_handle_t *state = NULL;
  gql_runtime_vm_pending_entry_t *entry = NULL;

  if (!ctx || !ctx->state_sv || !ctx->frame) {
    XSRETURN_UNDEF;
  }
  state = gql_runtime_vm_expect_exec_state_handle(aTHX_ ctx->state_sv);
  if (ctx->entry_index < 0 || ctx->entry_index >= ctx->frame->pending_count) {
    XSRETURN_UNDEF;
  }

  entry = &ctx->frame->pending_entries[ctx->entry_index];
  if (SvOK(reason_sv) && gql_runtime_vm_sv_is_outcome(aTHX_ reason_sv)) {
    gql_runtime_vm_async_pending_entry_store_outcome(aTHX_ entry, reason_sv);
  } else {
    SV *outcome_sv = gql_runtime_vm_new_error_outcome_for_path_sv(
      aTHX_
      reason_sv,
      entry->path_frame
    );
    gql_runtime_vm_async_pending_entry_store_outcome(aTHX_ entry, outcome_sv);
    SvREFCNT_dec(outcome_sv);
  }

  if (ctx->frame->pending_unresolved > 0) {
    ctx->frame->pending_unresolved--;
  }
  if (ctx->frame->pending_unresolved == 0) {
    gql_runtime_vm_async_scheduler_enqueue_frame(state, ctx->frame);
    if (!state->async_scheduler_draining) {
      gql_runtime_vm_async_scheduler_drain(aTHX_ ctx->state_sv, state);
    }
  }

  /* Last: nothing below may touch ctx once the pair is parked. */
  gql_runtime_vm_pending_callback_pair_recycle(aTHX_ ctx);
  XSRETURN_UNDEF;
}

static XS(gql_runtime_vm_xs_list_pending_callback)
{
  dVAR;
  dXSARGS;
  gql_runtime_vm_list_pending_callback_ctx_t *ctx = INT2PTR(
    gql_runtime_vm_list_pending_callback_ctx_t *,
    CvXSUBANY(cv).any_ptr
  );
  SV *resolved_sv = &PL_sv_undef;
  SV *tmp_resolved = NULL;
  gql_runtime_vm_exec_state_handle_t *state = NULL;

  if (!ctx || !ctx->pending || !ctx->pending->values_value || !ctx->state_sv) {
    XSRETURN_UNDEF;
  }

  if (items == 1) {
    resolved_sv = ST(0) ? ST(0) : &PL_sv_undef;
  } else if (items > 1) {
    AV *resolved_av = newAV();
    I32 i;
    for (i = 0; i < items; i++) {
      av_push(resolved_av, newSVsv(ST(i) ? ST(i) : &PL_sv_undef));
    }
    tmp_resolved = newRV_noinc((SV *)resolved_av);
    resolved_sv = tmp_resolved;
  }
  state = gql_runtime_vm_expect_exec_state_handle(aTHX_ ctx->state_sv);

  /* Outcomes carry error records (rejected items, failed child fields);
   * surface them in the response instead of collapsing to a silent null. */
  if (resolved_sv && SvOK(resolved_sv)
      && gql_runtime_vm_sv_is_outcome(aTHX_ resolved_sv)
      && state->writer) {
    gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_expect_outcome(aTHX_ resolved_sv);
    IV j;
    for (j = 0; outcome && j < outcome->error_record_count; j++) {
      gql_runtime_vm_writer_push_error_record(state->writer, outcome->error_records[j]);
    }
  }

  gql_runtime_vm_native_list_store_at(
    aTHX_
    ctx->pending->values_value,
    ctx->index,
    gql_runtime_vm_native_value_from_list_pending_sv(aTHX_ resolved_sv)
  );
  if (ctx->pending->unresolved_count > 0) {
    ctx->pending->unresolved_count--;
  }
  if (ctx->pending->unresolved_count == 0 && ctx->pending->owner_frame) {
    gql_runtime_vm_async_scheduler_enqueue_frame(state, ctx->pending->owner_frame);
    if (!state->async_scheduler_draining) {
      gql_runtime_vm_async_scheduler_drain(aTHX_ ctx->state_sv, state);
    }
  }

  if (tmp_resolved) {
    SvREFCNT_dec(tmp_resolved);
  }
  XSRETURN_UNDEF;
}

/* Then-callback for a list item that arrived as a promise: run the item's
 * child selection block once the item settles. Returning the child result
 * (a value, a nested promise - flattened by Promise::XS - or an error
 * Outcome) lets the ordinary list_pending machinery consume it. */
static XS(gql_runtime_vm_xs_list_item_child_callback)
{
  dVAR;
  dXSARGS;
  gql_runtime_vm_list_item_child_ctx_t *ctx = INT2PTR(
    gql_runtime_vm_list_item_child_ctx_t *,
    CvXSUBANY(cv).any_ptr
  );
  SV *resolved_sv = items > 0 && ST(0) ? ST(0) : &PL_sv_undef;
  SV *ret = NULL;
  gql_runtime_vm_exec_state_handle_t *s;

  if (!ctx || !ctx->state_sv) {
    XSRETURN_UNDEF;
  }
  s = gql_runtime_vm_expect_exec_state_handle(aTHX_ ctx->state_sv);

  if (!resolved_sv || !SvOK(resolved_sv)) {
    ret = newSVsv(&PL_sv_undef);
  } else if (gql_runtime_vm_sv_is_outcome(aTHX_ resolved_sv)) {
    ret = newSVsv(resolved_sv);
  } else {
    IV item_block_index = ctx->child_block_index;

    if (item_block_index < 0 && ctx->op) {
      /* Abstract-typed list: the member block depends on the settled
       * value, so it is picked here rather than at subscription time. */
      SV *type_error_sv = NULL;
      item_block_index = gql_runtime_vm_abstract_list_item_block_index(
        aTHX_
        ctx->state_sv,
        s,
        ctx->op,
        ctx->slot,
        resolved_sv,
        ctx->path_frame,
        &type_error_sv
      );
      if (type_error_sv && SvOK(type_error_sv)) {
        ret = gql_runtime_vm_new_error_outcome_for_path_sv(aTHX_ type_error_sv, ctx->path_frame);
        SvREFCNT_dec(type_error_sv);
        ST(0) = sv_2mortal(ret);
        XSRETURN(1);
      }
    }
    if (item_block_index < 0 && !ctx->op && ctx->slot) {
      /* Leaf list item settled from a promise: result coercion against
       * the inner type (armed with a slot but no op / block index). */
      SV *leaf_error = NULL;
      ret = gql_runtime_vm_serialize_leaf_sv(
        aTHX_ gql_runtime_vm_exec_state_native_runtime(aTHX_ s), ctx->slot, resolved_sv, &leaf_error
      );
      if (leaf_error) {
        ret = gql_runtime_vm_new_error_outcome_for_path_sv(aTHX_ leaf_error, ctx->path_frame);
        SvREFCNT_dec(leaf_error);
      }
    } else if (item_block_index < 0) {
      ret = newSVsv(resolved_sv);
    } else {
      /* Mode 2: sync completion yields a native outcome; the list_pending
       * consumer converts outcomes without materializing. */
      ret = gql_runtime_vm_exec_state_execute_block_async_path_sv(
        aTHX_
        ctx->state_sv,
        s,
        item_block_index,
        resolved_sv,
        ctx->path_frame,
        2
      );
    }
  }

  ST(0) = sv_2mortal(ret ? ret : newSVsv(&PL_sv_undef));
  XSRETURN(1);
}

static XS(gql_runtime_vm_xs_error_callback)
{
  dVAR;
  dXSARGS;
  gql_runtime_vm_error_callback_ctx_t *ctx = INT2PTR(
    gql_runtime_vm_error_callback_ctx_t *,
    CvXSUBANY(cv).any_ptr
  );
  SV *error_sv = items > 0 && ST(0) ? ST(0) : &PL_sv_undef;
  SV *ret = gql_runtime_vm_new_error_outcome_for_path_sv(
    aTHX_
    error_sv,
    ctx ? ctx->path_frame : NULL
  );

  ST(0) = sv_2mortal(ret ? ret : newSVsv(&PL_sv_undef));
  XSRETURN(1);
}

static XS(gql_runtime_vm_xs_finalize_callback)
{
  dVAR;
  dXSARGS;
  gql_runtime_vm_finalize_callback_ctx_t *ctx = INT2PTR(
    gql_runtime_vm_finalize_callback_ctx_t *,
    CvXSUBANY(cv).any_ptr
  );
  SV *resolved_sv = &PL_sv_undef;
  SV *tmp_resolved = NULL;
  SV *ret;

  if (!ctx || !ctx->merge) {
    XSRETURN_UNDEF;
  }

  if (items == 1 && ST(0) && SvROK(ST(0)) && SvTYPE(SvRV(ST(0))) == SVt_PVAV) {
    resolved_sv = ST(0);
  } else {
    AV *resolved_av = newAV();
    I32 i;
    for (i = 0; i < items; i++) {
      av_push(resolved_av, newSVsv(ST(i) ? ST(i) : &PL_sv_undef));
    }
    tmp_resolved = newRV_noinc((SV *)resolved_av);
    resolved_sv = tmp_resolved;
  }

  ret = gql_runtime_vm_pending_merge_resolve_sv(aTHX_ ctx->merge, resolved_sv);
  if (tmp_resolved) {
    SvREFCNT_dec(tmp_resolved);
  }

  ST(0) = sv_2mortal(ret ? ret : newSVsv(&PL_sv_undef));
  XSRETURN(1);
}

static SV *
gql_runtime_vm_new_error_callback_sv(pTHX_ gql_runtime_vm_path_frame_t *path_frame)
{
  CV *cv;
  SV *rv;
  gql_runtime_vm_error_callback_ctx_t *ctx;

  Newxz(ctx, 1, gql_runtime_vm_error_callback_ctx_t);
  ctx->path_frame = path_frame;
  if (ctx->path_frame) {
    ctx->path_frame->refcount++;
  }

  cv = newXS(NULL, gql_runtime_vm_xs_error_callback, __FILE__);
  CvXSUBANY(cv).any_ptr = ctx;
  gql_runtime_vm_attach_callback_magic_ptr(aTHX_ (SV *)cv, &gql_runtime_vm_error_callback_ctx_vtbl, ctx);
  rv = newRV_noinc((SV *)cv);
  return rv;
}

static SV *
gql_runtime_vm_new_list_item_child_callback_sv(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_path_frame_t *path_frame,
  IV child_block_index,
  const gql_runtime_vm_native_op_t *op,
  const gql_runtime_vm_native_slot_t *slot
)
{
  CV *cv;
  SV *rv;
  gql_runtime_vm_list_item_child_ctx_t *ctx;

  Newxz(ctx, 1, gql_runtime_vm_list_item_child_ctx_t);
  ctx->state_sv = state_sv ? SvREFCNT_inc_simple_NN(state_sv) : NULL;
  ctx->path_frame = path_frame;
  if (ctx->path_frame) {
    ctx->path_frame->refcount++;
  }
  ctx->child_block_index = child_block_index;
  ctx->op = op;
  ctx->slot = slot;

  cv = newXS(NULL, gql_runtime_vm_xs_list_item_child_callback, __FILE__);
  CvXSUBANY(cv).any_ptr = ctx;
  gql_runtime_vm_attach_callback_magic_ptr(aTHX_ (SV *)cv, &gql_runtime_vm_list_item_child_ctx_vtbl, ctx);
  rv = newRV_noinc((SV *)cv);
  return rv;
}

static SV *
gql_runtime_vm_new_finalize_callback_sv(pTHX_ gql_runtime_vm_pending_merge_t *merge)
{
  CV *cv;
  SV *rv;
  gql_runtime_vm_finalize_callback_ctx_t *ctx;

  Newxz(ctx, 1, gql_runtime_vm_finalize_callback_ctx_t);
  ctx->merge = merge;
  gql_runtime_vm_pending_merge_incref(merge);

  cv = newXS(NULL, gql_runtime_vm_xs_finalize_callback, __FILE__);
  CvXSUBANY(cv).any_ptr = ctx;
  gql_runtime_vm_attach_callback_magic_ptr(aTHX_ (SV *)cv, &gql_runtime_vm_finalize_callback_ctx_vtbl, ctx);
  rv = newRV_noinc((SV *)cv);
  return rv;
}

static SV *
gql_runtime_vm_new_outcome_handle_sv(pTHX_ U8 kind_code, SV *value, SV *error_records)
{
  gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_outcome_struct(
    aTHX_
    kind_code,
    value ? value : &PL_sv_undef,
    error_records ? error_records : &PL_sv_undef
  );
  SV *ret = gql_runtime_vm_wrap_outcome_sv(aTHX_ outcome);
  gql_runtime_vm_outcome_decref(aTHX_ outcome);
  return ret;
}

/* Sync-completion results for callers that consume outcome structs directly
 * (outcome_out != NULL): hand over a caller-owned struct and skip the
 * bless-then-DESTROY round trip of an SV handle, which the block execution
 * loops otherwise pay once per field. */
static SV *
gql_runtime_vm_sync_outcome_result_sv(
  pTHX_
  U8 kind_code,
  SV *value,
  gql_runtime_vm_outcome_t **outcome_out
)
{
  if (outcome_out) {
    *outcome_out = gql_runtime_vm_new_outcome_struct(
      aTHX_
      kind_code,
      value ? value : &PL_sv_undef,
      &PL_sv_undef
    );
    return NULL;
  }
  return gql_runtime_vm_new_outcome_handle_sv(aTHX_ kind_code, value, &PL_sv_undef);
}

/* Passthrough for a value that is already a wrapped outcome handle SV. */
static SV *
gql_runtime_vm_outcome_result_from_handle_sv(
  pTHX_
  SV *handle_sv,
  gql_runtime_vm_outcome_t **outcome_out
)
{
  if (outcome_out) {
    *outcome_out = gql_runtime_vm_expect_outcome(aTHX_ handle_sv);
    gql_runtime_vm_outcome_incref(*outcome_out);
    SvREFCNT_dec(handle_sv);
    return NULL;
  }
  return handle_sv;
}

static SV *
gql_runtime_vm_call_then_promise_xs_sv(
  pTHX_
  SV *promise_sv,
  SV *callback_sv,
  SV *error_callback_sv,
  gql_runtime_vm_path_frame_t *path_frame
)
{
  dSP;
  SV *ret = NULL;
  SV *stack_ret = NULL;

  if (!promise_sv || !SvOK(promise_sv) || !gql_runtime_vm_is_promise_xs_value_sv(promise_sv)) {
    return gql_runtime_vm_call_callback_scalar_sv(
      aTHX_
      callback_sv,
      promise_sv ? promise_sv : &PL_sv_undef,
      path_frame
    );
  }

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  XPUSHs(promise_sv ? promise_sv : &PL_sv_undef);
  XPUSHs(callback_sv ? callback_sv : &PL_sv_undef);
  if (error_callback_sv) {
    XPUSHs(error_callback_sv);
  }
  PUTBACK;
  {
    CV *then_cv = gql_runtime_vm_promise_xs_then_cv_get(aTHX);
    if (then_cv) {
      call_sv((SV *)then_cv, G_SCALAR | G_EVAL);
    } else {
      call_method("then", G_SCALAR | G_EVAL);
    }
  }
  SPAGAIN;
  if (SP > PL_stack_base) {
    stack_ret = POPs;
  }
  if (SvTRUE(ERRSV)) {
    ret = gql_runtime_vm_new_error_outcome_for_path_sv(
      aTHX_
      ERRSV,
      path_frame
    );
    sv_setsv(ERRSV, &PL_sv_undef);
  } else if (stack_ret) {
    ret = stack_ret ? newSVsv(stack_ret) : newSVsv(&PL_sv_undef);
  }
  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret ? ret : newSVsv(&PL_sv_undef);
}

static SV *
gql_runtime_vm_call_all_promise_xs_sv(
  pTHX_
  AV *values_av,
  gql_runtime_vm_path_frame_t *path_frame
)
{
  dSP;
  SV *aggregate = NULL;
  SV *flatten_callback_sv = NULL;
  SV *ret = NULL;
  SSize_t i;

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  for (i = 0; values_av && i <= av_len(values_av); i++) {
    SV **svp = av_fetch(values_av, i, 0);
    XPUSHs((svp && *svp) ? *svp : &PL_sv_undef);
  }
  PUTBACK;
  call_pv("Promise::XS::all", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && SP > PL_stack_base) {
    aggregate = POPs;
    aggregate = aggregate ? newSVsv(aggregate) : newSVsv(&PL_sv_undef);
  } else if (SP > PL_stack_base) {
    (void)POPs;
  }
  if (SvTRUE(ERRSV)) {
    ret = gql_runtime_vm_new_error_outcome_for_path_sv(
      aTHX_
      ERRSV,
      path_frame
    );
    sv_setsv(ERRSV, &PL_sv_undef);
  }
  PUTBACK;
  FREETMPS;
  LEAVE;

  if (ret) {
    return ret;
  }
  if (!aggregate) {
    return newSVsv(&PL_sv_undef);
  }

  flatten_callback_sv = gql_runtime_vm_promise_xs_flatten_all_callback_sv(aTHX);
  ret = gql_runtime_vm_call_then_promise_xs_sv(
    aTHX_
    aggregate,
    flatten_callback_sv,
    NULL,
    path_frame
  );
  SvREFCNT_dec(flatten_callback_sv);
  SvREFCNT_dec(aggregate);

  return ret ? ret : newSVsv(&PL_sv_undef);
}

static SV *
gql_runtime_vm_promise_xs_new_deferred_sv(pTHX)
{
  dSP;
  SV *ret = NULL;

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  PUTBACK;
  {
    static CV *deferred_cv = NULL;
    if (!deferred_cv) {
      deferred_cv = get_cv("Promise::XS::deferred", 0);
      if (deferred_cv) {
        SvREFCNT_inc_simple_void_NN((SV *)deferred_cv);
      }
    }
    if (deferred_cv) {
      call_sv((SV *)deferred_cv, G_SCALAR | G_EVAL);
    } else {
      call_pv("Promise::XS::deferred", G_SCALAR | G_EVAL);
    }
  }
  SPAGAIN;
  if (!SvTRUE(ERRSV) && SP > PL_stack_base) {
    SV *stack_ret = POPs;
    ret = stack_ret ? newSVsv(stack_ret) : newSVsv(&PL_sv_undef);
  } else if (SP > PL_stack_base) {
    (void)POPs;
  }
  PUTBACK;
  FREETMPS;
  LEAVE;

  if (!ret || !SvOK(ret)) {
    croak("failed to create Promise::XS deferred");
  }
  return ret;
}

static SV *
gql_runtime_vm_promise_xs_deferred_promise_sv(pTHX_ SV *deferred_sv)
{
  dSP;
  SV *ret = NULL;

  if (!deferred_sv || !SvOK(deferred_sv)) {
    return newSVsv(&PL_sv_undef);
  }

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  XPUSHs(deferred_sv);
  PUTBACK;
  call_method("promise", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && SP > PL_stack_base) {
    SV *stack_ret = POPs;
    ret = stack_ret ? newSVsv(stack_ret) : newSVsv(&PL_sv_undef);
  } else if (SP > PL_stack_base) {
    (void)POPs;
  }
  PUTBACK;
  FREETMPS;
  LEAVE;

  if (!ret || !SvOK(ret)) {
    croak("failed to fetch Promise::XS deferred promise");
  }
  return ret;
}

static void
gql_runtime_vm_promise_xs_deferred_resolve_sv(pTHX_ SV *deferred_sv, SV *value_sv)
{
  dSP;

  if (!deferred_sv || !SvOK(deferred_sv)) {
    return;
  }

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  XPUSHs(deferred_sv);
  XPUSHs(value_sv ? value_sv : &PL_sv_undef);
  PUTBACK;
  call_pv("GraphQL::Houtou::Promise::PromiseXS::resolve_deferred_xs", G_VOID | G_EVAL);
  SPAGAIN;
  if (SvTRUE(ERRSV)) {
    SV *error_sv = newSVsv(ERRSV);
    sv_setsv(ERRSV, &PL_sv_undef);
    PUTBACK;
    FREETMPS;
    LEAVE;
    croak("failed to resolve Promise::XS deferred: %s", SvPV_nolen(error_sv));
  }
  PUTBACK;
  FREETMPS;
  LEAVE;
}

static SV *
gql_runtime_vm_new_list_pending_callback_sv(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_list_pending_t *pending,
  IV index
)
{
  CV *cv;
  SV *rv;
  gql_runtime_vm_list_pending_callback_ctx_t *ctx;

  Newxz(ctx, 1, gql_runtime_vm_list_pending_callback_ctx_t);
  ctx->pending = pending;
  ctx->state_sv = state_sv ? SvREFCNT_inc_simple_NN(state_sv) : NULL;
  gql_runtime_vm_list_pending_incref(pending);
  ctx->index = index;

  cv = newXS(NULL, gql_runtime_vm_xs_list_pending_callback, __FILE__);
  CvXSUBANY(cv).any_ptr = ctx;
  gql_runtime_vm_attach_callback_magic_ptr(aTHX_ (SV *)cv, &gql_runtime_vm_list_pending_callback_ctx_vtbl, ctx);
  rv = newRV_noinc((SV *)cv);
  return rv;
}

static SV *
gql_runtime_vm_list_pending_handle_sv(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  AV *values_av,
  gql_runtime_vm_path_frame_t *path_frame
)
{
  gql_runtime_vm_list_pending_t *pending;
  SSize_t i;

  if (!values_av) {
    return gql_runtime_vm_new_outcome_from_owned_native_value_handle_sv(
      aTHX_
      GQL_VM_KIND_LIST,
      gql_runtime_vm_new_native_value_list()
    );
  }

  Newxz(pending, 1, gql_runtime_vm_list_pending_t);
  pending->refcount = 1;
  pending->owner_frame = NULL;
  pending->values_value = gql_runtime_vm_new_native_value_list();
  pending->unresolved_count = 0;

  for (i = 0; i <= av_len(values_av); i++) {
    SV **svp = av_fetch(values_av, i, 0);
    SV *value_sv = (svp && *svp) ? *svp : &PL_sv_undef;

    if (gql_runtime_vm_is_promise_value_for_state_sv(aTHX_ s, value_sv)) {
      pending->unresolved_count++;
      gql_runtime_vm_native_list_store_at(
        aTHX_
        pending->values_value,
        i,
        gql_runtime_vm_new_native_value_scalar(aTHX_ &PL_sv_undef)
      );
    } else {
      /* Freshly completed sync item: the values AV is its sole owner. */
      gql_runtime_vm_native_list_store_at(
        aTHX_
        pending->values_value,
        i,
        gql_runtime_vm_native_value_take_completed_item_sv(aTHX_ value_sv)
      );
    }
  }

  for (i = 0; i <= av_len(values_av); i++) {
    SV **svp = av_fetch(values_av, i, 0);
    SV *value_sv = (svp && *svp) ? *svp : &PL_sv_undef;

    if (gql_runtime_vm_is_promise_value_for_state_sv(aTHX_ s, value_sv)) {
      SV *callback_sv = gql_runtime_vm_new_list_pending_callback_sv(aTHX_ state_sv, pending, i);
      SV *error_callback_sv = gql_runtime_vm_new_error_callback_sv(aTHX_ path_frame);
      SV *ret;

      ret = gql_runtime_vm_call_then_promise_for_state_sv(
        aTHX_
        s,
        value_sv,
        callback_sv,
        error_callback_sv,
        path_frame
      );

      SvREFCNT_dec(callback_sv);
      SvREFCNT_dec(error_callback_sv);

      if (ret && SvOK(ret) && gql_runtime_vm_sv_is_outcome(aTHX_ ret)) {
        gql_runtime_vm_native_list_store_at(
          aTHX_
          pending->values_value,
          i,
          gql_runtime_vm_native_value_from_list_pending_sv(aTHX_ ret)
        );
        pending->unresolved_count--;
      }
      if (ret) {
        SvREFCNT_dec(ret);
      }
    }
  }
  {
    SV *ret = gql_runtime_vm_wrap_list_pending_sv(aTHX_ pending);
    gql_runtime_vm_list_pending_decref(aTHX_ pending);
    return ret;
  }
}

static SV *
gql_runtime_vm_call_then_promise_for_state_sv(
  pTHX_
  const gql_runtime_vm_exec_state_handle_t *s,
  SV *promise_sv,
  SV *callback_sv,
  SV *error_callback_sv,
  gql_runtime_vm_path_frame_t *path_frame
)
{
  if (s && s->promise_backend_code == GQL_VM_PROMISE_BACKEND_PROMISE_XS) {
    return gql_runtime_vm_call_then_promise_xs_sv(
      aTHX_
      promise_sv,
      callback_sv,
      error_callback_sv,
      path_frame
    );
  }
  croak("async runtime requires Promise::XS");
}

static SV *
gql_runtime_vm_exec_state_resolve_runtime_type_current_sv(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  SV *resolved_sv,
  gql_runtime_vm_path_frame_t *path_frame,
  SV **error_out
)
{
  const gql_runtime_vm_native_slot_t *slot = (s && s->cursor) ? gql_runtime_vm_cursor_current_native_slot(s->cursor) : NULL;
  return gql_runtime_vm_exec_state_resolve_runtime_type_for_slot_sv(
    aTHX_
    state_sv,
    s,
    slot,
    resolved_sv,
    path_frame,
    error_out
  );
}

static SV *
gql_runtime_vm_exec_state_resolve_runtime_type_for_slot_sv(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  const gql_runtime_vm_native_slot_t *slot,
  SV *resolved_sv,
  gql_runtime_vm_path_frame_t *path_frame,
  SV **error_out
)
{
  const gql_runtime_vm_native_runtime_t *runtime = gql_runtime_vm_exec_state_native_runtime(aTHX_ s);
  SV *abstract_type_sv = gql_runtime_vm_state_return_type_for_slot_sv(aTHX_ s, slot);
  SV *info_sv = NULL;
  HV *schema_hv;
  SV *runtime_cache_sv;
  SV *runtime_type_sv;

  if (error_out) {
    *error_out = NULL;
  }

  slot = gql_runtime_vm_effective_slot(runtime, slot);
  if (!slot || !slot->return_type_name || !*slot->return_type_name) {
    return NULL;
  }

  info_sv = gql_runtime_vm_new_lazy_info_for_path_sv(aTHX_ state_sv, s, path_frame);
  schema_hv = gql_runtime_vm_expect_hashref(aTHX_ s->runtime_schema, "runtime schema");
  runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ schema_hv, "runtime_cache", 13);
  runtime_type_sv = gql_runtime_vm_resolve_runtime_type_for_abstract_sv(
    aTHX_
    runtime_cache_sv,
    slot->return_type_name,
    resolved_sv,
    s->context,
    info_sv,
    abstract_type_sv,
    error_out
  );
  SvREFCNT_dec(info_sv);

  return runtime_type_sv;
}

/* Pick the member block for one item of an abstract-typed list. Returns
 * -1 without an error only for null items; a present item that fails to
 * resolve to a member type sets *error_out (field error per the spec). */
static IV
gql_runtime_vm_abstract_list_item_block_index(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  const gql_runtime_vm_native_op_t *op,
  const gql_runtime_vm_native_slot_t *slot,
  SV *item_sv,
  gql_runtime_vm_path_frame_t *item_path,
  SV **error_out
)
{
  SV *runtime_type_sv;
  IV child_block_index = -1;

  if (error_out) {
    *error_out = NULL;
  }
  if (!item_sv || !SvOK(item_sv) || !op || op->abstract_child_count <= 0) {
    return -1;
  }

  runtime_type_sv = gql_runtime_vm_exec_state_resolve_runtime_type_for_slot_sv(
    aTHX_
    state_sv,
    s,
    slot,
    item_sv,
    item_path,
    error_out
  );
  if (error_out && *error_out) {
    if (runtime_type_sv) {
      SvREFCNT_dec(runtime_type_sv);
    }
    return -1;
  }
  if (runtime_type_sv && SvOK(runtime_type_sv)) {
    child_block_index = gql_runtime_vm_find_abstract_child_block_index(
      op,
      gql_runtime_vm_type_name_from_sv(aTHX_ runtime_type_sv)
    );
  }
  if (runtime_type_sv) {
    SvREFCNT_dec(runtime_type_sv);
  }
  /* A present item whose member type cannot be resolved is a field error
   * (the -1/no-error return is reserved for null items). */
  if (child_block_index < 0 && error_out && !*error_out) {
    *error_out = newSVpvf(
      "Abstract type %s must resolve to an Object type at runtime",
      slot && slot->return_type_name ? slot->return_type_name : "(unknown)"
    );
  }
  return child_block_index;
}

static SV *
gql_runtime_vm_exec_state_complete_current_native_async_sv(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  gql_runtime_vm_path_frame_t *path_frame,
  const gql_runtime_vm_native_op_t *op,
  const gql_runtime_vm_native_slot_t *slot,
  SV *resolved_sv,
  gql_runtime_vm_outcome_t **outcome_out
)
{
  const gql_runtime_vm_native_runtime_t *runtime = gql_runtime_vm_exec_state_native_runtime(aTHX_ s);
  IV complete_code = op ? op->complete_code : 0;

  slot = gql_runtime_vm_effective_slot(runtime, slot);

  switch (complete_code) {
    case GQL_VM_COMPLETE_OBJECT:
    {
      IV child_block_index = op ? op->child_block_index : -1;
      SV *child_value;

      if (!resolved_sv || !SvOK(resolved_sv)) {
        return gql_runtime_vm_sync_outcome_result_sv(aTHX_ GQL_VM_KIND_SCALAR, &PL_sv_undef, outcome_out);
      }
      if (child_block_index < 0) {
        return gql_runtime_vm_sync_outcome_result_sv(aTHX_ GQL_VM_KIND_SCALAR, resolved_sv, outcome_out);
      }

      /* Mode 1: a synchronously completed child comes back as a native
       * outcome (returned as-is below) and a pending child as a raw
       * block-frame handle - no Promise::XS deferred/promise pair. Every
       * consumer of this value (consume_current_result_now, the scheduler's
       * resolved-value branch, pending merge) links handles into the
       * parent frame directly. */
      child_value = gql_runtime_vm_exec_state_execute_block_async_path_sv(
        aTHX_
        state_sv,
        s,
        child_block_index,
        resolved_sv,
        path_frame,
        1
      );
      if (gql_runtime_vm_is_block_frame_value_sv(child_value)) {
        return child_value;
      }
      if (child_value && SvOK(child_value) && gql_runtime_vm_sv_is_outcome(aTHX_ child_value)) {
        return gql_runtime_vm_outcome_result_from_handle_sv(aTHX_ child_value, outcome_out);
      }
      if (gql_runtime_vm_is_promise_value_for_state_sv(aTHX_ s, child_value)) {
        SV *callback_sv = gql_runtime_vm_wrap_object_outcome_callback_sv(aTHX);
        SV *ret = gql_runtime_vm_call_then_promise_for_state_sv(
          aTHX_
          s,
          child_value,
          callback_sv,
          NULL,
          path_frame
        );
        SvREFCNT_dec(callback_sv);
        SvREFCNT_dec(child_value);
        return ret;
      }

      {
        SV *ret = gql_runtime_vm_sync_outcome_result_sv(aTHX_ GQL_VM_KIND_OBJECT, child_value, outcome_out);
        SvREFCNT_dec(child_value);
        return ret;
      }
    }
    case GQL_VM_COMPLETE_LIST:
    {
      IV child_block_index = op ? op->child_block_index : -1;
      int abstract_items = (child_block_index < 0 && op && op->abstract_child_count > 0);
      AV *items_av;
      AV *resolved_items_av;
      SSize_t i;
      int has_promise = 0;

      if (!resolved_sv || !SvOK(resolved_sv)) {
        return gql_runtime_vm_sync_outcome_result_sv(aTHX_ GQL_VM_KIND_SCALAR, &PL_sv_undef, outcome_out);
      }
      if (!SvROK(resolved_sv) || SvTYPE(SvRV(resolved_sv)) != SVt_PVAV) {
        /* Non-list resolver result for a list field: field error + null,
         * never the raw value (same contract as the fast lanes). */
        SV *msg_sv = newSVpvs("list value must be an array reference");
        SV *ret = gql_runtime_vm_new_error_outcome_for_path_sv(aTHX_ msg_sv, path_frame);
        SvREFCNT_dec(msg_sv);
        return ret;
      }

      items_av = (AV *)SvRV(resolved_sv);
      resolved_items_av = newAV();
      for (i = 0; i <= av_len(items_av); i++) {
        SV **item_svp = av_fetch(items_av, i, 0);
        SV *item_sv = (item_svp && *item_svp) ? *item_svp : &PL_sv_undef;
        SV *item_result;

        if (child_block_index >= 0 || abstract_items) {
          SV *item_key = newSViv(i);
          gql_runtime_vm_path_frame_t *item_path =
            gql_runtime_vm_new_path_frame_struct(aTHX_ path_frame, item_key);
          if (gql_runtime_vm_is_promise_value_for_state_sv(aTHX_ s, item_sv)) {
            /* The item itself is a promise (per-item loader shape). Defer
             * the child selection block until it settles; the derived
             * promise below resolves to the completed child value. For
             * abstract items the member block is picked at settle time. */
            SV *child_cb = gql_runtime_vm_new_list_item_child_callback_sv(
              aTHX_ state_sv, item_path, child_block_index,
              abstract_items ? op : NULL,
              abstract_items ? slot : NULL
            );
            SV *error_cb = gql_runtime_vm_new_error_callback_sv(aTHX_ item_path);
            item_result = gql_runtime_vm_call_then_promise_for_state_sv(
              aTHX_ s, item_sv, child_cb, error_cb, item_path
            );
            SvREFCNT_dec(child_cb);
            SvREFCNT_dec(error_cb);
          } else {
            /* A null item completes as null: keep the block index at -1 so
             * it falls into the raw-value branch below. */
            IV item_block_index = SvOK(item_sv) ? child_block_index : -1;
            SV *type_error_sv = NULL;

            if (abstract_items && SvOK(item_sv)) {
              item_block_index = gql_runtime_vm_abstract_list_item_block_index(
                aTHX_ state_sv, s, op, slot, item_sv, item_path, &type_error_sv
              );
            }
            if (type_error_sv && SvOK(type_error_sv)) {
              item_result = gql_runtime_vm_new_error_outcome_for_path_sv(
                aTHX_ type_error_sv, item_path
              );
              SvREFCNT_dec(type_error_sv);
            } else if (item_block_index < 0) {
              /* No matching member (or a null item): complete the raw
               * value, mirroring COMPLETE_ABSTRACT's fallback. */
              item_result = newSVsv(item_sv);
            } else {
              /* Mode 2: sync items come back as native outcomes (assembled
               * into the list natively below), pending items as promises
               * (routed through the list_pending machinery). */
              item_result = gql_runtime_vm_exec_state_execute_block_async_path_sv(
                aTHX_
                state_sv,
                s,
                item_block_index,
                item_sv,
                item_path,
                2
              );
            }
          }
          gql_runtime_vm_path_frame_decref(item_path);
          SvREFCNT_dec(item_key);
        } else if (gql_runtime_vm_is_promise_value_for_state_sv(aTHX_ s, item_sv)) {
          /* Leaf list with a per-item promise: defer result coercion to
           * settle time (the list-item callback with block index -1 and a
           * slot but no op runs serialize_leaf_sv on the settled value). */
          SV *item_key = newSViv(i);
          gql_runtime_vm_path_frame_t *item_path =
            gql_runtime_vm_new_path_frame_struct(aTHX_ path_frame, item_key);
          SV *child_cb = gql_runtime_vm_new_list_item_child_callback_sv(
            aTHX_ state_sv, item_path, -1, NULL, slot
          );
          SV *error_cb = gql_runtime_vm_new_error_callback_sv(aTHX_ item_path);
          item_result = gql_runtime_vm_call_then_promise_for_state_sv(
            aTHX_ s, item_sv, child_cb, error_cb, item_path
          );
          SvREFCNT_dec(child_cb);
          SvREFCNT_dec(error_cb);
          gql_runtime_vm_path_frame_decref(item_path);
          SvREFCNT_dec(item_key);
        } else {
          /* Leaf list item: result coercion against the inner type. */
          SV *leaf_error = NULL;
          item_result = gql_runtime_vm_serialize_leaf_sv(
            aTHX_ gql_runtime_vm_exec_state_native_runtime(aTHX_ s), slot, item_sv, &leaf_error
          );
          if (leaf_error) {
            SV *item_key = newSViv(i);
            gql_runtime_vm_path_frame_t *item_path =
              gql_runtime_vm_new_path_frame_struct(aTHX_ path_frame, item_key);
            item_result = gql_runtime_vm_new_error_outcome_for_path_sv(
              aTHX_ leaf_error, item_path
            );
            SvREFCNT_dec(leaf_error);
            gql_runtime_vm_path_frame_decref(item_path);
            SvREFCNT_dec(item_key);
          }
        }

        if (gql_runtime_vm_is_promise_value_for_state_sv(aTHX_ s, item_result)) {
          has_promise = 1;
        }
        av_push(resolved_items_av, item_result);
      }

      if (has_promise) {
        SV *ret = gql_runtime_vm_list_pending_handle_sv(
          aTHX_
          state_sv,
          s,
          resolved_items_av,
          path_frame
        );
        SvREFCNT_dec((SV *)resolved_items_av);
        return ret;
      }

      {
        /* All items completed synchronously (native outcomes or plain
         * scalars): assemble the native list directly instead of wrapping
         * the SV array and reconverting it. */
        gql_runtime_vm_native_value_t *list_value = gql_runtime_vm_new_native_value_list();
        int item_null_violation = 0;
        for (i = 0; i <= av_len(resolved_items_av); i++) {
          SV **item_svp = av_fetch(resolved_items_av, i, 0);
          SV *completed_item_sv = (item_svp && *item_svp) ? *item_svp : &PL_sv_undef;
          gql_runtime_vm_native_value_t *item_native;
          /* Outcomes carry error records (unresolvable member types);
           * surface them before the value is flattened into the list,
           * mirroring the list_pending settle path. */
          if (SvOK(completed_item_sv)
              && gql_runtime_vm_sv_is_outcome(aTHX_ completed_item_sv)
              && s->writer) {
            gql_runtime_vm_outcome_t *item_outcome =
              gql_runtime_vm_expect_outcome(aTHX_ completed_item_sv);
            IV k;
            for (k = 0; item_outcome && k < item_outcome->error_record_count; k++) {
              gql_runtime_vm_writer_push_error_record(s->writer, item_outcome->error_records[k]);
            }
          }
          item_native = gql_runtime_vm_native_value_take_completed_item_sv(aTHX_ completed_item_sv);

          /* Non-Null list items ([T!]): a null item nulls the whole list.
           * The item's own error (if any) is already surfaced above; add
           * "Cannot return null" only when the null carries no error. */
          if (slot->item_non_null && gql_runtime_vm_native_value_is_null(item_native)) {
            int carries = SvOK(completed_item_sv)
              && gql_runtime_vm_sv_is_outcome(aTHX_ completed_item_sv)
              && (gql_runtime_vm_expect_outcome(aTHX_ completed_item_sv)->null_carries_error
                  || gql_runtime_vm_expect_outcome(aTHX_ completed_item_sv)->error_record_count > 0);
            if (!carries && s->writer) {
              const gql_runtime_vm_native_block_t *parent_block =
                (s && s->cursor) ? gql_runtime_vm_cursor_current_native_block(s->cursor) : NULL;
              SV *item_key = newSViv(i);
              gql_runtime_vm_path_frame_t *item_path =
                gql_runtime_vm_new_path_frame_struct(aTHX_ path_frame, item_key);
              SV *msg_sv = newSVpvf(
                "Cannot return null for non-nullable field %s.%s.",
                parent_block && parent_block->type_name ? parent_block->type_name : "(unknown)",
                slot && slot->field_name ? slot->field_name : "(unknown)"
              );
              gql_runtime_vm_outcome_t *err = gql_runtime_vm_new_error_outcome_struct_for_path(
                aTHX_ msg_sv, item_path
              );
              IV k;
              for (k = 0; err && k < err->error_record_count; k++) {
                gql_runtime_vm_writer_push_error_record(s->writer, err->error_records[k]);
              }
              if (err) {
                gql_runtime_vm_outcome_decref(aTHX_ err);
              }
              SvREFCNT_dec(msg_sv);
              gql_runtime_vm_path_frame_decref(item_path);
              SvREFCNT_dec(item_key);
            }
            item_null_violation = 1;
          }
          gql_runtime_vm_native_list_push(list_value, item_native);
        }
        SvREFCNT_dec((SV *)resolved_items_av);
        if (item_null_violation) {
          /* The whole list nulls; the null carries its error upward. */
          gql_runtime_vm_outcome_t *o =
            gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_SCALAR, &PL_sv_undef, &PL_sv_undef);
          o->null_carries_error = 1;
          gql_runtime_vm_native_value_destroy(aTHX_ list_value);
          if (outcome_out) {
            *outcome_out = o;
            return NULL;
          }
          {
            SV *ret = gql_runtime_vm_wrap_outcome_sv(aTHX_ o);
            gql_runtime_vm_outcome_decref(aTHX_ o);
            return ret;
          }
        }
        if (outcome_out) {
          *outcome_out = gql_runtime_vm_new_outcome_from_owned_native_value_struct(
            aTHX_ GQL_VM_KIND_LIST, list_value
          );
          return NULL;
        }
        return gql_runtime_vm_new_outcome_from_owned_native_value_handle_sv(
          aTHX_ GQL_VM_KIND_LIST, list_value
        );
      }
    }
    case GQL_VM_COMPLETE_ABSTRACT:
    {
      SV *runtime_error_sv = NULL;
      SV *runtime_type_sv;
      IV child_block_index = -1;

      if (!resolved_sv || !SvOK(resolved_sv)) {
        return gql_runtime_vm_sync_outcome_result_sv(aTHX_ GQL_VM_KIND_SCALAR, &PL_sv_undef, outcome_out);
      }

      runtime_type_sv = gql_runtime_vm_exec_state_resolve_runtime_type_for_slot_sv(
        aTHX_
        state_sv,
        s,
        slot,
        resolved_sv,
        path_frame,
        &runtime_error_sv
      );
      if (runtime_error_sv && SvOK(runtime_error_sv)) {
        SV *ret = gql_runtime_vm_new_error_outcome_for_path_sv(
          aTHX_
          runtime_error_sv,
          path_frame
        );
        SvREFCNT_dec(runtime_error_sv);
        return ret;
      }
      if (runtime_type_sv && SvOK(runtime_type_sv)) {
        child_block_index = gql_runtime_vm_find_abstract_child_block_index(
          op,
          gql_runtime_vm_type_name_from_sv(aTHX_ runtime_type_sv)
        );
      }
      if (runtime_type_sv) {
        SvREFCNT_dec(runtime_type_sv);
      }
      if (child_block_index < 0) {
        /* Unresolvable member type: field error + null, never the raw
         * source value (same contract as the fast lanes). */
        SV *msg_sv = newSVpvf(
          "Abstract type %s must resolve to an Object type at runtime",
          slot && slot->return_type_name ? slot->return_type_name : "(unknown)"
        );
        SV *ret = gql_runtime_vm_new_error_outcome_for_path_sv(aTHX_ msg_sv, path_frame);
        SvREFCNT_dec(msg_sv);
        return ret;
      }

      {
        /* Mode 1: same contract as the COMPLETE_OBJECT child above. */
        SV *child_value = gql_runtime_vm_exec_state_execute_block_async_path_sv(
          aTHX_
          state_sv,
          s,
          child_block_index,
          resolved_sv,
          path_frame,
          1
        );
        if (gql_runtime_vm_is_block_frame_value_sv(child_value)) {
          return child_value;
        }
        if (child_value && SvOK(child_value) && gql_runtime_vm_sv_is_outcome(aTHX_ child_value)) {
          return gql_runtime_vm_outcome_result_from_handle_sv(aTHX_ child_value, outcome_out);
        }
        if (gql_runtime_vm_is_promise_value_for_state_sv(aTHX_ s, child_value)) {
          SV *callback_sv = gql_runtime_vm_wrap_object_outcome_callback_sv(aTHX);
          SV *ret = gql_runtime_vm_call_then_promise_for_state_sv(
            aTHX_
            s,
            child_value,
            callback_sv,
            NULL,
            path_frame
          );
          SvREFCNT_dec(callback_sv);
          SvREFCNT_dec(child_value);
          return ret;
        }

        {
          SV *ret = gql_runtime_vm_sync_outcome_result_sv(aTHX_ GQL_VM_KIND_OBJECT, child_value, outcome_out);
          SvREFCNT_dec(child_value);
          return ret;
        }
      }
    }
    case GQL_VM_COMPLETE_GENERIC:
    default:
    {
      /* Leaf result coercion; a failure is a field error + null. */
      SV *leaf_error = NULL;
      SV *serialized = gql_runtime_vm_serialize_leaf_sv(
        aTHX_ runtime, slot, resolved_sv, &leaf_error
      );
      if (leaf_error) {
        SV *ret = gql_runtime_vm_new_error_outcome_for_path_sv(aTHX_ leaf_error, path_frame);
        SvREFCNT_dec(leaf_error);
        return ret;
      }
      {
        SV *ret = gql_runtime_vm_sync_outcome_result_sv(aTHX_ GQL_VM_KIND_SCALAR, serialized, outcome_out);
        SvREFCNT_dec(serialized);
        return ret;
      }
    }
  }
}

static SV *
gql_runtime_vm_state_current_return_type_sv(pTHX_ gql_runtime_vm_exec_state_handle_t *s, SV *op_sv, SV *slot_sv)
{
  const gql_runtime_vm_native_slot_t *native_slot;
  SV *type_name_sv;

  native_slot = (s && s->cursor) ? gql_runtime_vm_cursor_current_native_slot(s->cursor) : NULL;
  if (native_slot) {
    return gql_runtime_vm_state_return_type_for_slot_sv(aTHX_ s, native_slot);
  }

  type_name_sv = gql_runtime_vm_op_slot_sv(aTHX_ op_sv, 8);
  if (!type_name_sv || !SvOK(type_name_sv)) {
    return NULL;
  }

  return gql_runtime_vm_state_type_by_name_sv(aTHX_ s, type_name_sv);
}

static SV *
gql_runtime_vm_state_return_type_for_slot_sv(
  pTHX_
  gql_runtime_vm_exec_state_handle_t *s,
  const gql_runtime_vm_native_slot_t *slot
)
{
  const gql_runtime_vm_native_runtime_t *runtime = gql_runtime_vm_exec_state_native_runtime(aTHX_ s);
  SV *type_name_sv;

  slot = gql_runtime_vm_effective_slot(runtime, slot);
  if (!slot || !slot->return_type_name || !*slot->return_type_name) {
    return NULL;
  }

  type_name_sv = sv_2mortal(newSVpv(slot->return_type_name, 0));
  return gql_runtime_vm_state_type_by_name_sv(aTHX_ s, type_name_sv);
}

static SV *
gql_runtime_vm_state_current_resolver_sv(pTHX_ gql_runtime_vm_exec_state_handle_t *s)
{
  const gql_runtime_vm_native_runtime_t *runtime;
  const gql_runtime_vm_native_slot_t *slot;

  runtime = gql_runtime_vm_exec_state_native_runtime(aTHX_ s);
  slot = (s && s->cursor) ? gql_runtime_vm_cursor_current_native_slot(s->cursor) : NULL;

  if (!runtime || !runtime->callback_catalog || !slot) {
    return NULL;
  }
  if (!runtime->callback_catalog->slot_resolvers) {
    return NULL;
  }
  if (slot->schema_slot_index < 0 || slot->schema_slot_index >= runtime->runtime_slot_count) {
    return NULL;
  }
  return runtime->callback_catalog->slot_resolvers[slot->schema_slot_index];
}

static SV *
gql_runtime_vm_state_type_by_name_sv(pTHX_ gql_runtime_vm_exec_state_handle_t *s, SV *type_name_sv)
{
  SV *runtime_schema_sv;
  HV *schema_hv;
  SV *runtime_cache_sv;
  HV *runtime_cache_hv;
  SV *name2type_sv;
  HE *he;

  if (!type_name_sv || !SvOK(type_name_sv)) {
    return NULL;
  }

  runtime_schema_sv = s ? s->runtime_schema : NULL;
  if (!runtime_schema_sv || !SvOK(runtime_schema_sv) || !SvROK(runtime_schema_sv) || SvTYPE(SvRV(runtime_schema_sv)) != SVt_PVHV) {
    return NULL;
  }
  schema_hv = (HV *)SvRV(runtime_schema_sv);
  runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ schema_hv, "runtime_cache", 13);
  if (!runtime_cache_sv || !SvOK(runtime_cache_sv) || !SvROK(runtime_cache_sv) || SvTYPE(SvRV(runtime_cache_sv)) != SVt_PVHV) {
    return NULL;
  }
  runtime_cache_hv = (HV *)SvRV(runtime_cache_sv);
  name2type_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_cache_hv, "name2type", 9);
  if (!name2type_sv || !SvOK(name2type_sv) || !SvROK(name2type_sv) || SvTYPE(SvRV(name2type_sv)) != SVt_PVHV) {
    return NULL;
  }
  he = hv_fetch_ent((HV *)SvRV(name2type_sv), type_name_sv, 0, 0);
  return he ? HeVAL(he) : NULL;
}

static IV
gql_runtime_vm_program_find_block_index_sv(pTHX_ SV *program_sv, SV *block_sv)
{
  AV *program_av;
  SV **blocks_svp;
  AV *blocks_av;
  IV i;

  if (!program_sv || !SvOK(program_sv) || !SvROK(program_sv) || SvTYPE(SvRV(program_sv)) != SVt_PVAV) {
    return -1;
  }
  if (!block_sv || !SvOK(block_sv)) {
    return -1;
  }
  if (!SvROK(block_sv) && looks_like_number(block_sv)) {
    return SvIV(block_sv);
  }

  program_av = (AV *)SvRV(program_sv);
  blocks_svp = av_fetch(program_av, 4, 0);
  if (!blocks_svp || !*blocks_svp || !SvOK(*blocks_svp) || !SvROK(*blocks_svp) || SvTYPE(SvRV(*blocks_svp)) != SVt_PVAV) {
    return -1;
  }
  blocks_av = (AV *)SvRV(*blocks_svp);
  for (i = 0; i <= av_len(blocks_av); i++) {
    SV **svp = av_fetch(blocks_av, i, 0);
    if (svp && *svp && sv_eq(*svp, block_sv)) {
      return i;
    }
  }
  return -1;
}

static IV
gql_runtime_vm_block_index_from_sv(pTHX_ gql_runtime_vm_exec_state_handle_t *s, SV *block_sv)
{
  if (block_sv && SvOK(block_sv) && !SvROK(block_sv) && looks_like_number(block_sv)) {
    return SvIV(block_sv);
  }
  return gql_runtime_vm_program_find_block_index_sv(aTHX_ s ? s->program : NULL, block_sv);
}

static char *
gql_runtime_vm_copy_cstr(const char *src)
{
  STRLEN len;
  char *dst;
  if (!src) {
    return NULL;
  }
  len = (STRLEN)strlen(src);
  Newx(dst, len + 1, char);
  Copy(src, dst, len, char);
  dst[len] = '\0';
  return dst;
}

static SV *
gql_runtime_vm_lazy_info_materialize_hash_sv(pTHX_ gql_runtime_vm_lazy_info_t *info)
{
  HV *info_hv;
  SV *runtime_cache_sv = &PL_sv_undef;
  SV *schema_sv = &PL_sv_undef;
  SV *parent_type_sv = NULL;
  SV *return_type_sv = NULL;
  SV *path_sv = &PL_sv_undef;

  if (!info) {
    return newRV_noinc((SV *)newHV());
  }
  if (info->materialized_sv) {
    return newSVsv(info->materialized_sv);
  }

  info_hv = newHV();

  if (info->field_name_sv && SvOK(info->field_name_sv)) {
    hv_store(info_hv, "field_name", 10, newSVsv(info->field_name_sv), 0);
  } else if (info->field_name_pv) {
    hv_store(info_hv, "field_name", 10, newSVpv(info->field_name_pv, 0), 0);
  }

  return_type_sv = info->return_type_sv;
  if (!return_type_sv && info->runtime_schema && info->return_type_name_pv) {
    return_type_sv = gql_runtime_vm_lookup_type_object_by_name_sv(
      aTHX_ info->runtime_schema,
      info->return_type_name_pv
    );
  }
  if (return_type_sv && SvOK(return_type_sv)) {
    hv_store(info_hv, "return_type", 11, newSVsv(return_type_sv), 0);
  } else if (info->return_type_name_pv) {
    hv_store(info_hv, "return_type_name", 16, newSVpv(info->return_type_name_pv, 0), 0);
  }

  parent_type_sv = info->parent_type_sv;
  if (!parent_type_sv && info->runtime_schema && info->parent_type_name_pv) {
    parent_type_sv = gql_runtime_vm_lookup_type_object_by_name_sv(
      aTHX_ info->runtime_schema,
      info->parent_type_name_pv
    );
  }
  if (parent_type_sv && SvOK(parent_type_sv)) {
    hv_store(info_hv, "parent_type", 11, newSVsv(parent_type_sv), 0);
  } else if (info->parent_type_name_pv) {
    hv_store(info_hv, "parent_type_name", 16, newSVpv(info->parent_type_name_pv, 0), 0);
  }

  if (info->path_frame) {
    path_sv = gql_runtime_vm_path_frame_to_path_sv(aTHX_ info->path_frame);
  }
  hv_store(info_hv, "path", 4, path_sv ? path_sv : newSVsv(&PL_sv_undef), 0);

  hv_store(info_hv, "field_nodes", 11, newSVsv(&PL_sv_undef), 0);
  hv_store(info_hv, "context_value", 13, newSVsv(info->context_value ? info->context_value : &PL_sv_undef), 0);
  hv_store(info_hv, "root_value", 10, newSVsv(info->root_value ? info->root_value : &PL_sv_undef), 0);
  hv_store(info_hv, "variable_values", 15, newSVsv(info->variable_values ? info->variable_values : &PL_sv_undef), 0);
  hv_store(info_hv, "operation", 9, newSVsv(info->operation ? info->operation : &PL_sv_undef), 0);
  hv_store(info_hv, "runtime_schema", 14, newSVsv(info->runtime_schema ? info->runtime_schema : &PL_sv_undef), 0);
  hv_store(info_hv, "directives", 10, newSVsv(info->directives ? info->directives : &PL_sv_undef), 0);
  hv_store(info_hv, "block_index", 11, newSViv(info->block_index), 0);
  hv_store(info_hv, "op_index", 8, newSViv(info->op_index), 0);

  if (info->runtime_schema
      && SvROK(info->runtime_schema)
      && SvTYPE(SvRV(info->runtime_schema)) == SVt_PVHV) {
    HV *runtime_schema_hv = (HV *)SvRV(info->runtime_schema);
    SV *sv;

    sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_schema_hv, "runtime_cache", 13);
    if (sv && SvOK(sv)) {
      runtime_cache_sv = sv;
    }
    sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_schema_hv, "schema", 6);
    if (sv && SvOK(sv)) {
      schema_sv = sv;
    }
  }

  hv_store(info_hv, "runtime_cache", 13, newSVsv(runtime_cache_sv), 0);
  hv_store(info_hv, "schema", 6, newSVsv(schema_sv), 0);

  info->materialized_sv = newRV_noinc((SV *)info_hv);
  return newSVsv(info->materialized_sv);
}

static void
gql_runtime_vm_lazy_info_decref(pTHX_ gql_runtime_vm_lazy_info_t *info)
{
  if (!info) {
    return;
  }
  if (--info->refcount > 0) {
    return;
  }

  SvREFCNT_dec(info->field_name_sv);
  Safefree(info->field_name_pv);
  SvREFCNT_dec(info->parent_type_sv);
  Safefree(info->parent_type_name_pv);
  Safefree(info->return_type_name_pv);
  SvREFCNT_dec(info->return_type_sv);
  gql_runtime_vm_path_frame_decref(info->path_frame);
  SvREFCNT_dec(info->context_value);
  SvREFCNT_dec(info->root_value);
  SvREFCNT_dec(info->variable_values);
  SvREFCNT_dec(info->operation);
  SvREFCNT_dec(info->runtime_schema);
  SvREFCNT_dec(info->directives);
  SvREFCNT_dec(info->materialized_sv);
  Safefree(info);
}

static SV *
gql_runtime_vm_new_lazy_info_handle_sv(
  pTHX_
  SV *field_name_sv,
  const char *field_name_pv,
  SV *parent_type_sv,
  const char *parent_type_name_pv,
  const char *return_type_name_pv,
  SV *return_type_sv,
  gql_runtime_vm_path_frame_t *path_frame,
  SV *context_value,
  SV *root_value,
  SV *variable_values,
  SV *operation,
  SV *runtime_schema,
  SV *directives,
  IV block_index,
  IV op_index
)
{
  gql_runtime_vm_lazy_info_t *info;

  Newxz(info, 1, gql_runtime_vm_lazy_info_t);
  info->refcount = 1;
  info->field_name_sv = field_name_sv ? SvREFCNT_inc_simple_NN(field_name_sv) : NULL;
  info->field_name_pv = gql_runtime_vm_copy_cstr(field_name_pv);
  info->parent_type_sv = parent_type_sv ? SvREFCNT_inc_simple_NN(parent_type_sv) : NULL;
  info->parent_type_name_pv = gql_runtime_vm_copy_cstr(parent_type_name_pv);
  info->return_type_name_pv = gql_runtime_vm_copy_cstr(return_type_name_pv);
  info->return_type_sv = return_type_sv ? SvREFCNT_inc_simple_NN(return_type_sv) : NULL;
  if (path_frame) {
    path_frame->refcount++;
  }
  info->path_frame = path_frame;
  info->context_value = context_value ? SvREFCNT_inc_simple_NN(context_value) : NULL;
  info->root_value = root_value ? SvREFCNT_inc_simple_NN(root_value) : NULL;
  info->variable_values = variable_values ? SvREFCNT_inc_simple_NN(variable_values) : NULL;
  info->operation = operation ? SvREFCNT_inc_simple_NN(operation) : NULL;
  info->runtime_schema = runtime_schema ? SvREFCNT_inc_simple_NN(runtime_schema) : NULL;
  info->directives = directives ? SvREFCNT_inc_simple_NN(directives) : NULL;
  info->block_index = block_index;
  info->op_index = op_index;

  return gql_runtime_vm_new_handle_sv(aTHX_ "GraphQL::Houtou::Runtime::LazyInfo", info);
}

static SV *
gql_runtime_vm_new_lazy_info_for_path_sv(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  gql_runtime_vm_path_frame_t *path_ptr
)
{
  const gql_runtime_vm_native_block_t *block = (s && s->cursor)
    ? gql_runtime_vm_cursor_current_native_block(s->cursor)
    : NULL;
  const gql_runtime_vm_native_slot_t *slot = (s && s->cursor)
    ? gql_runtime_vm_cursor_current_native_slot(s->cursor)
    : NULL;
  const gql_runtime_vm_native_runtime_t *runtime = s
    ? gql_runtime_vm_exec_state_native_runtime(aTHX_ s)
    : NULL;
  gql_runtime_vm_native_callback_catalog_t *catalog = runtime ? runtime->callback_catalog : NULL;
  SV *return_type_sv = NULL;
  SV *field_name_sv = NULL;

  PERL_UNUSED_ARG(state_sv);
  if (!path_ptr && s && s->field_frame) {
    path_ptr = s->field_frame->path_frame;
  }
  if (runtime && slot) {
    return_type_sv = gql_runtime_vm_direct_slot_type_object_sv(runtime, slot);
  }
  if (catalog
      && catalog->slot_field_names
      && slot
      && slot->schema_slot_index >= 0
      && slot->schema_slot_index < runtime->runtime_slot_count) {
    field_name_sv = catalog->slot_field_names[slot->schema_slot_index];
  }

  return gql_runtime_vm_new_lazy_info_handle_sv(
    aTHX_
    field_name_sv,
    slot ? slot->field_name : NULL,
    block ? block->type_object_sv : NULL,
    block ? block->type_name : NULL,
    slot ? slot->return_type_name : NULL,
    return_type_sv,
    path_ptr,
    s ? s->context : &PL_sv_undef,
    s ? s->root_value : &PL_sv_undef,
    s ? s->variables : &PL_sv_undef,
    s ? s->program : &PL_sv_undef,
    s ? s->runtime_schema : &PL_sv_undef,
    &PL_sv_undef,
    (s && s->cursor) ? s->cursor->block_index : -1,
    (s && s->cursor) ? s->cursor->op_index : -1
  );
}

static SV *
gql_runtime_vm_new_lazy_info_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, SV *path_frame)
{
  gql_runtime_vm_path_frame_t *path_ptr = NULL;

  if (path_frame && SvOK(path_frame) && SvROK(path_frame) && SvIOK(SvRV(path_frame)) && SvUV(SvRV(path_frame)) != 0) {
    path_ptr = INT2PTR(gql_runtime_vm_path_frame_t *, SvUV(SvRV(path_frame)));
  }

  return gql_runtime_vm_new_lazy_info_for_path_sv(aTHX_ state_sv, s, path_ptr);
}

static SV *
gql_runtime_vm_runtime_schema_exec_struct_sv(pTHX_ SV *runtime_schema);

static SV *
gql_runtime_vm_state_resolve_args_sv(pTHX_ SV *state_sv)
{
  gql_runtime_vm_exec_state_handle_t *s = gql_runtime_vm_expect_exec_state_handle(aTHX_ state_sv);
  const gql_runtime_vm_native_runtime_t *runtime = gql_runtime_vm_exec_state_native_runtime(aTHX_ s);
  const gql_runtime_vm_native_slot_t *slot = (s && s->cursor) ? gql_runtime_vm_cursor_current_native_slot(s->cursor) : NULL;
  const gql_runtime_vm_native_op_t *op = (s && s->cursor) ? gql_runtime_vm_cursor_current_native_op(s->cursor) : NULL;
  HV *variables_hv = gql_runtime_vm_expect_hashref(aTHX_ s && s->variables ? s->variables : &PL_sv_undef, "variables");
  SV *args_sv;

  if (!runtime || !slot || !op) {
    return newSVsv(s && s->empty_args ? s->empty_args : &PL_sv_undef);
  }

  args_sv = gql_runtime_vm_specialize_arg_payload_sv(aTHX_ runtime, slot, op, variables_hv, NULL);
  return args_sv ? args_sv : newSVsv(s && s->empty_args ? s->empty_args : &PL_sv_undef);
}

static int
gql_runtime_vm_should_execute_op_now(pTHX_ gql_runtime_vm_exec_state_handle_t *s, SV *op_sv)
{
  const gql_runtime_vm_native_op_t *native_op = (s && s->cursor) ? gql_runtime_vm_cursor_current_native_op(s->cursor) : NULL;
  if (native_op) {
    HV *variables_hv = gql_runtime_vm_expect_hashref(aTHX_ s && s->variables ? s->variables : &PL_sv_undef, "variables");
    if (native_op->directives_mode_code == 0 || !native_op->has_directives || !native_op->directives_payload_native) {
      return 1;
    }
    return gql_runtime_vm_evaluate_runtime_guards_native(aTHX_ native_op->directives_payload_native, variables_hv) ? 1 : 0;
  }

  SV *mode_sv;
  SV *guards_sv;
  HV *variables_hv;
  const char *mode;

  if (!op_sv || !SvOK(op_sv)) {
    return 0;
  }

  mode_sv = gql_runtime_vm_op_slot_sv(aTHX_ op_sv, 16);
  mode = mode_sv ? SvPV_nolen(mode_sv) : "NONE";
  if (!mode || strEQ(mode, "NONE")) {
    return 1;
  }

  guards_sv = gql_runtime_vm_op_slot_sv(aTHX_ op_sv, 17);
  if (!guards_sv || !SvOK(guards_sv)) {
    return 1;
  }

  variables_hv = gql_runtime_vm_expect_hashref(aTHX_ s && s->variables ? s->variables : &PL_sv_undef, "variables");
  return gql_runtime_vm_evaluate_runtime_guards_hv(aTHX_ guards_sv, variables_hv) ? 1 : 0;
}

static SV *
gql_runtime_vm_call_resolver_sv(pTHX_ SV *resolver_sv, SV *source_sv, SV *args_sv, SV *context_sv, SV *info_sv, SV *return_type_sv, SV **error_out)
{
  dSP;
  SV *result = NULL;
  if (error_out) {
    *error_out = NULL;
  }
  if (!resolver_sv || !SvOK(resolver_sv)) {
    return newSVsv(&PL_sv_undef);
  }

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  XPUSHs(source_sv ? source_sv : &PL_sv_undef);
  XPUSHs(args_sv ? args_sv : &PL_sv_undef);
  XPUSHs(context_sv ? context_sv : &PL_sv_undef);
  XPUSHs(info_sv ? info_sv : &PL_sv_undef);
  XPUSHs(return_type_sv ? return_type_sv : &PL_sv_undef);
  PUTBACK;

  if (call_sv(resolver_sv, G_SCALAR | G_EVAL) > 0) {
    SPAGAIN;
    result = (SP > PL_stack_base) ? POPs : NULL;
    result = result ? newSVsv(result) : newSVsv(&PL_sv_undef);
    PUTBACK;
  }

  if (SvTRUE(ERRSV)) {
    if (error_out) {
      *error_out = newSVsv(ERRSV);
    }
    sv_setsv(ERRSV, &PL_sv_undef);
    result = NULL;
  }

  FREETMPS;
  LEAVE;
  return result ? result : newSVsv(&PL_sv_undef);
}

static SV *
gql_runtime_vm_call_default_property_sv(
  pTHX_ SV *callback_sv, SV *args_sv, SV *context_sv, SV *info_sv, SV **error_out
)
{
  dSP;
  SV *result = NULL;
  int count;
  int overloaded = callback_sv && SvROK(callback_sv)
    && SvTYPE(SvRV(callback_sv)) != SVt_PVCV && SvOBJECT(SvRV(callback_sv));

  if (error_out) {
    *error_out = NULL;
  }
  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  if (overloaded) {
    XPUSHs(callback_sv);
  }
  XPUSHs(args_sv ? args_sv : &PL_sv_undef);
  XPUSHs(context_sv ? context_sv : &PL_sv_undef);
  XPUSHs(info_sv ? info_sv : &PL_sv_undef);
  PUTBACK;
  count = overloaded
    ? call_pv(
        "GraphQL::Houtou::Runtime::DirectiveRuntime::_resolve_default_property_value",
        G_SCALAR | G_EVAL
      )
    : call_sv(callback_sv, G_SCALAR | G_EVAL);
  SPAGAIN;
  if (SvTRUE(ERRSV)) {
    if (error_out) {
      *error_out = newSVsv(ERRSV);
    }
    sv_setsv(ERRSV, &PL_sv_undef);
  } else if (count > 0) {
    result = newSVsv(POPs);
  }
  PUTBACK;
  FREETMPS;
  LEAVE;
  return result ? result : newSVsv(&PL_sv_undef);
}

static CV *
gql_runtime_vm_default_method_cv(SV *source_sv, const char *field_name)
{
  GV *method_gv;
  if (!source_sv || !SvROK(source_sv) || !SvOBJECT(SvRV(source_sv))
      || !field_name || !*field_name) {
    return NULL;
  }
  method_gv = gv_fetchmethod_autoload(SvSTASH(SvRV(source_sv)), field_name, 0);
  return method_gv ? GvCV(method_gv) : NULL;
}

static int
gql_runtime_vm_is_callable_property_candidate(pTHX_ SV *value_sv)
{
  if (!value_sv || !SvROK(value_sv)) {
    return 0;
  }
  if (SvTYPE(SvRV(value_sv)) == SVt_PVCV) {
    return 1;
  }
  /* Perl_amagic_applies is not exported by older supported Perls.  Treat a
   * blessed magical value as a rare candidate and let the Perl helper decide
   * whether it implements &{}; real CVs remain entirely on the native path.
   * If schemas commonly return objects with unrelated overloads (for example
   * stringified date objects), a future optimization may cache the public
   * overload::Method result by stash to avoid repeated Perl round trips. */
  return SvOBJECT(SvRV(value_sv)) && SvAMAGIC(value_sv) ? 1 : 0;
}

static SV *
gql_runtime_vm_exec_state_execute_block_sync_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, SV *block, IV block_index, SV *source, SV *base_path)
{
  gql_runtime_vm_cursor_t snapshot;
  gql_runtime_vm_field_frame_t *saved_field_frame;
  gql_runtime_vm_field_frame_t stack_field_frame;
  gql_runtime_vm_field_frame_guard_t *field_frame_guard;
  gql_runtime_vm_path_frame_t *base_path_ptr = NULL;
  const gql_runtime_vm_native_block_t *block_ptr = NULL;

  Zero(&snapshot, 1, gql_runtime_vm_cursor_t);
  Zero(&stack_field_frame, 1, gql_runtime_vm_field_frame_t);
  if (base_path && SvOK(base_path) && SvROK(base_path) && SvIOK(SvRV(base_path)) && SvUV(SvRV(base_path)) != 0) {
    base_path_ptr = INT2PTR(gql_runtime_vm_path_frame_t *, SvUV(SvRV(base_path)));
  }
  saved_field_frame = s ? s->field_frame : NULL;
  gql_runtime_vm_cursor_snapshot_copy(aTHX_ &snapshot, (s && s->cursor) ? s->cursor : NULL);
  if (s->cursor) {
    gql_runtime_vm_cursor_t *dst = s->cursor;
    dst->block_index = block_index >= 0 ? block_index : gql_runtime_vm_block_index_from_sv(aTHX_ s, block);
    dst->slot_index = 0;
    dst->op_index = -1;
    block_ptr = gql_runtime_vm_cursor_current_native_block(dst);
  }
  if (!block_ptr) {
    return newSVsv(&PL_sv_undef);
  }
  field_frame_guard = gql_runtime_vm_arm_field_frame_guard(aTHX_ s, saved_field_frame);

  if (s->frame_stack_count == s->frame_stack_capacity) {
    IV new_cap = s->frame_stack_capacity ? s->frame_stack_capacity * 2 : 4;
    Renew(s->frame_stack, new_cap, gql_runtime_vm_block_frame_t *);
    s->frame_stack_capacity = new_cap;
  }
  s->frame_stack[s->frame_stack_count++] = gql_runtime_vm_new_block_frame_struct(aTHX);
  s->frame = s->frame_stack[s->frame_stack_count - 1];
  if (!s->response_frame) {
    s->response_frame = s->frame;
  }

  while (1) {
    gql_runtime_vm_cursor_t *dst;
    IV next_index;
    const gql_runtime_vm_native_slot_t *slot;
    gql_runtime_vm_outcome_t *outcome;

    if (!s->cursor) {
      break;
    }
    dst = s->cursor;
    block_ptr = gql_runtime_vm_cursor_current_native_block(dst);
    if (!block_ptr) break;
    next_index = dst->op_index + 1;
    if (next_index >= block_ptr->op_count) {
      dst->op_index = next_index;
      dst->slot_index = 0;
      break;
    }
    dst->op_index = next_index;
    dst->slot_index = block_ptr->ops[next_index].slot_index;
    /* Program slot, not effective slot: the result path frame below
     * must carry the per-op result name (field alias). */
    slot = gql_runtime_vm_cursor_current_native_slot(dst);

    if (!gql_runtime_vm_should_execute_op_now(aTHX_ s, NULL)) {
      continue;
    }

    {
      gql_runtime_vm_path_frame_t *path_frame = gql_runtime_vm_new_result_path_frame(
        aTHX_
        base_path_ptr,
        slot
      );
      if (s->field_frame && s->field_frame != saved_field_frame) {
        gql_runtime_vm_free_field_frame(aTHX_ s->field_frame);
      }
      s->field_frame = gql_runtime_vm_init_stack_field_frame(
        aTHX_
        &stack_field_frame,
        source,
        path_frame
      );
      gql_runtime_vm_path_frame_decref(path_frame);
    }
    outcome = gql_runtime_vm_exec_state_execute_current_op_sync_now(aTHX_ state_sv, s);
    gql_runtime_vm_consume_current_outcome_now(aTHX_ s, outcome);
    gql_runtime_vm_outcome_decref(aTHX_ outcome);
  }

  {
    SV *result = newSVsv(&PL_sv_undef);
    if (s && s->frame) {
      gql_runtime_vm_block_frame_t *completed_frame = s->frame;
      result = gql_runtime_vm_native_value_materialize_sv(aTHX_ s->frame->values_value);
      if (s->frame_stack_count > 0) {
        s->frame_stack_count--;
      }
      s->frame = s->frame_stack_count > 0 ? s->frame_stack[s->frame_stack_count - 1] : NULL;
      gql_runtime_vm_free_block_frame(aTHX_ completed_frame);
    }
    if (s && s->cursor) {
      gql_runtime_vm_cursor_restore_copy(aTHX_ s->cursor, &snapshot);
    }
    gql_runtime_vm_cursor_destroy_copy(aTHX_ &snapshot);
    if (s->field_frame && s->field_frame != saved_field_frame) {
      gql_runtime_vm_free_field_frame(aTHX_ s->field_frame);
    }
    s->field_frame = saved_field_frame;
    field_frame_guard->state = NULL;
    return result;
  }
}

static SV *
gql_runtime_vm_new_serial_mutation_step_callback_sv(pTHX_ gql_runtime_vm_serial_mutation_ctx_t *ctx)
{
  CV *cv;
  SV *rv;

  cv = newXS(NULL, gql_runtime_vm_xs_serial_mutation_step_callback, __FILE__);
  CvXSUBANY(cv).any_ptr = ctx;
  gql_runtime_vm_attach_callback_magic_ptr(aTHX_ (SV *)cv, &gql_runtime_vm_serial_mutation_ctx_vtbl, ctx);
  rv = newRV_noinc((SV *)cv);
  return rv;
}

/*
 * Execute mutation root field ops from ctx->next_op_index in serial order.
 *
 * For each op: if the resolver returns a Promise, chain the next step via
 * .then() and return immediately (*all_sync_out = 0).  If all ops are sync,
 * finalize the block and set *sync_result_out to the materialized data value
 * (*all_sync_out = 1).
 *
 * Caller must push ctx->frame onto s->frame_stack before calling and must
 * NOT pop it on serial break (the continuation callback re-pushes it).
 */
static void
gql_runtime_vm_execute_serial_mutation_steps(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  gql_runtime_vm_serial_mutation_ctx_t *ctx,
  U8 *all_sync_out,
  SV **sync_result_out
)
{
  const gql_runtime_vm_native_block_t *block_ptr = NULL;
  gql_runtime_vm_field_frame_t stack_field_frame;
  gql_runtime_vm_field_frame_guard_t *field_frame_guard;

  *all_sync_out = 1;
  *sync_result_out = NULL;

  Zero(&stack_field_frame, 1, gql_runtime_vm_field_frame_t);
  field_frame_guard = gql_runtime_vm_arm_field_frame_guard(aTHX_ s, ctx->saved_field_frame);

  if (s->cursor) {
    s->cursor->block_index = ctx->block_index;
    block_ptr = gql_runtime_vm_cursor_current_native_block(s->cursor);
  }
  if (!block_ptr) {
    goto done_all_sync;
  }

  while (ctx->next_op_index < block_ptr->op_count) {
    IV op_index = ctx->next_op_index;
    const gql_runtime_vm_native_slot_t *slot;
    gql_runtime_vm_path_frame_t *path_frame;
    gql_runtime_vm_outcome_t *outcome = NULL;
    SV *result_sv;
    U8 result_is_promise;

    s->cursor->op_index = op_index;
    s->cursor->slot_index = block_ptr->ops[op_index].slot_index;
    /* Program slot, not effective slot: the result path frame below
     * must carry the per-op result name (field alias). */
    slot = gql_runtime_vm_cursor_current_native_slot(s->cursor);

    if (!gql_runtime_vm_should_execute_op_now(aTHX_ s, NULL)) {
      ctx->next_op_index++;
      continue;
    }

    path_frame = gql_runtime_vm_new_result_path_frame(aTHX_ ctx->base_path_ptr, slot);
    if (s->field_frame && s->field_frame != ctx->saved_field_frame) {
      gql_runtime_vm_free_field_frame(aTHX_ s->field_frame);
    }
    s->field_frame = gql_runtime_vm_init_stack_field_frame(
      aTHX_ &stack_field_frame, ctx->source_sv, path_frame
    );
    gql_runtime_vm_path_frame_decref(path_frame);

    result_sv = gql_runtime_vm_exec_state_execute_current_op_async_sv(
      aTHX_ state_sv, s, &outcome
    );

    if (outcome) {
      gql_runtime_vm_consume_current_outcome_now(aTHX_ s, outcome);
      gql_runtime_vm_outcome_decref(aTHX_ outcome);
      ctx->next_op_index++;
      continue;
    }

    result_is_promise = gql_runtime_vm_is_promise_value_for_state_sv(aTHX_ s, result_sv);
    gql_runtime_vm_consume_current_result_now(aTHX_ state_sv, s, result_sv);

    if (result_is_promise) {
      IV last_entry = ctx->frame->pending_count - 1;
      SV *pending_promise = NULL;

      if (last_entry >= 0
          && (ctx->frame->pending_entries[last_entry].payload_kind == GQL_VM_PENDING_PROMISE_SV
              || ctx->frame->pending_entries[last_entry].payload_kind == GQL_VM_PENDING_PROMISE_GENERIC_VALUE_SV)) {
        pending_promise = ctx->frame->pending_entries[last_entry].payload.promise_sv;
      }

      ctx->next_op_index = op_index + 1;
      *all_sync_out = 0;

      /* Lazily create the outer deferred on first async result */
      if (!ctx->frame->deferred_sv) {
        ctx->frame->deferred_sv = gql_runtime_vm_promise_xs_new_deferred_sv(aTHX);
        ctx->frame->promise_sv  = gql_runtime_vm_promise_xs_deferred_promise_sv(aTHX_ ctx->frame->deferred_sv);
        ctx->frame->deferred_resolves_response = (ctx->frame == s->response_frame) ? 1 : 0;
      }

      if (pending_promise && SvOK(pending_promise)) {
        SV *continuation = gql_runtime_vm_new_serial_mutation_step_callback_sv(aTHX_ ctx);
        SV *chain = gql_runtime_vm_call_then_promise_for_state_sv(
          aTHX_ s, pending_promise, continuation, NULL, NULL
        );
        SvREFCNT_dec(continuation);
        if (chain) {
          SvREFCNT_dec(chain);
        }
      }

      SvREFCNT_dec(result_sv);

      /* Pop ctx->frame from frame_stack; continuation re-pushes it */
      if (s->frame_stack_count > 0
          && s->frame_stack[s->frame_stack_count - 1] == ctx->frame) {
        s->frame_stack[s->frame_stack_count - 1] = NULL;
        s->frame_stack_count--;
        s->frame = s->frame_stack_count > 0
          ? s->frame_stack[s->frame_stack_count - 1] : NULL;
      }
      field_frame_guard->state = NULL;
      return;
    }

    SvREFCNT_dec(result_sv);
    ctx->next_op_index++;
  }

done_all_sync:
  {
    SV *result = gql_runtime_vm_finalize_current_block_now(
      aTHX_ state_sv, s, &PL_sv_undef, 0
    );
    if (s->cursor) {
      gql_runtime_vm_cursor_restore_copy(aTHX_ s->cursor, &ctx->cursor_snapshot);
    }
    gql_runtime_vm_cursor_destroy_copy(aTHX_ &ctx->cursor_snapshot);
    Zero(&ctx->cursor_snapshot, 1, gql_runtime_vm_cursor_t);
    if (s->field_frame && s->field_frame != ctx->saved_field_frame) {
      gql_runtime_vm_free_field_frame(aTHX_ s->field_frame);
    }
    s->field_frame = ctx->saved_field_frame;
    field_frame_guard->state = NULL;
    *sync_result_out = result;
  }
}

static XS(gql_runtime_vm_xs_serial_mutation_step_callback)
{
  dVAR;
  dXSARGS;
  gql_runtime_vm_serial_mutation_ctx_t *ctx = INT2PTR(
    gql_runtime_vm_serial_mutation_ctx_t *,
    CvXSUBANY(cv).any_ptr
  );
  gql_runtime_vm_exec_state_handle_t *s;
  U8 all_sync;
  SV *sync_result = NULL;

  PERL_UNUSED_VAR(items);

  if (!ctx || !ctx->state_sv) {
    XSRETURN_UNDEF;
  }

  s = gql_runtime_vm_expect_exec_state_handle(aTHX_ ctx->state_sv);

  /* Re-push ctx->frame onto frame_stack so s->frame is correct */
  if (ctx->frame) {
    if (s->frame_stack_count == s->frame_stack_capacity) {
      IV new_cap = s->frame_stack_capacity ? s->frame_stack_capacity * 2 : 4;
      Renew(s->frame_stack, new_cap, gql_runtime_vm_block_frame_t *);
      s->frame_stack_capacity = new_cap;
    }
    s->frame_stack[s->frame_stack_count++] = ctx->frame;
  if (!s->response_frame) {
    s->response_frame = ctx->frame;
  }
    s->frame = ctx->frame;
  }

  gql_runtime_vm_execute_serial_mutation_steps(
    aTHX_ ctx->state_sv, s, ctx, &all_sync, &sync_result
  );

  if (all_sync && sync_result) {
    /* All remaining ops were sync; deferred was pre-created, resolve it now */
    if (ctx->frame && ctx->frame->deferred_sv && SvOK(ctx->frame->deferred_sv)) {
      SV *response = gql_runtime_vm_fast_response_sv(aTHX_ sync_result, s->writer);
      gql_runtime_vm_promise_xs_deferred_resolve_sv(
        aTHX_ ctx->frame->deferred_sv, response
      );
      SvREFCNT_dec(response);
    }
    SvREFCNT_dec(sync_result);
  }

  XSRETURN_UNDEF;
}

static SV *
gql_runtime_vm_exec_state_execute_block_serial_mutation_sv(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  IV block_index,
  SV *source,
  gql_runtime_vm_path_frame_t *base_path_ptr
)
{
  gql_runtime_vm_serial_mutation_ctx_t *ctx;
  gql_runtime_vm_block_frame_t *frame;
  SV *outer_promise;
  U8 all_sync;
  SV *sync_result = NULL;

  /* Build the serial context */
  Newxz(ctx, 1, gql_runtime_vm_serial_mutation_ctx_t);
  ctx->state_sv       = SvREFCNT_inc_simple_NN(state_sv);
  ctx->block_index    = block_index;
  ctx->next_op_index  = 0;
  ctx->source_sv      = source ? SvREFCNT_inc_simple_NN(source) : NULL;
  ctx->base_path_ptr  = base_path_ptr;
  if (ctx->base_path_ptr) {
    ctx->base_path_ptr->refcount++;
  }
  ctx->saved_field_frame = s->field_frame;
  gql_runtime_vm_cursor_snapshot_copy(aTHX_ &ctx->cursor_snapshot,
    (s && s->cursor) ? s->cursor : NULL);

  /* Create the accumulator frame; deferred is created lazily on first async result */
  frame = gql_runtime_vm_new_block_frame_struct(aTHX);
  ctx->frame = frame;
  ctx->frame->refcount++; /* ctx holds an extra ref */

  /* Push the frame onto the exec-state frame stack */
  if (s->frame_stack_count == s->frame_stack_capacity) {
    IV new_cap = s->frame_stack_capacity ? s->frame_stack_capacity * 2 : 4;
    Renew(s->frame_stack, new_cap, gql_runtime_vm_block_frame_t *);
    s->frame_stack_capacity = new_cap;
  }
  s->frame_stack[s->frame_stack_count++] = frame;
  if (!s->response_frame) {
    s->response_frame = frame;
  }
  s->frame = frame;

  /* Run the first batch of serial steps */
  gql_runtime_vm_execute_serial_mutation_steps(
    aTHX_ state_sv, s, ctx, &all_sync, &sync_result
  );

  /* Release the ctx ref held by this scope */
  if (all_sync) {
    /* No callbacks were created – free ctx manually */
    if (ctx->state_sv) { SvREFCNT_dec(ctx->state_sv); }
    if (ctx->source_sv) { SvREFCNT_dec(ctx->source_sv); }
    if (ctx->base_path_ptr) { gql_runtime_vm_path_frame_decref(ctx->base_path_ptr); }
    if (ctx->frame) { gql_runtime_vm_free_block_frame(aTHX_ ctx->frame); }
    gql_runtime_vm_cursor_destroy_copy(aTHX_ &ctx->cursor_snapshot);
    Safefree(ctx);
    /* Return data SV directly; caller wraps with materialize_response_sv */
    return sync_result ? sync_result : newSVsv(&PL_sv_undef);
  }
  /* else: ctx is owned by the continuation callback CVs via magic */

  /* Return the deferred's promise (created lazily in execute_serial_mutation_steps) */
  outer_promise = frame->promise_sv ? newSVsv(frame->promise_sv) : newSVsv(&PL_sv_undef);
  return outer_promise;
}

static SV *
gql_runtime_vm_exec_state_execute_block_async_sv(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s, IV block_index, SV *source, SV *base_path)
{
  gql_runtime_vm_path_frame_t *base_path_ptr = NULL;

  if (base_path && SvOK(base_path) && SvROK(base_path) && SvIOK(SvRV(base_path)) && SvUV(SvRV(base_path)) != 0) {
    base_path_ptr = INT2PTR(gql_runtime_vm_path_frame_t *, SvUV(SvRV(base_path)));
  }

  return gql_runtime_vm_exec_state_execute_block_async_path_sv(
    aTHX_ state_sv, s, block_index, source, base_path_ptr, 0
  );
}

static SV *
gql_runtime_vm_exec_state_execute_block_async_path_sv(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  IV block_index,
  SV *source,
  gql_runtime_vm_path_frame_t *base_path_ptr,
  U8 return_pending_handle
)
{
  gql_runtime_vm_cursor_t snapshot;
  gql_runtime_vm_field_frame_t *saved_field_frame;
  gql_runtime_vm_field_frame_t stack_field_frame;
  gql_runtime_vm_field_frame_guard_t *field_frame_guard;
  const gql_runtime_vm_native_block_t *block_ptr = NULL;

  /* Dispatch to serial executor for mutation root blocks */
  if (s && s->cursor && s->cursor->native_program
      && s->cursor->native_program->operation_type_code == GQL_VM_OPTYPE_MUTATION
      && block_index == s->cursor->native_program->root_block_index
      && s->promise_backend_code == GQL_VM_PROMISE_BACKEND_PROMISE_XS
      && return_pending_handle == 0) {
    return gql_runtime_vm_exec_state_execute_block_serial_mutation_sv(
      aTHX_ state_sv, s, block_index, source, base_path_ptr
    );
  }

  Zero(&snapshot, 1, gql_runtime_vm_cursor_t);
  Zero(&stack_field_frame, 1, gql_runtime_vm_field_frame_t);
  saved_field_frame = s ? s->field_frame : NULL;
  gql_runtime_vm_cursor_snapshot_copy(aTHX_ &snapshot, (s && s->cursor) ? s->cursor : NULL);
  if (s->cursor) {
    gql_runtime_vm_cursor_t *dst = s->cursor;
    dst->block_index = block_index;
    dst->slot_index = 0;
    dst->op_index = -1;
    block_ptr = gql_runtime_vm_cursor_current_native_block(dst);
  }
  if (!block_ptr) {
    return newSVsv(&PL_sv_undef);
  }
  field_frame_guard = gql_runtime_vm_arm_field_frame_guard(aTHX_ s, saved_field_frame);

  if (s->frame_stack_count == s->frame_stack_capacity) {
    IV new_cap = s->frame_stack_capacity ? s->frame_stack_capacity * 2 : 4;
    Renew(s->frame_stack, new_cap, gql_runtime_vm_block_frame_t *);
    s->frame_stack_capacity = new_cap;
  }
  s->frame_stack[s->frame_stack_count++] = gql_runtime_vm_new_block_frame_struct(aTHX);
  s->frame = s->frame_stack[s->frame_stack_count - 1];
  if (!s->response_frame) {
    s->response_frame = s->frame;
  }

  while (1) {
    gql_runtime_vm_cursor_t *dst;
    IV next_index;
    const gql_runtime_vm_native_slot_t *slot;

    if (!s->cursor) {
      break;
    }
    dst = s->cursor;
    block_ptr = gql_runtime_vm_cursor_current_native_block(dst);
    if (!block_ptr) break;
    next_index = dst->op_index + 1;
    if (next_index >= block_ptr->op_count) {
      dst->op_index = next_index;
      dst->slot_index = 0;
      break;
    }
    dst->op_index = next_index;
    dst->slot_index = block_ptr->ops[next_index].slot_index;
    /* Program slot, not effective slot: the result path frame below
     * must carry the per-op result name (field alias). */
    slot = gql_runtime_vm_cursor_current_native_slot(dst);

    if (!gql_runtime_vm_should_execute_op_now(aTHX_ s, NULL)) {
      continue;
    }

    {
      gql_runtime_vm_path_frame_t *path_frame = gql_runtime_vm_new_result_path_frame(
        aTHX_
        base_path_ptr,
        slot
      );
      gql_runtime_vm_outcome_t *outcome = NULL;
      SV *result_sv;

      if (s->field_frame && s->field_frame != saved_field_frame) {
        gql_runtime_vm_free_field_frame(aTHX_ s->field_frame);
      }
      s->field_frame = gql_runtime_vm_init_stack_field_frame(
        aTHX_
        &stack_field_frame,
        source,
        path_frame
      );
      gql_runtime_vm_path_frame_decref(path_frame);

      result_sv = gql_runtime_vm_exec_state_execute_current_op_async_sv(
        aTHX_
        state_sv,
        s,
        &outcome
      );
      if (outcome) {
        gql_runtime_vm_consume_current_outcome_now(aTHX_ s, outcome);
        gql_runtime_vm_outcome_decref(aTHX_ outcome);
      } else {
        gql_runtime_vm_consume_current_result_now(aTHX_ state_sv, s, result_sv);
        if (result_sv) {
          SvREFCNT_dec(result_sv);
        }
      }
    }
  }

  {
    SV *result = gql_runtime_vm_finalize_current_block_now(aTHX_ state_sv, s, &PL_sv_undef, return_pending_handle);
    if (s && s->cursor) {
      gql_runtime_vm_cursor_restore_copy(aTHX_ s->cursor, &snapshot);
    }
    gql_runtime_vm_cursor_destroy_copy(aTHX_ &snapshot);
    if (s->field_frame && s->field_frame != saved_field_frame) {
      gql_runtime_vm_free_field_frame(aTHX_ s->field_frame);
    }
    s->field_frame = saved_field_frame;
    field_frame_guard->state = NULL;
    return result;
  }
}

static gql_runtime_vm_outcome_t *
gql_runtime_vm_exec_state_execute_current_op_sync_now(pTHX_ SV *state_sv, gql_runtime_vm_exec_state_handle_t *s)
{
  const gql_runtime_vm_native_block_t *block;
  const gql_runtime_vm_native_op_t *op;
  const gql_runtime_vm_native_slot_t *slot;
  SV *source_sv;
  SV *resolved_sv = NULL;
  SV *error_sv = NULL;
  IV resolve_code;
  IV complete_code;

  if (!s || !s->cursor || !s->field_frame) {
    return gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_SCALAR, &PL_sv_undef, &PL_sv_undef);
  }

  block = gql_runtime_vm_cursor_current_native_block(s->cursor);
  op = gql_runtime_vm_cursor_current_native_op(s->cursor);
  slot = gql_runtime_vm_cursor_current_native_slot(s->cursor);
  source_sv = s->field_frame->source;
  resolve_code = op ? op->resolve_code : 0;
  complete_code = op ? op->complete_code : 0;

  switch (resolve_code) {
    case GQL_VM_RESOLVE_DEFAULT:
    case GQL_VM_RESOLVE_EXPLICIT:
    {
      const char *field_name = slot ? slot->field_name : "";
      SV *field_name_sv = field_name ? newSVpv(field_name, 0) : newSVsv(&PL_sv_undef);
      SV *resolver_sv = gql_runtime_vm_state_current_resolver_sv(aTHX_ s);
      if (field_name && strEQ(field_name, "__typename")) {
        resolved_sv = (block && block->type_name && *block->type_name)
          ? newSVpv(block->type_name, 0)
          : newSVsv(&PL_sv_undef);
      } else if (resolver_sv && SvOK(resolver_sv)) {
        SV *args_sv = gql_runtime_vm_state_resolve_args_sv(aTHX_ state_sv);
        SV *info_sv = gql_runtime_vm_new_lazy_info_sv(aTHX_ state_sv, s, NULL);
        SV *return_type_sv = gql_runtime_vm_state_current_return_type_sv(aTHX_ s, NULL, NULL);
        resolved_sv = gql_runtime_vm_call_resolver_sv(
          aTHX_ resolver_sv, source_sv, args_sv, s->context, info_sv, return_type_sv, &error_sv
        );
        SvREFCNT_dec(args_sv);
        SvREFCNT_dec(info_sv);
      } else {
        CV *method_cv = gql_runtime_vm_default_method_cv(source_sv, field_name);
        if (method_cv) {
          SV *args_sv = gql_runtime_vm_state_resolve_args_sv(aTHX_ state_sv);
          SV *info_sv = gql_runtime_vm_new_lazy_info_sv(aTHX_ state_sv, s, NULL);
          resolved_sv = gql_runtime_vm_call_cb4_nonfatal(
            aTHX_ (SV *)method_cv, source_sv, args_sv, s->context, info_sv, &error_sv
          );
          SvREFCNT_dec(args_sv);
          SvREFCNT_dec(info_sv);
        } else if (source_sv && SvOK(source_sv) && SvROK(source_sv)
                   && SvTYPE(SvRV(source_sv)) == SVt_PVHV && field_name && *field_name) {
          HE *he = hv_fetch_ent((HV *)SvRV(source_sv), field_name_sv, 0, 0);
          SV *value_sv = he ? HeVAL(he) : &PL_sv_undef;
          if (gql_runtime_vm_is_callable_property_candidate(aTHX_ value_sv)) {
            SV *args_sv = gql_runtime_vm_state_resolve_args_sv(aTHX_ state_sv);
            SV *info_sv = gql_runtime_vm_new_lazy_info_sv(aTHX_ state_sv, s, NULL);
            resolved_sv = gql_runtime_vm_call_default_property_sv(
              aTHX_ value_sv, args_sv, s->context, info_sv, &error_sv
            );
            SvREFCNT_dec(args_sv);
            SvREFCNT_dec(info_sv);
          } else {
            resolved_sv = newSVsv(value_sv);
          }
        } else {
          resolved_sv = newSVsv(&PL_sv_undef);
        }
      }
      SvREFCNT_dec(field_name_sv);
      break;
    }
    default:
      resolved_sv = newSVsv(&PL_sv_undef);
      break;
  }

  if (error_sv && SvOK(error_sv)) {
    gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_error_outcome_struct_for_path(aTHX_ error_sv, s->field_frame->path_frame);
    SvREFCNT_dec(error_sv);
    if (resolved_sv) SvREFCNT_dec(resolved_sv);
    return outcome;
  }

  switch (complete_code) {
    case GQL_VM_COMPLETE_OBJECT:
    {
      IV child_block_index = -1;
      if (!resolved_sv || !SvOK(resolved_sv)) {
        gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_SCALAR, &PL_sv_undef, &PL_sv_undef);
        SvREFCNT_dec(resolved_sv);
        return outcome;
      }
      if (op) {
        child_block_index = op->child_block_index;
      }
      if (child_block_index < 0) {
        gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_SCALAR, resolved_sv, &PL_sv_undef);
        SvREFCNT_dec(resolved_sv);
        return outcome;
      }
      {
        SV *base_path_sv = gql_runtime_vm_wrap_path_frame_sv(aTHX_ s->field_frame->path_frame);
        SV *child_value = gql_runtime_vm_exec_state_execute_block_sync_sv(aTHX_ state_sv, s, &PL_sv_undef, child_block_index, resolved_sv, base_path_sv);
        SvREFCNT_dec(base_path_sv);
        gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_OBJECT, child_value, &PL_sv_undef);
        SvREFCNT_dec(child_value);
        SvREFCNT_dec(resolved_sv);
        return outcome;
      }
    }
    case GQL_VM_COMPLETE_LIST:
    {
      IV child_block_index = -1;
      AV *items_av;
      AV *resolved_items_av;
      SSize_t i;
      if (!resolved_sv || !SvOK(resolved_sv)) {
        gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_SCALAR, &PL_sv_undef, &PL_sv_undef);
        SvREFCNT_dec(resolved_sv);
        return outcome;
      }
      if (!SvROK(resolved_sv) || SvTYPE(SvRV(resolved_sv)) != SVt_PVAV) {
        gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_SCALAR, resolved_sv, &PL_sv_undef);
        SvREFCNT_dec(resolved_sv);
        return outcome;
      }
      if (op) {
        child_block_index = op->child_block_index;
      }
      items_av = (AV *)SvRV(resolved_sv);
      resolved_items_av = newAV();
      for (i = 0; i <= av_len(items_av); i++) {
        SV **item_svp = av_fetch(items_av, i, 0);
        SV *item_sv = (item_svp && *item_svp) ? *item_svp : &PL_sv_undef;
        if (child_block_index >= 0) {
          SV *item_key = newSViv(i);
          SV *base_path_sv = gql_runtime_vm_wrap_path_frame_sv(aTHX_ s->field_frame->path_frame);
          SV *item_path = gql_runtime_vm_new_path_frame_handle(aTHX_ base_path_sv, item_key);
          SV *child_value = gql_runtime_vm_exec_state_execute_block_sync_sv(aTHX_ state_sv, s, &PL_sv_undef, child_block_index, item_sv, item_path);
          av_push(resolved_items_av, child_value);
          SvREFCNT_dec(base_path_sv);
          SvREFCNT_dec(item_key);
          SvREFCNT_dec(item_path);
        } else {
          av_push(resolved_items_av, newSVsv(item_sv));
        }
      }
      {
        gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_LIST, newRV_noinc((SV *)resolved_items_av), &PL_sv_undef);
        SvREFCNT_dec(resolved_sv);
        return outcome;
      }
    }
    case GQL_VM_COMPLETE_ABSTRACT:
    {
      SV *runtime_error_sv = NULL;
      SV *runtime_type_sv;
      IV child_block_index = -1;
      if (!resolved_sv || !SvOK(resolved_sv)) {
        gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_SCALAR, &PL_sv_undef, &PL_sv_undef);
        SvREFCNT_dec(resolved_sv);
        return outcome;
      }
      runtime_type_sv = gql_runtime_vm_exec_state_resolve_runtime_type_current_sv(
        aTHX_
        state_sv,
        s,
        resolved_sv,
        NULL,
        &runtime_error_sv
      );
      if (runtime_error_sv && SvOK(runtime_error_sv)) {
        gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_error_outcome_struct_for_path(aTHX_ runtime_error_sv, s->field_frame->path_frame);
        SvREFCNT_dec(runtime_error_sv);
        SvREFCNT_dec(resolved_sv);
        return outcome;
      }
      if (!runtime_type_sv || !SvOK(runtime_type_sv)) {
        gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_SCALAR, resolved_sv, &PL_sv_undef);
        SvREFCNT_dec(resolved_sv);
        if (runtime_type_sv) SvREFCNT_dec(runtime_type_sv);
        return outcome;
      }
      child_block_index = gql_runtime_vm_find_abstract_child_block_index(
        op,
        gql_runtime_vm_type_name_from_sv(aTHX_ runtime_type_sv)
      );
      if (child_block_index < 0) {
        SvREFCNT_dec(runtime_type_sv);
        gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_SCALAR, resolved_sv, &PL_sv_undef);
        SvREFCNT_dec(resolved_sv);
        return outcome;
      }
      SvREFCNT_dec(runtime_type_sv);
      {
        SV *base_path_sv = gql_runtime_vm_wrap_path_frame_sv(aTHX_ s->field_frame->path_frame);
        SV *child_value = gql_runtime_vm_exec_state_execute_block_sync_sv(aTHX_ state_sv, s, &PL_sv_undef, child_block_index, resolved_sv, base_path_sv);
        SvREFCNT_dec(base_path_sv);
        gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_OBJECT, child_value, &PL_sv_undef);
        SvREFCNT_dec(child_value);
        SvREFCNT_dec(resolved_sv);
        return outcome;
      }
    }
    case GQL_VM_COMPLETE_GENERIC:
    default:
    {
      gql_runtime_vm_outcome_t *outcome = gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_SCALAR, resolved_sv ? resolved_sv : &PL_sv_undef, &PL_sv_undef);
      SvREFCNT_dec(resolved_sv);
      return outcome;
    }
  }
}

static SV *
gql_runtime_vm_exec_state_resolve_current_value_sv(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  SV *source_sv,
  gql_runtime_vm_path_frame_t *path_frame,
  SV **error_out
)
{
  const gql_runtime_vm_native_runtime_t *runtime;
  const gql_runtime_vm_native_block_t *block;
  const gql_runtime_vm_native_slot_t *slot;
  const char *field_name;
  SV *resolver_sv;
  SV *resolved_sv = NULL;
  SV *field_name_sv = NULL;

  if (error_out) {
    *error_out = NULL;
  }

  if (!s || !s->cursor) {
    return newSVsv(&PL_sv_undef);
  }

  runtime = gql_runtime_vm_exec_state_native_runtime(aTHX_ s);
  block = gql_runtime_vm_cursor_current_native_block(s->cursor);
  slot = gql_runtime_vm_cursor_current_native_slot(s->cursor);
  slot = gql_runtime_vm_effective_slot(runtime, slot);
  field_name = slot ? slot->field_name : "";
  resolver_sv = gql_runtime_vm_state_current_resolver_sv(aTHX_ s);

  if (field_name && strEQ(field_name, "__typename")) {
    return (block && block->type_name && *block->type_name)
      ? newSVpv(block->type_name, 0)
      : newSVsv(&PL_sv_undef);
  }

  if (resolver_sv && SvOK(resolver_sv)) {
    SV *args_sv = gql_runtime_vm_state_resolve_args_sv(aTHX_ state_sv);
    SV *return_type_sv = gql_runtime_vm_direct_slot_type_object_sv(runtime, slot);

    if (gql_runtime_vm_slot_uses_native_fast_abi(slot)) {
      resolved_sv = gql_runtime_vm_call_cb4_nonfatal(
        aTHX_
        resolver_sv,
        source_sv,
        args_sv,
        s->context,
        return_type_sv ? return_type_sv : &PL_sv_undef,
        error_out
      );
    } else {
      SV *info_sv = gql_runtime_vm_new_lazy_info_for_path_sv(aTHX_ state_sv, s, path_frame);

      if (!return_type_sv && !gql_runtime_vm_slot_uses_explicit_generic_fast_abi(slot)) {
        return_type_sv = gql_runtime_vm_state_current_return_type_sv(aTHX_ s, NULL, NULL);
      }
      if (!return_type_sv && gql_runtime_vm_slot_uses_explicit_generic_fast_abi(slot)) {
        croak("native VM slot type object is missing for explicit generic callback");
      }

      resolved_sv = gql_runtime_vm_call_cb5_nonfatal(
        aTHX_
        resolver_sv,
        source_sv,
        args_sv,
        s->context,
        info_sv,
        return_type_sv ? return_type_sv : &PL_sv_undef,
        error_out
      );
      SvREFCNT_dec(info_sv);
    }

    SvREFCNT_dec(args_sv);
    return resolved_sv ? resolved_sv : newSVsv(&PL_sv_undef);
  }

  {
    CV *method_cv = gql_runtime_vm_default_method_cv(source_sv, field_name);
    if (method_cv) {
      SV *args_sv = gql_runtime_vm_state_resolve_args_sv(aTHX_ state_sv);
      SV *info_sv = gql_runtime_vm_new_lazy_info_for_path_sv(aTHX_ state_sv, s, path_frame);
      resolved_sv = gql_runtime_vm_call_cb4_nonfatal(
        aTHX_ (SV *)method_cv, source_sv, args_sv, s->context, info_sv, error_out
      );
      SvREFCNT_dec(args_sv);
      SvREFCNT_dec(info_sv);
      return resolved_sv ? resolved_sv : newSVsv(&PL_sv_undef);
    }
  }

  /* Default resolver: share the source hash value instead of copying it.
   * Scalar leaves are copied into the native tree immediately after (or
   * newSVsv'd by the scalar-fallback path), and hash/array refs are only
   * read as child sources, so no caller mutates the shared SV. Avoiding
   * the key-SV allocation and the value copy matters: this runs once per
   * field on the async lane. */
  PERL_UNUSED_VAR(field_name_sv);
  if (source_sv && SvOK(source_sv) && SvROK(source_sv) && SvTYPE(SvRV(source_sv)) == SVt_PVHV && field_name && *field_name) {
    SV **valp = hv_fetch((HV *)SvRV(source_sv), field_name, (I32)strlen(field_name), 0);
    if (valp && *valp) {
      if (gql_runtime_vm_is_callable_property_candidate(aTHX_ *valp)) {
        SV *args_sv = gql_runtime_vm_state_resolve_args_sv(aTHX_ state_sv);
        SV *info_sv = gql_runtime_vm_new_lazy_info_for_path_sv(aTHX_ state_sv, s, path_frame);
        resolved_sv = gql_runtime_vm_call_default_property_sv(
          aTHX_ *valp, args_sv, s->context, info_sv, error_out
        );
        SvREFCNT_dec(args_sv);
        SvREFCNT_dec(info_sv);
        return resolved_sv ? resolved_sv : newSVsv(&PL_sv_undef);
      }
      return SvREFCNT_inc_simple_NN(*valp);
    }
  }
  resolved_sv = newSVsv(&PL_sv_undef);
  return resolved_sv;
}

static SV *
gql_runtime_vm_exec_state_complete_async_sv(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  gql_runtime_vm_path_frame_t *path_ptr,
  IV block_index,
  IV slot_index,
  IV op_index,
  SV *resolved_sv,
  gql_runtime_vm_outcome_t **outcome_out
)
{
  const gql_runtime_vm_native_runtime_t *runtime;
  const gql_runtime_vm_native_block_t *block;
  const gql_runtime_vm_native_op_t *op;
  const gql_runtime_vm_native_slot_t *slot;
  SV *result_sv = NULL;

  if (!s || !s->native_program) {
    return newSVsv(&PL_sv_undef);
  }
  runtime = gql_runtime_vm_exec_state_native_runtime(aTHX_ s);
  if (block_index < 0 || block_index >= s->native_program->block_count) {
    return newSVsv(&PL_sv_undef);
  }
  block = &s->native_program->blocks[block_index];
  if (op_index < 0 || op_index >= block->op_count) {
    return newSVsv(&PL_sv_undef);
  }
  op = &block->ops[op_index];
  if (slot_index < 0 || slot_index >= block->slot_count) {
    return newSVsv(&PL_sv_undef);
  }
  slot = gql_runtime_vm_effective_slot(runtime, &block->slots[slot_index]);

  result_sv = gql_runtime_vm_exec_state_complete_current_native_async_sv(
    aTHX_ state_sv,
    s,
    path_ptr,
    op,
    slot,
    resolved_sv,
    outcome_out
  );

  if (outcome_out && *outcome_out) {
    return NULL;
  }
  return result_sv ? result_sv : newSVsv(&PL_sv_undef);
}

static SV *
gql_runtime_vm_then_complete_current_sv(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  SV *promise_sv,
  gql_runtime_vm_path_frame_t *path_frame,
  IV block_index,
  IV slot_index,
  IV op_index
)
{
  const gql_runtime_vm_native_op_t *op =
    (s && s->cursor) ? gql_runtime_vm_cursor_current_native_op(s->cursor) : NULL;
  /* Program slot, not effective slot: pending entry keys carry the alias. */
  const gql_runtime_vm_native_slot_t *slot =
    (s && s->cursor) ? gql_runtime_vm_cursor_current_native_slot(s->cursor) : NULL;
  const char *result_name_pv = (slot && slot->result_name && *slot->result_name) ? slot->result_name : NULL;
  STRLEN result_name_len = result_name_pv ? (STRLEN)strlen(result_name_pv) : 0;
  IV complete_code = op ? op->complete_code : GQL_VM_COMPLETE_GENERIC;
  SV *callback_sv;
  SV *error_callback_sv;
  SV *ret = NULL;

  /* Direct subscription: park the user promise itself as the pending
   * entry; arm_frame then()s it once with the resolve/reject arms writing
   * straight into the entry. Skips one then(), one derived promise and
   * one error CV per user promise. */
  if (op && s && s->frame && result_name_pv && result_name_len > 0) {
    gql_runtime_vm_block_frame_push_pending_pvn_with_meta(
      aTHX_
      s->frame,
      result_name_pv,
      result_name_len,
      1,
      promise_sv,
      /* GENERIC_VALUE_SV stores the settled value without running
       * completion, so leaf-typed slots park as RESOLVED_VALUE_SV to get
       * result coercion at settle time. */
      complete_code == GQL_VM_COMPLETE_GENERIC
          && gql_runtime_vm_slot_leaf_kind(
               gql_runtime_vm_exec_state_native_runtime(aTHX_ s),
               gql_runtime_vm_effective_slot(
                 gql_runtime_vm_exec_state_native_runtime(aTHX_ s), slot
               )
             ) == GQL_VM_LEAF_NONE
        ? GQL_VM_PENDING_PROMISE_GENERIC_VALUE_SV
        : GQL_VM_PENDING_PROMISE_RESOLVED_VALUE_SV,
      path_frame,
      block_index,
      slot_index,
      op_index
    );
    return newSVsv(&PL_sv_undef);
  }

  callback_sv = gql_runtime_vm_identity_callback_sv(aTHX);
  error_callback_sv = gql_runtime_vm_new_error_callback_sv(aTHX_ path_frame);

  ret = gql_runtime_vm_call_then_promise_for_state_sv(
    aTHX_
    s,
    promise_sv,
    callback_sv,
    error_callback_sv,
    path_frame
  );

  if (callback_sv) {
    SvREFCNT_dec(callback_sv);
  }
  if (error_callback_sv) {
    SvREFCNT_dec(error_callback_sv);
  }

  if (ret
      && SvOK(ret)
      && !gql_runtime_vm_sv_is_outcome(aTHX_ ret)
      && !gql_runtime_vm_is_promise_value_for_state_sv(aTHX_ s, ret)) {
    SV *completed_sv;

    if (complete_code == GQL_VM_COMPLETE_GENERIC) {
      completed_sv = gql_runtime_vm_new_outcome_handle_sv(
        aTHX_
        GQL_VM_KIND_SCALAR,
        ret,
        &PL_sv_undef
      );
    } else {
      completed_sv = gql_runtime_vm_exec_state_complete_async_sv(
        aTHX_
        state_sv,
        s,
        path_frame,
        block_index,
        slot_index,
        op_index,
        ret,
        NULL
      );
    }
    SvREFCNT_dec(ret);
    return completed_sv ? completed_sv : newSVsv(&PL_sv_undef);
  }

  return ret ? ret : newSVsv(&PL_sv_undef);
}

static SV *
gql_runtime_vm_exec_state_execute_current_op_async_sv(
  pTHX_
  SV *state_sv,
  gql_runtime_vm_exec_state_handle_t *s,
  gql_runtime_vm_outcome_t **outcome_out
)
{
  gql_runtime_vm_path_frame_t *path_frame = NULL;
  SV *resolved_sv = NULL;
  SV *error_sv = NULL;
  SV *result_sv = NULL;

  if (outcome_out) {
    *outcome_out = NULL;
  }
  if (!s || !s->field_frame || !s->cursor) {
    return newSVsv(&PL_sv_undef);
  }

  path_frame = s->field_frame->path_frame;
  resolved_sv = gql_runtime_vm_exec_state_resolve_current_value_sv(
    aTHX_
    state_sv,
    s,
    s->field_frame->source,
    path_frame,
    &error_sv
  );
  if (error_sv && SvOK(error_sv)) {
    if (outcome_out) {
      *outcome_out = gql_runtime_vm_new_error_outcome_struct_for_path(
        aTHX_
        error_sv,
        path_frame
      );
    } else {
      result_sv = gql_runtime_vm_new_error_outcome_for_path_sv(aTHX_ error_sv, path_frame);
    }
    SvREFCNT_dec(error_sv);
    goto done_async_current_op;
  }

  if (gql_runtime_vm_is_promise_value_for_state_sv(aTHX_ s, resolved_sv)) {
    result_sv = gql_runtime_vm_then_complete_current_sv(
      aTHX_
      state_sv,
      s,
      resolved_sv,
      path_frame,
      s->cursor->block_index,
      s->cursor->slot_index,
      s->cursor->op_index
    );
    goto done_async_current_op;
  }

  if (s->cursor) {
    const gql_runtime_vm_native_block_t *block = gql_runtime_vm_cursor_current_native_block(s->cursor);
    const gql_runtime_vm_native_op_t *op = gql_runtime_vm_cursor_current_native_op(s->cursor);
    if (block && op && (op->has_runtime_directives || op->runtime_directives_sv)) {
      SV *applied_sv = gql_runtime_vm_apply_runtime_directives_nonfatal(
        aTHX_
        &(gql_runtime_vm_exec_state_t) {
          .runtime = gql_runtime_vm_exec_state_native_runtime(aTHX_ s),
          .bundle = s->native_program ? gql_runtime_vm_native_program_cached_bundle(aTHX_ gql_runtime_vm_exec_state_native_runtime(aTHX_ s), s->native_program) : NULL,
          .callback_ctx = &(gql_runtime_vm_callback_context_t) {
            .runtime_schema = s->runtime_schema,
            .program = s->program,
            .context = s->context,
            .variables = s->variables,
            .root_value = s->root_value,
          },
          .path_frame = path_frame,
          .empty_args_sv = s->empty_args,
          .writer = s->writer,
          .block = block,
          .op = op,
          .slot = gql_runtime_vm_effective_slot(gql_runtime_vm_exec_state_native_runtime(aTHX_ s), gql_runtime_vm_cursor_current_native_slot(s->cursor)),
          .block_index = s->cursor->block_index,
          .op_index = s->cursor->op_index,
        },
        s->field_frame->source,
        resolved_sv,
        &error_sv
      );
      if (error_sv && SvOK(error_sv)) {
        SvREFCNT_dec(applied_sv);
        if (outcome_out) {
          *outcome_out = gql_runtime_vm_new_error_outcome_struct_for_path(
            aTHX_
            error_sv,
            path_frame
          );
        } else {
          result_sv = gql_runtime_vm_new_error_outcome_for_path_sv(aTHX_ error_sv, path_frame);
        }
        SvREFCNT_dec(error_sv);
        goto done_async_current_op;
      }
      SvREFCNT_dec(resolved_sv);
      resolved_sv = applied_sv;
    }
  }

  result_sv = gql_runtime_vm_exec_state_complete_async_sv(
    aTHX_
    state_sv,
    s,
    path_frame,
    s->cursor->block_index,
    s->cursor->slot_index,
    s->cursor->op_index,
    resolved_sv,
    outcome_out
  );
  /* Fallback for completion paths that still hand back a wrapped outcome
   * handle SV despite outcome_out (e.g. error outcomes built deeper down). */
  if (outcome_out
      && !*outcome_out
      && result_sv
      && SvOK(result_sv)
      && gql_runtime_vm_sv_is_outcome(aTHX_ result_sv)) {
    *outcome_out = gql_runtime_vm_expect_outcome(aTHX_ result_sv);
    gql_runtime_vm_outcome_incref(*outcome_out);
    SvREFCNT_dec(result_sv);
    result_sv = NULL;
  }

done_async_current_op:
  if (resolved_sv) {
    SvREFCNT_dec(resolved_sv);
  }
  if (outcome_out && *outcome_out) {
    /* The outcome struct is the result; no SV (not even undef) to return,
     * so the callers' loops skip a per-field SV allocation. */
    if (result_sv) {
      SvREFCNT_dec(result_sv);
    }
    return NULL;
  }
  return result_sv ? result_sv : newSVsv(&PL_sv_undef);
}

static HV *
gql_runtime_vm_fetch_runtime_cache_hv(pTHX_ SV *runtime_schema)
{
  HV *schema_hv;
  SV *runtime_cache_sv;

  schema_hv = gql_runtime_vm_expect_hashref(aTHX_ runtime_schema, "runtime schema");
  runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ schema_hv, "runtime_cache", 13);
  return runtime_cache_sv
    ? gql_runtime_vm_expect_hashref(aTHX_ runtime_cache_sv, "runtime schema runtime_cache")
    : NULL;
}

static SV *
gql_runtime_vm_runtime_schema_exec_struct_sv(pTHX_ SV *runtime_schema)
{
  HV *schema_hv;
  SV *catalog_sv;
  SV *exec_struct_sv;
  dSP;

  schema_hv = gql_runtime_vm_expect_hashref(aTHX_ runtime_schema, "runtime schema");
  catalog_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ schema_hv, "slot_catalog_exec", 17);
  if (catalog_sv && SvOK(catalog_sv)) {
    return NULL;
  }

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  XPUSHs(runtime_schema ? runtime_schema : &PL_sv_undef);
  PUTBACK;
  if (call_method("to_native_exec_struct", G_SCALAR | G_EVAL) != 1 || SvTRUE(ERRSV)) {
    (void)POPs;
    sv_setsv(ERRSV, &PL_sv_undef);
    FREETMPS;
    LEAVE;
    return NULL;
  }
  SPAGAIN;
  exec_struct_sv = (SP > PL_stack_base) ? POPs : NULL;
  exec_struct_sv = exec_struct_sv ? newSVsv(exec_struct_sv) : NULL;
  PUTBACK;
  FREETMPS;
  LEAVE;
  return exec_struct_sv;
}

static const char *
gql_runtime_vm_type_name_from_sv(pTHX_ SV *type_sv);

static gql_runtime_vm_native_runtime_t *
gql_runtime_vm_native_runtime_from_runtime_schema_sv(pTHX_ SV *runtime_schema)
{
  gql_runtime_vm_native_runtime_t *runtime;
  HV *schema_hv;
  SV *exec_struct_sv;
  SV *catalog_sv;
  SV *resolver_catalog_sv;
  AV *catalog_av;
  AV *resolver_catalog_av;
  SV *runtime_cache_sv;
  IV i;

  exec_struct_sv = gql_runtime_vm_runtime_schema_exec_struct_sv(aTHX_ runtime_schema);
  schema_hv = exec_struct_sv
    ? gql_runtime_vm_expect_hashref(aTHX_ exec_struct_sv, "runtime exec schema")
    : gql_runtime_vm_expect_hashref(aTHX_ runtime_schema, "runtime schema");
  catalog_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ schema_hv, "slot_catalog_exec", 17);
  if (!catalog_sv) {
    catalog_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ schema_hv, "slot_catalog", 12);
  }
  if (!catalog_sv) {
    if (exec_struct_sv) {
      SvREFCNT_dec(exec_struct_sv);
    }
    croak("runtime schema is missing slot_catalog");
  }
  catalog_av = gql_runtime_vm_expect_arrayref(aTHX_ catalog_sv, "runtime schema slot_catalog");
  resolver_catalog_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ schema_hv, "slot_resolvers", 14);
  resolver_catalog_av = (resolver_catalog_sv && SvOK(resolver_catalog_sv))
    ? gql_runtime_vm_expect_arrayref(aTHX_ resolver_catalog_sv, "runtime schema slot_resolvers")
    : NULL;

  Newxz(runtime, 1, gql_runtime_vm_native_runtime_t);
  Newxz(runtime->callback_catalog, 1, gql_runtime_vm_native_callback_catalog_t);
  runtime->callback_catalog->runtime_schema = newSVsv(runtime_schema ? runtime_schema : &PL_sv_undef);
  runtime->runtime_slot_count = av_count(catalog_av);
  if (runtime->runtime_slot_count > 0) {
    Newxz(runtime->runtime_slots, runtime->runtime_slot_count, gql_runtime_vm_native_slot_t);
    Newxz(runtime->callback_catalog->slot_field_names, runtime->runtime_slot_count, SV *);
    Newxz(runtime->callback_catalog->slot_resolvers, runtime->runtime_slot_count, SV *);
    Newxz(runtime->callback_catalog->slot_type_objects, runtime->runtime_slot_count, SV *);
    Newxz(runtime->callback_catalog->slot_tag_resolvers, runtime->runtime_slot_count, SV *);
    Newxz(runtime->callback_catalog->slot_resolve_types, runtime->runtime_slot_count, SV *);
    Newxz(runtime->callback_catalog->slot_tag_entries, runtime->runtime_slot_count, gql_runtime_vm_native_tag_entry_t *);
    Newxz(runtime->callback_catalog->slot_tag_entry_counts, runtime->runtime_slot_count, IV);
    Newxz(runtime->callback_catalog->slot_possible_type_entries, runtime->runtime_slot_count, gql_runtime_vm_native_possible_type_entry_t *);
    Newxz(runtime->callback_catalog->slot_possible_type_entry_counts, runtime->runtime_slot_count, IV);
    Newxz(runtime->callback_catalog->slot_leaf_kinds, runtime->runtime_slot_count, IV);
    Newxz(runtime->callback_catalog->slot_leaf_payloads, runtime->runtime_slot_count, SV *);
    for (i = 0; i < runtime->runtime_slot_count; i++) {
      SV **slot_svp = av_fetch(catalog_av, i, 0);
      HV *slot_hv;
      SV *resolver_sv;
      if (!slot_svp || !SvOK(*slot_svp)) {
        if (exec_struct_sv) {
          SvREFCNT_dec(exec_struct_sv);
        }
        gql_runtime_vm_native_runtime_destroy(runtime);
        croak("runtime schema slot_catalog entry %ld is missing", (long)i);
      }
      if (!gql_runtime_vm_parse_native_slot(aTHX_ *slot_svp, &runtime->runtime_slots[i])) {
        if (exec_struct_sv) {
          SvREFCNT_dec(exec_struct_sv);
        }
        gql_runtime_vm_native_runtime_destroy(runtime);
        croak("runtime schema slot_catalog entry %ld is invalid", (long)i);
      }
      slot_hv = gql_runtime_vm_expect_hashref(aTHX_ *slot_svp, "runtime slot");
      resolver_sv = NULL;
      if (resolver_catalog_av && i <= (IV)av_count(resolver_catalog_av)) {
        SV **resolver_svp = av_fetch(resolver_catalog_av, i, 0);
        if (resolver_svp && SvOK(*resolver_svp)) {
          resolver_sv = *resolver_svp;
        }
      }
      if (!resolver_sv) {
        resolver_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ slot_hv, "resolve", 7);
      }
      if (resolver_sv) {
        runtime->callback_catalog->slot_resolvers[i] = newSVsv(resolver_sv);
      }
      if (runtime->runtime_slots[i].field_name && *runtime->runtime_slots[i].field_name) {
        runtime->callback_catalog->slot_field_names[i] = newSVpv(runtime->runtime_slots[i].field_name, 0);
      }
    }
  }

  runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ schema_hv, "runtime_cache", 13);
  if (runtime_cache_sv) {
    HV *runtime_cache_hv = gql_runtime_vm_expect_hashref(aTHX_ runtime_cache_sv, "runtime schema runtime_cache");
    HV *name2type_hv = NULL;
    HV *tag_resolver_map_hv = NULL;
    HV *runtime_tag_map_hv = NULL;
    HV *resolve_type_map_hv = NULL;
    HV *possible_types_hv = NULL;
    HV *is_type_of_map_hv = NULL;
    HV *leaf_kind_map_hv = NULL;
    HV *enum_values_map_hv = NULL;
    HV *serialize_map_hv = NULL;

    if ((runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_cache_hv, "name2type", 9))) {
      name2type_hv = gql_runtime_vm_expect_hashref(aTHX_ runtime_cache_sv, "runtime_cache name2type");
    }
    if ((runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_cache_hv, "tag_resolver_map", 16))) {
      tag_resolver_map_hv = gql_runtime_vm_expect_hashref(aTHX_ runtime_cache_sv, "runtime_cache tag_resolver_map");
    }
    if ((runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_cache_hv, "runtime_tag_map", 15))) {
      runtime_tag_map_hv = gql_runtime_vm_expect_hashref(aTHX_ runtime_cache_sv, "runtime_cache runtime_tag_map");
    }
    if ((runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_cache_hv, "resolve_type_map", 16))) {
      resolve_type_map_hv = gql_runtime_vm_expect_hashref(aTHX_ runtime_cache_sv, "runtime_cache resolve_type_map");
    }
    if ((runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_cache_hv, "possible_types", 14))) {
      possible_types_hv = gql_runtime_vm_expect_hashref(aTHX_ runtime_cache_sv, "runtime_cache possible_types");
    }
    if ((runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_cache_hv, "is_type_of_map", 14))) {
      is_type_of_map_hv = gql_runtime_vm_expect_hashref(aTHX_ runtime_cache_sv, "runtime_cache is_type_of_map");
    }
    if ((runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_cache_hv, "leaf_kind_map", 13))) {
      leaf_kind_map_hv = gql_runtime_vm_expect_hashref(aTHX_ runtime_cache_sv, "runtime_cache leaf_kind_map");
    }
    if ((runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_cache_hv, "enum_values_map", 15))) {
      enum_values_map_hv = gql_runtime_vm_expect_hashref(aTHX_ runtime_cache_sv, "runtime_cache enum_values_map");
    }
    if ((runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_cache_hv, "serialize_map", 13))) {
      serialize_map_hv = gql_runtime_vm_expect_hashref(aTHX_ runtime_cache_sv, "runtime_cache serialize_map");
    }

    if (runtime->runtime_slot_count > 0 && name2type_hv) {
      for (i = 0; i < runtime->runtime_slot_count; i++) {
        const char *return_type_name = runtime->runtime_slots[i].return_type_name;
        gql_runtime_vm_native_slot_t *slot = &runtime->runtime_slots[i];
        IV arg_index;
        SV **type_svp;
        if (!return_type_name) {
          goto finalize_arg_defs;
        }
        type_svp = hv_fetch(name2type_hv, return_type_name, (I32)strlen(return_type_name), 0);
        if (type_svp && SvOK(*type_svp)) {
          runtime->callback_catalog->slot_type_objects[i] = newSVsv(*type_svp);
        }
        if (tag_resolver_map_hv) {
          SV **svp = hv_fetch(tag_resolver_map_hv, return_type_name, (I32)strlen(return_type_name), 0);
          if (svp && SvOK(*svp)) {
            runtime->callback_catalog->slot_tag_resolvers[i] = newSVsv(*svp);
          }
        }
        if (leaf_kind_map_hv) {
          SV **svp = hv_fetch(leaf_kind_map_hv, return_type_name, (I32)strlen(return_type_name), 0);
          if (svp && SvOK(*svp)) {
            IV leaf_kind = SvIV(*svp);
            runtime->callback_catalog->slot_leaf_kinds[i] = leaf_kind;
            if (leaf_kind == GQL_VM_LEAF_ENUM && enum_values_map_hv) {
              SV **payload_svp = hv_fetch(enum_values_map_hv, return_type_name, (I32)strlen(return_type_name), 0);
              if (payload_svp && SvOK(*payload_svp)) {
                runtime->callback_catalog->slot_leaf_payloads[i] = newSVsv(*payload_svp);
              }
            } else if (leaf_kind == GQL_VM_LEAF_CUSTOM && serialize_map_hv) {
              SV **payload_svp = hv_fetch(serialize_map_hv, return_type_name, (I32)strlen(return_type_name), 0);
              if (payload_svp && SvOK(*payload_svp)) {
                runtime->callback_catalog->slot_leaf_payloads[i] = newSVsv(*payload_svp);
              }
            }
          }
        }
        if (runtime_tag_map_hv) {
          SV **svp = hv_fetch(runtime_tag_map_hv, return_type_name, (I32)strlen(return_type_name), 0);
          if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
            HV *tag_map_hv = (HV *)SvRV(*svp);
            IV count = hv_iterinit(tag_map_hv);
            if (count > 0) {
              HE *he;
              IV j = 0;
              Newxz(runtime->callback_catalog->slot_tag_entries[i], count, gql_runtime_vm_native_tag_entry_t);
              runtime->callback_catalog->slot_tag_entry_counts[i] = count;
              hv_iterinit(tag_map_hv);
              while ((he = hv_iternext(tag_map_hv))) {
                SV *val = HeVAL(he);
                const char *tag_name = HeKEY(he);
                const char *type_name = (val && SvOK(val)) ? gql_runtime_vm_type_name_from_sv(aTHX_ val) : NULL;
                runtime->callback_catalog->slot_tag_entries[i][j].tag_name = gql_runtime_vm_copy_cstr(tag_name);
                runtime->callback_catalog->slot_tag_entries[i][j].type_name = gql_runtime_vm_copy_cstr(type_name);
                j++;
              }
            }
          }
        }
        if (resolve_type_map_hv) {
          SV **svp = hv_fetch(resolve_type_map_hv, return_type_name, (I32)strlen(return_type_name), 0);
          if (svp && SvOK(*svp)) {
            runtime->callback_catalog->slot_resolve_types[i] = newSVsv(*svp);
          }
        }
        if (possible_types_hv && is_type_of_map_hv) {
          SV **svp = hv_fetch(possible_types_hv, return_type_name, (I32)strlen(return_type_name), 0);
          if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV) {
            AV *possible_types_av = (AV *)SvRV(*svp);
            IV count = av_count(possible_types_av);
            if (count > 0) {
              IV j;
              Newxz(runtime->callback_catalog->slot_possible_type_entries[i], count, gql_runtime_vm_native_possible_type_entry_t);
              runtime->callback_catalog->slot_possible_type_entry_counts[i] = count;
              for (j = 0; j < count; j++) {
                SV **type_entry_svp = av_fetch(possible_types_av, j, 0);
                SV *type_sv;
                const char *type_name;
                SV **cb_svp;
                if (!type_entry_svp || !SvOK(*type_entry_svp)) {
                  continue;
                }
                type_sv = *type_entry_svp;
                type_name = gql_runtime_vm_type_name_from_sv(aTHX_ type_sv);
                if (!type_name) {
                  continue;
                }
                cb_svp = hv_fetch(is_type_of_map_hv, type_name, (I32)strlen(type_name), 0);
                if (!cb_svp || !SvOK(*cb_svp)) {
                  continue;
                }
                runtime->callback_catalog->slot_possible_type_entries[i][j].type_name = gql_runtime_vm_copy_cstr(type_name);
                runtime->callback_catalog->slot_possible_type_entries[i][j].type_sv = newSVsv(type_sv);
                runtime->callback_catalog->slot_possible_type_entries[i][j].is_type_of_cb = newSVsv(*cb_svp);
              }
            }
          }
        }
finalize_arg_defs:
        if (slot->callback_abi_code != GQL_VM_CALLBACK_ABI_DEFAULT
            && (!runtime->callback_catalog->slot_type_objects[i]
                || !SvOK(runtime->callback_catalog->slot_type_objects[i]))) {
          if (exec_struct_sv) {
            SvREFCNT_dec(exec_struct_sv);
          }
          gql_runtime_vm_native_runtime_destroy(runtime);
          croak(
            "runtime schema slot_catalog entry %ld is missing direct slot_type_object for callback ABI %ld",
            (long)i,
            (long)slot->callback_abi_code
          );
        }
        for (arg_index = 0; arg_index < slot->arg_def_count; arg_index++) {
          gql_runtime_vm_finalize_native_arg_def(aTHX_ runtime_schema, &slot->arg_defs[arg_index]);
        }
      }
    }
  }

  if (exec_struct_sv) {
    SvREFCNT_dec(exec_struct_sv);
  }

  return runtime;
}

static gql_runtime_vm_native_runtime_t *
gql_runtime_vm_exec_state_native_runtime(pTHX_ gql_runtime_vm_exec_state_handle_t *s)
{
  if (!s) {
    return NULL;
  }
  if (!s->native_runtime && s->runtime_schema && SvOK(s->runtime_schema)) {
    s->native_runtime = gql_runtime_vm_native_runtime_from_runtime_schema_sv(aTHX_ s->runtime_schema);
  }
  return s->native_runtime;
}

static gql_runtime_vm_cursor_t *
gql_runtime_vm_new_cursor_struct_for_program(
  pTHX_
  gql_runtime_vm_native_program_t *program,
  IV block_index,
  IV slot_index,
  IV op_index
)
{
  gql_runtime_vm_cursor_t *cursor;

  Newxz(cursor, 1, gql_runtime_vm_cursor_t);
  cursor->refcount = 1;
  cursor->native_program = program;
  cursor->block_index = block_index;
  cursor->slot_index = slot_index;
  cursor->op_index = op_index;
  return cursor;
}

static SV *
gql_runtime_vm_new_exec_state_handle_sv(
  pTHX_
  const char *pkg,
  SV *runtime_schema,
  SV *program,
  gql_runtime_vm_cursor_t *cursor,
  gql_runtime_vm_writer_t *writer,
  SV *context,
  SV *variables,
  SV *root_value,
  SV *empty_args
)
{
  gql_runtime_vm_exec_state_handle_t *state;

  Newxz(state, 1, gql_runtime_vm_exec_state_handle_t);
  state->runtime_schema = newSVsv(runtime_schema ? runtime_schema : &PL_sv_undef);
  state->program = newSVsv(program ? program : &PL_sv_undef);
  state->native_runtime = NULL;
  state->native_runtime_is_borrowed = 0;
  state->cursor = cursor;
  gql_runtime_vm_cursor_incref(state->cursor);
  state->native_program = state->cursor ? state->cursor->native_program : NULL;
  state->frame = NULL;
  state->frame_stack_count = 0;
  state->frame_stack_capacity = 0;
  state->frame_stack = NULL;
  state->field_frame = NULL;
  state->writer = writer;
  gql_runtime_vm_writer_incref(state->writer);
  state->context = newSVsv(context ? context : &PL_sv_undef);
  state->variables = newSVsv(variables ? variables : &PL_sv_undef);
  state->root_value = newSVsv(root_value ? root_value : &PL_sv_undef);
  state->promise_backend_code = GQL_VM_PROMISE_BACKEND_PROMISE_XS;
  state->empty_args = (empty_args && SvOK(empty_args))
    ? newSVsv(empty_args)
    : gql_runtime_vm_empty_args_sv(aTHX);
  state->async_ready_frame_count = 0;
  state->async_ready_frame_capacity = 0;
  state->async_ready_frames = NULL;
  state->async_scheduler_draining = 0;
  return gql_runtime_vm_new_handle_sv(aTHX_ pkg, state);
}

/*
 * R5 leak 2: a request abandoned while promises are pending frees nothing,
 * because the live structures form a reference cycle:
 *
 *   block frame --(pending entry holds the resolver's promise)-->
 *   promise --(then callbacks)--> armed callback ctx --(strong state_sv)-->
 *   exec state --(frame_stack / response frame)--> block frame
 *
 * The response promise handed to the Perl driver carries this magic (a
 * strong ref to the exec state) so the driver can break the cycle when it
 * gives up on the request (deadlocked stall, missing on_stall): clearing
 * the pending entries drops the promise references, which frees the armed
 * callback pairs, which releases their exec-state references - the
 * ordinary DESTROY chain then reclaims every frame. A callback that still
 * fires later (a loader settling after abandonment) hits the entry-index
 * bounds check against the cleared pending array and no-ops.
 */
static MGVTBL gql_runtime_vm_response_state_magic_vtbl;

static void
gql_runtime_vm_attach_response_state_magic(pTHX_ SV *promise_rv, SV *state_sv)
{
  if (!promise_rv || !SvROK(promise_rv) || !state_sv) {
    return;
  }
  /* sv_magicext increments state_sv's refcount (MGf_REFCOUNTED). */
  sv_magicext(SvRV(promise_rv), state_sv, PERL_MAGIC_ext,
              &gql_runtime_vm_response_state_magic_vtbl, NULL, 0);
}

/* Cancel a suspended frame and its pending subtree, depth-first. A
 * BLOCK_FRAME_PTR payload is a suspended child that still owns its
 * allocation reference (resolve_frame, which would have released it, never
 * ran), so each child gets one extra release beyond the entry reference
 * that clear_pending drops. Entries form a tree, so the recursion
 * terminates. */
static void
gql_runtime_vm_cancel_frame_tree(pTHX_ gql_runtime_vm_block_frame_t *frame)
{
  IV i;
  if (!frame) {
    return;
  }
  for (i = 0; i < frame->pending_count; i++) {
    if (frame->pending_entries[i].payload_kind == GQL_VM_PENDING_BLOCK_FRAME_PTR
        && frame->pending_entries[i].payload.block_frame_ptr) {
      gql_runtime_vm_block_frame_t *child =
        frame->pending_entries[i].payload.block_frame_ptr;
      gql_runtime_vm_cancel_frame_tree(aTHX_ child);
      gql_runtime_vm_free_block_frame(aTHX_ child);
    }
  }
  gql_runtime_vm_block_frame_clear_pending(aTHX_ frame);
}

static void
gql_runtime_vm_cancel_pending_response_sv(pTHX_ SV *promise_rv)
{
  MAGIC *mg;
  gql_runtime_vm_exec_state_handle_t *state;
  IV i;

  if (!promise_rv || !SvROK(promise_rv)) {
    return;
  }
  mg = mg_findext(SvRV(promise_rv), PERL_MAGIC_ext,
                  &gql_runtime_vm_response_state_magic_vtbl);
  if (!mg || !mg->mg_obj) {
    return;
  }
  state = gql_runtime_vm_expect_exec_state_handle(aTHX_ mg->mg_obj);
  if (state) {
    if (state->response_frame) {
      gql_runtime_vm_cancel_frame_tree(aTHX_ state->response_frame);
    }
    if (state->frame && state->frame != state->response_frame) {
      gql_runtime_vm_cancel_frame_tree(aTHX_ state->frame);
    }
    for (i = 0; i < state->frame_stack_count; i++) {
      if (state->frame_stack[i] && state->frame_stack[i] != state->response_frame) {
        gql_runtime_vm_cancel_frame_tree(aTHX_ state->frame_stack[i]);
      }
    }
    /* Request-scoped user data can close a second cycle around the exec
     * state (context -> DataLoader -> queued deferred -> promise -> armed
     * callback -> exec state -> context), so a cancelled request drops
     * these references too. Cancelled continuations no-op before touching
     * any of them, and ExecState DESTROY's SvREFCNT_dec is NULL-safe. */
    SvREFCNT_dec(state->context);
    state->context = NULL;
    SvREFCNT_dec(state->root_value);
    state->root_value = NULL;
    SvREFCNT_dec(state->variables);
    state->variables = NULL;
  }
  /* Drop the magic so the promise no longer pins the exec state. */
  sv_unmagicext(SvRV(promise_rv), PERL_MAGIC_ext,
                &gql_runtime_vm_response_state_magic_vtbl);
}

static SV *
gql_runtime_vm_execute_native_program_auto_impl_sv(
  pTHX_
  SV *runtime_sv,
  SV *program_sv,
  SV *root_value,
  SV *context_value,
  SV *variables,
  U8 json_mode
)
{
  gql_runtime_vm_native_runtime_t *runtime;
  gql_runtime_vm_native_program_t *program;
  gql_runtime_vm_cursor_t *cursor = NULL;
  gql_runtime_vm_writer_t *writer = NULL;
  gql_runtime_vm_exec_state_handle_t *state = NULL;
  HV *provided_hv = NULL;
  SV *runtime_schema_sv = &PL_sv_undef;
  SV *prepared_variables_sv = NULL;
  SV *state_sv = NULL;
  SV *data_sv = NULL;
  SV *effective_root = root_value;
  SV *ret = NULL;

  if (!runtime_sv || !SvROK(runtime_sv) || !sv_derived_from(runtime_sv, "GraphQL::Houtou::Runtime::NativeRuntime")) {
    croak("expected a GraphQL::Houtou::Runtime::NativeRuntime");
  }

  runtime = INT2PTR(gql_runtime_vm_native_runtime_t *, SvUV(SvRV(runtime_sv)));
  if (!runtime) {
    croak("native VM runtime handle is no longer valid");
  }

  program = gql_runtime_vm_native_program_from_sv(aTHX_ program_sv);
  if (variables && SvOK(variables) && SvROK(variables) && SvTYPE(SvRV(variables)) == SVt_PVHV) {
    provided_hv = (HV *)SvRV(variables);
  }

  if (runtime->callback_catalog && runtime->callback_catalog->runtime_schema) {
    runtime_schema_sv = runtime->callback_catalog->runtime_schema;
  }
  /* Everything owned before execution is mortal (or dropped once the exec
   * state holds its own reference) so a die() escaping from resolvers or
   * input coercion cannot leak the request state. */
  prepared_variables_sv = sv_2mortal(gql_runtime_vm_prepare_program_variables_sv(
    aTHX_
    runtime_schema_sv,
    program,
    provided_hv
  ));

  cursor = gql_runtime_vm_new_cursor_struct_for_program(
    aTHX_
    program,
    program->root_block_index,
    0,
    0
  );
  writer = gql_runtime_vm_new_writer_struct(aTHX);
  state_sv = sv_2mortal(gql_runtime_vm_new_exec_state_handle_sv(
    aTHX_
    "GraphQL::Houtou::Runtime::ExecState",
    runtime_schema_sv,
    program_sv,
    cursor,
    writer,
    context_value,
    prepared_variables_sv,
    root_value,
    NULL
  ));
  state = gql_runtime_vm_expect_exec_state_handle(aTHX_ state_sv);
  state->native_runtime = runtime;
  state->native_runtime_is_borrowed = 1;
  state->response_json_mode = json_mode;
  /* The exec state holds its own cursor/writer references now. */
  gql_runtime_vm_cursor_decref(aTHX_ cursor);
  cursor = NULL;
  gql_runtime_vm_writer_decref(aTHX_ writer);
  writer = NULL;

  if (!effective_root || !SvOK(effective_root)) {
    effective_root = state->root_value;
  }
  data_sv = gql_runtime_vm_exec_state_execute_block_async_sv(
    aTHX_
    state_sv,
    state,
    program->root_block_index,
    effective_root,
    &PL_sv_undef
  );
  if (state->completed_response_sv) {
    /* The request finished inside this call without a deferred; the
     * parked value is already the finished envelope (or JSON bytes). */
    ret = state->completed_response_sv;
    state->completed_response_sv = NULL;
    SvREFCNT_dec(data_sv);
  } else if (gql_runtime_vm_is_promise_value_for_state_sv(aTHX_ state, data_sv)) {
    /* A genuinely pending response: let the Perl driver reach the exec
     * state for cancellation (see the magic's comment block). */
    gql_runtime_vm_attach_response_state_magic(aTHX_ data_sv, state_sv);
    ret = data_sv;
  } else if (json_mode) {
    ret = gql_runtime_vm_response_json_from_data_sv(aTHX_ state->writer, data_sv);
    SvREFCNT_dec(data_sv);
  } else {
    ret = gql_runtime_vm_exec_state_materialize_response_sv(aTHX_ state, data_sv);
    SvREFCNT_dec(data_sv);
  }

  /* state_sv / prepared_variables_sv are mortal; cursor and writer refs
   * were handed to the exec state above. */
  return ret ? ret : newSVsv(&PL_sv_undef);
}

static SV *
gql_runtime_vm_execute_native_program_auto_sv(
  pTHX_
  SV *runtime_sv,
  SV *program_sv,
  SV *root_value,
  SV *context_value,
  SV *variables
)
{
  return gql_runtime_vm_execute_native_program_auto_impl_sv(
    aTHX_ runtime_sv, program_sv, root_value, context_value, variables, 0
  );
}

static SV *
gql_runtime_vm_execute_native_program_auto_json_sv(
  pTHX_
  SV *runtime_sv,
  SV *program_sv,
  SV *root_value,
  SV *context_value,
  SV *variables
)
{
  return gql_runtime_vm_execute_native_program_auto_impl_sv(
    aTHX_ runtime_sv, program_sv, root_value, context_value, variables, 1
  );
}

static SV *
gql_runtime_vm_call_cb4_nonfatal(pTHX_ SV *cb, SV *arg0, SV *arg1, SV *arg2, SV *arg3, SV **error_out)
{
  dSP;
  SV *ret = NULL;
  int count;

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  XPUSHs(arg0 ? arg0 : &PL_sv_undef);
  XPUSHs(arg1 ? arg1 : &PL_sv_undef);
  XPUSHs(arg2 ? arg2 : &PL_sv_undef);
  XPUSHs(arg3 ? arg3 : &PL_sv_undef);
  PUTBACK;
  count = call_sv(cb, G_SCALAR | G_EVAL);
  SPAGAIN;
  if (SvTRUE(ERRSV)) {
    SV *err = newSVsv(ERRSV);
    sv_setsv(ERRSV, &PL_sv_undef);
    if (error_out) {
      *error_out = err;
      err = NULL;
    }
    if (err) {
      croak_sv(err);
    }
  }
  if (count > 0) {
    ret = newSVsv(POPs);
  }
  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret ? ret : newSVsv(&PL_sv_undef);
}

static SV *
gql_runtime_vm_call_cb5_nonfatal(pTHX_ SV *cb, SV *arg0, SV *arg1, SV *arg2, SV *arg3, SV *arg4, SV **error_out)
{
  dSP;
  SV *ret = NULL;
  int count;

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  XPUSHs(arg0 ? arg0 : &PL_sv_undef);
  XPUSHs(arg1 ? arg1 : &PL_sv_undef);
  XPUSHs(arg2 ? arg2 : &PL_sv_undef);
  XPUSHs(arg3 ? arg3 : &PL_sv_undef);
  XPUSHs(arg4 ? arg4 : &PL_sv_undef);
  PUTBACK;
  count = call_sv(cb, G_SCALAR | G_EVAL);
  SPAGAIN;
  if (SvTRUE(ERRSV)) {
    SV *err = newSVsv(ERRSV);
    sv_setsv(ERRSV, &PL_sv_undef);
    if (error_out) {
      *error_out = err;
      err = NULL;
    }
    if (err) {
      croak_sv(err);
    }
  }
  if (count > 0) {
    ret = newSVsv(POPs);
  }
  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret ? ret : newSVsv(&PL_sv_undef);
}

static SV *
gql_runtime_vm_cached_cv(pTHX_ const char *name)
{
  STRLEN len = name ? strlen(name) : 0;
  return name ? (SV *)get_cvn_flags(name, len, 0) : NULL;
}

static CV *
gql_runtime_vm_directive_runtime_apply_cv(pTHX)
{
  static CV *cv = NULL;
  if (!cv) {
    cv = (CV *)gql_runtime_vm_cached_cv(aTHX_ "GraphQL::Houtou::Runtime::DirectiveRuntime::apply_runtime_directives");
  }
  return cv;
}

static CV *
gql_runtime_vm_directive_runtime_materialize_cv(pTHX)
{
  static CV *cv = NULL;
  if (!cv) {
    cv = (CV *)gql_runtime_vm_cached_cv(aTHX_ "GraphQL::Houtou::Runtime::DirectiveRuntime::materialize_runtime_directives");
  }
  return cv;
}

static CV *
gql_runtime_vm_directive_runtime_program_materialize_cv(pTHX)
{
  static CV *cv = NULL;
  if (!cv) {
    cv = (CV *)gql_runtime_vm_cached_cv(aTHX_ "GraphQL::Houtou::Runtime::DirectiveRuntime::materialize_program_runtime_directives");
  }
  return cv;
}

static SV *
gql_runtime_vm_materialize_runtime_directives_sv(pTHX_ SV *payload, SV *variables)
{
  dSP;
  SV *ret = NULL;
  int count;

  if (!payload || !SvOK(payload)) {
    return newRV_noinc((SV *)newAV());
  }

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(payload);
  XPUSHs(variables ? variables : &PL_sv_undef);
  PUTBACK;
  count = call_sv((SV *)gql_runtime_vm_directive_runtime_materialize_cv(aTHX), G_SCALAR | G_EVAL);
  SPAGAIN;
  if (SvTRUE(ERRSV)) {
    SV *err = newSVsv(ERRSV);
    sv_setsv(ERRSV, &PL_sv_undef);
    FREETMPS;
    LEAVE;
    croak_sv(err);
  }
  if (count > 0) {
    ret = newSVsv(POPs);
  }
  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret ? ret : newRV_noinc((SV *)newAV());
}

static SV *
gql_runtime_vm_program_runtime_directives_sv(
  pTHX_
  SV *program,
  IV block_index,
  IV op_index,
  SV *variables
)
{
  dSP;
  SV *ret = NULL;
  int count;

  if (!program || !SvOK(program) || block_index < 0 || op_index < 0) {
    return newRV_noinc((SV *)newAV());
  }

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(program);
  XPUSHs(sv_2mortal(newSViv(block_index)));
  XPUSHs(sv_2mortal(newSViv(op_index)));
  XPUSHs(variables ? variables : &PL_sv_undef);
  PUTBACK;
  count = call_sv((SV *)gql_runtime_vm_directive_runtime_program_materialize_cv(aTHX), G_SCALAR | G_EVAL);
  SPAGAIN;
  if (SvTRUE(ERRSV)) {
    SV *err = newSVsv(ERRSV);
    sv_setsv(ERRSV, &PL_sv_undef);
    FREETMPS;
    LEAVE;
    croak_sv(err);
  }
  if (count > 0) {
    ret = newSVsv(POPs);
  }
  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret ? ret : newRV_noinc((SV *)newAV());
}

static SV *
gql_runtime_vm_apply_runtime_directives_nonfatal(
  pTHX_
  gql_runtime_vm_exec_state_t *state,
  SV *source,
  SV *resolved,
  SV **error_out
)
{
  dSP;
  SV *ret = NULL;
  SV *runtime_schema_sv = &PL_sv_undef;
  SV *context_sv = &PL_sv_undef;
  SV *return_type_sv = NULL;
  SV *args_sv = NULL;
  SV *info_sv = NULL;
  int count;

  if (!state || !state->op || (!state->op->has_runtime_directives && !state->op->runtime_directives_sv)) {
    return newSVsv(resolved ? resolved : &PL_sv_undef);
  }

  if (state->callback_ctx) {
    if (state->callback_ctx->runtime_schema && SvOK(state->callback_ctx->runtime_schema)) {
      runtime_schema_sv = state->callback_ctx->runtime_schema;
    }
    if (state->callback_ctx->context && SvOK(state->callback_ctx->context)) {
      context_sv = state->callback_ctx->context;
    }
  }
  if (runtime_schema_sv == &PL_sv_undef
      && state->runtime
      && state->runtime->callback_catalog
      && state->runtime->callback_catalog->runtime_schema
      && SvOK(state->runtime->callback_catalog->runtime_schema)) {
    runtime_schema_sv = state->runtime->callback_catalog->runtime_schema;
  }

  return_type_sv = gql_runtime_vm_direct_slot_type_object_sv(state->runtime, state->slot);
  if (!return_type_sv) {
    return_type_sv = gql_runtime_vm_lookup_slot_type_object_sv(
      aTHX_
      state->runtime,
      runtime_schema_sv,
      state->slot
    );
  }

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  args_sv = gql_runtime_vm_build_current_args_sv(aTHX_ state);
  if (!args_sv) {
    /* Argument coercion failed and armed the deferred croak channel:
     * skip the directive application, the response is discarded anyway. */
    FREETMPS;
    LEAVE;
    return newSVsv(resolved ? resolved : &PL_sv_undef);
  }
  args_sv = sv_2mortal(args_sv);
  info_sv = sv_2mortal(gql_runtime_vm_new_callback_info_sv(aTHX_ state));
  PUSHMARK(SP);
  XPUSHs(runtime_schema_sv);
  XPUSHs(source ? source : &PL_sv_undef);
  XPUSHs(args_sv);
  XPUSHs(context_sv);
  XPUSHs(info_sv);
  XPUSHs(return_type_sv ? return_type_sv : &PL_sv_undef);
  XPUSHs(resolved ? resolved : &PL_sv_undef);
  PUTBACK;
  count = call_sv((SV *)gql_runtime_vm_directive_runtime_apply_cv(aTHX), G_SCALAR | G_EVAL);
  SPAGAIN;
  if (SvTRUE(ERRSV)) {
    SV *err = newSVsv(ERRSV);
    sv_setsv(ERRSV, &PL_sv_undef);
    if (error_out) {
      *error_out = err;
      err = NULL;
    }
    if (err) {
      croak_sv(err);
    }
  }
  if (count > 0) {
    ret = newSVsv(POPs);
  }
  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret ? ret : newSVsv(&PL_sv_undef);
}

static int
gql_runtime_vm_slot_uses_native_fast_abi(const gql_runtime_vm_native_slot_t *slot)
{
  return slot && slot->callback_abi_code == GQL_VM_CALLBACK_ABI_EXPLICIT_NATIVE;
}

static int
gql_runtime_vm_slot_uses_explicit_generic_fast_abi(const gql_runtime_vm_native_slot_t *slot)
{
  return slot && slot->callback_abi_code == GQL_VM_CALLBACK_ABI_EXPLICIT_GENERIC;
}

static SV *
gql_runtime_vm_slot_resolver_sv(
  const gql_runtime_vm_native_runtime_t *runtime,
  const gql_runtime_vm_native_slot_t *slot
)
{
  if (!runtime || !slot) {
    return NULL;
  }
  if (slot->schema_slot_index < 0 || slot->schema_slot_index >= runtime->runtime_slot_count) {
    return NULL;
  }
  if (!runtime->callback_catalog || !runtime->callback_catalog->slot_resolvers) {
    return NULL;
  }
  return runtime->callback_catalog->slot_resolvers[slot->schema_slot_index];
}

static gql_runtime_vm_path_frame_t *
gql_runtime_vm_new_result_path_frame(
  pTHX_
  gql_runtime_vm_path_frame_t *parent,
  const gql_runtime_vm_native_slot_t *slot
)
{
  if (slot && slot->result_name) {
    return gql_runtime_vm_new_path_frame_struct_pvn_borrowed(
      aTHX_
      parent,
      slot->result_name,
      slot->result_name_len
    );
  }
  return gql_runtime_vm_new_path_frame_struct(aTHX_ parent, &PL_sv_undef);
}

static int
gql_runtime_vm_slot_can_delay_field_path(
  const gql_runtime_vm_native_runtime_t *runtime,
  const gql_runtime_vm_native_slot_t *slot,
  const gql_runtime_vm_native_op_t *op
)
{
  if (!slot || !op) {
    return 0;
  }
  if (gql_runtime_vm_slot_uses_native_fast_abi(slot)) {
    return 1;
  }
  if (op->complete_code == GQL_VM_COMPLETE_ABSTRACT) {
    return 0;
  }
  if (slot->resolver_shape_code != GQL_VM_RESOLVE_DEFAULT) {
    return 0;
  }
  return gql_runtime_vm_slot_resolver_sv(runtime, slot) ? 0 : 1;
}

static SV *
gql_runtime_vm_lookup_type_object_by_name_sv(pTHX_ SV *runtime_schema, const char *type_name)
{
  HV *runtime_cache_hv;
  SV *name2type_sv;
  HV *name2type_hv;
  SV **svp;

  if (!runtime_schema || !SvOK(runtime_schema) || !type_name || !*type_name) {
    return NULL;
  }
  runtime_cache_hv = gql_runtime_vm_fetch_runtime_cache_hv(aTHX_ runtime_schema);
  if (!runtime_cache_hv) {
    return NULL;
  }
  name2type_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_cache_hv, "name2type", 9);
  if (!name2type_sv || !SvROK(name2type_sv) || SvTYPE(SvRV(name2type_sv)) != SVt_PVHV) {
    return NULL;
  }
  name2type_hv = (HV *)SvRV(name2type_sv);
  svp = hv_fetch(name2type_hv, type_name, (I32)strlen(type_name), 0);
  return (svp && SvOK(*svp)) ? *svp : NULL;
}

static void
gql_runtime_vm_prepare_bundle_block_type_objects(
  pTHX_
  SV *runtime_schema,
  gql_runtime_vm_native_bundle_t *bundle
)
{
  IV i;

  if (!runtime_schema || !SvOK(runtime_schema) || !bundle || !bundle->blocks) {
    return;
  }

  if (bundle->prepared_runtime_schema == runtime_schema) {
    return;
  }

  if (bundle->prepared_runtime_schema && bundle->prepared_runtime_schema != runtime_schema) {
    for (i = 0; i < bundle->block_count; i++) {
      gql_runtime_vm_native_block_t *block = &bundle->blocks[i];
      if (block->type_object_sv) {
        SvREFCNT_dec(block->type_object_sv);
        block->type_object_sv = NULL;
      }
    }
    SvREFCNT_dec(bundle->prepared_runtime_schema);
    bundle->prepared_runtime_schema = NULL;
  }

  for (i = 0; i < bundle->block_count; i++) {
    gql_runtime_vm_native_block_t *block = &bundle->blocks[i];
    SV *type_sv;

    if (block->type_object_sv || !block->type_name || !*block->type_name) {
      continue;
    }
    type_sv = gql_runtime_vm_lookup_type_object_by_name_sv(aTHX_ runtime_schema, block->type_name);
    if (type_sv && SvOK(type_sv)) {
      block->type_object_sv = SvREFCNT_inc_simple_NN(type_sv);
    }
  }

  bundle->prepared_runtime_schema = SvREFCNT_inc_simple_NN(runtime_schema);
}

static SV *
gql_runtime_vm_lookup_slot_type_object_sv(
  pTHX_
  const gql_runtime_vm_native_runtime_t *runtime,
  SV *runtime_schema,
  const gql_runtime_vm_native_slot_t *slot
)
{
  IV slot_index;

  if (!runtime || !slot) {
    return NULL;
  }

  slot_index = slot->schema_slot_index;
  if (slot_index >= 0
      && slot_index < runtime->runtime_slot_count
      && runtime->callback_catalog
      && runtime->callback_catalog->slot_type_objects
      && runtime->callback_catalog->slot_type_objects[slot_index]
      && SvOK(runtime->callback_catalog->slot_type_objects[slot_index])) {
    return runtime->callback_catalog->slot_type_objects[slot_index];
  }

  if (slot->return_type_name && *slot->return_type_name) {
    return gql_runtime_vm_lookup_type_object_by_name_sv(
      aTHX_ runtime_schema,
      slot->return_type_name
    );
  }

  return NULL;
}

static SV *
gql_runtime_vm_execute_bundle_fast_response_sv(
  pTHX_
  gql_runtime_vm_native_runtime_t *runtime,
  SV *runtime_schema,
  gql_runtime_vm_native_bundle_t *bundle,
  SV *root_value,
  SV *context_value,
  SV *variables
)
{
  gql_runtime_vm_exec_state_t state;
  gql_runtime_vm_callback_context_t callback_ctx;
  gql_runtime_vm_writer_t writer_storage;
  SV *data_sv;
  SV *empty_args_sv;
  SV *response_sv;

  Zero(&state, 1, gql_runtime_vm_exec_state_t);
  Zero(&callback_ctx, 1, gql_runtime_vm_callback_context_t);

  state.runtime = runtime;
  state.bundle = bundle;
  callback_ctx.runtime_schema = runtime_schema ? runtime_schema : &PL_sv_undef;
  callback_ctx.root_value = root_value;
  callback_ctx.context = context_value;
  callback_ctx.variables = variables;
  state.callback_ctx = &callback_ctx;
  gql_runtime_vm_prepare_bundle_block_type_objects(aTHX_ callback_ctx.runtime_schema, bundle);

  gql_runtime_vm_init_writer_struct(&writer_storage);
  state.writer = &writer_storage;
  state.path_frame = NULL;
  empty_args_sv = gql_runtime_vm_empty_args_sv(aTHX);
  state.empty_args_sv = empty_args_sv;

  data_sv = gql_runtime_vm_execute_block_fast_sv(
    aTHX_
    &state,
    bundle->root_block_index,
    root_value
  );

  response_sv = gql_runtime_vm_fast_response_sv(aTHX_ data_sv, &writer_storage);
  SvREFCNT_dec(empty_args_sv);
  gql_runtime_vm_clear_writer_struct(aTHX_ &writer_storage);
  if (state.fast_lane_deferred_croak_sv) {
    /* Deferred from mid-lane so the path frame chain unwound normally. */
    SvREFCNT_dec(response_sv);
    croak_sv(sv_2mortal(state.fast_lane_deferred_croak_sv));
  }
  return response_sv;
}

static SV *
gql_runtime_vm_direct_slot_type_object_sv(
  const gql_runtime_vm_native_runtime_t *runtime,
  const gql_runtime_vm_native_slot_t *slot
)
{
  IV slot_index;

  if (!runtime || !slot) {
    return NULL;
  }
  slot_index = slot->schema_slot_index;
  if (slot_index < 0 || slot_index >= runtime->runtime_slot_count) {
    return NULL;
  }
  if (!runtime->callback_catalog || !runtime->callback_catalog->slot_type_objects) {
    return NULL;
  }
  if (!runtime->callback_catalog->slot_type_objects[slot_index]
      || !SvOK(runtime->callback_catalog->slot_type_objects[slot_index])) {
    return NULL;
  }
  return runtime->callback_catalog->slot_type_objects[slot_index];
}

static SV *
gql_runtime_vm_new_callback_info_sv(pTHX_ const gql_runtime_vm_exec_state_t *state)
{
  SV *return_type_sv;
  SV *directives_sv = NULL;
  const gql_runtime_vm_callback_context_t *ctx = state ? state->callback_ctx : NULL;
  const gql_runtime_vm_native_slot_t *slot = state ? state->slot : NULL;
  const gql_runtime_vm_native_op_t *op = state ? state->op : NULL;
  const gql_runtime_vm_native_block_t *block = state ? state->block : NULL;
  gql_runtime_vm_native_callback_catalog_t *catalog =
    (state && state->runtime) ? state->runtime->callback_catalog : NULL;
  SV *field_name_sv = NULL;

  if (!state) {
    return newRV_noinc((SV *)newHV());
  }

  return_type_sv = gql_runtime_vm_direct_slot_type_object_sv(state->runtime, slot);
  if (!return_type_sv) {
    return_type_sv = gql_runtime_vm_lookup_slot_type_object_sv(
      aTHX_
      state->runtime,
      ctx ? ctx->runtime_schema : &PL_sv_undef,
      slot
    );
  }
  if (catalog
      && catalog->slot_field_names
      && slot
      && slot->schema_slot_index >= 0
      && slot->schema_slot_index < state->runtime->runtime_slot_count) {
    field_name_sv = catalog->slot_field_names[slot->schema_slot_index];
  }
  if (op
      && op->runtime_directives_sv
      && op->runtime_directives_mode_code == GQL_VM_ARGS_STATIC) {
    directives_sv = newSVsv(op->runtime_directives_sv);
  } else if (ctx && ctx->program && state->block_index >= 0 && state->op_index >= 0) {
    directives_sv = gql_runtime_vm_program_runtime_directives_sv(
      aTHX_
      ctx->program,
      state->block_index,
      state->op_index,
      (ctx && ctx->variables) ? ctx->variables : &PL_sv_undef
    );
  } else if (op && op->runtime_directives_sv) {
    directives_sv = gql_runtime_vm_materialize_runtime_directives_sv(
      aTHX_
      op->runtime_directives_sv,
      (ctx && ctx->variables) ? ctx->variables : &PL_sv_undef
    );
  }

  return gql_runtime_vm_new_lazy_info_handle_sv(
    aTHX_
    field_name_sv,
    slot ? slot->field_name : NULL,
    block ? block->type_object_sv : NULL,
    block ? block->type_name : NULL,
    slot ? slot->return_type_name : NULL,
    return_type_sv,
    state->path_frame,
    (ctx && ctx->context) ? ctx->context : &PL_sv_undef,
    (ctx && ctx->root_value) ? ctx->root_value : &PL_sv_undef,
    (ctx && ctx->variables) ? ctx->variables : &PL_sv_undef,
    (ctx && ctx->program) ? ctx->program : &PL_sv_undef,
    (ctx && ctx->runtime_schema) ? ctx->runtime_schema : &PL_sv_undef,
    directives_sv ? sv_2mortal(directives_sv) : &PL_sv_undef,
    state->block_index,
    state->op_index
  );
}

static IV
gql_runtime_vm_find_abstract_child_block_index(const gql_runtime_vm_native_op_t *op, const char *type_name)
{
  IV i;
  if (!op || !type_name) {
    return -1;
  }
  if (op->abstract_child_count == 1) {
    if (op->abstract_child_names
        && op->abstract_child_names[0]
        && strEQ(op->abstract_child_names[0], type_name)) {
      return op->abstract_child_indexes ? op->abstract_child_indexes[0] : -1;
    }
    return -1;
  }
  for (i = 0; i < op->abstract_child_count; i++) {
    if (op->abstract_child_names[i] && strEQ(op->abstract_child_names[i], type_name)) {
      return op->abstract_child_indexes[i];
    }
  }
  return -1;
}

static const char *
gql_runtime_vm_type_name_from_sv(pTHX_ SV *type_sv)
{
  if (!type_sv || !SvOK(type_sv)) {
    return NULL;
  }
  if (SvROK(type_sv) && SvTYPE(SvRV(type_sv)) == SVt_PVHV) {
    HV *hv = (HV *)SvRV(type_sv);
    return gql_runtime_vm_fetch_hash_entry_pv(aTHX_ hv, "name", 4);
  }
  return SvPOK(type_sv) ? SvPV_nolen(type_sv) : NULL;
}

static SV *
gql_runtime_vm_clone_value_sv(pTHX_ SV *value)
{
  return newSVsv(value ? value : &PL_sv_undef);
}

/*
 * Async pending paths store callback values beyond the current Perl stack.
 * Keep these on the conservative clone path until the scheduler carries
 * stronger ownership provenance for every stored value.
 */
static SV *
gql_runtime_vm_snapshot_scalarish_value_sv(pTHX_ SV *value)
{
  if (!value || !SvOK(value)) {
    return newSVsv(&PL_sv_undef);
  }
  return newSVsv(value);
}

static SV *
gql_runtime_vm_clone_args_payload_sv(pTHX_ SV *value)
{
  if (!value) {
    return newSVsv(&PL_sv_undef);
  }
  if (!SvROK(value)) {
    return newSVsv(value);
  }

  switch (SvTYPE(SvRV(value))) {
    case SVt_PVHV: {
      HV *src_hv = (HV *)SvRV(value);
      HV *dst_hv = newHV();
      HE *he;
      hv_iterinit(src_hv);
      while ((he = hv_iternext(src_hv))) {
        SV *keysv = hv_iterkeysv(he);
        SV *val = HeVAL(he);
        hv_store_ent(dst_hv, keysv, gql_runtime_vm_clone_args_payload_sv(aTHX_ val), 0);
      }
      return newRV_noinc((SV *)dst_hv);
    }
    case SVt_PVAV: {
      AV *src_av = (AV *)SvRV(value);
      AV *dst_av = newAV();
      IV i;
      av_extend(dst_av, av_count(src_av) > 0 ? av_count(src_av) - 1 : 0);
      for (i = 0; i < (IV)av_count(src_av); i++) {
        SV **item_svp = av_fetch(src_av, i, 0);
        av_store(dst_av, i, gql_runtime_vm_clone_args_payload_sv(aTHX_ (item_svp && SvOK(*item_svp)) ? *item_svp : &PL_sv_undef));
      }
      return newRV_noinc((SV *)dst_av);
    }
    default:
      return newSVsv(value);
  }
}

static SV *
gql_runtime_vm_build_current_args_sv(pTHX_ gql_runtime_vm_exec_state_t *state)
{
  const gql_runtime_vm_native_op_t *op = state->op;
  const gql_runtime_vm_native_slot_t *slot = state->slot;
  gql_runtime_vm_native_runtime_t *runtime = state->runtime;
  gql_runtime_vm_callback_context_t *callback_ctx = state->callback_ctx;
  HV *variables_hv = NULL;
  SV *specialized_sv;
  if (!op) {
    if (state && state->empty_args_sv) {
      SvREFCNT_inc(state->empty_args_sv);
      return state->empty_args_sv;
    }
    return newRV_noinc((SV *)newHV());
  }
  if (!op->has_args && (!slot || slot->arg_def_count == 0)) {
    if (state && state->empty_args_sv) {
      SvREFCNT_inc(state->empty_args_sv);
      return state->empty_args_sv;
    }
    return newRV_noinc((SV *)newHV());
  }
  if (callback_ctx
      && callback_ctx->variables
      && SvROK(callback_ctx->variables)
      && SvTYPE(SvRV(callback_ctx->variables)) == SVt_PVHV) {
    variables_hv = (HV *)SvRV(callback_ctx->variables);
  }
  if (slot && (slot->arg_def_count > 0 || op->has_args)) {
    if (op->args_mode_code == GQL_VM_ARGS_STATIC && op->args_payload_native) {
      if (gql_runtime_vm_slot_uses_native_fast_abi(slot)) {
        return gql_runtime_vm_native_args_payload_materialize_cached_sv(aTHX_ op->args_payload_native);
      }
      return gql_runtime_vm_native_args_payload_materialize_sv(aTHX_ op->args_payload_native);
    }
    {
      SV *coercion_croak_sv = NULL;
      specialized_sv = gql_runtime_vm_specialize_arg_payload_sv(
        aTHX_ runtime, slot, op, variables_hv,
        state ? &coercion_croak_sv : NULL
      );
      if (coercion_croak_sv) {
        /* Request-time argument coercion failed (e.g. a null non-null
         * variable). Route it to the deferred croak channel and return
         * NULL so the caller skips the resolver; the top-level entry
         * re-raises it after the lane unwound its path frames. */
        if (!state->fast_lane_deferred_croak_sv) {
          state->fast_lane_deferred_croak_sv = coercion_croak_sv;
        } else {
          SvREFCNT_dec(coercion_croak_sv);
        }
        return NULL;
      }
    }
    if (specialized_sv) {
      return specialized_sv;
    }
    if (state && state->empty_args_sv) {
      SvREFCNT_inc(state->empty_args_sv);
      return state->empty_args_sv;
    }
    return newRV_noinc((SV *)newHV());
  }
  if (op->args_mode_code == GQL_VM_ARGS_STATIC && op->args_payload_native) {
    if (gql_runtime_vm_slot_uses_native_fast_abi(slot)) {
      return gql_runtime_vm_native_args_payload_materialize_cached_sv(aTHX_ op->args_payload_native);
    }
    return gql_runtime_vm_native_args_payload_materialize_sv(aTHX_ op->args_payload_native);
  }
  if (state && state->empty_args_sv) {
    SvREFCNT_inc(state->empty_args_sv);
    return state->empty_args_sv;
  }
  return newRV_noinc((SV *)newHV());
}

static SV *
gql_runtime_vm_resolve_current_field_default_fast_sv(
  pTHX_
  gql_runtime_vm_exec_state_t *state,
  SV *source,
  SV **error_out
)
{
  SV *resolver_sv;
  SV *return_type_sv = NULL;
  gql_runtime_vm_native_runtime_t *runtime = state->runtime;
  const gql_runtime_vm_native_slot_t *slot = state->slot;

  if (!runtime || slot->schema_slot_index < 0 || slot->schema_slot_index >= runtime->runtime_slot_count) {
    croak("native VM schema slot index %ld is invalid", (long)slot->schema_slot_index);
  }
  resolver_sv = (runtime->callback_catalog && runtime->callback_catalog->slot_resolvers)
    ? runtime->callback_catalog->slot_resolvers[slot->schema_slot_index]
    : NULL;

  if (resolver_sv && SvOK(resolver_sv)) {
    SV *args = gql_runtime_vm_build_current_args_sv(aTHX_ state);
    if (!args) {
      /* Argument coercion failed and armed the deferred croak channel:
       * skip the resolver and complete the field as null. */
      return newSVsv(&PL_sv_undef);
    }
    args = sv_2mortal(args);

    if (gql_runtime_vm_slot_uses_native_fast_abi(slot)) {
      return_type_sv = gql_runtime_vm_direct_slot_type_object_sv(runtime, slot);
      return gql_runtime_vm_fast_lane_guard_promise_sv(aTHX_ state, gql_runtime_vm_call_cb4_nonfatal(
        aTHX_
        resolver_sv,
        source,
        args,
        state->callback_ctx ? state->callback_ctx->context : &PL_sv_undef,
        return_type_sv ? return_type_sv : &PL_sv_undef,
        error_out
      ));
    }

    return_type_sv = gql_runtime_vm_direct_slot_type_object_sv(runtime, slot);
    if (!return_type_sv && !gql_runtime_vm_slot_uses_explicit_generic_fast_abi(slot)) {
      return_type_sv = gql_runtime_vm_lookup_slot_type_object_sv(
        aTHX_ runtime,
        state->callback_ctx ? state->callback_ctx->runtime_schema : &PL_sv_undef,
        slot
      );
    }
    if (!return_type_sv && gql_runtime_vm_slot_uses_explicit_generic_fast_abi(slot)) {
      croak("native VM slot type object is missing for explicit generic callback");
    }

    return gql_runtime_vm_fast_lane_guard_promise_sv(aTHX_ state, gql_runtime_vm_call_cb5_nonfatal(
      aTHX_
      resolver_sv,
      source,
      args,
      state->callback_ctx ? state->callback_ctx->context : &PL_sv_undef,
      sv_2mortal(gql_runtime_vm_new_callback_info_sv(aTHX_ state)),
      return_type_sv ? return_type_sv : &PL_sv_undef,
      error_out
    ));
  }

  if (slot->field_name
      && slot->field_name_len == (STRLEN)sizeof("__typename") - 1
      && memEQ(slot->field_name, "__typename", sizeof("__typename") - 1)) {
    return newSVpv((state->block && state->block->type_name) ? state->block->type_name : "", 0);
  }

  {
    CV *method_cv = gql_runtime_vm_default_method_cv(source, slot->field_name);
    if (method_cv) {
      SV *args = gql_runtime_vm_build_current_args_sv(aTHX_ state);
      SV *info;
      SV *resolved;
      if (!args) {
        return newSVsv(&PL_sv_undef);
      }
      args = sv_2mortal(args);
      info = sv_2mortal(gql_runtime_vm_new_callback_info_sv(aTHX_ state));
      resolved = gql_runtime_vm_call_cb4_nonfatal(
        aTHX_ (SV *)method_cv, source, args,
        state->callback_ctx ? state->callback_ctx->context : &PL_sv_undef,
        info, error_out
      );
      return gql_runtime_vm_fast_lane_guard_promise_sv(aTHX_ state, resolved);
    }
  }

  if (source && SvROK(source) && SvTYPE(SvRV(source)) == SVt_PVHV) {
    HV *source_hv = (HV *)SvRV(source);
    SV **value_svp = hv_fetch(source_hv, slot->field_name, (I32)slot->field_name_len, 0);
    if (value_svp && gql_runtime_vm_is_callable_property_candidate(aTHX_ *value_svp)) {
      SV *args = gql_runtime_vm_build_current_args_sv(aTHX_ state);
      SV *info;
      SV *resolved;
      if (!args) {
        return newSVsv(&PL_sv_undef);
      }
      args = sv_2mortal(args);
      info = sv_2mortal(gql_runtime_vm_new_callback_info_sv(aTHX_ state));
      resolved = gql_runtime_vm_call_default_property_sv(
        aTHX_ *value_svp, args,
        state->callback_ctx ? state->callback_ctx->context : &PL_sv_undef,
        info, error_out
      );
      return gql_runtime_vm_fast_lane_guard_promise_sv(aTHX_ state, resolved);
    }
    return gql_runtime_vm_clone_value_sv(aTHX_ (value_svp && SvOK(*value_svp)) ? *value_svp : &PL_sv_undef);
  }

  return newSVsv(&PL_sv_undef);
}


static SV *
gql_runtime_vm_fast_lane_guard_promise_sv(pTHX_ gql_runtime_vm_exec_state_t *state, SV *resolved)
{
  /* The sync fast lanes cannot suspend, so a promise-returning resolver
   * is a routing misconfiguration: async schemas declare themselves with
   * async => 1 on the runtime (or pass on_stall per request). Croaking
   * from mid-lane would leak the live path frame chain (each recursion
   * level holds one reference the unwind never releases - R5 leak 3), so
   * this completes the field as null, records the deferred croak, and the
   * top-level entry raises it after the lane unwound normally. */
  if (resolved
      && SvROK(resolved)
      && SvOBJECT(SvRV(resolved))
      && sv_derived_from(resolved, "Promise::XS::Promise")) {
    SvREFCNT_dec(resolved);
    if (state && !state->fast_lane_deferred_croak_sv) {
      state->fast_lane_deferred_croak_sv =
        newSVpv(GQL_RUNTIME_VM_FAST_LANE_PROMISE_ERROR, 0);
    }
    return newSVsv(&PL_sv_undef);
  }
  return resolved;
}

static SV *
gql_runtime_vm_resolve_current_field_explicit_fast_sv(
  pTHX_
  gql_runtime_vm_exec_state_t *state,
  SV *source,
  SV **error_out
)
{
  SV *resolver_sv;
  SV *return_type_sv = NULL;
  gql_runtime_vm_native_runtime_t *runtime = state->runtime;
  const gql_runtime_vm_native_slot_t *slot = state->slot;

  if (!runtime || slot->schema_slot_index < 0 || slot->schema_slot_index >= runtime->runtime_slot_count) {
    croak("native VM schema slot index %ld is invalid", (long)slot->schema_slot_index);
  }
  resolver_sv = (runtime->callback_catalog && runtime->callback_catalog->slot_resolvers)
    ? runtime->callback_catalog->slot_resolvers[slot->schema_slot_index]
    : NULL;

  if (!resolver_sv || !SvOK(resolver_sv)) {
    return gql_runtime_vm_clone_value_sv(aTHX_ &PL_sv_undef);
  }

  {
    SV *args = gql_runtime_vm_build_current_args_sv(aTHX_ state);
    if (!args) {
      /* Argument coercion failed and armed the deferred croak channel:
       * skip the resolver and complete the field as null. */
      return newSVsv(&PL_sv_undef);
    }
    args = sv_2mortal(args);

    if (gql_runtime_vm_slot_uses_native_fast_abi(slot)) {
      return_type_sv = gql_runtime_vm_direct_slot_type_object_sv(runtime, slot);
      return gql_runtime_vm_fast_lane_guard_promise_sv(aTHX_ state, gql_runtime_vm_call_cb4_nonfatal(
        aTHX_
        resolver_sv,
        source,
        args,
        state->callback_ctx ? state->callback_ctx->context : &PL_sv_undef,
        return_type_sv ? return_type_sv : &PL_sv_undef,
        error_out
      ));
    }

    return_type_sv = gql_runtime_vm_direct_slot_type_object_sv(runtime, slot);
    if (!return_type_sv) {
      return_type_sv = gql_runtime_vm_lookup_slot_type_object_sv(
        aTHX_ runtime,
        state->callback_ctx ? state->callback_ctx->runtime_schema : &PL_sv_undef,
        slot
      );
    }

    return gql_runtime_vm_fast_lane_guard_promise_sv(aTHX_ state, gql_runtime_vm_call_cb5_nonfatal(
      aTHX_
      resolver_sv,
      source,
      args,
      state->callback_ctx ? state->callback_ctx->context : &PL_sv_undef,
      sv_2mortal(gql_runtime_vm_new_callback_info_sv(aTHX_ state)),
      return_type_sv ? return_type_sv : &PL_sv_undef,
      error_out
    ));
  }
}

static IV
gql_runtime_vm_dispatch_index_from_opcode(IV opcode_code)
{
  switch (opcode_code) {
    case GQL_VM_OPCODE(GQL_VM_RESOLVE_DEFAULT, GQL_VM_COMPLETE_GENERIC): return 0;
    case GQL_VM_OPCODE(GQL_VM_RESOLVE_DEFAULT, GQL_VM_COMPLETE_OBJECT): return 1;
    case GQL_VM_OPCODE(GQL_VM_RESOLVE_DEFAULT, GQL_VM_COMPLETE_LIST): return 2;
    case GQL_VM_OPCODE(GQL_VM_RESOLVE_DEFAULT, GQL_VM_COMPLETE_ABSTRACT): return 3;
    case GQL_VM_OPCODE(GQL_VM_RESOLVE_EXPLICIT, GQL_VM_COMPLETE_GENERIC): return 4;
    case GQL_VM_OPCODE(GQL_VM_RESOLVE_EXPLICIT, GQL_VM_COMPLETE_OBJECT): return 5;
    case GQL_VM_OPCODE(GQL_VM_RESOLVE_EXPLICIT, GQL_VM_COMPLETE_LIST): return 6;
    case GQL_VM_OPCODE(GQL_VM_RESOLVE_EXPLICIT, GQL_VM_COMPLETE_ABSTRACT): return 7;
    default: return -1;
  }
}

static SV *gql_runtime_vm_execute_block_fast_sv(pTHX_ gql_runtime_vm_exec_state_t *state, IV block_index, SV *source);

static SV *
gql_runtime_vm_execute_child_block_fast_sv(
  pTHX_
  gql_runtime_vm_exec_state_t *state,
  IV block_index,
  SV *source
)
{
  gql_runtime_vm_path_frame_t *saved_path_frame = state ? state->path_frame : NULL;
  int saved_path_is_current_field = state ? state->path_frame_is_current_field : 0;
  gql_runtime_vm_path_frame_t *field_path;
  SV *ret;

  if (!state) {
    return newSVsv(&PL_sv_undef);
  }

  if (state->path_frame_is_current_field) {
    field_path = NULL;
  } else {
    field_path = gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, state->slot);
    state->path_frame = field_path;
    state->path_frame_is_current_field = 1;
  }
  ret = gql_runtime_vm_execute_block_fast_sv(aTHX_ state, block_index, source);
  state->path_frame = saved_path_frame;
  state->path_frame_is_current_field = saved_path_is_current_field;
  if (field_path) {
    gql_runtime_vm_path_frame_decref(field_path);
  }
  return ret;
}

/*
 * Shared abstract dispatch for the sync fast lanes: resolve the concrete
 * runtime type for `value` (tag resolver / resolve_type / possible types)
 * and return the matching abstract child block index, or -1.
 */
static IV
gql_runtime_vm_select_abstract_child_block_fast_core(
  pTHX_
  gql_runtime_vm_exec_state_t *state,
  SV *value,
  SV **error_out
)
{
  IV child_block_index = -1;
  gql_runtime_vm_native_runtime_t *runtime = state->runtime;
  const gql_runtime_vm_native_slot_t *slot = state->slot;
  const gql_runtime_vm_native_op_t *op = state->op;
  gql_runtime_vm_native_callback_catalog_t *catalog = runtime ? runtime->callback_catalog : NULL;
  IV slot_index;
  SV *info_sv = NULL;
  SV *abstract_type = NULL;
  int use_native_fast_abi = gql_runtime_vm_slot_uses_native_fast_abi(slot);

  if (!runtime) {
    return -1;
  }
  slot_index = slot->schema_slot_index;
  if (slot_index < 0 || slot_index >= runtime->runtime_slot_count) {
    return -1;
  }

  if (op->dispatch_family_code == GQL_VM_DISPATCH_TAG) {
    SV *tag_resolver = (catalog && catalog->slot_tag_resolvers)
      ? catalog->slot_tag_resolvers[slot_index]
      : NULL;
    SV *tag_sv;
    const char *type_name = NULL;

    if (tag_resolver
        && catalog
        && catalog->slot_tag_entries
        && catalog->slot_tag_entry_counts
        && catalog->slot_tag_entry_counts[slot_index] > 0) {
      abstract_type = gql_runtime_vm_direct_slot_type_object_sv(runtime, slot);
      if (!abstract_type) {
        abstract_type = gql_runtime_vm_lookup_slot_type_object_sv(
          aTHX_
          runtime,
          state->callback_ctx ? state->callback_ctx->runtime_schema : &PL_sv_undef,
          slot
        );
      }
      if (use_native_fast_abi) {
        tag_sv = gql_runtime_vm_call_cb4_nonfatal(
          aTHX_
          tag_resolver,
          value,
          state->callback_ctx ? state->callback_ctx->context : &PL_sv_undef,
          abstract_type ? abstract_type : &PL_sv_undef,
          &PL_sv_undef,
          error_out
        );
      } else {
        if (!info_sv) {
          info_sv = sv_2mortal(gql_runtime_vm_new_callback_info_sv(aTHX_ state));
        }
        tag_sv = gql_runtime_vm_call_cb4_nonfatal(
          aTHX_
          tag_resolver,
          value,
          state->callback_ctx ? state->callback_ctx->context : &PL_sv_undef,
          info_sv,
          abstract_type ? abstract_type : &PL_sv_undef,
          error_out
        );
      }
      if (error_out && *error_out) {
        return -1;
      }
      type_name = gql_runtime_vm_find_tagged_type_name(runtime, slot_index, tag_sv);
      child_block_index = gql_runtime_vm_find_abstract_child_block_index(op, type_name);
      SvREFCNT_dec(tag_sv);
    }
  }

  if (child_block_index < 0
      && (op->dispatch_family_code == GQL_VM_DISPATCH_RESOLVE_TYPE
          || op->dispatch_family_code == GQL_VM_DISPATCH_TAG)) {
    SV *resolve_type = (catalog && catalog->slot_resolve_types)
      ? catalog->slot_resolve_types[slot_index]
      : NULL;
    SV *type_sv;
    const char *type_name = NULL;

    if (!resolve_type) {
      return -1;
    }
    if (!abstract_type) {
      abstract_type = gql_runtime_vm_direct_slot_type_object_sv(runtime, slot);
    }
    if (!abstract_type) {
      abstract_type = gql_runtime_vm_lookup_slot_type_object_sv(
        aTHX_
        runtime,
        state->callback_ctx ? state->callback_ctx->runtime_schema : &PL_sv_undef,
        slot
      );
    }
    if (use_native_fast_abi) {
      type_sv = gql_runtime_vm_call_cb4_nonfatal(
        aTHX_
        resolve_type,
        value,
        state->callback_ctx ? state->callback_ctx->context : &PL_sv_undef,
        &PL_sv_undef,
        abstract_type ? abstract_type : &PL_sv_undef,
        error_out
      );
    } else {
      if (!info_sv) {
        info_sv = sv_2mortal(gql_runtime_vm_new_callback_info_sv(aTHX_ state));
      }
      type_sv = gql_runtime_vm_call_cb4_nonfatal(
        aTHX_
        resolve_type,
        value,
        state->callback_ctx ? state->callback_ctx->context : &PL_sv_undef,
        info_sv,
        abstract_type ? abstract_type : &PL_sv_undef,
        error_out
      );
    }
    if (error_out && *error_out) {
      return -1;
    }
    type_name = gql_runtime_vm_type_name_from_sv(aTHX_ type_sv);
    child_block_index = gql_runtime_vm_find_abstract_child_block_index(op, type_name);
    SvREFCNT_dec(type_sv);
  }

  if (child_block_index < 0) {
    if (!use_native_fast_abi && !info_sv) {
      info_sv = sv_2mortal(gql_runtime_vm_new_callback_info_sv(aTHX_ state));
    }
    gql_runtime_vm_native_possible_type_entry_t *entry =
      gql_runtime_vm_find_matching_possible_type(
        aTHX_
        runtime,
        slot_index,
        value,
        state->callback_ctx ? state->callback_ctx->context : &PL_sv_undef,
        use_native_fast_abi ? NULL : info_sv,
        error_out
      );
    if (error_out && *error_out) {
      return -1;
    }
    if (entry) {
      if (op->abstract_child_count == 1
          && op->abstract_child_names
          && op->abstract_child_names[0]
          && entry->type_name
          && strEQ(op->abstract_child_names[0], entry->type_name)) {
        child_block_index = op->abstract_child_indexes ? op->abstract_child_indexes[0] : -1;
      } else {
        child_block_index = gql_runtime_vm_find_abstract_child_block_index(op, entry->type_name);
      }
    }
  }

  return child_block_index;
}

/* Failing to resolve a member type is a field error per the spec: the
 * callers null the field/item and record the error, never leak the raw
 * source value. The wrapper guarantees the error regardless of which
 * early return in the core produced the -1. */
static IV
gql_runtime_vm_select_abstract_child_block_fast(
  pTHX_
  gql_runtime_vm_exec_state_t *state,
  SV *value,
  SV **error_out
)
{
  const gql_runtime_vm_native_slot_t *slot = state->slot;
  IV child_block_index = gql_runtime_vm_select_abstract_child_block_fast_core(
    aTHX_ state, value, error_out
  );
  if (child_block_index < 0 && error_out && !*error_out) {
    *error_out = newSVpvf(
      "Abstract type %s must resolve to an Object type at runtime",
      slot && slot->return_type_name ? slot->return_type_name : "(unknown)"
    );
  }
  return child_block_index;
}

static SV *
gql_runtime_vm_complete_current_abstract_fast_sv(
  pTHX_
  gql_runtime_vm_exec_state_t *state,
  SV *value,
  SV **error_out
)
{
  IV child_block_index;
  /* A null abstract value completes as null without consulting the
   * tag/resolve_type dispatch (mirrors the async lane). */
  if (!value || !SvOK(value)) {
    return newSVsv(&PL_sv_undef);
  }
  child_block_index = gql_runtime_vm_select_abstract_child_block_fast(
    aTHX_ state, value, error_out
  );
  if (error_out && *error_out) {
    return NULL;
  }
  if (child_block_index < 0) {
    return newSVsv(&PL_sv_undef);
  }
  return gql_runtime_vm_execute_child_block_fast_sv(aTHX_ state, child_block_index, value);
}

static SV *
gql_runtime_vm_complete_current_generic_fast_sv(
  pTHX_
  gql_runtime_vm_exec_state_t *state,
  SV *value,
  SV **error_out
)
{
  /*
   * Leaf result coercion: serialize_leaf_sv returns an owned SV (the input
   * with an extra ref when it already conforms, matching this lane's
   * ownership-transfer contract; the dispatch loop drops the original
   * "resolved" ref after completion). A coercion failure sets *error_out
   * and the loop records a field error + null.
   */
  return gql_runtime_vm_serialize_leaf_sv(aTHX_ state->runtime, state->slot, value, error_out);
}

static SV *
gql_runtime_vm_complete_current_object_fast_sv(pTHX_ gql_runtime_vm_exec_state_t *state, SV *value)
{
  const gql_runtime_vm_native_op_t *op = state->op;
  if (op->complete_code == GQL_VM_COMPLETE_OBJECT && op->child_block_index >= 0) {
    /* A null resolved value completes as null; the selection block only
     * runs over a present source (mirrors the async lane). */
    if (!value || !SvOK(value)) {
      return newSVsv(&PL_sv_undef);
    }
    return gql_runtime_vm_execute_child_block_fast_sv(aTHX_ state, op->child_block_index, value);
  }
  return gql_runtime_vm_clone_value_sv(aTHX_ value);
}

/* Record a field error at `path` on the fast lanes' shared writer (the
 * envelope/JSON response tails render writer records into the errors
 * array). Copies error_sv; the caller keeps ownership. */
static void
gql_runtime_vm_fast_lane_record_error_for_path(
  pTHX_
  gql_runtime_vm_exec_state_t *state,
  SV *error_sv,
  gql_runtime_vm_path_frame_t *path
)
{
  gql_runtime_vm_outcome_t *outcome =
    gql_runtime_vm_new_error_outcome_struct_for_path(aTHX_ error_sv, path);
  if (state->writer) {
    IV j;
    for (j = 0; j < outcome->error_record_count; j++) {
      gql_runtime_vm_writer_push_error_record(state->writer, outcome->error_records[j]);
    }
  }
  gql_runtime_vm_outcome_decref(aTHX_ outcome);
}

static SV *
gql_runtime_vm_complete_current_list_fast_sv(pTHX_ gql_runtime_vm_exec_state_t *state, SV *value)
{
  const gql_runtime_vm_native_op_t *op = state->op;
  if (op->complete_code == GQL_VM_COMPLETE_LIST) {
    AV *in_av;
    AV *out_av;
    IV i;
    gql_runtime_vm_path_frame_t *saved_path_frame = state ? state->path_frame : NULL;
    gql_runtime_vm_path_frame_t *field_path = NULL;
    gql_runtime_vm_path_frame_t *base_path = NULL;
    int has_child_block = op->child_block_index >= 0;

    if (!value || !SvOK(value)) {
      return newSVsv(&PL_sv_undef);
    }
    if (!SvROK(value) || SvTYPE(SvRV(value)) != SVt_PVAV) {
      /* Non-list resolver result for a list field: field error + null,
       * matching the async lane (never croak the whole request). */
      SV *msg_sv = newSVpvs("list value must be an array reference");
      gql_runtime_vm_path_frame_t *error_path = state->path_frame_is_current_field
        ? state->path_frame
        : (field_path = gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, state->slot));
      gql_runtime_vm_fast_lane_record_error_for_path(aTHX_ state, msg_sv, error_path);
      SvREFCNT_dec(msg_sv);
      if (field_path) {
        gql_runtime_vm_path_frame_decref(field_path);
      }
      return newSVsv(&PL_sv_undef);
    }
    in_av = (AV *)SvRV(value);
    out_av = newAV();
    av_extend(out_av, av_count(in_av) > 0 ? av_count(in_av) - 1 : 0);
    if (has_child_block || op->abstract_child_count > 0) {
      /* Base the per-item index frames on the field frame; when the
       * dispatch loop already pushed it (eager path) reuse that frame
       * instead of stacking a duplicate segment. */
      if (!state->path_frame_is_current_field) {
        field_path = gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, state->slot);
        state->path_frame = field_path;
      }
      base_path = state->path_frame;
    }
    for (i = 0; i < (IV)av_count(in_av); i++) {
      SV **item_svp = av_fetch(in_av, i, 0);
      SV *item = (item_svp && SvOK(*item_svp)) ? *item_svp : &PL_sv_undef;
      SV *completed;
      SV *sel_error = NULL;
      gql_runtime_vm_path_frame_t *item_path = NULL;
      IV item_block_index;
      if (gql_runtime_vm_sv_is_promise_xs(aTHX_ item)) {
        /* Promise list item on the sync lane: complete it as null and
         * record the deferred croak; the top-level entry raises it after
         * cleanup. The item SV is borrowed from the resolver's array,
         * so no decref. */
        if (!state->fast_lane_deferred_croak_sv) {
          state->fast_lane_deferred_croak_sv =
            newSVpv(GQL_RUNTIME_VM_FAST_LANE_PROMISE_ERROR, 0);
        }
        item = &PL_sv_undef;
      }
      item_block_index = (has_child_block && SvOK(item)) ? op->child_block_index : -1;
      if (base_path) {
        SV *item_key = newSViv(i);
        item_path = gql_runtime_vm_new_path_frame_struct(aTHX_ base_path, item_key);
        SvREFCNT_dec(item_key);
        state->path_frame = item_path;
      }
      if (item_block_index < 0 && op->abstract_child_count > 0 && SvOK(item)) {
        /* List of an interface/union: pick the member block per item. */
        item_block_index = gql_runtime_vm_select_abstract_child_block_fast(
          aTHX_ state, item, &sel_error
        );
      }
      int item_had_error = 0;
      if (sel_error) {
        /* Unresolvable member type: field error + null item. */
        gql_runtime_vm_fast_lane_record_error_for_path(aTHX_ state, sel_error, item_path);
        SvREFCNT_dec(sel_error);
        completed = newSVsv(&PL_sv_undef);
        item_had_error = 1;
      } else if (item_block_index >= 0) {
        completed = gql_runtime_vm_execute_block_fast_sv(aTHX_ state, item_block_index, item);
        if (!completed) {
          /* The item block nulled itself (non-null propagation). */
          item_had_error = state->null_carries_error;
          state->null_carries_error = 0;
        }
      } else {
        /* Leaf list item: result coercion against the inner type
         * (slot->return_type_name is the list's inner name). Errors get
         * a lazily built field+index path since leaf lists skip the
         * per-item frames. */
        SV *leaf_error = NULL;
        completed = gql_runtime_vm_serialize_leaf_sv(
          aTHX_ state->runtime, state->slot, item, &leaf_error
        );
        if (leaf_error) {
          gql_runtime_vm_path_frame_t *error_path = item_path;
          gql_runtime_vm_path_frame_t *lazy_field = NULL;
          gql_runtime_vm_path_frame_t *lazy_item = NULL;
          if (!error_path) {
            SV *item_key = newSViv(i);
            lazy_field = state->path_frame_is_current_field
              ? NULL
              : gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, state->slot);
            lazy_item = gql_runtime_vm_new_path_frame_struct(
              aTHX_ lazy_field ? lazy_field : state->path_frame, item_key
            );
            SvREFCNT_dec(item_key);
            error_path = lazy_item;
          }
          gql_runtime_vm_fast_lane_record_error_for_path(aTHX_ state, leaf_error, error_path);
          SvREFCNT_dec(leaf_error);
          if (lazy_item) {
            gql_runtime_vm_path_frame_decref(lazy_item);
          }
          if (lazy_field) {
            gql_runtime_vm_path_frame_decref(lazy_field);
          }
          completed = newSVsv(&PL_sv_undef);
          item_had_error = 1;
        }
      }

      /* Non-Null list items ([T!]): a null item nulls the whole list
       * (spec 6.4.4); whether the null then travels further is the
       * enclosing field check's call (return_type_kind_code == 8). */
      if (state->slot->item_non_null && (!completed || !SvOK(completed))) {
        if (!item_had_error) {
          SV *msg_sv = newSVpvf(
            "Cannot return null for non-nullable field %s.%s.",
            state->block->type_name ? state->block->type_name : "(unknown)",
            state->slot->field_name ? state->slot->field_name : "(unknown)"
          );
          gql_runtime_vm_path_frame_t *error_path = item_path;
          gql_runtime_vm_path_frame_t *lazy_field = NULL;
          gql_runtime_vm_path_frame_t *lazy_item = NULL;
          if (!error_path) {
            SV *item_key = newSViv(i);
            lazy_field = state->path_frame_is_current_field
              ? NULL
              : gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, state->slot);
            lazy_item = gql_runtime_vm_new_path_frame_struct(
              aTHX_ lazy_field ? lazy_field : state->path_frame, item_key
            );
            SvREFCNT_dec(item_key);
            error_path = lazy_item;
          }
          gql_runtime_vm_fast_lane_record_error_for_path(aTHX_ state, msg_sv, error_path);
          SvREFCNT_dec(msg_sv);
          if (lazy_item) {
            gql_runtime_vm_path_frame_decref(lazy_item);
          }
          if (lazy_field) {
            gql_runtime_vm_path_frame_decref(lazy_field);
          }
        }
        if (completed) {
          SvREFCNT_dec(completed);
        }
        if (item_path) {
          state->path_frame = base_path;
          gql_runtime_vm_path_frame_decref(item_path);
        }
        if (field_path) {
          state->path_frame = saved_path_frame;
          gql_runtime_vm_path_frame_decref(field_path);
        }
        SvREFCNT_dec((SV *)out_av);
        state->null_carries_error = 1;
        return newSVsv(&PL_sv_undef);
      }
      if (!completed) {
        completed = newSVsv(&PL_sv_undef);
      }
      if (item_path) {
        state->path_frame = base_path;
        gql_runtime_vm_path_frame_decref(item_path);
      }
      av_store(out_av, i, completed);
    }
    if (field_path) {
      state->path_frame = saved_path_frame;
      gql_runtime_vm_path_frame_decref(field_path);
    }
    return newRV_noinc((SV *)out_av);
  }
  return gql_runtime_vm_clone_value_sv(aTHX_ value);
}

static SV *
gql_runtime_vm_execute_current_op_fast_sv(
  pTHX_
  gql_runtime_vm_exec_state_t *state,
  SV *source,
  SV **error_sv_out
)
{
  SV *resolved = NULL;
  SV *completed = NULL;
  SV *error_sv = NULL;
  IV dispatch_index = gql_runtime_vm_dispatch_index_from_opcode(state->op->opcode_code);

#if defined(__GNUC__) || defined(__clang__)
  static void *dispatch_table[] = {
    &&OP_DEFAULT_GENERIC,
    &&OP_DEFAULT_OBJECT,
    &&OP_DEFAULT_LIST,
    &&OP_DEFAULT_ABSTRACT,
    &&OP_EXPLICIT_GENERIC,
    &&OP_EXPLICIT_OBJECT,
    &&OP_EXPLICIT_LIST,
    &&OP_EXPLICIT_ABSTRACT
  };
#endif

  if (dispatch_index < 0) {
    croak("native VM opcode_code %ld is unsupported", (long)state->op->opcode_code);
  }

#if defined(__GNUC__) || defined(__clang__)
  goto *dispatch_table[dispatch_index];
OP_DEFAULT_GENERIC:
  resolved = gql_runtime_vm_resolve_current_field_default_fast_sv(aTHX_ state, source, &error_sv);
  if (error_sv) goto DISPATCH_ERROR;
  if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
    SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
    if (error_sv) goto DISPATCH_ERROR;
    SvREFCNT_dec(resolved);
    resolved = applied;
  }
  completed = gql_runtime_vm_complete_current_generic_fast_sv(aTHX_ state, resolved, &error_sv);
  goto DISPATCH_DONE;
OP_DEFAULT_OBJECT:
  resolved = gql_runtime_vm_resolve_current_field_default_fast_sv(aTHX_ state, source, &error_sv);
  if (error_sv) goto DISPATCH_ERROR;
  if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
    SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
    if (error_sv) goto DISPATCH_ERROR;
    SvREFCNT_dec(resolved);
    resolved = applied;
  }
  completed = gql_runtime_vm_complete_current_object_fast_sv(aTHX_ state, resolved);
  goto DISPATCH_DONE;
OP_DEFAULT_LIST:
  resolved = gql_runtime_vm_resolve_current_field_default_fast_sv(aTHX_ state, source, &error_sv);
  if (error_sv) goto DISPATCH_ERROR;
  if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
    SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
    if (error_sv) goto DISPATCH_ERROR;
    SvREFCNT_dec(resolved);
    resolved = applied;
  }
  completed = gql_runtime_vm_complete_current_list_fast_sv(aTHX_ state, resolved);
  goto DISPATCH_DONE;
OP_DEFAULT_ABSTRACT:
  resolved = gql_runtime_vm_resolve_current_field_default_fast_sv(aTHX_ state, source, &error_sv);
  if (error_sv) goto DISPATCH_ERROR;
  if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
    SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
    if (error_sv) goto DISPATCH_ERROR;
    SvREFCNT_dec(resolved);
    resolved = applied;
  }
  completed = gql_runtime_vm_complete_current_abstract_fast_sv(aTHX_ state, resolved, &error_sv);
  if (error_sv) goto DISPATCH_ERROR;
  goto DISPATCH_DONE;
OP_EXPLICIT_GENERIC:
  resolved = gql_runtime_vm_resolve_current_field_explicit_fast_sv(aTHX_ state, source, &error_sv);
  if (error_sv) goto DISPATCH_ERROR;
  if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
    SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
    if (error_sv) goto DISPATCH_ERROR;
    SvREFCNT_dec(resolved);
    resolved = applied;
  }
  completed = gql_runtime_vm_complete_current_generic_fast_sv(aTHX_ state, resolved, &error_sv);
  goto DISPATCH_DONE;
OP_EXPLICIT_OBJECT:
  resolved = gql_runtime_vm_resolve_current_field_explicit_fast_sv(aTHX_ state, source, &error_sv);
  if (error_sv) goto DISPATCH_ERROR;
  if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
    SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
    if (error_sv) goto DISPATCH_ERROR;
    SvREFCNT_dec(resolved);
    resolved = applied;
  }
  completed = gql_runtime_vm_complete_current_object_fast_sv(aTHX_ state, resolved);
  goto DISPATCH_DONE;
OP_EXPLICIT_LIST:
  resolved = gql_runtime_vm_resolve_current_field_explicit_fast_sv(aTHX_ state, source, &error_sv);
  if (error_sv) goto DISPATCH_ERROR;
  if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
    SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
    if (error_sv) goto DISPATCH_ERROR;
    SvREFCNT_dec(resolved);
    resolved = applied;
  }
  completed = gql_runtime_vm_complete_current_list_fast_sv(aTHX_ state, resolved);
  goto DISPATCH_DONE;
OP_EXPLICIT_ABSTRACT:
  resolved = gql_runtime_vm_resolve_current_field_explicit_fast_sv(aTHX_ state, source, &error_sv);
  if (error_sv) goto DISPATCH_ERROR;
  if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
    SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
    if (error_sv) goto DISPATCH_ERROR;
    SvREFCNT_dec(resolved);
    resolved = applied;
  }
  completed = gql_runtime_vm_complete_current_abstract_fast_sv(aTHX_ state, resolved, &error_sv);
  if (error_sv) goto DISPATCH_ERROR;
  goto DISPATCH_DONE;
DISPATCH_DONE:
#else
  switch (dispatch_index) {
    case 0:
      resolved = gql_runtime_vm_resolve_current_field_default_fast_sv(aTHX_ state, source, &error_sv);
      if (error_sv) break;
      if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
        SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
        if (error_sv) break;
        SvREFCNT_dec(resolved);
        resolved = applied;
      }
      completed = gql_runtime_vm_complete_current_generic_fast_sv(aTHX_ state, resolved, &error_sv);
      break;
    case 1:
      resolved = gql_runtime_vm_resolve_current_field_default_fast_sv(aTHX_ state, source, &error_sv);
      if (error_sv) break;
      if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
        SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
        if (error_sv) break;
        SvREFCNT_dec(resolved);
        resolved = applied;
      }
      completed = gql_runtime_vm_complete_current_object_fast_sv(aTHX_ state, resolved);
      break;
    case 2:
      resolved = gql_runtime_vm_resolve_current_field_default_fast_sv(aTHX_ state, source, &error_sv);
      if (error_sv) break;
      if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
        SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
        if (error_sv) break;
        SvREFCNT_dec(resolved);
        resolved = applied;
      }
      completed = gql_runtime_vm_complete_current_list_fast_sv(aTHX_ state, resolved);
      break;
    case 3:
      resolved = gql_runtime_vm_resolve_current_field_default_fast_sv(aTHX_ state, source, &error_sv);
      if (error_sv) break;
      if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
        SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
        if (error_sv) break;
        SvREFCNT_dec(resolved);
        resolved = applied;
      }
      completed = gql_runtime_vm_complete_current_abstract_fast_sv(aTHX_ state, resolved, &error_sv);
      break;
    case 4:
      resolved = gql_runtime_vm_resolve_current_field_explicit_fast_sv(aTHX_ state, source, &error_sv);
      if (error_sv) break;
      if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
        SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
        if (error_sv) break;
        SvREFCNT_dec(resolved);
        resolved = applied;
      }
      completed = gql_runtime_vm_complete_current_generic_fast_sv(aTHX_ state, resolved, &error_sv);
      break;
    case 5:
      resolved = gql_runtime_vm_resolve_current_field_explicit_fast_sv(aTHX_ state, source, &error_sv);
      if (error_sv) break;
      if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
        SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
        if (error_sv) break;
        SvREFCNT_dec(resolved);
        resolved = applied;
      }
      completed = gql_runtime_vm_complete_current_object_fast_sv(aTHX_ state, resolved);
      break;
    case 6:
      resolved = gql_runtime_vm_resolve_current_field_explicit_fast_sv(aTHX_ state, source, &error_sv);
      if (error_sv) break;
      if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
        SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
        if (error_sv) break;
        SvREFCNT_dec(resolved);
        resolved = applied;
      }
      completed = gql_runtime_vm_complete_current_list_fast_sv(aTHX_ state, resolved);
      break;
    case 7:
      resolved = gql_runtime_vm_resolve_current_field_explicit_fast_sv(aTHX_ state, source, &error_sv);
      if (error_sv) break;
      if (state->op->has_runtime_directives || state->op->runtime_directives_sv) {
        SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
        if (error_sv) break;
        SvREFCNT_dec(resolved);
        resolved = applied;
      }
      completed = gql_runtime_vm_complete_current_abstract_fast_sv(aTHX_ state, resolved, &error_sv);
      break;
  }
#endif

  if (resolved) {
    SvREFCNT_dec(resolved);
  }
  if (error_sv) {
    if (completed) {
      SvREFCNT_dec(completed);
    }
    if (error_sv_out) {
      *error_sv_out = error_sv;
      error_sv = NULL;
    }
    SvREFCNT_dec(error_sv);
    return NULL;
  }
  return completed ? completed : newSVsv(&PL_sv_undef);

#if defined(__GNUC__) || defined(__clang__)
DISPATCH_ERROR:
  if (resolved) {
    SvREFCNT_dec(resolved);
    resolved = NULL;
  }
  if (completed) {
    SvREFCNT_dec(completed);
    completed = NULL;
  }
  if (error_sv) {
    if (error_sv_out) {
      *error_sv_out = error_sv;
      error_sv = NULL;
    }
    SvREFCNT_dec(error_sv);
  }
  return NULL;
#endif
}

static SV *
gql_runtime_vm_execute_block_fast_sv(pTHX_ gql_runtime_vm_exec_state_t *state, IV block_index, SV *source)
{
  gql_runtime_vm_native_block_t *block;
  HV *data_hv;
  IV i;
  gql_runtime_vm_native_block_t *saved_block = (gql_runtime_vm_native_block_t *)state->block;
  const gql_runtime_vm_native_op_t *saved_op = state->op;
  const gql_runtime_vm_native_slot_t *saved_slot = state->slot;
  gql_runtime_vm_path_frame_t *saved_path_frame = state->path_frame;
  int saved_path_is_current_field = state->path_frame_is_current_field;
  IV saved_block_index = state->block_index;
  IV saved_op_index = state->op_index;

  if (!state->bundle || block_index < 0 || block_index >= state->bundle->block_count) {
    croak("native VM block index %ld is invalid", (long)block_index);
  }

  block = &state->bundle->blocks[block_index];
  state->block = block;
  state->block_index = block_index;
  data_hv = newHV();

  for (i = 0; i < block->op_count; i++) {
    gql_runtime_vm_native_op_t *op = &block->ops[i];
    gql_runtime_vm_native_slot_t *slot;
    SV *completed;
    SV *error_sv = NULL;
    gql_runtime_vm_outcome_t *error_outcome = NULL;
    gql_runtime_vm_path_frame_t *field_path = NULL;
    int eager_path_frame;

    if (op->slot_index < 0 || op->slot_index >= block->slot_count) {
      croak("native VM op slot_index %ld is invalid in block %ld", (long)op->slot_index, (long)block_index);
    }
    slot = &block->slots[op->slot_index];
    state->op = op;
    state->slot = slot;
    state->op_index = i;

    eager_path_frame = !gql_runtime_vm_slot_can_delay_field_path(state->runtime, slot, op);

    if (eager_path_frame) {
      field_path = gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, slot);
      state->path_frame = field_path;
      state->path_frame_is_current_field = 1;
    } else {
      state->path_frame = saved_path_frame;
      state->path_frame_is_current_field = 0;
    }

    completed = gql_runtime_vm_execute_current_op_fast_sv(aTHX_ state, source, &error_sv);
    state->path_frame = saved_path_frame;
    state->path_frame_is_current_field = saved_path_is_current_field;

    if (!eager_path_frame && error_sv) {
      field_path = gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, slot);
      error_outcome = gql_runtime_vm_new_error_outcome_struct_for_path(aTHX_ error_sv, field_path);
      SvREFCNT_dec(error_sv);
      error_sv = NULL;
    } else if (error_sv) {
      error_outcome = gql_runtime_vm_new_error_outcome_struct_for_path(aTHX_ error_sv, field_path);
      SvREFCNT_dec(error_sv);
      error_sv = NULL;
    }

    if (error_outcome) {
      if (state->writer) {
        IV j;
        for (j = 0; j < error_outcome->error_record_count; j++) {
          gql_runtime_vm_writer_push_error_record(state->writer, error_outcome->error_records[j]);
        }
      }
      gql_runtime_vm_outcome_decref(aTHX_ error_outcome);
      error_outcome = NULL;
      completed = newSVsv(&PL_sv_undef);
      /* The null below carries this field error. */
      state->null_carries_error = 1;
    }

    /* Non-Null propagation (spec 6.4.4): a null in a non-null position
     * nulls this block. Add the "Cannot return null" error only when the
     * null did not already come with one (a field error above, or a
     * propagated child null). */
    if ((!completed || !SvOK(completed)) && slot->return_type_kind_code == 8) {
      if (!state->null_carries_error) {
        SV *msg_sv = newSVpvf(
          "Cannot return null for non-nullable field %s.%s.",
          block->type_name ? block->type_name : "(unknown)",
          slot->field_name ? slot->field_name : "(unknown)"
        );
        gql_runtime_vm_path_frame_t *error_path = field_path
          ? field_path
          : gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, slot);
        gql_runtime_vm_fast_lane_record_error_for_path(aTHX_ state, msg_sv, error_path);
        SvREFCNT_dec(msg_sv);
        if (error_path != field_path) {
          gql_runtime_vm_path_frame_decref(error_path);
        }
      }
      if (field_path) {
        gql_runtime_vm_path_frame_decref(field_path);
      }
      if (completed) {
        SvREFCNT_dec(completed);
      }
      SvREFCNT_dec((SV *)data_hv);
      state->block = saved_block;
      state->op = saved_op;
      state->slot = saved_slot;
      state->path_frame = saved_path_frame;
      state->path_frame_is_current_field = saved_path_is_current_field;
      state->block_index = saved_block_index;
      state->op_index = saved_op_index;
      state->null_carries_error = 1;
      return NULL;
    }
    state->null_carries_error = 0;

    if (field_path) {
      gql_runtime_vm_path_frame_decref(field_path);
      field_path = NULL;
    }
    if (!completed) {
      completed = newSVsv(&PL_sv_undef);
    }
    hv_store(data_hv, slot->result_name, (I32)slot->result_name_len, completed, 0);
  }

  state->block = saved_block;
  state->op = saved_op;
  state->slot = saved_slot;
  state->path_frame = saved_path_frame;
  state->path_frame_is_current_field = saved_path_is_current_field;
  state->block_index = saved_block_index;
  state->op_index = saved_op_index;

  return newRV_noinc((SV *)data_hv);
}

/*
 * Direct-JSON variant of the sync fast lane. Instead of materializing the
 * response as Perl hashes/arrays and encoding afterwards, the block loop
 * appends JSON bytes straight into an output SV. Field order follows op
 * order, i.e. the query's field order. Output is UTF-8 encoded octets.
 */

static int gql_runtime_vm_execute_block_fast_json(pTHX_ gql_runtime_vm_exec_state_t *state, IV block_index, SV *source, SV *out);

static void
gql_runtime_vm_json_cat_string(pTHX_ SV *out, const char *pv, STRLEN len)
{
  STRLEN i;
  STRLEN run_start = 0;

  sv_catpvs(out, "\"");
  for (i = 0; i < len; i++) {
    const unsigned char c = (unsigned char)pv[i];
    const char *escape = NULL;
    char ubuf[8];

    switch (c) {
      case '"': escape = "\\\""; break;
      case '\\': escape = "\\\\"; break;
      case '\b': escape = "\\b"; break;
      case '\f': escape = "\\f"; break;
      case '\n': escape = "\\n"; break;
      case '\r': escape = "\\r"; break;
      case '\t': escape = "\\t"; break;
      default:
        if (c < 0x20) {
          my_snprintf(ubuf, sizeof(ubuf), "\\u%04x", (unsigned int)c);
          escape = ubuf;
        }
        break;
    }
    if (escape) {
      if (i > run_start) {
        sv_catpvn(out, pv + run_start, i - run_start);
      }
      sv_catpv(out, escape);
      run_start = i + 1;
    }
  }
  if (len > run_start) {
    sv_catpvn(out, pv + run_start, len - run_start);
  }
  sv_catpvs(out, "\"");
}

static void
gql_runtime_vm_json_cat_scalar(pTHX_ gql_runtime_vm_exec_state_t *state, SV *out, SV *value)
{
  if (!value || !SvOK(value)) {
    sv_catpvs(out, "null");
    return;
  }
  if (SvROK(value)) {
    SV *inner = SvRV(value);
    if (sv_isobject(value)
        && (sv_derived_from(value, "JSON::PP::Boolean")
          || sv_derived_from(value, "Types::Serialiser::Boolean"))) {
      sv_catpv(out, SvTRUE(inner) ? "true" : "false");
      return;
    }
    if (!SvOBJECT(inner) && SvIOK(inner) && (SvIV(inner) == 0 || SvIV(inner) == 1)) {
      /* \0 / \1 boolean convention */
      sv_catpv(out, SvIV(inner) ? "true" : "false");
      return;
    }
    if (sv_isobject(value) && sv_derived_from(value, "Promise::XS::Promise")) {
      /* A promise that slipped past the resolve/item guards (e.g. inside
       * a source hash). On the fast lanes, defer the croak so the live
       * path frame chain unwinds; the native-value writer (async tail,
       * state == NULL) never sees promises, so croaking there is safe. */
      if (state) {
        if (!state->fast_lane_deferred_croak_sv) {
          state->fast_lane_deferred_croak_sv =
            newSVpv(GQL_RUNTIME_VM_FAST_LANE_PROMISE_ERROR, 0);
        }
        sv_catpvs(out, "null");
        return;
      }
      croak("%s", GQL_RUNTIME_VM_FAST_LANE_PROMISE_ERROR);
    }
    /* Unexpected reference in a leaf position: stringify. */
    {
      STRLEN len;
      const char *pv = SvPVutf8(value, len);
      gql_runtime_vm_json_cat_string(aTHX_ out, pv, len);
    }
    return;
  }
  if (SvPOKp(value) && !SvIOKp(value) && !SvNOKp(value)) {
    STRLEN len;
    const char *pv = SvPVutf8(value, len);
    gql_runtime_vm_json_cat_string(aTHX_ out, pv, len);
    return;
  }
  if (SvIOKp(value)) {
    if (SvIsUV(value)) {
      sv_catpvf(out, "%" UVuf, (UV)SvUV(value));
    } else {
      sv_catpvf(out, "%" IVdf, (IV)SvIV(value));
    }
    return;
  }
  if (SvNOKp(value)) {
    NV nv = SvNV(value);
    if (Perl_isnan(nv) || Perl_isinf(nv)) {
      sv_catpvs(out, "null");
      return;
    }
    {
      char nbuf[NV_DIG + 32];
      Gconvert(nv, NV_DIG, 0, nbuf);
      sv_catpv(out, nbuf);
    }
    return;
  }
  {
    STRLEN len;
    const char *pv = SvPVutf8(value, len);
    gql_runtime_vm_json_cat_string(aTHX_ out, pv, len);
  }
}

/* Returns 1 when the block nulled itself over a non-null violation; the
 * callee has already truncated its own bytes from `out` and the caller
 * writes "null" or keeps propagating. */
static int
gql_runtime_vm_execute_child_block_fast_json(
  pTHX_
  gql_runtime_vm_exec_state_t *state,
  IV block_index,
  SV *source,
  SV *out
)
{
  gql_runtime_vm_path_frame_t *saved_path_frame = state ? state->path_frame : NULL;
  int saved_path_is_current_field = state ? state->path_frame_is_current_field : 0;
  gql_runtime_vm_path_frame_t *field_path;
  int propagated;

  if (!state) {
    sv_catpvs(out, "null");
    return 0;
  }

  if (state->path_frame_is_current_field) {
    field_path = NULL;
  } else {
    field_path = gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, state->slot);
    state->path_frame = field_path;
    state->path_frame_is_current_field = 1;
  }
  propagated = gql_runtime_vm_execute_block_fast_json(aTHX_ state, block_index, source, out);
  state->path_frame = saved_path_frame;
  state->path_frame_is_current_field = saved_path_is_current_field;
  if (field_path) {
    gql_runtime_vm_path_frame_decref(field_path);
  }
  return propagated;
}

/* Returns 1 when a non-null list item ([T!]) was null: the list's bytes
 * are truncated from `out` and the caller emits null / propagates. */
static int
gql_runtime_vm_complete_current_list_fast_json(
  pTHX_
  gql_runtime_vm_exec_state_t *state,
  SV *value,
  SV *out
)
{
  const gql_runtime_vm_native_op_t *op = state->op;

  if (op->complete_code != GQL_VM_COMPLETE_LIST) {
    gql_runtime_vm_json_cat_scalar(aTHX_ state, out, value);
    return 0;
  }
  if (!value || !SvOK(value)) {
    sv_catpvs(out, "null");
    return 0;
  }
  if (!SvROK(value) || SvTYPE(SvRV(value)) != SVt_PVAV) {
    /* Non-list resolver result for a list field: field error + null,
     * matching the async lane (never croak the whole request). */
    gql_runtime_vm_path_frame_t *field_path = NULL;
    gql_runtime_vm_path_frame_t *error_path;
    SV *msg_sv = newSVpvs("list value must be an array reference");
    error_path = state->path_frame_is_current_field
      ? state->path_frame
      : (field_path = gql_runtime_vm_new_result_path_frame(aTHX_ state->path_frame, state->slot));
    gql_runtime_vm_fast_lane_record_error_for_path(aTHX_ state, msg_sv, error_path);
    SvREFCNT_dec(msg_sv);
    if (field_path) {
      gql_runtime_vm_path_frame_decref(field_path);
    }
    sv_catpvs(out, "null");
    state->null_carries_error = 1;
    return 0;
  }
  {
    AV *in_av = (AV *)SvRV(value);
    gql_runtime_vm_path_frame_t *saved_path_frame = state ? state->path_frame : NULL;
    gql_runtime_vm_path_frame_t *field_path = NULL;
    gql_runtime_vm_path_frame_t *base_path = NULL;
    int has_child_block = op->child_block_index >= 0;
    int has_abstract_items = (!has_child_block && op->abstract_child_count > 0);
    STRLEN list_start = SvCUR(out);
    IV i;

    if (has_child_block || has_abstract_items) {
      /* Base the per-item index frames on the field frame; when the
       * dispatch loop already pushed it (eager path) reuse that frame
       * instead of stacking a duplicate segment. */
      if (!state->path_frame_is_current_field) {
        field_path = gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, state->slot);
        state->path_frame = field_path;
      }
      base_path = state->path_frame;
    }
    sv_catpvs(out, "[");
    for (i = 0; i < (IV)av_count(in_av); i++) {
      SV **item_svp = av_fetch(in_av, i, 0);
      SV *item = (item_svp && SvOK(*item_svp)) ? *item_svp : &PL_sv_undef;
      gql_runtime_vm_path_frame_t *item_path = NULL;
      STRLEN item_start;
      int item_had_error = 0;
      if (i) {
        sv_catpvs(out, ",");
      }
      item_start = SvCUR(out);
      if (gql_runtime_vm_sv_is_promise_xs(aTHX_ item)) {
        /* Promise list item on the sync lane: complete it as null and
         * record the deferred croak; the top-level entry raises it after
         * cleanup. The item SV is borrowed from the resolver's array,
         * so no decref. */
        if (!state->fast_lane_deferred_croak_sv) {
          state->fast_lane_deferred_croak_sv =
            newSVpv(GQL_RUNTIME_VM_FAST_LANE_PROMISE_ERROR, 0);
        }
        item = &PL_sv_undef;
      }
      if (base_path) {
        SV *item_key = newSViv(i);
        item_path = gql_runtime_vm_new_path_frame_struct(aTHX_ base_path, item_key);
        SvREFCNT_dec(item_key);
        state->path_frame = item_path;
      }
      if (has_abstract_items && SvOK(item)) {
        /* List of an interface/union: pick the member block per item. */
        SV *sel_error = NULL;
        IV item_block_index = gql_runtime_vm_select_abstract_child_block_fast(
          aTHX_ state, item, &sel_error
        );
        if (sel_error) {
          /* Unresolvable member type: field error + null item. */
          gql_runtime_vm_fast_lane_record_error_for_path(aTHX_ state, sel_error, item_path);
          SvREFCNT_dec(sel_error);
          sv_catpvs(out, "null");
          item_had_error = 1;
        } else if (item_block_index >= 0) {
          if (gql_runtime_vm_execute_block_fast_json(aTHX_ state, item_block_index, item, out)) {
            sv_catpvs(out, "null");
            item_had_error = 1;
          }
        } else {
          sv_catpvs(out, "null");
        }
      } else if (has_abstract_items) {
        sv_catpvs(out, "null");
      } else if (has_child_block && SvOK(item)) {
        if (gql_runtime_vm_execute_block_fast_json(aTHX_ state, op->child_block_index, item, out)) {
          sv_catpvs(out, "null");
          item_had_error = 1;
        }
      } else if (has_child_block) {
        sv_catpvs(out, "null");
      } else {
        /* Leaf list item: result coercion against the inner type before
         * serialization; a failure is a per-item field error + null. */
        SV *leaf_error = NULL;
        SV *serialized = gql_runtime_vm_serialize_leaf_sv(
          aTHX_ state->runtime, state->slot, item, &leaf_error
        );
        if (leaf_error) {
          gql_runtime_vm_path_frame_t *error_path = item_path;
          gql_runtime_vm_path_frame_t *lazy_field = NULL;
          gql_runtime_vm_path_frame_t *lazy_item = NULL;
          if (!error_path) {
            SV *item_key = newSViv(i);
            lazy_field = state->path_frame_is_current_field
              ? NULL
              : gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, state->slot);
            lazy_item = gql_runtime_vm_new_path_frame_struct(
              aTHX_ lazy_field ? lazy_field : state->path_frame, item_key
            );
            SvREFCNT_dec(item_key);
            error_path = lazy_item;
          }
          gql_runtime_vm_fast_lane_record_error_for_path(aTHX_ state, leaf_error, error_path);
          SvREFCNT_dec(leaf_error);
          if (lazy_item) {
            gql_runtime_vm_path_frame_decref(lazy_item);
          }
          if (lazy_field) {
            gql_runtime_vm_path_frame_decref(lazy_field);
          }
          sv_catpvs(out, "null");
          item_had_error = 1;
        } else if (SvOK(serialized) && !SvROK(serialized)
            && state->slot && state->slot->return_type_name
            && strEQ(state->slot->return_type_name, "Boolean")) {
          sv_catpv(out, SvTRUE(serialized) ? "true" : "false");
        } else {
          gql_runtime_vm_json_cat_scalar(aTHX_ state, out, serialized);
        }
        if (serialized) {
          SvREFCNT_dec(serialized);
        }
      }

      /* Non-Null list items ([T!]): a null item nulls the whole list. */
      if (state->slot->item_non_null
          && SvCUR(out) - item_start == 4
          && memEQ(SvPVX(out) + item_start, "null", 4)) {
        if (!item_had_error && !state->null_carries_error) {
          SV *msg_sv = newSVpvf(
            "Cannot return null for non-nullable field %s.%s.",
            state->block->type_name ? state->block->type_name : "(unknown)",
            state->slot->field_name ? state->slot->field_name : "(unknown)"
          );
          gql_runtime_vm_path_frame_t *error_path = item_path;
          gql_runtime_vm_path_frame_t *lazy_field = NULL;
          gql_runtime_vm_path_frame_t *lazy_item = NULL;
          if (!error_path) {
            SV *item_key = newSViv(i);
            lazy_field = state->path_frame_is_current_field
              ? NULL
              : gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, state->slot);
            lazy_item = gql_runtime_vm_new_path_frame_struct(
              aTHX_ lazy_field ? lazy_field : state->path_frame, item_key
            );
            SvREFCNT_dec(item_key);
            error_path = lazy_item;
          }
          gql_runtime_vm_fast_lane_record_error_for_path(aTHX_ state, msg_sv, error_path);
          SvREFCNT_dec(msg_sv);
          if (lazy_item) {
            gql_runtime_vm_path_frame_decref(lazy_item);
          }
          if (lazy_field) {
            gql_runtime_vm_path_frame_decref(lazy_field);
          }
        }
        if (item_path) {
          state->path_frame = base_path;
          gql_runtime_vm_path_frame_decref(item_path);
        }
        if (field_path) {
          state->path_frame = saved_path_frame;
          gql_runtime_vm_path_frame_decref(field_path);
        }
        SvCUR_set(out, list_start);
        state->null_carries_error = 1;
        return 1;
      }
      state->null_carries_error = 0;
      if (item_path) {
        state->path_frame = base_path;
        gql_runtime_vm_path_frame_decref(item_path);
      }
    }
    sv_catpvs(out, "]");
    if (field_path) {
      state->path_frame = saved_path_frame;
      gql_runtime_vm_path_frame_decref(field_path);
    }
  }
  return 0;
}

static int
gql_runtime_vm_execute_block_fast_json(pTHX_ gql_runtime_vm_exec_state_t *state, IV block_index, SV *source, SV *out)
{
  gql_runtime_vm_native_block_t *block;
  IV i;
  STRLEN block_start = SvCUR(out);
  gql_runtime_vm_native_block_t *saved_block = (gql_runtime_vm_native_block_t *)state->block;
  const gql_runtime_vm_native_op_t *saved_op = state->op;
  const gql_runtime_vm_native_slot_t *saved_slot = state->slot;
  gql_runtime_vm_path_frame_t *saved_path_frame = state->path_frame;
  int saved_path_is_current_field = state->path_frame_is_current_field;
  IV saved_block_index = state->block_index;
  IV saved_op_index = state->op_index;

  if (!state->bundle || block_index < 0 || block_index >= state->bundle->block_count) {
    croak("native VM block index %ld is invalid", (long)block_index);
  }

  block = &state->bundle->blocks[block_index];
  state->block = block;
  state->block_index = block_index;
  sv_catpvs(out, "{");

  for (i = 0; i < block->op_count; i++) {
    gql_runtime_vm_native_op_t *op = &block->ops[i];
    gql_runtime_vm_native_slot_t *slot;
    SV *resolved = NULL;
    SV *error_sv = NULL;
    gql_runtime_vm_outcome_t *error_outcome = NULL;
    gql_runtime_vm_path_frame_t *field_path = NULL;
    int eager_path_frame;
    IV dispatch_index;
    IV family;
    STRLEN value_start;

    if (op->slot_index < 0 || op->slot_index >= block->slot_count) {
      croak("native VM op slot_index %ld is invalid in block %ld", (long)op->slot_index, (long)block_index);
    }
    slot = &block->slots[op->slot_index];
    state->op = op;
    state->slot = slot;
    state->op_index = i;

    dispatch_index = gql_runtime_vm_dispatch_index_from_opcode(op->opcode_code);
    if (dispatch_index < 0) {
      croak("native VM opcode_code %ld is unsupported", (long)op->opcode_code);
    }
    family = dispatch_index % 4;

    if (i) {
      sv_catpvs(out, ",");
    }
    sv_catpvs(out, "\"");
    sv_catpvn(out, slot->result_name, slot->result_name_len);
    sv_catpvs(out, "\":");
    value_start = SvCUR(out);

    eager_path_frame = !gql_runtime_vm_slot_can_delay_field_path(state->runtime, slot, op);
    if (eager_path_frame) {
      field_path = gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, slot);
      state->path_frame = field_path;
      state->path_frame_is_current_field = 1;
    } else {
      state->path_frame = saved_path_frame;
      state->path_frame_is_current_field = 0;
    }

    resolved = (dispatch_index >= 4)
      ? gql_runtime_vm_resolve_current_field_explicit_fast_sv(aTHX_ state, source, &error_sv)
      : gql_runtime_vm_resolve_current_field_default_fast_sv(aTHX_ state, source, &error_sv);
    if (!error_sv && (op->has_runtime_directives || op->runtime_directives_sv)) {
      SV *applied = gql_runtime_vm_apply_runtime_directives_nonfatal(aTHX_ state, source, resolved, &error_sv);
      if (!error_sv) {
        SvREFCNT_dec(resolved);
        resolved = applied;
      } else if (applied) {
        SvREFCNT_dec(applied);
      }
    }

    if (!error_sv) {
      switch (family) {
        case 0: /* GENERIC */
        {
          /* Leaf result coercion before serialization; a failure becomes
           * a field error + null via the shared error_sv tail. */
          SV *serialized = gql_runtime_vm_serialize_leaf_sv(
            aTHX_ state->runtime, slot, resolved, &error_sv
          );
          if (error_sv) {
            /* The shared error tail records the field error and emits the
             * null for this field. */
            break;
          }
          if (serialized && SvOK(serialized) && !SvROK(serialized)
              && slot->return_type_name && strEQ(slot->return_type_name, "Boolean")) {
            /* Boolean-typed leaves serialize as JSON booleans even when the
             * resolver returned a plain 0/1. */
            sv_catpv(out, SvTRUE(serialized) ? "true" : "false");
          } else {
            gql_runtime_vm_json_cat_scalar(aTHX_ state, out, serialized);
          }
          SvREFCNT_dec(serialized);
          break;
        }
        case 1: /* OBJECT */
          if (resolved && SvOK(resolved) && op->complete_code == GQL_VM_COMPLETE_OBJECT && op->child_block_index >= 0) {
            if (gql_runtime_vm_execute_child_block_fast_json(aTHX_ state, op->child_block_index, resolved, out)) {
              sv_catpvs(out, "null");
            }
          } else if (resolved && SvOK(resolved)) {
            gql_runtime_vm_json_cat_scalar(aTHX_ state, out, resolved);
          } else {
            sv_catpvs(out, "null");
          }
          break;
        case 2: /* LIST */
          if (gql_runtime_vm_complete_current_list_fast_json(aTHX_ state, resolved, out)) {
            sv_catpvs(out, "null");
          }
          break;
        case 3: /* ABSTRACT */
        default:
          if (!resolved || !SvOK(resolved)) {
            sv_catpvs(out, "null");
          } else {
            IV abstract_child_block_index = gql_runtime_vm_select_abstract_child_block_fast(
              aTHX_ state, resolved, &error_sv
            );
            if (!error_sv) {
              if (abstract_child_block_index >= 0) {
                if (gql_runtime_vm_execute_child_block_fast_json(aTHX_ state, abstract_child_block_index, resolved, out)) {
                  sv_catpvs(out, "null");
                }
              } else {
                sv_catpvs(out, "null");
              }
            }
          }
          break;
      }
    }

    state->path_frame = saved_path_frame;
    state->path_frame_is_current_field = saved_path_is_current_field;

    if (error_sv) {
      if (!eager_path_frame && !field_path) {
        field_path = gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, slot);
      }
      error_outcome = gql_runtime_vm_new_error_outcome_struct_for_path(aTHX_ error_sv, field_path);
      SvREFCNT_dec(error_sv);
      error_sv = NULL;
    }
    if (error_outcome) {
      if (state->writer) {
        IV j;
        for (j = 0; j < error_outcome->error_record_count; j++) {
          gql_runtime_vm_writer_push_error_record(state->writer, error_outcome->error_records[j]);
        }
      }
      gql_runtime_vm_outcome_decref(aTHX_ error_outcome);
      error_outcome = NULL;
      sv_catpvs(out, "null");
      /* The null just emitted carries this field error. */
      state->null_carries_error = 1;
    }
    if (resolved) {
      SvREFCNT_dec(resolved);
      resolved = NULL;
    }

    /* Non-Null propagation (spec 6.4.4): a null value in a non-null
     * position nulls this block. The emitted value region being exactly
     * the token "null" identifies a null field value. */
    if (slot->return_type_kind_code == 8
        && SvCUR(out) - value_start == 4
        && memEQ(SvPVX(out) + value_start, "null", 4)) {
      if (!state->null_carries_error) {
        SV *msg_sv = newSVpvf(
          "Cannot return null for non-nullable field %s.%s.",
          block->type_name ? block->type_name : "(unknown)",
          slot->field_name ? slot->field_name : "(unknown)"
        );
        gql_runtime_vm_path_frame_t *error_path = field_path
          ? field_path
          : gql_runtime_vm_new_result_path_frame(aTHX_ saved_path_frame, slot);
        gql_runtime_vm_fast_lane_record_error_for_path(aTHX_ state, msg_sv, error_path);
        SvREFCNT_dec(msg_sv);
        if (error_path != field_path) {
          gql_runtime_vm_path_frame_decref(error_path);
        }
      }
      if (field_path) {
        gql_runtime_vm_path_frame_decref(field_path);
      }
      SvCUR_set(out, block_start);
      state->block = saved_block;
      state->op = saved_op;
      state->slot = saved_slot;
      state->path_frame = saved_path_frame;
      state->path_frame_is_current_field = saved_path_is_current_field;
      state->block_index = saved_block_index;
      state->op_index = saved_op_index;
      state->null_carries_error = 1;
      return 1;
    }
    state->null_carries_error = 0;

    if (field_path) {
      gql_runtime_vm_path_frame_decref(field_path);
      field_path = NULL;
    }
  }

  sv_catpvs(out, "}");

  state->block = saved_block;
  state->op = saved_op;
  state->slot = saved_slot;
  state->path_frame = saved_path_frame;
  state->path_frame_is_current_field = saved_path_is_current_field;
  state->block_index = saved_block_index;
  state->op_index = saved_op_index;
  return 0;
}

static void
gql_runtime_vm_json_cat_errors(pTHX_ SV *out, const gql_runtime_vm_writer_t *writer)
{
  IV i;

  sv_catpvs(out, "[");
  for (i = 0; writer && i < writer->error_record_count; i++) {
    const gql_runtime_vm_error_record_t *record = writer->error_records[i];
    if (i) {
      sv_catpvs(out, ",");
    }
    sv_catpvs(out, "{\"message\":");
    if (record && record->message_pv) {
      gql_runtime_vm_json_cat_string(aTHX_ out, record->message_pv, strlen(record->message_pv));
    } else {
      sv_catpvs(out, "null");
    }
    if (record && record->path_frame) {
      SV *path_sv = gql_runtime_vm_path_frame_to_path_sv(aTHX_ record->path_frame);
      if (path_sv && SvOK(path_sv) && SvROK(path_sv) && SvTYPE(SvRV(path_sv)) == SVt_PVAV
          && av_count((AV *)SvRV(path_sv)) > 0) {
        AV *path_av = (AV *)SvRV(path_sv);
        IV j;
        sv_catpvs(out, ",\"path\":[");
        for (j = 0; j < (IV)av_count(path_av); j++) {
          SV **item_svp = av_fetch(path_av, j, 0);
          if (j) {
            sv_catpvs(out, ",");
          }
          gql_runtime_vm_json_cat_scalar(aTHX_ NULL, out, item_svp ? *item_svp : NULL);
        }
        sv_catpvs(out, "]");
      }
      if (path_sv) {
        SvREFCNT_dec(path_sv);
      }
    }
    sv_catpvs(out, "}");
  }
  sv_catpvs(out, "]");
}

/*
 * Async direct-JSON tail: serialize a completed native value tree (the
 * response frame's values at resolve time) straight to JSON bytes. The
 * native tree preserves insertion order, so sync-resolved fields appear
 * first and late-resolved fields follow in completion order (JSON object
 * member order carries no meaning). Scalars carry no GraphQL type info, so
 * Boolean-typed leaves render as the resolver returned them (0/1),
 * matching execute() + JSON encode of the async envelope.
 */
static void
gql_runtime_vm_native_value_cat_json(pTHX_ SV *out, const gql_runtime_vm_native_value_t *value)
{
  IV i;

  if (!value) {
    sv_catpvs(out, "null");
    return;
  }
  switch (value->kind_code) {
    case GQL_VM_NATIVE_VALUE_OBJECT:
      sv_catpvs(out, "{");
      for (i = 0; i < value->object.count; i++) {
        if (i) {
          sv_catpvs(out, ",");
        }
        gql_runtime_vm_json_cat_string(
          aTHX_ out,
          value->object.names[i] ? value->object.names[i] : "",
          value->object.names[i] ? strlen(value->object.names[i]) : 0
        );
        sv_catpvs(out, ":");
        gql_runtime_vm_native_value_cat_json(aTHX_ out, value->object.values[i]);
      }
      sv_catpvs(out, "}");
      return;
    case GQL_VM_NATIVE_VALUE_LIST:
      sv_catpvs(out, "[");
      for (i = 0; i < value->list.count; i++) {
        if (i) {
          sv_catpvs(out, ",");
        }
        gql_runtime_vm_native_value_cat_json(aTHX_ out, value->list.items[i]);
      }
      sv_catpvs(out, "]");
      return;
    case GQL_VM_NATIVE_VALUE_SCALAR:
    default:
      switch (value->scalar_kind_code) {
        case GQL_VM_NATIVE_SCALAR_UNDEF:
          sv_catpvs(out, "null");
          return;
        case GQL_VM_NATIVE_SCALAR_IV:
          sv_catpvf(out, "%" IVdf, value->scalar_iv);
          return;
        case GQL_VM_NATIVE_SCALAR_NV:
          if (Perl_isnan(value->scalar_nv) || Perl_isinf(value->scalar_nv)) {
            sv_catpvs(out, "null");
          } else {
            char nbuf[NV_DIG + 32];
            Gconvert(value->scalar_nv, NV_DIG, 0, nbuf);
            sv_catpv(out, nbuf);
          }
          return;
        case GQL_VM_NATIVE_SCALAR_PV:
          gql_runtime_vm_json_cat_string(
            aTHX_ out,
            value->scalar_pv ? value->scalar_pv : "",
            value->scalar_pv_len
          );
          return;
        case GQL_VM_NATIVE_SCALAR_FALLBACK_SV:
        default:
          gql_runtime_vm_json_cat_scalar(aTHX_ NULL, out, value->scalar_fallback_sv);
          return;
      }
  }
}

/* Materialized SV data (hash key order is not preserved, matching the
 * envelope execute() returns for the same request). */
static void
gql_runtime_vm_json_cat_sv_data(pTHX_ SV *out, SV *value)
{
  if (value && SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVHV && !SvOBJECT(SvRV(value))) {
    HV *hv = (HV *)SvRV(value);
    HE *he;
    int first = 1;

    sv_catpvs(out, "{");
    hv_iterinit(hv);
    while ((he = hv_iternext(hv)) != NULL) {
      SV *key_sv = hv_iterkeysv(he);
      STRLEN key_len = 0;
      const char *key_pv = SvPVutf8(key_sv, key_len);

      if (!first) {
        sv_catpvs(out, ",");
      }
      first = 0;
      gql_runtime_vm_json_cat_string(aTHX_ out, key_pv, key_len);
      sv_catpvs(out, ":");
      gql_runtime_vm_json_cat_sv_data(aTHX_ out, hv_iterval(hv, he));
    }
    sv_catpvs(out, "}");
    return;
  }
  if (value && SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVAV && !SvOBJECT(SvRV(value))) {
    AV *av = (AV *)SvRV(value);
    SSize_t i;

    sv_catpvs(out, "[");
    for (i = 0; i < (IV)av_count(av); i++) {
      SV **svp = av_fetch(av, i, 0);
      if (i) {
        sv_catpvs(out, ",");
      }
      gql_runtime_vm_json_cat_sv_data(aTHX_ out, (svp && *svp) ? *svp : NULL);
    }
    sv_catpvs(out, "]");
    return;
  }
  gql_runtime_vm_json_cat_scalar(aTHX_ NULL, out, value);
}

static SV *
gql_runtime_vm_response_json_from_native_sv(pTHX_ const gql_runtime_vm_writer_t *writer, const gql_runtime_vm_native_value_t *value)
{
  SV *out = newSV(1024);

  sv_setpvs(out, "{\"data\":");
  gql_runtime_vm_native_value_cat_json(aTHX_ out, value);
  if (writer && writer->error_record_count > 0) {
    sv_catpvs(out, ",\"errors\":");
    gql_runtime_vm_json_cat_errors(aTHX_ out, writer);
  }
  sv_catpvs(out, "}");
  return out;
}

static SV *
gql_runtime_vm_response_json_from_data_sv(pTHX_ const gql_runtime_vm_writer_t *writer, SV *data_sv)
{
  SV *out = newSV(1024);

  sv_setpvs(out, "{\"data\":");
  gql_runtime_vm_json_cat_sv_data(aTHX_ out, data_sv);
  if (writer && writer->error_record_count > 0) {
    sv_catpvs(out, ",\"errors\":");
    gql_runtime_vm_json_cat_errors(aTHX_ out, writer);
  }
  sv_catpvs(out, "}");
  return out;
}

static SV *
gql_runtime_vm_execute_bundle_fast_response_json(
  pTHX_
  gql_runtime_vm_native_runtime_t *runtime,
  SV *runtime_schema,
  gql_runtime_vm_native_bundle_t *bundle,
  SV *root_value,
  SV *context_value,
  SV *variables
)
{
  gql_runtime_vm_exec_state_t state;
  gql_runtime_vm_callback_context_t callback_ctx;
  gql_runtime_vm_writer_t writer_storage;
  SV *empty_args_sv;
  SV *out;

  Zero(&state, 1, gql_runtime_vm_exec_state_t);
  Zero(&callback_ctx, 1, gql_runtime_vm_callback_context_t);

  state.runtime = runtime;
  state.bundle = bundle;
  callback_ctx.runtime_schema = runtime_schema ? runtime_schema : &PL_sv_undef;
  callback_ctx.root_value = root_value;
  callback_ctx.context = context_value;
  callback_ctx.variables = variables;
  state.callback_ctx = &callback_ctx;
  gql_runtime_vm_prepare_bundle_block_type_objects(aTHX_ callback_ctx.runtime_schema, bundle);

  gql_runtime_vm_init_writer_struct(&writer_storage);
  state.writer = &writer_storage;
  state.path_frame = NULL;
  empty_args_sv = gql_runtime_vm_empty_args_sv(aTHX);
  state.empty_args_sv = empty_args_sv;

  out = newSV(1024);
  sv_setpvs(out, "{\"data\":");

  if (gql_runtime_vm_execute_block_fast_json(
        aTHX_
        &state,
        bundle->root_block_index,
        root_value,
        out
      )) {
    /* Non-null propagation reached the root: data is null. */
    sv_catpvs(out, "null");
  }

  if (writer_storage.error_record_count > 0) {
    sv_catpvs(out, ",\"errors\":");
    gql_runtime_vm_json_cat_errors(aTHX_ out, &writer_storage);
  }
  sv_catpvs(out, "}");

  SvREFCNT_dec(empty_args_sv);
  gql_runtime_vm_clear_writer_struct(aTHX_ &writer_storage);
  if (state.fast_lane_deferred_croak_sv) {
    /* Deferred from mid-lane so the path frame chain unwound normally. */
    SvREFCNT_dec(out);
    croak_sv(sv_2mortal(state.fast_lane_deferred_croak_sv));
  }
  return out;
}


MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::XS::Parser

SV *
parse_xs(source, no_location = &PL_sv_undef)
    SV *source
    SV *no_location
  CODE:
    RETVAL = gql_parse_document(aTHX_ source, no_location);
  OUTPUT:
    RETVAL

SV *
_parse_with_diagnostics_xs(source)
    SV *source
  CODE:
    {
      AV *errors_av = newAV();
      AV *result_av = newAV();
      av_push(result_av, gql_parse_document_for_validation(
        aTHX_ source, &PL_sv_undef, errors_av
      ));
      av_push(result_av, newRV_noinc((SV *)errors_av));
      RETVAL = newRV_noinc((SV *)result_av);
    }
  OUTPUT:
    RETVAL

SV *
_materialize_arguments_xs(state, ptr)
    SV *state
    UV ptr
  CODE:
    {
      RETVAL = newRV_noinc((SV *)gql_parser_materialize_lazy_array(
        aTHX_ state,
        ptr,
        GQLJS_LAZY_ARRAY_ARGUMENTS
      ));
    }
  OUTPUT:
    RETVAL

SV *
_materialize_directives_xs(state, ptr)
    SV *state
    UV ptr
  CODE:
    {
      RETVAL = newRV_noinc((SV *)gql_parser_materialize_lazy_array(
        aTHX_ state,
        ptr,
        GQLJS_LAZY_ARRAY_DIRECTIVES
      ));
    }
  OUTPUT:
    RETVAL

SV *
_materialize_variable_definitions_xs(state, ptr)
    SV *state
    UV ptr
  CODE:
    {
      RETVAL = newRV_noinc((SV *)gql_parser_materialize_lazy_array(
        aTHX_ state,
        ptr,
        GQLJS_LAZY_ARRAY_VARIABLE_DEFINITIONS
      ));
    }
  OUTPUT:
    RETVAL

SV *
_materialize_object_fields_xs(state, ptr)
    SV *state
    UV ptr
  CODE:
    {
      RETVAL = newRV_noinc((SV *)gql_parser_materialize_lazy_array(
        aTHX_ state,
        ptr,
        GQLJS_LAZY_ARRAY_OBJECT_FIELDS
      ));
    }
  OUTPUT:
    RETVAL

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::XS::LazyState

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_parser_lazy_state_t *state = INT2PTR(gql_parser_lazy_state_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_parser_lazy_state_destroy(state);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::XS::Parser

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::XS::SchemaCompiler

SV *
compile_schema_xs(schema)
    SV *schema
  CODE:
    RETVAL = gql_schema_compile_schema(aTHX_ schema);
  OUTPUT:
    RETVAL

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::XS::Validation

SV *
validate_xs(schema, document, options = NULL)
    SV *schema
    SV *document
    SV *options
  CODE:
    RETVAL = gql_validation_validate(aTHX_ schema, document, options);
  OUTPUT:
    RETVAL

SV *
check_cost_xs(schema, document, options)
    SV *schema
    SV *document
    SV *options
  CODE:
    RETVAL = gql_validation_check_cost(aTHX_ schema, document, options);
  OUTPUT:
    RETVAL

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::XS::VM

BOOT:
    {
      /* XS handle classes wrap raw C pointers; duplicating them across
       * ithreads would double-free. CLONE_SKIP makes ithread clones drop
       * them (become undef) instead. ithreads are otherwise unsupported. */
      static const char *const gql_handle_classes[] = {
        "GraphQL::Houtou::Runtime::ExecState",
        "GraphQL::Houtou::Runtime::Cursor",
        "GraphQL::Houtou::Runtime::Writer",
        "GraphQL::Houtou::Runtime::Outcome",
        "GraphQL::Houtou::Runtime::FieldFrame",
        "GraphQL::Houtou::Runtime::BlockFrame",
        "GraphQL::Houtou::Runtime::PathFrame",
        "GraphQL::Houtou::Runtime::ErrorRecord",
        "GraphQL::Houtou::Runtime::LazyInfo",
        "GraphQL::Houtou::Runtime::ListPending",
        "GraphQL::Houtou::Runtime::PendingMerge",
        "GraphQL::Houtou::Runtime::NativeProgram",
        "GraphQL::Houtou::Runtime::NativeBundle",
        "GraphQL::Houtou::Runtime::NativeRuntime",
        "GraphQL::Houtou::XS::LazyState",
      };
      size_t gql_handle_class_index;
      for (gql_handle_class_index = 0;
           gql_handle_class_index < sizeof(gql_handle_classes) / sizeof(gql_handle_classes[0]);
           gql_handle_class_index++) {
        HV *stash = gv_stashpv(gql_handle_classes[gql_handle_class_index], GV_ADD);
        newCONSTSUB(stash, "CLONE_SKIP", newSViv(1));
      }
    }
    if (!gql_runtime_vm_global_empty_args_sv) {
      gql_runtime_vm_global_empty_args_sv = newRV_noinc((SV *)newHV());
    }
    if (!gql_runtime_vm_global_identity_callback_sv) {
      CV *cv = get_cv("GraphQL::Houtou::XS::VM::identity_callback_xs", 0);
      if (cv) {
        gql_runtime_vm_global_identity_callback_sv = newRV_inc((SV *)cv);
      }
    }
    if (!gql_runtime_vm_global_wrap_object_outcome_callback_sv) {
      CV *cv = get_cv("GraphQL::Houtou::XS::VM::wrap_object_outcome_callback_xs", 0);
      if (cv) {
        gql_runtime_vm_global_wrap_object_outcome_callback_sv = newRV_inc((SV *)cv);
      }
    }
    if (!gql_runtime_vm_global_wrap_list_outcome_callback_sv) {
      CV *cv = get_cv("GraphQL::Houtou::XS::VM::wrap_list_outcome_callback_xs", 0);
      if (cv) {
        gql_runtime_vm_global_wrap_list_outcome_callback_sv = newRV_inc((SV *)cv);
      }
    }
    if (!gql_runtime_vm_global_promise_xs_flatten_all_callback_sv) {
      CV *cv = get_cv("GraphQL::Houtou::XS::VM::promise_xs_flatten_all_callback_xs", 0);
      if (cv) {
        gql_runtime_vm_global_promise_xs_flatten_all_callback_sv = newRV_inc((SV *)cv);
      }
    }

SV *
native_codes_xs()
  CODE:
    {
      HV *hv = newHV();
      hv_store(hv, "resolve_default", 15, newSViv(GQL_VM_RESOLVE_DEFAULT), 0);
      hv_store(hv, "resolve_explicit", 16, newSViv(GQL_VM_RESOLVE_EXPLICIT), 0);
      hv_store(hv, "complete_generic", 16, newSViv(GQL_VM_COMPLETE_GENERIC), 0);
      hv_store(hv, "complete_object", 15, newSViv(GQL_VM_COMPLETE_OBJECT), 0);
      hv_store(hv, "complete_list", 13, newSViv(GQL_VM_COMPLETE_LIST), 0);
      hv_store(hv, "complete_abstract", 17, newSViv(GQL_VM_COMPLETE_ABSTRACT), 0);
      hv_store(hv, "family_generic", 14, newSViv(GQL_VM_FAMILY_GENERIC), 0);
      hv_store(hv, "family_object", 13, newSViv(GQL_VM_FAMILY_OBJECT), 0);
      hv_store(hv, "family_list", 11, newSViv(GQL_VM_FAMILY_LIST), 0);
      hv_store(hv, "family_abstract", 15, newSViv(GQL_VM_FAMILY_ABSTRACT), 0);
      hv_store(hv, "dispatch_generic", 16, newSViv(GQL_VM_DISPATCH_GENERIC), 0);
      hv_store(hv, "dispatch_resolve_type", 21, newSViv(GQL_VM_DISPATCH_RESOLVE_TYPE), 0);
      hv_store(hv, "dispatch_tag", 12, newSViv(GQL_VM_DISPATCH_TAG), 0);
      hv_store(hv, "dispatch_possible_types", 23, newSViv(GQL_VM_DISPATCH_POSSIBLE_TYPES), 0);
      hv_store(hv, "kind_scalar", 11, newSViv(GQL_VM_KIND_SCALAR), 0);
      hv_store(hv, "kind_object", 11, newSViv(GQL_VM_KIND_OBJECT), 0);
      hv_store(hv, "kind_list", 9, newSViv(GQL_VM_KIND_LIST), 0);
      hv_store(hv, "kind_interface", 14, newSViv(GQL_VM_KIND_INTERFACE), 0);
      hv_store(hv, "kind_union", 10, newSViv(GQL_VM_KIND_UNION), 0);
      hv_store(hv, "kind_enum", 9, newSViv(GQL_VM_KIND_ENUM), 0);
      hv_store(hv, "kind_input_object", 17, newSViv(GQL_VM_KIND_INPUT_OBJECT), 0);
      hv_store(hv, "kind_non_null", 13, newSViv(GQL_VM_KIND_NON_NULL), 0);
      hv_store(hv, "optype_query", 12, newSViv(GQL_VM_OPTYPE_QUERY), 0);
      hv_store(hv, "optype_mutation", 15, newSViv(GQL_VM_OPTYPE_MUTATION), 0);
      hv_store(hv, "optype_subscription", 18, newSViv(GQL_VM_OPTYPE_SUBSCRIPTION), 0);
      RETVAL = newRV_noinc((SV *)hv);
    }
  OUTPUT:
    RETVAL

void
cancel_pending_response_xs(promise)
    SV *promise
  CODE:
    gql_runtime_vm_cancel_pending_response_sv(aTHX_ promise);

SV *
debug_frame_live_counts_xs()
  CODE:
    {
      /* Leak instrumentation (R5): frames handed out minus frames released.
       * Both counts must be zero whenever no request is executing and no
       * promise is pending; a positive residue is an orphaned frame. */
      HV *hv = newHV();
      hv_store(hv, "block_frame", 11, newSViv(gql_runtime_vm_block_frame_live_count), 0);
      hv_store(hv, "path_frame", 10, newSViv(gql_runtime_vm_path_frame_live_count), 0);
      RETVAL = newRV_noinc((SV *)hv);
    }
  OUTPUT:
    RETVAL

SV *
load_native_bundle_xs(descriptor)
    SV *descriptor
  CODE:
    {
      gql_runtime_vm_native_bundle_t *bundle =
        gql_runtime_vm_native_bundle_from_sv(aTHX_ descriptor);
      SV *inner = newSVuv(PTR2UV(bundle));
      RETVAL = newRV_noinc(inner);
      sv_bless(RETVAL, gv_stashpv("GraphQL::Houtou::Runtime::NativeBundle", GV_ADD));
    }
  OUTPUT:
    RETVAL

SV *
load_native_bundle_parts_xs(runtime_descriptor, program_descriptor)
    SV *runtime_descriptor
    SV *program_descriptor
  CODE:
    {
      gql_runtime_vm_native_bundle_t *bundle =
        gql_runtime_vm_native_bundle_from_runtime_and_program_sv(
          aTHX_ runtime_descriptor, program_descriptor
        );
      SV *inner = newSVuv(PTR2UV(bundle));
      RETVAL = newRV_noinc(inner);
      sv_bless(RETVAL, gv_stashpv("GraphQL::Houtou::Runtime::NativeBundle", GV_ADD));
    }
  OUTPUT:
    RETVAL

SV *
native_bundle_summary_xs(bundle_sv)
    SV *bundle_sv
  CODE:
    {
      gql_runtime_vm_native_bundle_t *bundle;
      HV *hv;
      AV *dispatch_codes;
      IV i;

      if (!bundle_sv || !SvROK(bundle_sv) || !sv_derived_from(bundle_sv, "GraphQL::Houtou::Runtime::NativeBundle")) {
        croak("expected a GraphQL::Houtou::Runtime::NativeBundle");
      }
      bundle = INT2PTR(gql_runtime_vm_native_bundle_t *, SvUV(SvRV(bundle_sv)));
      if (!bundle) {
        croak("native VM bundle handle is no longer valid");
      }

      hv = newHV();
      hv_store(hv, "runtime_slot_count", 18, newSViv(bundle->runtime_slot_count), 0);
      hv_store(hv, "block_count", 11, newSViv(bundle->block_count), 0);
      hv_store(hv, "root_block_index", 16, newSViv(bundle->root_block_index), 0);
      hv_store(hv, "operation_type_code", 19, newSViv(bundle->operation_type_code), 0);

      if (bundle->root_block_index >= 0 && bundle->root_block_index < bundle->block_count) {
        gql_runtime_vm_native_block_t *root = &bundle->blocks[bundle->root_block_index];
        hv_store(hv, "root_family_code", 16, newSViv(root->family_code), 0);
        hv_store(hv, "root_slot_count", 15, newSViv(root->slot_count), 0);
        hv_store(hv, "root_op_count", 13, newSViv(root->op_count), 0);

        dispatch_codes = newAV();
        av_extend(dispatch_codes, root->op_count > 0 ? root->op_count - 1 : 0);
        for (i = 0; i < root->op_count; i++) {
          av_store(dispatch_codes, i, newSViv(root->ops[i].dispatch_family_code));
        }
        hv_store(hv, "root_dispatch_family_codes", 26, newRV_noinc((SV *)dispatch_codes), 0);
      }

      RETVAL = newRV_noinc((SV *)hv);
    }
  OUTPUT:
    RETVAL

SV *
load_native_program_xs(program_descriptor)
    SV *program_descriptor
  CODE:
    {
      gql_runtime_vm_native_program_t *program =
        gql_runtime_vm_native_program_from_sv(aTHX_ program_descriptor);
      SV *inner = newSVuv(PTR2UV(program));
      RETVAL = newRV_noinc(inner);
      sv_bless(RETVAL, gv_stashpv("GraphQL::Houtou::Runtime::NativeProgram", GV_ADD));
    }
  OUTPUT:
    RETVAL

SV *
native_program_descriptor_xs(program_sv)
    SV *program_sv
  CODE:
    {
      gql_runtime_vm_native_program_t *program =
        gql_runtime_vm_native_program_from_sv(aTHX_ program_sv);
      RETVAL = gql_runtime_vm_native_program_to_compact_sv(aTHX_ program);
    }
  OUTPUT:
    RETVAL

SV *
native_program_prepare_variables_xs(runtime_schema, program_sv, provided = &PL_sv_undef)
    SV *runtime_schema
    SV *program_sv
    SV *provided
  CODE:
    {
      gql_runtime_vm_native_program_t *program =
        gql_runtime_vm_native_program_from_sv(aTHX_ program_sv);
      HV *provided_hv = NULL;
      if (provided && SvOK(provided) && SvROK(provided) && SvTYPE(SvRV(provided)) == SVt_PVHV) {
        provided_hv = (HV *)SvRV(provided);
      }
      RETVAL = gql_runtime_vm_prepare_program_variables_sv(
        aTHX_ runtime_schema,
        program,
        provided_hv
      );
    }
  OUTPUT:
    RETVAL

IV
native_program_root_block_index_xs(program_sv)
    SV *program_sv
  CODE:
    {
      gql_runtime_vm_native_program_t *program =
        gql_runtime_vm_native_program_from_sv(aTHX_ program_sv);
      RETVAL = program->root_block_index;
    }
  OUTPUT:
    RETVAL

IV
native_program_needs_variable_specialization_xs(program_sv)
    SV *program_sv
  CODE:
    {
      gql_runtime_vm_native_program_t *program =
        gql_runtime_vm_native_program_from_sv(aTHX_ program_sv);
      RETVAL = gql_runtime_vm_program_needs_variable_specialization(program);
    }
  OUTPUT:
    RETVAL

SV *
specialize_native_program_xs(runtime_sv, program_descriptor, variables = &PL_sv_undef)
    SV *runtime_sv
    SV *program_descriptor
    SV *variables
  CODE:
    {
      gql_runtime_vm_native_runtime_t *runtime;
      gql_runtime_vm_native_program_t *program;
      HV *variables_hv = NULL;
      SV *inner;

      if (!runtime_sv || !SvROK(runtime_sv) || !sv_derived_from(runtime_sv, "GraphQL::Houtou::Runtime::NativeRuntime")) {
        croak("expected a GraphQL::Houtou::Runtime::NativeRuntime");
      }
      runtime = INT2PTR(gql_runtime_vm_native_runtime_t *, SvUV(SvRV(runtime_sv)));
      if (!runtime) {
        croak("native VM runtime handle is no longer valid");
      }
      if (variables && SvOK(variables) && SvROK(variables) && SvTYPE(SvRV(variables)) == SVt_PVHV) {
        variables_hv = (HV *)SvRV(variables);
      }

      program = gql_runtime_vm_native_program_from_sv(aTHX_ program_descriptor);
      if (program_descriptor && SvROK(program_descriptor) && sv_derived_from(program_descriptor, "GraphQL::Houtou::Runtime::NativeProgram")) {
        program = gql_runtime_vm_clone_native_program(aTHX_ program);
      }
      gql_runtime_vm_specialize_native_program_in_place(aTHX_ runtime, program, variables_hv);

      inner = newSVuv(PTR2UV(program));
      RETVAL = newRV_noinc(inner);
      sv_bless(RETVAL, gv_stashpv("GraphQL::Houtou::Runtime::NativeProgram", GV_ADD));
    }
  OUTPUT:
    RETVAL

SV *
load_native_bundle_from_handles_xs(runtime_sv, program_sv)
    SV *runtime_sv
    SV *program_sv
  CODE:
    {
      gql_runtime_vm_native_runtime_t *runtime;
      gql_runtime_vm_native_program_t *program;
      gql_runtime_vm_native_bundle_t *bundle;
      if (!runtime_sv || !SvROK(runtime_sv) || !sv_derived_from(runtime_sv, "GraphQL::Houtou::Runtime::NativeRuntime")) {
        croak("expected a GraphQL::Houtou::Runtime::NativeRuntime");
      }
      runtime = INT2PTR(gql_runtime_vm_native_runtime_t *, SvUV(SvRV(runtime_sv)));
      if (!runtime) {
        croak("native VM runtime handle is no longer valid");
      }
      program = gql_runtime_vm_native_program_from_sv(aTHX_ program_sv);
      bundle = gql_runtime_vm_native_bundle_from_runtime_and_program_handles(runtime, program);
      SV *inner = newSVuv(PTR2UV(bundle));
      RETVAL = newRV_noinc(inner);
      sv_bless(RETVAL, gv_stashpv("GraphQL::Houtou::Runtime::NativeBundle", GV_ADD));
    }
  OUTPUT:
    RETVAL

SV *
native_program_summary_xs(program_sv)
    SV *program_sv
  CODE:
    {
      gql_runtime_vm_native_program_t *program;
      HV *hv;
      if (!program_sv || !SvROK(program_sv) || !sv_derived_from(program_sv, "GraphQL::Houtou::Runtime::NativeProgram")) {
        croak("expected a GraphQL::Houtou::Runtime::NativeProgram");
      }
      program = INT2PTR(gql_runtime_vm_native_program_t *, SvUV(SvRV(program_sv)));
      if (!program) {
        croak("native VM program handle is no longer valid");
      }
      hv = newHV();
      hv_store(hv, "block_count", 11, newSViv(program->block_count), 0);
      hv_store(hv, "root_block_index", 16, newSViv(program->root_block_index), 0);
      hv_store(hv, "operation_type_code", 19, newSViv(program->operation_type_code), 0);
      RETVAL = newRV_noinc((SV *)hv);
    }
  OUTPUT:
    RETVAL

SV *
load_native_runtime_xs(runtime_schema)
    SV *runtime_schema
  CODE:
    {
      gql_runtime_vm_native_runtime_t *runtime =
        gql_runtime_vm_native_runtime_from_runtime_schema_sv(aTHX_ runtime_schema);
      SV *inner = newSVuv(PTR2UV(runtime));
      RETVAL = newRV_noinc(inner);
      sv_bless(RETVAL, gv_stashpv("GraphQL::Houtou::Runtime::NativeRuntime", GV_ADD));
    }
  OUTPUT:
    RETVAL

SV *
native_runtime_summary_xs(runtime_sv)
    SV *runtime_sv
  CODE:
    {
      gql_runtime_vm_native_runtime_t *runtime;
      HV *hv;

      if (!runtime_sv || !SvROK(runtime_sv) || !sv_derived_from(runtime_sv, "GraphQL::Houtou::Runtime::NativeRuntime")) {
        croak("expected a GraphQL::Houtou::Runtime::NativeRuntime");
      }
      runtime = INT2PTR(gql_runtime_vm_native_runtime_t *, SvUV(SvRV(runtime_sv)));
      if (!runtime) {
        croak("native VM runtime handle is no longer valid");
      }

      hv = newHV();
      hv_store(hv, "runtime_slot_count", 18, newSViv(runtime->runtime_slot_count), 0);
      hv_store(hv, "has_slot_type_objects", 21, newSViv(runtime->callback_catalog && runtime->callback_catalog->slot_type_objects ? 1 : 0), 0);
      hv_store(hv, "has_tag_dispatch_tables", 23, newSViv(runtime->callback_catalog && runtime->callback_catalog->slot_tag_entries ? 1 : 0), 0);
      hv_store(hv, "has_possible_type_entries", 25, newSViv(runtime->callback_catalog && runtime->callback_catalog->slot_possible_type_entries ? 1 : 0), 0);
      RETVAL = newRV_noinc((SV *)hv);
    }
  OUTPUT:
    RETVAL

int
program_native_eligible_xs(program, has_promise = 0)
    SV *program
    int has_promise
  CODE:
    RETVAL = gql_runtime_vm_program_is_native_eligible_sv(aTHX_ program, has_promise);
  OUTPUT:
    RETVAL

void
resolve_runtime_type_xs(dispatch, runtime_cache, value, context, info, abstract_type)
    SV *dispatch
    SV *runtime_cache
    SV *value
    SV *context
    SV *info
    SV *abstract_type
  PPCODE:
    {
      SV *error = NULL;
      SV *runtime_type = gql_runtime_vm_resolve_runtime_type_sv(
        aTHX_ dispatch, runtime_cache, value, context, info, abstract_type, &error
      );
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(runtime_type ? runtime_type : newSV(0)));
      PUSHs(sv_2mortal(error ? error : newSV(0)));
    }

void
resolve_runtime_type_for_abstract_xs(runtime_cache, abstract_name, value, context, info, abstract_type)
    SV *runtime_cache
    SV *abstract_name
    SV *value
    SV *context
    SV *info
    SV *abstract_type
  PPCODE:
    {
      SV *error = NULL;
      STRLEN abstract_name_len = 0;
      const char *abstract_name_pv = (abstract_name && SvOK(abstract_name))
        ? SvPV(abstract_name, abstract_name_len)
        : NULL;
      SV *runtime_type = gql_runtime_vm_resolve_runtime_type_for_abstract_sv(
        aTHX_ runtime_cache, abstract_name_pv, value, context, info, abstract_type, &error
      );
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(runtime_type ? runtime_type : newSV(0)));
      PUSHs(sv_2mortal(error ? error : newSV(0)));
    }

SV *
outcome_scalar_xs(value, error_records = &PL_sv_undef)
    SV *value
    SV *error_records
  CODE:
    RETVAL = gql_runtime_vm_new_handle_sv(
      aTHX_
      "GraphQL::Houtou::Runtime::Outcome",
      gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_SCALAR, value, error_records)
    );
  OUTPUT:
    RETVAL

SV *
outcome_object_xs(value, error_records = &PL_sv_undef)
    SV *value
    SV *error_records
  CODE:
    RETVAL = gql_runtime_vm_new_handle_sv(
      aTHX_
      "GraphQL::Houtou::Runtime::Outcome",
      gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_OBJECT, value, error_records)
    );
  OUTPUT:
    RETVAL

SV *
outcome_list_xs(value, error_records = &PL_sv_undef)
    SV *value
    SV *error_records
  CODE:
    RETVAL = gql_runtime_vm_new_handle_sv(
      aTHX_
      "GraphQL::Houtou::Runtime::Outcome",
      gql_runtime_vm_new_outcome_struct(aTHX_ GQL_VM_KIND_LIST, value, error_records)
    );
  OUTPUT:
    RETVAL

SV *
wrap_object_outcome_callback_xs(...)
  CODE:
    {
      SV *value = items > 0 ? ST(0) : &PL_sv_undef;
      RETVAL = gql_runtime_vm_new_outcome_handle_sv(
        aTHX_
        GQL_VM_KIND_OBJECT,
        value,
        &PL_sv_undef
      );
    }
  OUTPUT:
    RETVAL

SV *
wrap_list_outcome_callback_xs(...)
  PREINIT:
    AV *resolved_av;
    I32 i;
  CODE:
    {
      resolved_av = newAV();
      if (items == 1 && ST(0) && SvROK(ST(0)) && SvTYPE(SvRV(ST(0))) == SVt_PVAV) {
        AV *source_av = (AV *)SvRV(ST(0));
        SSize_t max = av_len(source_av);
        for (i = 0; i <= max; i++) {
          SV **svp = av_fetch(source_av, i, 0);
          av_push(resolved_av, newSVsv((svp && *svp) ? *svp : &PL_sv_undef));
        }
      } else {
        for (i = 0; i < items; i++) {
          av_push(resolved_av, newSVsv(ST(i) ? ST(i) : &PL_sv_undef));
        }
      }
      {
        SV *list_sv = newRV_noinc((SV *)resolved_av);
        RETVAL = gql_runtime_vm_new_outcome_handle_sv(
          aTHX_
          GQL_VM_KIND_LIST,
          list_sv,
          &PL_sv_undef
        );
        SvREFCNT_dec(list_sv);
      }
    }
  OUTPUT:
    RETVAL

SV *
promise_xs_flatten_all_callback_xs(...)
  PREINIT:
    AV *flattened_av;
    I32 i;
  CODE:
    {
      flattened_av = newAV();
      for (i = 0; i < items; i++) {
        SV *row_sv = ST(i) ? ST(i) : &PL_sv_undef;
        if (row_sv && SvROK(row_sv) && SvTYPE(SvRV(row_sv)) == SVt_PVAV) {
          AV *row_av = (AV *)SvRV(row_sv);
          if (av_len(row_av) == 0) {
            SV **item_svp = av_fetch(row_av, 0, 0);
            av_push(flattened_av, newSVsv((item_svp && *item_svp) ? *item_svp : &PL_sv_undef));
          } else {
            av_push(flattened_av, newSVsv(row_sv));
          }
        } else {
          av_push(flattened_av, newSVsv(row_sv));
        }
      }
      RETVAL = newRV_noinc((SV *)flattened_av);
    }
  OUTPUT:
    RETVAL

SV *
identity_callback_xs(...)
  CODE:
    {
      SV *resolved_sv = items > 0 && ST(0) ? ST(0) : &PL_sv_undef;
      SvREFCNT_inc_simple_NN(resolved_sv);
      RETVAL = resolved_sv;
    }
  OUTPUT:
    RETVAL

SV *
writer_new_xs(class)
    SV *class
  CODE:
    PERL_UNUSED_ARG(class);
    RETVAL = gql_runtime_vm_new_handle_sv(
      aTHX_
      "GraphQL::Houtou::Runtime::Writer",
      gql_runtime_vm_new_writer_struct(aTHX)
    );
  OUTPUT:
    RETVAL

void
consume_outcome_xs(writer, data, result_name, outcome)
    SV *writer
    SV *data
    SV *result_name
    SV *outcome
  PPCODE:
    {
      HV *data_hv = NULL;
      gql_runtime_vm_writer_t *writer_state = gql_runtime_vm_expect_writer(aTHX_ writer);
      gql_runtime_vm_outcome_t *outcome_state = gql_runtime_vm_expect_outcome(aTHX_ outcome);
      if (data && SvOK(data) && SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV) {
        data_hv = (HV *)SvRV(data);
      }
      gql_runtime_vm_consume_outcome_struct(aTHX_ data_hv, result_name, outcome_state, writer_state);
    }

SV *
outcome_kind_xs(outcome)
    SV *outcome
  CODE:
    RETVAL = gql_runtime_vm_outcome_kind_sv(aTHX_ gql_runtime_vm_expect_outcome(aTHX_ outcome));
  OUTPUT:
    RETVAL

SV *
outcome_value_xs(outcome)
    SV *outcome
  CODE:
    {
      gql_runtime_vm_outcome_t *state = gql_runtime_vm_expect_outcome(aTHX_ outcome);
      RETVAL = state->value ? gql_runtime_vm_native_value_materialize_sv(aTHX_ state->value) : newSV(0);
    }
  OUTPUT:
    RETVAL

SV *
outcome_error_records_xs(outcome)
    SV *outcome
  CODE:
    {
      gql_runtime_vm_outcome_t *state = gql_runtime_vm_expect_outcome(aTHX_ outcome);
      AV *ret = newAV();
      IV i;
      for (i = 0; i < state->error_record_count; i++) {
        gql_runtime_vm_error_record_incref(state->error_records[i]);
        av_push(ret, gql_runtime_vm_new_handle_sv(aTHX_ "GraphQL::Houtou::Runtime::ErrorRecord", state->error_records[i]));
      }
      RETVAL = newRV_noinc((SV *)ret);
    }
  OUTPUT:
    RETVAL

SV *
writer_error_records_xs(writer)
    SV *writer
  CODE:
    {
      gql_runtime_vm_writer_t *state = gql_runtime_vm_expect_writer(aTHX_ writer);
      AV *ret = newAV();
      IV i;
      for (i = 0; i < state->error_record_count; i++) {
        gql_runtime_vm_error_record_incref(state->error_records[i]);
        av_push(ret, gql_runtime_vm_new_handle_sv(aTHX_ "GraphQL::Houtou::Runtime::ErrorRecord", state->error_records[i]));
      }
      RETVAL = newRV_noinc((SV *)ret);
    }
  OUTPUT:
    RETVAL

SV *
cursor_new_xs(class, block, native_program = &PL_sv_undef, block_index = -1, slot_index = 0, op_index = 0, current_slot = &PL_sv_undef, current_op = &PL_sv_undef)
    SV *class
    SV *block
    SV *native_program
    IV block_index
    IV slot_index
    IV op_index
    SV *current_slot
    SV *current_op
  CODE:
    {
      gql_runtime_vm_cursor_t *cursor;
      const char *pkg = SvPV_nolen(class);
      (void)current_slot;
      (void)current_op;
      Newxz(cursor, 1, gql_runtime_vm_cursor_t);
      cursor->refcount = 1;
      cursor->native_program = (native_program && SvOK(native_program))
        ? gql_runtime_vm_native_program_from_sv(aTHX_ native_program)
        : NULL;
      if (block_index < 0 && block && SvOK(block) && !SvROK(block) && SvIOK(block)) {
        block_index = SvIV(block);
      }
      cursor->block_index = block_index;
      (void)block;
      cursor->slot_index = slot_index;
      cursor->op_index = op_index;
      RETVAL = gql_runtime_vm_new_handle_sv(aTHX_ pkg, cursor);
    }
  OUTPUT:
    RETVAL

SV *
cursor_snapshot_xs(cursor)
    SV *cursor
  CODE:
    RETVAL = gql_runtime_vm_cursor_snapshot_sv(aTHX_ cursor);
  OUTPUT:
    RETVAL

void
cursor_restore_xs(cursor, snapshot)
    SV *cursor
    SV *snapshot
  CODE:
    {
      gql_runtime_vm_cursor_t *dst = gql_runtime_vm_expect_cursor(aTHX_ cursor);
      gql_runtime_vm_cursor_restore_sv(aTHX_ dst, snapshot);
    }

void
cursor_enter_block_xs(cursor, block, block_index = -1)
    SV *cursor
    SV *block
    IV block_index
  CODE:
    {
      gql_runtime_vm_cursor_t *dst = gql_runtime_vm_expect_cursor(aTHX_ cursor);
      if (block_index < 0 && block && SvOK(block) && !SvROK(block) && SvIOK(block)) {
        block_index = SvIV(block);
      }
      (void)block;
      dst->block_index = block_index;
      dst->slot_index = 0;
      dst->op_index = -1;
    }

void
cursor_set_current_op_xs(cursor, op, index = -2147483647)
    SV *cursor
    SV *op
    IV index
  CODE:
    {
      gql_runtime_vm_cursor_t *dst = gql_runtime_vm_expect_cursor(aTHX_ cursor);
      (void)op;
      if (index != -2147483647) {
        dst->op_index = index;
      }
    }

SV *
cursor_advance_op_xs(cursor)
    SV *cursor
  CODE:
    {
      gql_runtime_vm_cursor_t *dst = gql_runtime_vm_expect_cursor(aTHX_ cursor);
      const gql_runtime_vm_native_block_t *block;
      const gql_runtime_vm_native_op_t *op;
      IV next_index;
      block = gql_runtime_vm_cursor_current_native_block(dst);
      if (!block) {
        RETVAL = &PL_sv_undef;
        goto done_cursor_advance;
      }
      next_index = dst->op_index + 1;
      if (next_index >= block->op_count) {
        dst->op_index = next_index;
        RETVAL = &PL_sv_undef;
        goto done_cursor_advance;
      }
      dst->op_index = next_index;
      op = &block->ops[next_index];
      dst->slot_index = op ? op->slot_index : 0;
      RETVAL = newSViv(next_index);
	done_cursor_advance:
	      ;
    }
  OUTPUT:
    RETVAL

SV *
cursor_block_xs(cursor)
    SV *cursor
  CODE:
    {
      PERL_UNUSED_ARG(cursor);
      RETVAL = newSVsv(&PL_sv_undef);
    }
  OUTPUT:
    RETVAL

IV
cursor_slot_index_xs(cursor)
    SV *cursor
  CODE:
    RETVAL = gql_runtime_vm_expect_cursor(aTHX_ cursor)->slot_index;
  OUTPUT:
    RETVAL

IV
cursor_op_index_xs(cursor)
    SV *cursor
  CODE:
    RETVAL = gql_runtime_vm_expect_cursor(aTHX_ cursor)->op_index;
  OUTPUT:
    RETVAL

SV *
cursor_current_slot_xs(cursor)
    SV *cursor
  CODE:
    {
      PERL_UNUSED_ARG(cursor);
      RETVAL = newSVsv(&PL_sv_undef);
    }
  OUTPUT:
    RETVAL

SV *
cursor_current_op_xs(cursor)
    SV *cursor
  CODE:
    {
      PERL_UNUSED_ARG(cursor);
      RETVAL = newSVsv(&PL_sv_undef);
    }
  OUTPUT:
    RETVAL

SV *
field_frame_new_xs(class, source = &PL_sv_undef, path_frame = &PL_sv_undef, resolved_value = &PL_sv_undef, outcome = &PL_sv_undef)
    SV *class
    SV *source
    SV *path_frame
    SV *resolved_value
    SV *outcome
  CODE:
    {
      gql_runtime_vm_field_frame_t *frame;
      const char *pkg = SvPV_nolen(class);
      frame = gql_runtime_vm_new_field_frame_struct(
        aTHX_
        source,
        (path_frame && SvOK(path_frame) && SvROK(path_frame) && SvIOK(SvRV(path_frame)) && SvUV(SvRV(path_frame)) != 0)
          ? INT2PTR(gql_runtime_vm_path_frame_t *, SvUV(SvRV(path_frame)))
          : NULL
      );
      frame->resolved_value = newSVsv(resolved_value ? resolved_value : &PL_sv_undef);
      if (outcome && SvOK(outcome)) {
        frame->outcome = gql_runtime_vm_expect_outcome(aTHX_ outcome);
        gql_runtime_vm_outcome_incref(frame->outcome);
      }
      RETVAL = gql_runtime_vm_new_handle_sv(aTHX_ pkg, frame);
    }
  OUTPUT:
    RETVAL

void
field_frame_set_resolved_value_xs(frame, value)
    SV *frame
    SV *value
  CODE:
    {
      gql_runtime_vm_field_frame_t *state = gql_runtime_vm_expect_field_frame(aTHX_ frame);
      if (state->resolved_value) {
        SvREFCNT_dec(state->resolved_value);
      }
      state->resolved_value = newSVsv(value ? value : &PL_sv_undef);
    }

void
field_frame_set_outcome_xs(frame, outcome)
    SV *frame
    SV *outcome
  CODE:
    {
      gql_runtime_vm_field_frame_t *state = gql_runtime_vm_expect_field_frame(aTHX_ frame);
      gql_runtime_vm_outcome_decref(aTHX_ state->outcome);
      state->outcome = NULL;
      if (outcome && SvOK(outcome)) {
        state->outcome = gql_runtime_vm_expect_outcome(aTHX_ outcome);
        gql_runtime_vm_outcome_incref(state->outcome);
      }
    }

SV *
field_frame_source_xs(frame)
    SV *frame
  CODE:
    {
      gql_runtime_vm_field_frame_t *state = gql_runtime_vm_expect_field_frame(aTHX_ frame);
      RETVAL = newSVsv(state->source ? state->source : &PL_sv_undef);
    }
  OUTPUT:
    RETVAL

SV *
field_frame_path_frame_xs(frame)
    SV *frame
  CODE:
    {
      gql_runtime_vm_field_frame_t *state = gql_runtime_vm_expect_field_frame(aTHX_ frame);
      if (state->path_frame) {
        state->path_frame->refcount++;
        RETVAL = gql_runtime_vm_new_handle_sv(aTHX_ "GraphQL::Houtou::Runtime::PathFrame", state->path_frame);
      } else {
        RETVAL = newSVsv(&PL_sv_undef);
      }
    }
  OUTPUT:
    RETVAL

SV *
field_frame_resolved_value_xs(frame)
    SV *frame
  CODE:
    {
      gql_runtime_vm_field_frame_t *state = gql_runtime_vm_expect_field_frame(aTHX_ frame);
      RETVAL = newSVsv(state->resolved_value ? state->resolved_value : &PL_sv_undef);
    }
  OUTPUT:
    RETVAL

SV *
field_frame_outcome_xs(frame)
    SV *frame
  CODE:
    {
      gql_runtime_vm_field_frame_t *state = gql_runtime_vm_expect_field_frame(aTHX_ frame);
      RETVAL = gql_runtime_vm_wrap_outcome_sv(aTHX_ state->outcome);
    }
  OUTPUT:
    RETVAL

SV *
path_frame_new_xs(class, parent = &PL_sv_undef, key = &PL_sv_undef)
    SV *class
    SV *parent
    SV *key
  CODE:
    {
      PERL_UNUSED_ARG(class);
      RETVAL = gql_runtime_vm_new_path_frame_handle(aTHX_ parent, key);
    }
  OUTPUT:
    RETVAL

SV *
path_frame_materialize_path_xs(path_frame)
    SV *path_frame
  CODE:
    {
      gql_runtime_vm_path_frame_t *frame = gql_runtime_vm_expect_path_frame(aTHX_ path_frame);
      RETVAL = gql_runtime_vm_path_frame_to_path_sv(aTHX_ frame);
    }
  OUTPUT:
    RETVAL

SV *
path_frame_parent_xs(path_frame)
    SV *path_frame
  CODE:
    {
      gql_runtime_vm_path_frame_t *state = gql_runtime_vm_expect_path_frame(aTHX_ path_frame);
      if (state->parent) {
        state->parent->refcount++;
        RETVAL = gql_runtime_vm_new_handle_sv(aTHX_ "GraphQL::Houtou::Runtime::PathFrame", state->parent);
      } else {
        RETVAL = newSVsv(&PL_sv_undef);
      }
    }
  OUTPUT:
    RETVAL

SV *
path_frame_key_xs(path_frame)
    SV *path_frame
  CODE:
    {
      gql_runtime_vm_path_frame_t *state = gql_runtime_vm_expect_path_frame(aTHX_ path_frame);
      RETVAL = gql_runtime_vm_path_frame_key_sv(aTHX_ state);
    }
  OUTPUT:
    RETVAL

SV *
lazy_info_hashref_xs(info_sv)
    SV *info_sv
  CODE:
    {
      gql_runtime_vm_lazy_info_t *info;

      if (!info_sv || !SvROK(info_sv) || !sv_derived_from(info_sv, "GraphQL::Houtou::Runtime::LazyInfo")) {
        croak("expected a GraphQL::Houtou::Runtime::LazyInfo");
      }
      info = INT2PTR(gql_runtime_vm_lazy_info_t *, SvUV(SvRV(info_sv)));
      if (!info) {
        croak("lazy info handle is no longer valid");
      }
      RETVAL = gql_runtime_vm_lazy_info_materialize_hash_sv(aTHX_ info);
    }
  OUTPUT:
    RETVAL

SV *
block_frame_new_xs(class, values = &PL_sv_undef, pending_names = &PL_sv_undef, pending_outcomes = &PL_sv_undef)
    SV *class
    SV *values
    SV *pending_names
    SV *pending_outcomes
  CODE:
    {
      gql_runtime_vm_block_frame_t *frame;
      const char *pkg = SvPV_nolen(class);
      frame = gql_runtime_vm_new_block_frame_struct(aTHX);
      if (values && SvOK(values) && SvROK(values) && SvTYPE(SvRV(values)) == SVt_PVHV) {
        gql_runtime_vm_native_value_destroy(aTHX_ frame->values_value);
        frame->values_value = gql_runtime_vm_native_value_from_sv(aTHX_ values);
      }
      if (pending_names && SvOK(pending_names) && SvROK(pending_names) && SvTYPE(SvRV(pending_names)) == SVt_PVAV &&
          pending_outcomes && SvOK(pending_outcomes) && SvROK(pending_outcomes) && SvTYPE(SvRV(pending_outcomes)) == SVt_PVAV) {
        AV *names_av = (AV *)SvRV(pending_names);
        AV *outcomes_av = (AV *)SvRV(pending_outcomes);
        SSize_t i;
        for (i = 0; i <= av_len(names_av); i++) {
          SV **name_svp = av_fetch(names_av, i, 0);
          SV **outcome_svp = av_fetch(outcomes_av, i, 0);
          if (name_svp && *name_svp && outcome_svp && *outcome_svp && SvOK(*outcome_svp)) {
            gql_runtime_vm_block_frame_push_pending(aTHX_ frame, *name_svp, *outcome_svp);
          }
        }
      }
      RETVAL = gql_runtime_vm_new_handle_sv(aTHX_ pkg, frame);
    }
  OUTPUT:
    RETVAL

void
block_frame_add_pending_xs(frame, result_name, outcome)
    SV *frame
    SV *result_name
    SV *outcome
  PPCODE:
    {
      gql_runtime_vm_block_frame_t *state = gql_runtime_vm_expect_block_frame(aTHX_ frame);
      gql_runtime_vm_block_frame_push_pending(aTHX_ state, result_name, outcome);
    }

void
block_frame_consume_outcome_xs(frame, writer, result_name, outcome)
    SV *frame
    SV *writer
    SV *result_name
    SV *outcome
  CODE:
    {
      gql_runtime_vm_block_frame_t *state = gql_runtime_vm_expect_block_frame(aTHX_ frame);
      gql_runtime_vm_writer_t *writer_state;
      STRLEN result_name_len = 0;
      const char *result_name_pv = NULL;
      if (!outcome || !SvOK(outcome)) {
        XSRETURN_EMPTY;
      }
      writer_state = gql_runtime_vm_expect_writer(aTHX_ writer);
      result_name_pv = (result_name && SvOK(result_name)) ? SvPV(result_name, result_name_len) : "";
      gql_runtime_vm_consume_outcome_native_object(
        aTHX_
        state->values_value,
        result_name_pv,
        0,
        gql_runtime_vm_expect_outcome(aTHX_ outcome),
        writer_state
      );
    }

SV *
block_frame_values_xs(frame)
    SV *frame
  CODE:
    {
      gql_runtime_vm_block_frame_t *state = gql_runtime_vm_expect_block_frame(aTHX_ frame);
      RETVAL = gql_runtime_vm_native_value_materialize_sv(aTHX_ state->values_value);
    }
  OUTPUT:
    RETVAL

SV *
block_frame_finalize_xs(frame, writer)
    SV *frame
    SV *writer
  CODE:
    {
      gql_runtime_vm_block_frame_t *state = gql_runtime_vm_expect_block_frame(aTHX_ frame);
      gql_runtime_vm_writer_t *writer_state = gql_runtime_vm_expect_writer(aTHX_ writer);
      RETVAL = gql_runtime_vm_block_frame_finalize_sv(
        aTHX_
        state,
        GQL_VM_PROMISE_BACKEND_PROMISE_XS,
        writer_state,
        &PL_sv_undef,
        0
      );
    }
  OUTPUT:
    RETVAL

IV
block_frame_has_pending_xs(frame)
    SV *frame
  CODE:
    {
      gql_runtime_vm_block_frame_t *state = gql_runtime_vm_expect_block_frame(aTHX_ frame);
      RETVAL = state->pending_count > 0 ? 1 : 0;
    }
  OUTPUT:
    RETVAL

SV *
block_frame_merge_pending_xs(frame, writer, resolved)
    SV *frame
    SV *writer
    SV *resolved
  CODE:
    {
      gql_runtime_vm_block_frame_t *state = gql_runtime_vm_expect_block_frame(aTHX_ frame);
      gql_runtime_vm_writer_t *writer_state = gql_runtime_vm_expect_writer(aTHX_ writer);
      AV *resolved_av = gql_runtime_vm_expect_arrayref(aTHX_ resolved, "resolved outcomes");
      SSize_t i;

      for (i = 0; i <= av_len(resolved_av) && i < state->pending_count; i++) {
        SV **outcome_svp = av_fetch(resolved_av, i, 0);
        if (outcome_svp && *outcome_svp) {
          gql_runtime_vm_consume_outcome_native_object(
            aTHX_
            state->values_value,
            state->pending_entries[i].result_name_pv,
            state->pending_entries[i].result_name_pv_borrowed,
            gql_runtime_vm_expect_outcome(aTHX_ *outcome_svp),
            writer_state
          );
        }
      }

      RETVAL = gql_runtime_vm_native_value_materialize_sv(aTHX_ state->values_value);
    }
  OUTPUT:
    RETVAL

SV *
exec_state_new_xs(class, runtime_schema, program, cursor, writer, context = &PL_sv_undef, variables = &PL_sv_undef, root_value = &PL_sv_undef, empty_args = &PL_sv_undef)
    SV *class
    SV *runtime_schema
    SV *program
    SV *cursor
    SV *writer
    SV *context
    SV *variables
    SV *root_value
    SV *empty_args
  CODE:
    {
      const char *pkg = SvPV_nolen(class);
      RETVAL = gql_runtime_vm_new_exec_state_handle_sv(
        aTHX_
        pkg,
        runtime_schema,
        program,
        (cursor && SvOK(cursor)) ? gql_runtime_vm_expect_cursor(aTHX_ cursor) : NULL,
        (writer && SvOK(writer)) ? gql_runtime_vm_expect_writer(aTHX_ writer) : NULL,
        context,
        variables,
        root_value,
        empty_args
      );
    }
  OUTPUT:
    RETVAL

SV *
exec_state_execute_block_async_xs(state, block_index, source = &PL_sv_undef, base_path = &PL_sv_undef)
    SV *state
    IV block_index
    SV *source
    SV *base_path
  CODE:
    {
      gql_runtime_vm_exec_state_handle_t *s = gql_runtime_vm_expect_exec_state_handle(aTHX_ state);
      RETVAL = gql_runtime_vm_exec_state_execute_block_async_sv(aTHX_ state, s, block_index, source, base_path);
      if (s->completed_response_sv) {
        /* Response frame completed without a deferred; hand back the
         * parked envelope the promise would have resolved with. */
        SvREFCNT_dec(RETVAL);
        RETVAL = s->completed_response_sv;
        s->completed_response_sv = NULL;
      }
    }
  OUTPUT:
    RETVAL

SV *
exec_state_run_program_xs(state, root_value = &PL_sv_undef)
    SV *state
    SV *root_value
  CODE:
    {
      gql_runtime_vm_exec_state_handle_t *s = gql_runtime_vm_expect_exec_state_handle(aTHX_ state);
      SV *effective_root = root_value;
      gql_runtime_vm_native_runtime_t *runtime;
      gql_runtime_vm_native_bundle_t *bundle;
      SV *runtime_schema_sv;
      SV *variables_sv;
      SV *context_sv;

      if (!s->cursor || !s->cursor->native_program) {
        croak("exec state cursor must hold a native program");
      }
      if (!effective_root || !SvOK(effective_root)) {
        effective_root = s->root_value;
      }
      runtime = gql_runtime_vm_exec_state_native_runtime(aTHX_ s);
      runtime_schema_sv =
        (s->runtime_schema && SvOK(s->runtime_schema))
          ? s->runtime_schema
          : (runtime && runtime->callback_catalog && runtime->callback_catalog->runtime_schema
            ? runtime->callback_catalog->runtime_schema
            : &PL_sv_undef);
      variables_sv = (s->variables && SvOK(s->variables)) ? s->variables : &PL_sv_undef;
      context_sv = (s->context && SvOK(s->context)) ? s->context : &PL_sv_undef;
      bundle = gql_runtime_vm_native_program_cached_bundle(
        aTHX_
        runtime,
        s->cursor->native_program
      );
      RETVAL = gql_runtime_vm_execute_bundle_fast_response_sv(
        aTHX_
        runtime,
        runtime_schema_sv,
        bundle,
        effective_root,
        context_sv,
        variables_sv
      );
    }
  OUTPUT:
    RETVAL

SV *
exec_state_run_program_async_xs(state, root_value = &PL_sv_undef)
    SV *state
    SV *root_value
  CODE:
    {
      gql_runtime_vm_exec_state_handle_t *s = gql_runtime_vm_expect_exec_state_handle(aTHX_ state);
      SV *effective_root = root_value;
      SV *data_sv;
      IV root_block_index = -1;

      if (!s->cursor || !s->cursor->native_program) {
        croak("exec state cursor must hold a native program");
      }
      root_block_index = s->cursor->native_program->root_block_index;
      if (!effective_root || !SvOK(effective_root)) {
        effective_root = s->root_value;
      }

      data_sv = gql_runtime_vm_exec_state_execute_block_async_sv(
        aTHX_
        state,
        s,
        root_block_index,
        effective_root,
        &PL_sv_undef
      );
      if (s->completed_response_sv) {
        /* Response frame completed without a deferred; the parked value
         * is already the finished envelope. */
        RETVAL = s->completed_response_sv;
        s->completed_response_sv = NULL;
        SvREFCNT_dec(data_sv);
      } else if (gql_runtime_vm_is_promise_value_for_state_sv(aTHX_ s, data_sv)) {
        RETVAL = data_sv;
      } else {
        RETVAL = gql_runtime_vm_exec_state_materialize_response_sv(aTHX_ s, data_sv);
        SvREFCNT_dec(data_sv);
      }
    }
  OUTPUT:
    RETVAL

SV *
exec_state_materialize_response_xs(state, data = &PL_sv_undef)
    SV *state
    SV *data
  CODE:
    {
      gql_runtime_vm_exec_state_handle_t *s = gql_runtime_vm_expect_exec_state_handle(aTHX_ state);
      RETVAL = gql_runtime_vm_exec_state_materialize_response_sv(aTHX_ s, data);
    }
  OUTPUT:
    RETVAL

SV *
execute_native_bundle_xs(runtime_schema, bundle_sv, root_value = &PL_sv_undef, context_value = &PL_sv_undef, variables = &PL_sv_undef)
    SV *runtime_schema
    SV *bundle_sv
    SV *root_value
    SV *context_value
    SV *variables
  CODE:
    {
      gql_runtime_vm_native_bundle_t *bundle;
      gql_runtime_vm_native_runtime_t *runtime = NULL;
      int owns_runtime = 0;
      SV *runtime_schema_sv;

      if (!bundle_sv || !SvROK(bundle_sv) || !sv_derived_from(bundle_sv, "GraphQL::Houtou::Runtime::NativeBundle")) {
        croak("expected a GraphQL::Houtou::Runtime::NativeBundle");
      }
      bundle = INT2PTR(gql_runtime_vm_native_bundle_t *, SvUV(SvRV(bundle_sv)));
      if (!bundle) {
        croak("native VM bundle handle is no longer valid");
      }

      if (runtime_schema && SvROK(runtime_schema) && sv_derived_from(runtime_schema, "GraphQL::Houtou::Runtime::NativeRuntime")) {
        runtime = INT2PTR(gql_runtime_vm_native_runtime_t *, SvUV(SvRV(runtime_schema)));
        if (!runtime) {
          croak("native VM runtime handle is no longer valid");
        }
      } else {
        runtime = gql_runtime_vm_native_runtime_from_runtime_schema_sv(aTHX_ runtime_schema);
        owns_runtime = 1;
      }

      runtime_schema_sv = (runtime_schema && !sv_derived_from(runtime_schema, "GraphQL::Houtou::Runtime::NativeRuntime"))
        ? runtime_schema
        : (runtime && runtime->callback_catalog && runtime->callback_catalog->runtime_schema
          ? runtime->callback_catalog->runtime_schema
          : &PL_sv_undef);
      RETVAL = gql_runtime_vm_execute_bundle_fast_response_sv(
        aTHX_
        runtime,
        runtime_schema_sv,
        bundle,
        root_value,
        context_value,
        variables
      );
      if (owns_runtime) {
        gql_runtime_vm_native_runtime_destroy(runtime);
      }
    }
  OUTPUT:
    RETVAL

SV *
execute_native_program_xs(runtime_schema, runtime_descriptor, program_descriptor, root_value = &PL_sv_undef, context_value = &PL_sv_undef, variables = &PL_sv_undef)
    SV *runtime_schema
    SV *runtime_descriptor
    SV *program_descriptor
    SV *root_value
    SV *context_value
    SV *variables
  CODE:
    {
      gql_runtime_vm_native_bundle_t *bundle;
      gql_runtime_vm_native_runtime_t *runtime = NULL;
      int owns_runtime = 0;
      SV *runtime_schema_sv;

      bundle = gql_runtime_vm_native_bundle_from_runtime_and_program_sv(
        aTHX_ runtime_descriptor, program_descriptor
      );

      if (runtime_schema && SvROK(runtime_schema) && sv_derived_from(runtime_schema, "GraphQL::Houtou::Runtime::NativeRuntime")) {
        runtime = INT2PTR(gql_runtime_vm_native_runtime_t *, SvUV(SvRV(runtime_schema)));
        if (!runtime) {
          gql_runtime_vm_native_bundle_destroy(bundle);
          croak("native VM runtime handle is no longer valid");
        }
      } else {
        runtime = gql_runtime_vm_native_runtime_from_runtime_schema_sv(aTHX_ runtime_schema);
        owns_runtime = 1;
      }

      runtime_schema_sv = (runtime_schema && !sv_derived_from(runtime_schema, "GraphQL::Houtou::Runtime::NativeRuntime"))
        ? runtime_schema
        : (runtime && runtime->callback_catalog && runtime->callback_catalog->runtime_schema
          ? runtime->callback_catalog->runtime_schema
          : &PL_sv_undef);
      RETVAL = gql_runtime_vm_execute_bundle_fast_response_sv(
        aTHX_
        runtime,
        runtime_schema_sv,
        bundle,
        root_value,
        context_value,
        variables
      );
      gql_runtime_vm_native_bundle_destroy(bundle);
      if (owns_runtime) {
        gql_runtime_vm_native_runtime_destroy(runtime);
      }
    }
  OUTPUT:
    RETVAL

SV *
execute_native_program_handle_xs(runtime_sv, program_sv, root_value = &PL_sv_undef, context_value = &PL_sv_undef, variables = &PL_sv_undef)
    SV *runtime_sv
    SV *program_sv
    SV *root_value
    SV *context_value
    SV *variables
  CODE:
    {
      gql_runtime_vm_native_runtime_t *runtime;
      gql_runtime_vm_native_program_t *program;
      gql_runtime_vm_native_bundle_t *bundle;
      SV *runtime_schema_sv;

      if (!runtime_sv || !SvROK(runtime_sv) || !sv_derived_from(runtime_sv, "GraphQL::Houtou::Runtime::NativeRuntime")) {
        croak("expected a GraphQL::Houtou::Runtime::NativeRuntime");
      }
      runtime = INT2PTR(gql_runtime_vm_native_runtime_t *, SvUV(SvRV(runtime_sv)));
      if (!runtime) {
        croak("native VM runtime handle is no longer valid");
      }
      program = gql_runtime_vm_native_program_from_sv(aTHX_ program_sv);
      bundle = gql_runtime_vm_native_program_cached_bundle(aTHX_ runtime, program);
      runtime_schema_sv = (runtime && runtime->callback_catalog && runtime->callback_catalog->runtime_schema)
        ? runtime->callback_catalog->runtime_schema
        : &PL_sv_undef;
      RETVAL = gql_runtime_vm_execute_bundle_fast_response_sv(
        aTHX_
        runtime,
        runtime_schema_sv,
        bundle,
        root_value,
        context_value,
        variables
      );
    }
  OUTPUT:
    RETVAL

SV *
execute_native_program_to_json_xs(runtime_sv, program_sv, root_value = &PL_sv_undef, context_value = &PL_sv_undef, variables = &PL_sv_undef)
    SV *runtime_sv
    SV *program_sv
    SV *root_value
    SV *context_value
    SV *variables
  CODE:
    {
      gql_runtime_vm_native_runtime_t *runtime;
      gql_runtime_vm_native_program_t *program;
      gql_runtime_vm_native_bundle_t *bundle;
      SV *runtime_schema_sv;

      if (!runtime_sv || !SvROK(runtime_sv) || !sv_derived_from(runtime_sv, "GraphQL::Houtou::Runtime::NativeRuntime")) {
        croak("expected a GraphQL::Houtou::Runtime::NativeRuntime");
      }
      runtime = INT2PTR(gql_runtime_vm_native_runtime_t *, SvUV(SvRV(runtime_sv)));
      if (!runtime) {
        croak("native VM runtime handle is no longer valid");
      }
      program = gql_runtime_vm_native_program_from_sv(aTHX_ program_sv);
      bundle = gql_runtime_vm_native_program_cached_bundle(aTHX_ runtime, program);
      runtime_schema_sv = (runtime && runtime->callback_catalog && runtime->callback_catalog->runtime_schema)
        ? runtime->callback_catalog->runtime_schema
        : &PL_sv_undef;
      RETVAL = gql_runtime_vm_execute_bundle_fast_response_json(
        aTHX_
        runtime,
        runtime_schema_sv,
        bundle,
        root_value,
        context_value,
        variables
      );
    }
  OUTPUT:
    RETVAL

SV *
execute_native_bundle_to_json_xs(runtime_sv, bundle_sv, root_value = &PL_sv_undef, context_value = &PL_sv_undef, variables = &PL_sv_undef)
    SV *runtime_sv
    SV *bundle_sv
    SV *root_value
    SV *context_value
    SV *variables
  CODE:
    {
      gql_runtime_vm_native_bundle_t *bundle;
      gql_runtime_vm_native_runtime_t *runtime;
      SV *runtime_schema_sv;

      if (!runtime_sv || !SvROK(runtime_sv) || !sv_derived_from(runtime_sv, "GraphQL::Houtou::Runtime::NativeRuntime")) {
        croak("expected a GraphQL::Houtou::Runtime::NativeRuntime");
      }
      runtime = INT2PTR(gql_runtime_vm_native_runtime_t *, SvUV(SvRV(runtime_sv)));
      if (!runtime) {
        croak("native VM runtime handle is no longer valid");
      }
      if (!bundle_sv || !SvROK(bundle_sv) || !sv_derived_from(bundle_sv, "GraphQL::Houtou::Runtime::NativeBundle")) {
        croak("expected a GraphQL::Houtou::Runtime::NativeBundle");
      }
      bundle = INT2PTR(gql_runtime_vm_native_bundle_t *, SvUV(SvRV(bundle_sv)));
      if (!bundle) {
        croak("native VM bundle handle is no longer valid");
      }
      runtime_schema_sv = (runtime && runtime->callback_catalog && runtime->callback_catalog->runtime_schema)
        ? runtime->callback_catalog->runtime_schema
        : &PL_sv_undef;
      RETVAL = gql_runtime_vm_execute_bundle_fast_response_json(
        aTHX_
        runtime,
        runtime_schema_sv,
        bundle,
        root_value,
        context_value,
        variables
      );
    }
  OUTPUT:
    RETVAL

SV *
execute_native_program_auto_xs(runtime_sv, program_sv, root_value = &PL_sv_undef, context_value = &PL_sv_undef, variables = &PL_sv_undef)
    SV *runtime_sv
    SV *program_sv
    SV *root_value
    SV *context_value
    SV *variables
  CODE:
    {
      RETVAL = gql_runtime_vm_execute_native_program_auto_sv(
        aTHX_
        runtime_sv,
        program_sv,
        root_value,
        context_value,
        variables
      );
    }
  OUTPUT:
    RETVAL

SV *
execute_native_program_auto_simple_xs(runtime_sv, program_sv)
    SV *runtime_sv
    SV *program_sv
  CODE:
    {
      RETVAL = gql_runtime_vm_execute_native_program_auto_sv(
        aTHX_
        runtime_sv,
        program_sv,
        &PL_sv_undef,
        &PL_sv_undef,
        &PL_sv_undef
      );
    }
  OUTPUT:
    RETVAL

SV *
execute_native_program_auto_to_json_xs(runtime_sv, program_sv, root_value = &PL_sv_undef, context_value = &PL_sv_undef, variables = &PL_sv_undef)
    SV *runtime_sv
    SV *program_sv
    SV *root_value
    SV *context_value
    SV *variables
  CODE:
    {
      RETVAL = gql_runtime_vm_execute_native_program_auto_json_sv(
        aTHX_
        runtime_sv,
        program_sv,
        root_value,
        context_value,
        variables
      );
    }
  OUTPUT:
    RETVAL

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::Cursor

void
DESTROY(self)
    SV *self
  CODE:
      if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_cursor_t *cursor = INT2PTR(gql_runtime_vm_cursor_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_runtime_vm_cursor_decref(aTHX_ cursor);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::FieldFrame

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_field_frame_t *frame = INT2PTR(gql_runtime_vm_field_frame_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_runtime_vm_free_field_frame(aTHX_ frame);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::LazyInfo

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_lazy_info_t *info = INT2PTR(gql_runtime_vm_lazy_info_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_runtime_vm_lazy_info_decref(aTHX_ info);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::PathFrame

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_path_frame_t *frame = INT2PTR(gql_runtime_vm_path_frame_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_runtime_vm_path_frame_decref(frame);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::BlockFrame

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_block_frame_t *frame = INT2PTR(gql_runtime_vm_block_frame_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_runtime_vm_free_block_frame(aTHX_ frame);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::ListPending

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_list_pending_t *pending = INT2PTR(gql_runtime_vm_list_pending_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_runtime_vm_list_pending_decref(aTHX_ pending);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::ErrorRecord

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_error_record_t *record = INT2PTR(gql_runtime_vm_error_record_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_runtime_vm_error_record_decref(aTHX_ record);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::Outcome

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_outcome_t *outcome = INT2PTR(gql_runtime_vm_outcome_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_runtime_vm_outcome_decref(aTHX_ outcome);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::Writer

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_writer_t *writer = INT2PTR(gql_runtime_vm_writer_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_runtime_vm_writer_decref(aTHX_ writer);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::PendingMerge

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_pending_merge_t *merge = INT2PTR(gql_runtime_vm_pending_merge_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_runtime_vm_pending_merge_decref(aTHX_ merge);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::ExecState

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_exec_state_handle_t *state = INT2PTR(gql_runtime_vm_exec_state_handle_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        SvREFCNT_dec(state->runtime_schema);
        SvREFCNT_dec(state->program);
        if (state->native_runtime && !state->native_runtime_is_borrowed) {
          gql_runtime_vm_native_runtime_destroy(state->native_runtime);
        }
        gql_runtime_vm_cursor_decref(aTHX_ state->cursor);
        /* A suspended response frame lives only in response_frame: the
         * scheduler popped it off frame_stack, and resolve_frame (which
         * pairs the field's NULLing with releasing the allocation
         * reference) never ran for an abandoned request. Release that
         * reference here - unless the frame is still on the stack, whose
         * teardown below owns it (R5 leak 2). */
        if (state->response_frame) {
          IV rf_i;
          int rf_on_stack = (state->frame == state->response_frame);
          for (rf_i = 0; !rf_on_stack && rf_i < state->frame_stack_count; rf_i++) {
            rf_on_stack = (state->frame_stack[rf_i] == state->response_frame);
          }
          if (!rf_on_stack) {
            gql_runtime_vm_free_block_frame(aTHX_ state->response_frame);
          }
          state->response_frame = NULL;
        }
        if (state->frame && state->frame_stack_count == 0) {
          gql_runtime_vm_free_block_frame(aTHX_ state->frame);
        }
        while (state->frame_stack_count > 0) {
          gql_runtime_vm_free_block_frame(aTHX_ state->frame_stack[--state->frame_stack_count]);
          state->frame_stack[state->frame_stack_count] = NULL;
        }
        Safefree(state->frame_stack);
        Safefree(state->async_ready_frames);
        state->frame = NULL;
        gql_runtime_vm_free_field_frame(aTHX_ state->field_frame);
        state->field_frame = NULL;
        gql_runtime_vm_writer_decref(aTHX_ state->writer);
        SvREFCNT_dec(state->context);
        SvREFCNT_dec(state->variables);
        SvREFCNT_dec(state->root_value);
        SvREFCNT_dec(state->empty_args);
        SvREFCNT_dec(state->completed_response_sv);
        Safefree(state);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::NativeBundle

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_native_bundle_t *bundle =
          INT2PTR(gql_runtime_vm_native_bundle_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_runtime_vm_native_bundle_destroy(bundle);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::NativeProgram

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_native_program_t *program =
          INT2PTR(gql_runtime_vm_native_program_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_runtime_vm_native_program_destroy(program);
      }
    }

MODULE = GraphQL::Houtou    PACKAGE = GraphQL::Houtou::Runtime::NativeRuntime

void
DESTROY(self)
    SV *self
  CODE:
    if (self && SvROK(self)) {
      SV *inner_sv = SvRV(self);
      if (SvIOK(inner_sv) && SvUV(inner_sv) != 0) {
        gql_runtime_vm_native_runtime_t *runtime =
          INT2PTR(gql_runtime_vm_native_runtime_t *, SvUV(inner_sv));
        sv_setuv(inner_sv, 0);
        gql_runtime_vm_native_runtime_destroy(runtime);
      }
    }
