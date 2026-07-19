/*
 * Responsibility: shared XS types, IR structs, and forward declarations
 * used across the parser, graphql-js compatibility layer, and legacy
 * compatibility builders.
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "../lib/GraphQL/ppport.h"

typedef enum {
  TOK_EOF = 0,
  TOK_BANG,
  TOK_DOLLAR,
  TOK_AMP,
  TOK_LPAREN,
  TOK_RPAREN,
  TOK_SPREAD,
  TOK_COLON,
  TOK_EQUALS,
  TOK_AT,
  TOK_LBRACKET,
  TOK_RBRACKET,
  TOK_LBRACE,
  TOK_RBRACE,
  TOK_PIPE,
  TOK_NAME,
  TOK_INT,
  TOK_FLOAT,
  TOK_STRING,
  TOK_BLOCK_STRING
} gql_token_kind_t;

typedef struct gql_ir_arena_chunk {
  char *buf;
  Size_t used;
  Size_t cap;
  struct gql_ir_arena_chunk *next;
} gql_ir_arena_chunk_t;

typedef struct {
  gql_ir_arena_chunk_t *head;
  gql_ir_arena_chunk_t *tail;
} gql_ir_arena_t;

typedef struct {
  const char *src;
  STRLEN len;
  STRLEN pos;
  STRLEN last_pos;
  STRLEN tok_start;
  STRLEN tok_end;
  STRLEN val_start;
  STRLEN val_end;
  gql_token_kind_t kind;
  bool is_utf8;
  bool no_location;
  UV *line_starts;
  I32 num_lines;
  gql_ir_arena_t *ir_arena;
  /* Nesting depth of the recursive-descent parser (selection sets and
   * input values). Capped so adversarial input cannot overflow the C
   * stack: a deeply nested query used to segfault the worker before any
   * validation ran. */
  IV depth;
  /* Total tokens lexed. Capped so a huge-but-flat document cannot force an
   * unbounded AST from the parse() API independent of any transport-level
   * body limit. */
  IV token_count;
  /* Optional validation-only sink. Public parse() leaves this NULL, so
   * duplicate-name diagnostics do not change the canonical AST or allocate
   * metadata on the parser hot path. */
  AV *validation_errors;
} gql_parser_t;

/* Maximum selection-set / input-value nesting. Real documents nest a few
 * dozen levels; 512 is well clear of that yet far below the ~35k that
 * overflows an 8 MB stack. Exceeding it is a request error, not a crash. */
#ifndef GQL_PARSER_MAX_DEPTH
#define GQL_PARSER_MAX_DEPTH 512
#endif

/* Maximum tokens per document. Real documents (including large SDL schemas
 * and full introspection queries) stay well under this; a million tokens
 * is a multi-MB adversarial document, not a legitimate request. */
#ifndef GQL_PARSER_MAX_TOKENS
#define GQL_PARSER_MAX_TOKENS 1000000
#endif

typedef struct {
  const char *src;
  STRLEN len;
  AV *rewrites;
  UV *line_starts;
  I32 num_lines;
  struct gql_parser_rewrite_index *rewrite_index;
  I32 rewrite_index_count;
  UV last_original_pos;
  I32 last_line_index;
  bool has_last_line_index;
  bool lazy_location;
  bool compact_location;
} gql_parser_loc_context_t;

typedef struct gql_parser_rewrite_index {
  UV original_start;
  IV rewritten_start;
  IV rewritten_end;
  IV delta_after;
} gql_parser_rewrite_index_t;

typedef struct {
  I32 count;
  I32 cap;
  void **items;
} gql_ir_ptr_array_t;

typedef struct {
  UV start;
  UV end;
} gql_ir_span_t;

typedef enum {
  GQL_IR_TYPE_NAMED = 0,
  GQL_IR_TYPE_LIST,
  GQL_IR_TYPE_NON_NULL
} gql_ir_type_kind_t;

typedef enum {
  GQL_IR_VALUE_NULL = 0,
  GQL_IR_VALUE_BOOL,
  GQL_IR_VALUE_INT,
  GQL_IR_VALUE_FLOAT,
  GQL_IR_VALUE_STRING,
  GQL_IR_VALUE_ENUM,
  GQL_IR_VALUE_VARIABLE,
  GQL_IR_VALUE_LIST,
  GQL_IR_VALUE_OBJECT
} gql_ir_value_kind_t;

typedef enum {
  GQL_IR_SELECTION_FIELD = 0,
  GQL_IR_SELECTION_FRAGMENT_SPREAD,
  GQL_IR_SELECTION_INLINE_FRAGMENT
} gql_ir_selection_kind_t;

typedef enum {
  GQL_IR_DEFINITION_OPERATION = 0,
  GQL_IR_DEFINITION_FRAGMENT
} gql_ir_definition_kind_t;

typedef enum {
  GQL_IR_OPERATION_QUERY = 0,
  GQL_IR_OPERATION_MUTATION,
  GQL_IR_OPERATION_SUBSCRIPTION
} gql_ir_operation_kind_t;

typedef struct gql_ir_type gql_ir_type_t;
typedef struct gql_ir_value gql_ir_value_t;
typedef struct gql_ir_directive gql_ir_directive_t;
typedef struct gql_ir_argument gql_ir_argument_t;
typedef struct gql_ir_object_field gql_ir_object_field_t;
typedef struct gql_ir_variable_definition gql_ir_variable_definition_t;
typedef struct gql_ir_selection gql_ir_selection_t;
typedef struct gql_ir_selection_set gql_ir_selection_set_t;
typedef struct gql_ir_field gql_ir_field_t;
typedef struct gql_ir_fragment_spread gql_ir_fragment_spread_t;
typedef struct gql_ir_inline_fragment gql_ir_inline_fragment_t;
typedef struct gql_ir_operation_definition gql_ir_operation_definition_t;
typedef struct gql_ir_fragment_definition gql_ir_fragment_definition_t;
typedef struct gql_ir_definition gql_ir_definition_t;
typedef struct gql_ir_document gql_ir_document_t;
typedef struct gql_ir_prepared_exec gql_ir_prepared_exec_t;
typedef struct gql_ir_compiled_exec gql_ir_compiled_exec_t;
typedef struct gql_ir_compiled_root_field_plan_entry gql_ir_compiled_root_field_plan_entry_t;
typedef struct gql_ir_compiled_root_field_plan gql_ir_compiled_root_field_plan_t;
typedef struct gql_runtime_vm_lowered_plan gql_runtime_vm_lowered_plan_t;
typedef struct gql_ir_vm_block gql_ir_vm_block_t;
typedef struct gql_ir_vm_exec_state gql_ir_vm_exec_state_t;
typedef struct gql_ir_vm_field_meta gql_ir_vm_field_meta_t;
typedef struct gql_ir_vm_field_hot gql_ir_vm_field_hot_t;
typedef struct gql_ir_vm_field_cold gql_ir_vm_field_cold_t;
typedef struct gql_ir_vm_program gql_ir_vm_program_t;
typedef struct gql_ir_vm_field_slot gql_ir_vm_field_slot_t;
typedef struct gql_ir_lowered_abstract_child_entry gql_ir_lowered_abstract_child_entry_t;
typedef struct gql_ir_lowered_abstract_child_plan_table gql_ir_lowered_abstract_child_plan_table_t;
typedef struct gql_ir_compiled_concrete_plan_entry gql_ir_compiled_concrete_plan_entry_t;
typedef struct gql_ir_compiled_concrete_plan_table gql_ir_compiled_concrete_plan_table_t;
typedef struct gql_ir_compiled_field_bucket_entry gql_ir_compiled_field_bucket_entry_t;
typedef struct gql_ir_compiled_field_bucket_table gql_ir_compiled_field_bucket_table_t;
typedef struct gql_execution_context_fast_cache gql_execution_context_fast_cache_t;
typedef struct gql_ir_native_exec_env gql_ir_native_exec_env_t;
typedef struct gql_ir_vm_exec_hot gql_ir_vm_exec_hot_t;
typedef struct gql_ir_native_exec_accum gql_ir_native_exec_accum_t;
typedef struct gql_ir_native_result_writer gql_ir_native_result_writer_t;
typedef struct gql_ir_native_pending_entry gql_ir_native_pending_entry_t;
typedef struct gql_ir_native_child_outcome gql_ir_native_child_outcome_t;
typedef struct gql_execution_lazy_resolve_info gql_execution_lazy_resolve_info_t;
typedef struct gql_ir_native_field_frame gql_ir_native_field_frame_t;
typedef enum gql_ir_native_field_op gql_ir_native_field_op_t;
typedef enum gql_ir_native_meta_dispatch_kind gql_ir_native_meta_dispatch_kind_t;
typedef enum gql_ir_native_resolve_dispatch_kind gql_ir_native_resolve_dispatch_kind_t;
typedef enum gql_ir_native_args_dispatch_kind gql_ir_native_args_dispatch_kind_t;
typedef enum gql_ir_native_completion_dispatch_kind gql_ir_native_completion_dispatch_kind_t;
typedef enum gql_ir_abstract_dispatch_kind gql_ir_abstract_dispatch_kind_t;
typedef enum gql_ir_compilation_stage gql_ir_compilation_stage_t;
typedef struct {
  gql_ir_document_t *document;
} gql_ir_document_cleanup_t;

enum gql_ir_compilation_stage {
  GQL_IR_COMPILATION_STAGE_NONE = 0,
  GQL_IR_COMPILATION_STAGE_LOWERED_NATIVE_FIELDS = 1
};

enum gql_ir_native_field_op {
  GQL_IR_NATIVE_FIELD_OP_META = 0,
  GQL_IR_NATIVE_FIELD_OP_TRIVIAL_CONTEXT = 1,
  GQL_IR_NATIVE_FIELD_OP_CALL_FIXED_EMPTY_ARGS = 2,
  GQL_IR_NATIVE_FIELD_OP_CALL_FIXED_BUILD_ARGS = 3,
  GQL_IR_NATIVE_FIELD_OP_CALL_CONTEXT_EMPTY_ARGS = 4,
  GQL_IR_NATIVE_FIELD_OP_CALL_CONTEXT_BUILD_ARGS = 5,
  GQL_IR_NATIVE_FIELD_OP_COMPLETE_TRIVIAL = 6,
  GQL_IR_NATIVE_FIELD_OP_COMPLETE_GENERIC = 7,
  GQL_IR_NATIVE_FIELD_OP_COMPLETE_OBJECT = 8,
  GQL_IR_NATIVE_FIELD_OP_COMPLETE_LIST = 9,
  GQL_IR_NATIVE_FIELD_OP_COMPLETE_ABSTRACT_TAG = 10,
  GQL_IR_NATIVE_FIELD_OP_COMPLETE_ABSTRACT_RESOLVE_TYPE = 11,
  GQL_IR_NATIVE_FIELD_OP_COMPLETE_ABSTRACT_POSSIBLE_TYPES = 12,
  GQL_IR_NATIVE_FIELD_OP_COMPLETE_ABSTRACT = 13,
  GQL_IR_NATIVE_FIELD_OP_CONSUME = 14
};

enum gql_ir_native_meta_dispatch_kind {
  GQL_IR_NATIVE_META_DISPATCH_NONE = 0,
  GQL_IR_NATIVE_META_DISPATCH_TYPENAME = 1
};

enum gql_ir_native_resolve_dispatch_kind {
  GQL_IR_NATIVE_RESOLVE_DISPATCH_FIXED = 0,
  GQL_IR_NATIVE_RESOLVE_DISPATCH_CONTEXT_OR_DEFAULT = 1
};

enum gql_ir_native_args_dispatch_kind {
  GQL_IR_NATIVE_ARGS_DISPATCH_EMPTY = 0,
  GQL_IR_NATIVE_ARGS_DISPATCH_BUILD = 1
};

enum gql_ir_native_completion_dispatch_kind {
  GQL_IR_NATIVE_COMPLETION_GENERIC = 0,
  GQL_IR_NATIVE_COMPLETION_TRIVIAL = 1,
  GQL_IR_NATIVE_COMPLETION_OBJECT = 2,
  GQL_IR_NATIVE_COMPLETION_LIST = 3,
  GQL_IR_NATIVE_COMPLETION_ABSTRACT = 4
};

enum gql_ir_abstract_dispatch_kind {
  GQL_IR_ABSTRACT_DISPATCH_NONE = 0,
  GQL_IR_ABSTRACT_DISPATCH_TAG = 1,
  GQL_IR_ABSTRACT_DISPATCH_RESOLVE_TYPE = 2,
  GQL_IR_ABSTRACT_DISPATCH_POSSIBLE_TYPES = 3
};

struct gql_execution_lazy_resolve_info {
  SV *context_sv;
  SV *parent_type_sv;
  SV *field_def_sv;
  SV *return_type_sv;
  SV *field_name_sv;
  SV *nodes_sv;
  SV *base_path_sv;
  SV *result_name_sv;
  SV *path_sv;
  SV *info_sv;
};

struct gql_ir_native_field_frame {
  gql_ir_vm_field_meta_t *meta;
  gql_execution_lazy_resolve_info_t lazy_info;
  SV *resolve_sv;
  SV *args_sv;
  SV *result_sv;
  SV *outcome_sv;
  AV *outcome_errors_av;
  int used_fast_default_resolve;
  int owns_resolve_sv;
  int owns_args_sv;
  int resolve_is_default;
  U8 outcome_kind;
};

enum {
  GQL_IR_NATIVE_FIELD_OUTCOME_NONE = 0,
  GQL_IR_NATIVE_FIELD_OUTCOME_DIRECT_VALUE = 1,
  GQL_IR_NATIVE_FIELD_OUTCOME_COMPLETED_SV = 2,
  GQL_IR_NATIVE_FIELD_OUTCOME_DIRECT_OBJECT_HV = 3,
  GQL_IR_NATIVE_FIELD_OUTCOME_DIRECT_LIST_AV = 4
};

struct gql_ir_prepared_exec {
  gql_ir_document_t *document;
  SV *source_sv;
  SV *cached_operation_name_sv;
  SV *cached_operation_legacy_sv;
  SV *cached_fragments_legacy_sv;
  SV *cached_root_legacy_fields_sv;
};

struct gql_ir_vm_field_meta {
  SV *result_name_sv;
  SV *field_name_sv;
  SV *return_type_sv;
  SV *completion_type_sv;
  SV *list_item_type_sv;
  UV argument_count;
  UV field_arg_count;
  UV directive_count;
  UV selection_count;
  UV trivial_completion_flags;
  U8 op_count;
  U8 consume_op_index;
  gql_ir_native_field_op_t ops[5];
  gql_ir_native_meta_dispatch_kind_t meta_dispatch_kind;
  gql_ir_native_resolve_dispatch_kind_t resolve_dispatch_kind;
  gql_ir_native_args_dispatch_kind_t args_dispatch_kind;
  gql_ir_native_completion_dispatch_kind_t completion_dispatch_kind;
  gql_ir_abstract_dispatch_kind_t abstract_dispatch_kind;
};

struct gql_ir_vm_field_hot {
  SV *field_def_sv;
  SV *return_type_sv;
  SV *type_sv;
  SV *resolve_sv;
  SV *nodes_sv;
  SV *first_node_sv;
  gql_ir_compiled_root_field_plan_t *native_field_plan;
  gql_ir_vm_block_t *native_block;
  gql_ir_lowered_abstract_child_plan_table_t *abstract_child_plan_table;
  gql_ir_lowered_abstract_child_plan_table_t *list_item_abstract_child_plan_table;
};

struct gql_ir_vm_field_cold {
  SV *path_sv;
  UV node_count;
};

struct gql_ir_native_child_outcome {
  HV *data_hv;
  AV *errors_av;
};

typedef enum {
  GQL_EXECUTION_SYNC_OUTCOME_NONE = 0,
  GQL_EXECUTION_SYNC_OUTCOME_DIRECT_VALUE = 1,
  GQL_EXECUTION_SYNC_OUTCOME_COMPLETED_SV = 2,
  GQL_EXECUTION_SYNC_OUTCOME_DIRECT_OBJECT_HV = 3,
  GQL_EXECUTION_SYNC_OUTCOME_DIRECT_LIST_AV = 4
} gql_execution_sync_outcome_kind_t;

struct gql_execution_sync_outcome {
  gql_execution_sync_outcome_kind_t kind;
  SV *value_sv;
  HV *object_hv;
  AV *list_av;
  AV *errors_av;
  SV *completed_sv;
};
typedef struct gql_execution_sync_outcome gql_execution_sync_outcome_t;

struct gql_ir_compiled_root_field_plan_entry {
  gql_ir_vm_field_meta_t *meta;
  gql_ir_vm_field_meta_t meta_inline;
  gql_ir_vm_field_hot_t *hot;
  gql_ir_vm_field_hot_t hot_inline;
  gql_ir_vm_field_cold_t *cold;
  gql_ir_vm_field_cold_t cold_inline;
  SV *field_def_sv;
  SV *type_sv;
  SV *resolve_sv;
  SV *nodes_sv;
  SV *first_node_sv;
  U8 operands_ready;
  gql_ir_compiled_root_field_plan_t *native_field_plan;
  gql_ir_vm_block_t *native_block;
  gql_ir_lowered_abstract_child_plan_table_t *abstract_child_plan_table;
  gql_ir_lowered_abstract_child_plan_table_t *list_item_abstract_child_plan_table;
};

struct gql_ir_compiled_root_field_plan {
  UV field_count;
  U8 requires_runtime_operand_fill;
  SV *fallback_subfields_sv;
  gql_ir_compiled_root_field_plan_entry_t *entries;
};

struct gql_ir_vm_block {
  gql_ir_compiled_root_field_plan_t *field_plan;
  gql_ir_compiled_root_field_plan_entry_t *entries;
  gql_ir_vm_field_slot_t *slots;
  UV field_count;
  U8 requires_runtime_operand_fill;
  U8 owns_field_plan;
};

struct gql_ir_vm_field_slot {
  gql_ir_compiled_root_field_plan_entry_t *entry;
  gql_ir_vm_field_meta_t *meta;
  gql_ir_vm_field_hot_t *hot;
  gql_ir_vm_field_cold_t *cold;
  SV *field_def_sv;
  SV *resolve_sv;
  SV *nodes_sv;
  SV *first_node_sv;
  SV *type_sv;
  SV *path_sv;
  gql_ir_compiled_root_field_plan_t *native_field_plan;
  gql_ir_vm_block_t *native_block;
  gql_ir_lowered_abstract_child_plan_table_t *abstract_child_plan_table;
  gql_ir_lowered_abstract_child_plan_table_t *list_item_abstract_child_plan_table;
};

typedef struct {
  UV field_index;
  U8 pc;
  gql_ir_native_field_op_t current_op;
  gql_ir_vm_field_slot_t *slot;
  gql_ir_compiled_root_field_plan_entry_t *entry;
  gql_ir_vm_field_meta_t *meta;
  gql_ir_vm_field_hot_t *hot;
  gql_ir_vm_field_cold_t *cold;
  SV *field_def_sv;
  SV *resolve_sv;
  SV *nodes_sv;
  SV *first_node_sv;
  SV *type_sv;
  SV *path_sv;
  gql_ir_compiled_root_field_plan_t *native_field_plan;
  gql_ir_vm_block_t *native_block;
  gql_ir_lowered_abstract_child_plan_table_t *abstract_child_plan_table;
  gql_ir_lowered_abstract_child_plan_table_t *list_item_abstract_child_plan_table;
} gql_ir_vm_exec_cursor_t;

struct gql_ir_vm_exec_state {
  gql_ir_compiled_exec_t *compiled;
  gql_ir_vm_block_t *block;
  gql_ir_native_exec_env_t *env;
  gql_ir_native_result_writer_t *writer;
  int *promise_present;
  gql_ir_vm_exec_cursor_t cursor;
  gql_ir_native_field_frame_t frame;
  U8 require_runtime_operand_fill;
};

struct gql_ir_vm_program {
  gql_ir_compilation_stage_t stage;
  gql_ir_vm_block_t *root_block;
};

struct gql_runtime_vm_lowered_plan {
  gql_ir_vm_program_t *program;
};

struct gql_ir_lowered_abstract_child_entry {
  SV *possible_type_sv;
  SV *possible_type_name_sv;
  SV *dispatch_tag_sv;
  gql_ir_compiled_root_field_plan_t *native_field_plan;
  gql_ir_vm_block_t *native_block;
};

struct gql_ir_lowered_abstract_child_plan_table {
  UV count;
  gql_ir_lowered_abstract_child_entry_t *entries;
  SV *tag_resolver_sv;
  SV *cached_possible_type_sv;
  SV *cached_possible_type_name_sv;
  SV *cached_dispatch_tag_sv;
  gql_ir_compiled_root_field_plan_t *cached_native_field_plan;
  gql_ir_vm_block_t *cached_native_block;
  U8 dispatch_tags_ready;
};

struct gql_ir_compiled_concrete_plan_entry {
  SV *possible_type_sv;
  SV *compiled_fields_sv;
  SV *field_plan_sv;
  gql_ir_compiled_root_field_plan_t *native_field_plan;
  gql_ir_vm_block_t *native_block;
};

struct gql_ir_compiled_concrete_plan_table {
  UV count;
  gql_ir_compiled_concrete_plan_entry_t *entries;
};

struct gql_ir_compiled_field_bucket_entry {
  SV *result_name_sv;
  SV *nodes_sv;
};

struct gql_ir_compiled_field_bucket_table {
  UV count;
  gql_ir_compiled_field_bucket_entry_t *entries;
};

struct gql_ir_compiled_exec {
  SV *prepared_handle_sv;
  SV *schema_sv;
  SV *operation_name_sv;
  gql_ir_operation_definition_t *selected_operation;
  SV *root_selection_plan_sv;
  gql_runtime_vm_lowered_plan_t *lowered_plan;
  SV *root_field_plan_sv;
  SV *root_type_sv;
};

struct gql_execution_context_fast_cache {
  SV *schema_sv;
  SV *fragments_sv;
  SV *root_value_sv;
  SV *context_value_sv;
  SV *operation_sv;
  SV *variable_values_sv;
  SV *field_resolver_sv;
  SV *promise_code_sv;
  SV *empty_args_sv;
  SV *compiled_root_field_defs_sv;
  HV *resolve_info_base_hv;
};

struct gql_ir_vm_exec_hot {
  SV *context_sv;
  SV *parent_type_sv;
  SV *root_value_sv;
  SV *base_path_sv;
  SV *promise_code_sv;
};

struct gql_ir_native_exec_env {
  gql_ir_vm_exec_hot_t hot_inline;
  gql_ir_vm_exec_hot_t *hot;
  SV *context_value_sv;
  SV *variable_values_sv;
  SV *empty_args_sv;
  SV *field_resolver_sv;
};

struct gql_ir_native_pending_entry {
  SV *key_sv;
  SV *value_sv;
};

struct gql_ir_native_result_writer {
  HV *direct_data_hv;
  AV *all_errors_av;
  gql_ir_native_pending_entry_t *pending_entries;
  UV pending_count;
  UV pending_capacity;
};

struct gql_ir_native_exec_accum {
  gql_ir_native_result_writer_t writer;
  int promise_present;
};


typedef enum {
  GQLJS_LAZY_ARRAY_ARGUMENTS = 1,
  GQLJS_LAZY_ARRAY_DIRECTIVES = 2,
  GQLJS_LAZY_ARRAY_VARIABLE_DEFINITIONS = 3,
  GQLJS_LAZY_ARRAY_OBJECT_FIELDS = 4
} gql_parser_lazy_array_kind_t;

typedef struct {
  gql_ir_document_t *document;
  SV *source_sv;
  gql_parser_loc_context_t ctx;
  bool has_ctx;
} gql_parser_lazy_state_t;

struct gql_ir_type {
  gql_ir_type_kind_t kind;
  UV start_pos;
  gql_ir_span_t name;
  gql_ir_type_t *inner;
};

struct gql_ir_argument {
  UV start_pos;
  gql_ir_span_t name;
  gql_ir_value_t *value;
};

struct gql_ir_object_field {
  UV start_pos;
  gql_ir_span_t name;
  gql_ir_value_t *value;
};

struct gql_ir_value {
  gql_ir_value_kind_t kind;
  UV start_pos;
  UV name_pos;
  bool is_block_string;
  union {
    int boolean;
    gql_ir_span_t span;
    gql_ir_ptr_array_t list_items;
    gql_ir_ptr_array_t object_fields;
  } as;
};

struct gql_ir_directive {
  UV start_pos;
  UV name_pos;
  gql_ir_span_t name;
  gql_ir_ptr_array_t arguments;
};

struct gql_ir_variable_definition {
  UV start_pos;
  UV name_pos;
  gql_ir_span_t name;
  gql_ir_type_t *type;
  gql_ir_value_t *default_value;
  gql_ir_ptr_array_t directives;
};

struct gql_ir_field {
  UV start_pos;
  UV alias_pos;
  UV name_pos;
  gql_ir_span_t alias;
  gql_ir_span_t name;
  gql_ir_ptr_array_t arguments;
  gql_ir_ptr_array_t directives;
  gql_ir_selection_set_t *selection_set;
};

struct gql_ir_fragment_spread {
  UV start_pos;
  UV name_pos;
  gql_ir_span_t name;
  gql_ir_ptr_array_t directives;
};

struct gql_ir_inline_fragment {
  UV start_pos;
  UV type_condition_pos;
  gql_ir_span_t type_condition;
  gql_ir_ptr_array_t directives;
  gql_ir_selection_set_t *selection_set;
};

struct gql_ir_selection {
  gql_ir_selection_kind_t kind;
  union {
    gql_ir_field_t *field;
    gql_ir_fragment_spread_t *fragment_spread;
    gql_ir_inline_fragment_t *inline_fragment;
  } as;
};

struct gql_ir_selection_set {
  UV start_pos;
  gql_ir_ptr_array_t selections;
};

struct gql_ir_operation_definition {
  gql_ir_operation_kind_t operation;
  UV start_pos;
  UV name_pos;
  gql_ir_span_t name;
  gql_ir_ptr_array_t variable_definitions;
  gql_ir_ptr_array_t directives;
  gql_ir_selection_set_t *selection_set;
};

struct gql_ir_fragment_definition {
  UV start_pos;
  UV name_pos;
  UV type_condition_pos;
  gql_ir_span_t name;
  gql_ir_span_t type_condition;
  gql_ir_ptr_array_t directives;
  gql_ir_selection_set_t *selection_set;
};

struct gql_ir_definition {
  gql_ir_definition_kind_t kind;
  union {
    gql_ir_operation_definition_t *operation;
    gql_ir_fragment_definition_t *fragment;
  } as;
};

struct gql_ir_document {
  gql_ir_ptr_array_t definitions;
  gql_ir_arena_t arena;
  const char *src;
  STRLEN len;
  bool is_utf8;
};

static SV *gql_parse_document(pTHX_ SV *source_sv, SV *no_location_sv);
static SV *gql_parse_document_for_validation(
  pTHX_ SV *source_sv, SV *no_location_sv, AV *validation_errors
);
static void gql_advance(pTHX_ gql_parser_t *p);
static void gql_skip_ignored(gql_parser_t *p);
static void gql_lex_token(pTHX_ gql_parser_t *p);
static void gql_throw(pTHX_ gql_parser_t *p, STRLEN pos, const char *msg);
static void gql_expect(pTHX_ gql_parser_t *p, gql_token_kind_t kind, const char *msg);
static int gql_peek_name(gql_parser_t *p, const char *name);
static SV *gql_parse_definition(pTHX_ gql_parser_t *p);
static SV *gql_parse_type_system_definition(pTHX_ gql_parser_t *p, SV *description);
static AV *gql_parse_definitions(pTHX_ gql_parser_t *p);
static SV *gql_parse_operation_definition(pTHX_ gql_parser_t *p, SV *description);
static SV *gql_parse_fragment_definition(pTHX_ gql_parser_t *p, SV *description);
static SV *gql_parse_selection_set(pTHX_ gql_parser_t *p);
static SV *gql_parse_selection(pTHX_ gql_parser_t *p);
static SV *gql_parse_field(pTHX_ gql_parser_t *p);
static SV *gql_parse_arguments(pTHX_ gql_parser_t *p, int is_const);
static SV *gql_parse_value(pTHX_ gql_parser_t *p, int is_const);
static SV *gql_parse_object_value(pTHX_ gql_parser_t *p, int is_const);
static SV *gql_parse_list_value(pTHX_ gql_parser_t *p, int is_const);
static SV *gql_parse_directives(pTHX_ gql_parser_t *p);
static SV *gql_parse_const_directives(pTHX_ gql_parser_t *p);
static SV *gql_parse_directive(pTHX_ gql_parser_t *p);
static SV *gql_parse_variable_definitions(pTHX_ gql_parser_t *p);
static SV *gql_parse_type_reference(pTHX_ gql_parser_t *p);
static SV *gql_parse_schema_definition(pTHX_ gql_parser_t *p);
static SV *gql_parse_schema_definition_extended(pTHX_ gql_parser_t *p, int allow_empty_body);
static SV *gql_parse_scalar_type_definition(pTHX_ gql_parser_t *p);
static SV *gql_parse_object_type_definition(pTHX_ gql_parser_t *p, const char *kind);
static SV *gql_parse_union_type_definition(pTHX_ gql_parser_t *p);
static SV *gql_parse_enum_type_definition(pTHX_ gql_parser_t *p);
static SV *gql_parse_directive_definition(pTHX_ gql_parser_t *p);
static SV *gql_parse_input_value_definition(pTHX_ gql_parser_t *p);
static SV *gql_parse_field_definition(pTHX_ gql_parser_t *p);
static SV *gql_parse_arguments_definition(pTHX_ gql_parser_t *p);
static SV *gql_parse_description(pTHX_ gql_parser_t *p);
static SV *gql_copy_token_sv(pTHX_ gql_parser_t *p);
static SV *gql_copy_value_sv(pTHX_ gql_parser_t *p);
static SV *gql_unescape_string_sv(pTHX_ SV *raw);
static int gql_hex4_to_uv(const char *src, UV *value);
static SV *gql_make_string_sv(pTHX_ gql_parser_t *p, STRLEN start, STRLEN end);
static SV *gql_make_location(pTHX_ gql_parser_t *p);
static SV *gql_make_current_location(pTHX_ gql_parser_t *p);
static SV *gql_make_endline_location(pTHX_ gql_parser_t *p);
static SV *gql_make_current_or_endline_location(pTHX_ gql_parser_t *p);
static void gql_parser_init(pTHX_ gql_parser_t *p, SV *source_sv, int no_location);
static void gql_parser_invalidate(gql_parser_t *p);
static void gql_store_current_location(pTHX_ gql_parser_t *p, HV *hv);
static void gql_store_endline_location(pTHX_ gql_parser_t *p, HV *hv);
static void gql_store_current_or_endline_location(pTHX_ gql_parser_t *p, HV *hv);
static void gql_store_sv(HV *hv, const char *key, SV *value);
static SV *gql_make_type_wrapper(pTHX_ SV *type_sv, const char *kind);
static SV *gql_parse_name(pTHX_ gql_parser_t *p, const char *msg);
static SV *gql_parse_fragment_name(pTHX_ gql_parser_t *p);
static gql_ir_span_t gql_ir_parse_name_span(pTHX_ gql_parser_t *p, const char *msg);
static gql_ir_span_t gql_ir_parse_fragment_name_span(pTHX_ gql_parser_t *p);
static void gql_line_column_from_last(gql_parser_t *p, IV *line, IV *column);
static void gql_line_column_from_pos(gql_parser_t *p, STRLEN pos, IV *line, IV *column, int one_based);
static void gql_throw_sv(pTHX_ gql_parser_t *p, STRLEN pos, SV *msg);
static const char *gql_expected_token_label(gql_token_kind_t kind);
static SV *gql_current_token_desc_sv(pTHX_ gql_parser_t *p);
static void gql_throw_expected_message(pTHX_ gql_parser_t *p, STRLEN pos, const char *msg);
static void gql_throw_expected_token(pTHX_ gql_parser_t *p, gql_token_kind_t kind);
static void gql_throw_unexpected_character(pTHX_ gql_parser_t *p, STRLEN pos, unsigned char c);
static void gql_parser_skip_quoted_string_raw(const char *src, STRLEN len, STRLEN *pos);
static void gql_parser_skip_delimited_raw(const char *src, STRLEN len, STRLEN *pos, char open, char close);
static void gql_parser_store_hash_key_sv(HV *hv, SV *key_sv, SV *value);
static void *gql_ir_arena_alloc_zero(gql_ir_arena_t *arena, Size_t size);
static void gql_ir_arena_free(gql_ir_arena_t *arena);
static void gql_ir_ptr_array_push(gql_ir_ptr_array_t *array, void *item);
static void gql_ir_ptr_array_free(gql_ir_ptr_array_t *array);
static gql_ir_type_t *gql_ir_parse_type_reference(pTHX_ gql_parser_t *p);
static gql_ir_value_t *gql_ir_parse_value(pTHX_ gql_parser_t *p, int is_const);
static gql_ir_ptr_array_t gql_ir_parse_arguments(pTHX_ gql_parser_t *p, int is_const);
static gql_ir_ptr_array_t gql_ir_parse_directives(pTHX_ gql_parser_t *p);
static gql_ir_selection_set_t *gql_ir_parse_selection_set(pTHX_ gql_parser_t *p);
static gql_ir_selection_t *gql_ir_parse_selection(pTHX_ gql_parser_t *p);
static void gql_ir_free_type(gql_ir_type_t *type);
static void gql_ir_free_value(gql_ir_value_t *value);
static void gql_ir_free_directive(gql_ir_directive_t *directive);
static void gql_ir_free_argument(gql_ir_argument_t *argument);
static void gql_ir_free_object_field(gql_ir_object_field_t *field);
static void gql_ir_free_variable_definition(gql_ir_variable_definition_t *definition);
static void gql_ir_free_selection(gql_ir_selection_t *selection);
static void gql_ir_free_selection_set(gql_ir_selection_set_t *selection_set);
static void gql_ir_free_operation_definition(gql_ir_operation_definition_t *definition);
static void gql_ir_free_fragment_definition(gql_ir_fragment_definition_t *definition);
static void gql_ir_free_definition(gql_ir_definition_t *definition);
static void gql_ir_free_document(gql_ir_document_t *document);
static void gql_parser_loc_context_destroy(gql_parser_loc_context_t *ctx);
static UV gql_parser_original_pos_from_rewritten_pos(gql_parser_loc_context_t *ctx, UV rewritten_pos);
static SV *gql_parser_new_loc_sv(pTHX_ IV line, IV column);
static SV *gql_parser_new_lazy_loc_sv(pTHX_ UV start);
static gql_parser_lazy_state_t *gql_parser_lazy_state_from_sv(SV *state_sv);
static void gql_parser_lazy_state_destroy(gql_parser_lazy_state_t *state);
static SV *gql_parser_new_lazy_arguments_sv(pTHX_ SV *state_sv, gql_ir_ptr_array_t *arguments);
static SV *gql_parser_new_lazy_directives_sv(pTHX_ SV *state_sv, gql_ir_ptr_array_t *directives);
static SV *gql_parser_new_lazy_object_fields_sv(pTHX_ SV *state_sv, gql_ir_ptr_array_t *fields);
static AV *gql_parser_materialize_lazy_array(pTHX_ SV *state_sv, UV ptr, IV kind);
static SV *gql_parser_loc_from_rewritten_pos(pTHX_ gql_parser_loc_context_t *ctx, UV rewritten_pos);
static SV *gql_ir_make_sv_from_span(pTHX_ gql_ir_document_t *document, gql_ir_span_t span);
static SV *gql_ir_make_string_value_sv(pTHX_ gql_ir_document_t *document, gql_ir_value_t *value);
static SV *gql_parser_build_type_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_type_t *type);
static AV *gql_parser_build_object_fields_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_ptr_array_t *fields, SV *state_sv);
static SV *gql_parser_build_value_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_value_t *value, SV *state_sv);
static AV *gql_parser_build_arguments_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_ptr_array_t *arguments, SV *state_sv);
static AV *gql_parser_build_directives_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_ptr_array_t *directives, SV *state_sv);
static SV *gql_parser_build_selection_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_selection_t *selection, SV *state_sv);
static SV *gql_parser_build_selection_set_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_selection_set_t *selection_set, SV *state_sv);
static AV *gql_parser_build_variable_definitions_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_ptr_array_t *definitions, SV *state_sv);
static SV *gql_parser_clone_with_loc(pTHX_ SV *value, SV *loc_sv);
static void gql_parser_set_loc_node(pTHX_ SV *node_sv, SV *loc_sv);
static void gql_parser_set_rewritten_loc_node(pTHX_ gql_parser_loc_context_t *ctx, SV *node_sv, UV rewritten_pos);
static void gql_parser_set_shared_rewritten_loc_nodes(pTHX_ gql_parser_loc_context_t *ctx, UV rewritten_pos, SV *left_sv, SV *right_sv);
static HV *gql_parser_node_hv(SV *node_sv);
static SV *gql_parser_fetch_sv(HV *hv, const char *key);
static AV *gql_parser_fetch_array(HV *hv, const char *key);
static const char *gql_parser_fetch_kind(HV *hv);
static const char *gql_parser_name_value(SV *node_sv);
static SV *gql_parser_find_named_node(AV *av, const char *name);
static SV *gql_parser_find_named_node_sv(AV *av, SV *name_sv);
static SV *gql_parser_locate_name_node(pTHX_ gql_parser_t *p, SV *node_sv);
static SV *gql_parser_locate_type_node(pTHX_ gql_parser_t *p, SV *node_sv);
static SV *gql_parser_locate_value_node(pTHX_ gql_parser_t *p, SV *node_sv);
static void gql_parser_locate_arguments_nodes(pTHX_ gql_parser_t *p, AV *av);
static void gql_parser_locate_directives_nodes(pTHX_ gql_parser_t *p, AV *av);
static SV *gql_parser_locate_selection_set_node(pTHX_ gql_parser_t *p, SV *node_sv);
static void gql_parser_locate_selection_node(pTHX_ gql_parser_t *p, SV *node_sv);
static HV *gql_parser_new_node_hv_sized(const char *kind, I32 keys);
static HV *gql_parser_new_node_hv(const char *kind);
static SV *gql_parser_new_node_ref(const char *kind);
static SV *gql_parser_new_name_node_sv(pTHX_ SV *value_sv);
static SV *gql_parser_new_named_type_node_sv(pTHX_ SV *value_sv);
static SV *gql_parser_new_variable_node_sv(pTHX_ SV *value_sv);
static int gql_parser_cmp_sv_ptrs(const void *a, const void *b);
static SV **gql_parser_sorted_hash_keys(pTHX_ HV *hv, I32 *count_out);
static void gql_parser_free_sorted_hash_keys(SV **keys, I32 count);
static SV *gqlperl_location_from_gql_parser_node(pTHX_ SV *node_sv);
static void gqlperl_store_location_from_gql_parser_node(pTHX_ HV *dst_hv, SV *node_sv);
static SV *gqlperl_convert_type_from_gqljs(pTHX_ SV *node_sv);
static SV *gqlperl_convert_value_from_gqljs(pTHX_ SV *node_sv);
static SV *gqlperl_convert_arguments_from_gqljs(pTHX_ AV *av);
static SV *gqlperl_convert_directives_from_gqljs(pTHX_ AV *av);
static SV *gqlperl_convert_selection_from_gqljs(pTHX_ SV *node_sv);
static AV *gqlperl_convert_selections_from_gqljs(pTHX_ AV *av);
