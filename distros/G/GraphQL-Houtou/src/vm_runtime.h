#ifndef GQL_RUNTIME_VM_H
#define GQL_RUNTIME_VM_H

#include <stdlib.h>

enum {
  GQL_VM_RESOLVE_DEFAULT = 1,
  GQL_VM_RESOLVE_EXPLICIT = 2
};

enum {
  GQL_VM_COMPLETE_GENERIC = 1,
  GQL_VM_COMPLETE_OBJECT = 2,
  GQL_VM_COMPLETE_LIST = 3,
  GQL_VM_COMPLETE_ABSTRACT = 4
};

enum {
  GQL_VM_FAMILY_GENERIC = 1,
  GQL_VM_FAMILY_OBJECT = 2,
  GQL_VM_FAMILY_LIST = 3,
  GQL_VM_FAMILY_ABSTRACT = 4
};

enum {
  GQL_VM_DISPATCH_GENERIC = 1,
  GQL_VM_DISPATCH_RESOLVE_TYPE = 2,
  GQL_VM_DISPATCH_TAG = 3,
  GQL_VM_DISPATCH_POSSIBLE_TYPES = 4
};

enum {
  GQL_VM_ARGS_NONE = 0,
  GQL_VM_ARGS_STATIC = 1,
  GQL_VM_ARGS_DYNAMIC = 2
};

enum {
  GQL_VM_KIND_UNKNOWN = 0,
  GQL_VM_KIND_SCALAR = 1,
  GQL_VM_KIND_OBJECT = 2,
  GQL_VM_KIND_LIST = 3,
  GQL_VM_KIND_INTERFACE = 4,
  GQL_VM_KIND_UNION = 5,
  GQL_VM_KIND_ENUM = 6,
  GQL_VM_KIND_INPUT_OBJECT = 7,
  GQL_VM_KIND_NON_NULL = 8
};

enum {
  GQL_VM_OPTYPE_QUERY = 1,
  GQL_VM_OPTYPE_MUTATION = 2,
  GQL_VM_OPTYPE_SUBSCRIPTION = 3
};

enum {
  GQL_VM_GUARD_INCLUDE = 1,
  GQL_VM_GUARD_SKIP = 2
};

enum {
  GQL_VM_CALLBACK_ABI_DEFAULT = 1,
  GQL_VM_CALLBACK_ABI_EXPLICIT_GENERIC = 2,
  GQL_VM_CALLBACK_ABI_EXPLICIT_NATIVE = 3
};

enum {
  GQL_VM_DYNAMIC_UNDEF = 0,
  GQL_VM_DYNAMIC_SCALAR = 1,
  GQL_VM_DYNAMIC_VARIABLE = 2,
  GQL_VM_DYNAMIC_LIST = 3,
  GQL_VM_DYNAMIC_OBJECT = 4
};

#define GQL_VM_OPCODE(resolve_code, complete_code) (((resolve_code) * 16) + (complete_code))

typedef struct gql_runtime_vm_native_value gql_runtime_vm_native_value_t;
typedef struct gql_runtime_vm_native_dynamic_value gql_runtime_vm_native_dynamic_value_t;
typedef struct gql_runtime_vm_list_pending_t gql_runtime_vm_list_pending_t;

typedef struct {
  char *name;
  SV *type_def_sv;
  SV *input_type_sv;
  U8 has_default;
  /* Lazily cached isa(NonNull) of input_type_sv so the missing-variable
   * check costs no method lookup per request: 0 unknown, 1 non-null,
   * 2 nullable. Newxz zero-fill leaves fresh defs at "unknown". */
  U8 input_type_nonnull_state;
  SV *default_value_sv;
  gql_runtime_vm_native_value_t *default_native_value;
} gql_runtime_vm_native_arg_def_t;

typedef struct {
  IV count;
  char **names;
  gql_runtime_vm_native_dynamic_value_t **values;
  SV *static_args_sv;
} gql_runtime_vm_native_args_payload_t;

typedef struct {
  IV kind_code;
  gql_runtime_vm_native_dynamic_value_t *if_expr;
} gql_runtime_vm_native_guard_t;

typedef struct {
  IV count;
  gql_runtime_vm_native_guard_t *guards;
} gql_runtime_vm_native_directives_payload_t;

typedef struct {
  char *field_name;
  STRLEN field_name_len;
  char *result_name;
  STRLEN result_name_len;
  char *return_type_name;
  IV schema_slot_index;
  IV resolver_shape_code;
  IV resolver_mode_code;
  IV callback_abi_code;
  IV completion_family_code;
  IV dispatch_family_code;
  IV return_type_kind_code;
  IV arg_def_count;
  gql_runtime_vm_native_arg_def_t *arg_defs;
  U8 has_args;
  U8 has_directives;
  /* Non-Null propagation (spec 6.4.4): return_type_kind_code == 8 marks
   * the field position itself non-null; item_non_null marks a list
   * field's item positions ([T!]). */
  U8 item_non_null;
} gql_runtime_vm_native_slot_t;

typedef struct {
  char *tag_name;
  char *type_name;
} gql_runtime_vm_native_tag_entry_t;

typedef struct {
  char *type_name;
  SV *type_sv;
  SV *is_type_of_cb;
} gql_runtime_vm_native_possible_type_entry_t;

/* Leaf result coercion kinds, shared with Schema::prepare_runtime's
 * leaf_kind_map. 0 = not a leaf type (or unknown: no coercion). */
#define GQL_VM_LEAF_NONE 0
#define GQL_VM_LEAF_INT 1
#define GQL_VM_LEAF_FLOAT 2
#define GQL_VM_LEAF_STRING 3
#define GQL_VM_LEAF_BOOLEAN 4
#define GQL_VM_LEAF_ID 5
#define GQL_VM_LEAF_ENUM 6
#define GQL_VM_LEAF_CUSTOM 7

typedef struct {
  SV *runtime_schema;
  SV **slot_field_names;
  SV **slot_resolvers;
  SV **slot_type_objects;
  SV **slot_tag_resolvers;
  SV **slot_resolve_types;
  gql_runtime_vm_native_tag_entry_t **slot_tag_entries;
  IV *slot_tag_entry_counts;
  gql_runtime_vm_native_possible_type_entry_t **slot_possible_type_entries;
  IV *slot_possible_type_entry_counts;
  /* Leaf result coercion per slot: kind code, and for ENUM the
   * value-to-name HV ref / for CUSTOM the serialize CV. */
  IV *slot_leaf_kinds;
  SV **slot_leaf_payloads;
} gql_runtime_vm_native_callback_catalog_t;

typedef struct {
  char **abstract_child_names;
  IV *abstract_child_indexes;
  IV opcode_code;
  IV resolve_code;
  IV complete_code;
  IV dispatch_family_code;
  IV slot_index;
  IV child_block_index;
  IV abstract_child_count;
  IV args_mode_code;
  IV directives_mode_code;
  IV args_payload_index;
  IV directives_payload_index;
  gql_runtime_vm_native_args_payload_t *args_payload_native;
  gql_runtime_vm_native_directives_payload_t *directives_payload_native;
  U8 has_args;
  U8 has_directives;
  IV runtime_directives_mode_code;
  SV *runtime_directives_sv;
  U8 has_runtime_directives;
} gql_runtime_vm_native_op_t;

typedef struct {
  IV family_code;
  char *type_name;
  SV *type_object_sv;
  IV slot_count;
  IV op_count;
  gql_runtime_vm_native_slot_t *slots;
  gql_runtime_vm_native_op_t *ops;
} gql_runtime_vm_native_block_t;

typedef struct {
  IV runtime_slot_count;
  gql_runtime_vm_native_slot_t *runtime_slots;
  gql_runtime_vm_native_callback_catalog_t *callback_catalog;
} gql_runtime_vm_native_runtime_t;

typedef struct {
  IV operation_type_code;
  IV root_block_index;
  IV runtime_slot_count;
  IV block_count;
  U8 owns_runtime_slots;
  U8 owns_blocks;
  SV *prepared_runtime_schema;
  gql_runtime_vm_native_slot_t *runtime_slots;
  gql_runtime_vm_native_block_t *blocks;
} gql_runtime_vm_native_bundle_t;

typedef struct {
  IV version;
  char *operation_name;
  IV operation_type_code;
  IV root_block_index;
  IV variable_def_count;
  IV block_count;
  IV args_payload_count;
  IV directives_payload_count;
  gql_runtime_vm_native_arg_def_t *variable_defs;
  gql_runtime_vm_native_block_t *blocks;
  gql_runtime_vm_native_args_payload_t **args_payloads;
  gql_runtime_vm_native_directives_payload_t **directives_payloads;
  gql_runtime_vm_native_runtime_t *cached_bundle_runtime;
  gql_runtime_vm_native_bundle_t *cached_bundle;
  /* 0 = not computed yet, 1 = no, 2 = yes: whether any op carries runtime
   * directives or variable-dependent directive guards, i.e. whether
   * per-request program specialization is required at all. Zero-init via
   * Newxz means "not computed". */
  IV needs_variable_specialization;
} gql_runtime_vm_native_program_t;

typedef struct gql_runtime_vm_path_frame gql_runtime_vm_path_frame_t;
typedef struct gql_runtime_vm_outcome gql_runtime_vm_outcome_t;
typedef struct gql_runtime_vm_cursor_t gql_runtime_vm_cursor_t;
typedef struct gql_runtime_vm_field_frame_t gql_runtime_vm_field_frame_t;
typedef struct gql_runtime_vm_block_frame_t gql_runtime_vm_block_frame_t;
typedef struct gql_runtime_vm_writer_t gql_runtime_vm_writer_t;
typedef struct gql_runtime_vm_pending_entry_t gql_runtime_vm_pending_entry_t;
typedef struct gql_runtime_vm_callback_context gql_runtime_vm_callback_context_t;
typedef struct gql_runtime_vm_lazy_info gql_runtime_vm_lazy_info_t;

struct gql_runtime_vm_callback_context {
  SV *runtime_schema;
  SV *program;
  SV *context;
  SV *variables;
  SV *root_value;
};

typedef struct {
  gql_runtime_vm_native_runtime_t *runtime;
  gql_runtime_vm_native_bundle_t *bundle;
  gql_runtime_vm_callback_context_t *callback_ctx;
  gql_runtime_vm_path_frame_t *path_frame;
  int path_frame_is_current_field;
  SV *empty_args_sv;
  gql_runtime_vm_writer_t *writer;
  const gql_runtime_vm_native_block_t *block;
  const gql_runtime_vm_native_op_t *op;
  const gql_runtime_vm_native_slot_t *slot;
  IV block_index;
  IV op_index;
  /* Non-Null propagation scratch: set when a block/list just nulled
   * itself over a non-null violation (the field error is already
   * recorded), consumed by the enclosing field/item check so propagation
   * does not add one error per level. */
  U8 null_carries_error;
  /* Deferred croak channel for the sync fast lanes: croaking from inside
   * the lane longjmps past the recursion that owns the live path frame
   * chain and leaks it. Detection sites (promise-returning resolver,
   * request-time argument coercion failure) store the first error here
   * instead - a plain string croaks as an exception, a blessed
   * GraphQL::Houtou::Error becomes a request-error envelope at the Perl
   * boundary - and the top-level entry croak_sv()s it after cleanup. */
  SV *fast_lane_deferred_croak_sv;
} gql_runtime_vm_exec_state_t;

enum {
  GQL_VM_NATIVE_VALUE_UNDEF = 0,
  GQL_VM_NATIVE_VALUE_SCALAR = 1,
  GQL_VM_NATIVE_VALUE_OBJECT = 2,
  GQL_VM_NATIVE_VALUE_LIST = 3
};

enum {
  GQL_VM_NATIVE_SCALAR_UNDEF = 0,
  GQL_VM_NATIVE_SCALAR_IV = 1,
  GQL_VM_NATIVE_SCALAR_NV = 2,
  GQL_VM_NATIVE_SCALAR_PV = 3,
  GQL_VM_NATIVE_SCALAR_FALLBACK_SV = 4
};

typedef struct {
  char **names;
  /* Parallel to names: 1 marks a field name borrowed from the execution
   * plan (plan strings outlive every value of the request), 0 an owned
   * savepv copy that destroy must free. */
  U8 *names_borrowed;
  gql_runtime_vm_native_value_t **values;
  IV count;
  IV capacity;
} gql_runtime_vm_native_object_t;

typedef struct {
  gql_runtime_vm_native_value_t **items;
  IV count;
  IV capacity;
} gql_runtime_vm_native_list_t;

struct gql_runtime_vm_native_value {
  U8 kind_code;
  U8 scalar_kind_code;
  IV scalar_iv;
  NV scalar_nv;
  char *scalar_pv;
  STRLEN scalar_pv_len;
  SV *scalar_fallback_sv;
  gql_runtime_vm_native_object_t object;
  gql_runtime_vm_native_list_t list;
  gql_runtime_vm_native_value_t *pool_next;
};

struct gql_runtime_vm_native_dynamic_value {
  U8 kind_code;
  U8 scalar_kind_code;
  IV scalar_iv;
  NV scalar_nv;
  char *scalar_pv;
  STRLEN scalar_pv_len;
  char *variable_name;
  IV object_count;
  char **object_names;
  gql_runtime_vm_native_dynamic_value_t **object_values;
  IV list_count;
  gql_runtime_vm_native_dynamic_value_t **list_values;
};

typedef struct {
  SV *runtime_schema;
  SV *program;
  gql_runtime_vm_native_runtime_t *native_runtime;
  U8 native_runtime_is_borrowed;
  gql_runtime_vm_native_program_t *native_program;
  gql_runtime_vm_cursor_t *cursor;
  gql_runtime_vm_block_frame_t *frame;
  IV frame_stack_count;
  IV frame_stack_capacity;
  gql_runtime_vm_block_frame_t **frame_stack;
  gql_runtime_vm_field_frame_t *field_frame;
  gql_runtime_vm_writer_t *writer;
  SV *context;
  SV *variables;
  SV *root_value;
  U8 promise_backend_code;
  SV *empty_args;
  IV async_ready_frame_count;
  IV async_ready_frame_capacity;
  gql_runtime_vm_block_frame_t **async_ready_frames;
  U8 async_scheduler_draining;
  /* The first block frame pushed for the request. Only this frame's
   * deferred resolves the response envelope; child frames finalized during
   * late promise continuations may momentarily be the only stack entry,
   * so frame_stack_count is not a safe root signal. */
  gql_runtime_vm_block_frame_t *response_frame;
  /* When set, the response frame resolves its deferred with UTF-8 JSON
   * bytes (rendered from the native value tree) instead of the Perl
   * envelope hash. */
  U8 response_json_mode;
  /* Set by resolve_frame when the response frame completes without a
   * deferred: the request finished inside the original execute call, so
   * the execute entry point hands this back directly instead of routing
   * the response through a deferred/promise pair. */
  SV *completed_response_sv;
} gql_runtime_vm_exec_state_handle_t;

struct gql_runtime_vm_cursor_t {
  UV refcount;
  gql_runtime_vm_native_program_t *native_program;
  IV block_index;
  IV slot_index;
  IV op_index;
};

struct gql_runtime_vm_field_frame_t {
  UV refcount;
  SV *source;
  gql_runtime_vm_path_frame_t *path_frame;
  SV *resolved_value;
  gql_runtime_vm_outcome_t *outcome;
  U8 source_is_runtime_owned;
  U8 storage_is_stack;
};

struct gql_runtime_vm_path_frame {
  UV refcount;
  struct gql_runtime_vm_path_frame *parent;
  IV key_kind;
  IV key_iv;
  char *key_pv;
  STRLEN key_pv_len;
  U8 key_pv_borrowed;
};

typedef struct {
  UV refcount;
  char *message_pv;
  gql_runtime_vm_path_frame_t *path_frame;
} gql_runtime_vm_error_record_t;

struct gql_runtime_vm_list_pending_t {
  UV refcount;
  gql_runtime_vm_block_frame_t *owner_frame;
  gql_runtime_vm_native_value_t *values_value;
  IV unresolved_count;
};

struct gql_runtime_vm_block_frame_t {
  UV refcount;
  gql_runtime_vm_native_value_t *values_value;
  IV pending_count;
  IV pending_capacity;
  IV pending_unresolved;
  gql_runtime_vm_pending_entry_t *pending_entries;
  gql_runtime_vm_block_frame_t *parent_frame;
  IV parent_entry_index;
  SV *deferred_sv;
  SV *promise_sv;
  U8 queued;
  U8 deferred_resolves_response;
  /* Non-Null propagation (spec 6.4.4): set when one of this frame's
   * non-null fields resolved to null. The frame then resolves to null
   * instead of its object; the originating "Cannot return null" error is
   * already recorded, so the null propagates without stacking errors. */
  U8 self_nulled;
};

enum {
  GQL_VM_PENDING_PROMISE_SV = 1,
  GQL_VM_PENDING_OUTCOME_PTR = 2,
  GQL_VM_PENDING_PROMISE_GENERIC_VALUE_SV = 3,
  GQL_VM_PENDING_PROMISE_RESOLVED_VALUE_SV = 4,
  GQL_VM_PENDING_BLOCK_FRAME_PTR = 5,
  GQL_VM_PENDING_LIST_PENDING_PTR = 6,
};

enum {
  GQL_VM_PENDING_STATE_WAITING_UNARMED = 1,
  GQL_VM_PENDING_STATE_WAITING_ARMED = 2,
  GQL_VM_PENDING_STATE_READY_SV = 3,
  GQL_VM_PENDING_STATE_READY_OUTCOME = 4
};

struct gql_runtime_vm_pending_entry_t {
  char *result_name_pv;
  STRLEN result_name_len;
  gql_runtime_vm_path_frame_t *path_frame;
  IV block_index;
  IV slot_index;
  IV op_index;
  /* Armed then-callback contexts (resolve/reject arms) hold this entry's
   * index by value; when process_frame re-pushes a still-waiting entry
   * into the rebuilt pending array its index shifts, and these borrowed
   * pointers (owned by the callback CVs) let the move retarget them.
   * A settle through a stale index is silently dropped by the callbacks'
   * bounds check, deadlocking the frame. */
  void *armed_resolve_ctx;
  void *armed_reject_ctx;
  U8 result_name_pv_borrowed;
  U8 payload_kind;
  U8 state_code;
  union {
    SV *promise_sv;
    gql_runtime_vm_outcome_t *outcome_ptr;
    gql_runtime_vm_block_frame_t *block_frame_ptr;
    gql_runtime_vm_list_pending_t *list_pending_ptr;
  } payload;
};

struct gql_runtime_vm_outcome {
  UV refcount;
  U8 kind_code;
  gql_runtime_vm_native_value_t *value;
  IV error_record_count;
  gql_runtime_vm_error_record_t **error_records;
  struct gql_runtime_vm_outcome *pool_next;
  /* Non-Null propagation: set on a null outcome whose originating
   * "Cannot return null" (or field) error is already recorded, so a
   * parent nulling itself over this value adds no further error. */
  U8 null_carries_error;
};

struct gql_runtime_vm_writer_t {
  UV refcount;
  IV error_record_count;
  IV error_record_capacity;
  gql_runtime_vm_error_record_t **error_records;
};

struct gql_runtime_vm_lazy_info {
  UV refcount;
  SV *field_name_sv;
  char *field_name_pv;
  SV *parent_type_sv;
  char *parent_type_name_pv;
  char *return_type_name_pv;
  SV *return_type_sv;
  gql_runtime_vm_path_frame_t *path_frame;
  SV *context_value;
  SV *root_value;
  SV *variable_values;
  SV *operation;
  SV *runtime_schema;
  SV *directives;
  IV block_index;
  IV op_index;
  SV *materialized_sv;
};

static AV *gql_runtime_vm_expect_op_array(pTHX_ SV *op_sv);
static SV *gql_runtime_vm_op_slot_sv(pTHX_ SV *op_sv, IV index);
static const gql_runtime_vm_native_block_t *gql_runtime_vm_cursor_current_native_block(const gql_runtime_vm_cursor_t *cursor);
static const gql_runtime_vm_native_op_t *gql_runtime_vm_cursor_current_native_op(const gql_runtime_vm_cursor_t *cursor);
static const gql_runtime_vm_native_slot_t *gql_runtime_vm_cursor_current_native_slot(const gql_runtime_vm_cursor_t *cursor);
static SV *gql_runtime_vm_new_handle_sv(pTHX_ const char *pkg, void *ptr);
static SV *gql_runtime_vm_fetch_hash_entry_sv(pTHX_ HV *hv, const char *key, I32 keylen);
static gql_runtime_vm_cursor_t *gql_runtime_vm_expect_cursor(pTHX_ SV *self);
static gql_runtime_vm_error_record_t *gql_runtime_vm_expect_error_record(pTHX_ SV *self);
static gql_runtime_vm_outcome_t *gql_runtime_vm_expect_outcome(pTHX_ SV *self);
static void gql_runtime_vm_free_block_frame(pTHX_ gql_runtime_vm_block_frame_t *frame);
static void gql_runtime_vm_error_record_incref(gql_runtime_vm_error_record_t *record);
static void gql_runtime_vm_error_record_decref(pTHX_ gql_runtime_vm_error_record_t *record);
static void gql_runtime_vm_outcome_incref(gql_runtime_vm_outcome_t *outcome);
static void gql_runtime_vm_outcome_decref(pTHX_ gql_runtime_vm_outcome_t *outcome);
static void gql_runtime_vm_list_pending_decref(pTHX_ gql_runtime_vm_list_pending_t *pending);
static void gql_runtime_vm_writer_push_error_record(gql_runtime_vm_writer_t *writer, gql_runtime_vm_error_record_t *record);
static void gql_runtime_vm_block_frame_push_pending_pvn(
  pTHX_
  gql_runtime_vm_block_frame_t *frame,
  const char *result_name_pv,
  STRLEN result_name_len,
  SV *outcome
);
static void gql_runtime_vm_block_frame_push_pending_pvn_with_meta(
  pTHX_
  gql_runtime_vm_block_frame_t *frame,
  const char *result_name_pv,
  STRLEN result_name_len,
  U8 result_name_pv_borrowed,
  SV *outcome,
  U8 payload_kind,
  gql_runtime_vm_path_frame_t *path_frame,
  IV block_index,
  IV slot_index,
  IV op_index
);
static gql_runtime_vm_pending_entry_t *gql_runtime_vm_block_frame_push_pending_entry_with_meta(
  pTHX_
  gql_runtime_vm_block_frame_t *frame,
  const char *result_name_pv,
  STRLEN result_name_len,
  U8 result_name_pv_borrowed,
  gql_runtime_vm_path_frame_t *path_frame,
  IV block_index,
  IV slot_index,
  IV op_index
);
static void gql_runtime_vm_block_frame_push_pending(pTHX_ gql_runtime_vm_block_frame_t *frame, SV *result_name, SV *outcome);
static void gql_runtime_vm_block_frame_clear_pending(pTHX_ gql_runtime_vm_block_frame_t *frame);
static void gql_runtime_vm_path_frame_decref(gql_runtime_vm_path_frame_t *frame);
static SV *gql_runtime_vm_call_cb4_nonfatal(pTHX_ SV *cb, SV *arg0, SV *arg1, SV *arg2, SV *arg3, SV **error_out);
static SV *gql_runtime_vm_call_cb5_nonfatal(pTHX_ SV *cb, SV *arg0, SV *arg1, SV *arg2, SV *arg3, SV *arg4, SV **error_out);
static SV *gql_runtime_vm_new_callback_info_sv(pTHX_ const gql_runtime_vm_exec_state_t *state);
static gql_runtime_vm_native_value_t *gql_runtime_vm_new_native_value_scalar(pTHX_ SV *value);
static gql_runtime_vm_native_value_t *gql_runtime_vm_new_native_value_object(void);
static gql_runtime_vm_native_value_t *gql_runtime_vm_new_native_value_list(void);
static void gql_runtime_vm_native_object_store(pTHX_ gql_runtime_vm_native_value_t *value, const char *name, U8 name_borrowed, gql_runtime_vm_native_value_t *child);
static void gql_runtime_vm_native_list_push(gql_runtime_vm_native_value_t *value, gql_runtime_vm_native_value_t *child);
static void gql_runtime_vm_native_value_destroy(pTHX_ gql_runtime_vm_native_value_t *value);
static SV *gql_runtime_vm_native_value_materialize_sv(pTHX_ gql_runtime_vm_native_value_t *value);
static gql_runtime_vm_native_value_t *gql_runtime_vm_native_value_from_sv(pTHX_ SV *value);
static gql_runtime_vm_native_value_t *gql_runtime_vm_native_value_clone(pTHX_ const gql_runtime_vm_native_value_t *value);
static gql_runtime_vm_native_dynamic_value_t *gql_runtime_vm_native_dynamic_value_from_sv(pTHX_ SV *value);
static gql_runtime_vm_native_dynamic_value_t *gql_runtime_vm_native_dynamic_value_from_native_value(
  pTHX_ const gql_runtime_vm_native_value_t *value
);
static gql_runtime_vm_native_dynamic_value_t *gql_runtime_vm_native_dynamic_value_clone(
  pTHX_ const gql_runtime_vm_native_dynamic_value_t *value
);
static void gql_runtime_vm_native_dynamic_value_destroy(
  pTHX_ gql_runtime_vm_native_dynamic_value_t *value
);
static SV *gql_runtime_vm_native_dynamic_value_materialize_sv(
  pTHX_ const gql_runtime_vm_native_dynamic_value_t *value,
  HV *variables
);
static int gql_runtime_vm_native_dynamic_value_truthy(
  pTHX_ const gql_runtime_vm_native_dynamic_value_t *value,
  HV *variables
);
static const gql_runtime_vm_native_dynamic_value_t *gql_runtime_vm_native_args_payload_lookup_value(
  const gql_runtime_vm_native_args_payload_t *payload,
  const char *arg_name,
  IV hint_index
);
static gql_runtime_vm_native_args_payload_t *gql_runtime_vm_native_args_payload_from_hv(pTHX_ HV *hv);
static gql_runtime_vm_native_args_payload_t *gql_runtime_vm_native_args_payload_clone(
  pTHX_ const gql_runtime_vm_native_args_payload_t *payload
);
static void gql_runtime_vm_native_args_payload_destroy(pTHX_ gql_runtime_vm_native_args_payload_t *payload);
static SV *gql_runtime_vm_native_args_payload_materialize_sv(
  pTHX_ const gql_runtime_vm_native_args_payload_t *payload
);
static SV *gql_runtime_vm_native_args_payload_materialize_cached_sv(
  pTHX_ gql_runtime_vm_native_args_payload_t *payload
);
static gql_runtime_vm_native_directives_payload_t *gql_runtime_vm_native_directives_payload_from_sv(
  pTHX_ SV *guards_sv
);
static gql_runtime_vm_native_directives_payload_t *gql_runtime_vm_native_directives_payload_clone(
  pTHX_ const gql_runtime_vm_native_directives_payload_t *payload
);
static void gql_runtime_vm_native_directives_payload_destroy(
  pTHX_ gql_runtime_vm_native_directives_payload_t *payload
);
static int gql_runtime_vm_evaluate_runtime_guards_native(
  pTHX_ const gql_runtime_vm_native_directives_payload_t *payload,
  HV *variables
);
static gql_runtime_vm_native_args_payload_t *gql_runtime_vm_specialize_arg_payload_native(
  pTHX_
  const gql_runtime_vm_native_runtime_t *runtime,
  const gql_runtime_vm_native_slot_t *slot,
  const gql_runtime_vm_native_op_t *op,
  HV *variables_hv
);
static IV gql_runtime_vm_infer_callback_abi_code(IV resolver_shape_code, IV resolver_mode_code);
static const gql_runtime_vm_native_slot_t *gql_runtime_vm_effective_slot(
  const gql_runtime_vm_native_runtime_t *runtime,
  const gql_runtime_vm_native_slot_t *slot
);
static int gql_runtime_vm_sv_to_hv(pTHX_ SV *sv, HV **out);
static int gql_runtime_vm_sv_to_av(pTHX_ SV *sv, AV **out);
static void gql_runtime_vm_free_native_arg_defs(pTHX_ gql_runtime_vm_native_arg_def_t *arg_defs, IV count);

static AV *
gql_runtime_vm_expect_op_array(pTHX_ SV *op_sv)
{
  if (!op_sv || !SvOK(op_sv) || !SvROK(op_sv) || SvTYPE(SvRV(op_sv)) != SVt_PVAV) {
    return NULL;
  }
  return (AV *)SvRV(op_sv);
}

static SV *
gql_runtime_vm_op_slot_sv(pTHX_ SV *op_sv, IV index)
{
  AV *op_av = gql_runtime_vm_expect_op_array(aTHX_ op_sv);
  SV **svp;

  if (!op_av) {
    return NULL;
  }

  svp = av_fetch(op_av, index, 0);
  return (svp && SvOK(*svp)) ? *svp : NULL;
}

static const gql_runtime_vm_native_block_t *
gql_runtime_vm_cursor_current_native_block(const gql_runtime_vm_cursor_t *cursor)
{
  if (!cursor || !cursor->native_program) {
    return NULL;
  }
  if (cursor->block_index < 0 || cursor->block_index >= cursor->native_program->block_count) {
    return NULL;
  }
  return &cursor->native_program->blocks[cursor->block_index];
}

static const gql_runtime_vm_native_op_t *
gql_runtime_vm_cursor_current_native_op(const gql_runtime_vm_cursor_t *cursor)
{
  const gql_runtime_vm_native_block_t *block = gql_runtime_vm_cursor_current_native_block(cursor);
  if (!block) {
    return NULL;
  }
  if (cursor->op_index < 0 || cursor->op_index >= block->op_count) {
    return NULL;
  }
  return &block->ops[cursor->op_index];
}

static const gql_runtime_vm_native_slot_t *
gql_runtime_vm_cursor_current_native_slot(const gql_runtime_vm_cursor_t *cursor)
{
  const gql_runtime_vm_native_block_t *block = gql_runtime_vm_cursor_current_native_block(cursor);
  if (!block) {
    return NULL;
  }
  if (cursor->slot_index < 0 || cursor->slot_index >= block->slot_count) {
    return NULL;
  }
  return &block->slots[cursor->slot_index];
}

/*
 * Free-list pool for native value nodes. The async lane allocates and
 * destroys one node per response field plus one per object/list container,
 * which made calloc/free the top self-time cost in profiles. Released nodes
 * park here with their object/list backing arrays intact (count reset,
 * capacity retained), so a reused container node also skips the Renew
 * doubling ramp. Nodes hold no SVs while pooled; the pool is process-global
 * like the cached stashes and is capped so idle memory stays bounded.
 */
#define GQL_RUNTIME_VM_NATIVE_VALUE_POOL_MAX 4096
static gql_runtime_vm_native_value_t *gql_runtime_vm_native_value_pool_head = NULL;
static IV gql_runtime_vm_native_value_pool_count = 0;

/* Outcome and path-frame structs are allocated once per field on the async
 * lane; they recycle through the same kind of capped free lists. Reused
 * structs are zeroed so the constructors keep their Newxz assumptions. */
#define GQL_RUNTIME_VM_OUTCOME_POOL_MAX 1024
static gql_runtime_vm_outcome_t *gql_runtime_vm_outcome_pool_head = NULL;
static IV gql_runtime_vm_outcome_pool_count = 0;

#define GQL_RUNTIME_VM_PATH_FRAME_POOL_MAX 1024
static gql_runtime_vm_path_frame_t *gql_runtime_vm_path_frame_pool_head = NULL;
static IV gql_runtime_vm_path_frame_pool_count = 0;

#define GQL_RUNTIME_VM_BLOCK_FRAME_POOL_MAX 256
static gql_runtime_vm_block_frame_t *gql_runtime_vm_block_frame_pool_head = NULL;
static IV gql_runtime_vm_block_frame_pool_count = 0;

/* Leak instrumentation: frames handed out minus frames released (a pooled
 * frame counts as released). A quiescent process must read zero; a positive
 * residue after a request fully completed is an orphaned frame. Exposed via
 * GraphQL::Houtou::XS::VM::debug_frame_live_counts_xs. */
static IV gql_runtime_vm_path_frame_live_count = 0;
static IV gql_runtime_vm_block_frame_live_count = 0;

static gql_runtime_vm_block_frame_t *
gql_runtime_vm_block_frame_pool_get(pTHX)
{
  /* Pooled block frames chain through their (dead) parent_frame pointer and
   * keep their pending_entries array so refills skip the Renew ramp. */
  gql_runtime_vm_block_frame_t *ret = gql_runtime_vm_block_frame_pool_head;
  gql_runtime_vm_block_frame_live_count++;
  if (ret) {
    gql_runtime_vm_pending_entry_t *entries = ret->pending_entries;
    IV capacity = ret->pending_capacity;
    gql_runtime_vm_block_frame_pool_head = ret->parent_frame;
    gql_runtime_vm_block_frame_pool_count--;
    Zero(ret, 1, gql_runtime_vm_block_frame_t);
    ret->pending_entries = entries;
    ret->pending_capacity = capacity;
    return ret;
  }
  Newxz(ret, 1, gql_runtime_vm_block_frame_t);
  return ret;
}

static gql_runtime_vm_outcome_t *
gql_runtime_vm_outcome_pool_get(pTHX)
{
  gql_runtime_vm_outcome_t *ret = gql_runtime_vm_outcome_pool_head;
  if (ret) {
    gql_runtime_vm_outcome_pool_head = ret->pool_next;
    gql_runtime_vm_outcome_pool_count--;
    Zero(ret, 1, gql_runtime_vm_outcome_t);
    return ret;
  }
  Newxz(ret, 1, gql_runtime_vm_outcome_t);
  return ret;
}

static gql_runtime_vm_path_frame_t *
gql_runtime_vm_path_frame_pool_get(pTHX)
{
  /* Pooled path frames chain through their (dead) parent pointer. */
  gql_runtime_vm_path_frame_t *ret = gql_runtime_vm_path_frame_pool_head;
  gql_runtime_vm_path_frame_live_count++;
  if (ret) {
    gql_runtime_vm_path_frame_pool_head = ret->parent;
    gql_runtime_vm_path_frame_pool_count--;
    Zero(ret, 1, gql_runtime_vm_path_frame_t);
    return ret;
  }
  Newxz(ret, 1, gql_runtime_vm_path_frame_t);
  return ret;
}

static gql_runtime_vm_native_value_t *
gql_runtime_vm_native_value_pool_get(U8 kind_code)
{
  gql_runtime_vm_native_value_t *ret = gql_runtime_vm_native_value_pool_head;
  if (ret) {
    gql_runtime_vm_native_value_pool_head = ret->pool_next;
    gql_runtime_vm_native_value_pool_count--;
    ret->pool_next = NULL;
    ret->kind_code = kind_code;
    return ret;
  }
  Newxz(ret, 1, gql_runtime_vm_native_value_t);
  ret->kind_code = kind_code;
  return ret;
}

static gql_runtime_vm_native_value_t *
gql_runtime_vm_new_native_value_scalar(pTHX_ SV *value)
{
  gql_runtime_vm_native_value_t *ret;
  ret = gql_runtime_vm_native_value_pool_get(GQL_VM_NATIVE_VALUE_SCALAR);
  ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_UNDEF;
  ret->scalar_iv = 0;
  ret->scalar_nv = 0.0;
  ret->scalar_pv = NULL;
  ret->scalar_pv_len = 0;
  ret->scalar_fallback_sv = NULL;
  if (!value || !SvOK(value)) {
    return ret;
  }
  if (SvROK(value) || SvMAGICAL(value)) {
    ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_FALLBACK_SV;
    ret->scalar_fallback_sv = newSVsv(value);
    return ret;
  }
  if (SvPOKp(value)) {
    STRLEN len = 0;
    const char *pv = SvPV(value, len);
    ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_PV;
    ret->scalar_pv = savepvn(pv, len);
    ret->scalar_pv_len = len;
    return ret;
  }
  if (SvIOKp(value)) {
    ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_IV;
    ret->scalar_iv = SvIV(value);
    return ret;
  }
  if (SvNOKp(value)) {
    ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_NV;
    ret->scalar_nv = SvNV(value);
    return ret;
  }
  ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_FALLBACK_SV;
  ret->scalar_fallback_sv = newSVsv(value);
  return ret;
}

static gql_runtime_vm_native_value_t *
gql_runtime_vm_new_native_value_object(void)
{
  return gql_runtime_vm_native_value_pool_get(GQL_VM_NATIVE_VALUE_OBJECT);
}

static gql_runtime_vm_native_value_t *
gql_runtime_vm_new_native_value_list(void)
{
  return gql_runtime_vm_native_value_pool_get(GQL_VM_NATIVE_VALUE_LIST);
}

static void
gql_runtime_vm_native_object_store(pTHX_ gql_runtime_vm_native_value_t *value, const char *name, U8 name_borrowed, gql_runtime_vm_native_value_t *child)
{
  gql_runtime_vm_native_object_t *object;
  if (!value || value->kind_code != GQL_VM_NATIVE_VALUE_OBJECT || !name || !child) {
    return;
  }
  object = &value->object;
  if (object->count == object->capacity) {
    IV new_capacity = object->capacity ? object->capacity * 2 : 8;
    Renew(object->names, new_capacity, char *);
    Renew(object->names_borrowed, new_capacity, U8);
    Renew(object->values, new_capacity, gql_runtime_vm_native_value_t *);
    object->capacity = new_capacity;
  }
  object->names[object->count] = name_borrowed ? (char *)name : savepv(name);
  object->names_borrowed[object->count] = name_borrowed ? 1 : 0;
  object->values[object->count] = child;
  object->count++;
}

static void
gql_runtime_vm_native_list_push(gql_runtime_vm_native_value_t *value, gql_runtime_vm_native_value_t *child)
{
  gql_runtime_vm_native_list_t *list;
  IV i;
  if (!value || value->kind_code != GQL_VM_NATIVE_VALUE_LIST || !child) {
    return;
  }
  list = &value->list;
  if (list->count == list->capacity) {
    IV new_capacity = list->capacity ? list->capacity * 2 : 8;
    Renew(list->items, new_capacity, gql_runtime_vm_native_value_t *);
    /* Entries at or beyond count must be NULL: destroy only clears up to
     * count before pooling the value, and a pooled reuse via the sparse
     * native_list_store_at treats any non-NULL slot as a live child to
     * destroy - an uninitialized slot there is a wild pointer. */
    for (i = list->capacity; i < new_capacity; i++) {
      list->items[i] = NULL;
    }
    list->capacity = new_capacity;
  }
  list->items[list->count] = child;
  list->count++;
}

static void
gql_runtime_vm_native_value_destroy(pTHX_ gql_runtime_vm_native_value_t *value)
{
  IV i;
  if (!value) {
    return;
  }
  switch (value->kind_code) {
    case GQL_VM_NATIVE_VALUE_SCALAR:
      switch (value->scalar_kind_code) {
        case GQL_VM_NATIVE_SCALAR_PV:
          Safefree(value->scalar_pv);
          break;
        case GQL_VM_NATIVE_SCALAR_FALLBACK_SV:
          SvREFCNT_dec(value->scalar_fallback_sv);
          break;
        default:
          break;
      }
      break;
    case GQL_VM_NATIVE_VALUE_OBJECT:
      /* Slots must go back to NULL: the retained arrays are reused with the
       * invariant that entries at or beyond count are empty (sparse
       * store_at fills rely on it to detect real overwrites). */
      for (i = 0; i < value->object.count; i++) {
        if (!value->object.names_borrowed || !value->object.names_borrowed[i]) {
          Safefree(value->object.names[i]);
        }
        value->object.names[i] = NULL;
        gql_runtime_vm_native_value_destroy(aTHX_ value->object.values[i]);
        value->object.values[i] = NULL;
      }
      value->object.count = 0;
      break;
    case GQL_VM_NATIVE_VALUE_LIST:
      for (i = 0; i < value->list.count; i++) {
        gql_runtime_vm_native_value_destroy(aTHX_ value->list.items[i]);
        value->list.items[i] = NULL;
      }
      value->list.count = 0;
      break;
  }
  value->scalar_kind_code = GQL_VM_NATIVE_SCALAR_UNDEF;
  value->scalar_pv = NULL;
  value->scalar_pv_len = 0;
  value->scalar_fallback_sv = NULL;
  if (gql_runtime_vm_native_value_pool_count < GQL_RUNTIME_VM_NATIVE_VALUE_POOL_MAX) {
    value->pool_next = gql_runtime_vm_native_value_pool_head;
    gql_runtime_vm_native_value_pool_head = value;
    gql_runtime_vm_native_value_pool_count++;
    return;
  }
  Safefree(value->object.names);
  Safefree(value->object.names_borrowed);
  Safefree(value->object.values);
  Safefree(value->list.items);
  Safefree(value);
}

static SV *
gql_runtime_vm_native_value_materialize_sv(pTHX_ gql_runtime_vm_native_value_t *value)
{
  IV i;
  if (!value) {
    return newSVsv(&PL_sv_undef);
  }
  switch (value->kind_code) {
    case GQL_VM_NATIVE_VALUE_OBJECT: {
      HV *hv = newHV();
      for (i = 0; i < value->object.count; i++) {
        hv_store(
          hv,
          value->object.names[i],
          (I32)strlen(value->object.names[i]),
          gql_runtime_vm_native_value_materialize_sv(aTHX_ value->object.values[i]),
          0
        );
      }
      return newRV_noinc((SV *)hv);
    }
    case GQL_VM_NATIVE_VALUE_LIST: {
      AV *av = newAV();
      av_extend(av, value->list.count > 0 ? value->list.count - 1 : 0);
      for (i = 0; i < value->list.count; i++) {
        av_store(av, i, gql_runtime_vm_native_value_materialize_sv(aTHX_ value->list.items[i]));
      }
      return newRV_noinc((SV *)av);
    }
    case GQL_VM_NATIVE_VALUE_SCALAR:
    default:
      switch (value->scalar_kind_code) {
        case GQL_VM_NATIVE_SCALAR_UNDEF:
          return newSVsv(&PL_sv_undef);
        case GQL_VM_NATIVE_SCALAR_IV:
          return newSViv(value->scalar_iv);
        case GQL_VM_NATIVE_SCALAR_NV:
          return newSVnv(value->scalar_nv);
        case GQL_VM_NATIVE_SCALAR_PV:
          return newSVpvn(value->scalar_pv ? value->scalar_pv : "", value->scalar_pv_len);
        case GQL_VM_NATIVE_SCALAR_FALLBACK_SV:
        default:
          return value->scalar_fallback_sv ? newSVsv(value->scalar_fallback_sv) : newSVsv(&PL_sv_undef);
      }
  }
}

static gql_runtime_vm_native_value_t *
gql_runtime_vm_native_value_from_sv(pTHX_ SV *value)
{
  SSize_t i;
  if (!value || !SvOK(value)) {
    return gql_runtime_vm_new_native_value_scalar(aTHX_ &PL_sv_undef);
  }
  if (SvROK(value)) {
    SV *rv = SvRV(value);
    if (SvTYPE(rv) == SVt_PVHV) {
      HV *hv = (HV *)rv;
      HE *he;
      gql_runtime_vm_native_value_t *ret = gql_runtime_vm_new_native_value_object();
      hv_iterinit(hv);
      while ((he = hv_iternext(hv))) {
        SV *key_sv = hv_iterkeysv(he);
        SV *val_sv = hv_iterval(hv, he);
        STRLEN key_len = 0;
        const char *key_pv = key_sv ? SvPV(key_sv, key_len) : "";
        /* store copies non-borrowed names itself (SvPV is NUL-terminated). */
        gql_runtime_vm_native_object_store(aTHX_ ret, key_pv, 0, gql_runtime_vm_native_value_from_sv(aTHX_ val_sv));
      }
      return ret;
    }
    if (SvTYPE(rv) == SVt_PVAV) {
      AV *av = (AV *)rv;
      gql_runtime_vm_native_value_t *ret = gql_runtime_vm_new_native_value_list();
      for (i = 0; i <= av_len(av); i++) {
        SV **svp = av_fetch(av, i, 0);
        gql_runtime_vm_native_list_push(ret, gql_runtime_vm_native_value_from_sv(aTHX_ (svp && *svp) ? *svp : &PL_sv_undef));
      }
      return ret;
    }
  }
  return gql_runtime_vm_new_native_value_scalar(aTHX_ value);
}

static gql_runtime_vm_native_value_t *
gql_runtime_vm_native_value_clone(pTHX_ const gql_runtime_vm_native_value_t *value)
{
  IV i;
  gql_runtime_vm_native_value_t *ret;
  if (!value) {
    return gql_runtime_vm_new_native_value_scalar(aTHX_ &PL_sv_undef);
  }
  switch (value->kind_code) {
    case GQL_VM_NATIVE_VALUE_OBJECT:
      ret = gql_runtime_vm_new_native_value_object();
      for (i = 0; i < value->object.count; i++) {
        gql_runtime_vm_native_object_store(
          aTHX_ ret,
          value->object.names[i],
          /* Plan-borrowed names stay borrowed: clones never outlive the
           * request, and the plan outlives it. */
          value->object.names_borrowed ? value->object.names_borrowed[i] : 0,
          gql_runtime_vm_native_value_clone(aTHX_ value->object.values[i])
        );
      }
      return ret;
    case GQL_VM_NATIVE_VALUE_LIST:
      ret = gql_runtime_vm_new_native_value_list();
      for (i = 0; i < value->list.count; i++) {
        gql_runtime_vm_native_list_push(
          ret,
          gql_runtime_vm_native_value_clone(aTHX_ value->list.items[i])
        );
      }
      return ret;
    case GQL_VM_NATIVE_VALUE_SCALAR:
    default:
      switch (value->scalar_kind_code) {
        case GQL_VM_NATIVE_SCALAR_UNDEF:
          return gql_runtime_vm_new_native_value_scalar(aTHX_ &PL_sv_undef);
        case GQL_VM_NATIVE_SCALAR_IV:
          ret = gql_runtime_vm_new_native_value_scalar(aTHX_ &PL_sv_undef);
          ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_IV;
          ret->scalar_iv = value->scalar_iv;
          return ret;
        case GQL_VM_NATIVE_SCALAR_NV:
          ret = gql_runtime_vm_new_native_value_scalar(aTHX_ &PL_sv_undef);
          ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_NV;
          ret->scalar_nv = value->scalar_nv;
          return ret;
        case GQL_VM_NATIVE_SCALAR_PV:
          ret = gql_runtime_vm_new_native_value_scalar(aTHX_ &PL_sv_undef);
          ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_PV;
          if (value->scalar_pv && value->scalar_pv_len) {
            ret->scalar_pv = savepvn(value->scalar_pv, value->scalar_pv_len);
            ret->scalar_pv_len = value->scalar_pv_len;
          }
          return ret;
        case GQL_VM_NATIVE_SCALAR_FALLBACK_SV:
        default:
          return gql_runtime_vm_new_native_value_scalar(aTHX_ value->scalar_fallback_sv ? value->scalar_fallback_sv : &PL_sv_undef);
      }
  }
}

static gql_runtime_vm_native_dynamic_value_t *
gql_runtime_vm_native_dynamic_value_from_sv(pTHX_ SV *value)
{
  gql_runtime_vm_native_dynamic_value_t *ret;
  STRLEN len = 0;

  Newxz(ret, 1, gql_runtime_vm_native_dynamic_value_t);
  ret->kind_code = GQL_VM_DYNAMIC_UNDEF;
  ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_UNDEF;

  if (!value || !SvOK(value)) {
    return ret;
  }

  if (SvROK(value)) {
    SV *inner = SvRV(value);
    if (SvTYPE(inner) == SVt_PVAV) {
      AV *av = (AV *)inner;
      IV i;
      ret->kind_code = GQL_VM_DYNAMIC_LIST;
      ret->list_count = av_len(av) + 1;
      if (ret->list_count > 0) {
        Newxz(ret->list_values, ret->list_count, gql_runtime_vm_native_dynamic_value_t *);
        for (i = 0; i < ret->list_count; i++) {
          SV **svp = av_fetch(av, i, 0);
          ret->list_values[i] = gql_runtime_vm_native_dynamic_value_from_sv(aTHX_ (svp && SvOK(*svp)) ? *svp : &PL_sv_undef);
        }
      }
      return ret;
    }
    if (SvTYPE(inner) == SVt_PVHV) {
      HV *hv = (HV *)inner;
      HE *he;
      IV count = HvUSEDKEYS(hv);
      ret->kind_code = GQL_VM_DYNAMIC_OBJECT;
      ret->object_count = count;
      if (count > 0) {
        IV i = 0;
        Newxz(ret->object_names, count, char *);
        Newxz(ret->object_values, count, gql_runtime_vm_native_dynamic_value_t *);
        hv_iterinit(hv);
        while ((he = hv_iternext(hv))) {
          SV *key_sv = hv_iterkeysv(he);
          SV *val_sv = hv_iterval(hv, he);
          const char *key_pv = SvPV(key_sv, len);
          ret->object_names[i] = savepvn(key_pv, len);
          ret->object_values[i] = gql_runtime_vm_native_dynamic_value_from_sv(aTHX_ val_sv);
          i++;
        }
        ret->object_count = i;
      }
      return ret;
    }
    if (SvTYPE(inner) == SVt_PV) {
      const char *name = SvPV(inner, len);
      ret->kind_code = GQL_VM_DYNAMIC_VARIABLE;
      ret->variable_name = savepvn(name, len);
      return ret;
    }
  }

  ret->kind_code = GQL_VM_DYNAMIC_SCALAR;
  if (SvPOKp(value)) {
    const char *pv = SvPV(value, len);
    ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_PV;
    ret->scalar_pv = savepvn(pv, len);
    ret->scalar_pv_len = len;
    return ret;
  }
  if (SvIOKp(value)) {
    ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_IV;
    ret->scalar_iv = SvIV(value);
    return ret;
  }
  if (SvNOKp(value)) {
    ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_NV;
    ret->scalar_nv = SvNV(value);
    return ret;
  }
  return ret;
}

static gql_runtime_vm_native_dynamic_value_t *
gql_runtime_vm_native_dynamic_value_from_native_value(
  pTHX_ const gql_runtime_vm_native_value_t *value
)
{
  gql_runtime_vm_native_dynamic_value_t *ret;
  IV i;

  Newxz(ret, 1, gql_runtime_vm_native_dynamic_value_t);
  ret->kind_code = GQL_VM_DYNAMIC_UNDEF;
  ret->scalar_kind_code = GQL_VM_NATIVE_SCALAR_UNDEF;

  if (!value || value->kind_code == GQL_VM_NATIVE_VALUE_UNDEF) {
    return ret;
  }

  switch (value->kind_code) {
    case GQL_VM_NATIVE_VALUE_OBJECT:
      ret->kind_code = GQL_VM_DYNAMIC_OBJECT;
      ret->object_count = value->object.count;
      if (ret->object_count > 0) {
        Newxz(ret->object_names, ret->object_count, char *);
        Newxz(ret->object_values, ret->object_count, gql_runtime_vm_native_dynamic_value_t *);
        for (i = 0; i < ret->object_count; i++) {
          if (value->object.names && value->object.names[i]) {
            ret->object_names[i] = savepv(value->object.names[i]);
          }
          ret->object_values[i] = gql_runtime_vm_native_dynamic_value_from_native_value(
            aTHX_ value->object.values ? value->object.values[i] : NULL
          );
        }
      }
      return ret;
    case GQL_VM_NATIVE_VALUE_LIST:
      ret->kind_code = GQL_VM_DYNAMIC_LIST;
      ret->list_count = value->list.count;
      if (ret->list_count > 0) {
        Newxz(ret->list_values, ret->list_count, gql_runtime_vm_native_dynamic_value_t *);
        for (i = 0; i < ret->list_count; i++) {
          ret->list_values[i] = gql_runtime_vm_native_dynamic_value_from_native_value(
            aTHX_ value->list.items ? value->list.items[i] : NULL
          );
        }
      }
      return ret;
    case GQL_VM_NATIVE_VALUE_SCALAR:
    default:
      ret->kind_code = GQL_VM_DYNAMIC_SCALAR;
      ret->scalar_kind_code = value->scalar_kind_code;
      ret->scalar_iv = value->scalar_iv;
      ret->scalar_nv = value->scalar_nv;
      if (value->scalar_kind_code == GQL_VM_NATIVE_SCALAR_PV && value->scalar_pv) {
        ret->scalar_pv = savepvn(value->scalar_pv, value->scalar_pv_len);
        ret->scalar_pv_len = value->scalar_pv_len;
      } else if (value->scalar_kind_code == GQL_VM_NATIVE_SCALAR_FALLBACK_SV && value->scalar_fallback_sv) {
        gql_runtime_vm_native_dynamic_value_destroy(aTHX_ ret);
        return gql_runtime_vm_native_dynamic_value_from_sv(aTHX_ value->scalar_fallback_sv);
      }
      return ret;
  }
}

static gql_runtime_vm_native_dynamic_value_t *
gql_runtime_vm_native_dynamic_value_clone(
  pTHX_ const gql_runtime_vm_native_dynamic_value_t *value
)
{
  gql_runtime_vm_native_dynamic_value_t *ret;
  IV i;

  if (!value) {
    return NULL;
  }
  Newxz(ret, 1, gql_runtime_vm_native_dynamic_value_t);
  *ret = *value;
  ret->scalar_pv = NULL;
  ret->variable_name = NULL;
  ret->object_names = NULL;
  ret->object_values = NULL;
  ret->list_values = NULL;

  if (value->scalar_kind_code == GQL_VM_NATIVE_SCALAR_PV && value->scalar_pv) {
    ret->scalar_pv = savepvn(value->scalar_pv, value->scalar_pv_len);
  }
  if (value->kind_code == GQL_VM_DYNAMIC_VARIABLE && value->variable_name) {
    ret->variable_name = savepv(value->variable_name);
  }
  if (value->kind_code == GQL_VM_DYNAMIC_OBJECT && value->object_count > 0) {
    Newxz(ret->object_names, value->object_count, char *);
    Newxz(ret->object_values, value->object_count, gql_runtime_vm_native_dynamic_value_t *);
    for (i = 0; i < value->object_count; i++) {
      ret->object_names[i] = value->object_names[i] ? savepv(value->object_names[i]) : NULL;
      ret->object_values[i] = gql_runtime_vm_native_dynamic_value_clone(aTHX_ value->object_values[i]);
    }
  }
  if (value->kind_code == GQL_VM_DYNAMIC_LIST && value->list_count > 0) {
    Newxz(ret->list_values, value->list_count, gql_runtime_vm_native_dynamic_value_t *);
    for (i = 0; i < value->list_count; i++) {
      ret->list_values[i] = gql_runtime_vm_native_dynamic_value_clone(aTHX_ value->list_values[i]);
    }
  }
  return ret;
}

static void
gql_runtime_vm_native_dynamic_value_destroy(
  pTHX_ gql_runtime_vm_native_dynamic_value_t *value
)
{
  IV i;

  if (!value) {
    return;
  }
  if (value->scalar_kind_code == GQL_VM_NATIVE_SCALAR_PV) {
    Safefree(value->scalar_pv);
  }
  Safefree(value->variable_name);
  if (value->kind_code == GQL_VM_DYNAMIC_OBJECT) {
    for (i = 0; i < value->object_count; i++) {
      Safefree(value->object_names ? value->object_names[i] : NULL);
      gql_runtime_vm_native_dynamic_value_destroy(aTHX_ value->object_values ? value->object_values[i] : NULL);
    }
    Safefree(value->object_names);
    Safefree(value->object_values);
  } else if (value->kind_code == GQL_VM_DYNAMIC_LIST) {
    for (i = 0; i < value->list_count; i++) {
      gql_runtime_vm_native_dynamic_value_destroy(aTHX_ value->list_values ? value->list_values[i] : NULL);
    }
    Safefree(value->list_values);
  }
  Safefree(value);
}

static SV *
gql_runtime_vm_native_dynamic_value_materialize_sv(
  pTHX_ const gql_runtime_vm_native_dynamic_value_t *value,
  HV *variables
)
{
  IV i;

  if (!value || value->kind_code == GQL_VM_DYNAMIC_UNDEF) {
    return newSV(0);
  }

  switch (value->kind_code) {
    case GQL_VM_DYNAMIC_VARIABLE: {
      SV **svp = (variables && value->variable_name)
        ? hv_fetch(variables, value->variable_name, (I32)strlen(value->variable_name), 0)
        : NULL;
      return (svp && SvOK(*svp)) ? newSVsv(*svp) : newSV(0);
    }
    case GQL_VM_DYNAMIC_LIST: {
      AV *av = newAV();
      for (i = 0; i < value->list_count; i++) {
        av_push(av, gql_runtime_vm_native_dynamic_value_materialize_sv(aTHX_ value->list_values[i], variables));
      }
      return newRV_noinc((SV *)av);
    }
    case GQL_VM_DYNAMIC_OBJECT: {
      HV *hv = newHV();
      for (i = 0; i < value->object_count; i++) {
        if (!value->object_names || !value->object_names[i]) {
          continue;
        }
        hv_store(
          hv,
          value->object_names[i],
          (I32)strlen(value->object_names[i]),
          gql_runtime_vm_native_dynamic_value_materialize_sv(aTHX_ value->object_values[i], variables),
          0
        );
      }
      return newRV_noinc((SV *)hv);
    }
    case GQL_VM_DYNAMIC_SCALAR:
    default:
      switch (value->scalar_kind_code) {
        case GQL_VM_NATIVE_SCALAR_IV:
          return newSViv(value->scalar_iv);
        case GQL_VM_NATIVE_SCALAR_NV:
          return newSVnv(value->scalar_nv);
        case GQL_VM_NATIVE_SCALAR_PV:
          return newSVpvn(value->scalar_pv ? value->scalar_pv : "", value->scalar_pv_len);
        default:
          return newSV(0);
      }
  }
}

static int
gql_runtime_vm_native_dynamic_value_truthy(
  pTHX_ const gql_runtime_vm_native_dynamic_value_t *value,
  HV *variables
)
{
  if (!value || value->kind_code == GQL_VM_DYNAMIC_UNDEF) {
    return 0;
  }

  switch (value->kind_code) {
    case GQL_VM_DYNAMIC_VARIABLE: {
      SV **svp = (variables && value->variable_name)
        ? hv_fetch(variables, value->variable_name, (I32)strlen(value->variable_name), 0)
        : NULL;
      return (svp && SvOK(*svp) && SvTRUE(*svp)) ? 1 : 0;
    }
    case GQL_VM_DYNAMIC_LIST:
    case GQL_VM_DYNAMIC_OBJECT:
      return 1;
    case GQL_VM_DYNAMIC_SCALAR:
    default:
      switch (value->scalar_kind_code) {
        case GQL_VM_NATIVE_SCALAR_IV:
          return value->scalar_iv ? 1 : 0;
        case GQL_VM_NATIVE_SCALAR_NV:
          return value->scalar_nv != 0.0 ? 1 : 0;
        case GQL_VM_NATIVE_SCALAR_PV:
          if (!value->scalar_pv || value->scalar_pv_len == 0) {
            return 0;
          }
          if (value->scalar_pv_len == 1 && value->scalar_pv[0] == '0') {
            return 0;
          }
          return 1;
        case GQL_VM_NATIVE_SCALAR_UNDEF:
        default:
          return 0;
      }
  }
}

static const gql_runtime_vm_native_dynamic_value_t *
gql_runtime_vm_native_args_payload_lookup_value(
  const gql_runtime_vm_native_args_payload_t *payload,
  const char *arg_name,
  IV hint_index
)
{
  IV j;

  if (!payload || !arg_name) {
    return NULL;
  }

  if (hint_index >= 0
      && hint_index < payload->count
      && payload->names
      && payload->names[hint_index]
      && strEQ(payload->names[hint_index], arg_name)) {
    return payload->values ? payload->values[hint_index] : NULL;
  }

  for (j = 0; j < payload->count; j++) {
    if (payload->names && payload->names[j] && strEQ(payload->names[j], arg_name)) {
      return payload->values ? payload->values[j] : NULL;
    }
  }

  return NULL;
}

static gql_runtime_vm_native_args_payload_t *
gql_runtime_vm_native_args_payload_from_hv(pTHX_ HV *hv)
{
  HE *he;
  gql_runtime_vm_native_args_payload_t *payload;
  IV count = 0;

  if (!hv) {
    return NULL;
  }

  Newxz(payload, 1, gql_runtime_vm_native_args_payload_t);
  count = HvUSEDKEYS(hv);
  payload->count = count;
  if (count <= 0) {
    return payload;
  }

  Newxz(payload->names, count, char *);
  Newxz(payload->values, count, gql_runtime_vm_native_dynamic_value_t *);

  hv_iterinit(hv);
  count = 0;
  while ((he = hv_iternext(hv))) {
    SV *key_sv = hv_iterkeysv(he);
    SV *val_sv = hv_iterval(hv, he);
    STRLEN key_len = 0;
    const char *key_pv = key_sv ? SvPV(key_sv, key_len) : "";
    payload->names[count] = savepvn(key_pv, key_len);
    payload->values[count] = gql_runtime_vm_native_dynamic_value_from_sv(aTHX_ val_sv);
    count++;
  }
  payload->count = count;
  return payload;
}

static gql_runtime_vm_native_args_payload_t *
gql_runtime_vm_native_args_payload_clone(
  pTHX_ const gql_runtime_vm_native_args_payload_t *payload
)
{
  gql_runtime_vm_native_args_payload_t *copy;
  IV i;

  if (!payload) {
    return NULL;
  }

  Newxz(copy, 1, gql_runtime_vm_native_args_payload_t);
  copy->count = payload->count;
  if (copy->count <= 0) {
    return copy;
  }

  Newxz(copy->names, copy->count, char *);
  Newxz(copy->values, copy->count, gql_runtime_vm_native_dynamic_value_t *);
  for (i = 0; i < copy->count; i++) {
    copy->names[i] = payload->names[i] ? savepv(payload->names[i]) : NULL;
    copy->values[i] = gql_runtime_vm_native_dynamic_value_clone(aTHX_ payload->values[i]);
  }
  return copy;
}

static void
gql_runtime_vm_native_args_payload_destroy(pTHX_ gql_runtime_vm_native_args_payload_t *payload)
{
  IV i;
  if (!payload) {
    return;
  }
  for (i = 0; i < payload->count; i++) {
    Safefree(payload->names ? payload->names[i] : NULL);
    gql_runtime_vm_native_dynamic_value_destroy(aTHX_ payload->values ? payload->values[i] : NULL);
  }
  if (payload->static_args_sv) {
    SvREFCNT_dec(payload->static_args_sv);
  }
  Safefree(payload->names);
  Safefree(payload->values);
  Safefree(payload);
}

static SV *
gql_runtime_vm_native_args_payload_materialize_sv(
  pTHX_ const gql_runtime_vm_native_args_payload_t *payload
)
{
  HV *hv;
  IV i;

  hv = newHV();
  if (!payload) {
    return newRV_noinc((SV *)hv);
  }

  for (i = 0; i < payload->count; i++) {
    if (!payload->names || !payload->names[i]) {
      continue;
    }
    hv_store(
      hv,
      payload->names[i],
      (I32)strlen(payload->names[i]),
      gql_runtime_vm_native_dynamic_value_materialize_sv(aTHX_ payload->values ? payload->values[i] : NULL, NULL),
      0
    );
  }

  return newRV_noinc((SV *)hv);
}

static SV *
gql_runtime_vm_native_args_payload_materialize_cached_sv(
  pTHX_ gql_runtime_vm_native_args_payload_t *payload
)
{
  HV *hv;
  IV i;

  if (!payload) {
    return newRV_noinc((SV *)newHV());
  }

  if (payload->static_args_sv) {
    return SvREFCNT_inc_simple_NN(payload->static_args_sv);
  }

  hv = newHV();
  for (i = 0; i < payload->count; i++) {
    if (!payload->names || !payload->names[i]) {
      continue;
    }
    hv_store(
      hv,
      payload->names[i],
      (I32)strlen(payload->names[i]),
      gql_runtime_vm_native_dynamic_value_materialize_sv(aTHX_ payload->values ? payload->values[i] : NULL, NULL),
      0
    );
  }

  payload->static_args_sv = newRV_noinc((SV *)hv);
  return SvREFCNT_inc_simple_NN(payload->static_args_sv);
}

static SV *
gql_runtime_vm_native_directives_payload_materialize_sv(
  pTHX_ const gql_runtime_vm_native_directives_payload_t *payload
)
{
  AV *av;
  IV i;

  av = newAV();
  if (!payload) {
    return newRV_noinc((SV *)av);
  }

  for (i = 0; i < payload->count; i++) {
    HV *hv = newHV();
    HV *args_hv = newHV();
    SV *args_sv;
    gql_runtime_vm_native_guard_t *guard = &payload->guards[i];
    const char *name = (guard->kind_code == GQL_VM_GUARD_SKIP) ? "skip" : "include";

    hv_store(hv, "name", 4, newSVpv(name, 0), 0);
    hv_store(
      args_hv,
      "if",
      2,
      gql_runtime_vm_native_dynamic_value_materialize_sv(aTHX_ guard->if_expr, NULL),
      0
    );
    args_sv = newRV_noinc((SV *)args_hv);
    hv_store(
      hv,
      "arguments",
      9,
      args_sv,
      0
    );
    av_push(av, newRV_noinc((SV *)hv));
  }

  return newRV_noinc((SV *)av);
}

static SV *
gql_runtime_vm_native_slot_to_compact_sv(
  pTHX_ const gql_runtime_vm_native_slot_t *slot
)
{
  AV *av = newAV();
  AV *arg_defs_av = newAV();
  IV i;

  av_push(av, newSVpv(slot->field_name ? slot->field_name : "", 0));
  av_push(av, newSVpv(slot->result_name ? slot->result_name : "", 0));
  av_push(av, newSVpv(slot->return_type_name ? slot->return_type_name : "", 0));
  av_push(av, newSViv(slot->schema_slot_index));
  av_push(av, newSViv(slot->resolver_shape_code));
  av_push(av, newSViv(slot->completion_family_code));
  av_push(av, newSViv(slot->dispatch_family_code));
  av_push(av, newSViv(slot->return_type_kind_code));
  av_push(av, newSViv(slot->has_args ? 1 : 0));
  av_push(av, newSViv(slot->has_directives ? 1 : 0));
  av_push(av, newSViv(slot->resolver_mode_code));

  for (i = 0; i < slot->arg_def_count; i++) {
    AV *arg_def_av = newAV();
    gql_runtime_vm_native_arg_def_t *arg_def = &slot->arg_defs[i];
    av_push(arg_def_av, newSVpv(arg_def->name ? arg_def->name : "", 0));
    av_push(arg_def_av, arg_def->type_def_sv ? newSVsv(arg_def->type_def_sv) : newSV(0));
    av_push(arg_def_av, newSViv(arg_def->has_default ? 1 : 0));
    if (arg_def->has_default) {
      SV *default_sv = arg_def->default_native_value
        ? gql_runtime_vm_native_value_materialize_sv(aTHX_ arg_def->default_native_value)
        : (arg_def->default_value_sv ? newSVsv(arg_def->default_value_sv) : newSV(0));
      av_push(arg_def_av, default_sv);
    } else {
      av_push(arg_def_av, newSV(0));
    }
    av_push(arg_defs_av, newRV_noinc((SV *)arg_def_av));
  }
  av_push(av, newRV_noinc((SV *)arg_defs_av));
  av_push(av, newSViv(slot->callback_abi_code));
  av_push(av, newSViv(slot->item_non_null ? 1 : 0));

  return newRV_noinc((SV *)av);
}

static SV *
gql_runtime_vm_native_op_to_compact_sv(
  pTHX_ const gql_runtime_vm_native_block_t *block,
  const gql_runtime_vm_native_op_t *op
)
{
  AV *av = newAV();
  HV *abstract_children_hv = newHV();
  IV i;
  const gql_runtime_vm_native_slot_t *slot = NULL;

  if (block && op && op->slot_index >= 0 && op->slot_index < block->slot_count) {
    slot = &block->slots[op->slot_index];
  }

  av_push(av, newSViv(op->opcode_code));
  av_push(av, newSViv(op->resolve_code));
  av_push(av, newSViv(op->complete_code));
  av_push(av, newSViv(op->dispatch_family_code));
  av_push(av, newSViv(op->slot_index));
  av_push(av, newSViv(op->child_block_index));

  for (i = 0; i < op->abstract_child_count; i++) {
    const char *name = op->abstract_child_names ? op->abstract_child_names[i] : NULL;
    if (!name) {
      continue;
    }
    hv_store(
      abstract_children_hv,
      name,
      (I32)strlen(name),
      newSViv(op->abstract_child_indexes ? op->abstract_child_indexes[i] : -1),
      0
    );
  }
  av_push(av, newRV_noinc((SV *)abstract_children_hv));
  av_push(av, newSViv(op->args_mode_code));
  av_push(av, newSViv(-1));
  av_push(av, op->args_payload_native
    ? gql_runtime_vm_native_args_payload_materialize_sv(aTHX_ op->args_payload_native)
    : newSV(0));
  av_push(av, newSViv(op->has_args ? 1 : 0));
  av_push(av, newSViv(op->directives_mode_code));
  av_push(av, newSViv(-1));
  av_push(av, op->directives_payload_native
    ? gql_runtime_vm_native_directives_payload_materialize_sv(aTHX_ op->directives_payload_native)
    : newSV(0));
  av_push(av, newSViv(op->has_directives ? 1 : 0));
  av_push(av, newSVpv((slot && slot->field_name) ? slot->field_name : "", 0));
  av_push(av, newSVpv((slot && slot->result_name) ? slot->result_name : "", 0));
  av_push(av, newSVpv((slot && slot->return_type_name) ? slot->return_type_name : "", 0));
  av_push(av, newSViv(op->runtime_directives_mode_code));
  av_push(av, op->runtime_directives_sv ? newSVsv(op->runtime_directives_sv) : newSV(0));
  av_push(av, newSViv(op->has_runtime_directives ? 1 : 0));

  return newRV_noinc((SV *)av);
}

static SV *
gql_runtime_vm_native_block_to_compact_sv(
  pTHX_ const gql_runtime_vm_native_block_t *block
)
{
  AV *slots_av = newAV();
  AV *ops_av = newAV();
  AV *av = newAV();
  IV i;

  av_push(av, newSV(0));
  av_push(av, newSVpv(block->type_name ? block->type_name : "", 0));
  av_push(av, newSViv(block->family_code));

  for (i = 0; i < block->slot_count; i++) {
    av_push(slots_av, gql_runtime_vm_native_slot_to_compact_sv(aTHX_ &block->slots[i]));
  }
  av_push(av, newRV_noinc((SV *)slots_av));

  for (i = 0; i < block->op_count; i++) {
    av_push(ops_av, gql_runtime_vm_native_op_to_compact_sv(aTHX_ block, &block->ops[i]));
  }
  av_push(av, newRV_noinc((SV *)ops_av));

  return newRV_noinc((SV *)av);
}

static SV *
gql_runtime_vm_native_arg_defs_to_hash_sv(
  pTHX_ const gql_runtime_vm_native_arg_def_t *arg_defs,
  IV arg_def_count
)
{
  HV *hv = newHV();
  IV i;

  for (i = 0; i < arg_def_count; i++) {
    const gql_runtime_vm_native_arg_def_t *arg_def = &arg_defs[i];
    HV *arg_def_hv = newHV();

    if (!arg_def->name) {
      continue;
    }

    hv_store(arg_def_hv, "type", 4, arg_def->type_def_sv ? newSVsv(arg_def->type_def_sv) : newSV(0), 0);
    hv_store(arg_def_hv, "has_default", 11, newSViv(arg_def->has_default ? 1 : 0), 0);
    if (arg_def->has_default) {
      SV *default_sv = arg_def->default_native_value
        ? gql_runtime_vm_native_value_materialize_sv(aTHX_ arg_def->default_native_value)
        : (arg_def->default_value_sv ? newSVsv(arg_def->default_value_sv) : newSV(0));
      hv_store(arg_def_hv, "default_value", 13, default_sv, 0);
    }

    hv_store(
      hv,
      arg_def->name,
      (I32)strlen(arg_def->name),
      newRV_noinc((SV *)arg_def_hv),
      0
    );
  }

  return newRV_noinc((SV *)hv);
}

static SV *
gql_runtime_vm_native_program_to_compact_sv(
  pTHX_ const gql_runtime_vm_native_program_t *program
)
{
  HV *hv = newHV();
  AV *blocks_av = newAV();
  AV *args_payloads_av = newAV();
  AV *directives_payloads_av = newAV();
  IV i;

  hv_store(hv, "version", 7, newSViv(program->version > 0 ? program->version : 1), 0);
  hv_store(hv, "operation_type_code", 19, newSViv(program->operation_type_code), 0);
  hv_store(
    hv,
    "operation_name",
    14,
    program->operation_name ? newSVpv(program->operation_name, 0) : newSV(0),
    0
  );
  hv_store(hv, "root_block_index", 16, newSViv(program->root_block_index), 0);
  hv_store(
    hv,
    "variable_defs",
    13,
    gql_runtime_vm_native_arg_defs_to_hash_sv(aTHX_ program->variable_defs, program->variable_def_count),
    0
  );

  for (i = 0; i < program->args_payload_count; i++) {
    av_push(
      args_payloads_av,
      program->args_payloads && program->args_payloads[i]
        ? gql_runtime_vm_native_args_payload_materialize_sv(aTHX_ program->args_payloads[i])
        : newSV(0)
    );
  }
  hv_store(hv, "args_payloads_compact", 21, newRV_noinc((SV *)args_payloads_av), 0);

  for (i = 0; i < program->directives_payload_count; i++) {
    av_push(
      directives_payloads_av,
      program->directives_payloads && program->directives_payloads[i]
        ? gql_runtime_vm_native_directives_payload_materialize_sv(aTHX_ program->directives_payloads[i])
        : newSV(0)
    );
  }
  hv_store(hv, "directives_payloads_compact", 27, newRV_noinc((SV *)directives_payloads_av), 0);

  for (i = 0; i < program->block_count; i++) {
    av_push(blocks_av, gql_runtime_vm_native_block_to_compact_sv(aTHX_ &program->blocks[i]));
  }
  hv_store(hv, "blocks_compact", 14, newRV_noinc((SV *)blocks_av), 0);

  return newRV_noinc((SV *)hv);
}

static gql_runtime_vm_native_directives_payload_t *
gql_runtime_vm_native_directives_payload_from_sv(pTHX_ SV *guards_sv)
{
  AV *guards_av;
  gql_runtime_vm_native_directives_payload_t *payload;
  IV i;

  if (!guards_sv || !SvOK(guards_sv) || !SvROK(guards_sv) || SvTYPE(SvRV(guards_sv)) != SVt_PVAV) {
    return NULL;
  }

  guards_av = (AV *)SvRV(guards_sv);
  Newxz(payload, 1, gql_runtime_vm_native_directives_payload_t);
  payload->count = av_len(guards_av) + 1;
  if (payload->count <= 0) {
    return payload;
  }
  Newxz(payload->guards, payload->count, gql_runtime_vm_native_guard_t);

  for (i = 0; i < payload->count; i++) {
    SV **directive_svp = av_fetch(guards_av, i, 0);
    HV *directive_hv;
    SV **name_svp;
    SV **arguments_svp;
    HV *arguments_hv;
    SV **if_svp;
    STRLEN name_len = 0;
    const char *name;

    if (!directive_svp || !SvOK(*directive_svp) || !SvROK(*directive_svp) || SvTYPE(SvRV(*directive_svp)) != SVt_PVHV) {
      continue;
    }
    directive_hv = (HV *)SvRV(*directive_svp);
    name_svp = hv_fetch(directive_hv, "name", 4, 0);
    arguments_svp = hv_fetch(directive_hv, "arguments", 9, 0);
    if (!name_svp || !SvOK(*name_svp) || !arguments_svp || !SvOK(*arguments_svp) || !SvROK(*arguments_svp) || SvTYPE(SvRV(*arguments_svp)) != SVt_PVHV) {
      continue;
    }
    arguments_hv = (HV *)SvRV(*arguments_svp);
    if_svp = hv_fetch(arguments_hv, "if", 2, 0);
    if (!if_svp || !SvOK(*if_svp)) {
      continue;
    }
    name = SvPV(*name_svp, name_len);
    if (name_len == 4 && memEQ(name, "skip", 4)) {
      payload->guards[i].kind_code = GQL_VM_GUARD_SKIP;
    } else {
      payload->guards[i].kind_code = GQL_VM_GUARD_INCLUDE;
    }
    payload->guards[i].if_expr = gql_runtime_vm_native_dynamic_value_from_sv(aTHX_ *if_svp);
  }

  return payload;
}

static gql_runtime_vm_native_directives_payload_t *
gql_runtime_vm_native_directives_payload_clone(
  pTHX_ const gql_runtime_vm_native_directives_payload_t *payload
)
{
  gql_runtime_vm_native_directives_payload_t *copy;
  IV i;

  if (!payload) {
    return NULL;
  }
  Newxz(copy, 1, gql_runtime_vm_native_directives_payload_t);
  copy->count = payload->count;
  if (copy->count <= 0) {
    return copy;
  }
  Newxz(copy->guards, copy->count, gql_runtime_vm_native_guard_t);
  for (i = 0; i < copy->count; i++) {
    copy->guards[i].kind_code = payload->guards[i].kind_code;
    copy->guards[i].if_expr = gql_runtime_vm_native_dynamic_value_clone(aTHX_ payload->guards[i].if_expr);
  }
  return copy;
}

static void
gql_runtime_vm_native_directives_payload_destroy(
  pTHX_ gql_runtime_vm_native_directives_payload_t *payload
)
{
  IV i;

  if (!payload) {
    return;
  }
  for (i = 0; i < payload->count; i++) {
    gql_runtime_vm_native_dynamic_value_destroy(aTHX_ payload->guards ? payload->guards[i].if_expr : NULL);
  }
  Safefree(payload->guards);
  Safefree(payload);
}

static int
gql_runtime_vm_evaluate_runtime_guards_native(
  pTHX_ const gql_runtime_vm_native_directives_payload_t *payload,
  HV *variables
)
{
  IV i;

  if (!payload) {
    return 1;
  }
  for (i = 0; i < payload->count; i++) {
    const gql_runtime_vm_native_guard_t *guard = &payload->guards[i];
    int bool_value = gql_runtime_vm_native_dynamic_value_truthy(aTHX_ guard->if_expr, variables);
    if (guard->kind_code == GQL_VM_GUARD_SKIP && bool_value) {
      return 0;
    }
    if (guard->kind_code == GQL_VM_GUARD_INCLUDE && !bool_value) {
      return 0;
    }
  }
  return 1;
}

static IV
gql_runtime_vm_infer_callback_abi_code(IV resolver_shape_code, IV resolver_mode_code)
{
  if (resolver_mode_code == 2) {
    return GQL_VM_CALLBACK_ABI_EXPLICIT_NATIVE;
  }
  if (resolver_shape_code == GQL_VM_RESOLVE_EXPLICIT) {
    return GQL_VM_CALLBACK_ABI_EXPLICIT_GENERIC;
  }
  return GQL_VM_CALLBACK_ABI_DEFAULT;
}

static const gql_runtime_vm_native_slot_t *
gql_runtime_vm_effective_slot(
  const gql_runtime_vm_native_runtime_t *runtime,
  const gql_runtime_vm_native_slot_t *slot
)
{
  if (!runtime || !slot) {
    return slot;
  }
  if (slot->schema_slot_index >= 0 && slot->schema_slot_index < runtime->runtime_slot_count) {
    return &runtime->runtime_slots[slot->schema_slot_index];
  }
  return slot;
}

static SV *
gql_runtime_vm_new_cursor_handle(pTHX_ const char *pkg, gql_runtime_vm_cursor_t *cursor)
{
  return gql_runtime_vm_new_handle_sv(aTHX_ pkg, cursor);
}

static void
gql_runtime_vm_error_record_incref(gql_runtime_vm_error_record_t *record)
{
  if (record) {
    record->refcount++;
  }
}

static const char *
gql_runtime_vm_find_tagged_type_name(
  const gql_runtime_vm_native_runtime_t *runtime,
  IV slot_index,
  SV *tag_sv
)
{
  IV i;
  STRLEN tag_len = 0;
  const char *tag_name = NULL;
  gql_runtime_vm_native_tag_entry_t *entries;
  IV count;
  gql_runtime_vm_native_callback_catalog_t *catalog;

  if (!runtime || slot_index < 0 || slot_index >= runtime->runtime_slot_count || !tag_sv || !SvOK(tag_sv)) {
    return NULL;
  }
  catalog = runtime->callback_catalog;
  if (!catalog || !catalog->slot_tag_entries || !catalog->slot_tag_entry_counts) {
    return NULL;
  }
  entries = catalog->slot_tag_entries[slot_index];
  count = catalog->slot_tag_entry_counts[slot_index];
  if (!entries || count <= 0) {
    return NULL;
  }
  tag_name = SvPV(tag_sv, tag_len);
  if (!tag_name) {
    return NULL;
  }
  for (i = 0; i < count; i++) {
    const char *candidate = entries[i].tag_name;
    if (candidate && strlen(candidate) == (size_t)tag_len && memcmp(candidate, tag_name, (size_t)tag_len) == 0) {
      return entries[i].type_name;
    }
  }
  return NULL;
}

static gql_runtime_vm_native_possible_type_entry_t *
gql_runtime_vm_find_matching_possible_type(
  pTHX_
  const gql_runtime_vm_native_runtime_t *runtime,
  IV slot_index,
  SV *value,
  SV *context,
  SV *info,
  SV **error_out
)
{
  IV i;
  gql_runtime_vm_native_possible_type_entry_t *entries;
  IV count;
  gql_runtime_vm_native_callback_catalog_t *catalog;

  if (!runtime || slot_index < 0 || slot_index >= runtime->runtime_slot_count) {
    return NULL;
  }
  catalog = runtime->callback_catalog;
  if (!catalog || !catalog->slot_possible_type_entries || !catalog->slot_possible_type_entry_counts) {
    return NULL;
  }
  entries = catalog->slot_possible_type_entries[slot_index];
  count = catalog->slot_possible_type_entry_counts[slot_index];
  if (!entries || count <= 0) {
    return NULL;
  }

  for (i = 0; i < count; i++) {
    SV *ok_sv;
    if (!entries[i].type_sv || !entries[i].is_type_of_cb) {
      continue;
    }
    ok_sv = gql_runtime_vm_call_cb4_nonfatal(
      aTHX_
      entries[i].is_type_of_cb,
      value,
      context,
      info ? info : &PL_sv_undef,
      entries[i].type_sv,
      error_out
    );
    if (error_out && *error_out) {
      return NULL;
    }
    if (SvTRUE(ok_sv)) {
      SvREFCNT_dec(ok_sv);
      return &entries[i];
    }
    SvREFCNT_dec(ok_sv);
  }

  return NULL;
}

static void
gql_runtime_vm_error_record_decref(pTHX_ gql_runtime_vm_error_record_t *record)
{
  if (!record) {
    return;
  }
  if (record->refcount > 1) {
    record->refcount--;
    return;
  }
  if (record->message_pv) {
    Safefree(record->message_pv);
  }
  gql_runtime_vm_path_frame_decref(record->path_frame);
  Safefree(record);
}

static void
gql_runtime_vm_outcome_incref(gql_runtime_vm_outcome_t *outcome)
{
  if (outcome) {
    outcome->refcount++;
  }
}

static void
gql_runtime_vm_outcome_decref(pTHX_ gql_runtime_vm_outcome_t *outcome)
{
  IV i;
  if (!outcome) {
    return;
  }
  if (outcome->refcount > 1) {
    outcome->refcount--;
    return;
  }
  gql_runtime_vm_native_value_destroy(aTHX_ outcome->value);
  for (i = 0; i < outcome->error_record_count; i++) {
    gql_runtime_vm_error_record_decref(aTHX_ outcome->error_records[i]);
  }
  Safefree(outcome->error_records);
  if (gql_runtime_vm_outcome_pool_count < GQL_RUNTIME_VM_OUTCOME_POOL_MAX) {
    outcome->pool_next = gql_runtime_vm_outcome_pool_head;
    gql_runtime_vm_outcome_pool_head = outcome;
    gql_runtime_vm_outcome_pool_count++;
    return;
  }
  Safefree(outcome);
}

static void
gql_runtime_vm_writer_push_error_record(gql_runtime_vm_writer_t *writer, gql_runtime_vm_error_record_t *record)
{
  if (!writer || !record) {
    return;
  }
  if (writer->error_record_count == writer->error_record_capacity) {
    writer->error_record_capacity = writer->error_record_capacity ? writer->error_record_capacity * 2 : 4;
    Renew(writer->error_records, writer->error_record_capacity, gql_runtime_vm_error_record_t *);
  }
  gql_runtime_vm_error_record_incref(record);
  writer->error_records[writer->error_record_count++] = record;
}

static void
gql_runtime_vm_block_frame_push_pending_pvn(
  pTHX_
  gql_runtime_vm_block_frame_t *frame,
  const char *result_name_pv,
  STRLEN result_name_len,
  SV *outcome
)
{
  U8 payload_kind = GQL_VM_PENDING_PROMISE_SV;

  if (outcome && SvOK(outcome) && sv_derived_from(outcome, "GraphQL::Houtou::Runtime::Outcome")) {
    payload_kind = GQL_VM_PENDING_OUTCOME_PTR;
  }

  gql_runtime_vm_block_frame_push_pending_pvn_with_meta(
    aTHX_
    frame,
    result_name_pv,
    result_name_len,
    0,
    outcome,
    payload_kind,
    NULL,
    -1,
    -1,
    -1
  );
}

static void
gql_runtime_vm_block_frame_push_pending_pvn_with_meta(
  pTHX_
  gql_runtime_vm_block_frame_t *frame,
  const char *result_name_pv,
  STRLEN result_name_len,
  U8 result_name_pv_borrowed,
  SV *outcome,
  U8 payload_kind,
  gql_runtime_vm_path_frame_t *path_frame,
  IV block_index,
  IV slot_index,
  IV op_index
)
{
  gql_runtime_vm_pending_entry_t *entry = NULL;

  if (!frame || !result_name_pv || result_name_len == 0 || !outcome) {
    return;
  }

  entry = gql_runtime_vm_block_frame_push_pending_entry_with_meta(
    aTHX_
    frame,
    result_name_pv,
    result_name_len,
    result_name_pv_borrowed,
    path_frame,
    block_index,
    slot_index,
    op_index
  );
  if (!entry) {
    return;
  }

  if (payload_kind == GQL_VM_PENDING_OUTCOME_PTR) {
    entry->payload_kind = GQL_VM_PENDING_OUTCOME_PTR;
    entry->state_code = GQL_VM_PENDING_STATE_READY_OUTCOME;
    entry->payload.outcome_ptr = gql_runtime_vm_expect_outcome(aTHX_ outcome);
    gql_runtime_vm_outcome_incref(entry->payload.outcome_ptr);
  } else {
    entry->payload_kind = payload_kind;
    entry->payload.promise_sv = newSVsv(outcome);
    if (outcome
        && SvOK(outcome)
        && SvROK(outcome)
        && sv_derived_from(outcome, "Promise::XS::Promise")) {
      entry->state_code = GQL_VM_PENDING_STATE_WAITING_UNARMED;
    } else {
      entry->state_code = GQL_VM_PENDING_STATE_READY_SV;
    }
  }
}

static gql_runtime_vm_pending_entry_t *
gql_runtime_vm_block_frame_push_pending_entry_with_meta(
  pTHX_
  gql_runtime_vm_block_frame_t *frame,
  const char *result_name_pv,
  STRLEN result_name_len,
  U8 result_name_pv_borrowed,
  gql_runtime_vm_path_frame_t *path_frame,
  IV block_index,
  IV slot_index,
  IV op_index
)
{
  gql_runtime_vm_pending_entry_t *entry = NULL;

  if (!frame || !result_name_pv || result_name_len == 0) {
    return NULL;
  }

  if (frame->pending_count == frame->pending_capacity) {
    frame->pending_capacity = frame->pending_capacity ? frame->pending_capacity * 2 : 4;
    Renew(frame->pending_entries, frame->pending_capacity, gql_runtime_vm_pending_entry_t);
  }

  entry = &frame->pending_entries[frame->pending_count];
  entry->result_name_pv = result_name_pv_borrowed
    ? (char *)result_name_pv
    : savepvn(result_name_pv, result_name_len);
  entry->result_name_len = result_name_len;
  entry->path_frame = path_frame;
  if (entry->path_frame) {
    entry->path_frame->refcount++;
  }
  entry->block_index = block_index;
  entry->slot_index = slot_index;
  entry->op_index = op_index;
  entry->result_name_pv_borrowed = result_name_pv_borrowed ? 1 : 0;
  entry->armed_resolve_ctx = NULL;
  entry->armed_reject_ctx = NULL;
  entry->payload.promise_sv = NULL;
  entry->payload_kind = 0;
  entry->state_code = 0;
  frame->pending_count++;
  return entry;
}

static void
gql_runtime_vm_block_frame_push_pending(pTHX_ gql_runtime_vm_block_frame_t *frame, SV *result_name, SV *outcome)
{
  STRLEN result_name_len = 0;
  const char *result_name_pv = NULL;
  if (!frame || !result_name || !outcome) {
    return;
  }
  result_name_pv = SvPV(result_name, result_name_len);
  gql_runtime_vm_block_frame_push_pending_pvn(
    aTHX_ frame,
    result_name_pv,
    result_name_len,
    outcome
  );
}

static void
gql_runtime_vm_block_frame_clear_pending(pTHX_ gql_runtime_vm_block_frame_t *frame)
{
  IV i;
  if (!frame) {
    return;
  }
  for (i = 0; i < frame->pending_count; i++) {
    if (!frame->pending_entries[i].result_name_pv_borrowed) {
      Safefree(frame->pending_entries[i].result_name_pv);
    }
    gql_runtime_vm_path_frame_decref(frame->pending_entries[i].path_frame);
    if (frame->pending_entries[i].payload_kind == GQL_VM_PENDING_OUTCOME_PTR) {
      gql_runtime_vm_outcome_decref(aTHX_ frame->pending_entries[i].payload.outcome_ptr);
    } else if (frame->pending_entries[i].payload_kind == GQL_VM_PENDING_BLOCK_FRAME_PTR) {
      gql_runtime_vm_free_block_frame(aTHX_ frame->pending_entries[i].payload.block_frame_ptr);
    } else if (frame->pending_entries[i].payload_kind == GQL_VM_PENDING_LIST_PENDING_PTR) {
      gql_runtime_vm_list_pending_decref(aTHX_ frame->pending_entries[i].payload.list_pending_ptr);
    } else if (frame->pending_entries[i].payload_kind == GQL_VM_PENDING_PROMISE_SV
        || frame->pending_entries[i].payload_kind == GQL_VM_PENDING_PROMISE_GENERIC_VALUE_SV) {
      SvREFCNT_dec(frame->pending_entries[i].payload.promise_sv);
    } else if (frame->pending_entries[i].payload_kind == GQL_VM_PENDING_PROMISE_RESOLVED_VALUE_SV) {
      SvREFCNT_dec(frame->pending_entries[i].payload.promise_sv);
    }
  }
  /* The entries array (and its capacity) is retained for reuse; block
   * frames recycle through a pool and re-fill it without a Renew ramp.
   * gql_runtime_vm_free_block_frame frees it when a frame really dies. */
  frame->pending_count = 0;
  frame->pending_unresolved = 0;
}

static SV *
gql_runtime_vm_cursor_snapshot_sv(pTHX_ SV *cursor_sv)
{
  gql_runtime_vm_cursor_t *cursor;
  gql_runtime_vm_cursor_t *snapshot;

  if (!cursor_sv || !SvOK(cursor_sv) || !SvROK(cursor_sv)) {
    return newSVsv(&PL_sv_undef);
  }

  cursor = gql_runtime_vm_expect_cursor(aTHX_ cursor_sv);
  Newxz(snapshot, 1, gql_runtime_vm_cursor_t);
  snapshot->native_program = cursor->native_program;
  snapshot->block_index = cursor->block_index;
  snapshot->slot_index = cursor->slot_index;
  snapshot->op_index = cursor->op_index;

  return gql_runtime_vm_new_cursor_handle(aTHX_ "GraphQL::Houtou::Runtime::Cursor", snapshot);
}

static void
gql_runtime_vm_cursor_snapshot_copy(pTHX_ gql_runtime_vm_cursor_t *dst, const gql_runtime_vm_cursor_t *src)
{
  if (!dst) {
    return;
  }
  Zero(dst, 1, gql_runtime_vm_cursor_t);
  if (!src) {
    dst->native_program = NULL;
    dst->block_index = -1;
    return;
  }
  dst->native_program = src->native_program;
  dst->block_index = src->block_index;
  dst->slot_index = src->slot_index;
  dst->op_index = src->op_index;
}

static void
gql_runtime_vm_cursor_destroy_copy(pTHX_ gql_runtime_vm_cursor_t *cursor)
{
  if (!cursor) {
    return;
  }
  Zero(cursor, 1, gql_runtime_vm_cursor_t);
}

static void
gql_runtime_vm_cursor_restore_copy(pTHX_ gql_runtime_vm_cursor_t *dst, const gql_runtime_vm_cursor_t *src)
{
  /* Unlike snapshot_copy this restores into a LIVE cursor, so it must only
   * touch the navigation fields. Reusing snapshot_copy here used to
   * Zero(dst) first, wiping the live refcount; the next decref then
   * underflowed the unsigned count and the cursor struct leaked on every
   * exec-state request. */
  if (!dst) {
    return;
  }
  if (!src) {
    dst->native_program = NULL;
    dst->block_index = -1;
    dst->slot_index = 0;
    dst->op_index = 0;
    return;
  }
  dst->native_program = src->native_program;
  dst->block_index = src->block_index;
  dst->slot_index = src->slot_index;
  dst->op_index = src->op_index;
}

static void
gql_runtime_vm_cursor_restore_sv(pTHX_ gql_runtime_vm_cursor_t *dst, SV *snapshot_sv)
{
  gql_runtime_vm_cursor_t *src;

  if (!dst || !snapshot_sv || !SvOK(snapshot_sv) || !SvROK(snapshot_sv)) {
    return;
  }

  src = gql_runtime_vm_expect_cursor(aTHX_ snapshot_sv);
  gql_runtime_vm_cursor_snapshot_copy(aTHX_ dst, src);
}

/* Returns a borrowed AV, or NULL when no error records were provided. */
static AV *
gql_runtime_vm_expect_error_records_av(pTHX_ SV *error_records)
{
  if (error_records && SvOK(error_records) && SvROK(error_records) && SvTYPE(SvRV(error_records)) == SVt_PVAV) {
    return (AV *)SvRV(error_records);
  }
  return NULL;
}

static gql_runtime_vm_error_record_t *
gql_runtime_vm_new_error_record_struct_for_path(
  pTHX_
  SV *message,
  gql_runtime_vm_path_frame_t *path_frame
)
{
  gql_runtime_vm_error_record_t *record;
  STRLEN len = 0;
  const char *pv = NULL;

  Newxz(record, 1, gql_runtime_vm_error_record_t);
  record->refcount = 1;
  if (message && SvOK(message)) {
    pv = SvPV(message, len);
    Newxz(record->message_pv, len + 1, char);
    Copy(pv, record->message_pv, len, char);
    record->message_pv[len] = '\0';
  }
  if (path_frame) {
    record->path_frame = path_frame;
    record->path_frame->refcount++;
  } else {
    record->path_frame = NULL;
  }
  return record;
}

static SV *
gql_runtime_vm_path_frame_key_sv(pTHX_ const gql_runtime_vm_path_frame_t *frame)
{
  if (!frame) {
    return newSV(0);
  }
  if (frame->key_kind == 1) {
    return newSViv(frame->key_iv);
  }
  if (frame->key_pv) {
    return newSVpvn(frame->key_pv, frame->key_pv_len);
  }
  return newSV(0);
}

static void
gql_runtime_vm_path_frame_decref(gql_runtime_vm_path_frame_t *frame)
{
  if (!frame) {
    return;
  }
  if (frame->refcount > 0) {
    frame->refcount--;
  }
  if (frame->refcount == 0) {
    gql_runtime_vm_path_frame_t *parent = frame->parent;
    gql_runtime_vm_path_frame_live_count--;
    if (frame->key_pv && !frame->key_pv_borrowed) {
      Safefree(frame->key_pv);
    }
    if (gql_runtime_vm_path_frame_pool_count < GQL_RUNTIME_VM_PATH_FRAME_POOL_MAX) {
      frame->parent = gql_runtime_vm_path_frame_pool_head;
      gql_runtime_vm_path_frame_pool_head = frame;
      gql_runtime_vm_path_frame_pool_count++;
    } else {
      Safefree(frame);
    }
    gql_runtime_vm_path_frame_decref(parent);
  }
}

static SV *
gql_runtime_vm_path_frame_to_path_sv(pTHX_ gql_runtime_vm_path_frame_t *path_frame)
{
  AV *segments = newAV();
  AV *path_av = newAV();
  gql_runtime_vm_path_frame_t *cursor = path_frame;
  SSize_t i;

  while (cursor) {
    av_push(segments, gql_runtime_vm_path_frame_key_sv(aTHX_ cursor));
    cursor = cursor->parent;
  }

  for (i = av_len(segments); i >= 0; i--) {
    SV **svp = av_fetch(segments, i, 0);
    if (svp && *svp) {
      av_push(path_av, newSVsv(*svp));
    }
  }

  SvREFCNT_dec((SV *)segments);
  return newRV_noinc((SV *)path_av);
}

static SV *
gql_runtime_vm_error_record_to_error_sv(pTHX_ const gql_runtime_vm_error_record_t *record)
{
  HV *error_hv = newHV();
  SV *path_sv = NULL;

  if (!record) {
    return newRV_noinc((SV *)error_hv);
  }

  hv_store(error_hv, "message", 7, record->message_pv ? newSVpv(record->message_pv, 0) : newSVsv(&PL_sv_undef), 0);

  if (record->path_frame) {
    path_sv = gql_runtime_vm_path_frame_to_path_sv(aTHX_ record->path_frame);
    if (path_sv && SvOK(path_sv) && SvROK(path_sv) && SvTYPE(SvRV(path_sv)) == SVt_PVAV && av_count((AV *)SvRV(path_sv)) > 0) {
      hv_store(error_hv, "path", 4, path_sv, 0);
      path_sv = NULL;
    }
  }

  if (path_sv) {
    SvREFCNT_dec(path_sv);
  }

  return newRV_noinc((SV *)error_hv);
}

/* Completed child selections arrive as plain hash/array trees (nested
 * objects and lists of the response). Convert those recursively so the
 * native tree keeps their structure; anything else - scalars and blessed
 * leaves (custom scalar objects, boolean objects) - stays a scalar node
 * for the shared scalar serializer. A shallow scalar wrap here turns a
 * nested hashref into the string "HASH(0x...)" on the JSON lane. */
static gql_runtime_vm_native_value_t *
gql_runtime_vm_native_value_from_completed_sv(pTHX_ SV *value)
{
  if (value && SvOK(value) && SvROK(value) && !sv_isobject(value)
      && (SvTYPE(SvRV(value)) == SVt_PVHV || SvTYPE(SvRV(value)) == SVt_PVAV)) {
    return gql_runtime_vm_native_value_from_sv(aTHX_ value);
  }
  return gql_runtime_vm_new_native_value_scalar(aTHX_ value ? value : &PL_sv_undef);
}

static gql_runtime_vm_outcome_t *
gql_runtime_vm_new_outcome_struct(pTHX_ U8 kind_code, SV *value, SV *error_records)
{
  gql_runtime_vm_outcome_t *outcome;
  AV *errors_av = gql_runtime_vm_expect_error_records_av(aTHX_ error_records);
  SSize_t i;

  outcome = gql_runtime_vm_outcome_pool_get(aTHX);
  outcome->refcount = 1;
  outcome->kind_code = kind_code;
  switch (kind_code) {
    case GQL_VM_KIND_OBJECT:
      if (value && SvOK(value)) {
        if (SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVHV) {
          HV *src_hv = (HV *)SvRV(value);
          HE *he;
          outcome->value = gql_runtime_vm_new_native_value_object();
          hv_iterinit(src_hv);
          while ((he = hv_iternext(src_hv)) != NULL) {
            SV *key_sv = hv_iterkeysv(he);
            SV *val_sv = hv_iterval(src_hv, he);
            STRLEN key_len = 0;
            const char *key_pv = SvPV(key_sv, key_len);
            gql_runtime_vm_native_object_store(
              aTHX_
              outcome->value,
              key_pv,
              0,
              gql_runtime_vm_native_value_from_completed_sv(aTHX_ val_sv)
            );
          }
        } else {
          outcome->value = gql_runtime_vm_new_native_value_scalar(aTHX_ value);
        }
      } else {
        outcome->value = gql_runtime_vm_new_native_value_scalar(aTHX_ &PL_sv_undef);
      }
      break;
    case GQL_VM_KIND_LIST:
      if (value && SvOK(value) && SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVAV) {
        AV *src_av = (AV *)SvRV(value);
        SSize_t max = av_len(src_av);
        outcome->value = gql_runtime_vm_new_native_value_list();
        for (i = 0; i <= max; i++) {
          SV **svp = av_fetch(src_av, i, 0);
          gql_runtime_vm_native_list_push(
            outcome->value,
            gql_runtime_vm_native_value_from_completed_sv(aTHX_ (svp && *svp) ? *svp : &PL_sv_undef)
          );
        }
      } else {
        outcome->value = gql_runtime_vm_new_native_value_scalar(aTHX_ value ? value : &PL_sv_undef);
      }
      break;
    case GQL_VM_KIND_SCALAR:
    default:
      outcome->value = gql_runtime_vm_new_native_value_scalar(aTHX_ value ? value : &PL_sv_undef);
      break;
  }
  outcome->error_record_count = errors_av ? av_count(errors_av) : 0;
  if (outcome->error_record_count > 0) {
    Newxz(outcome->error_records, outcome->error_record_count, gql_runtime_vm_error_record_t *);
    for (i = 0; i < outcome->error_record_count; i++) {
      SV **svp = av_fetch(errors_av, i, 0);
      if (svp && *svp && SvOK(*svp)) {
        gql_runtime_vm_error_record_t *record = gql_runtime_vm_expect_error_record(aTHX_ *svp);
        gql_runtime_vm_error_record_incref(record);
        outcome->error_records[i] = record;
      }
    }
  }

  return outcome;
}

static SV *
gql_runtime_vm_outcome_kind_sv(pTHX_ const gql_runtime_vm_outcome_t *outcome)
{
  if (!outcome) {
    return newSVpvs("");
  }
  switch (outcome->kind_code) {
    case GQL_VM_KIND_SCALAR:
      return newSVpvs("SCALAR");
    case GQL_VM_KIND_OBJECT:
      return newSVpvs("OBJECT");
    case GQL_VM_KIND_LIST:
      return newSVpvs("LIST");
    default:
      return newSVpvs("");
  }
}

static gql_runtime_vm_writer_t *
gql_runtime_vm_new_writer_struct(pTHX)
{
  gql_runtime_vm_writer_t *writer;

  Newxz(writer, 1, gql_runtime_vm_writer_t);
  writer->refcount = 1;
  return writer;
}

static void
gql_runtime_vm_init_writer_struct(gql_runtime_vm_writer_t *writer)
{
  if (!writer) {
    return;
  }
  Zero(writer, 1, gql_runtime_vm_writer_t);
  writer->refcount = 1;
}

static void
gql_runtime_vm_clear_writer_struct(pTHX_ gql_runtime_vm_writer_t *writer)
{
  if (!writer) {
    return;
  }
  while (writer->error_record_count > 0) {
    gql_runtime_vm_error_record_decref(aTHX_ writer->error_records[--writer->error_record_count]);
  }
  Safefree(writer->error_records);
  Zero(writer, 1, gql_runtime_vm_writer_t);
}

static void
gql_runtime_vm_consume_outcome_struct(pTHX_ HV *data_hv, SV *result_name_sv, const gql_runtime_vm_outcome_t *outcome, gql_runtime_vm_writer_t *writer)
{
  IV i;

  if (!data_hv || !result_name_sv || !outcome) {
    return;
  }

  hv_store_ent(
    data_hv,
    result_name_sv,
    outcome->value ? gql_runtime_vm_native_value_materialize_sv(aTHX_ outcome->value) : newSV(0),
    0
  );

  if (!writer) {
    return;
  }

  for (i = 0; i < outcome->error_record_count; i++) {
    gql_runtime_vm_writer_push_error_record(writer, outcome->error_records[i]);
  }
}

static void
gql_runtime_vm_consume_outcome_native_object(
  pTHX_
  gql_runtime_vm_native_value_t *data_value,
  const char *result_name_pv,
  U8 result_name_borrowed,
  gql_runtime_vm_outcome_t *outcome,
  gql_runtime_vm_writer_t *writer
)
{
  IV i;

  if (!data_value || data_value->kind_code != GQL_VM_NATIVE_VALUE_OBJECT || !result_name_pv || !outcome) {
    return;
  }

  /* Consuming is the outcome's terminal use: when the caller is the sole
   * owner, transfer the native subtree instead of deep-cloning it (the
   * clone was immediately followed by destroying the original). Shared
   * outcomes (refcount > 1, e.g. still referenced by a pending entry
   * elsewhere) keep the defensive clone. */
  if (outcome->refcount == 1 && outcome->value) {
    gql_runtime_vm_native_object_store(aTHX_ data_value, result_name_pv, result_name_borrowed, outcome->value);
    outcome->value = NULL;
  } else {
    gql_runtime_vm_native_object_store(
      aTHX_ data_value,
      result_name_pv,
      result_name_borrowed,
      outcome->value ? gql_runtime_vm_native_value_clone(aTHX_ outcome->value)
                     : gql_runtime_vm_new_native_value_scalar(aTHX_ &PL_sv_undef)
    );
  }

  if (!writer) {
    return;
  }

  for (i = 0; i < outcome->error_record_count; i++) {
    gql_runtime_vm_writer_push_error_record(writer, outcome->error_records[i]);
  }
}

/* A completed native value counts as null when it is absent or a scalar
 * undef. Object/list values are never null here (an empty list is not a
 * null). Used by Non-Null propagation on the async lane. */
static int
gql_runtime_vm_native_value_is_null(const gql_runtime_vm_native_value_t *value)
{
  if (!value) {
    return 1;
  }
  return value->kind_code == GQL_VM_NATIVE_VALUE_SCALAR
    && value->scalar_kind_code == GQL_VM_NATIVE_SCALAR_UNDEF;
}

static void
gql_runtime_vm_consume_value_native_object(
  pTHX_
  gql_runtime_vm_native_value_t *data_value,
  const char *result_name_pv,
  U8 result_name_borrowed,
  SV *value_sv
)
{
  if (!data_value || data_value->kind_code != GQL_VM_NATIVE_VALUE_OBJECT || !result_name_pv) {
    return;
  }

  gql_runtime_vm_native_object_store(
    aTHX_
    data_value,
    result_name_pv,
    result_name_borrowed,
    gql_runtime_vm_native_value_from_sv(aTHX_ value_sv ? value_sv : &PL_sv_undef)
  );
}

static SV *
gql_runtime_vm_writer_materialize_errors_sv(pTHX_ const gql_runtime_vm_writer_t *writer)
{
  AV *errors_av;
  IV i;

  if (!writer || writer->error_record_count == 0) {
    return NULL;
  }

  errors_av = newAV();
  for (i = 0; i < writer->error_record_count; i++) {
    av_push(errors_av, gql_runtime_vm_error_record_to_error_sv(aTHX_ writer->error_records[i]));
  }

  return newRV_noinc((SV *)errors_av);
}

static SV *
gql_runtime_vm_dispatch_hash_fetch(pTHX_ SV *dispatch_sv, const char *key, STRLEN key_len)
{
  HV *hv;
  SV **svp;
  if (!dispatch_sv || !SvOK(dispatch_sv) || !SvROK(dispatch_sv) || SvTYPE(SvRV(dispatch_sv)) != SVt_PVHV) {
    return NULL;
  }
  hv = (HV *)SvRV(dispatch_sv);
  svp = hv_fetch(hv, key, (I32)key_len, 0);
  return svp ? *svp : NULL;
}

static SV *
gql_runtime_vm_hash_lookup_ent_sv(pTHX_ SV *hv_sv, SV *key_sv)
{
  HE *he;
  HV *hv;
  if (!hv_sv || !SvOK(hv_sv) || !SvROK(hv_sv) || SvTYPE(SvRV(hv_sv)) != SVt_PVHV || !key_sv) {
    return NULL;
  }
  hv = (HV *)SvRV(hv_sv);
  he = hv_fetch_ent(hv, key_sv, 0, 0);
  return he ? HeVAL(he) : NULL;
}

static SV *
gql_runtime_vm_call_cb_scalar(pTHX_ SV *cb, SV *value, SV *context, SV *info, SV *type_like, SV **error_out)
{
  dSP;
  SV *result = NULL;
  if (error_out) {
    *error_out = NULL;
  }
  if (!cb || !SvOK(cb)) {
    return NULL;
  }

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVsv(value ? value : &PL_sv_undef)));
  XPUSHs(sv_2mortal(newSVsv(context ? context : &PL_sv_undef)));
  XPUSHs(sv_2mortal(newSVsv(info ? info : &PL_sv_undef)));
  XPUSHs(sv_2mortal(newSVsv(type_like ? type_like : &PL_sv_undef)));
  PUTBACK;

  if (call_sv(cb, G_SCALAR | G_EVAL) > 0) {
    SPAGAIN;
    result = POPs;
    result = result ? newSVsv(result) : NULL;
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
  return result;
}

static SV *
gql_runtime_vm_resolve_runtime_type_sv(
  pTHX_
  SV *dispatch_sv,
  SV *cache_sv,
  SV *value,
  SV *context,
  SV *info,
  SV *abstract_type,
  SV **error_out
)
{
  SV *tag_resolver;
  SV *tag_map_sv;
  SV *resolve_type;
  SV *name2type_sv;
  SV *possible_types_sv;
  SV *is_type_of_map_sv;
  SV *tmp_error = NULL;
  SV *resolved = NULL;

  if (error_out) {
    *error_out = NULL;
  }

  tag_resolver = gql_runtime_vm_dispatch_hash_fetch(aTHX_ dispatch_sv, "tag_resolver", 12);
  tag_map_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ dispatch_sv, "tag_map", 7);
  resolve_type = gql_runtime_vm_dispatch_hash_fetch(aTHX_ dispatch_sv, "resolve_type", 12);
  name2type_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ dispatch_sv, "name2type", 9);
  possible_types_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ dispatch_sv, "possible_types", 14);
  is_type_of_map_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ dispatch_sv, "is_type_of_map", 14);

  if (!name2type_sv) {
    name2type_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ cache_sv, "name2type", 9);
  }
  if (!possible_types_sv) {
    SV *possible_types_map = gql_runtime_vm_dispatch_hash_fetch(aTHX_ cache_sv, "possible_types", 14);
    SV *abstract_name = gql_runtime_vm_dispatch_hash_fetch(aTHX_ dispatch_sv, "abstract_name", 13);
    possible_types_sv = gql_runtime_vm_hash_lookup_ent_sv(aTHX_ possible_types_map, abstract_name);
  }
  if (!is_type_of_map_sv) {
    is_type_of_map_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ cache_sv, "is_type_of_map", 14);
  }

  if (tag_resolver) {
    SV *tag = gql_runtime_vm_call_cb_scalar(aTHX_ tag_resolver, value, context, info, abstract_type, &tmp_error);
    if (tmp_error) {
      if (error_out) *error_out = tmp_error;
      return NULL;
    }
    if (tag && SvOK(tag)) {
      SV *mapped = gql_runtime_vm_hash_lookup_ent_sv(aTHX_ tag_map_sv, tag);
      SvREFCNT_dec(tag);
      if (mapped && SvOK(mapped)) {
        return newSVsv(mapped);
      }
    } else if (tag) {
      SvREFCNT_dec(tag);
    }
  }

  if (resolve_type) {
    resolved = gql_runtime_vm_call_cb_scalar(aTHX_ resolve_type, value, context, info, abstract_type, &tmp_error);
    if (tmp_error) {
      if (error_out) *error_out = tmp_error;
      return NULL;
    }
    if (resolved && SvOK(resolved)) {
      if (SvROK(resolved)) {
        return resolved;
      }
      else {
        SV *mapped = gql_runtime_vm_hash_lookup_ent_sv(aTHX_ name2type_sv, resolved);
        SvREFCNT_dec(resolved);
        return mapped && SvOK(mapped) ? newSVsv(mapped) : NULL;
      }
    } else if (resolved) {
      SvREFCNT_dec(resolved);
    }
  }

  if (possible_types_sv && SvOK(possible_types_sv) && SvROK(possible_types_sv) && SvTYPE(SvRV(possible_types_sv)) == SVt_PVAV) {
    AV *possible_types_av = (AV *)SvRV(possible_types_sv);
    SSize_t i;
    for (i = 0; i <= av_len(possible_types_av); i++) {
      SV **type_svp = av_fetch(possible_types_av, i, 0);
      SV *type_sv;
      SV *type_name_sv;
      SV *cb;
      SV *matched;
      if (!type_svp || !(type_sv = *type_svp) || !SvOK(type_sv)) {
        continue;
      }
      type_name_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ type_sv, "name", 4);
      if (!type_name_sv) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVsv(type_sv)));
        PUTBACK;
        if (call_method("name", G_SCALAR) > 0) {
          SPAGAIN;
          type_name_sv = POPs;
          type_name_sv = type_name_sv ? newSVsv(type_name_sv) : NULL;
          PUTBACK;
        }
        FREETMPS;
        LEAVE;
      } else {
        type_name_sv = newSVsv(type_name_sv);
      }
      cb = gql_runtime_vm_hash_lookup_ent_sv(aTHX_ is_type_of_map_sv, type_name_sv);
      SvREFCNT_dec(type_name_sv);
      if (!cb || !SvOK(cb)) {
        continue;
      }
      matched = gql_runtime_vm_call_cb_scalar(aTHX_ cb, value, context, info, type_sv, &tmp_error);
      if (tmp_error) {
        if (error_out) *error_out = tmp_error;
        return NULL;
      }
      if (matched && SvTRUE(matched)) {
        SvREFCNT_dec(matched);
        return newSVsv(type_sv);
      }
      if (matched) {
        SvREFCNT_dec(matched);
      }
    }
  }

  return NULL;
}

static SV *
gql_runtime_vm_resolve_runtime_type_for_abstract_sv(
  pTHX_
  SV *cache_sv,
  const char *abstract_name,
  SV *value,
  SV *context,
  SV *info,
  SV *abstract_type,
  SV **error_out
)
{
  SV *tag_resolver = NULL;
  SV *tag_map_sv = NULL;
  SV *resolve_type = NULL;
  SV *name2type_sv = NULL;
  SV *possible_types_sv = NULL;
  SV *is_type_of_map_sv = NULL;
  SV *tmp_error = NULL;
  SV *resolved = NULL;

  if (error_out) {
    *error_out = NULL;
  }

  if (!cache_sv || !SvOK(cache_sv) || !SvROK(cache_sv) || SvTYPE(SvRV(cache_sv)) != SVt_PVHV || !abstract_name) {
    return NULL;
  }

  {
    SV *abstract_name_sv = newSVpv(abstract_name, 0);
    SV *tag_resolver_map_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ cache_sv, "tag_resolver_map", 16);
    SV *runtime_tag_map_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ cache_sv, "runtime_tag_map", 15);
    SV *resolve_type_map_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ cache_sv, "resolve_type_map", 16);
    SV *possible_types_map_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ cache_sv, "possible_types", 14);

    name2type_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ cache_sv, "name2type", 9);
    is_type_of_map_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ cache_sv, "is_type_of_map", 14);

    if (tag_resolver_map_sv) {
      tag_resolver = gql_runtime_vm_hash_lookup_ent_sv(aTHX_ tag_resolver_map_sv, abstract_name_sv);
    }
    if (runtime_tag_map_sv) {
      tag_map_sv = gql_runtime_vm_hash_lookup_ent_sv(aTHX_ runtime_tag_map_sv, abstract_name_sv);
    }
    if (resolve_type_map_sv) {
      resolve_type = gql_runtime_vm_hash_lookup_ent_sv(aTHX_ resolve_type_map_sv, abstract_name_sv);
    }
    if (possible_types_map_sv) {
      possible_types_sv = gql_runtime_vm_hash_lookup_ent_sv(aTHX_ possible_types_map_sv, abstract_name_sv);
    }

    SvREFCNT_dec(abstract_name_sv);
  }

  if (tag_resolver) {
    SV *tag = gql_runtime_vm_call_cb_scalar(aTHX_ tag_resolver, value, context, info, abstract_type, &tmp_error);
    if (tmp_error) {
      if (error_out) *error_out = tmp_error;
      return NULL;
    }
    if (tag && SvOK(tag)) {
      SV *mapped = gql_runtime_vm_hash_lookup_ent_sv(aTHX_ tag_map_sv, tag);
      SvREFCNT_dec(tag);
      if (mapped && SvOK(mapped)) {
        return newSVsv(mapped);
      }
    } else if (tag) {
      SvREFCNT_dec(tag);
    }
  }

  if (resolve_type) {
    resolved = gql_runtime_vm_call_cb_scalar(aTHX_ resolve_type, value, context, info, abstract_type, &tmp_error);
    if (tmp_error) {
      if (error_out) *error_out = tmp_error;
      return NULL;
    }
    if (resolved && SvOK(resolved)) {
      if (SvROK(resolved)) {
        return resolved;
      }
      else {
        SV *mapped = gql_runtime_vm_hash_lookup_ent_sv(aTHX_ name2type_sv, resolved);
        SvREFCNT_dec(resolved);
        return mapped && SvOK(mapped) ? newSVsv(mapped) : NULL;
      }
    } else if (resolved) {
      SvREFCNT_dec(resolved);
    }
  }

  if (possible_types_sv && SvOK(possible_types_sv) && SvROK(possible_types_sv) && SvTYPE(SvRV(possible_types_sv)) == SVt_PVAV) {
    AV *possible_types_av = (AV *)SvRV(possible_types_sv);
    SSize_t i;
    for (i = 0; i <= av_len(possible_types_av); i++) {
      SV **type_svp = av_fetch(possible_types_av, i, 0);
      SV *type_sv;
      SV *type_name_sv;
      SV *cb;
      SV *matched;
      if (!type_svp || !(type_sv = *type_svp) || !SvOK(type_sv)) {
        continue;
      }
      type_name_sv = gql_runtime_vm_dispatch_hash_fetch(aTHX_ type_sv, "name", 4);
      if (!type_name_sv) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVsv(type_sv)));
        PUTBACK;
        if (call_method("name", G_SCALAR) > 0) {
          SPAGAIN;
          type_name_sv = POPs;
          type_name_sv = type_name_sv ? newSVsv(type_name_sv) : NULL;
          PUTBACK;
        }
        FREETMPS;
        LEAVE;
      } else {
        type_name_sv = newSVsv(type_name_sv);
      }
      cb = gql_runtime_vm_hash_lookup_ent_sv(aTHX_ is_type_of_map_sv, type_name_sv);
      SvREFCNT_dec(type_name_sv);
      if (!cb || !SvOK(cb)) {
        continue;
      }
      matched = gql_runtime_vm_call_cb_scalar(aTHX_ cb, value, context, info, type_sv, &tmp_error);
      if (tmp_error) {
        if (error_out) *error_out = tmp_error;
        return NULL;
      }
      if (matched && SvTRUE(matched)) {
        SvREFCNT_dec(matched);
        return newSVsv(type_sv);
      }
      if (matched) {
        SvREFCNT_dec(matched);
      }
    }
  }

  return NULL;
}

static SV *
gql_runtime_vm_materialize_dynamic_value_sv(pTHX_ SV *value, HV *variables)
{
  SV *inner;

  if (!value || !SvOK(value)) {
    return newSV(0);
  }

  if (!SvROK(value)) {
    return newSVsv(value);
  }

  inner = SvRV(value);

  if (SvTYPE(inner) == SVt_PVAV) {
    AV *src = (AV *)inner;
    AV *dst = newAV();
    SSize_t max = av_len(src);
    SSize_t i;
    av_extend(dst, max);
    for (i = 0; i <= max; i++) {
      SV **svp = av_fetch(src, i, 0);
      av_store(dst, i, gql_runtime_vm_materialize_dynamic_value_sv(
        aTHX_
        (svp ? *svp : &PL_sv_undef),
        variables
      ));
    }
    return newRV_noinc((SV *)dst);
  }

  if (SvTYPE(inner) == SVt_PVHV) {
    HV *src = (HV *)inner;
    HV *dst = newHV();
    HE *he;
    (void)hv_iterinit(src);
    while ((he = hv_iternext(src))) {
      SV *key_sv = HeSVKEY_force(he);
      SV *val_sv = HeVAL(he);
      hv_store_ent(
        dst,
        newSVsv(key_sv),
        gql_runtime_vm_materialize_dynamic_value_sv(aTHX_ val_sv, variables),
        0
      );
    }
    return newRV_noinc((SV *)dst);
  }

  if (SvROK(inner)) {
    return newSVsv(SvRV(inner));
  }

  if (variables) {
    STRLEN len;
    const char *name = SvPV(inner, len);
    SV **svp = hv_fetch(variables, name, (I32)len, 0);
    return svp ? newSVsv(*svp) : newSV(0);
  }

  return newSV(0);
}

static int
gql_runtime_vm_evaluate_runtime_guards_hv(pTHX_ SV *guards_sv, HV *variables)
{
  AV *guards_av;
  SSize_t i;

  if (!guards_sv || !SvOK(guards_sv) || !SvROK(guards_sv) || SvTYPE(SvRV(guards_sv)) != SVt_PVAV) {
    return 1;
  }

  guards_av = (AV *)SvRV(guards_sv);
  for (i = 0; i <= av_len(guards_av); i++) {
    SV **directive_svp = av_fetch(guards_av, i, 0);
    SV *directive_sv;
    HV *directive_hv;
    SV **name_svp;
    SV **arguments_svp;
    HV *arguments_hv;
    SV **if_svp;
    SV *if_value_sv;
    int bool_value;
    STRLEN name_len;
    const char *name;

    if (!directive_svp || !(directive_sv = *directive_svp) || !SvOK(directive_sv)) {
      continue;
    }
    if (!SvROK(directive_sv) || SvTYPE(SvRV(directive_sv)) != SVt_PVHV) {
      continue;
    }
    directive_hv = (HV *)SvRV(directive_sv);
    name_svp = hv_fetch(directive_hv, "name", 4, 0);
    arguments_svp = hv_fetch(directive_hv, "arguments", 9, 0);
    if (!name_svp || !SvOK(*name_svp) || !arguments_svp || !SvOK(*arguments_svp)) {
      continue;
    }
    if (!SvROK(*arguments_svp) || SvTYPE(SvRV(*arguments_svp)) != SVt_PVHV) {
      continue;
    }
    arguments_hv = (HV *)SvRV(*arguments_svp);
    if_svp = hv_fetch(arguments_hv, "if", 2, 0);
    if (!if_svp) {
      continue;
    }

    if_value_sv = gql_runtime_vm_materialize_dynamic_value_sv(
      aTHX_
      *if_svp,
      variables
    );
    bool_value = SvTRUE(if_value_sv) ? 1 : 0;
    SvREFCNT_dec(if_value_sv);

    name = SvPV(*name_svp, name_len);
    if (name_len == 4 && memEQ(name, "skip", 4) && bool_value) {
      return 0;
    }
    if (name_len == 7 && memEQ(name, "include", 7) && !bool_value) {
      return 0;
    }
  }

  return 1;
}

/* Free an op's abstract-child member-name table. abstract_child_names is a
 * char** whose entries are individually allocated by parse/clone, so the
 * destroy paths must free each string, not just the array. Valgrind found
 * these leaking - bounded by the program cache, so the
 * RSS soak never saw them). */
static void
gql_runtime_vm_free_op_abstract_child_names(pTHX_ gql_runtime_vm_native_op_t *op)
{
  IV i;
  if (op->abstract_child_names) {
    for (i = 0; i < op->abstract_child_count; i++) {
      Safefree(op->abstract_child_names[i]);
    }
  }
  Safefree(op->abstract_child_names);
  op->abstract_child_names = NULL;
}

static void
gql_runtime_vm_native_bundle_destroy(gql_runtime_vm_native_bundle_t *bundle)
{
  IV i;
  IV j;
  if (!bundle) {
    return;
  }
  if (bundle->runtime_slots) {
    if (bundle->owns_runtime_slots) {
      for (i = 0; i < bundle->runtime_slot_count; i++) {
        Safefree(bundle->runtime_slots[i].field_name);
        Safefree(bundle->runtime_slots[i].result_name);
        Safefree(bundle->runtime_slots[i].return_type_name);
        gql_runtime_vm_free_native_arg_defs(aTHX_ bundle->runtime_slots[i].arg_defs, bundle->runtime_slots[i].arg_def_count);
      }
    }
  }
  Safefree(bundle->runtime_slots);
  if (bundle->blocks && bundle->owns_blocks) {
    for (i = 0; i < bundle->block_count; i++) {
      Safefree(bundle->blocks[i].type_name);
      SvREFCNT_dec(bundle->blocks[i].type_object_sv);
      if (bundle->blocks[i].slots) {
        for (j = 0; j < bundle->blocks[i].slot_count; j++) {
          Safefree(bundle->blocks[i].slots[j].field_name);
          Safefree(bundle->blocks[i].slots[j].result_name);
          Safefree(bundle->blocks[i].slots[j].return_type_name);
          gql_runtime_vm_free_native_arg_defs(aTHX_ bundle->blocks[i].slots[j].arg_defs, bundle->blocks[i].slots[j].arg_def_count);
        }
      }
      if (bundle->blocks[i].ops) {
        for (j = 0; j < bundle->blocks[i].op_count; j++) {
          gql_runtime_vm_free_op_abstract_child_names(aTHX_ &bundle->blocks[i].ops[j]);
          Safefree(bundle->blocks[i].ops[j].abstract_child_indexes);
          gql_runtime_vm_native_args_payload_destroy(aTHX_ bundle->blocks[i].ops[j].args_payload_native);
          gql_runtime_vm_native_directives_payload_destroy(aTHX_ bundle->blocks[i].ops[j].directives_payload_native);
          SvREFCNT_dec(bundle->blocks[i].ops[j].runtime_directives_sv);
        }
      }
      Safefree(bundle->blocks[i].slots);
      Safefree(bundle->blocks[i].ops);
    }
  }
  Safefree(bundle->blocks);
  SvREFCNT_dec(bundle->prepared_runtime_schema);
  Safefree(bundle);
}

static IV
gql_runtime_vm_program_needs_variable_specialization(gql_runtime_vm_native_program_t *program)
{
  IV i;
  IV j;
  if (!program) {
    return 0;
  }
  if (program->needs_variable_specialization) {
    return program->needs_variable_specialization == 2 ? 1 : 0;
  }
  program->needs_variable_specialization = 1;
  for (i = 0; i < program->block_count; i++) {
    gql_runtime_vm_native_block_t *block = &program->blocks[i];
    if (!block->ops) {
      continue;
    }
    for (j = 0; j < block->op_count; j++) {
      gql_runtime_vm_native_op_t *op = &block->ops[j];
      if (op->has_runtime_directives
          || (op->has_directives && op->directives_mode_code == GQL_VM_ARGS_DYNAMIC)) {
        program->needs_variable_specialization = 2;
        return 1;
      }
    }
  }
  return 0;
}

static void
gql_runtime_vm_native_program_destroy(gql_runtime_vm_native_program_t *program)
{
  IV i;
  IV j;
  if (!program) {
    return;
  }
  Safefree(program->operation_name);
  gql_runtime_vm_free_native_arg_defs(aTHX_ program->variable_defs, program->variable_def_count);
  if (program->blocks) {
    for (i = 0; i < program->block_count; i++) {
      Safefree(program->blocks[i].type_name);
      SvREFCNT_dec(program->blocks[i].type_object_sv);
      if (program->blocks[i].slots) {
        for (j = 0; j < program->blocks[i].slot_count; j++) {
          Safefree(program->blocks[i].slots[j].field_name);
          Safefree(program->blocks[i].slots[j].result_name);
          Safefree(program->blocks[i].slots[j].return_type_name);
          gql_runtime_vm_free_native_arg_defs(aTHX_ program->blocks[i].slots[j].arg_defs, program->blocks[i].slots[j].arg_def_count);
        }
      }
      if (program->blocks[i].ops) {
        for (j = 0; j < program->blocks[i].op_count; j++) {
          gql_runtime_vm_free_op_abstract_child_names(aTHX_ &program->blocks[i].ops[j]);
          Safefree(program->blocks[i].ops[j].abstract_child_indexes);
          gql_runtime_vm_native_args_payload_destroy(aTHX_ program->blocks[i].ops[j].args_payload_native);
          gql_runtime_vm_native_directives_payload_destroy(aTHX_ program->blocks[i].ops[j].directives_payload_native);
          SvREFCNT_dec(program->blocks[i].ops[j].runtime_directives_sv);
        }
      }
      Safefree(program->blocks[i].slots);
      Safefree(program->blocks[i].ops);
    }
  }
  if (program->args_payloads) {
    for (i = 0; i < program->args_payload_count; i++) {
      gql_runtime_vm_native_args_payload_destroy(aTHX_ program->args_payloads[i]);
    }
  }
  if (program->directives_payloads) {
    for (i = 0; i < program->directives_payload_count; i++) {
      gql_runtime_vm_native_directives_payload_destroy(aTHX_ program->directives_payloads[i]);
    }
  }
  gql_runtime_vm_native_bundle_destroy(program->cached_bundle);
  Safefree(program->args_payloads);
  Safefree(program->directives_payloads);
  Safefree(program->blocks);
  Safefree(program);
}

static void
gql_runtime_vm_native_runtime_destroy(gql_runtime_vm_native_runtime_t *runtime)
{
  IV i;
  if (!runtime) {
    return;
  }
  if (runtime->runtime_slots) {
    for (i = 0; i < runtime->runtime_slot_count; i++) {
      Safefree(runtime->runtime_slots[i].field_name);
      Safefree(runtime->runtime_slots[i].result_name);
      Safefree(runtime->runtime_slots[i].return_type_name);
      gql_runtime_vm_free_native_arg_defs(aTHX_ runtime->runtime_slots[i].arg_defs, runtime->runtime_slots[i].arg_def_count);
    }
  }
  Safefree(runtime->runtime_slots);
  if (runtime->callback_catalog && runtime->callback_catalog->slot_resolvers) {
    gql_runtime_vm_native_callback_catalog_t *catalog = runtime->callback_catalog;
    for (i = 0; i < runtime->runtime_slot_count; i++) {
      if (catalog->slot_field_names && catalog->slot_field_names[i]) {
        SvREFCNT_dec(catalog->slot_field_names[i]);
      }
      if (catalog->slot_resolvers[i]) {
        SvREFCNT_dec(catalog->slot_resolvers[i]);
      }
      if (catalog->slot_type_objects && catalog->slot_type_objects[i]) {
        SvREFCNT_dec(catalog->slot_type_objects[i]);
      }
      if (catalog->slot_tag_resolvers && catalog->slot_tag_resolvers[i]) {
        SvREFCNT_dec(catalog->slot_tag_resolvers[i]);
      }
      if (catalog->slot_resolve_types && catalog->slot_resolve_types[i]) {
        SvREFCNT_dec(catalog->slot_resolve_types[i]);
      }
      if (catalog->slot_leaf_payloads && catalog->slot_leaf_payloads[i]) {
        SvREFCNT_dec(catalog->slot_leaf_payloads[i]);
      }
      if (catalog->slot_tag_entries && catalog->slot_tag_entries[i]) {
        IV j;
        for (j = 0; j < catalog->slot_tag_entry_counts[i]; j++) {
          Safefree(catalog->slot_tag_entries[i][j].tag_name);
          Safefree(catalog->slot_tag_entries[i][j].type_name);
        }
        Safefree(catalog->slot_tag_entries[i]);
      }
      if (catalog->slot_possible_type_entries && catalog->slot_possible_type_entries[i]) {
        IV j;
        for (j = 0; j < catalog->slot_possible_type_entry_counts[i]; j++) {
          Safefree(catalog->slot_possible_type_entries[i][j].type_name);
          SvREFCNT_dec(catalog->slot_possible_type_entries[i][j].type_sv);
          SvREFCNT_dec(catalog->slot_possible_type_entries[i][j].is_type_of_cb);
        }
        Safefree(catalog->slot_possible_type_entries[i]);
      }
    }
    Safefree(catalog->slot_field_names);
    Safefree(catalog->slot_resolvers);
    Safefree(catalog->slot_type_objects);
    Safefree(catalog->slot_tag_resolvers);
    Safefree(catalog->slot_tag_entries);
    Safefree(catalog->slot_tag_entry_counts);
    Safefree(catalog->slot_resolve_types);
    Safefree(catalog->slot_possible_type_entries);
    Safefree(catalog->slot_possible_type_entry_counts);
    Safefree(catalog->slot_leaf_kinds);
    Safefree(catalog->slot_leaf_payloads);
    if (catalog->runtime_schema) {
      SvREFCNT_dec(catalog->runtime_schema);
    }
    Safefree(catalog);
  }
  Safefree(runtime);
}

static int
gql_runtime_vm_fetch_hv_string(pTHX_ HV *hv, const char *key, I32 keylen, char **out)
{
  SV **svp = hv_fetch(hv, key, keylen, 0);
  STRLEN len;
  const char *pv;
  if (!svp || !SvOK(*svp)) {
    return 0;
  }
  pv = SvPV(*svp, len);
  Newxz(*out, len + 1, char);
  Copy(pv, *out, len, char);
  (*out)[len] = '\0';
  return 1;
}

static void
gql_runtime_vm_free_native_arg_defs(pTHX_ gql_runtime_vm_native_arg_def_t *arg_defs, IV count)
{
  IV i;
  if (!arg_defs) {
    return;
  }
  for (i = 0; i < count; i++) {
    Safefree(arg_defs[i].name);
    if (arg_defs[i].type_def_sv) {
      SvREFCNT_dec(arg_defs[i].type_def_sv);
    }
    if (arg_defs[i].input_type_sv) {
      SvREFCNT_dec(arg_defs[i].input_type_sv);
    }
    if (arg_defs[i].default_value_sv) {
      SvREFCNT_dec(arg_defs[i].default_value_sv);
    }
    if (arg_defs[i].default_native_value) {
      gql_runtime_vm_native_value_destroy(aTHX_ arg_defs[i].default_native_value);
    }
  }
  Safefree(arg_defs);
}

static int
gql_runtime_vm_parse_native_arg_defs(pTHX_ SV *sv, gql_runtime_vm_native_arg_def_t **out_defs, IV *out_count)
{
  AV *defs_av;
  HV *defs_hv;
  IV i;
  *out_defs = NULL;
  *out_count = 0;
  if (!sv || !SvOK(sv)) {
    return 1;
  }
  if (gql_runtime_vm_sv_to_hv(aTHX_ sv, &defs_hv)) {
    HE *he;
    IV count = hv_iterinit(defs_hv);
    if (count <= 0) {
      return 1;
    }
    Newxz(*out_defs, count, gql_runtime_vm_native_arg_def_t);
    *out_count = count;
    i = 0;
    while ((he = hv_iternext(defs_hv))) {
      SV *value_sv = hv_iterval(defs_hv, he);
      SV *key_sv = hv_iterkeysv(he);
      HV *def_hv = NULL;
      SV **svp;
      gql_runtime_vm_native_arg_def_t *def = &(*out_defs)[i++];

      if (key_sv && SvOK(key_sv)) {
        STRLEN len;
        const char *pv = SvPV(key_sv, len);
        Newxz(def->name, len + 1, char);
        Copy(pv, def->name, len, char);
        def->name[len] = '\0';
      }

      if (!value_sv || !gql_runtime_vm_sv_to_hv(aTHX_ value_sv, &def_hv)) {
        gql_runtime_vm_free_native_arg_defs(aTHX_ *out_defs, *out_count);
        *out_defs = NULL;
        *out_count = 0;
        croak("native VM slot arg_defs hash entry must be a hash reference");
      }

      svp = hv_fetch(def_hv, "type", 4, 0);
      def->type_def_sv = (svp && SvOK(*svp)) ? newSVsv(*svp) : NULL;

      svp = hv_fetch(def_hv, "has_default", 11, 0);
      def->has_default = (svp && SvOK(*svp) && SvTRUE(*svp)) ? 1 : 0;

      svp = hv_fetch(def_hv, "default_value", 13, 0);
      def->default_value_sv = (svp && SvOK(*svp)) ? newSVsv(*svp) : NULL;
    }
    return 1;
  }
  if (!gql_runtime_vm_sv_to_av(aTHX_ sv, &defs_av)) {
    croak("native VM slot arg_defs must be an array reference or hash reference");
  }
  *out_count = av_count(defs_av);
  if (*out_count <= 0) {
    *out_count = 0;
    return 1;
  }
  Newxz(*out_defs, *out_count, gql_runtime_vm_native_arg_def_t);
  for (i = 0; i < *out_count; i++) {
    SV **entry_svp = av_fetch(defs_av, i, 0);
    AV *entry_av;
    SV **svp;
    gql_runtime_vm_native_arg_def_t *def;
    if (!entry_svp || !gql_runtime_vm_sv_to_av(aTHX_ *entry_svp, &entry_av)) {
      gql_runtime_vm_free_native_arg_defs(aTHX_ *out_defs, *out_count);
      *out_defs = NULL;
      *out_count = 0;
      croak("native VM slot arg_defs entry must be an array reference");
    }
    def = &(*out_defs)[i];
    svp = av_fetch(entry_av, 0, 0);
    if (!svp || !SvOK(*svp)) {
      gql_runtime_vm_free_native_arg_defs(aTHX_ *out_defs, *out_count);
      *out_defs = NULL;
      *out_count = 0;
      croak("native VM slot arg_defs entry is missing name");
    }
    {
      STRLEN len;
      const char *pv = SvPV(*svp, len);
      Newxz(def->name, len + 1, char);
      Copy(pv, def->name, len, char);
      def->name[len] = '\0';
    }
    svp = av_fetch(entry_av, 1, 0);
    def->type_def_sv = (svp && SvOK(*svp)) ? newSVsv(*svp) : NULL;
    svp = av_fetch(entry_av, 2, 0);
    def->has_default = (svp && SvOK(*svp) && SvTRUE(*svp)) ? 1 : 0;
    svp = av_fetch(entry_av, 3, 0);
    def->default_value_sv = (svp && SvOK(*svp)) ? newSVsv(*svp) : NULL;
  }
  return 1;
}

static int
gql_runtime_vm_fetch_hv_iv(pTHX_ HV *hv, const char *key, I32 keylen, IV *out)
{
  SV **svp = hv_fetch(hv, key, keylen, 0);
  if (!svp || !SvOK(*svp)) {
    return 0;
  }
  *out = SvIV(*svp);
  return 1;
}

static int
gql_runtime_vm_fetch_hv_bool(pTHX_ HV *hv, const char *key, I32 keylen, U8 *out)
{
  IV value = 0;
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ hv, key, keylen, &value)) {
    return 0;
  }
  *out = value ? 1 : 0;
  return 1;
}

static int
gql_runtime_vm_sv_to_hv(pTHX_ SV *sv, HV **out)
{
  if (!sv || !SvOK(sv) || !SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV) {
    return 0;
  }
  *out = (HV *)SvRV(sv);
  return 1;
}

static int
gql_runtime_vm_sv_to_av(pTHX_ SV *sv, AV **out)
{
  if (!sv || !SvOK(sv) || !SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV) {
    return 0;
  }
  *out = (AV *)SvRV(sv);
  return 1;
}

static int
gql_runtime_vm_parse_native_slot(pTHX_ SV *sv, gql_runtime_vm_native_slot_t *out)
{
  HV *hv;
  AV *av;
  SV **svp;
  if (gql_runtime_vm_sv_to_av(aTHX_ sv, &av)) {
    svp = av_fetch(av, 0, 0);
    if (!svp || !SvOK(*svp)) croak("native VM slot entry is missing field_name");
    {
      STRLEN len;
      const char *pv = SvPV(*svp, len);
      Newxz(out->field_name, len + 1, char);
      Copy(pv, out->field_name, len, char);
      out->field_name[len] = '\0';
      out->field_name_len = len;
    }
    svp = av_fetch(av, 1, 0);
    if (!svp || !SvOK(*svp)) croak("native VM slot entry is missing result_name");
    {
      STRLEN len;
      const char *pv = SvPV(*svp, len);
      Newxz(out->result_name, len + 1, char);
      Copy(pv, out->result_name, len, char);
      out->result_name[len] = '\0';
      out->result_name_len = len;
    }
    svp = av_fetch(av, 2, 0);
    if (!svp || !SvOK(*svp)) croak("native VM slot entry is missing return_type_name");
    {
      STRLEN len;
      const char *pv = SvPV(*svp, len);
      Newxz(out->return_type_name, len + 1, char);
      Copy(pv, out->return_type_name, len, char);
      out->return_type_name[len] = '\0';
    }
    svp = av_fetch(av, 3, 0);
    out->schema_slot_index = (svp && SvOK(*svp)) ? SvIV(*svp) : -1;
    svp = av_fetch(av, 4, 0);
    out->resolver_shape_code = (svp && SvOK(*svp)) ? SvIV(*svp) : 0;
    svp = av_fetch(av, 5, 0);
    out->completion_family_code = (svp && SvOK(*svp)) ? SvIV(*svp) : 0;
    svp = av_fetch(av, 6, 0);
    out->dispatch_family_code = (svp && SvOK(*svp)) ? SvIV(*svp) : 0;
    svp = av_fetch(av, 7, 0);
    out->return_type_kind_code = (svp && SvOK(*svp)) ? SvIV(*svp) : 0;
    svp = av_fetch(av, 8, 0);
    out->has_args = (svp && SvOK(*svp) && SvTRUE(*svp)) ? 1 : 0;
    svp = av_fetch(av, 9, 0);
    out->has_directives = (svp && SvOK(*svp) && SvTRUE(*svp)) ? 1 : 0;
    svp = av_fetch(av, 10, 0);
    out->resolver_mode_code = (svp && SvOK(*svp)) ? SvIV(*svp) : 0;
    svp = av_fetch(av, 11, 0);
    gql_runtime_vm_parse_native_arg_defs(aTHX_ (svp ? *svp : NULL), &out->arg_defs, &out->arg_def_count);
    svp = av_fetch(av, 12, 0);
    out->callback_abi_code = (svp && SvOK(*svp))
      ? SvIV(*svp)
      : gql_runtime_vm_infer_callback_abi_code(out->resolver_shape_code, out->resolver_mode_code);
    svp = av_fetch(av, 13, 0);
    out->item_non_null = (svp && SvOK(*svp) && SvTRUE(*svp)) ? 1 : 0;
    return 1;
  }
  if (!gql_runtime_vm_sv_to_hv(aTHX_ sv, &hv)) {
    croak("native VM slot entry must be a hash reference");
  }
  if (!gql_runtime_vm_fetch_hv_string(aTHX_ hv, "field_name", 10, &out->field_name)) {
    croak("native VM slot entry is missing field_name");
  }
  out->field_name_len = out->field_name ? strlen(out->field_name) : 0;
  if (!gql_runtime_vm_fetch_hv_string(aTHX_ hv, "result_name", 11, &out->result_name)) {
    croak("native VM slot entry is missing result_name");
  }
  out->result_name_len = out->result_name ? strlen(out->result_name) : 0;
  if (!gql_runtime_vm_fetch_hv_string(aTHX_ hv, "return_type_name", 16, &out->return_type_name)) {
    croak("native VM slot entry is missing return_type_name");
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ hv, "schema_slot_index", 17, &out->schema_slot_index)) {
    croak("native VM slot entry is missing schema_slot_index");
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ hv, "resolver_shape_code", 19, &out->resolver_shape_code)) {
    croak("native VM slot entry is missing resolver_shape_code");
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ hv, "resolver_mode_code", 18, &out->resolver_mode_code)) {
    croak("native VM slot entry is missing resolver_mode_code");
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ hv, "completion_family_code", 22, &out->completion_family_code)) {
    croak("native VM slot entry is missing completion_family_code");
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ hv, "dispatch_family_code", 20, &out->dispatch_family_code)) {
    croak("native VM slot entry is missing dispatch_family_code");
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ hv, "return_type_kind_code", 21, &out->return_type_kind_code)) {
    croak("native VM slot entry is missing return_type_kind_code");
  }
  if (!gql_runtime_vm_fetch_hv_bool(aTHX_ hv, "has_args", 8, &out->has_args)) {
    croak("native VM slot entry is missing has_args");
  }
  if (!gql_runtime_vm_fetch_hv_bool(aTHX_ hv, "has_directives", 14, &out->has_directives)) {
    croak("native VM slot entry is missing has_directives");
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ hv, "callback_abi_code", 17, &out->callback_abi_code)) {
    out->callback_abi_code = gql_runtime_vm_infer_callback_abi_code(
      out->resolver_shape_code,
      out->resolver_mode_code
    );
  }
  {
    SV **item_nn_svp = hv_fetch(hv, "item_non_null", 13, 0);
    out->item_non_null = (item_nn_svp && SvOK(*item_nn_svp) && SvTRUE(*item_nn_svp)) ? 1 : 0;
  }
  svp = hv_fetch(hv, "arg_defs", 8, 0);
  gql_runtime_vm_parse_native_arg_defs(aTHX_ (svp ? *svp : NULL), &out->arg_defs, &out->arg_def_count);
  return 1;
}

static void
gql_runtime_vm_clone_native_slot(
  pTHX_
  const gql_runtime_vm_native_slot_t *src,
  gql_runtime_vm_native_slot_t *dst
)
{
  Zero(dst, 1, gql_runtime_vm_native_slot_t);
  dst->schema_slot_index = src->schema_slot_index;
  dst->resolver_shape_code = src->resolver_shape_code;
  dst->resolver_mode_code = src->resolver_mode_code;
  dst->callback_abi_code = src->callback_abi_code;
  dst->completion_family_code = src->completion_family_code;
  dst->dispatch_family_code = src->dispatch_family_code;
  dst->return_type_kind_code = src->return_type_kind_code;
  dst->arg_def_count = src->arg_def_count;
  dst->has_args = src->has_args;
  dst->has_directives = src->has_directives;
  dst->item_non_null = src->item_non_null;
  if (src->field_name) {
    STRLEN len = src->field_name_len ? src->field_name_len : strlen(src->field_name);
    Newxz(dst->field_name, len + 1, char);
    Copy(src->field_name, dst->field_name, len, char);
    dst->field_name[len] = '\0';
    dst->field_name_len = len;
  }
  if (src->result_name) {
    STRLEN len = src->result_name_len ? src->result_name_len : strlen(src->result_name);
    Newxz(dst->result_name, len + 1, char);
    Copy(src->result_name, dst->result_name, len, char);
    dst->result_name[len] = '\0';
    dst->result_name_len = len;
  }
  if (src->return_type_name) {
    STRLEN len = strlen(src->return_type_name);
    Newxz(dst->return_type_name, len + 1, char);
    Copy(src->return_type_name, dst->return_type_name, len, char);
    dst->return_type_name[len] = '\0';
  }
  if (src->arg_def_count > 0 && src->arg_defs) {
    IV i;
    Newxz(dst->arg_defs, src->arg_def_count, gql_runtime_vm_native_arg_def_t);
    for (i = 0; i < src->arg_def_count; i++) {
      gql_runtime_vm_native_arg_def_t *src_def = &src->arg_defs[i];
      gql_runtime_vm_native_arg_def_t *dst_def = &dst->arg_defs[i];
      dst_def->has_default = src_def->has_default;
      dst_def->input_type_nonnull_state = src_def->input_type_nonnull_state;
      if (src_def->name) {
        STRLEN len = strlen(src_def->name);
        Newxz(dst_def->name, len + 1, char);
        Copy(src_def->name, dst_def->name, len, char);
        dst_def->name[len] = '\0';
      }
      if (src_def->type_def_sv) {
        dst_def->type_def_sv = newSVsv(src_def->type_def_sv);
      }
      if (src_def->input_type_sv) {
        dst_def->input_type_sv = newSVsv(src_def->input_type_sv);
      }
      if (src_def->default_value_sv) {
        dst_def->default_value_sv = newSVsv(src_def->default_value_sv);
      }
      if (src_def->default_native_value) {
        dst_def->default_native_value = gql_runtime_vm_native_value_clone(aTHX_ src_def->default_native_value);
      }
    }
  }
}

static void
gql_runtime_vm_clone_native_op(
  pTHX_
  const gql_runtime_vm_native_op_t *src,
  gql_runtime_vm_native_op_t *dst
)
{
  IV i;
  Zero(dst, 1, gql_runtime_vm_native_op_t);
  *dst = *src;
  dst->abstract_child_names = NULL;
  dst->abstract_child_indexes = NULL;
  dst->args_payload_native = NULL;
  dst->directives_payload_native = NULL;
  if (src->abstract_child_count > 0) {
    Newxz(dst->abstract_child_names, src->abstract_child_count, char *);
    Newxz(dst->abstract_child_indexes, src->abstract_child_count, IV);
    for (i = 0; i < src->abstract_child_count; i++) {
      dst->abstract_child_indexes[i] = src->abstract_child_indexes[i];
      if (src->abstract_child_names && src->abstract_child_names[i]) {
        STRLEN len = strlen(src->abstract_child_names[i]);
        Newxz(dst->abstract_child_names[i], len + 1, char);
        Copy(src->abstract_child_names[i], dst->abstract_child_names[i], len, char);
        dst->abstract_child_names[i][len] = '\0';
      }
    }
  }
  if (src->args_payload_native) {
    dst->args_payload_native = gql_runtime_vm_native_args_payload_clone(aTHX_ src->args_payload_native);
  }
  if (src->directives_payload_native) {
    dst->directives_payload_native = gql_runtime_vm_native_directives_payload_clone(aTHX_ src->directives_payload_native);
  }
  if (src->runtime_directives_sv) {
    dst->runtime_directives_sv = newSVsv(src->runtime_directives_sv);
  }
}

static void
gql_runtime_vm_clone_native_block(
  pTHX_
  const gql_runtime_vm_native_block_t *src,
  gql_runtime_vm_native_block_t *dst
)
{
  IV i;
  Zero(dst, 1, gql_runtime_vm_native_block_t);
  dst->family_code = src->family_code;
  dst->slot_count = src->slot_count;
  dst->op_count = src->op_count;
  if (src->type_name) {
    STRLEN len = strlen(src->type_name);
    Newxz(dst->type_name, len + 1, char);
    Copy(src->type_name, dst->type_name, len, char);
    dst->type_name[len] = '\0';
  }
  if (src->slot_count > 0) {
    Newxz(dst->slots, src->slot_count, gql_runtime_vm_native_slot_t);
    for (i = 0; i < src->slot_count; i++) {
      gql_runtime_vm_clone_native_slot(aTHX_ &src->slots[i], &dst->slots[i]);
    }
  }
  if (src->op_count > 0) {
    Newxz(dst->ops, src->op_count, gql_runtime_vm_native_op_t);
    for (i = 0; i < src->op_count; i++) {
      gql_runtime_vm_clone_native_op(aTHX_ &src->ops[i], &dst->ops[i]);
    }
  }
}

static int
gql_runtime_vm_parse_native_op(pTHX_ SV *sv, gql_runtime_vm_native_op_t *out)
{
  HV *hv;
  AV *av;
  HV *children_hv;
  HE *he;
  SV **svp;
  IV idx;
  if (gql_runtime_vm_sv_to_av(aTHX_ sv, &av)) {
    svp = av_fetch(av, 0, 0);
    out->opcode_code = (svp && SvOK(*svp)) ? SvIV(*svp) : 0;
    svp = av_fetch(av, 1, 0);
    out->resolve_code = (svp && SvOK(*svp)) ? SvIV(*svp) : 0;
    svp = av_fetch(av, 2, 0);
    out->complete_code = (svp && SvOK(*svp)) ? SvIV(*svp) : 0;
    svp = av_fetch(av, 3, 0);
    out->dispatch_family_code = (svp && SvOK(*svp)) ? SvIV(*svp) : 0;
    svp = av_fetch(av, 4, 0);
    out->slot_index = (svp && SvOK(*svp)) ? SvIV(*svp) : -1;
    svp = av_fetch(av, 5, 0);
    out->child_block_index = (svp && SvOK(*svp)) ? SvIV(*svp) : -1;
    svp = av_fetch(av, 6, 0);
    if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
      children_hv = (HV *)SvRV(*svp);
      out->abstract_child_count = hv_iterinit(children_hv);
      if (out->abstract_child_count > 0) {
        Newxz(out->abstract_child_names, out->abstract_child_count, char *);
        Newxz(out->abstract_child_indexes, out->abstract_child_count, IV);
        idx = 0;
        hv_iterinit(children_hv);
        while ((he = hv_iternext(children_hv))) {
          STRLEN keylen;
          const char *key = HePV(he, keylen);
          SV *val = HeVAL(he);
          Newxz(out->abstract_child_names[idx], keylen + 1, char);
          Copy(key, out->abstract_child_names[idx], keylen, char);
          out->abstract_child_names[idx][keylen] = '\0';
          out->abstract_child_indexes[idx] = (val && SvOK(val)) ? SvIV(val) : -1;
          idx++;
        }
      }
    } else {
      out->abstract_child_count = 0;
      out->abstract_child_names = NULL;
      out->abstract_child_indexes = NULL;
    }
    svp = av_fetch(av, 7, 0);
    out->args_mode_code = (svp && SvOK(*svp)) ? SvIV(*svp) : GQL_VM_ARGS_NONE;
    svp = av_fetch(av, 8, 0);
    out->args_payload_index = (svp && SvOK(*svp)) ? SvIV(*svp) : -1;
    svp = av_fetch(av, 9, 0);
    out->args_payload_native =
      (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV)
      ? gql_runtime_vm_native_args_payload_from_hv(aTHX_ (HV *)SvRV(*svp))
      : NULL;
    svp = av_fetch(av, 10, 0);
    out->has_args = (svp && SvOK(*svp) && SvTRUE(*svp)) ? 1 : 0;
    svp = av_fetch(av, 11, 0);
    out->directives_mode_code = (svp && SvOK(*svp)) ? SvIV(*svp) : GQL_VM_ARGS_NONE;
    svp = av_fetch(av, 12, 0);
    out->directives_payload_index = (svp && SvOK(*svp)) ? SvIV(*svp) : -1;
    svp = av_fetch(av, 13, 0);
    out->directives_payload_native = (svp && SvOK(*svp))
      ? gql_runtime_vm_native_directives_payload_from_sv(aTHX_ *svp)
      : NULL;
    svp = av_fetch(av, 14, 0);
    out->has_directives = (svp && SvOK(*svp) && SvTRUE(*svp)) ? 1 : 0;
    svp = av_fetch(av, 18, 0);
    out->runtime_directives_mode_code = (svp && SvOK(*svp)) ? SvIV(*svp) : GQL_VM_ARGS_NONE;
    svp = av_fetch(av, 19, 0);
    out->runtime_directives_sv = (svp && SvOK(*svp)) ? newSVsv(*svp) : NULL;
    svp = av_fetch(av, 20, 0);
    out->has_runtime_directives = (svp && SvOK(*svp) && SvTRUE(*svp)) ? 1 : 0;
    return 1;
  }
  if (!gql_runtime_vm_sv_to_hv(aTHX_ sv, &hv)) {
    croak("native VM op entry must be a hash reference");
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ hv, "opcode_code", 11, &out->opcode_code)) {
    croak("native VM op entry is missing opcode_code");
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ hv, "resolve_code", 12, &out->resolve_code)) {
    croak("native VM op entry is missing resolve_code");
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ hv, "complete_code", 13, &out->complete_code)) {
    croak("native VM op entry is missing complete_code");
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ hv, "dispatch_family_code", 20, &out->dispatch_family_code)) {
    croak("native VM op entry is missing dispatch_family_code");
  }
  svp = hv_fetch(hv, "slot_index", 10, 0);
  out->slot_index = (svp && SvOK(*svp)) ? SvIV(*svp) : -1;
  svp = hv_fetch(hv, "child_block_index", 17, 0);
  out->child_block_index = (svp && SvOK(*svp)) ? SvIV(*svp) : -1;
  if (!gql_runtime_vm_fetch_hv_bool(aTHX_ hv, "has_args", 8, &out->has_args)) {
    croak("native VM op entry is missing has_args");
  }
  if (!gql_runtime_vm_fetch_hv_bool(aTHX_ hv, "has_directives", 14, &out->has_directives)) {
    croak("native VM op entry is missing has_directives");
  }
  svp = hv_fetch(hv, "runtime_directives_mode_code", 28, 0);
  out->runtime_directives_mode_code = (svp && SvOK(*svp)) ? SvIV(*svp) : GQL_VM_ARGS_NONE;
  svp = hv_fetch(hv, "runtime_directives_payload", 26, 0);
  out->runtime_directives_sv = (svp && SvOK(*svp)) ? newSVsv(*svp) : NULL;
  svp = hv_fetch(hv, "has_runtime_directives", 22, 0);
  out->has_runtime_directives = (svp && SvOK(*svp) && SvTRUE(*svp)) ? 1 : 0;
  svp = hv_fetch(hv, "directives_mode_code", 20, 0);
  out->directives_mode_code = (svp && SvOK(*svp)) ? SvIV(*svp) : GQL_VM_ARGS_NONE;
  svp = hv_fetch(hv, "abstract_child_block_indexes", 28, 0);
  if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
    children_hv = (HV *)SvRV(*svp);
    out->abstract_child_count = hv_iterinit(children_hv);
    if (out->abstract_child_count > 0) {
      Newxz(out->abstract_child_names, out->abstract_child_count, char *);
      Newxz(out->abstract_child_indexes, out->abstract_child_count, IV);
      idx = 0;
      hv_iterinit(children_hv);
      while ((he = hv_iternext(children_hv))) {
        STRLEN keylen;
        const char *key = HePV(he, keylen);
        SV *val = HeVAL(he);
        Newxz(out->abstract_child_names[idx], keylen + 1, char);
        Copy(key, out->abstract_child_names[idx], keylen, char);
        out->abstract_child_names[idx][keylen] = '\0';
        out->abstract_child_indexes[idx] = (val && SvOK(val)) ? SvIV(val) : -1;
        idx++;
      }
    }
  } else {
    out->abstract_child_count = 0;
    out->abstract_child_names = NULL;
    out->abstract_child_indexes = NULL;
  }
  svp = hv_fetch(hv, "args_mode_code", 14, 0);
  out->args_mode_code = (svp && SvOK(*svp)) ? SvIV(*svp) : GQL_VM_ARGS_NONE;
  svp = hv_fetch(hv, "args_payload_index", 18, 0);
  out->args_payload_index = (svp && SvOK(*svp)) ? SvIV(*svp) : -1;
  svp = hv_fetch(hv, "args_payload", 12, 0);
  out->args_payload_native =
    (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV)
    ? gql_runtime_vm_native_args_payload_from_hv(aTHX_ (HV *)SvRV(*svp))
    : NULL;
  svp = hv_fetch(hv, "directives_payload_index", 24, 0);
  out->directives_payload_index = (svp && SvOK(*svp)) ? SvIV(*svp) : -1;
  svp = hv_fetch(hv, "directives_payload", 18, 0);
  out->directives_payload_native = (svp && SvOK(*svp))
    ? gql_runtime_vm_native_directives_payload_from_sv(aTHX_ *svp)
    : NULL;
  return 1;
}

static void
gql_runtime_vm_parse_native_program_payload_catalogs(
  pTHX_
  HV *program_hv,
  gql_runtime_vm_native_program_t *program
)
{
  AV *payloads_av;
  IV i;
  SV **svp;

  svp = hv_fetch(program_hv, "args_payloads_compact", 21, 0);
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &payloads_av)) {
    svp = hv_fetch(program_hv, "args_payloads", 13, 0);
  }
  if (svp && gql_runtime_vm_sv_to_av(aTHX_ *svp, &payloads_av)) {
    program->args_payload_count = av_len(payloads_av) + 1;
    if (program->args_payload_count > 0) {
      Newxz(program->args_payloads, program->args_payload_count, gql_runtime_vm_native_args_payload_t *);
      for (i = 0; i < program->args_payload_count; i++) {
        SV **payload_svp = av_fetch(payloads_av, i, 0);
        if (!payload_svp) {
          gql_runtime_vm_native_program_destroy(program);
          croak("native VM args payload entry %ld is missing", (long)i);
        }
        if (*payload_svp && SvOK(*payload_svp) && SvROK(*payload_svp) && SvTYPE(SvRV(*payload_svp)) == SVt_PVHV) {
          program->args_payloads[i] =
            gql_runtime_vm_native_args_payload_from_hv(aTHX_ (HV *)SvRV(*payload_svp));
        }
      }
    }
  }

  svp = hv_fetch(program_hv, "directives_payloads_compact", 27, 0);
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &payloads_av)) {
    svp = hv_fetch(program_hv, "directives_payloads", 19, 0);
  }
  if (svp && gql_runtime_vm_sv_to_av(aTHX_ *svp, &payloads_av)) {
    program->directives_payload_count = av_len(payloads_av) + 1;
    if (program->directives_payload_count > 0) {
      Newxz(program->directives_payloads, program->directives_payload_count, gql_runtime_vm_native_directives_payload_t *);
      for (i = 0; i < program->directives_payload_count; i++) {
        SV **payload_svp = av_fetch(payloads_av, i, 0);
        if (!payload_svp) {
          gql_runtime_vm_native_program_destroy(program);
          croak("native VM directives payload entry %ld is missing", (long)i);
        }
        if (*payload_svp && SvOK(*payload_svp)) {
          program->directives_payloads[i] =
            gql_runtime_vm_native_directives_payload_from_sv(aTHX_ *payload_svp);
        }
      }
    }
  }
}

static void
gql_runtime_vm_free_native_payload_catalogs(
  pTHX_
  gql_runtime_vm_native_args_payload_t **args_payloads,
  IV args_payload_count,
  gql_runtime_vm_native_directives_payload_t **directives_payloads,
  IV directives_payload_count
)
{
  IV i;
  if (args_payloads) {
    for (i = 0; i < args_payload_count; i++) {
      gql_runtime_vm_native_args_payload_destroy(aTHX_ args_payloads[i]);
    }
  }
  if (directives_payloads) {
    for (i = 0; i < directives_payload_count; i++) {
      gql_runtime_vm_native_directives_payload_destroy(aTHX_ directives_payloads[i]);
    }
  }
  Safefree(args_payloads);
  Safefree(directives_payloads);
}

static void
gql_runtime_vm_parse_native_payload_catalogs(
  pTHX_
  HV *program_hv,
  gql_runtime_vm_native_args_payload_t ***args_payloads_out,
  IV *args_payload_count_out,
  gql_runtime_vm_native_directives_payload_t ***directives_payloads_out,
  IV *directives_payload_count_out
)
{
  AV *payloads_av;
  IV i;
  SV **svp;

  *args_payloads_out = NULL;
  *args_payload_count_out = 0;
  *directives_payloads_out = NULL;
  *directives_payload_count_out = 0;

  svp = hv_fetch(program_hv, "args_payloads_compact", 21, 0);
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &payloads_av)) {
    svp = hv_fetch(program_hv, "args_payloads", 13, 0);
  }
  if (svp && gql_runtime_vm_sv_to_av(aTHX_ *svp, &payloads_av)) {
    *args_payload_count_out = av_len(payloads_av) + 1;
    if (*args_payload_count_out > 0) {
      Newxz(*args_payloads_out, *args_payload_count_out, gql_runtime_vm_native_args_payload_t *);
      for (i = 0; i < *args_payload_count_out; i++) {
        SV **payload_svp = av_fetch(payloads_av, i, 0);
        if (!payload_svp) {
          gql_runtime_vm_free_native_payload_catalogs(
            aTHX_ *args_payloads_out,
            *args_payload_count_out,
            *directives_payloads_out,
            *directives_payload_count_out
          );
          croak("native VM args payload entry %ld is missing", (long)i);
        }
        if (*payload_svp && SvOK(*payload_svp) && SvROK(*payload_svp) && SvTYPE(SvRV(*payload_svp)) == SVt_PVHV) {
          (*args_payloads_out)[i] =
            gql_runtime_vm_native_args_payload_from_hv(aTHX_ (HV *)SvRV(*payload_svp));
        }
      }
    }
  }

  svp = hv_fetch(program_hv, "directives_payloads_compact", 27, 0);
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &payloads_av)) {
    svp = hv_fetch(program_hv, "directives_payloads", 19, 0);
  }
  if (svp && gql_runtime_vm_sv_to_av(aTHX_ *svp, &payloads_av)) {
    *directives_payload_count_out = av_len(payloads_av) + 1;
    if (*directives_payload_count_out > 0) {
      Newxz(*directives_payloads_out, *directives_payload_count_out, gql_runtime_vm_native_directives_payload_t *);
      for (i = 0; i < *directives_payload_count_out; i++) {
        SV **payload_svp = av_fetch(payloads_av, i, 0);
        if (!payload_svp) {
          gql_runtime_vm_free_native_payload_catalogs(
            aTHX_ *args_payloads_out,
            *args_payload_count_out,
            *directives_payloads_out,
            *directives_payload_count_out
          );
          croak("native VM directives payload entry %ld is missing", (long)i);
        }
        if (*payload_svp && SvOK(*payload_svp)) {
          (*directives_payloads_out)[i] =
            gql_runtime_vm_native_directives_payload_from_sv(aTHX_ *payload_svp);
        }
      }
    }
  }
}

static int
gql_runtime_vm_parse_native_block(pTHX_ SV *sv, gql_runtime_vm_native_block_t *out)
{
  HV *hv;
  AV *av;
  AV *slots_av;
  AV *ops_av;
  IV i;
  SV **svp;
  if (gql_runtime_vm_sv_to_av(aTHX_ sv, &av)) {
    /* index 0 is the block name; the native block keeps only type_name. */
    SV **type_svp = av_fetch(av, 1, 0);
    SV **family_svp = av_fetch(av, 2, 0);
    SV **slots_svp = av_fetch(av, 3, 0);
    SV **ops_svp = av_fetch(av, 4, 0);
    if (!family_svp || !SvOK(*family_svp)) return 0;
    if (!type_svp || !SvOK(*type_svp)) croak("native VM block entry is missing type_name");
    out->family_code = SvIV(*family_svp);
    {
      STRLEN len;
      const char *pv = SvPV(*type_svp, len);
      Newxz(out->type_name, len + 1, char);
      Copy(pv, out->type_name, len, char);
      out->type_name[len] = '\0';
    }
    if (!slots_svp || !gql_runtime_vm_sv_to_av(aTHX_ *slots_svp, &slots_av)) return 0;
    if (!ops_svp || !gql_runtime_vm_sv_to_av(aTHX_ *ops_svp, &ops_av)) return 0;
    out->slot_count = av_count(slots_av);
    out->op_count = av_count(ops_av);
    out->slots = NULL;
    out->ops = NULL;
    if (out->slot_count > 0) {
      Newxz(out->slots, out->slot_count, gql_runtime_vm_native_slot_t);
      for (i = 0; i < out->slot_count; i++) {
        SV **slot_svp = av_fetch(slots_av, i, 0);
        if (!slot_svp || !gql_runtime_vm_parse_native_slot(aTHX_ *slot_svp, &out->slots[i])) return 0;
      }
    }
    if (out->op_count > 0) {
      Newxz(out->ops, out->op_count, gql_runtime_vm_native_op_t);
      for (i = 0; i < out->op_count; i++) {
        SV **op_svp = av_fetch(ops_av, i, 0);
        if (!op_svp || !gql_runtime_vm_parse_native_op(aTHX_ *op_svp, &out->ops[i])) return 0;
      }
    }
    return 1;
  }
  if (!gql_runtime_vm_sv_to_hv(aTHX_ sv, &hv)) {
    return 0;
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ hv, "family_code", 11, &out->family_code)) {
    return 0;
  }
  if (!gql_runtime_vm_fetch_hv_string(aTHX_ hv, "type_name", 9, &out->type_name)) {
    croak("native VM block entry is missing type_name");
  }
  svp = hv_fetch(hv, "slots", 5, 0);
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &slots_av)) {
    return 0;
  }
  svp = hv_fetch(hv, "ops", 3, 0);
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &ops_av)) {
    return 0;
  }
  out->slot_count = av_count(slots_av);
  out->op_count = av_count(ops_av);
  out->slots = NULL;
  out->ops = NULL;
  if (out->slot_count > 0) {
    Newxz(out->slots, out->slot_count, gql_runtime_vm_native_slot_t);
    for (i = 0; i < out->slot_count; i++) {
      SV **slot_svp = av_fetch(slots_av, i, 0);
      if (!slot_svp || !gql_runtime_vm_parse_native_slot(aTHX_ *slot_svp, &out->slots[i])) {
        return 0;
      }
    }
  }
  if (out->op_count > 0) {
    Newxz(out->ops, out->op_count, gql_runtime_vm_native_op_t);
    for (i = 0; i < out->op_count; i++) {
      SV **op_svp = av_fetch(ops_av, i, 0);
      if (!op_svp || !gql_runtime_vm_parse_native_op(aTHX_ *op_svp, &out->ops[i])) {
        return 0;
      }
    }
  }
  return 1;
}

static gql_runtime_vm_native_bundle_t *
gql_runtime_vm_native_bundle_from_runtime_and_program_sv(pTHX_ SV *runtime_sv, SV *program_sv)
{
  HV *runtime_hv;
  HV *program_hv;
  AV *runtime_slots_av;
  AV *blocks_av;
  gql_runtime_vm_native_args_payload_t **args_payloads = NULL;
  gql_runtime_vm_native_directives_payload_t **directives_payloads = NULL;
  IV args_payload_count = 0;
  IV directives_payload_count = 0;
  IV i;
  IV j;
  SV **svp;
  gql_runtime_vm_native_bundle_t *bundle;

  if (!gql_runtime_vm_sv_to_hv(aTHX_ runtime_sv, &runtime_hv)) {
    croak("native VM runtime descriptor must be a hash reference");
  }
  if (!gql_runtime_vm_sv_to_hv(aTHX_ program_sv, &program_hv)) {
    croak("native VM program descriptor must be a hash reference");
  }

  Newxz(bundle, 1, gql_runtime_vm_native_bundle_t);

  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ program_hv, "operation_type_code", 19, &bundle->operation_type_code)) {
    gql_runtime_vm_native_bundle_destroy(bundle);
    croak("native VM program descriptor is missing operation_type_code");
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ program_hv, "root_block_index", 16, &bundle->root_block_index)) {
    gql_runtime_vm_native_bundle_destroy(bundle);
    croak("native VM program descriptor is missing root_block_index");
  }

  gql_runtime_vm_parse_native_payload_catalogs(
    aTHX_
    program_hv,
    &args_payloads,
    &args_payload_count,
    &directives_payloads,
    &directives_payload_count
  );

  svp = hv_fetch(runtime_hv, "slot_catalog_exec", 17, 0);
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &runtime_slots_av)) {
    svp = hv_fetch(runtime_hv, "slot_catalog_compact", 20, 0);
  }
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &runtime_slots_av)) {
    svp = hv_fetch(runtime_hv, "slot_catalog", 12, 0);
  }
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &runtime_slots_av)) {
    gql_runtime_vm_native_bundle_destroy(bundle);
    croak("native VM runtime descriptor is missing slot_catalog");
  }
  bundle->runtime_slot_count = av_count(runtime_slots_av);
  if (bundle->runtime_slot_count > 0) {
    bundle->owns_runtime_slots = 1;
    Newxz(bundle->runtime_slots, bundle->runtime_slot_count, gql_runtime_vm_native_slot_t);
    for (i = 0; i < bundle->runtime_slot_count; i++) {
      SV **slot_svp = av_fetch(runtime_slots_av, i, 0);
      if (!slot_svp) {
        gql_runtime_vm_native_bundle_destroy(bundle);
        croak("native VM runtime slot entry %ld is missing", (long)i);
      }
      if (!gql_runtime_vm_parse_native_slot(aTHX_ *slot_svp, &bundle->runtime_slots[i])) {
        gql_runtime_vm_native_bundle_destroy(bundle);
        croak("native VM runtime slot entry %ld is invalid", (long)i);
      }
    }
  }

  svp = hv_fetch(program_hv, "blocks_compact", 14, 0);
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &blocks_av)) {
    svp = hv_fetch(program_hv, "blocks", 6, 0);
  }
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &blocks_av)) {
    gql_runtime_vm_free_native_payload_catalogs(
      aTHX_ args_payloads,
      args_payload_count,
      directives_payloads,
      directives_payload_count
    );
    gql_runtime_vm_native_bundle_destroy(bundle);
    croak("native VM program descriptor is missing blocks");
  }
  bundle->block_count = av_count(blocks_av);
  if (bundle->block_count > 0) {
    bundle->owns_blocks = 1;
    Newxz(bundle->blocks, bundle->block_count, gql_runtime_vm_native_block_t);
    for (i = 0; i < bundle->block_count; i++) {
      SV **block_svp = av_fetch(blocks_av, i, 0);
      if (!block_svp) {
        gql_runtime_vm_free_native_payload_catalogs(
          aTHX_ args_payloads,
          args_payload_count,
          directives_payloads,
          directives_payload_count
        );
        gql_runtime_vm_native_bundle_destroy(bundle);
        croak("native VM block entry %ld is missing", (long)i);
      }
      if (!gql_runtime_vm_parse_native_block(aTHX_ *block_svp, &bundle->blocks[i])) {
        gql_runtime_vm_free_native_payload_catalogs(
          aTHX_ args_payloads,
          args_payload_count,
          directives_payloads,
          directives_payload_count
        );
        gql_runtime_vm_native_bundle_destroy(bundle);
        croak("native VM block entry %ld is invalid", (long)i);
      }
      for (j = 0; j < bundle->blocks[i].op_count; j++) {
        gql_runtime_vm_native_op_t *op = &bundle->blocks[i].ops[j];
        if (!op->args_payload_native && op->args_payload_index >= 0) {
          if (op->args_payload_index >= args_payload_count ||
              !args_payloads ||
              !args_payloads[op->args_payload_index]) {
            gql_runtime_vm_free_native_payload_catalogs(
              aTHX_ args_payloads,
              args_payload_count,
              directives_payloads,
              directives_payload_count
            );
            gql_runtime_vm_native_bundle_destroy(bundle);
            croak("native VM args payload index %ld is invalid", (long)op->args_payload_index);
          }
          op->args_payload_native =
            gql_runtime_vm_native_args_payload_clone(aTHX_ args_payloads[op->args_payload_index]);
        }
        if (!op->directives_payload_native && op->directives_payload_index >= 0) {
          if (op->directives_payload_index >= directives_payload_count ||
              !directives_payloads ||
              !directives_payloads[op->directives_payload_index]) {
            gql_runtime_vm_free_native_payload_catalogs(
              aTHX_ args_payloads,
              args_payload_count,
              directives_payloads,
              directives_payload_count
            );
            gql_runtime_vm_native_bundle_destroy(bundle);
            croak("native VM directives payload index %ld is invalid", (long)op->directives_payload_index);
          }
          op->directives_payload_native =
            gql_runtime_vm_native_directives_payload_clone(aTHX_ directives_payloads[op->directives_payload_index]);
        }
      }
    }
  }

  gql_runtime_vm_free_native_payload_catalogs(
    aTHX_ args_payloads,
    args_payload_count,
    directives_payloads,
    directives_payload_count
  );

  return bundle;
}

static gql_runtime_vm_native_program_t *
gql_runtime_vm_native_program_from_sv(pTHX_ SV *sv)
{
  HV *program_hv;
  AV *blocks_av;
  IV i;
  IV j;
  SV **svp;
  gql_runtime_vm_native_program_t *program;

  if (sv && SvROK(sv) && sv_derived_from(sv, "GraphQL::Houtou::Runtime::NativeProgram")) {
    gql_runtime_vm_native_program_t *existing =
      INT2PTR(gql_runtime_vm_native_program_t *, SvUV(SvRV(sv)));
    if (!existing) {
      croak("native VM program handle is no longer valid");
    }
    return existing;
  }

  if (!gql_runtime_vm_sv_to_hv(aTHX_ sv, &program_hv)) {
    croak("native VM program descriptor must be a hash reference");
  }

  Newxz(program, 1, gql_runtime_vm_native_program_t);
  svp = hv_fetch(program_hv, "version", 7, 0);
  program->version = (svp && SvOK(*svp)) ? SvIV(*svp) : 1;
  svp = hv_fetch(program_hv, "operation_name", 14, 0);
  if (svp && SvOK(*svp)) {
    STRLEN len;
    const char *pv = SvPV(*svp, len);
    Newxz(program->operation_name, len + 1, char);
    Copy(pv, program->operation_name, len, char);
    program->operation_name[len] = '\0';
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ program_hv, "operation_type_code", 19, &program->operation_type_code)) {
    gql_runtime_vm_native_program_destroy(program);
    croak("native VM program descriptor is missing operation_type_code");
  }
  if (!gql_runtime_vm_fetch_hv_iv(aTHX_ program_hv, "root_block_index", 16, &program->root_block_index)) {
    gql_runtime_vm_native_program_destroy(program);
    croak("native VM program descriptor is missing root_block_index");
  }
  svp = hv_fetch(program_hv, "variable_defs", 13, 0);
  gql_runtime_vm_parse_native_arg_defs(aTHX_ (svp ? *svp : NULL), &program->variable_defs, &program->variable_def_count);

  gql_runtime_vm_parse_native_program_payload_catalogs(aTHX_ program_hv, program);

  svp = hv_fetch(program_hv, "blocks_compact", 14, 0);
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &blocks_av)) {
    svp = hv_fetch(program_hv, "blocks", 6, 0);
  }
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &blocks_av)) {
    gql_runtime_vm_native_program_destroy(program);
    croak("native VM program descriptor is missing blocks");
  }

  program->block_count = av_count(blocks_av);
  if (program->block_count > 0) {
    Newxz(program->blocks, program->block_count, gql_runtime_vm_native_block_t);
    for (i = 0; i < program->block_count; i++) {
      SV **block_svp = av_fetch(blocks_av, i, 0);
      if (!block_svp) {
        gql_runtime_vm_native_program_destroy(program);
        croak("native VM block entry %ld is missing", (long)i);
      }
      if (!gql_runtime_vm_parse_native_block(aTHX_ *block_svp, &program->blocks[i])) {
        gql_runtime_vm_native_program_destroy(program);
        croak("native VM block entry %ld is invalid", (long)i);
      }
      for (j = 0; j < program->blocks[i].op_count; j++) {
        gql_runtime_vm_native_op_t *op = &program->blocks[i].ops[j];
        if (!op->args_payload_native && op->args_payload_index >= 0) {
          if (op->args_payload_index >= program->args_payload_count ||
              !program->args_payloads ||
              !program->args_payloads[op->args_payload_index]) {
            gql_runtime_vm_native_program_destroy(program);
            croak("native VM args payload index %ld is invalid", (long)op->args_payload_index);
          }
          op->args_payload_native =
            gql_runtime_vm_native_args_payload_clone(aTHX_ program->args_payloads[op->args_payload_index]);
        }
        if (!op->directives_payload_native && op->directives_payload_index >= 0) {
          if (op->directives_payload_index >= program->directives_payload_count ||
              !program->directives_payloads ||
              !program->directives_payloads[op->directives_payload_index]) {
            gql_runtime_vm_native_program_destroy(program);
            croak("native VM directives payload index %ld is invalid", (long)op->directives_payload_index);
          }
          op->directives_payload_native =
            gql_runtime_vm_native_directives_payload_clone(aTHX_ program->directives_payloads[op->directives_payload_index]);
        }
      }
    }
  }

  return program;
}

static gql_runtime_vm_native_bundle_t *
gql_runtime_vm_native_bundle_from_runtime_and_program_handles(
  gql_runtime_vm_native_runtime_t *runtime,
  gql_runtime_vm_native_program_t *program
)
{
  gql_runtime_vm_native_bundle_t *bundle;
  IV i;
  if (!runtime || !program) {
    croak("native runtime and native program handles are required");
  }

  Newxz(bundle, 1, gql_runtime_vm_native_bundle_t);
  bundle->operation_type_code = program->operation_type_code;
  bundle->root_block_index = program->root_block_index;
  bundle->runtime_slot_count = runtime->runtime_slot_count;
  bundle->owns_runtime_slots = 1;
  bundle->runtime_slots = NULL;
  if (runtime->runtime_slot_count > 0) {
    Newxz(bundle->runtime_slots, runtime->runtime_slot_count, gql_runtime_vm_native_slot_t);
    for (i = 0; i < runtime->runtime_slot_count; i++) {
      gql_runtime_vm_clone_native_slot(aTHX_ &runtime->runtime_slots[i], &bundle->runtime_slots[i]);
    }
  }
  bundle->block_count = program->block_count;
  if (program->block_count > 0) {
    bundle->owns_blocks = 1;
    Newxz(bundle->blocks, program->block_count, gql_runtime_vm_native_block_t);
    for (i = 0; i < program->block_count; i++) {
      gql_runtime_vm_clone_native_block(aTHX_ &program->blocks[i], &bundle->blocks[i]);
    }
  }
  return bundle;
}

static void
gql_runtime_vm_prepare_cached_bundle_in_place(
  pTHX_
  gql_runtime_vm_native_runtime_t *runtime,
  gql_runtime_vm_native_bundle_t *bundle
)
{
  IV i;

  if (!runtime || !bundle || !bundle->blocks) {
    return;
  }

  for (i = 0; i < bundle->block_count; i++) {
    gql_runtime_vm_native_block_t *block = &bundle->blocks[i];
    IV read_index;
    IV write_index = 0;

    for (read_index = 0; read_index < block->op_count; read_index++) {
      gql_runtime_vm_native_op_t *op = &block->ops[read_index];
      const gql_runtime_vm_native_slot_t *slot = NULL;
      int keep = 1;

      if (op->slot_index >= 0 && op->slot_index < block->slot_count) {
        slot = &block->slots[op->slot_index];
      }

      if (op->has_directives && op->directives_mode_code == GQL_VM_ARGS_STATIC) {
        if (!gql_runtime_vm_evaluate_runtime_guards_native(
              aTHX_
              op->directives_payload_native,
              NULL
            )) {
          keep = 0;
        } else {
          op->has_directives = 0;
          op->directives_mode_code = GQL_VM_ARGS_NONE;
          gql_runtime_vm_native_directives_payload_destroy(aTHX_ op->directives_payload_native);
          op->directives_payload_native = NULL;
        }
      }

      if (keep
          && slot
          && op->args_mode_code == GQL_VM_ARGS_STATIC
          && (slot->arg_def_count > 0 || op->has_args)) {
        gql_runtime_vm_native_args_payload_t *specialized_payload =
          gql_runtime_vm_specialize_arg_payload_native(aTHX_ runtime, slot, op, NULL);
        gql_runtime_vm_native_args_payload_destroy(aTHX_ op->args_payload_native);
        op->args_payload_native = NULL;
        if (specialized_payload) {
          op->args_payload_native = specialized_payload;
          op->args_mode_code = GQL_VM_ARGS_STATIC;
          op->has_args = 1;
        } else {
          op->args_mode_code = GQL_VM_ARGS_NONE;
          op->has_args = 0;
        }
      }

      if (!keep) {
        gql_runtime_vm_native_args_payload_destroy(aTHX_ op->args_payload_native);
        op->args_payload_native = NULL;
        gql_runtime_vm_native_directives_payload_destroy(aTHX_ op->directives_payload_native);
        op->directives_payload_native = NULL;
        SvREFCNT_dec(op->runtime_directives_sv);
        op->runtime_directives_sv = NULL;
        continue;
      }

      if (write_index != read_index) {
        block->ops[write_index] = *op;
        Zero(op, 1, gql_runtime_vm_native_op_t);
      }
      write_index++;
    }

    block->op_count = write_index;
  }
}

static gql_runtime_vm_native_bundle_t *
gql_runtime_vm_native_program_cached_bundle(
  pTHX_
  gql_runtime_vm_native_runtime_t *runtime,
  gql_runtime_vm_native_program_t *program
)
{
  if (!runtime || !program) {
    croak("native runtime and native program handles are required");
  }

  if (program->cached_bundle && program->cached_bundle_runtime == runtime) {
    return program->cached_bundle;
  }

  if (program->cached_bundle) {
    gql_runtime_vm_native_bundle_destroy(program->cached_bundle);
    program->cached_bundle = NULL;
    program->cached_bundle_runtime = NULL;
  }

  program->cached_bundle =
    gql_runtime_vm_native_bundle_from_runtime_and_program_handles(runtime, program);
  gql_runtime_vm_prepare_cached_bundle_in_place(aTHX_ runtime, program->cached_bundle);
  program->cached_bundle_runtime = runtime;
  return program->cached_bundle;
}

static gql_runtime_vm_native_bundle_t *
gql_runtime_vm_native_bundle_from_sv(pTHX_ SV *sv)
{
  HV *bundle_hv;
  SV **runtime_svp;
  SV **program_svp;

  if (!gql_runtime_vm_sv_to_hv(aTHX_ sv, &bundle_hv)) {
    croak("native VM bundle descriptor must be a hash reference");
  }

  runtime_svp = hv_fetch(bundle_hv, "runtime", 7, 0);
  if (!runtime_svp) {
    croak("native VM bundle descriptor is missing runtime");
  }
  program_svp = hv_fetch(bundle_hv, "program", 7, 0);
  if (!program_svp) {
    croak("native VM bundle descriptor is missing program");
  }

  return gql_runtime_vm_native_bundle_from_runtime_and_program_sv(
    aTHX_ *runtime_svp, *program_svp
  );
}

static int
gql_runtime_vm_program_is_native_eligible_sv(pTHX_ SV *program_sv, int has_promise)
{
  HV *program_hv;
  AV *blocks_av;
  IV i, j, k;
  SV **svp;

  if (has_promise) {
    return 0;
  }
  if (program_sv && SvROK(program_sv) && sv_derived_from(program_sv, "GraphQL::Houtou::Runtime::NativeProgram")) {
    gql_runtime_vm_native_program_t *program =
      INT2PTR(gql_runtime_vm_native_program_t *, SvUV(SvRV(program_sv)));
    return program ? 1 : 0;
  }
  if (!gql_runtime_vm_sv_to_hv(aTHX_ program_sv, &program_hv)) {
    return 0;
  }

  svp = hv_fetch(program_hv, "variable_defs", 13, 0);
  if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
    HV *defs_hv = (HV *)SvRV(*svp);
    if (HvUSEDKEYS(defs_hv) > 0) {
      return 0;
    }
  }

  svp = hv_fetch(program_hv, "blocks_compact", 14, 0);
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &blocks_av)) {
    svp = hv_fetch(program_hv, "blocks", 6, 0);
  }
  if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &blocks_av)) {
    return 0;
  }

  for (i = 0; i <= av_len(blocks_av); i++) {
    SV **block_svp = av_fetch(blocks_av, i, 0);
    AV *block_av;
    AV *slots_av;
    AV *ops_av;
    if (!block_svp || !gql_runtime_vm_sv_to_av(aTHX_ *block_svp, &block_av)) {
      return 0;
    }

    svp = av_fetch(block_av, 3, 0);
    if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &slots_av)) {
      return 0;
    }
    for (j = 0; j <= av_len(slots_av); j++) {
      SV **slot_svp = av_fetch(slots_av, j, 0);
      AV *slot_av;
      IV resolver_shape_code;
      IV resolver_mode_code;
      IV callback_abi_code;
      if (!slot_svp || !gql_runtime_vm_sv_to_av(aTHX_ *slot_svp, &slot_av)) {
        return 0;
      }
      svp = av_fetch(slot_av, 4, 0);
      resolver_shape_code = (svp && SvOK(*svp)) ? SvIV(*svp) : 0;
      svp = av_fetch(slot_av, 10, 0);
      resolver_mode_code = (svp && SvOK(*svp)) ? SvIV(*svp) : 0;
      svp = av_fetch(slot_av, 12, 0);
      callback_abi_code = (svp && SvOK(*svp))
        ? SvIV(*svp)
        : gql_runtime_vm_infer_callback_abi_code(resolver_shape_code, resolver_mode_code);
      if (resolver_shape_code != GQL_VM_RESOLVE_DEFAULT) {
        if (resolver_shape_code != GQL_VM_RESOLVE_EXPLICIT
            || (callback_abi_code != GQL_VM_CALLBACK_ABI_EXPLICIT_GENERIC
                && callback_abi_code != GQL_VM_CALLBACK_ABI_EXPLICIT_NATIVE)) {
          return 0;
        }
      }
    }

    svp = av_fetch(block_av, 4, 0);
    if (!svp || !gql_runtime_vm_sv_to_av(aTHX_ *svp, &ops_av)) {
      return 0;
    }
    for (k = 0; k <= av_len(ops_av); k++) {
      SV **op_svp = av_fetch(ops_av, k, 0);
      AV *op_av;
      IV args_mode_code;
      int has_directives;
      if (!op_svp || !gql_runtime_vm_sv_to_av(aTHX_ *op_svp, &op_av)) {
        return 0;
      }
      svp = av_fetch(op_av, 7, 0);
      args_mode_code = (svp && SvOK(*svp)) ? SvIV(*svp) : GQL_VM_ARGS_NONE;
      svp = av_fetch(op_av, 12, 0);
      has_directives = (svp && SvOK(*svp) && SvTRUE(*svp)) ? 1 : 0;
      if (args_mode_code != GQL_VM_ARGS_NONE && args_mode_code != GQL_VM_ARGS_STATIC) {
        return 0;
      }
      if (has_directives) {
        return 0;
      }
    }
  }

  return 1;
}

static gql_runtime_vm_native_program_t *
gql_runtime_vm_clone_native_program(pTHX_ gql_runtime_vm_native_program_t *src)
{
  gql_runtime_vm_native_program_t *dst;
  IV i;
  if (!src) {
    return NULL;
  }
  Newxz(dst, 1, gql_runtime_vm_native_program_t);
  dst->version = src->version;
  dst->operation_type_code = src->operation_type_code;
  dst->root_block_index = src->root_block_index;
  dst->variable_def_count = src->variable_def_count;
  dst->block_count = src->block_count;
  dst->args_payload_count = src->args_payload_count;
  dst->directives_payload_count = src->directives_payload_count;
  if (src->operation_name) {
    STRLEN len = strlen(src->operation_name);
    Newxz(dst->operation_name, len + 1, char);
    Copy(src->operation_name, dst->operation_name, len, char);
    dst->operation_name[len] = '\0';
  }
  if (src->variable_def_count > 0 && src->variable_defs) {
    Newxz(dst->variable_defs, src->variable_def_count, gql_runtime_vm_native_arg_def_t);
    for (i = 0; i < src->variable_def_count; i++) {
      gql_runtime_vm_native_arg_def_t *src_def = &src->variable_defs[i];
      gql_runtime_vm_native_arg_def_t *dst_def = &dst->variable_defs[i];
      dst_def->has_default = src_def->has_default;
      dst_def->input_type_nonnull_state = src_def->input_type_nonnull_state;
      if (src_def->name) {
        STRLEN len = strlen(src_def->name);
        Newxz(dst_def->name, len + 1, char);
        Copy(src_def->name, dst_def->name, len, char);
        dst_def->name[len] = '\0';
      }
      if (src_def->type_def_sv) {
        dst_def->type_def_sv = newSVsv(src_def->type_def_sv);
      }
      if (src_def->input_type_sv) {
        dst_def->input_type_sv = newSVsv(src_def->input_type_sv);
      }
      if (src_def->default_value_sv) {
        dst_def->default_value_sv = newSVsv(src_def->default_value_sv);
      }
      if (src_def->default_native_value) {
        dst_def->default_native_value = gql_runtime_vm_native_value_clone(aTHX_ src_def->default_native_value);
      }
    }
  }
  if (src->args_payload_count > 0 && src->args_payloads) {
    Newxz(dst->args_payloads, src->args_payload_count, gql_runtime_vm_native_args_payload_t *);
    for (i = 0; i < src->args_payload_count; i++) {
      if (src->args_payloads[i]) {
        dst->args_payloads[i] = gql_runtime_vm_native_args_payload_clone(aTHX_ src->args_payloads[i]);
      }
    }
  }
  if (src->directives_payload_count > 0 && src->directives_payloads) {
    Newxz(dst->directives_payloads, src->directives_payload_count, gql_runtime_vm_native_directives_payload_t *);
    for (i = 0; i < src->directives_payload_count; i++) {
      if (src->directives_payloads[i]) {
        dst->directives_payloads[i] = gql_runtime_vm_native_directives_payload_clone(aTHX_ src->directives_payloads[i]);
      }
    }
  }
  if (src->block_count > 0) {
    Newxz(dst->blocks, src->block_count, gql_runtime_vm_native_block_t);
    for (i = 0; i < src->block_count; i++) {
      gql_runtime_vm_clone_native_block(aTHX_ &src->blocks[i], &dst->blocks[i]);
    }
  }
  return dst;
}

static SV *
gql_runtime_vm_lookup_input_type_by_typedef_sv(pTHX_ SV *runtime_schema, SV *typedef_sv)
{
  dSP;
  SV *runtime_cache_sv;
  SV *name2type_sv;
  HV *schema_hv;
  HV *runtime_cache_hv;
  SV *result = NULL;
  int count;

  if (!runtime_schema || !SvROK(runtime_schema) || SvTYPE(SvRV(runtime_schema)) != SVt_PVHV || !typedef_sv || !SvOK(typedef_sv)) {
    return NULL;
  }
  schema_hv = (HV *)SvRV(runtime_schema);
  runtime_cache_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ schema_hv, "runtime_cache", 13);
  if (!runtime_cache_sv || !SvROK(runtime_cache_sv) || SvTYPE(SvRV(runtime_cache_sv)) != SVt_PVHV) {
    return NULL;
  }
  runtime_cache_hv = (HV *)SvRV(runtime_cache_sv);
  name2type_sv = gql_runtime_vm_fetch_hash_entry_sv(aTHX_ runtime_cache_hv, "name2type", 9);
  if (!name2type_sv || !SvROK(name2type_sv) || SvTYPE(SvRV(name2type_sv)) != SVt_PVHV) {
    return NULL;
  }

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  XPUSHs(typedef_sv);
  XPUSHs(name2type_sv);
  PUTBACK;
  count = call_pv("GraphQL::Houtou::Schema::lookup_type", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (SvTRUE(ERRSV)) {
    SV *err = newSVsv(ERRSV);
    PUTBACK;
    FREETMPS;
    LEAVE;
    croak_sv(err);
  }
  if (count > 0) {
    result = newSVsv(POPs);
  }
  PUTBACK;
  FREETMPS;
  LEAVE;
  return result;
}

/* Leaf coercion kind for a slot, or GQL_VM_LEAF_NONE when the runtime
 * carries no leaf metadata (descriptor-inflated) or the slot's return
 * type is not a leaf. */
static IV
gql_runtime_vm_slot_leaf_kind(
  const gql_runtime_vm_native_runtime_t *runtime,
  const gql_runtime_vm_native_slot_t *slot
)
{
  IV slot_index;
  if (!runtime || !slot || !runtime->callback_catalog
      || !runtime->callback_catalog->slot_leaf_kinds) {
    return GQL_VM_LEAF_NONE;
  }
  slot_index = slot->schema_slot_index;
  if (slot_index < 0 || slot_index >= runtime->runtime_slot_count) {
    return GQL_VM_LEAF_NONE;
  }
  return runtime->callback_catalog->slot_leaf_kinds[slot_index];
}

/*
 * Leaf result coercion (spec 6.4.3 value completion for leaf types).
 * Checks/serializes a resolver's output value against the field's leaf
 * type. Returns an OWNED SV with the coerced value on success (which may
 * be the input with an extra refcount when it already conforms). On a
 * coercion failure returns NULL and sets *error_out to an owned message
 * SV; the caller nulls the field and records a field error. Slots whose
 * return type carries no leaf metadata (objects, unions, descriptor-only
 * runtimes) pass the value through untouched.
 *
 * Perl note: scalars are untyped, so the builtin checks are value-based
 * (grok_number), not SV-flag-based - a resolver returning "5" for an Int
 * serializes as 5, matching graphql-js's coercing serializers.
 */
static SV *
gql_runtime_vm_serialize_leaf_sv(
  pTHX_
  const gql_runtime_vm_native_runtime_t *runtime,
  const gql_runtime_vm_native_slot_t *slot,
  SV *value,
  SV **error_out
)
{
  const gql_runtime_vm_native_callback_catalog_t *catalog =
    runtime ? runtime->callback_catalog : NULL;
  IV slot_index;
  IV leaf_kind;
  SV *payload;

  if (error_out) {
    *error_out = NULL;
  }
  if (!value || !SvOK(value)) {
    return newSVsv(&PL_sv_undef);
  }
  if (!catalog || !catalog->slot_leaf_kinds || !slot) {
    SvREFCNT_inc_simple_NN(value);
    return value;
  }
  slot_index = slot->schema_slot_index;
  if (slot_index < 0 || slot_index >= runtime->runtime_slot_count) {
    SvREFCNT_inc_simple_NN(value);
    return value;
  }
  leaf_kind = catalog->slot_leaf_kinds[slot_index];
  if (leaf_kind == GQL_VM_LEAF_NONE) {
    SvREFCNT_inc_simple_NN(value);
    return value;
  }
  payload = catalog->slot_leaf_payloads ? catalog->slot_leaf_payloads[slot_index] : NULL;

  switch (leaf_kind) {
    case GQL_VM_LEAF_INT:
    {
      /* Fast path: an IV in int32 range passes as-is. */
      if (SvIOK(value) && !SvPOK(value) && !SvNOK(value)) {
        IV iv = SvIV(value);
        if (iv >= -2147483648LL && iv <= 2147483647LL) {
          SvREFCNT_inc_simple_NN(value);
          return value;
        }
      }
      if (!SvROK(value) && looks_like_number(value)) {
        NV nv = SvNV(value);
        if (nv == (NV)(IV)nv && nv >= -2147483648.0 && nv <= 2147483647.0) {
          return newSViv((IV)nv);
        }
      }
      if (error_out) {
        *error_out = newSVpvf("Int cannot represent non-integer value: %s",
          SvROK(value) ? "(reference)" : SvPV_nolen(value));
      }
      return NULL;
    }
    case GQL_VM_LEAF_FLOAT:
    {
      if (SvNIOK(value) && !SvPOK(value)) {
        SvREFCNT_inc_simple_NN(value);
        return value;
      }
      if (!SvROK(value) && looks_like_number(value)) {
        return newSVnv(SvNV(value));
      }
      if (error_out) {
        *error_out = newSVpvf("Float cannot represent non-numeric value: %s",
          SvROK(value) ? "(reference)" : SvPV_nolen(value));
      }
      return NULL;
    }
    case GQL_VM_LEAF_STRING:
    case GQL_VM_LEAF_ID:
    {
      const char *type_label = leaf_kind == GQL_VM_LEAF_ID ? "ID" : "String";
      if (SvPOK(value) && !SvROK(value)) {
        SvREFCNT_inc_simple_NN(value);
        return value;
      }
      if (!SvROK(value)) {
        /* Numbers (and dualvars) stringify; the copy pins the PV
         * representation so the JSON lanes emit a string. */
        STRLEN len;
        const char *pv = SvPV(value, len);
        return newSVpvn_utf8(pv, len, SvUTF8(value) ? 1 : 0);
      }
      if (sv_isobject(value) && sv_derived_from(value, "JSON::PP::Boolean")) {
        return newSVpv(SvTRUE(value) ? "true" : "false", 0);
      }
      if (error_out) {
        *error_out = newSVpvf("%s cannot represent a reference value", type_label);
      }
      return NULL;
    }
    case GQL_VM_LEAF_BOOLEAN:
    {
      /* Perl has no boolean type: any non-reference scalar coerces by
       * truthiness (JSON bool objects included). */
      if (!SvROK(value) || (sv_isobject(value) && sv_derived_from(value, "JSON::PP::Boolean"))) {
        return newSViv(SvTRUE(value) ? 1 : 0);
      }
      if (error_out) {
        *error_out = newSVpvs("Boolean cannot represent a reference value");
      }
      return NULL;
    }
    case GQL_VM_LEAF_ENUM:
    {
      /* payload maps internal values to enum names (identity for the
       * default declaration shape). */
      if (!SvROK(value) && payload && SvROK(payload) && SvTYPE(SvRV(payload)) == SVt_PVHV) {
        STRLEN klen;
        const char *kpv = SvPV(value, klen);
        SV **name_svp = hv_fetch((HV *)SvRV(payload), kpv, (I32)klen, 0);
        if (name_svp && SvOK(*name_svp)) {
          return newSVsv(*name_svp);
        }
      }
      if (error_out) {
        *error_out = newSVpvf("Enum '%s' cannot represent value: %s",
          slot->return_type_name ? slot->return_type_name : "(unknown)",
          SvROK(value) ? "(reference)" : SvPV_nolen(value));
      }
      return NULL;
    }
    case GQL_VM_LEAF_CUSTOM:
    {
      dSP;
      int count;
      SV *result = NULL;
      if (!payload) {
        SvREFCNT_inc_simple_NN(value);
        return value;
      }
      ENTER;
      SAVETMPS;
      sv_setsv(ERRSV, &PL_sv_undef);
      PUSHMARK(SP);
      XPUSHs(value);
      PUTBACK;
      count = call_sv(payload, G_SCALAR | G_EVAL);
      SPAGAIN;
      if (SvTRUE(ERRSV)) {
        if (error_out) {
          *error_out = newSVsv(ERRSV);
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
        return NULL;
      }
      result = count > 0 ? newSVsv(POPs) : newSVsv(&PL_sv_undef);
      PUTBACK;
      FREETMPS;
      LEAVE;
      return result;
    }
    default:
      SvREFCNT_inc_simple_NN(value);
      return value;
  }
}

static SV *
gql_runtime_vm_coerce_input_value_sv(pTHX_ SV *type_sv, SV *value_sv, SV **croak_out)
{
  dSP;
  SV *result = NULL;
  int count;

  if (!value_sv) {
    return newSV(0);
  }
  if (!type_sv || !SvOK(type_sv)) {
    return newSVsv(value_sv);
  }

  /* Built-in scalar fast path: Type::Scalar carries _builtin_kind for the
   * five specced scalars, and graphql_to_perl short-circuits parse_value
   * for them anyway. Handle the unambiguous plain-SV shapes here and skip
   * the per-coercion call_method; anything we cannot decide exactly
   * (magic, refs, string-y numbers, JSON booleans) falls through to the
   * Perl path, which validates and dies with the same messages. */
  if (SvROK(type_sv) && SvTYPE(SvRV(type_sv)) == SVt_PVHV && !SvMAGICAL(SvRV(type_sv))) {
    SV **kindp = hv_fetchs((HV *)SvRV(type_sv), "_builtin_kind", 0);
    if (kindp && *kindp && SvPOK(*kindp) && !SvROK(value_sv) && !SvMAGICAL(value_sv)) {
      const char *kind = SvPVX(*kindp);
      STRLEN klen = SvCUR(*kindp);
      if (!SvOK(value_sv)) {
        return newSV(0);
      }
      if ((klen == 6 && memcmp(kind, "String", 6) == 0)
          || (klen == 2 && memcmp(kind, "ID", 2) == 0)) {
        /* Any defined non-ref value is accepted and passed through. */
        return newSVsv(value_sv);
      }
      if (klen == 3 && memcmp(kind, "Int", 3) == 0 && SvIOK(value_sv) && !SvPOK(value_sv) && !SvNOK(value_sv)) {
        IV v = SvIV(value_sv);
        if (v >= -2147483648LL && v <= 2147483647LL) {
          return newSViv(v);
        }
        /* Out-of-range: fall through so the Perl path raises "Not an Int." */
      } else if (klen == 5 && memcmp(kind, "Float", 5) == 0 && !SvPOK(value_sv)) {
        if (SvIOK(value_sv)) {
          return newSViv(SvIV(value_sv));
        }
        if (SvNOK(value_sv)) {
          return newSVnv(SvNV(value_sv));
        }
      } else if (klen == 7 && memcmp(kind, "Boolean", 7) == 0 && SvIOK(value_sv) && !SvPOK(value_sv) && !SvNOK(value_sv)) {
        IV v = SvIV(value_sv);
        if (v == 0 || v == 1) {
          return newSViv(v);
        }
        /* Other numbers: fall through so the Perl path raises the error. */
      }
    }
  }

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  XPUSHs(type_sv);
  XPUSHs(value_sv);
  PUTBACK;
  count = call_method("graphql_to_perl", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (SvTRUE(ERRSV)) {
    SV *err = newSVsv(ERRSV);
    PUTBACK;
    FREETMPS;
    LEAVE;
    /* Input coercion failures are GraphQL request errors (bad variables
     * or literals from the client), so they surface as
     * GraphQL::Houtou::Error: the execute_document boundary turns blessed
     * Houtou errors into an errors-only response envelope and lets any
     * other die (a config or internal error) propagate. graphql_to_perl
     * raises plain strings; wrap them, keep already-blessed errors. */
    if (!sv_isobject(err)) {
      HV *error_hv = newHV();
      SV *message_sv = newSVsv(err);
      STRLEN message_len;
      char *message_pv = SvPV(message_sv, message_len);
      /* Trailing newline is die()'s "no location suffix" convention, not
       * part of the GraphQL error message. */
      while (message_len > 0 && message_pv[message_len - 1] == '\n') {
        SvCUR_set(message_sv, --message_len);
      }
      (void)hv_stores(error_hv, "message", message_sv);
      SvREFCNT_dec(err);
      err = newRV_noinc((SV *)error_hv);
      sv_bless(err, gv_stashpvs("GraphQL::Houtou::Error", GV_ADD));
    }
    /* With croak_out the caller defers the croak (the sync fast lanes
     * must unwind their path frame chain first); otherwise croak here.
     * Mortalize onto the caller's tmps so the copy is reclaimed during
     * die unwinding instead of leaking once per coercion failure. */
    if (croak_out) {
      *croak_out = err;
      return newSV(0);
    }
    croak_sv(sv_2mortal(err));
  }
  if (count > 0) {
    result = newSVsv(POPs);
  } else {
    result = newSV(0);
  }
  PUTBACK;
  FREETMPS;
  LEAVE;
  return result;
}

static void
gql_runtime_vm_finalize_native_arg_def(
  pTHX_
  SV *runtime_schema,
  gql_runtime_vm_native_arg_def_t *arg_def
)
{
  if (!arg_def) {
    return;
  }

  if (arg_def->type_def_sv && !arg_def->input_type_sv) {
    arg_def->input_type_sv = gql_runtime_vm_lookup_input_type_by_typedef_sv(
      aTHX_ runtime_schema, arg_def->type_def_sv
    );
  }
  if (arg_def->has_default
      && arg_def->default_value_sv
      && arg_def->input_type_sv
      && !arg_def->default_native_value) {
    /* Mortal so a croak from coercion cannot leak the copies. */
    SV *default_raw_sv = sv_2mortal(newSVsv(arg_def->default_value_sv));
    SV *default_coerced_sv = sv_2mortal(gql_runtime_vm_coerce_input_value_sv(
      aTHX_ arg_def->input_type_sv, default_raw_sv, NULL
    ));
    arg_def->default_native_value = gql_runtime_vm_native_value_from_sv(aTHX_ default_coerced_sv);
  }
}

/* Bounded, human-readable rendering of a provided variable value for
 * request-error messages. Strings are quoted and escaped, JSON booleans
 * render as true/false, other references keep the house "(reference)"
 * placeholder, and long strings are truncated on a UTF-8 boundary so a
 * hostile variable cannot bloat the error envelope. */
#define GQL_RUNTIME_VM_VARIABLE_DESC_MAX_BYTES 64
static SV *
gql_runtime_vm_variable_value_desc_sv(pTHX_ SV *value_sv)
{
  SV *desc_sv;
  const char *pv;
  STRLEN len;
  STRLEN i;
  int truncated = 0;

  if (!value_sv || !SvOK(value_sv)) {
    return newSVpvs("null");
  }
  if (SvROK(value_sv)) {
    if (sv_isobject(value_sv) && sv_derived_from(value_sv, "JSON::PP::Boolean")) {
      return SvTRUE(SvRV(value_sv)) ? newSVpvs("true") : newSVpvs("false");
    }
    return newSVpvs("(reference)");
  }
  if (!SvPOK(value_sv)) {
    /* Plain IV/NV: Perl's stringification is already the message shape. */
    return newSVsv(value_sv);
  }

  pv = SvPV(value_sv, len);
  if (len > GQL_RUNTIME_VM_VARIABLE_DESC_MAX_BYTES) {
    len = GQL_RUNTIME_VM_VARIABLE_DESC_MAX_BYTES;
    if (SvUTF8(value_sv)) {
      /* Do not cut a multi-byte sequence: back off continuation bytes. */
      while (len > 0 && (((const U8 *)pv)[len] & 0xC0) == 0x80) {
        len--;
      }
    }
    truncated = 1;
  }
  desc_sv = newSVpvs("\"");
  for (i = 0; i < len; i++) {
    const char c = pv[i];
    if (c == '"' || c == '\\') {
      sv_catpvs(desc_sv, "\\");
      sv_catpvn(desc_sv, &c, 1);
    } else if ((U8)c < 0x20) {
      sv_catpvs(desc_sv, " ");
    } else {
      sv_catpvn(desc_sv, &c, 1);
    }
  }
  if (truncated) {
    sv_catpvs(desc_sv, "...");
  }
  sv_catpvs(desc_sv, "\"");
  if (SvUTF8(value_sv)) {
    SvUTF8_on(desc_sv);
  }
  return desc_sv;
}

/* Prepend "Variable \"$name\" got invalid value <desc>; " to a Houtou
 * request-error message so clients can tell which variable failed input
 * coercion. Custom blessed errors that are not plain Houtou error hashes
 * are left untouched to preserve their contract. */
static void
gql_runtime_vm_variable_error_prepend_context(
  pTHX_ SV *err_sv, const char *name, SV *raw_sv
)
{
  HV *err_hv;
  SV **msgp;
  SV *desc_sv;
  SV *message_sv;

  if (!err_sv || !name || !SvROK(err_sv) || SvTYPE(SvRV(err_sv)) != SVt_PVHV
      || !sv_derived_from(err_sv, "GraphQL::Houtou::Error")) {
    return;
  }
  err_hv = (HV *)SvRV(err_sv);
  msgp = hv_fetchs(err_hv, "message", 0);
  if (!msgp || !*msgp || !SvOK(*msgp)) {
    return;
  }
  desc_sv = gql_runtime_vm_variable_value_desc_sv(aTHX_ raw_sv);
  message_sv = newSVpvf(
    "Variable \"$%s\" got invalid value %" SVf "; %" SVf,
    name, SVfARG(desc_sv), SVfARG(*msgp)
  );
  SvREFCNT_dec(desc_sv);
  (void)hv_stores(err_hv, "message", message_sv);
}

/* Request error for a Non-Null variable with no value and no default,
 * raised while coercing variables (spec CoerceVariableValues) instead of
 * later inside argument specialization, so the message can carry the
 * variable name and declared type. */
static SV *
gql_runtime_vm_missing_variable_error_sv(pTHX_ SV *type_sv, const char *name)
{
  dSP;
  SV *type_str_sv = NULL;
  SV *message_sv;
  HV *error_hv;
  SV *err;
  int count;

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  XPUSHs(type_sv);
  PUTBACK;
  count = call_method("to_string", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (SvTRUE(ERRSV)) {
    sv_setsv(ERRSV, &PL_sv_undef);
  } else if (count > 0) {
    type_str_sv = newSVsv(POPs);
  }
  PUTBACK;
  FREETMPS;
  LEAVE;

  if (type_str_sv && SvOK(type_str_sv)) {
    message_sv = newSVpvf(
      "Variable \"$%s\" of required type \"%" SVf "\" was not provided.",
      name, SVfARG(type_str_sv)
    );
  } else {
    message_sv = newSVpvf("Variable \"$%s\" of required type was not provided.", name);
  }
  SvREFCNT_dec(type_str_sv);

  error_hv = newHV();
  (void)hv_stores(error_hv, "message", message_sv);
  err = newRV_noinc((SV *)error_hv);
  sv_bless(err, gv_stashpvs("GraphQL::Houtou::Error", GV_ADD));
  return err;
}

static SV *
gql_runtime_vm_prepare_program_variables_sv(
  pTHX_
  SV *runtime_schema,
  gql_runtime_vm_native_program_t *program,
  HV *provided_hv
)
{
  HV *coerced_hv;
  SV *coerced_rv;
  IV i;

  coerced_hv = newHV();
  /* Owned by a mortal wrapper so a croak from coercion below reclaims the
   * hash (and everything stored so far) during die unwinding. */
  coerced_rv = sv_2mortal(newRV_noinc((SV *)coerced_hv));

  for (i = 0; program && i < program->variable_def_count; i++) {
    gql_runtime_vm_native_arg_def_t *arg_def = &program->variable_defs[i];
    STRLEN name_len = 0;
    SV *raw_sv = NULL;
    SV *coerced_sv = NULL;
    U8 has_value = 0;

    if (!arg_def->name) {
      continue;
    }

    name_len = strlen(arg_def->name);
    gql_runtime_vm_finalize_native_arg_def(aTHX_ runtime_schema, arg_def);

    if (provided_hv && hv_exists(provided_hv, arg_def->name, (I32)name_len)) {
      SV **provided_svp = hv_fetch(provided_hv, arg_def->name, (I32)name_len, 0);
      raw_sv = sv_2mortal(provided_svp ? newSVsv(*provided_svp) : newSV(0));
      has_value = 1;
    } else if (arg_def->has_default && arg_def->default_native_value) {
      coerced_sv = gql_runtime_vm_native_value_materialize_sv(aTHX_ arg_def->default_native_value);
    } else if (arg_def->has_default && arg_def->default_value_sv) {
      raw_sv = sv_2mortal(newSVsv(arg_def->default_value_sv));
    }

    if (!has_value && !raw_sv && !coerced_sv) {
      if (arg_def->input_type_nonnull_state == 0
          && arg_def->input_type_sv && SvOK(arg_def->input_type_sv)) {
        arg_def->input_type_nonnull_state = sv_derived_from(
          arg_def->input_type_sv, "GraphQL::Houtou::Type::NonNull"
        ) ? 1 : 2;
      }
      if (arg_def->input_type_nonnull_state == 1) {
        croak_sv(sv_2mortal(gql_runtime_vm_missing_variable_error_sv(
          aTHX_ arg_def->input_type_sv, arg_def->name
        )));
      }
      continue;
    }

    if (!coerced_sv) {
      SV *coerce_err = NULL;
      coerced_sv = gql_runtime_vm_coerce_input_value_sv(
        aTHX_ arg_def->input_type_sv, raw_sv, &coerce_err
      );
      if (coerce_err) {
        /* The placeholder undef from the deferred-croak contract. */
        SvREFCNT_dec(coerced_sv);
        /* Only client-provided values get the "got invalid value" context;
         * a failing default keeps the raw coercion message (defaults are
         * already validated against their declared types at build time). */
        if (has_value) {
          gql_runtime_vm_variable_error_prepend_context(
            aTHX_ coerce_err, arg_def->name, raw_sv
          );
        }
        croak_sv(sv_2mortal(coerce_err));
      }
    }
    hv_store(coerced_hv, arg_def->name, (I32)name_len, coerced_sv, 0);
  }

  if (provided_hv) {
    HE *he;
    hv_iterinit(provided_hv);
    while ((he = hv_iternext(provided_hv))) {
      SV *key_sv = hv_iterkeysv(he);
      SV *value_sv = hv_iterval(provided_hv, he);
      STRLEN key_len = 0;
      const char *key_pv;

      if (!key_sv || !SvOK(key_sv)) {
        continue;
      }
      key_pv = SvPV(key_sv, key_len);
      if (hv_exists(coerced_hv, key_pv, (I32)key_len)) {
        continue;
      }
      hv_store(coerced_hv, key_pv, (I32)key_len, newSVsv(value_sv), 0);
    }
  }

  return SvREFCNT_inc_simple_NN(coerced_rv);
}

static SV *
gql_runtime_vm_specialize_arg_payload_sv(
  pTHX_
  const gql_runtime_vm_native_runtime_t *runtime,
  const gql_runtime_vm_native_slot_t *slot,
  const gql_runtime_vm_native_op_t *op,
  HV *variables_hv,
  SV **croak_out
)
{
  HV *coerced_hv;
  SV *coerced_rv;
  const gql_runtime_vm_native_args_payload_t *payload = op->args_payload_native;
  const gql_runtime_vm_native_slot_t *effective_slot = gql_runtime_vm_effective_slot(runtime, slot);
  IV i;

  coerced_hv = newHV();
  /* Owned by a mortal wrapper so a croak from coercion below reclaims the
   * hash during die unwinding. */
  coerced_rv = sv_2mortal(newRV_noinc((SV *)coerced_hv));
  for (i = 0; effective_slot && i < effective_slot->arg_def_count; i++) {
    const gql_runtime_vm_native_arg_def_t *arg_def = &effective_slot->arg_defs[i];
    SV *raw_sv = NULL;
    SV *coerced_sv = NULL;
    const gql_runtime_vm_native_dynamic_value_t *raw_value = NULL;

    raw_value = gql_runtime_vm_native_args_payload_lookup_value(payload, arg_def->name, i);

    if (raw_value) {
      if (op->args_mode_code == GQL_VM_ARGS_DYNAMIC) {
        raw_sv = sv_2mortal(gql_runtime_vm_native_dynamic_value_materialize_sv(aTHX_ raw_value, variables_hv));
      } else {
        raw_sv = sv_2mortal(gql_runtime_vm_native_dynamic_value_materialize_sv(aTHX_ raw_value, NULL));
      }
    } else if (arg_def->has_default && arg_def->default_native_value) {
      coerced_sv = gql_runtime_vm_native_value_materialize_sv(aTHX_ arg_def->default_native_value);
      hv_store(coerced_hv, arg_def->name, (I32)strlen(arg_def->name), coerced_sv, 0);
      continue;
    } else if (arg_def->has_default && arg_def->default_value_sv) {
      raw_sv = sv_2mortal(newSVsv(arg_def->default_value_sv));
    } else {
      continue;
    }

    coerced_sv = gql_runtime_vm_coerce_input_value_sv(aTHX_ arg_def->input_type_sv, raw_sv, croak_out);
    if (croak_out && *croak_out) {
      /* Deferred coercion failure: the partial hash is reclaimed by its
       * mortal wrapper; the caller routes the error to the state's
       * deferred croak channel. */
      SvREFCNT_dec(coerced_sv);
      return NULL;
    }
    hv_store(coerced_hv, arg_def->name, (I32)strlen(arg_def->name), coerced_sv, 0);
  }

  if (HvUSEDKEYS(coerced_hv) == 0) {
    return NULL;
  }
  return SvREFCNT_inc_simple_NN(coerced_rv);
}

/*
 * Croak-safety net for a partially built native args payload: coercion can
 * die mid-loop, and the longjmp would otherwise leak the payload skeleton
 * plus everything specialized so far. Registered on Perl's save stack; the
 * builder disarms it by clearing the payload slot on its normal exits.
 */
static void
gql_runtime_vm_args_payload_guard_fire(pTHX_ void *ptr)
{
  gql_runtime_vm_native_args_payload_t **payload_slot =
    (gql_runtime_vm_native_args_payload_t **)ptr;
  if (payload_slot) {
    if (*payload_slot) {
      gql_runtime_vm_native_args_payload_destroy(aTHX_ *payload_slot);
    }
    Safefree(payload_slot);
  }
}

static gql_runtime_vm_native_args_payload_t *
gql_runtime_vm_specialize_arg_payload_native(
  pTHX_
  const gql_runtime_vm_native_runtime_t *runtime,
  const gql_runtime_vm_native_slot_t *slot,
  const gql_runtime_vm_native_op_t *op,
  HV *variables_hv
)
{
  const gql_runtime_vm_native_args_payload_t *payload = op ? op->args_payload_native : NULL;
  const gql_runtime_vm_native_slot_t *effective_slot = gql_runtime_vm_effective_slot(runtime, slot);
  gql_runtime_vm_native_args_payload_t *ret;
  gql_runtime_vm_native_args_payload_t **payload_guard;
  IV i;

  if (!effective_slot || effective_slot->arg_def_count <= 0) {
    return NULL;
  }

  Newxz(ret, 1, gql_runtime_vm_native_args_payload_t);
  Newxz(ret->names, effective_slot->arg_def_count, char *);
  Newxz(ret->values, effective_slot->arg_def_count, gql_runtime_vm_native_dynamic_value_t *);
  Newxz(payload_guard, 1, gql_runtime_vm_native_args_payload_t *);
  *payload_guard = ret;
  SAVEDESTRUCTOR_X(gql_runtime_vm_args_payload_guard_fire, payload_guard);

  for (i = 0; i < effective_slot->arg_def_count; i++) {
    const gql_runtime_vm_native_arg_def_t *arg_def = &effective_slot->arg_defs[i];
    const gql_runtime_vm_native_dynamic_value_t *raw_value =
      gql_runtime_vm_native_args_payload_lookup_value(payload, arg_def->name, i);
    gql_runtime_vm_native_dynamic_value_t *coerced_value = NULL;

    if (raw_value) {
      SV *raw_sv = NULL;
      SV *coerced_sv;
      if (op && op->args_mode_code == GQL_VM_ARGS_DYNAMIC) {
        raw_sv = sv_2mortal(gql_runtime_vm_native_dynamic_value_materialize_sv(aTHX_ raw_value, variables_hv));
      } else {
        raw_sv = sv_2mortal(gql_runtime_vm_native_dynamic_value_materialize_sv(aTHX_ raw_value, NULL));
      }
      coerced_sv = sv_2mortal(gql_runtime_vm_coerce_input_value_sv(aTHX_ arg_def->input_type_sv, raw_sv, NULL));
      coerced_value = gql_runtime_vm_native_dynamic_value_from_sv(aTHX_ coerced_sv);
    } else if (arg_def->has_default && arg_def->default_native_value) {
      coerced_value = gql_runtime_vm_native_dynamic_value_from_native_value(
        aTHX_ arg_def->default_native_value
      );
    } else if (arg_def->has_default && arg_def->default_value_sv) {
      SV *raw_sv = sv_2mortal(newSVsv(arg_def->default_value_sv));
      SV *coerced_sv = sv_2mortal(gql_runtime_vm_coerce_input_value_sv(aTHX_ arg_def->input_type_sv, raw_sv, NULL));
      coerced_value = gql_runtime_vm_native_dynamic_value_from_sv(aTHX_ coerced_sv);
    } else {
      continue;
    }

    ret->names[ret->count] = savepv(arg_def->name);
    ret->values[ret->count] = coerced_value;
    ret->count++;
  }

  *payload_guard = NULL;

  if (ret->count == 0) {
    gql_runtime_vm_native_args_payload_destroy(aTHX_ ret);
    return NULL;
  }

  return ret;
}

static void
gql_runtime_vm_specialize_native_program_in_place(
  pTHX_
  gql_runtime_vm_native_runtime_t *runtime,
  gql_runtime_vm_native_program_t *program,
  HV *variables_hv
)
{
  IV i;

  if (!program) {
    return;
  }

  for (i = 0; i < program->block_count; i++) {
    gql_runtime_vm_native_block_t *block = &program->blocks[i];
    IV read_index;
    IV write_index = 0;

    for (read_index = 0; read_index < block->op_count; read_index++) {
      gql_runtime_vm_native_op_t *op = &block->ops[read_index];
      const gql_runtime_vm_native_slot_t *slot = NULL;
      int keep = 1;

      if (op->slot_index >= 0 && op->slot_index < block->slot_count) {
        slot = &block->slots[op->slot_index];
      }

      if (op->has_directives && op->directives_mode_code == GQL_VM_ARGS_DYNAMIC) {
        if (!gql_runtime_vm_evaluate_runtime_guards_native(
              aTHX_
              op->directives_payload_native,
              variables_hv
            )) {
          keep = 0;
        } else {
          op->has_directives = 0;
          op->directives_mode_code = GQL_VM_ARGS_NONE;
          gql_runtime_vm_native_directives_payload_destroy(aTHX_ op->directives_payload_native);
          op->directives_payload_native = NULL;
        }
      }

      if (keep && slot && (slot->arg_def_count > 0 || op->has_args)) {
        gql_runtime_vm_native_args_payload_t *specialized_payload = gql_runtime_vm_specialize_arg_payload_native(
          aTHX_ runtime, slot, op, variables_hv
        );
        gql_runtime_vm_native_args_payload_destroy(aTHX_ op->args_payload_native);
        op->args_payload_native = NULL;
        if (specialized_payload) {
          op->args_payload_native = specialized_payload;
          op->args_mode_code = GQL_VM_ARGS_STATIC;
          op->has_args = 1;
        } else {
          op->args_mode_code = GQL_VM_ARGS_NONE;
          op->has_args = 0;
        }
      }

      if (!keep) {
        /* Same asymmetry class as the destroy-path fix: the name strings
         * are owned per entry, so freeing only the array leaks them. */
        gql_runtime_vm_free_op_abstract_child_names(aTHX_ op);
        Safefree(op->abstract_child_indexes);
        gql_runtime_vm_native_args_payload_destroy(aTHX_ op->args_payload_native);
        op->args_payload_native = NULL;
        gql_runtime_vm_native_directives_payload_destroy(aTHX_ op->directives_payload_native);
        op->directives_payload_native = NULL;
        SvREFCNT_dec(op->runtime_directives_sv);
        op->runtime_directives_sv = NULL;
        Zero(op, 1, gql_runtime_vm_native_op_t);
        continue;
      }

      if (write_index != read_index) {
        block->ops[write_index] = block->ops[read_index];
        Zero(&block->ops[read_index], 1, gql_runtime_vm_native_op_t);
      }
      write_index++;
    }
    block->op_count = write_index;
  }
}

#endif
