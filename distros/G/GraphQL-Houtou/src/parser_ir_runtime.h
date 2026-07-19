
static void *
gql_ir_arena_alloc_zero(gql_ir_arena_t *arena, Size_t size) {
  gql_ir_arena_chunk_t *chunk;
  Size_t aligned_used;
  Size_t next_used;
  Size_t chunk_cap;
  char *ptr;

  chunk = arena->tail;
  aligned_used = chunk ? ((chunk->used + sizeof(void *) - 1) & ~(sizeof(void *) - 1)) : 0;
  next_used = aligned_used + size;
  if (!chunk || next_used > chunk->cap) {
    chunk_cap = 4096;
    while (chunk_cap < size) {
      chunk_cap *= 2;
    }
    Newxz(chunk, 1, gql_ir_arena_chunk_t);
    Newx(chunk->buf, chunk_cap, char);
    chunk->cap = chunk_cap;
    if (arena->tail) {
      arena->tail->next = chunk;
    } else {
      arena->head = chunk;
    }
    arena->tail = chunk;
    aligned_used = 0;
    next_used = size;
  }
  ptr = chunk->buf + aligned_used;
  Zero(ptr, size, char);
  chunk->used = next_used;
  return ptr;
}

static void
gql_ir_arena_free(gql_ir_arena_t *arena) {
  gql_ir_arena_chunk_t *chunk = arena->head;

  while (chunk) {
    gql_ir_arena_chunk_t *next = chunk->next;
    if (chunk->buf) {
      Safefree(chunk->buf);
    }
    Safefree(chunk);
    chunk = next;
  }
  arena->head = NULL;
  arena->tail = NULL;
}

static void
gql_ir_ptr_array_push(gql_ir_ptr_array_t *array, void *item) {
  if (array->count == array->cap) {
    I32 next_cap = array->cap ? array->cap * 2 : 4;
    Renew(array->items, next_cap, void *);
    array->cap = next_cap;
  }
  array->items[array->count++] = item;
}

static void
gql_ir_ptr_array_free(gql_ir_ptr_array_t *array) {
  if (array->items) {
    Safefree(array->items);
  }
  array->items = NULL;
  array->count = 0;
  array->cap = 0;
}

static gql_ir_type_t *
gql_ir_parse_type_reference(pTHX_ gql_parser_t *p) {
  gql_ir_type_t *type;
  UV start_pos = (UV)p->tok_start;

  type = (gql_ir_type_t *)gql_ir_arena_alloc_zero(p->ir_arena, sizeof(gql_ir_type_t));
  type->start_pos = start_pos;
  if (p->kind == TOK_LBRACKET) {
    type->kind = GQL_IR_TYPE_LIST;
    gql_advance(aTHX_ p);
    type->inner = gql_ir_parse_type_reference(aTHX_ p);
    gql_expect(aTHX_ p, TOK_RBRACKET, NULL);
  } else {
    type->kind = GQL_IR_TYPE_NAMED;
    type->name = gql_ir_parse_name_span(aTHX_ p, "Expected name");
  }

  if (p->kind == TOK_BANG) {
    gql_ir_type_t *wrapped;
    gql_advance(aTHX_ p);
    wrapped = (gql_ir_type_t *)gql_ir_arena_alloc_zero(p->ir_arena, sizeof(gql_ir_type_t));
    wrapped->kind = GQL_IR_TYPE_NON_NULL;
    wrapped->start_pos = type->start_pos;
    wrapped->inner = type;
    type = wrapped;
  }

  return type;
}

static gql_ir_value_t *
gql_ir_parse_value(pTHX_ gql_parser_t *p, int is_const) {
  gql_ir_value_t *value;
  UV start_pos = (UV)p->tok_start;

  value = (gql_ir_value_t *)gql_ir_arena_alloc_zero(p->ir_arena, sizeof(gql_ir_value_t));
  value->start_pos = start_pos;
  switch (p->kind) {
    case TOK_DOLLAR:
      if (is_const) {
        gql_throw(aTHX_ p, p->tok_start, "Expected name or constant");
      }
      value->kind = GQL_IR_VALUE_VARIABLE;
      gql_advance(aTHX_ p);
      value->name_pos = (UV)p->tok_start;
      value->as.span = gql_ir_parse_name_span(aTHX_ p, "Expected name");
      return value;
    case TOK_INT:
      value->kind = GQL_IR_VALUE_INT;
      value->as.span.start = (UV)p->tok_start;
      value->as.span.end = (UV)p->tok_end;
      gql_advance(aTHX_ p);
      return value;
    case TOK_FLOAT:
      value->kind = GQL_IR_VALUE_FLOAT;
      value->as.span.start = (UV)p->tok_start;
      value->as.span.end = (UV)p->tok_end;
      gql_advance(aTHX_ p);
      return value;
    case TOK_STRING:
    case TOK_BLOCK_STRING:
      value->kind = GQL_IR_VALUE_STRING;
      value->is_block_string = p->kind == TOK_BLOCK_STRING ? 1 : 0;
      value->as.span.start = (UV)p->val_start;
      value->as.span.end = (UV)p->val_end;
      gql_advance(aTHX_ p);
      return value;
    case TOK_NAME:
      if (gql_peek_name(p, "true")) {
        value->kind = GQL_IR_VALUE_BOOL;
        value->as.boolean = 1;
        gql_advance(aTHX_ p);
        return value;
      }
      if (gql_peek_name(p, "false")) {
        value->kind = GQL_IR_VALUE_BOOL;
        value->as.boolean = 0;
        gql_advance(aTHX_ p);
        return value;
      }
      if (gql_peek_name(p, "null")) {
        value->kind = GQL_IR_VALUE_NULL;
        gql_advance(aTHX_ p);
        return value;
      }
      value->kind = GQL_IR_VALUE_ENUM;
      value->as.span.start = (UV)p->tok_start;
      value->as.span.end = (UV)p->tok_end;
      gql_advance(aTHX_ p);
      return value;
    case TOK_LBRACKET:
      value->kind = GQL_IR_VALUE_LIST;
      gql_expect(aTHX_ p, TOK_LBRACKET, NULL);
      while (p->kind != TOK_RBRACKET) {
        gql_ir_ptr_array_push(&value->as.list_items, gql_ir_parse_value(aTHX_ p, is_const));
      }
      gql_expect(aTHX_ p, TOK_RBRACKET, NULL);
      return value;
    case TOK_LBRACE:
      value->kind = GQL_IR_VALUE_OBJECT;
      gql_expect(aTHX_ p, TOK_LBRACE, "Expected name");
      while (p->kind != TOK_RBRACE) {
        gql_ir_object_field_t *field;
        field = (gql_ir_object_field_t *)gql_ir_arena_alloc_zero(p->ir_arena, sizeof(gql_ir_object_field_t));
        field->start_pos = (UV)p->tok_start;
        field->name = gql_ir_parse_name_span(aTHX_ p, "Expected name");
        gql_expect(aTHX_ p, TOK_COLON, NULL);
        field->value = gql_ir_parse_value(aTHX_ p, is_const);
        gql_ir_ptr_array_push(&value->as.object_fields, field);
      }
      gql_expect(aTHX_ p, TOK_RBRACE, NULL);
      return value;
    default:
      gql_throw(aTHX_ p, p->tok_start, is_const ? "Expected name or constant" : "Expected value");
  }
  return NULL;
}

static gql_ir_ptr_array_t
gql_ir_parse_arguments(pTHX_ gql_parser_t *p, int is_const) {
  gql_ir_ptr_array_t arguments = { 0, 0, NULL };

  gql_expect(aTHX_ p, TOK_LPAREN, NULL);
  if (p->kind == TOK_RPAREN) {
    gql_throw_expected_message(aTHX_ p, p->tok_start, "Expected name");
  }
  while (p->kind != TOK_RPAREN) {
    gql_ir_argument_t *argument;
    argument = (gql_ir_argument_t *)gql_ir_arena_alloc_zero(p->ir_arena, sizeof(gql_ir_argument_t));
    argument->start_pos = (UV)p->tok_start;
    argument->name = gql_ir_parse_name_span(aTHX_ p, "Expected name");
    gql_expect(aTHX_ p, TOK_COLON, NULL);
    argument->value = gql_ir_parse_value(aTHX_ p, is_const);
    gql_ir_ptr_array_push(&arguments, argument);
  }
  gql_expect(aTHX_ p, TOK_RPAREN, NULL);
  return arguments;
}

static gql_ir_ptr_array_t
gql_ir_parse_directives(pTHX_ gql_parser_t *p) {
  gql_ir_ptr_array_t directives = { 0, 0, NULL };

  while (p->kind == TOK_AT) {
    gql_ir_directive_t *directive;
    directive = (gql_ir_directive_t *)gql_ir_arena_alloc_zero(p->ir_arena, sizeof(gql_ir_directive_t));
    directive->start_pos = (UV)p->tok_start;
    gql_expect(aTHX_ p, TOK_AT, NULL);
    directive->name_pos = (UV)p->tok_start;
    directive->name = gql_ir_parse_name_span(aTHX_ p, "Expected name");
    if (p->kind == TOK_LPAREN) {
      directive->arguments = gql_ir_parse_arguments(aTHX_ p, 0);
    }
    gql_ir_ptr_array_push(&directives, directive);
  }

  return directives;
}

static gql_ir_selection_set_t *
gql_ir_parse_selection_set(pTHX_ gql_parser_t *p) {
  gql_ir_selection_set_t *selection_set;

  selection_set = (gql_ir_selection_set_t *)gql_ir_arena_alloc_zero(p->ir_arena, sizeof(gql_ir_selection_set_t));
  selection_set->start_pos = (UV)p->tok_start;
  gql_expect(aTHX_ p, TOK_LBRACE, "Expected name");
  if (p->kind == TOK_RBRACE) {
    gql_throw(aTHX_ p, p->tok_start, "Expected name");
  }
  while (p->kind != TOK_RBRACE) {
    gql_ir_ptr_array_push(&selection_set->selections, gql_ir_parse_selection(aTHX_ p));
  }
  gql_expect(aTHX_ p, TOK_RBRACE, NULL);
  return selection_set;
}

static gql_ir_selection_t *
gql_ir_parse_selection(pTHX_ gql_parser_t *p) {
  gql_ir_selection_t *selection;

  selection = (gql_ir_selection_t *)gql_ir_arena_alloc_zero(p->ir_arena, sizeof(gql_ir_selection_t));
  if (p->kind == TOK_SPREAD) {
    UV spread_start = (UV)p->tok_start;
    gql_advance(aTHX_ p);
    if (gql_peek_name(p, "on")) {
      gql_parser_t lookahead = *p;
      gql_ir_inline_fragment_t *fragment;
      gql_advance(aTHX_ &lookahead);
      if (lookahead.kind != TOK_NAME) {
        gql_throw(aTHX_ p, p->tok_start, "Unexpected Name \"on\"");
      }
      selection->kind = GQL_IR_SELECTION_INLINE_FRAGMENT;
      fragment = (gql_ir_inline_fragment_t *)gql_ir_arena_alloc_zero(p->ir_arena, sizeof(gql_ir_inline_fragment_t));
      fragment->start_pos = spread_start;
      gql_advance(aTHX_ p);
      fragment->type_condition_pos = (UV)p->tok_start;
      fragment->type_condition = gql_ir_parse_name_span(aTHX_ p, "Expected name");
      if (p->kind == TOK_AT) {
        fragment->directives = gql_ir_parse_directives(aTHX_ p);
      }
      fragment->selection_set = gql_ir_parse_selection_set(aTHX_ p);
      selection->as.inline_fragment = fragment;
      return selection;
    }
    if (p->kind == TOK_LBRACE || p->kind == TOK_AT) {
      gql_ir_inline_fragment_t *fragment;
      selection->kind = GQL_IR_SELECTION_INLINE_FRAGMENT;
      fragment = (gql_ir_inline_fragment_t *)gql_ir_arena_alloc_zero(p->ir_arena, sizeof(gql_ir_inline_fragment_t));
      fragment->start_pos = spread_start;
      if (p->kind == TOK_AT) {
        fragment->directives = gql_ir_parse_directives(aTHX_ p);
      }
      fragment->selection_set = gql_ir_parse_selection_set(aTHX_ p);
      selection->as.inline_fragment = fragment;
      return selection;
    }
    {
      gql_ir_fragment_spread_t *spread;
      selection->kind = GQL_IR_SELECTION_FRAGMENT_SPREAD;
      spread = (gql_ir_fragment_spread_t *)gql_ir_arena_alloc_zero(p->ir_arena, sizeof(gql_ir_fragment_spread_t));
      spread->start_pos = spread_start;
      spread->name_pos = (UV)p->tok_start;
      spread->name = gql_ir_parse_fragment_name_span(aTHX_ p);
      if (p->kind == TOK_AT) {
        spread->directives = gql_ir_parse_directives(aTHX_ p);
      }
      selection->as.fragment_spread = spread;
      return selection;
    }
  }

  {
    gql_ir_field_t *field;
    gql_ir_span_t first_name;
    selection->kind = GQL_IR_SELECTION_FIELD;
    field = (gql_ir_field_t *)gql_ir_arena_alloc_zero(p->ir_arena, sizeof(gql_ir_field_t));
    field->start_pos = (UV)p->tok_start;
    field->name_pos = (UV)p->tok_start;
    first_name = gql_ir_parse_name_span(aTHX_ p, "Expected name");
    if (p->kind == TOK_COLON) {
      field->alias_pos = field->name_pos;
      field->alias = first_name;
      gql_advance(aTHX_ p);
      field->name_pos = (UV)p->tok_start;
      field->name = gql_ir_parse_name_span(aTHX_ p, "Expected name");
    } else {
      field->name = first_name;
    }
    if (p->kind == TOK_LPAREN) {
      field->arguments = gql_ir_parse_arguments(aTHX_ p, 0);
    }
    if (p->kind == TOK_AT) {
      field->directives = gql_ir_parse_directives(aTHX_ p);
    }
    if (p->kind == TOK_LBRACE) {
      field->selection_set = gql_ir_parse_selection_set(aTHX_ p);
    }
    selection->as.field = field;
    return selection;
  }
}

static void
gql_ir_free_type(gql_ir_type_t *type) {
  if (!type) {
    return;
  }
  gql_ir_free_type(type->inner);
}

static void
gql_ir_free_argument(gql_ir_argument_t *argument) {
  if (!argument) {
    return;
  }
  gql_ir_free_value(argument->value);
}

static void
gql_ir_free_object_field(gql_ir_object_field_t *field) {
  if (!field) {
    return;
  }
  gql_ir_free_value(field->value);
}

static void
gql_ir_free_value(gql_ir_value_t *value) {
  I32 i;

  if (!value) {
    return;
  }
  switch (value->kind) {
    case GQL_IR_VALUE_LIST:
      for (i = 0; i < value->as.list_items.count; i++) {
        gql_ir_free_value((gql_ir_value_t *)value->as.list_items.items[i]);
      }
      gql_ir_ptr_array_free(&value->as.list_items);
      break;
    case GQL_IR_VALUE_OBJECT:
      for (i = 0; i < value->as.object_fields.count; i++) {
        gql_ir_free_object_field((gql_ir_object_field_t *)value->as.object_fields.items[i]);
      }
      gql_ir_ptr_array_free(&value->as.object_fields);
      break;
    default:
      break;
  }
}

static void
gql_ir_free_directive(gql_ir_directive_t *directive) {
  I32 i;

  if (!directive) {
    return;
  }
  for (i = 0; i < directive->arguments.count; i++) {
    gql_ir_free_argument((gql_ir_argument_t *)directive->arguments.items[i]);
  }
  gql_ir_ptr_array_free(&directive->arguments);
}

static void
gql_ir_free_variable_definition(gql_ir_variable_definition_t *definition) {
  I32 i;

  if (!definition) {
    return;
  }
  gql_ir_free_type(definition->type);
  gql_ir_free_value(definition->default_value);
  for (i = 0; i < definition->directives.count; i++) {
    gql_ir_free_directive((gql_ir_directive_t *)definition->directives.items[i]);
  }
  gql_ir_ptr_array_free(&definition->directives);
}

static void
gql_ir_free_selection_set(gql_ir_selection_set_t *selection_set) {
  I32 i;

  if (!selection_set) {
    return;
  }
  for (i = 0; i < selection_set->selections.count; i++) {
    gql_ir_free_selection((gql_ir_selection_t *)selection_set->selections.items[i]);
  }
  gql_ir_ptr_array_free(&selection_set->selections);
}

static void
gql_ir_free_selection(gql_ir_selection_t *selection) {
  if (!selection) {
    return;
  }
  switch (selection->kind) {
    case GQL_IR_SELECTION_FIELD:
      if (selection->as.field) {
        gql_ir_field_t *field = selection->as.field;
        I32 i;
        for (i = 0; i < field->arguments.count; i++) {
          gql_ir_free_argument((gql_ir_argument_t *)field->arguments.items[i]);
        }
        gql_ir_ptr_array_free(&field->arguments);
        for (i = 0; i < field->directives.count; i++) {
          gql_ir_free_directive((gql_ir_directive_t *)field->directives.items[i]);
        }
        gql_ir_ptr_array_free(&field->directives);
        gql_ir_free_selection_set(field->selection_set);
      }
      break;
    case GQL_IR_SELECTION_FRAGMENT_SPREAD:
      if (selection->as.fragment_spread) {
        gql_ir_fragment_spread_t *spread = selection->as.fragment_spread;
        I32 i;
        for (i = 0; i < spread->directives.count; i++) {
          gql_ir_free_directive((gql_ir_directive_t *)spread->directives.items[i]);
        }
        gql_ir_ptr_array_free(&spread->directives);
      }
      break;
    case GQL_IR_SELECTION_INLINE_FRAGMENT:
      if (selection->as.inline_fragment) {
        gql_ir_inline_fragment_t *fragment = selection->as.inline_fragment;
        I32 i;
        for (i = 0; i < fragment->directives.count; i++) {
          gql_ir_free_directive((gql_ir_directive_t *)fragment->directives.items[i]);
        }
        gql_ir_ptr_array_free(&fragment->directives);
        gql_ir_free_selection_set(fragment->selection_set);
      }
      break;
  }
}

static void
gql_ir_free_operation_definition(gql_ir_operation_definition_t *definition) {
  I32 i;

  if (!definition) {
    return;
  }
  for (i = 0; i < definition->variable_definitions.count; i++) {
    gql_ir_free_variable_definition((gql_ir_variable_definition_t *)definition->variable_definitions.items[i]);
  }
  gql_ir_ptr_array_free(&definition->variable_definitions);
  for (i = 0; i < definition->directives.count; i++) {
    gql_ir_free_directive((gql_ir_directive_t *)definition->directives.items[i]);
  }
  gql_ir_ptr_array_free(&definition->directives);
  gql_ir_free_selection_set(definition->selection_set);
}

static void
gql_ir_free_fragment_definition(gql_ir_fragment_definition_t *definition) {
  I32 i;

  if (!definition) {
    return;
  }
  for (i = 0; i < definition->directives.count; i++) {
    gql_ir_free_directive((gql_ir_directive_t *)definition->directives.items[i]);
  }
  gql_ir_ptr_array_free(&definition->directives);
  gql_ir_free_selection_set(definition->selection_set);
}

static void
gql_ir_free_definition(gql_ir_definition_t *definition) {
  if (!definition) {
    return;
  }
  if (definition->kind == GQL_IR_DEFINITION_OPERATION) {
    gql_ir_free_operation_definition(definition->as.operation);
  } else {
    gql_ir_free_fragment_definition(definition->as.fragment);
  }
}

static void
gql_ir_free_document(gql_ir_document_t *document) {
  I32 i;

  if (!document) {
    return;
  }
  for (i = 0; i < document->definitions.count; i++) {
    gql_ir_free_definition((gql_ir_definition_t *)document->definitions.items[i]);
  }
  gql_ir_ptr_array_free(&document->definitions);
  gql_ir_arena_free(&document->arena);
  Safefree(document);
}

static SV *
gql_ir_make_sv_from_span(pTHX_ gql_ir_document_t *document, gql_ir_span_t span) {
  SV *sv;

  if (!document || span.end < span.start) {
    return newSVpvn("", 0);
  }
  sv = newSVpvn(document->src + span.start, span.end - span.start);
  if (document->is_utf8) {
    SvUTF8_on(sv);
  }
  return sv;
}

static SV *
gql_ir_make_string_value_sv(pTHX_ gql_ir_document_t *document, gql_ir_value_t *value) {
  SV *raw;
  SV *ret;

  raw = gql_ir_make_sv_from_span(aTHX_ document, value->as.span);
  if (value->is_block_string) {
    ret = gql_call_helper1(aTHX_ "GraphQL::Houtou::Parser::Internal::_block_string_value", raw);
  } else {
    ret = gql_unescape_string_sv(aTHX_ raw);
  }
  SvREFCNT_dec(raw);
  return ret;
}

static SV *
gql_parser_build_type_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_type_t *type) {
  HV *hv;
  SV *node_sv;
  SV *name_sv;

  if (!type) {
    return &PL_sv_undef;
  }
  if (type->kind == GQL_IR_TYPE_NAMED) {
    SV *type_name_sv = gql_ir_make_sv_from_span(aTHX_ document, type->name);
    node_sv = gql_parser_new_named_type_node_sv(aTHX_ type_name_sv);
    SvREFCNT_dec(type_name_sv);
    if (ctx) {
      if (ctx->compact_location) {
        gql_parser_set_rewritten_loc_node(aTHX_ ctx, node_sv, type->start_pos);
      } else {
        name_sv = gql_parser_fetch_sv(gql_parser_node_hv(node_sv), "name");
        gql_parser_set_shared_rewritten_loc_nodes(aTHX_ ctx, type->start_pos, node_sv, name_sv);
      }
    }
    return node_sv;
  }

  hv = gql_parser_new_node_hv_sized(type->kind == GQL_IR_TYPE_LIST ? "ListType" : "NonNullType", 2);
  node_sv = gql_parser_build_type_from_ir(aTHX_ ctx, document, type->inner);
  hv_stores(hv, "type", node_sv);
  node_sv = newRV_noinc((SV *)hv);
  if (ctx) {
    gql_parser_set_rewritten_loc_node(aTHX_ ctx, node_sv, type->start_pos);
  }
  return node_sv;
}

static AV *
gql_parser_build_object_fields_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_ptr_array_t *fields, SV *state_sv) {
  AV *av = newAV();
  I32 i;

  if (!fields) {
    return av;
  }
  if (fields->count > 0) {
    av_extend(av, fields->count - 1);
  }
  for (i = 0; i < fields->count; i++) {
    gql_ir_object_field_t *field = (gql_ir_object_field_t *)fields->items[i];
    HV *field_hv = gql_parser_new_node_hv_sized("ObjectField", 3);
    SV *field_sv;
    SV *field_name_value_sv = gql_ir_make_sv_from_span(aTHX_ document, field->name);
    SV *field_name_sv = gql_parser_new_name_node_sv(aTHX_ field_name_value_sv);
    SvREFCNT_dec(field_name_value_sv);
    hv_stores(field_hv, "name", field_name_sv);
    hv_stores(field_hv, "value", gql_parser_build_value_from_ir(aTHX_ ctx, document, field->value, state_sv));
    field_sv = newRV_noinc((SV *)field_hv);
    if (ctx) {
      if (ctx->compact_location) {
        gql_parser_set_rewritten_loc_node(aTHX_ ctx, field_sv, field->start_pos);
      } else {
        gql_parser_set_shared_rewritten_loc_nodes(aTHX_ ctx, field->start_pos, field_sv, field_name_sv);
      }
    }
    av_push(av, field_sv);
  }

  return av;
}

static SV *
gql_parser_build_value_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_value_t *value, SV *state_sv) {
  HV *hv;
  I32 i;
  SV *node_sv = &PL_sv_undef;
  SV *name_sv;

  if (!value) {
    return &PL_sv_undef;
  }
  switch (value->kind) {
    case GQL_IR_VALUE_NULL:
      node_sv = gql_parser_new_node_ref("NullValue");
      break;
    case GQL_IR_VALUE_BOOL:
      hv = gql_parser_new_node_hv_sized("BooleanValue", 2);
      hv_stores(hv, "value", newSViv(value->as.boolean ? 1 : 0));
      node_sv = newRV_noinc((SV *)hv);
      break;
    case GQL_IR_VALUE_INT:
      hv = gql_parser_new_node_hv_sized("IntValue", 2);
      hv_stores(hv, "value", gql_ir_make_sv_from_span(aTHX_ document, value->as.span));
      node_sv = newRV_noinc((SV *)hv);
      break;
    case GQL_IR_VALUE_FLOAT:
      hv = gql_parser_new_node_hv_sized("FloatValue", 2);
      hv_stores(hv, "value", gql_ir_make_sv_from_span(aTHX_ document, value->as.span));
      node_sv = newRV_noinc((SV *)hv);
      break;
    case GQL_IR_VALUE_STRING:
      hv = gql_parser_new_node_hv_sized("StringValue", 2);
      hv_stores(hv, "value", gql_ir_make_string_value_sv(aTHX_ document, value));
      node_sv = newRV_noinc((SV *)hv);
      break;
    case GQL_IR_VALUE_ENUM:
      hv = gql_parser_new_node_hv_sized("EnumValue", 2);
      hv_stores(hv, "value", gql_ir_make_sv_from_span(aTHX_ document, value->as.span));
      node_sv = newRV_noinc((SV *)hv);
      break;
    case GQL_IR_VALUE_VARIABLE:
      {
        SV *var_name_sv = gql_ir_make_sv_from_span(aTHX_ document, value->as.span);
        node_sv = gql_parser_new_variable_node_sv(aTHX_ var_name_sv);
        SvREFCNT_dec(var_name_sv);
      }
      if (ctx) {
        gql_parser_set_rewritten_loc_node(aTHX_ ctx, node_sv, value->start_pos);
        if (!ctx->compact_location) {
          name_sv = gql_parser_fetch_sv(gql_parser_node_hv(node_sv), "name");
          gql_parser_set_rewritten_loc_node(aTHX_ ctx, name_sv, value->name_pos);
        }
      }
      return node_sv;
    case GQL_IR_VALUE_LIST: {
      AV *items = newAV();
      hv = gql_parser_new_node_hv_sized("ListValue", 2);
      if (value->as.list_items.count > 0) {
        av_extend(items, value->as.list_items.count - 1);
      }
      for (i = 0; i < value->as.list_items.count; i++) {
        av_push(items, gql_parser_build_value_from_ir(aTHX_ ctx, document, (gql_ir_value_t *)value->as.list_items.items[i], state_sv));
      }
      hv_stores(hv, "values", newRV_noinc((SV *)items));
      node_sv = newRV_noinc((SV *)hv);
      break;
    }
    case GQL_IR_VALUE_OBJECT: {
      hv = gql_parser_new_node_hv_sized("ObjectValue", 2);
      if (value->as.object_fields.count > 0 && state_sv) {
        hv_stores(hv, "fields", gql_parser_new_lazy_object_fields_sv(aTHX_ state_sv, &value->as.object_fields));
      } else {
        hv_stores(hv, "fields", newRV_noinc((SV *)gql_parser_build_object_fields_from_ir(
          aTHX_ ctx,
          document,
          &value->as.object_fields,
          state_sv
        )));
      }
      node_sv = newRV_noinc((SV *)hv);
      break;
    }
  }

  if (ctx && node_sv && node_sv != &PL_sv_undef) {
    gql_parser_set_rewritten_loc_node(aTHX_ ctx, node_sv, value->start_pos);
  }
  return node_sv;
}

static AV *
gql_parser_build_arguments_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_ptr_array_t *arguments, SV *state_sv) {
  AV *av = newAV();
  I32 i;

  if (!arguments) {
    return av;
  }
  if (arguments->count > 0) {
    av_extend(av, arguments->count - 1);
  }
  for (i = 0; i < arguments->count; i++) {
    gql_ir_argument_t *argument = (gql_ir_argument_t *)arguments->items[i];
    HV *arg_hv = gql_parser_new_node_hv_sized("Argument", 3);
    SV *arg_sv;
    SV *name_value_sv = gql_ir_make_sv_from_span(aTHX_ document, argument->name);
    SV *name_sv = gql_parser_new_name_node_sv(aTHX_ name_value_sv);
    SvREFCNT_dec(name_value_sv);
    hv_stores(arg_hv, "name", name_sv);
    hv_stores(arg_hv, "value", gql_parser_build_value_from_ir(aTHX_ ctx, document, argument->value, state_sv));
    arg_sv = newRV_noinc((SV *)arg_hv);
    if (ctx) {
      if (ctx->compact_location) {
        gql_parser_set_rewritten_loc_node(aTHX_ ctx, arg_sv, argument->start_pos);
      } else {
        gql_parser_set_shared_rewritten_loc_nodes(aTHX_ ctx, argument->start_pos, arg_sv, name_sv);
      }
    }
    av_push(av, arg_sv);
  }
  return av;
}

static AV *
gql_parser_build_directives_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_ptr_array_t *directives, SV *state_sv) {
  AV *av = newAV();
  I32 i;

  if (!directives) {
    return av;
  }
  if (directives->count > 0) {
    av_extend(av, directives->count - 1);
  }
  for (i = 0; i < directives->count; i++) {
    gql_ir_directive_t *directive = (gql_ir_directive_t *)directives->items[i];
    HV *dir_hv = gql_parser_new_node_hv_sized("Directive", 3);
    SV *dir_sv;
    SV *name_value_sv = gql_ir_make_sv_from_span(aTHX_ document, directive->name);
    SV *name_sv = gql_parser_new_name_node_sv(aTHX_ name_value_sv);
    SvREFCNT_dec(name_value_sv);
    hv_stores(dir_hv, "name", name_sv);
    if (state_sv && directive->arguments.count > 0) {
      hv_stores(dir_hv, "arguments", gql_parser_new_lazy_arguments_sv(aTHX_ state_sv, &directive->arguments));
    } else {
      hv_stores(dir_hv, "arguments", newRV_noinc((SV *)gql_parser_build_arguments_from_ir(aTHX_ ctx, document, &directive->arguments, state_sv)));
    }
    dir_sv = newRV_noinc((SV *)dir_hv);
    if (ctx) {
      gql_parser_set_rewritten_loc_node(aTHX_ ctx, dir_sv, directive->start_pos);
      if (!ctx->compact_location) {
        gql_parser_set_rewritten_loc_node(aTHX_ ctx, name_sv, directive->name_pos);
      }
    }
    av_push(av, dir_sv);
  }
  return av;
}

static SV *
gql_parser_build_selection_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_selection_t *selection, SV *state_sv) {
  HV *hv;
  SV *node_sv;

  if (!selection) {
    return &PL_sv_undef;
  }
  switch (selection->kind) {
    case GQL_IR_SELECTION_FIELD: {
      gql_ir_field_t *field = selection->as.field;
      hv = gql_parser_new_node_hv_sized("Field", 6);
      if (field->alias.start != field->alias.end) {
        SV *alias_value_sv = gql_ir_make_sv_from_span(aTHX_ document, field->alias);
        SV *alias_sv = gql_parser_new_name_node_sv(aTHX_ alias_value_sv);
        SvREFCNT_dec(alias_value_sv);
        hv_stores(hv, "alias", alias_sv);
        if (ctx && !ctx->compact_location) {
          gql_parser_set_rewritten_loc_node(aTHX_ ctx, alias_sv, field->alias_pos);
        }
      }
      {
        SV *name_value_sv = gql_ir_make_sv_from_span(aTHX_ document, field->name);
        SV *name_sv = gql_parser_new_name_node_sv(aTHX_ name_value_sv);
        SvREFCNT_dec(name_value_sv);
        hv_stores(hv, "name", name_sv);
        if (ctx && !ctx->compact_location) {
          if (field->alias.start != field->alias.end || field->start_pos != field->name_pos) {
            gql_parser_set_rewritten_loc_node(aTHX_ ctx, name_sv, field->name_pos);
          }
        }
      }
      if (state_sv && field->arguments.count > 0) {
        hv_stores(hv, "arguments", gql_parser_new_lazy_arguments_sv(aTHX_ state_sv, &field->arguments));
      } else {
        hv_stores(hv, "arguments", newRV_noinc((SV *)gql_parser_build_arguments_from_ir(aTHX_ ctx, document, &field->arguments, state_sv)));
      }
      if (state_sv && field->directives.count > 0) {
        hv_stores(hv, "directives", gql_parser_new_lazy_directives_sv(aTHX_ state_sv, &field->directives));
      } else {
        hv_stores(hv, "directives", newRV_noinc((SV *)gql_parser_build_directives_from_ir(aTHX_ ctx, document, &field->directives, state_sv)));
      }
      if (field->selection_set) {
        hv_stores(hv, "selectionSet", gql_parser_build_selection_set_from_ir(aTHX_ ctx, document, field->selection_set, state_sv));
      }
      node_sv = newRV_noinc((SV *)hv);
      if (ctx) {
        if (!ctx->compact_location && field->alias.start == field->alias.end && field->start_pos == field->name_pos) {
          SV *name_sv = gql_parser_fetch_sv(hv, "name");
          gql_parser_set_shared_rewritten_loc_nodes(aTHX_ ctx, field->start_pos, node_sv, name_sv);
        } else {
          gql_parser_set_rewritten_loc_node(aTHX_ ctx, node_sv, field->start_pos);
        }
      }
      return node_sv;
    }
    case GQL_IR_SELECTION_FRAGMENT_SPREAD: {
      gql_ir_fragment_spread_t *spread = selection->as.fragment_spread;
      hv = gql_parser_new_node_hv_sized("FragmentSpread", 3);
      {
        SV *name_value_sv = gql_ir_make_sv_from_span(aTHX_ document, spread->name);
        SV *name_sv = gql_parser_new_name_node_sv(aTHX_ name_value_sv);
        SvREFCNT_dec(name_value_sv);
        hv_stores(hv, "name", name_sv);
        if (ctx && !ctx->compact_location) {
          gql_parser_set_rewritten_loc_node(aTHX_ ctx, name_sv, spread->name_pos);
        }
      }
      if (state_sv && spread->directives.count > 0) {
        hv_stores(hv, "directives", gql_parser_new_lazy_directives_sv(aTHX_ state_sv, &spread->directives));
      } else {
        hv_stores(hv, "directives", newRV_noinc((SV *)gql_parser_build_directives_from_ir(aTHX_ ctx, document, &spread->directives, state_sv)));
      }
      node_sv = newRV_noinc((SV *)hv);
      if (ctx) {
        gql_parser_set_rewritten_loc_node(aTHX_ ctx, node_sv, spread->start_pos);
      }
      return node_sv;
    }
    case GQL_IR_SELECTION_INLINE_FRAGMENT: {
      gql_ir_inline_fragment_t *fragment = selection->as.inline_fragment;
      hv = gql_parser_new_node_hv_sized("InlineFragment", 4);
      if (fragment->type_condition.start != fragment->type_condition.end) {
        SV *type_name_sv = gql_ir_make_sv_from_span(aTHX_ document, fragment->type_condition);
        SV *type_sv = gql_parser_new_named_type_node_sv(aTHX_ type_name_sv);
        SvREFCNT_dec(type_name_sv);
        hv_stores(hv, "typeCondition", type_sv);
        if (ctx) {
          if (ctx->compact_location) {
            gql_parser_set_rewritten_loc_node(aTHX_ ctx, type_sv, fragment->type_condition_pos);
          } else {
            SV *type_name_sv = gql_parser_fetch_sv(gql_parser_node_hv(type_sv), "name");
            gql_parser_set_shared_rewritten_loc_nodes(aTHX_ ctx, fragment->type_condition_pos, type_sv, type_name_sv);
          }
        }
      }
      if (state_sv && fragment->directives.count > 0) {
        hv_stores(hv, "directives", gql_parser_new_lazy_directives_sv(aTHX_ state_sv, &fragment->directives));
      } else {
        hv_stores(hv, "directives", newRV_noinc((SV *)gql_parser_build_directives_from_ir(aTHX_ ctx, document, &fragment->directives, state_sv)));
      }
      hv_stores(hv, "selectionSet", gql_parser_build_selection_set_from_ir(aTHX_ ctx, document, fragment->selection_set, state_sv));
      node_sv = newRV_noinc((SV *)hv);
      if (ctx) {
        gql_parser_set_rewritten_loc_node(aTHX_ ctx, node_sv, fragment->start_pos);
      }
      return node_sv;
    }
  }

  return &PL_sv_undef;
}

static SV *
gql_parser_build_selection_set_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_selection_set_t *selection_set, SV *state_sv) {
  HV *hv = gql_parser_new_node_hv_sized("SelectionSet", 2);
  AV *selections = newAV();
  I32 i;
  SV *node_sv;

  if (selection_set && selection_set->selections.count > 0) {
    av_extend(selections, selection_set->selections.count - 1);
  }
  for (i = 0; selection_set && i < selection_set->selections.count; i++) {
    av_push(selections, gql_parser_build_selection_from_ir(aTHX_ ctx, document, (gql_ir_selection_t *)selection_set->selections.items[i], state_sv));
  }
  hv_stores(hv, "selections", newRV_noinc((SV *)selections));
  node_sv = newRV_noinc((SV *)hv);
  if (ctx && selection_set) {
    gql_parser_set_rewritten_loc_node(aTHX_ ctx, node_sv, selection_set->start_pos);
  }
  return node_sv;
}

static AV *
gql_parser_build_variable_definitions_from_ir(pTHX_ gql_parser_loc_context_t *ctx, gql_ir_document_t *document, gql_ir_ptr_array_t *definitions, SV *state_sv) {
  AV *av = newAV();
  I32 i;

  if (!definitions) {
    return av;
  }
  if (definitions->count > 0) {
    av_extend(av, definitions->count - 1);
  }
  for (i = 0; i < definitions->count; i++) {
    gql_ir_variable_definition_t *definition = (gql_ir_variable_definition_t *)definitions->items[i];
    HV *def_hv = gql_parser_new_node_hv_sized("VariableDefinition", 5);
    SV *def_sv;
    SV *variable_name_value_sv = gql_ir_make_sv_from_span(aTHX_ document, definition->name);
    SV *variable_sv = gql_parser_new_variable_node_sv(aTHX_ variable_name_value_sv);
    SvREFCNT_dec(variable_name_value_sv);
    hv_stores(def_hv, "variable", variable_sv);
    hv_stores(def_hv, "type", gql_parser_build_type_from_ir(aTHX_ ctx, document, definition->type));
    if (definition->default_value) {
      hv_stores(def_hv, "defaultValue", gql_parser_build_value_from_ir(aTHX_ ctx, document, definition->default_value, state_sv));
    }
    if (state_sv && definition->directives.count > 0) {
      hv_stores(def_hv, "directives", gql_parser_new_lazy_directives_sv(aTHX_ state_sv, &definition->directives));
    } else {
      hv_stores(def_hv, "directives", newRV_noinc((SV *)gql_parser_build_directives_from_ir(aTHX_ ctx, document, &definition->directives, state_sv)));
    }
    def_sv = newRV_noinc((SV *)def_hv);
    if (ctx) {
      SV *variable_name_sv = gql_parser_fetch_sv(gql_parser_node_hv(variable_sv), "name");
      gql_parser_set_shared_rewritten_loc_nodes(aTHX_ ctx, definition->start_pos, def_sv, variable_sv);
      if (!ctx->compact_location) {
        gql_parser_set_rewritten_loc_node(aTHX_ ctx, variable_name_sv, definition->name_pos);
      }
    }
    av_push(av, def_sv);
  }
  return av;
}

static SV *
gqlperl_location_from_gql_parser_node(pTHX_ SV *node_sv) {
  HV *src_hv;
  HV *loc_hv;
  HV *dst_hv;
  SV *line_sv;
  SV *column_sv;
  SV *loc_sv;

  if (!node_sv || !SvROK(node_sv) || SvTYPE(SvRV(node_sv)) != SVt_PVHV) {
    return &PL_sv_undef;
  }
  src_hv = (HV *)SvRV(node_sv);
  loc_sv = gql_parser_fetch_sv(src_hv, "loc");
  if (!loc_sv || !SvROK(loc_sv) || SvTYPE(SvRV(loc_sv)) != SVt_PVHV) {
    return &PL_sv_undef;
  }

  loc_hv = (HV *)SvRV(loc_sv);
  line_sv = gql_parser_fetch_sv(loc_hv, "line");
  column_sv = gql_parser_fetch_sv(loc_hv, "column");
  if (!line_sv || !column_sv) {
    return &PL_sv_undef;
  }

  dst_hv = newHV();
  gql_store_sv(dst_hv, "line", newSViv(SvIV(line_sv)));
  gql_store_sv(dst_hv, "column", newSViv(SvIV(column_sv)));
  return newRV_noinc((SV *)dst_hv);
}

static void
gqlperl_store_location_from_gql_parser_node(pTHX_ HV *dst_hv, SV *node_sv) {
  SV *location_sv = gqlperl_location_from_gql_parser_node(aTHX_ node_sv);
  if (location_sv && location_sv != &PL_sv_undef) {
    gql_store_sv(dst_hv, "location", location_sv);
  }
}

static SV *
gqlperl_convert_type_from_gqljs(pTHX_ SV *node_sv) {
  HV *src_hv;
  const char *kind;

  if (!node_sv || !SvROK(node_sv) || SvTYPE(SvRV(node_sv)) != SVt_PVHV) {
    return &PL_sv_undef;
  }
  src_hv = (HV *)SvRV(node_sv);
  kind = gql_parser_fetch_kind(src_hv);

  if (strEQ(kind, "NamedType")) {
    return newSVpv(gql_parser_name_value(gql_parser_fetch_sv(src_hv, "name")), 0);
  }
  if (strEQ(kind, "ListType") || strEQ(kind, "NonNullType")) {
    AV *av = newAV();
    HV *inner_hv = newHV();
    av_push(av, newSVpv(strEQ(kind, "ListType") ? "list" : "non_null", 0));
    gql_store_sv(inner_hv, "type",
      gqlperl_convert_type_from_gqljs(aTHX_ gql_parser_fetch_sv(src_hv, "type")));
    av_push(av, newRV_noinc((SV *)inner_hv));
    return newRV_noinc((SV *)av);
  }

  croak("Unsupported parser type node '%s'.", kind);
}

static SV *
gqlperl_convert_value_from_gqljs(pTHX_ SV *node_sv) {
  HV *src_hv;
  const char *kind;
  SV *value_sv;

  if (!node_sv || !SvROK(node_sv) || SvTYPE(SvRV(node_sv)) != SVt_PVHV) {
    return &PL_sv_undef;
  }
  src_hv = (HV *)SvRV(node_sv);
  kind = gql_parser_fetch_kind(src_hv);

  if (strEQ(kind, "Variable")) {
    return newRV_noinc(newSVpv(gql_parser_name_value(gql_parser_fetch_sv(src_hv, "name")), 0));
  }
  if (strEQ(kind, "IntValue")) {
    value_sv = gql_parser_fetch_sv(src_hv, "value");
    return newSViv(SvIV(value_sv));
  }
  if (strEQ(kind, "FloatValue")) {
    value_sv = gql_parser_fetch_sv(src_hv, "value");
    return newSVnv(SvNV(value_sv));
  }
  if (strEQ(kind, "StringValue")) {
    value_sv = gql_parser_fetch_sv(src_hv, "value");
    return newSVsv(value_sv);
  }
  if (strEQ(kind, "BooleanValue")) {
    value_sv = gql_parser_fetch_sv(src_hv, "value");
    return gql_call_helper1(aTHX_ "GraphQL::Houtou::Parser::Internal::_make_bool",
      newSViv(SvTRUE(value_sv) ? 1 : 0));
  }
  if (strEQ(kind, "NullValue")) {
    return newSV(0);
  }
  if (strEQ(kind, "EnumValue")) {
    SV *enum_sv = newSVsv(gql_parser_fetch_sv(src_hv, "value"));
    SV *inner_ref = newRV_noinc(enum_sv);
    return newRV_noinc(inner_ref);
  }
  if (strEQ(kind, "ListValue")) {
    AV *src_av = gql_parser_fetch_array(src_hv, "values");
    AV *dst_av = newAV();
    I32 i;
    for (i = 0; src_av && i <= av_len(src_av); i++) {
      SV **svp = av_fetch(src_av, i, 0);
      if (svp) {
        av_push(dst_av, gqlperl_convert_value_from_gqljs(aTHX_ *svp));
      }
    }
    return newRV_noinc((SV *)dst_av);
  }
  if (strEQ(kind, "ObjectValue")) {
    AV *fields_av = gql_parser_fetch_array(src_hv, "fields");
    HV *dst_hv = newHV();
    I32 i;
    for (i = 0; fields_av && i <= av_len(fields_av); i++) {
      SV **svp = av_fetch(fields_av, i, 0);
      HV *field_hv;
      const char *name;
      if (!svp || !SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVHV) {
        continue;
      }
      field_hv = (HV *)SvRV(*svp);
      name = gql_parser_name_value(gql_parser_fetch_sv(field_hv, "name"));
      gql_store_sv(dst_hv, name,
        gqlperl_convert_value_from_gqljs(aTHX_ gql_parser_fetch_sv(field_hv, "value")));
    }
    return newRV_noinc((SV *)dst_hv);
  }

  croak("Unsupported parser value node '%s'.", kind);
}

static SV *
gqlperl_convert_arguments_from_gqljs(pTHX_ AV *av) {
  HV *dst_hv = newHV();
  I32 i;

  if (!av || av_len(av) < 0) {
    SvREFCNT_dec((SV *)dst_hv);
    return &PL_sv_undef;
  }

  for (i = 0; i <= av_len(av); i++) {
    SV **svp = av_fetch(av, i, 0);
    HV *arg_hv;
    const char *name;
    if (!svp || !SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVHV) {
      continue;
    }
    arg_hv = (HV *)SvRV(*svp);
    name = gql_parser_name_value(gql_parser_fetch_sv(arg_hv, "name"));
    gql_store_sv(dst_hv, name,
      gqlperl_convert_value_from_gqljs(aTHX_ gql_parser_fetch_sv(arg_hv, "value")));
  }

  return newRV_noinc((SV *)dst_hv);
}

static SV *
gqlperl_convert_directives_from_gqljs(pTHX_ AV *av) {
  AV *dst_av = newAV();
  I32 i;

  if (!av || av_len(av) < 0) {
    return newRV_noinc((SV *)dst_av);
  }

  for (i = 0; i <= av_len(av); i++) {
    SV **svp = av_fetch(av, i, 0);
    HV *src_hv;
    HV *dst_hv;
    SV *arguments_sv;
    if (!svp || !SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVHV) {
      continue;
    }
    src_hv = (HV *)SvRV(*svp);
    dst_hv = newHV();
    gql_store_sv(dst_hv, "name",
      newSVpv(gql_parser_name_value(gql_parser_fetch_sv(src_hv, "name")), 0));
    arguments_sv = gqlperl_convert_arguments_from_gqljs(aTHX_ gql_parser_fetch_array(src_hv, "arguments"));
    if (arguments_sv && arguments_sv != &PL_sv_undef) {
      gql_store_sv(dst_hv, "arguments", arguments_sv);
    }
    gqlperl_store_location_from_gql_parser_node(aTHX_ dst_hv, *svp);
    av_push(dst_av, newRV_noinc((SV *)dst_hv));
  }

  return newRV_noinc((SV *)dst_av);
}

static AV *
gqlperl_convert_selections_from_gqljs(pTHX_ AV *av) {
  AV *dst_av = newAV();
  I32 i;

  for (i = 0; av && i <= av_len(av); i++) {
    SV **svp = av_fetch(av, i, 0);
    if (svp) {
      av_push(dst_av, gqlperl_convert_selection_from_gqljs(aTHX_ *svp));
    }
  }

  return dst_av;
}

static SV *
gqlperl_convert_selection_from_gqljs(pTHX_ SV *node_sv) {
  HV *src_hv;
  HV *dst_hv;
  const char *kind;
  SV *arguments_sv;
  SV *directives_sv;
  AV *selection_av;

  if (!node_sv || !SvROK(node_sv) || SvTYPE(SvRV(node_sv)) != SVt_PVHV) {
    croak("Unsupported parser selection node");
  }
  src_hv = (HV *)SvRV(node_sv);
  kind = gql_parser_fetch_kind(src_hv);
  dst_hv = newHV();

  if (strEQ(kind, "Field")) {
    gql_store_sv(dst_hv, "kind", newSVpv("field", 0));
    gql_store_sv(dst_hv, "name", newSVpv(gql_parser_name_value(gql_parser_fetch_sv(src_hv, "name")), 0));
    if (gql_parser_fetch_sv(src_hv, "alias")) {
      gql_store_sv(dst_hv, "alias",
        newSVpv(gql_parser_name_value(gql_parser_fetch_sv(src_hv, "alias")), 0));
    }
    arguments_sv = gqlperl_convert_arguments_from_gqljs(aTHX_ gql_parser_fetch_array(src_hv, "arguments"));
    if (arguments_sv && arguments_sv != &PL_sv_undef) {
      gql_store_sv(dst_hv, "arguments", arguments_sv);
    }
    directives_sv = gqlperl_convert_directives_from_gqljs(aTHX_ gql_parser_fetch_array(src_hv, "directives"));
    if (directives_sv && SvROK(directives_sv) && av_len((AV *)SvRV(directives_sv)) >= 0) {
      gql_store_sv(dst_hv, "directives", directives_sv);
    } else if (directives_sv && directives_sv != &PL_sv_undef) {
      SvREFCNT_dec(directives_sv);
    }
    if (gql_parser_fetch_sv(src_hv, "selectionSet")) {
      selection_av = gqlperl_convert_selections_from_gqljs(aTHX_
        gql_parser_fetch_array((HV *)SvRV(gql_parser_fetch_sv(src_hv, "selectionSet")), "selections"));
      if (av_len(selection_av) >= 0) {
        gql_store_sv(dst_hv, "selections", newRV_noinc((SV *)selection_av));
      } else {
        SvREFCNT_dec((SV *)selection_av);
      }
    }
    gqlperl_store_location_from_gql_parser_node(aTHX_ dst_hv, node_sv);
    return newRV_noinc((SV *)dst_hv);
  }

  if (strEQ(kind, "FragmentSpread")) {
    gql_store_sv(dst_hv, "kind", newSVpv("fragment_spread", 0));
    gql_store_sv(dst_hv, "name", newSVpv(gql_parser_name_value(gql_parser_fetch_sv(src_hv, "name")), 0));
    directives_sv = gqlperl_convert_directives_from_gqljs(aTHX_ gql_parser_fetch_array(src_hv, "directives"));
    if (directives_sv && SvROK(directives_sv) && av_len((AV *)SvRV(directives_sv)) >= 0) {
      gql_store_sv(dst_hv, "directives", directives_sv);
    } else if (directives_sv && directives_sv != &PL_sv_undef) {
      SvREFCNT_dec(directives_sv);
    }
    gqlperl_store_location_from_gql_parser_node(aTHX_ dst_hv, node_sv);
    return newRV_noinc((SV *)dst_hv);
  }

  if (strEQ(kind, "InlineFragment")) {
    gql_store_sv(dst_hv, "kind", newSVpv("inline_fragment", 0));
    if (gql_parser_fetch_sv(src_hv, "typeCondition")) {
      gql_store_sv(dst_hv, "on",
        newSVpv(gql_parser_name_value(gql_parser_fetch_sv((HV *)SvRV(gql_parser_fetch_sv(src_hv, "typeCondition")), "name")), 0));
    }
    directives_sv = gqlperl_convert_directives_from_gqljs(aTHX_ gql_parser_fetch_array(src_hv, "directives"));
    if (directives_sv && SvROK(directives_sv) && av_len((AV *)SvRV(directives_sv)) >= 0) {
      gql_store_sv(dst_hv, "directives", directives_sv);
    } else if (directives_sv && directives_sv != &PL_sv_undef) {
      SvREFCNT_dec(directives_sv);
    }
    selection_av = gqlperl_convert_selections_from_gqljs(aTHX_
      gql_parser_fetch_array((HV *)SvRV(gql_parser_fetch_sv(src_hv, "selectionSet")), "selections"));
    gql_store_sv(dst_hv, "selections", newRV_noinc((SV *)selection_av));
    gqlperl_store_location_from_gql_parser_node(aTHX_ dst_hv, node_sv);
    return newRV_noinc((SV *)dst_hv);
  }

  SvREFCNT_dec((SV *)dst_hv);
  croak("Unsupported parser selection node '%s'.", kind);
}
