/*
 * Responsibility: compile graphql-perl schema/type/directive objects into
 * a normalized internal representation that future XS validation and
 * execution layers can consume directly.
 */

static const char *
gql_schema_class_name(SV *sv) {
  if (!sv || !SvROK(sv) || !SvOBJECT(SvRV(sv))) {
    return "";
  }
  return HvNAME(SvSTASH(SvRV(sv)));
}

static UV
gql_schema_refaddr(SV *sv) {
  if (!sv || !SvROK(sv)) {
    return 0;
  }
  return PTR2UV(SvRV(sv));
}

static SV *
gql_schema_call_method0(pTHX_ SV *invocant, const char *method) {
  dSP;
  int count;
  SV *ret;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVsv(invocant)));
  PUTBACK;
  count = call_method(method, G_SCALAR);
  SPAGAIN;
  if (count != 1) {
    PUTBACK;
    FREETMPS;
    LEAVE;
    croak("Method %s did not return a scalar", method);
  }
  ret = newSVsv(POPs);
  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

static SV *
gql_schema_call_method1(pTHX_ SV *invocant, const char *method, SV *arg) {
  dSP;
  int count;
  SV *ret;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVsv(invocant)));
  XPUSHs(sv_2mortal(arg));
  PUTBACK;
  count = call_method(method, G_SCALAR);
  SPAGAIN;
  if (count != 1) {
    PUTBACK;
    FREETMPS;
    LEAVE;
    croak("Method %s did not return a scalar", method);
  }
  ret = newSVsv(POPs);
  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

static int
gql_schema_does_role(pTHX_ SV *obj, const char *role) {
  SV *ret = gql_schema_call_method1(aTHX_ obj, "DOES", newSVpv(role, 0));
  int truth = SvTRUE(ret) ? 1 : 0;
  SvREFCNT_dec(ret);
  return truth;
}

static int
gql_schema_does_any_role(pTHX_ SV *obj, const char **roles, Size_t count) {
  Size_t i;

  for (i = 0; i < count; i++) {
    if (gql_schema_does_role(aTHX_ obj, roles[i])) {
      return 1;
    }
  }

  return 0;
}

static SV *
gql_schema_clone_hashref_shallow(pTHX_ SV *hashref_sv) {
  HV *src_hv;
  HV *dst_hv;
  I32 count;
  I32 i;
  SV **keys;

  if (!hashref_sv || !SvROK(hashref_sv) || SvTYPE(SvRV(hashref_sv)) != SVt_PVHV) {
    return newRV_noinc((SV *)newHV());
  }

  src_hv = (HV *)SvRV(hashref_sv);
  dst_hv = newHV();
  keys = gql_parser_sorted_hash_keys(aTHX_ src_hv, &count);
  if (!keys) {
    return newRV_noinc((SV *)dst_hv);
  }

  hv_ksplit(dst_hv, count > 1 ? count : 1);
  for (i = 0; i < count; i++) {
    HE *he = hv_fetch_ent(src_hv, keys[i], 0, 0);
    SV *value_sv;
    if (!he) {
      continue;
    }
    value_sv = HeVAL(he);
    gql_parser_store_hash_key_sv(dst_hv, keys[i], newSVsv(value_sv));
  }
  gql_parser_free_sorted_hash_keys(keys, count);

  return newRV_noinc((SV *)dst_hv);
}

static SV *
gql_schema_clone_arrayref_shallow(pTHX_ SV *arrayref_sv) {
  AV *dst_av = newAV();
  AV *src_av;
  I32 i;

  if (!arrayref_sv || !SvROK(arrayref_sv) || SvTYPE(SvRV(arrayref_sv)) != SVt_PVAV) {
    return newRV_noinc((SV *)dst_av);
  }

  src_av = (AV *)SvRV(arrayref_sv);
  if (av_len(src_av) >= 0) {
    av_extend(dst_av, av_len(src_av));
  }
  for (i = 0; i <= av_len(src_av); i++) {
    SV **svp = av_fetch(src_av, i, 0);
    if (!svp) {
      av_push(dst_av, newSV(0));
      continue;
    }
    av_push(dst_av, newSVsv(*svp));
  }

  return newRV_noinc((SV *)dst_av);
}

static const char *
gql_schema_named_type_kind(SV *type_sv) {
  if (sv_derived_from(type_sv, "GraphQL::Type::Scalar")
      || sv_derived_from(type_sv, "GraphQL::Houtou::Type::Scalar")) {
    return "SCALAR";
  }
  if (sv_derived_from(type_sv, "GraphQL::Type::Object")
      || sv_derived_from(type_sv, "GraphQL::Houtou::Type::Object")) {
    return "OBJECT";
  }
  if (sv_derived_from(type_sv, "GraphQL::Type::Interface")
      || sv_derived_from(type_sv, "GraphQL::Houtou::Type::Interface")) {
    return "INTERFACE";
  }
  if (sv_derived_from(type_sv, "GraphQL::Type::Union")
      || sv_derived_from(type_sv, "GraphQL::Houtou::Type::Union")) {
    return "UNION";
  }
  if (sv_derived_from(type_sv, "GraphQL::Type::Enum")
      || sv_derived_from(type_sv, "GraphQL::Houtou::Type::Enum")) {
    return "ENUM";
  }
  if (sv_derived_from(type_sv, "GraphQL::Type::InputObject")
      || sv_derived_from(type_sv, "GraphQL::Houtou::Type::InputObject")) {
    return "INPUT_OBJECT";
  }

  croak("unknown GraphQL named type class %s", gql_schema_class_name(type_sv));
  return "";
}

static SV *gql_schema_compile_type_ref(pTHX_ SV *type_sv);
static SV *gql_schema_compile_input_fields(pTHX_ SV *fields_sv);
static SV *gql_schema_compile_directive_instances(pTHX_ SV *directives_sv);

static SV *
gql_schema_compile_type_name_array(pTHX_ SV *arrayref_sv) {
  AV *out_av = newAV();
  AV *src_av;
  I32 i;

  if (!arrayref_sv || !SvROK(arrayref_sv) || SvTYPE(SvRV(arrayref_sv)) != SVt_PVAV) {
    return newRV_noinc((SV *)out_av);
  }

  src_av = (AV *)SvRV(arrayref_sv);
  if (av_len(src_av) >= 0) {
    av_extend(out_av, av_len(src_av));
  }
  for (i = 0; i <= av_len(src_av); i++) {
    SV **item_svp = av_fetch(src_av, i, 0);
    SV *name_sv;
    if (!item_svp) {
      continue;
    }
    name_sv = gql_schema_call_method0(aTHX_ *item_svp, "name");
    av_push(out_av, name_sv);
  }

  return newRV_noinc((SV *)out_av);
}

static SV *
gql_schema_compile_directive_instances(pTHX_ SV *directives_sv) {
  AV *out_av = newAV();
  AV *src_av;
  I32 i;

  if (!directives_sv || !SvOK(directives_sv) || !SvROK(directives_sv) || SvTYPE(SvRV(directives_sv)) != SVt_PVAV) {
    return newRV_noinc((SV *)out_av);
  }

  src_av = (AV *)SvRV(directives_sv);
  if (av_len(src_av) >= 0) {
    av_extend(out_av, av_len(src_av));
  }
  for (i = 0; i <= av_len(src_av); i++) {
    SV **dir_svp = av_fetch(src_av, i, 0);
    HV *compiled_hv;
    HV *dir_hv;
    SV **name_svp;
    SV **args_svp;
    if (!dir_svp || !SvROK(*dir_svp) || SvTYPE(SvRV(*dir_svp)) != SVt_PVHV) {
      continue;
    }
    dir_hv = (HV *)SvRV(*dir_svp);
    compiled_hv = newHV();
    hv_ksplit(compiled_hv, 3);

    name_svp = hv_fetch(dir_hv, "name", 4, 0);
    args_svp = hv_fetch(dir_hv, "arguments", 9, 0);

    gql_store_sv(compiled_hv, "name", name_svp ? newSVsv(*name_svp) : newSV(0));
    gql_store_sv(
      compiled_hv,
      "arguments",
      args_svp ? gql_schema_clone_hashref_shallow(aTHX_ *args_svp) : newRV_noinc((SV *)newHV())
    );
    gql_store_sv(compiled_hv, "source_directive", newSVsv(*dir_svp));
    av_push(out_av, newRV_noinc((SV *)compiled_hv));
  }

  return newRV_noinc((SV *)out_av);
}

static SV *
gql_schema_compile_type_ref(pTHX_ SV *type_sv) {
  HV *compiled_hv;
  SV *type_string_sv;

  if (!type_sv || !SvOK(type_sv)) {
    croak("cannot compile undefined GraphQL type reference");
  }

  if (sv_derived_from(type_sv, "GraphQL::Type::NonNull")
      || sv_derived_from(type_sv, "GraphQL::Houtou::Type::NonNull")) {
    SV *inner_sv = gql_schema_call_method0(aTHX_ type_sv, "of");
    compiled_hv = newHV();
    hv_ksplit(compiled_hv, 5);
    type_string_sv = gql_schema_call_method0(aTHX_ type_sv, "to_string");
    gql_store_sv(compiled_hv, "kind", newSVpv("NON_NULL", 0));
    gql_store_sv(compiled_hv, "of", gql_schema_compile_type_ref(aTHX_ inner_sv));
    gql_store_sv(compiled_hv, "type_string", type_string_sv);
    gql_store_sv(compiled_hv, "source_type", newSVsv(type_sv));
    gql_store_sv(compiled_hv, "source_type_id", newSVuv(gql_schema_refaddr(type_sv)));
    SvREFCNT_dec(inner_sv);
    return newRV_noinc((SV *)compiled_hv);
  }

  if (sv_derived_from(type_sv, "GraphQL::Type::List")
      || sv_derived_from(type_sv, "GraphQL::Houtou::Type::List")) {
    SV *inner_sv = gql_schema_call_method0(aTHX_ type_sv, "of");
    compiled_hv = newHV();
    hv_ksplit(compiled_hv, 5);
    type_string_sv = gql_schema_call_method0(aTHX_ type_sv, "to_string");
    gql_store_sv(compiled_hv, "kind", newSVpv("LIST", 0));
    gql_store_sv(compiled_hv, "of", gql_schema_compile_type_ref(aTHX_ inner_sv));
    gql_store_sv(compiled_hv, "type_string", type_string_sv);
    gql_store_sv(compiled_hv, "source_type", newSVsv(type_sv));
    gql_store_sv(compiled_hv, "source_type_id", newSVuv(gql_schema_refaddr(type_sv)));
    SvREFCNT_dec(inner_sv);
    return newRV_noinc((SV *)compiled_hv);
  }

  compiled_hv = newHV();
  hv_ksplit(compiled_hv, 6);
  gql_store_sv(compiled_hv, "kind", newSVpv("NAMED", 0));
  gql_store_sv(compiled_hv, "name", gql_schema_call_method0(aTHX_ type_sv, "name"));
  gql_store_sv(compiled_hv, "named_kind", newSVpv(gql_schema_named_type_kind(type_sv), 0));
  gql_store_sv(compiled_hv, "type_string", gql_schema_call_method0(aTHX_ type_sv, "to_string"));
  gql_store_sv(compiled_hv, "source_type", newSVsv(type_sv));
  gql_store_sv(compiled_hv, "source_type_id", newSVuv(gql_schema_refaddr(type_sv)));
  return newRV_noinc((SV *)compiled_hv);
}

static SV *
gql_schema_compile_input_fields(pTHX_ SV *fields_sv) {
  HV *out_hv = newHV();
  HV *fields_hv;
  I32 count;
  I32 i;
  SV **keys;

  if (!fields_sv || !SvOK(fields_sv) || !SvROK(fields_sv) || SvTYPE(SvRV(fields_sv)) != SVt_PVHV) {
    return newRV_noinc((SV *)out_hv);
  }

  fields_hv = (HV *)SvRV(fields_sv);
  keys = gql_parser_sorted_hash_keys(aTHX_ fields_hv, &count);
  if (!keys) {
    return newRV_noinc((SV *)out_hv);
  }

  hv_ksplit(out_hv, count > 1 ? count : 1);
  for (i = 0; i < count; i++) {
    HE *he = hv_fetch_ent(fields_hv, keys[i], 0, 0);
    SV *field_sv;
    HV *field_hv;
    HV *compiled_hv;
    SV **type_svp;
    SV **description_svp;
    SV **directives_svp;
    SV **deprecated_svp;
    SV **deprecated_reason_svp;

    if (!he) {
      continue;
    }
    field_sv = HeVAL(he);
    if (!SvROK(field_sv) || SvTYPE(SvRV(field_sv)) != SVt_PVHV) {
      continue;
    }

    field_hv = (HV *)SvRV(field_sv);
    type_svp = hv_fetch(field_hv, "type", 4, 0);
    if (!type_svp) {
      croak("schema compiler expected input field type");
    }

    compiled_hv = newHV();
    hv_ksplit(compiled_hv, 8);
    gql_store_sv(compiled_hv, "name", newSVsv(keys[i]));
    gql_store_sv(compiled_hv, "type", gql_schema_compile_type_ref(aTHX_ *type_svp));

    description_svp = hv_fetch(field_hv, "description", 11, 0);
    if (description_svp) {
      gql_store_sv(compiled_hv, "description", newSVsv(*description_svp));
    } else {
      gql_store_sv(compiled_hv, "description", newSV(0));
    }

    if (hv_exists(field_hv, "default_value", 13)) {
      SV **default_svp = hv_fetch(field_hv, "default_value", 13, 0);
      gql_store_sv(compiled_hv, "default_value", default_svp ? newSVsv(*default_svp) : newSV(0));
      gql_store_sv(compiled_hv, "has_default_value", newSViv(1));
    } else {
      gql_store_sv(compiled_hv, "default_value", newSV(0));
      gql_store_sv(compiled_hv, "has_default_value", newSViv(0));
    }

    directives_svp = hv_fetch(field_hv, "directives", 10, 0);
    gql_store_sv(
      compiled_hv,
      "directives",
      directives_svp ? gql_schema_compile_directive_instances(aTHX_ *directives_svp) : newRV_noinc((SV *)newAV())
    );

    deprecated_reason_svp = hv_fetch(field_hv, "deprecation_reason", 18, 0);
    if (deprecated_reason_svp) {
      gql_store_sv(compiled_hv, "deprecation_reason", newSVsv(*deprecated_reason_svp));
    } else {
      gql_store_sv(compiled_hv, "deprecation_reason", newSV(0));
    }

    deprecated_svp = hv_fetch(field_hv, "is_deprecated", 13, 0);
    gql_store_sv(compiled_hv, "is_deprecated", newSViv(deprecated_svp && SvTRUE(*deprecated_svp) ? 1 : 0));
    gql_store_sv(compiled_hv, "source_field", newSVsv(field_sv));

    gql_parser_store_hash_key_sv(out_hv, keys[i], newRV_noinc((SV *)compiled_hv));
  }

  gql_parser_free_sorted_hash_keys(keys, count);
  return newRV_noinc((SV *)out_hv);
}

static SV *
gql_schema_compile_fields(pTHX_ SV *fields_sv) {
  HV *out_hv = newHV();
  HV *fields_hv;
  I32 count;
  I32 i;
  SV **keys;

  if (!fields_sv || !SvOK(fields_sv) || !SvROK(fields_sv) || SvTYPE(SvRV(fields_sv)) != SVt_PVHV) {
    return newRV_noinc((SV *)out_hv);
  }

  fields_hv = (HV *)SvRV(fields_sv);
  keys = gql_parser_sorted_hash_keys(aTHX_ fields_hv, &count);
  if (!keys) {
    return newRV_noinc((SV *)out_hv);
  }

  hv_ksplit(out_hv, count > 1 ? count : 1);
  for (i = 0; i < count; i++) {
    HE *he = hv_fetch_ent(fields_hv, keys[i], 0, 0);
    SV *field_sv;
    HV *field_hv;
    HV *compiled_hv;
    SV **type_svp;
    SV **description_svp;
    SV **directives_svp;
    SV **deprecated_svp;
    SV **deprecated_reason_svp;
    SV **args_svp;
    SV **resolve_svp;
    SV **subscribe_svp;
    SV **cost_svp;
    SV **list_size_svp;

    if (!he) {
      continue;
    }
    field_sv = HeVAL(he);
    if (!SvROK(field_sv) || SvTYPE(SvRV(field_sv)) != SVt_PVHV) {
      continue;
    }

    field_hv = (HV *)SvRV(field_sv);
    type_svp = hv_fetch(field_hv, "type", 4, 0);
    if (!type_svp) {
      croak("schema compiler expected field type");
    }

    compiled_hv = newHV();
    hv_ksplit(compiled_hv, 12);
    gql_store_sv(compiled_hv, "name", newSVsv(keys[i]));
    gql_store_sv(compiled_hv, "type", gql_schema_compile_type_ref(aTHX_ *type_svp));

    description_svp = hv_fetch(field_hv, "description", 11, 0);
    gql_store_sv(compiled_hv, "description", description_svp ? newSVsv(*description_svp) : newSV(0));

    deprecated_reason_svp = hv_fetch(field_hv, "deprecation_reason", 18, 0);
    gql_store_sv(compiled_hv, "deprecation_reason", deprecated_reason_svp ? newSVsv(*deprecated_reason_svp) : newSV(0));

    deprecated_svp = hv_fetch(field_hv, "is_deprecated", 13, 0);
    gql_store_sv(compiled_hv, "is_deprecated", newSViv(deprecated_svp && SvTRUE(*deprecated_svp) ? 1 : 0));

    directives_svp = hv_fetch(field_hv, "directives", 10, 0);
    gql_store_sv(
      compiled_hv,
      "directives",
      directives_svp ? gql_schema_compile_directive_instances(aTHX_ *directives_svp) : newRV_noinc((SV *)newAV())
    );

    args_svp = hv_fetch(field_hv, "args", 4, 0);
    gql_store_sv(
      compiled_hv,
      "args",
      args_svp ? gql_schema_compile_input_fields(aTHX_ *args_svp) : newRV_noinc((SV *)newHV())
    );

    resolve_svp = hv_fetch(field_hv, "resolve", 7, 0);
    if (resolve_svp) {
      gql_store_sv(compiled_hv, "resolve", newSVsv(*resolve_svp));
    }

    subscribe_svp = hv_fetch(field_hv, "subscribe", 9, 0);
    if (subscribe_svp) {
      gql_store_sv(compiled_hv, "subscribe", newSVsv(*subscribe_svp));
    }

    cost_svp = hv_fetch(field_hv, "cost", 4, 0);
    if (cost_svp) {
      if (!SvIOK(*cost_svp) || SvIV(*cost_svp) < 0) {
        croak("field cost must be a non-negative integer");
      }
      gql_store_sv(compiled_hv, "cost", newSVuv(SvUV(*cost_svp)));
    }

    list_size_svp = hv_fetch(field_hv, "list_size", 9, 0);
    if (list_size_svp) {
      if (!SvIOK(*list_size_svp) || SvIV(*list_size_svp) < 1) {
        croak("field list_size must be a positive integer");
      }
      gql_store_sv(compiled_hv, "list_size", newSVuv(SvUV(*list_size_svp)));
    }

    gql_store_sv(compiled_hv, "source_field", newSVsv(field_sv));
    gql_parser_store_hash_key_sv(out_hv, keys[i], newRV_noinc((SV *)compiled_hv));
  }

  gql_parser_free_sorted_hash_keys(keys, count);
  return newRV_noinc((SV *)out_hv);
}

static SV *
gql_schema_compile_enum_values(pTHX_ SV *values_sv) {
  HV *out_hv = newHV();
  HV *values_hv;
  I32 count;
  I32 i;
  SV **keys;

  if (!values_sv || !SvOK(values_sv) || !SvROK(values_sv) || SvTYPE(SvRV(values_sv)) != SVt_PVHV) {
    return newRV_noinc((SV *)out_hv);
  }

  values_hv = (HV *)SvRV(values_sv);
  keys = gql_parser_sorted_hash_keys(aTHX_ values_hv, &count);
  if (!keys) {
    return newRV_noinc((SV *)out_hv);
  }

  hv_ksplit(out_hv, count > 1 ? count : 1);
  for (i = 0; i < count; i++) {
    HE *he = hv_fetch_ent(values_hv, keys[i], 0, 0);
    SV *value_sv;
    HV *value_hv;
    HV *compiled_hv;
    SV **actual_value_svp;
    SV **description_svp;
    SV **deprecated_svp;
    SV **deprecated_reason_svp;

    if (!he) {
      continue;
    }
    value_sv = HeVAL(he);
    if (!SvROK(value_sv) || SvTYPE(SvRV(value_sv)) != SVt_PVHV) {
      continue;
    }

    value_hv = (HV *)SvRV(value_sv);
    compiled_hv = newHV();
    hv_ksplit(compiled_hv, 6);
    gql_store_sv(compiled_hv, "name", newSVsv(keys[i]));

    actual_value_svp = hv_fetch(value_hv, "value", 5, 0);
    gql_store_sv(compiled_hv, "value", actual_value_svp ? newSVsv(*actual_value_svp) : newSVsv(keys[i]));

    description_svp = hv_fetch(value_hv, "description", 11, 0);
    gql_store_sv(compiled_hv, "description", description_svp ? newSVsv(*description_svp) : newSV(0));

    deprecated_reason_svp = hv_fetch(value_hv, "deprecation_reason", 18, 0);
    gql_store_sv(compiled_hv, "deprecation_reason", deprecated_reason_svp ? newSVsv(*deprecated_reason_svp) : newSV(0));

    deprecated_svp = hv_fetch(value_hv, "is_deprecated", 13, 0);
    gql_store_sv(compiled_hv, "is_deprecated", newSViv(deprecated_svp && SvTRUE(*deprecated_svp) ? 1 : 0));
    gql_store_sv(compiled_hv, "source_value", newSVsv(value_sv));

    gql_parser_store_hash_key_sv(out_hv, keys[i], newRV_noinc((SV *)compiled_hv));
  }

  gql_parser_free_sorted_hash_keys(keys, count);
  return newRV_noinc((SV *)out_hv);
}

static SV *
gql_schema_compile_directive(pTHX_ SV *directive_sv) {
  HV *compiled_hv = newHV();
  SV *args_sv;
  SV *locations_sv;

  hv_ksplit(compiled_hv, 6);
  gql_store_sv(compiled_hv, "name", gql_schema_call_method0(aTHX_ directive_sv, "name"));
  gql_store_sv(compiled_hv, "class", newSVpv(gql_schema_class_name(directive_sv), 0));
  gql_store_sv(compiled_hv, "description", gql_schema_call_method0(aTHX_ directive_sv, "description"));
  gql_store_sv(compiled_hv, "repeatable", gql_schema_call_method0(aTHX_ directive_sv, "repeatable"));

  locations_sv = gql_schema_call_method0(aTHX_ directive_sv, "locations");
  gql_store_sv(compiled_hv, "locations", gql_schema_clone_arrayref_shallow(aTHX_ locations_sv));
  SvREFCNT_dec(locations_sv);

  args_sv = gql_schema_call_method0(aTHX_ directive_sv, "args");
  gql_store_sv(compiled_hv, "args", gql_schema_compile_input_fields(aTHX_ args_sv));
  SvREFCNT_dec(args_sv);

  gql_store_sv(compiled_hv, "source_directive", newSVsv(directive_sv));
  return newRV_noinc((SV *)compiled_hv);
}

static SV *
gql_schema_compile_named_type(pTHX_ SV *type_sv) {
  HV *compiled_hv = newHV();
  const char *kind = gql_schema_named_type_kind(type_sv);
  SV *fields_sv;
  static const char *input_roles[] = {
    "GraphQL::Houtou::Role::Input",
    "GraphQL::Role::Input",
  };
  static const char *output_roles[] = {
    "GraphQL::Houtou::Role::Output",
    "GraphQL::Role::Output",
  };
  static const char *abstract_roles[] = {
    "GraphQL::Houtou::Role::Abstract",
    "GraphQL::Role::Abstract",
  };

  hv_ksplit(compiled_hv, 12);
  gql_store_sv(compiled_hv, "kind", newSVpv(kind, 0));
  gql_store_sv(compiled_hv, "name", gql_schema_call_method0(aTHX_ type_sv, "name"));
  gql_store_sv(compiled_hv, "class", newSVpv(gql_schema_class_name(type_sv), 0));
  gql_store_sv(compiled_hv, "description", gql_schema_call_method0(aTHX_ type_sv, "description"));
  gql_store_sv(compiled_hv, "type_string", gql_schema_call_method0(aTHX_ type_sv, "to_string"));
  gql_store_sv(compiled_hv, "source_type", newSVsv(type_sv));
  gql_store_sv(compiled_hv, "source_type_id", newSVuv(gql_schema_refaddr(type_sv)));
  gql_store_sv(compiled_hv, "is_input", newSViv(gql_schema_does_any_role(aTHX_ type_sv, input_roles, 2)));
  gql_store_sv(compiled_hv, "is_output", newSViv(gql_schema_does_any_role(aTHX_ type_sv, output_roles, 2)));
  gql_store_sv(compiled_hv, "is_abstract", newSViv(gql_schema_does_any_role(aTHX_ type_sv, abstract_roles, 2)));

  if (SvROK(type_sv) && SvTYPE(SvRV(type_sv)) == SVt_PVHV) {
    HV *type_hv = (HV *)SvRV(type_sv);
    SV **introspection_svp = hv_fetch(type_hv, "is_introspection", 16, 0);
    gql_store_sv(compiled_hv, "is_introspection", newSViv(introspection_svp && SvTRUE(*introspection_svp) ? 1 : 0));
  } else {
    gql_store_sv(compiled_hv, "is_introspection", newSViv(0));
  }

  if (strEQ(kind, "OBJECT")) {
    SV *interfaces_sv = gql_schema_call_method0(aTHX_ type_sv, "interfaces");
    fields_sv = gql_schema_call_method0(aTHX_ type_sv, "fields");
    gql_store_sv(compiled_hv, "interfaces", gql_schema_compile_type_name_array(aTHX_ interfaces_sv));
    gql_store_sv(compiled_hv, "fields", gql_schema_compile_fields(aTHX_ fields_sv));
    SvREFCNT_dec(interfaces_sv);
    SvREFCNT_dec(fields_sv);
    {
      SV *is_type_of_sv = gql_schema_call_method0(aTHX_ type_sv, "is_type_of");
      if (SvOK(is_type_of_sv)) {
        gql_store_sv(compiled_hv, "is_type_of", is_type_of_sv);
      } else {
        SvREFCNT_dec(is_type_of_sv);
      }
    }
  } else if (strEQ(kind, "INTERFACE")) {
    SV *interfaces_sv = gql_schema_call_method0(aTHX_ type_sv, "interfaces");
    fields_sv = gql_schema_call_method0(aTHX_ type_sv, "fields");
    gql_store_sv(compiled_hv, "interfaces", gql_schema_compile_type_name_array(aTHX_ interfaces_sv));
    gql_store_sv(compiled_hv, "fields", gql_schema_compile_fields(aTHX_ fields_sv));
    SvREFCNT_dec(interfaces_sv);
    SvREFCNT_dec(fields_sv);
    {
      SV *resolve_type_sv = gql_schema_call_method0(aTHX_ type_sv, "resolve_type");
      if (SvOK(resolve_type_sv)) {
        gql_store_sv(compiled_hv, "resolve_type", resolve_type_sv);
      } else {
        SvREFCNT_dec(resolve_type_sv);
      }
    }
  } else if (strEQ(kind, "UNION")) {
    SV *types_sv = gql_schema_call_method0(aTHX_ type_sv, "get_types");
    gql_store_sv(compiled_hv, "types", gql_schema_compile_type_name_array(aTHX_ types_sv));
    SvREFCNT_dec(types_sv);
    {
      SV *resolve_type_sv = gql_schema_call_method0(aTHX_ type_sv, "resolve_type");
      if (SvOK(resolve_type_sv)) {
        gql_store_sv(compiled_hv, "resolve_type", resolve_type_sv);
      } else {
        SvREFCNT_dec(resolve_type_sv);
      }
    }
  } else if (strEQ(kind, "INPUT_OBJECT")) {
    fields_sv = gql_schema_call_method0(aTHX_ type_sv, "fields");
    gql_store_sv(compiled_hv, "fields", gql_schema_compile_input_fields(aTHX_ fields_sv));
    SvREFCNT_dec(fields_sv);
    {
      SV *one_of_sv = gql_schema_call_method0(aTHX_ type_sv, "is_one_of");
      if (SvTRUE(one_of_sv)) {
        gql_store_sv(compiled_hv, "is_one_of", newSViv(1));
      }
      SvREFCNT_dec(one_of_sv);
    }
  } else if (strEQ(kind, "ENUM")) {
    SV *values_sv = gql_schema_call_method0(aTHX_ type_sv, "values");
    gql_store_sv(compiled_hv, "values", gql_schema_compile_enum_values(aTHX_ values_sv));
    SvREFCNT_dec(values_sv);
  } else if (strEQ(kind, "SCALAR")) {
    SV *serialize_sv = gql_schema_call_method0(aTHX_ type_sv, "serialize");
    SV *parse_value_sv = gql_schema_call_method0(aTHX_ type_sv, "parse_value");
    SV *specified_by_url_sv = gql_schema_call_method0(aTHX_ type_sv, "specified_by_url");
    if (SvOK(serialize_sv)) {
      gql_store_sv(compiled_hv, "serialize", serialize_sv);
    } else {
      SvREFCNT_dec(serialize_sv);
    }
    if (SvOK(parse_value_sv)) {
      gql_store_sv(compiled_hv, "parse_value", parse_value_sv);
    } else {
      SvREFCNT_dec(parse_value_sv);
    }
    if (SvOK(specified_by_url_sv)) {
      gql_store_sv(compiled_hv, "specified_by_url", specified_by_url_sv);
    } else {
      SvREFCNT_dec(specified_by_url_sv);
    }
  }

  return newRV_noinc((SV *)compiled_hv);
}

static SV *
gql_schema_compile_schema(pTHX_ SV *schema_sv) {
  HV *compiled_hv;
  HV *roots_hv;
  HV *types_hv;
  HV *directives_hv;
  HV *interface_implementations_hv;
  HV *possible_types_hv;
  SV *name2type_sv;
  HV *name2type_hv;
  I32 type_count;
  I32 i;
  SV **type_keys;
  SV *directives_sv;
  AV *directives_av;

  if (!sv_derived_from(schema_sv, "GraphQL::Schema")
      && !sv_derived_from(schema_sv, "GraphQL::Houtou::Schema")) {
    croak("compile_schema_xs expects a GraphQL::Houtou::Schema or GraphQL::Schema instance");
  }

  compiled_hv = newHV();
  roots_hv = newHV();
  types_hv = newHV();
  directives_hv = newHV();
  interface_implementations_hv = newHV();
  possible_types_hv = newHV();

  {
    const char *root_names[] = { "query", "mutation", "subscription" };
    I32 root_i;
    hv_ksplit(roots_hv, 3);
    for (root_i = 0; root_i < 3; root_i++) {
      SV *root_type_sv = gql_schema_call_method0(aTHX_ schema_sv, root_names[root_i]);
      if (SvOK(root_type_sv) && SvROK(root_type_sv)) {
        SV *root_name_sv = gql_schema_call_method0(aTHX_ root_type_sv, "name");
        gql_store_sv(roots_hv, root_names[root_i], root_name_sv);
      } else {
        gql_store_sv(roots_hv, root_names[root_i], newSV(0));
      }
      SvREFCNT_dec(root_type_sv);
    }
  }

  name2type_sv = gql_schema_call_method0(aTHX_ schema_sv, "name2type");
  if (!SvROK(name2type_sv) || SvTYPE(SvRV(name2type_sv)) != SVt_PVHV) {
    SvREFCNT_dec(name2type_sv);
    croak("GraphQL::Schema->name2type did not return a hash reference");
  }
  name2type_hv = (HV *)SvRV(name2type_sv);
  type_keys = gql_parser_sorted_hash_keys(aTHX_ name2type_hv, &type_count);
  if (type_keys) {
    hv_ksplit(types_hv, type_count > 1 ? type_count : 1);
    for (i = 0; i < type_count; i++) {
      HE *he = hv_fetch_ent(name2type_hv, type_keys[i], 0, 0);
      SV *type_sv;
      if (!he) {
        continue;
      }
      type_sv = HeVAL(he);
      gql_parser_store_hash_key_sv(types_hv, type_keys[i], gql_schema_compile_named_type(aTHX_ type_sv));
    }

    for (i = 0; i < type_count; i++) {
      HE *he = hv_fetch_ent(name2type_hv, type_keys[i], 0, 0);
      SV *type_sv;
      if (!he) {
        continue;
      }
      type_sv = HeVAL(he);

      if (sv_derived_from(type_sv, "GraphQL::Type::Object")
          || sv_derived_from(type_sv, "GraphQL::Houtou::Type::Object")) {
        SV *interfaces_sv = gql_schema_call_method0(aTHX_ type_sv, "interfaces");
        if (SvROK(interfaces_sv) && SvTYPE(SvRV(interfaces_sv)) == SVt_PVAV) {
          AV *interfaces_av = (AV *)SvRV(interfaces_sv);
          I32 j;
          for (j = 0; j <= av_len(interfaces_av); j++) {
            SV **iface_svp = av_fetch(interfaces_av, j, 0);
            SV *iface_name_sv;
            HE *existing_he;
            SV *existing_sv = NULL;
            AV *existing_av;
            if (!iface_svp) {
              continue;
            }
            iface_name_sv = gql_schema_call_method0(aTHX_ *iface_svp, "name");
            existing_he = hv_fetch_ent(interface_implementations_hv, iface_name_sv, 0, 0);
            if (existing_he) {
              existing_sv = HeVAL(existing_he);
            }
            if (existing_sv && SvROK(existing_sv) && SvTYPE(SvRV(existing_sv)) == SVt_PVAV) {
              existing_av = (AV *)SvRV(existing_sv);
            } else {
              existing_av = newAV();
              gql_parser_store_hash_key_sv(interface_implementations_hv, iface_name_sv, newRV_noinc((SV *)existing_av));
            }
            av_push(existing_av, newSVsv(type_keys[i]));
            SvREFCNT_dec(iface_name_sv);
          }
        }
        SvREFCNT_dec(interfaces_sv);
      }

      if (sv_derived_from(type_sv, "GraphQL::Type::Interface")
          || sv_derived_from(type_sv, "GraphQL::Houtou::Type::Interface")
          || sv_derived_from(type_sv, "GraphQL::Type::Union")
          || sv_derived_from(type_sv, "GraphQL::Houtou::Type::Union")) {
        SV *possible_sv = gql_schema_call_method1(aTHX_ schema_sv, "get_possible_types", newSVsv(type_sv));
        gql_parser_store_hash_key_sv(possible_types_hv, type_keys[i], gql_schema_compile_type_name_array(aTHX_ possible_sv));
        SvREFCNT_dec(possible_sv);
      }
    }
    gql_parser_free_sorted_hash_keys(type_keys, type_count);
  }
  SvREFCNT_dec(name2type_sv);

  directives_sv = gql_schema_call_method0(aTHX_ schema_sv, "directives");
  if (!SvROK(directives_sv) || SvTYPE(SvRV(directives_sv)) != SVt_PVAV) {
    SvREFCNT_dec(directives_sv);
    croak("GraphQL::Schema->directives did not return an array reference");
  }
  directives_av = (AV *)SvRV(directives_sv);
  if (av_len(directives_av) >= 0) {
    hv_ksplit(directives_hv, av_len(directives_av) + 1);
  }
  for (i = 0; i <= av_len(directives_av); i++) {
    SV **directive_svp = av_fetch(directives_av, i, 0);
    SV *name_sv;
    if (!directive_svp) {
      continue;
    }
    name_sv = gql_schema_call_method0(aTHX_ *directive_svp, "name");
    gql_parser_store_hash_key_sv(directives_hv, name_sv, gql_schema_compile_directive(aTHX_ *directive_svp));
    SvREFCNT_dec(name_sv);
  }
  SvREFCNT_dec(directives_sv);

  hv_ksplit(compiled_hv, 6);
  gql_store_sv(compiled_hv, "roots", newRV_noinc((SV *)roots_hv));
  gql_store_sv(compiled_hv, "types", newRV_noinc((SV *)types_hv));
  gql_store_sv(compiled_hv, "directives", newRV_noinc((SV *)directives_hv));
  gql_store_sv(compiled_hv, "interface_implementations", newRV_noinc((SV *)interface_implementations_hv));
  gql_store_sv(compiled_hv, "possible_types", newRV_noinc((SV *)possible_types_hv));
  gql_store_sv(compiled_hv, "source_schema", newSVsv(schema_sv));

  return newRV_noinc((SV *)compiled_hv);
}
