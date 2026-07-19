/*
 * Responsibility: provide the initial XS validation entrypoint so the public
 * validation facade can route through XS while rule implementations migrate
 * from PP to C incrementally.
 */

static SV *
gql_validation_parse_ast(pTHX_ SV *document, SV *options, AV *errors_av) {
  if (document && SvROK(document)) {
    return newSVsv(document);
  }

  /* Validation owns an internal parser mode so duplicate arguments,
   * variables, and input fields can be diagnosed before the canonical hash
   * AST overwrites the earlier entry. Public parse() remains compatible. */
  {
    SV *no_location_sv = &PL_sv_undef;
    if (options && SvROK(options) && SvTYPE(SvRV(options)) == SVt_PVHV) {
      SV **svp = hv_fetch((HV *)SvRV(options), "no_location", 11, 0);
      if (!svp) {
        svp = hv_fetch((HV *)SvRV(options), "noLocation", 10, 0);
      }
      if (svp) {
        no_location_sv = *svp;
      }
    }
    return gql_parse_document_for_validation(
      aTHX_ document, no_location_sv, errors_av
    );
  }
}

static SV *
gql_validation_schema_name2type_sv(pTHX_ SV *schema) {
  dSP;
  int count;
  SV *ret;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVsv(schema)));
  PUTBACK;

  count = call_method("name2type", G_SCALAR);
  SPAGAIN;
  if (count != 1) {
    PUTBACK;
    FREETMPS;
    LEAVE;
    croak("schema->name2type did not return a scalar");
  }

  ret = newSVsv(POPs);
  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

static SV *
gql_validation_lookup_type_sv(pTHX_ SV *schema, SV *type_ref) {
  dSP;
  int count;
  SV *ret;
  SV *name2type_sv;

  eval_pv("require GraphQL::Houtou::Schema; 1;", TRUE);
  name2type_sv = gql_validation_schema_name2type_sv(aTHX_ schema);

  ENTER;
  SAVETMPS;
  sv_setsv(ERRSV, &PL_sv_undef);
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVsv(type_ref)));
  XPUSHs(sv_2mortal(name2type_sv));
  PUTBACK;

  count = call_pv("GraphQL::Houtou::Schema::lookup_type", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (count != 1) {
    PUTBACK;
    FREETMPS;
    LEAVE;
    croak("GraphQL::Houtou::Schema::lookup_type did not return a scalar");
  }

  ret = newSVsv(POPs);
  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

static SV *
gql_validation_error(pTHX_ const char *message, SV *location) {
  HV *error_hv = newHV();
  gql_store_sv(error_hv, "message", newSVpv(message, 0));
  if (location && SvOK(location)) {
    AV *locations_av = newAV();
    av_push(locations_av, newSVsv(location));
    gql_store_sv(error_hv, "locations", newRV_noinc((SV *)locations_av));
  }
  return newRV_noinc((SV *)error_hv);
}

static void
gql_validation_push_operation_errors(pTHX_ AV *errors_av, AV *operations_av) {
  HV *seen_hv = newHV();
  I32 operation_len = av_len(operations_av);
  I32 i;
  int operation_count = operation_len >= 0 ? operation_len + 1 : 0;

  if (operation_count == 0) {
    av_push(errors_av, gql_validation_error(aTHX_ "No operations supplied.", NULL));
    SvREFCNT_dec((SV *)seen_hv);
    return;
  }

  for (i = 0; i <= operation_len; i++) {
    SV **operation_svp = av_fetch(operations_av, i, 0);
    HV *operation_hv;
    SV **name_svp;
    SV **location_svp;
    STRLEN name_len;
    const char *name;

    if (!operation_svp || !SvROK(*operation_svp) || SvTYPE(SvRV(*operation_svp)) != SVt_PVHV) {
      continue;
    }

    operation_hv = (HV *)SvRV(*operation_svp);
    location_svp = hv_fetch(operation_hv, "location", 8, 0);
    name_svp = hv_fetch(operation_hv, "name", 4, 0);

    if (!name_svp || !SvOK(*name_svp)) {
      if (operation_count > 1) {
        av_push(
          errors_av,
          gql_validation_error(
            aTHX_ "Anonymous operations must be the only operation in the document.",
            location_svp ? *location_svp : NULL
          )
        );
      }
      continue;
    }

    name = SvPV(*name_svp, name_len);
    if (hv_exists(seen_hv, name, (I32)name_len)) {
      SV *message = newSVpvf("Operation '%s' is defined more than once.", name);
      av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
      SvREFCNT_dec(message);
      continue;
    }

    (void)hv_store(seen_hv, name, (I32)name_len, newSViv(1), 0);
  }

  SvREFCNT_dec((SV *)seen_hv);
}

static HV *
gql_validation_build_fragments_map(pTHX_ AV *ast_av) {
  HV *fragments_hv = newHV();
  I32 ast_len = av_len(ast_av);
  I32 i;

  for (i = 0; i <= ast_len; i++) {
    SV **node_svp = av_fetch(ast_av, i, 0);
    HV *node_hv;
    SV **kind_svp;
    SV **name_svp;
    STRLEN name_len;
    const char *name;

    if (!node_svp || !SvROK(*node_svp) || SvTYPE(SvRV(*node_svp)) != SVt_PVHV) {
      continue;
    }

    node_hv = (HV *)SvRV(*node_svp);
    kind_svp = hv_fetch(node_hv, "kind", 4, 0);
    if (!kind_svp || !SvOK(*kind_svp) || !SvPOK(*kind_svp) || !strEQ(SvPV_nolen(*kind_svp), "fragment")) {
      continue;
    }

    name_svp = hv_fetch(node_hv, "name", 4, 0);
    if (!name_svp || !SvOK(*name_svp)) {
      continue;
    }

    name = SvPV(*name_svp, name_len);
    (void)hv_store(fragments_hv, name, (I32)name_len, newSVsv(*node_svp), 0);
  }

  return fragments_hv;
}

static void
gql_validation_push_fragment_name_errors(pTHX_ AV *errors_av, AV *ast_av) {
  HV *seen_hv = newHV();
  I32 i;

  for (i = 0; i <= av_len(ast_av); i++) {
    SV **node_svp = av_fetch(ast_av, i, 0);
    HV *node_hv;
    SV **kind_svp;
    SV **name_svp;
    SV **location_svp;
    STRLEN name_len;
    const char *name;

    if (!node_svp || !SvROK(*node_svp) || SvTYPE(SvRV(*node_svp)) != SVt_PVHV) {
      continue;
    }
    node_hv = (HV *)SvRV(*node_svp);
    kind_svp = hv_fetch(node_hv, "kind", 4, 0);
    if (!kind_svp || !SvOK(*kind_svp) || !SvPOK(*kind_svp)
        || !strEQ(SvPV_nolen(*kind_svp), "fragment")) {
      continue;
    }
    name_svp = hv_fetch(node_hv, "name", 4, 0);
    if (!name_svp || !SvOK(*name_svp)) {
      continue;
    }
    name = SvPV(*name_svp, name_len);
    if (hv_exists(seen_hv, name, (I32)name_len)) {
      SV *message = newSVpvf("Fragment '%s' is defined more than once.", name);
      location_svp = hv_fetch(node_hv, "location", 8, 0);
      av_push(errors_av, gql_validation_error(
        aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL
      ));
      SvREFCNT_dec(message);
    } else {
      (void)hv_store(seen_hv, name, (I32)name_len, newSViv(1), 0);
    }
  }
  SvREFCNT_dec((SV *)seen_hv);
}

static void
gql_validation_collect_usage(
  pTHX_ SV *node_sv,
  HV *fragments_hv,
  HV *variables_hv,
  HV *spreads_hv,
  HV *visited_hv
) {
  SV *inner_sv;

  if (!node_sv || !SvROK(node_sv)) {
    return;
  }
  inner_sv = SvRV(node_sv);
  if (SvTYPE(inner_sv) != SVt_PVAV && SvTYPE(inner_sv) != SVt_PVHV
      && !SvROK(inner_sv) && !sv_isobject(node_sv)) {
    STRLEN name_len;
    const char *name = SvPV(inner_sv, name_len);
    (void)hv_store(variables_hv, name, (I32)name_len, newSViv(1), 0);
    return;
  }
  if (SvTYPE(inner_sv) == SVt_PVAV) {
    AV *items_av = (AV *)inner_sv;
    I32 i;
    for (i = 0; i <= av_len(items_av); i++) {
      SV **item_svp = av_fetch(items_av, i, 0);
      if (item_svp) {
        gql_validation_collect_usage(
          aTHX_ *item_svp, fragments_hv, variables_hv, spreads_hv, visited_hv
        );
      }
    }
    return;
  }
  if (SvTYPE(inner_sv) == SVt_PVHV) {
    HV *node_hv = (HV *)inner_sv;
    SV **kind_svp = hv_fetch(node_hv, "kind", 4, 0);
    if (kind_svp && SvOK(*kind_svp) && SvPOK(*kind_svp)
        && strEQ(SvPV_nolen(*kind_svp), "fragment_spread")) {
      SV **name_svp = hv_fetch(node_hv, "name", 4, 0);
      if (name_svp && SvOK(*name_svp)) {
        STRLEN name_len;
        const char *name = SvPV(*name_svp, name_len);
        (void)hv_store(spreads_hv, name, (I32)name_len, newSViv(1), 0);
        if (!hv_exists(visited_hv, name, (I32)name_len)) {
          HE *fragment_he;
          (void)hv_store(visited_hv, name, (I32)name_len, newSViv(1), 0);
          fragment_he = hv_fetch_ent(fragments_hv, *name_svp, 0, 0);
          if (fragment_he && SvROK(HeVAL(fragment_he))
              && SvTYPE(SvRV(HeVAL(fragment_he))) == SVt_PVHV) {
            SV **selections_svp = hv_fetch(
              (HV *)SvRV(HeVAL(fragment_he)), "selections", 10, 0
            );
            if (selections_svp) {
              gql_validation_collect_usage(
                aTHX_ *selections_svp, fragments_hv, variables_hv,
                spreads_hv, visited_hv
              );
            }
          }
        }
      }
    }
    {
      HE *he;
      hv_iterinit(node_hv);
      while ((he = hv_iternext(node_hv))) {
        STRLEN key_len;
        const char *key = HePV(he, key_len);
        if ((key_len == 9 && memEQ(key, "variables", 9))
            || (key_len == 8 && memEQ(key, "location", 8))) {
          continue;
        }
        gql_validation_collect_usage(
          aTHX_ HeVAL(he), fragments_hv, variables_hv, spreads_hv, visited_hv
        );
      }
    }
  }
}

static void
gql_validation_push_usage_errors(
  pTHX_ AV *errors_av, AV *ast_av, AV *operations_av, HV *fragments_hv
) {
  HV *reachable_hv = newHV();
  I32 i;

  for (i = 0; i <= av_len(operations_av); i++) {
    SV **operation_svp = av_fetch(operations_av, i, 0);
    HV *operation_hv;
    HV *used_variables_hv = newHV();
    HV *spreads_hv = newHV();
    HV *visited_hv = newHV();
    SV **variable_defs_svp;
    HE *he;

    if (!operation_svp || !SvROK(*operation_svp)
        || SvTYPE(SvRV(*operation_svp)) != SVt_PVHV) {
      SvREFCNT_dec((SV *)used_variables_hv);
      SvREFCNT_dec((SV *)spreads_hv);
      SvREFCNT_dec((SV *)visited_hv);
      continue;
    }
    operation_hv = (HV *)SvRV(*operation_svp);
    gql_validation_collect_usage(
      aTHX_ *operation_svp, fragments_hv, used_variables_hv, spreads_hv, visited_hv
    );
    hv_iterinit(spreads_hv);
    while ((he = hv_iternext(spreads_hv))) {
      STRLEN name_len;
      const char *name = HePV(he, name_len);
      (void)hv_store(reachable_hv, name, (I32)name_len, newSViv(1), 0);
    }

    variable_defs_svp = hv_fetch(operation_hv, "variables", 9, 0);
    if (variable_defs_svp && SvROK(*variable_defs_svp)
        && SvTYPE(SvRV(*variable_defs_svp)) == SVt_PVHV) {
      HV *defs_hv = (HV *)SvRV(*variable_defs_svp);
      hv_iterinit(defs_hv);
      while ((he = hv_iternext(defs_hv))) {
        STRLEN name_len;
        const char *name = HePV(he, name_len);
        if (!hv_exists(used_variables_hv, name, (I32)name_len)) {
          SV **operation_name_svp = hv_fetch(operation_hv, "name", 4, 0);
          SV **location_svp = hv_fetch(operation_hv, "location", 8, 0);
          const char *operation_name = operation_name_svp && SvOK(*operation_name_svp)
            ? SvPV_nolen(*operation_name_svp) : "<anonymous>";
          SV *message = newSVpvf(
            "Variable '$%s' is never used in operation '%s'.", name, operation_name
          );
          av_push(errors_av, gql_validation_error(
            aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL
          ));
          SvREFCNT_dec(message);
        }
      }
    }
    SvREFCNT_dec((SV *)used_variables_hv);
    SvREFCNT_dec((SV *)spreads_hv);
    SvREFCNT_dec((SV *)visited_hv);
  }

  for (i = 0; i <= av_len(ast_av); i++) {
    SV **node_svp = av_fetch(ast_av, i, 0);
    HV *node_hv;
    SV **kind_svp;
    SV **name_svp;
    SV **location_svp;
    STRLEN name_len;
    const char *name;
    if (!node_svp || !SvROK(*node_svp) || SvTYPE(SvRV(*node_svp)) != SVt_PVHV) {
      continue;
    }
    node_hv = (HV *)SvRV(*node_svp);
    kind_svp = hv_fetch(node_hv, "kind", 4, 0);
    name_svp = hv_fetch(node_hv, "name", 4, 0);
    if (!kind_svp || !SvOK(*kind_svp) || !SvPOK(*kind_svp)
        || !strEQ(SvPV_nolen(*kind_svp), "fragment")
        || !name_svp || !SvOK(*name_svp)) {
      continue;
    }
    name = SvPV(*name_svp, name_len);
    if (!hv_exists(reachable_hv, name, (I32)name_len)) {
      SV *message = newSVpvf("Fragment '%s' is never used.", name);
      location_svp = hv_fetch(node_hv, "location", 8, 0);
      av_push(errors_av, gql_validation_error(
        aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL
      ));
      SvREFCNT_dec(message);
    }
  }
  SvREFCNT_dec((SV *)reachable_hv);
}

static void
gql_validation_collect_subscription_fields(pTHX_ HV *fields_hv, SV *selections_sv, HV *fragments_hv, HV *visited_hv) {
  AV *selections_av;
  I32 selection_len;
  I32 i;

  if (!selections_sv || !SvROK(selections_sv) || SvTYPE(SvRV(selections_sv)) != SVt_PVAV) {
    return;
  }

  selections_av = (AV *)SvRV(selections_sv);
  selection_len = av_len(selections_av);
  for (i = 0; i <= selection_len; i++) {
    SV **selection_svp = av_fetch(selections_av, i, 0);
    HV *selection_hv;
    SV **kind_svp;

    if (!selection_svp || !SvROK(*selection_svp) || SvTYPE(SvRV(*selection_svp)) != SVt_PVHV) {
      continue;
    }

    selection_hv = (HV *)SvRV(*selection_svp);
    kind_svp = hv_fetch(selection_hv, "kind", 4, 0);
    if (!kind_svp || !SvOK(*kind_svp) || !SvPOK(*kind_svp)) {
      continue;
    }

    if (strEQ(SvPV_nolen(*kind_svp), "field")) {
      SV **name_svp = hv_fetch(selection_hv, "name", 4, 0);
      if (name_svp && SvOK(*name_svp)) {
        SV **alias_svp = hv_fetch(selection_hv, "alias", 5, 0);
        SV *response_name_sv = alias_svp && SvOK(*alias_svp) ? *alias_svp : *name_svp;
        (void)hv_store_ent(fields_hv, response_name_sv, newSVsv(*name_svp), 0);
      }
      continue;
    }

    if (strEQ(SvPV_nolen(*kind_svp), "fragment_spread")) {
      SV **name_svp = hv_fetch(selection_hv, "name", 4, 0);
      STRLEN name_len;
      const char *name;
      HE *fragment_he;
      SV *fragment_sv;
      HV *fragment_hv;
      SV **fragment_selections_svp;

      if (!name_svp || !SvOK(*name_svp)) {
        continue;
      }

      name = SvPV(*name_svp, name_len);
      if (hv_exists(visited_hv, name, (I32)name_len)) {
        continue;
      }

      fragment_he = hv_fetch_ent(fragments_hv, *name_svp, 0, 0);
      if (!fragment_he) {
        continue;
      }

      fragment_sv = HeVAL(fragment_he);
      if (!SvROK(fragment_sv) || SvTYPE(SvRV(fragment_sv)) != SVt_PVHV) {
        continue;
      }

      (void)hv_store(visited_hv, name, (I32)name_len, newSViv(1), 0);
      fragment_hv = (HV *)SvRV(fragment_sv);
      fragment_selections_svp = hv_fetch(fragment_hv, "selections", 10, 0);
      gql_validation_collect_subscription_fields(
        aTHX_ fields_hv,
        fragment_selections_svp ? *fragment_selections_svp : NULL,
        fragments_hv,
        visited_hv
      );
      (void)hv_delete(visited_hv, name, (I32)name_len, G_DISCARD);
      continue;
    }

    if (strEQ(SvPV_nolen(*kind_svp), "inline_fragment")) {
      SV **nested_svp = hv_fetch(selection_hv, "selections", 10, 0);
      gql_validation_collect_subscription_fields(
        aTHX_ fields_hv,
        nested_svp ? *nested_svp : NULL,
        fragments_hv,
        visited_hv
      );
    }
  }
}

static void
gql_validation_collect_fragment_spreads(pTHX_ AV *names_av, SV *selections_sv) {
  AV *selections_av;
  I32 selection_len;
  I32 i;

  if (!selections_sv || !SvROK(selections_sv) || SvTYPE(SvRV(selections_sv)) != SVt_PVAV) {
    return;
  }

  selections_av = (AV *)SvRV(selections_sv);
  selection_len = av_len(selections_av);
  for (i = 0; i <= selection_len; i++) {
    SV **selection_svp = av_fetch(selections_av, i, 0);
    HV *selection_hv;
    SV **kind_svp;

    if (!selection_svp || !SvROK(*selection_svp) || SvTYPE(SvRV(*selection_svp)) != SVt_PVHV) {
      continue;
    }

    selection_hv = (HV *)SvRV(*selection_svp);
    kind_svp = hv_fetch(selection_hv, "kind", 4, 0);
    if (!kind_svp || !SvOK(*kind_svp) || !SvPOK(*kind_svp)) {
      continue;
    }

    if (strEQ(SvPV_nolen(*kind_svp), "fragment_spread")) {
      SV **name_svp = hv_fetch(selection_hv, "name", 4, 0);
      if (name_svp && SvOK(*name_svp)) {
        av_push(names_av, newSVsv(*name_svp));
      }
      continue;
    }

    if (strEQ(SvPV_nolen(*kind_svp), "field") || strEQ(SvPV_nolen(*kind_svp), "inline_fragment")) {
      SV **nested_svp = hv_fetch(selection_hv, "selections", 10, 0);
      gql_validation_collect_fragment_spreads(aTHX_ names_av, nested_svp ? *nested_svp : NULL);
    }
  }
}

static void
gql_validation_visit_fragment_cycles(pTHX_ AV *errors_av, HV *fragments_hv, HV *state_hv, SV *name_key_sv) {
  STRLEN name_len;
  const char *name;
  HE *fragment_he;
  SV *fragment_sv;
  HV *fragment_hv;
  HE *state_he;
  const char *state;
  SV **selections_svp;
  AV *spreads_av = newAV();
  I32 spread_len;
  I32 i;
  SV **location_svp;

  if (!name_key_sv || !SvOK(name_key_sv)) {
    SvREFCNT_dec((SV *)spreads_av);
    return;
  }

  name = SvPV(name_key_sv, name_len);
  fragment_he = hv_fetch_ent(fragments_hv, name_key_sv, 0, 0);
  if (!fragment_he) {
    SvREFCNT_dec((SV *)spreads_av);
    return;
  }

  state_he = hv_fetch_ent(state_hv, name_key_sv, 0, 0);
  if (state_he && SvOK(HeVAL(state_he))) {
    state = SvPV_nolen(HeVAL(state_he));
    if (strEQ(state, "done")) {
      SvREFCNT_dec((SV *)spreads_av);
      return;
    }
    if (strEQ(state, "visiting")) {
      fragment_sv = HeVAL(fragment_he);
      if (SvROK(fragment_sv) && SvTYPE(SvRV(fragment_sv)) == SVt_PVHV) {
        fragment_hv = (HV *)SvRV(fragment_sv);
        location_svp = hv_fetch(fragment_hv, "location", 8, 0);
        {
          SV *message = newSVpvf("Fragment '%s' participates in a cycle.", name);
          av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
          SvREFCNT_dec(message);
        }
      }
      SvREFCNT_dec((SV *)spreads_av);
      return;
    }
  }

  (void)hv_store(state_hv, name, (I32)name_len, newSVpv("visiting", 0), 0);
  fragment_sv = HeVAL(fragment_he);
  if (!SvROK(fragment_sv) || SvTYPE(SvRV(fragment_sv)) != SVt_PVHV) {
    (void)hv_store(state_hv, name, (I32)name_len, newSVpv("done", 0), 0);
    SvREFCNT_dec((SV *)spreads_av);
    return;
  }

  fragment_hv = (HV *)SvRV(fragment_sv);
  selections_svp = hv_fetch(fragment_hv, "selections", 10, 0);
  gql_validation_collect_fragment_spreads(aTHX_ spreads_av, selections_svp ? *selections_svp : NULL);

  spread_len = av_len(spreads_av);
  for (i = 0; i <= spread_len; i++) {
    SV **spread_name_svp = av_fetch(spreads_av, i, 0);
    if (!spread_name_svp || !SvOK(*spread_name_svp)) {
      continue;
    }
    gql_validation_visit_fragment_cycles(aTHX_ errors_av, fragments_hv, state_hv, *spread_name_svp);
  }

  (void)hv_store(state_hv, name, (I32)name_len, newSVpv("done", 0), 0);
  SvREFCNT_dec((SV *)spreads_av);
}

static void
gql_validation_push_fragment_cycle_errors(pTHX_ AV *errors_av, HV *fragments_hv) {
  I32 fragment_count;
  I32 i;
  SV **keys;
  HV *state_hv = newHV();

  keys = gql_parser_sorted_hash_keys(aTHX_ fragments_hv, &fragment_count);
  if (!keys) {
    SvREFCNT_dec((SV *)state_hv);
    return;
  }

  for (i = 0; i < fragment_count; i++) {
    gql_validation_visit_fragment_cycles(aTHX_ errors_av, fragments_hv, state_hv, keys[i]);
  }

  gql_parser_free_sorted_hash_keys(keys, fragment_count);
  SvREFCNT_dec((SV *)state_hv);
}

static void
gql_validation_push_subscription_errors(pTHX_ AV *operation_errors_av, AV *operations_av, HV *fragments_hv) {
  I32 operation_len = av_len(operations_av);
  I32 i;

  for (i = 0; i <= operation_len; i++) {
    SV **operation_svp = av_fetch(operations_av, i, 0);
    AV *errors_av = newAV();
    HV *operation_hv;
    SV **operation_type_svp;

    av_push(operation_errors_av, newRV_noinc((SV *)errors_av));

    if (!operation_svp || !SvROK(*operation_svp) || SvTYPE(SvRV(*operation_svp)) != SVt_PVHV) {
      continue;
    }

    operation_hv = (HV *)SvRV(*operation_svp);
    operation_type_svp = hv_fetch(operation_hv, "operationType", 13, 0);
    if (operation_type_svp && SvOK(*operation_type_svp) && SvPOK(*operation_type_svp)
        && strEQ(SvPV_nolen(*operation_type_svp), "subscription")) {
      HV *fields_hv = newHV();
      HV *visited_hv = newHV();
      SV **selections_svp = hv_fetch(operation_hv, "selections", 10, 0);
      SV **location_svp = hv_fetch(operation_hv, "location", 8, 0);
      I32 field_count;

      gql_validation_collect_subscription_fields(
        aTHX_ fields_hv,
        selections_svp ? *selections_svp : NULL,
        fragments_hv,
        visited_hv
      );
      field_count = (I32)HvUSEDKEYS(fields_hv);
      if (field_count != 1) {
        SV *message = newSVpv("Subscription needs to have only one field; got (", 0);
        I32 sorted_count = 0;
        SV **keys = gql_parser_sorted_hash_keys(aTHX_ fields_hv, &sorted_count);
        I32 j;
        for (j = 0; j < sorted_count; j++) {
          if (j > 0) {
            sv_catpvn(message, " ", 1);
          }
          sv_catsv(message, keys[j]);
        }
        sv_catpvn(message, ")", 1);
        av_push(
          errors_av,
          gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL)
        );
        SvREFCNT_dec(message);
        gql_parser_free_sorted_hash_keys(keys, sorted_count);
      } else {
        HE *field_he;
        hv_iterinit(fields_hv);
        field_he = hv_iternext(fields_hv);
        if (field_he && HeVAL(field_he) && SvOK(HeVAL(field_he))
            && strnEQ(SvPV_nolen(HeVAL(field_he)), "__", 2)) {
          SV *message = newSVpv("Subscription root field must not be an introspection field.", 0);
          av_push(
            errors_av,
            gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL)
          );
          SvREFCNT_dec(message);
        }
      }

      SvREFCNT_dec((SV *)visited_hv);
      SvREFCNT_dec((SV *)fields_hv);
    }
  }
}

static HV *
gql_validation_compiled_hv_from_sv(SV *compiled_sv) {
  if (!compiled_sv || !SvROK(compiled_sv) || SvTYPE(SvRV(compiled_sv)) != SVt_PVHV) {
    return NULL;
  }
  return (HV *)SvRV(compiled_sv);
}

static HV *
gql_validation_compiled_type_hv(pTHX_ SV *compiled_sv, SV *type_name_sv) {
  HV *compiled_hv = gql_validation_compiled_hv_from_sv(compiled_sv);
  SV **types_svp;
  HE *type_he;

  if (!compiled_hv || !type_name_sv || !SvOK(type_name_sv)) {
    return NULL;
  }

  types_svp = hv_fetch(compiled_hv, "types", 5, 0);
  if (!types_svp || !SvROK(*types_svp) || SvTYPE(SvRV(*types_svp)) != SVt_PVHV) {
    return NULL;
  }

  type_he = hv_fetch_ent((HV *)SvRV(*types_svp), type_name_sv, 0, 0);
  if (!type_he || !SvROK(HeVAL(type_he)) || SvTYPE(SvRV(HeVAL(type_he))) != SVt_PVHV) {
    return NULL;
  }

  return (HV *)SvRV(HeVAL(type_he));
}

static SV *
gql_validation_named_type_name_sv(SV *type_ref_sv) {
  HV *type_ref_hv;
  SV **kind_svp;
  SV **name_svp;
  SV **of_svp;

  if (!type_ref_sv || !SvROK(type_ref_sv) || SvTYPE(SvRV(type_ref_sv)) != SVt_PVHV) {
    return NULL;
  }

  type_ref_hv = (HV *)SvRV(type_ref_sv);
  kind_svp = hv_fetch(type_ref_hv, "kind", 4, 0);
  if (kind_svp && SvOK(*kind_svp) && SvPOK(*kind_svp) && strEQ(SvPV_nolen(*kind_svp), "NAMED")) {
    name_svp = hv_fetch(type_ref_hv, "name", 4, 0);
    return name_svp ? *name_svp : NULL;
  }

  of_svp = hv_fetch(type_ref_hv, "of", 2, 0);
  return of_svp ? gql_validation_named_type_name_sv(*of_svp) : NULL;
}

static int
gql_validation_type_is_non_null(SV *type_ref_sv) {
  HV *type_ref_hv;
  SV **kind_svp;

  if (!type_ref_sv || !SvROK(type_ref_sv) || SvTYPE(SvRV(type_ref_sv)) != SVt_PVHV) {
    return 0;
  }

  type_ref_hv = (HV *)SvRV(type_ref_sv);
  kind_svp = hv_fetch(type_ref_hv, "kind", 4, 0);
  return kind_svp && SvOK(*kind_svp) && SvPOK(*kind_svp) && strEQ(SvPV_nolen(*kind_svp), "NON_NULL");
}

static void
gql_validation_add_possible_object_names(pTHX_ HV *out_hv, SV *compiled_sv, SV *type_name_sv) {
  HV *type_hv = gql_validation_compiled_type_hv(aTHX_ compiled_sv, type_name_sv);
  SV **kind_svp;

  if (!type_hv) {
    return;
  }

  kind_svp = hv_fetch(type_hv, "kind", 4, 0);
  if (!kind_svp || !SvOK(*kind_svp) || !SvPOK(*kind_svp)) {
    return;
  }

  if (strEQ(SvPV_nolen(*kind_svp), "OBJECT")) {
    STRLEN len;
    const char *name = SvPV(type_name_sv, len);
    (void)hv_store(out_hv, name, (I32)len, newSViv(1), 0);
    return;
  }

  if (strEQ(SvPV_nolen(*kind_svp), "INTERFACE") || strEQ(SvPV_nolen(*kind_svp), "UNION")) {
    HV *compiled_hv = gql_validation_compiled_hv_from_sv(compiled_sv);
    SV **possible_types_svp;
    HE *possible_he;
    AV *possible_av;
    I32 i;

    if (!compiled_hv) {
      return;
    }

    possible_types_svp = hv_fetch(compiled_hv, "possible_types", 14, 0);
    if (!possible_types_svp || !SvROK(*possible_types_svp) || SvTYPE(SvRV(*possible_types_svp)) != SVt_PVHV) {
      return;
    }

    possible_he = hv_fetch_ent((HV *)SvRV(*possible_types_svp), type_name_sv, 0, 0);
    if (!possible_he || !SvROK(HeVAL(possible_he)) || SvTYPE(SvRV(HeVAL(possible_he))) != SVt_PVAV) {
      return;
    }

    possible_av = (AV *)SvRV(HeVAL(possible_he));
    for (i = 0; i <= av_len(possible_av); i++) {
      SV **possible_name_svp = av_fetch(possible_av, i, 0);
      if (possible_name_svp && SvOK(*possible_name_svp)) {
        gql_validation_add_possible_object_names(aTHX_ out_hv, compiled_sv, *possible_name_svp);
      }
    }
  }
}

static int
gql_validation_selection_types_overlap(pTHX_ SV *compiled_sv, SV *left_name_sv, SV *right_name_sv) {
  HV *left_objects_hv = newHV();
  int overlap = 0;
  HV *right_objects_hv = newHV();
  HE *he;

  if (!left_name_sv || !right_name_sv || !SvOK(left_name_sv) || !SvOK(right_name_sv)) {
    SvREFCNT_dec((SV *)left_objects_hv);
    SvREFCNT_dec((SV *)right_objects_hv);
    return 0;
  }

  if (sv_eq(left_name_sv, right_name_sv)) {
    SvREFCNT_dec((SV *)left_objects_hv);
    SvREFCNT_dec((SV *)right_objects_hv);
    return 1;
  }

  gql_validation_add_possible_object_names(aTHX_ left_objects_hv, compiled_sv, left_name_sv);
  gql_validation_add_possible_object_names(aTHX_ right_objects_hv, compiled_sv, right_name_sv);

  hv_iterinit(right_objects_hv);
  while ((he = hv_iternext(right_objects_hv))) {
    STRLEN key_len;
    const char *key = HePV(he, key_len);
    if (hv_exists(left_objects_hv, key, (I32)key_len)) {
      overlap = 1;
      break;
    }
  }

  SvREFCNT_dec((SV *)left_objects_hv);
  SvREFCNT_dec((SV *)right_objects_hv);
  return overlap;
}

static void gql_validation_validate_value(
  pTHX_ AV *errors_av,
  SV *schema,
  SV *compiled_sv,
  SV *value_sv,
  SV *expected_type_sv,
  HV *variables_hv,
  SV *location_sv
);

static int
gql_validation_variable_type_is_kind(SV *type_sv, const char *wanted) {
  if (!type_sv || !SvROK(type_sv) || SvTYPE(SvRV(type_sv)) != SVt_PVAV) {
    return 0;
  }
  {
    SV **kind_svp = av_fetch((AV *)SvRV(type_sv), 0, 0);
    return kind_svp && SvOK(*kind_svp) && strEQ(SvPV_nolen(*kind_svp), wanted);
  }
}

static SV *
gql_validation_variable_type_inner(SV *type_sv) {
  SV **wrapper_svp;
  SV **inner_svp;
  if (!type_sv || !SvROK(type_sv) || SvTYPE(SvRV(type_sv)) != SVt_PVAV) {
    return NULL;
  }
  wrapper_svp = av_fetch((AV *)SvRV(type_sv), 1, 0);
  if (!wrapper_svp || !SvROK(*wrapper_svp) || SvTYPE(SvRV(*wrapper_svp)) != SVt_PVHV) {
    return NULL;
  }
  inner_svp = hv_fetch((HV *)SvRV(*wrapper_svp), "type", 4, 0);
  return inner_svp ? *inner_svp : NULL;
}

static int
gql_validation_variable_type_compatible(SV *variable_type, SV *location_type) {
  HV *location_hv;
  SV **kind_svp;
  const char *kind;
  if (!variable_type || !location_type || !SvROK(location_type)
      || SvTYPE(SvRV(location_type)) != SVt_PVHV) {
    return 0;
  }
  location_hv = (HV *)SvRV(location_type);
  kind_svp = hv_fetch(location_hv, "kind", 4, 0);
  if (!kind_svp || !SvOK(*kind_svp)) {
    return 0;
  }
  kind = SvPV_nolen(*kind_svp);
  if (strEQ(kind, "NON_NULL")) {
    SV **of_svp = hv_fetch(location_hv, "of", 2, 0);
    return gql_validation_variable_type_is_kind(variable_type, "non_null")
      && of_svp
      && gql_validation_variable_type_compatible(
        gql_validation_variable_type_inner(variable_type), *of_svp
      );
  }
  if (gql_validation_variable_type_is_kind(variable_type, "non_null")) {
    return gql_validation_variable_type_compatible(
      gql_validation_variable_type_inner(variable_type), location_type
    );
  }
  if (strEQ(kind, "LIST")) {
    SV **of_svp = hv_fetch(location_hv, "of", 2, 0);
    return gql_validation_variable_type_is_kind(variable_type, "list")
      && of_svp
      && gql_validation_variable_type_compatible(
        gql_validation_variable_type_inner(variable_type), *of_svp
      );
  }
  if (gql_validation_variable_type_is_kind(variable_type, "list")) {
    return 0;
  }
  if (strEQ(kind, "NAMED") && !SvROK(variable_type)) {
    SV **name_svp = hv_fetch(location_hv, "name", 4, 0);
    return name_svp && SvOK(*name_svp) && sv_eq(variable_type, *name_svp);
  }
  return 0;
}

static void
gql_validation_validate_nested_variable_position(
  pTHX_ AV *errors_av, SV *value_sv, SV *expected_type_sv,
  HV *variables_hv, int location_has_default, const char *position,
  SV *location_sv
) {
  SV *inner_sv;
  HE *variable_he;
  HV *variable_hv;
  SV **variable_type_svp;
  SV *location_type = expected_type_sv;
  STRLEN name_len;
  const char *name;

  if (!value_sv || !expected_type_sv || !SvROK(value_sv)
      || !SvOK(SvRV(value_sv)) || SvROK(SvRV(value_sv))
      || sv_isobject(value_sv)) {
    return;
  }
  inner_sv = SvRV(value_sv);
  variable_he = variables_hv ? hv_fetch_ent(variables_hv, inner_sv, 0, 0) : NULL;
  if (!variable_he || !SvROK(HeVAL(variable_he))
      || SvTYPE(SvRV(HeVAL(variable_he))) != SVt_PVHV) {
    return;
  }
  variable_hv = (HV *)SvRV(HeVAL(variable_he));
  variable_type_svp = hv_fetch(variable_hv, "type", 4, 0);
  if (gql_validation_type_is_non_null(location_type) && variable_type_svp
      && !gql_validation_variable_type_is_kind(*variable_type_svp, "non_null")) {
    SV **default_svp = hv_fetch(variable_hv, "default_value", 13, 0);
    if ((default_svp && SvOK(*default_svp)) || location_has_default) {
      SV **of_svp = hv_fetch((HV *)SvRV(location_type), "of", 2, 0);
      if (of_svp) {
        location_type = *of_svp;
      }
    }
  }
  if (variable_type_svp
      && gql_validation_variable_type_compatible(*variable_type_svp, location_type)) {
    return;
  }
  name = SvPV(inner_sv, name_len);
  {
    SV *message = newSVpvf(
      "Variable '$%s' cannot be used for %s because its type is incompatible.",
      name, position
    );
    av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
    SvREFCNT_dec(message);
  }
}

static void
gql_validation_validate_arguments(
  pTHX_ AV *errors_av,
  SV *schema,
  SV *compiled_sv,
  HV *arguments_hv,
  HV *argument_defs_hv,
  HV *variables_hv,
  SV *location_sv
) {
  I32 argument_count = 0;
  SV **argument_keys;
  I32 i;

  argument_keys = gql_parser_sorted_hash_keys(aTHX_ arguments_hv, &argument_count);
  if (argument_keys) {
    for (i = 0; i < argument_count; i++) {
      HE *arg_he = hv_fetch_ent(arguments_hv, argument_keys[i], 0, 0);
      HE *def_he = hv_fetch_ent(argument_defs_hv, argument_keys[i], 0, 0);
      if (!def_he) {
        SV *message = newSVpvf("Unknown argument '%s'.", SvPV_nolen(argument_keys[i]));
        av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
        SvREFCNT_dec(message);
        continue;
      }
      if (arg_he && SvROK(HeVAL(def_he)) && SvTYPE(SvRV(HeVAL(def_he))) == SVt_PVHV) {
        SV **type_svp = hv_fetch((HV *)SvRV(HeVAL(def_he)), "type", 4, 0);
        SV *arg_value = HeVAL(arg_he);
        if (type_svp && arg_value && SvROK(arg_value)
            && SvOK(SvRV(arg_value))
            && !SvROK(SvRV(arg_value)) && !sv_isobject(arg_value)) {
          STRLEN variable_name_len;
          const char *variable_name = SvPV(SvRV(arg_value), variable_name_len);
          HE *variable_he = variables_hv
            ? hv_fetch_ent(variables_hv, SvRV(arg_value), 0, 0) : NULL;
          if (variable_he && SvROK(HeVAL(variable_he))
              && SvTYPE(SvRV(HeVAL(variable_he))) == SVt_PVHV) {
            HV *variable_hv = (HV *)SvRV(HeVAL(variable_he));
            SV **variable_type_svp = hv_fetch(variable_hv, "type", 4, 0);
            SV *location_type = *type_svp;
            int compatible;
            if (gql_validation_type_is_non_null(location_type)
                && variable_type_svp
                && !gql_validation_variable_type_is_kind(*variable_type_svp, "non_null")) {
              SV **variable_default_svp = hv_fetch(variable_hv, "default_value", 13, 0);
              SV **location_default_svp = hv_fetch(
                (HV *)SvRV(HeVAL(def_he)), "has_default_value", 17, 0
              );
              if ((variable_default_svp && SvOK(*variable_default_svp))
                  || (location_default_svp && SvTRUE(*location_default_svp))) {
                SV **of_svp = hv_fetch((HV *)SvRV(location_type), "of", 2, 0);
                if (of_svp) {
                  location_type = *of_svp;
                }
              }
            }
            compatible = variable_type_svp
              && gql_validation_variable_type_compatible(*variable_type_svp, location_type);
            if (!compatible) {
              SV *message = newSVpvf(
                "Variable '$%s' cannot be used for argument '%s' because its type is incompatible.",
                variable_name, SvPV_nolen(argument_keys[i])
              );
              av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
              SvREFCNT_dec(message);
            }
          }
        }
        gql_validation_validate_value(
          aTHX_ errors_av,
          schema,
          compiled_sv,
          HeVAL(arg_he),
          type_svp ? *type_svp : NULL,
          variables_hv,
          location_sv
        );
      }
    }
    gql_parser_free_sorted_hash_keys(argument_keys, argument_count);
  }

  argument_keys = gql_parser_sorted_hash_keys(aTHX_ argument_defs_hv, &argument_count);
  if (argument_keys) {
    for (i = 0; i < argument_count; i++) {
      HE *def_he = hv_fetch_ent(argument_defs_hv, argument_keys[i], 0, 0);
      HV *def_hv;
      SV **type_svp;
      SV **has_default_svp;
      if (hv_fetch_ent(arguments_hv, argument_keys[i], 0, 0) || !def_he || !SvROK(HeVAL(def_he)) || SvTYPE(SvRV(HeVAL(def_he))) != SVt_PVHV) {
        continue;
      }
      def_hv = (HV *)SvRV(HeVAL(def_he));
      type_svp = hv_fetch(def_hv, "type", 4, 0);
      has_default_svp = hv_fetch(def_hv, "has_default_value", 17, 0);
      if (type_svp && gql_validation_type_is_non_null(*type_svp)
          && !(has_default_svp && SvOK(*has_default_svp) && SvTRUE(*has_default_svp))) {
        SV *message = newSVpvf("Required argument '%s' was not provided.", SvPV_nolen(argument_keys[i]));
        av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
        SvREFCNT_dec(message);
      }
    }
    gql_parser_free_sorted_hash_keys(argument_keys, argument_count);
  }
}

static void
gql_validation_validate_value(
  pTHX_ AV *errors_av,
  SV *schema,
  SV *compiled_sv,
  SV *value_sv,
  SV *expected_type_sv,
  HV *variables_hv,
  SV *location_sv
) {
  if (!value_sv) {
    return;
  }

  if (!SvOK(value_sv)) {
    if (gql_validation_type_is_non_null(expected_type_sv)) {
      SV *type_name_sv = gql_validation_named_type_name_sv(expected_type_sv);
      SV *message = newSVpvf(
        "Null is not a valid value for non-null type '%s'.",
        type_name_sv && SvOK(type_name_sv) ? SvPV_nolen(type_name_sv) : ""
      );
      av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
      SvREFCNT_dec(message);
    }
    return;
  }

  if (SvROK(value_sv) && SvTYPE(SvRV(value_sv)) == SVt_PVAV) {
    AV *value_av = (AV *)SvRV(value_sv);
    SV *item_type_sv = expected_type_sv;
    SV *list_type_sv = expected_type_sv;
    if (gql_validation_type_is_non_null(list_type_sv)) {
      SV **of_svp = hv_fetch((HV *)SvRV(list_type_sv), "of", 2, 0);
      list_type_sv = of_svp ? *of_svp : NULL;
    }
    if (list_type_sv && SvROK(list_type_sv) && SvTYPE(SvRV(list_type_sv)) == SVt_PVHV) {
      SV **kind_svp = hv_fetch((HV *)SvRV(list_type_sv), "kind", 4, 0);
      if (kind_svp && SvOK(*kind_svp) && SvPOK(*kind_svp) && strEQ(SvPV_nolen(*kind_svp), "LIST")) {
        SV **of_svp = hv_fetch((HV *)SvRV(list_type_sv), "of", 2, 0);
        if (of_svp) {
          item_type_sv = *of_svp;
        }
      } else {
        SV *message = newSVpv("List value is not valid for a non-list type.", 0);
        av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
        SvREFCNT_dec(message);
        return;
      }
    }
    for (I32 i = 0; i <= av_len(value_av); i++) {
      SV **item_svp = av_fetch(value_av, i, 0);
      if (item_svp) {
        gql_validation_validate_nested_variable_position(
          aTHX_ errors_av, *item_svp, item_type_sv, variables_hv, 0,
          "a list item", location_sv
        );
        gql_validation_validate_value(aTHX_ errors_av, schema, compiled_sv, *item_svp, item_type_sv, variables_hv, location_sv);
      }
    }
    return;
  }

  if (SvROK(value_sv) && SvTYPE(SvRV(value_sv)) == SVt_PVHV) {
    HV *value_hv = (HV *)SvRV(value_sv);
    SV *named_type_name_sv = gql_validation_named_type_name_sv(expected_type_sv);
    HV *named_type_hv = gql_validation_compiled_type_hv(aTHX_ compiled_sv, named_type_name_sv);
    SV **kind_svp;
    if (!named_type_hv) {
      return;
    }
    kind_svp = hv_fetch(named_type_hv, "kind", 4, 0);
    if (!kind_svp || !SvOK(*kind_svp) || !SvPOK(*kind_svp) || !strEQ(SvPV_nolen(*kind_svp), "INPUT_OBJECT")) {
      SV *message = newSVpv("Input object value is not valid for a non-input-object type.", 0);
      av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
      SvREFCNT_dec(message);
      return;
    }
    {
      SV **one_of_svp = hv_fetch(named_type_hv, "is_one_of", 9, 0);
      if (one_of_svp && SvOK(*one_of_svp) && SvTRUE(*one_of_svp)) {
        if ((I32)HvUSEDKEYS(value_hv) != 1) {
          SV *message = newSVpvf(
            "OneOf Input Object '%s' must specify exactly one key.",
            named_type_name_sv ? SvPV_nolen(named_type_name_sv) : ""
          );
          av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
          SvREFCNT_dec(message);
        } else {
          HE *entry;
          hv_iterinit(value_hv);
          entry = hv_iternext(value_hv);
          if (entry && (!HeVAL(entry) || !SvOK(HeVAL(entry)))) {
            SV *message = newSVpvf(
              "OneOf Input Object '%s' field '%s' must be non-null.",
              named_type_name_sv ? SvPV_nolen(named_type_name_sv) : "",
              HePV(entry, PL_na)
            );
            av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
            SvREFCNT_dec(message);
          }
        }
      }
    }
    {
      SV **fields_svp = hv_fetch(named_type_hv, "fields", 6, 0);
      HV *fields_hv = (fields_svp && SvROK(*fields_svp) && SvTYPE(SvRV(*fields_svp)) == SVt_PVHV) ? (HV *)SvRV(*fields_svp) : NULL;
      I32 count = 0;
      SV **keys = gql_parser_sorted_hash_keys(aTHX_ value_hv, &count);
      I32 i;
      if (keys) {
        for (i = 0; i < count; i++) {
          HE *field_he = fields_hv ? hv_fetch_ent(fields_hv, keys[i], 0, 0) : NULL;
          HE *value_he = hv_fetch_ent(value_hv, keys[i], 0, 0);
          if (!field_he) {
            SV *message = newSVpvf(
              "Input field '%s' is not defined on type '%s'.",
              SvPV_nolen(keys[i]),
              named_type_name_sv ? SvPV_nolen(named_type_name_sv) : ""
            );
            av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
            SvREFCNT_dec(message);
            continue;
          }
          if (value_he && SvROK(HeVAL(field_he)) && SvTYPE(SvRV(HeVAL(field_he))) == SVt_PVHV) {
            SV **field_type_svp = hv_fetch((HV *)SvRV(HeVAL(field_he)), "type", 4, 0);
            SV **has_default_svp = hv_fetch(
              (HV *)SvRV(HeVAL(field_he)), "has_default_value", 17, 0
            );
            gql_validation_validate_nested_variable_position(
              aTHX_ errors_av, HeVAL(value_he),
              field_type_svp ? *field_type_svp : NULL, variables_hv,
              has_default_svp && SvTRUE(*has_default_svp),
              "an input object field", location_sv
            );
            gql_validation_validate_value(aTHX_ errors_av, schema, compiled_sv, HeVAL(value_he), field_type_svp ? *field_type_svp : NULL, variables_hv, location_sv);
          }
        }
        gql_parser_free_sorted_hash_keys(keys, count);
      }
      if (fields_hv) {
        keys = gql_parser_sorted_hash_keys(aTHX_ fields_hv, &count);
        if (keys) {
          for (i = 0; i < count; i++) {
            HE *field_he = hv_fetch_ent(fields_hv, keys[i], 0, 0);
            HV *field_hv;
            SV **field_type_svp;
            SV **has_default_svp;
            if (hv_fetch_ent(value_hv, keys[i], 0, 0) || !field_he || !SvROK(HeVAL(field_he)) || SvTYPE(SvRV(HeVAL(field_he))) != SVt_PVHV) {
              continue;
            }
            field_hv = (HV *)SvRV(HeVAL(field_he));
            field_type_svp = hv_fetch(field_hv, "type", 4, 0);
            has_default_svp = hv_fetch(field_hv, "has_default_value", 17, 0);
            if (field_type_svp && gql_validation_type_is_non_null(*field_type_svp)
                && !(has_default_svp && SvOK(*has_default_svp) && SvTRUE(*has_default_svp))) {
              SV *message = newSVpvf(
                "Required input field '%s' was not provided for type '%s'.",
                SvPV_nolen(keys[i]),
                named_type_name_sv ? SvPV_nolen(named_type_name_sv) : ""
              );
              av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
              SvREFCNT_dec(message);
            }
          }
          gql_parser_free_sorted_hash_keys(keys, count);
        }
      }
    }
    return;
  }

  if (SvROK(value_sv)) {
    SV *inner_sv = SvRV(value_sv);
    /* A variable reference is an UNBLESSED scalar ref (\'name'). Blessed
     * scalar refs are literals - JSON::PP::Boolean booleans from the
     * parser - and REF-of-ref is the enum literal marker; neither names
     * a variable. */
    if (!SvROK(inner_sv) && !sv_isobject(value_sv)) {
      STRLEN name_len;
      const char *name = SvPV(inner_sv, name_len);
      if ((!variables_hv || !hv_exists(variables_hv, name, (I32)name_len))
          && (!variables_hv
            || !hv_exists(variables_hv, "__defer_fragment_variables", 26))) {
        SV *message = newSVpvf("Variable '$%s' is used but not defined.", name);
        av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
        SvREFCNT_dec(message);
      }
      return;
    }
  }

  /* Built-in literal coercion stays in XS. The parser preserves literal
   * categories in the SV flags (and blesses JSON booleans), so validation
   * does not need a Perl method call per scalar literal. */
  {
    SV *type_name_sv = gql_validation_named_type_name_sv(expected_type_sv);
    const char *type_name = type_name_sv && SvOK(type_name_sv)
      ? SvPV_nolen(type_name_sv) : NULL;
    int valid = 1;
    if (!SvOK(value_sv) || !type_name) {
      return;
    }
    {
      HV *named_type_hv = gql_validation_compiled_type_hv(aTHX_ compiled_sv, type_name_sv);
      SV **kind_svp = named_type_hv ? hv_fetch(named_type_hv, "kind", 4, 0) : NULL;
      if (kind_svp && SvOK(*kind_svp) && SvPOK(*kind_svp)
          && strEQ(SvPV_nolen(*kind_svp), "ENUM")) {
        SV **values_svp = hv_fetch(named_type_hv, "values", 6, 0);
        HV *values_hv = values_svp && SvROK(*values_svp)
          && SvTYPE(SvRV(*values_svp)) == SVt_PVHV
          ? (HV *)SvRV(*values_svp) : NULL;
        valid = 0;
        if (values_hv && SvROK(value_sv) && SvROK(SvRV(value_sv))) {
          SV *enum_name_sv = SvRV(SvRV(value_sv));
          if (!SvROK(enum_name_sv) && SvOK(enum_name_sv)) {
            STRLEN enum_name_len;
            const char *enum_name = SvPV(enum_name_sv, enum_name_len);
            valid = hv_exists(values_hv, enum_name, (I32)enum_name_len);
          }
        }
        if (!valid) {
          SV *message = newSVpvf("Value is not a valid %s literal.", type_name);
          av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
          SvREFCNT_dec(message);
        }
        return;
      }
      if (kind_svp && SvOK(*kind_svp) && SvPOK(*kind_svp)
          && strEQ(SvPV_nolen(*kind_svp), "INPUT_OBJECT")) {
        SV *message = newSVpv("Scalar value is not valid for an input object type.", 0);
        av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
        SvREFCNT_dec(message);
        return;
      }
      if (kind_svp && SvOK(*kind_svp) && SvPOK(*kind_svp)
          && strEQ(SvPV_nolen(*kind_svp), "SCALAR")
          && !strEQ(type_name, "Int") && !strEQ(type_name, "Float")
          && !strEQ(type_name, "String") && !strEQ(type_name, "Boolean")
          && !strEQ(type_name, "ID")) {
        SV **parse_value_svp = hv_fetch(named_type_hv, "parse_value", 11, 0);
        if (parse_value_svp && SvOK(*parse_value_svp)) {
          dSP;
          int count;
          ENTER;
          SAVETMPS;
          sv_setsv(ERRSV, &PL_sv_undef);
          PUSHMARK(SP);
          XPUSHs(value_sv);
          PUTBACK;
          count = call_sv(*parse_value_svp, G_SCALAR | G_EVAL);
          SPAGAIN;
          if (count > 0) {
            (void)POPs;
          }
          PUTBACK;
          if (SvTRUE(ERRSV)) {
            SV *message = newSVpvf(
              "Value is not a valid %s literal: %s",
              type_name, SvPV_nolen(ERRSV)
            );
            av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
            SvREFCNT_dec(message);
          }
          FREETMPS;
          LEAVE;
        }
        return;
      }
    }
    if (strEQ(type_name, "Int")) {
      valid = !SvROK(value_sv) && SvIOK(value_sv)
        && SvIV(value_sv) >= -2147483648LL && SvIV(value_sv) <= 2147483647LL;
    } else if (strEQ(type_name, "Float")) {
      valid = !SvROK(value_sv) && (SvIOK(value_sv) || SvNOK(value_sv));
    } else if (strEQ(type_name, "String")) {
      valid = !SvROK(value_sv) && SvPOK(value_sv)
        && !SvIOK(value_sv) && !SvNOK(value_sv);
    } else if (strEQ(type_name, "Boolean")) {
      valid = sv_isobject(value_sv);
    } else if (strEQ(type_name, "ID")) {
      valid = !SvROK(value_sv) && (SvPOK(value_sv) || SvIOK(value_sv));
    } else {
      return;
    }
    if (!valid) {
      SV *message = newSVpvf("Value is not a valid %s literal.", type_name);
      av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
      SvREFCNT_dec(message);
    }
  }
}

static int
gql_validation_values_equal(pTHX_ SV *left_sv, SV *right_sv) {
  if (left_sv == right_sv) {
    return 1;
  }
  if (!left_sv || !right_sv || SvOK(left_sv) != SvOK(right_sv)) {
    return 0;
  }
  if (!SvOK(left_sv)) {
    return 1;
  }
  if (SvROK(left_sv) != SvROK(right_sv)) {
    return 0;
  }
  if (!SvROK(left_sv)) {
    return sv_eq(left_sv, right_sv);
  }
  if (SvTYPE(SvRV(left_sv)) != SvTYPE(SvRV(right_sv))) {
    return 0;
  }
  if (SvTYPE(SvRV(left_sv)) == SVt_PVAV) {
    AV *left_av = (AV *)SvRV(left_sv);
    AV *right_av = (AV *)SvRV(right_sv);
    I32 i;
    if (av_len(left_av) != av_len(right_av)) {
      return 0;
    }
    for (i = 0; i <= av_len(left_av); i++) {
      SV **left_item = av_fetch(left_av, i, 0);
      SV **right_item = av_fetch(right_av, i, 0);
      if (!gql_validation_values_equal(aTHX_ left_item ? *left_item : NULL, right_item ? *right_item : NULL)) {
        return 0;
      }
    }
    return 1;
  }
  if (SvTYPE(SvRV(left_sv)) == SVt_PVHV) {
    HV *left_hv = (HV *)SvRV(left_sv);
    HV *right_hv = (HV *)SvRV(right_sv);
    HE *he;
    if (HvUSEDKEYS(left_hv) != HvUSEDKEYS(right_hv)) {
      return 0;
    }
    hv_iterinit(left_hv);
    while ((he = hv_iternext(left_hv))) {
      SV *key_sv = hv_iterkeysv(he);
      HE *right_he = hv_fetch_ent(right_hv, key_sv, 0, 0);
      if (!right_he || !gql_validation_values_equal(aTHX_ HeVAL(he), HeVAL(right_he))) {
        return 0;
      }
    }
    return 1;
  }
  return gql_validation_values_equal(aTHX_ SvRV(left_sv), SvRV(right_sv));
}

static void
gql_validation_collect_merge_fields(
  pTHX_ AV *out_av,
  AV *selections_av,
  SV *parent_type_name_sv,
  HV *fragments_hv,
  HV *visited_fragments_hv
) {
  I32 i;
  if (!selections_av) {
    return;
  }
  for (i = 0; i <= av_len(selections_av); i++) {
    SV **selection_svp = av_fetch(selections_av, i, 0);
    HV *selection_hv;
    SV **kind_svp;
    if (!selection_svp || !SvROK(*selection_svp) || SvTYPE(SvRV(*selection_svp)) != SVt_PVHV) {
      continue;
    }
    selection_hv = (HV *)SvRV(*selection_svp);
    kind_svp = hv_fetch(selection_hv, "kind", 4, 0);
    if (!kind_svp || !SvOK(*kind_svp) || !SvPOK(*kind_svp)) {
      continue;
    }
    if (strEQ(SvPV_nolen(*kind_svp), "field")) {
      HV *entry_hv = newHV();
      gql_store_sv(entry_hv, "field", newSVsv(*selection_svp));
      gql_store_sv(entry_hv, "parent_type", newSVsv(parent_type_name_sv));
      av_push(out_av, newRV_noinc((SV *)entry_hv));
      continue;
    }
    if (strEQ(SvPV_nolen(*kind_svp), "inline_fragment")) {
      SV **on_svp = hv_fetch(selection_hv, "on", 2, 0);
      SV **nested_svp = hv_fetch(selection_hv, "selections", 10, 0);
      SV *target_type_sv = on_svp && SvOK(*on_svp) ? *on_svp : parent_type_name_sv;
      if (nested_svp && SvROK(*nested_svp) && SvTYPE(SvRV(*nested_svp)) == SVt_PVAV) {
        gql_validation_collect_merge_fields(
          aTHX_ out_av, (AV *)SvRV(*nested_svp), target_type_sv,
          fragments_hv, visited_fragments_hv
        );
      }
      continue;
    }
    if (strEQ(SvPV_nolen(*kind_svp), "fragment_spread")) {
      SV **name_svp = hv_fetch(selection_hv, "name", 4, 0);
      HE *fragment_he;
      STRLEN name_len;
      const char *name;
      if (!name_svp || !SvOK(*name_svp)) {
        continue;
      }
      name = SvPV(*name_svp, name_len);
      if (hv_exists(visited_fragments_hv, name, (I32)name_len)) {
        continue;
      }
      fragment_he = hv_fetch_ent(fragments_hv, *name_svp, 0, 0);
      if (fragment_he && SvROK(HeVAL(fragment_he)) && SvTYPE(SvRV(HeVAL(fragment_he))) == SVt_PVHV) {
        HV *fragment_hv = (HV *)SvRV(HeVAL(fragment_he));
        SV **on_svp = hv_fetch(fragment_hv, "on", 2, 0);
        SV **nested_svp = hv_fetch(fragment_hv, "selections", 10, 0);
        (void)hv_store_ent(visited_fragments_hv, *name_svp, newSViv(1), 0);
        if (on_svp && SvOK(*on_svp) && nested_svp && SvROK(*nested_svp)
            && SvTYPE(SvRV(*nested_svp)) == SVt_PVAV) {
          gql_validation_collect_merge_fields(
            aTHX_ out_av, (AV *)SvRV(*nested_svp), *on_svp,
            fragments_hv, visited_fragments_hv
          );
        }
      }
    }
  }
}

static SV *
gql_validation_field_type_sv(
  pTHX_ SV *compiled_sv,
  SV *parent_type_name_sv,
  SV *field_name_sv
) {
  HV *parent_hv = gql_validation_compiled_type_hv(aTHX_ compiled_sv, parent_type_name_sv);
  SV **fields_svp = parent_hv ? hv_fetch(parent_hv, "fields", 6, 0) : NULL;
  HE *field_he;
  SV **type_svp;
  if (!fields_svp || !SvROK(*fields_svp) || SvTYPE(SvRV(*fields_svp)) != SVt_PVHV) {
    return NULL;
  }
  field_he = hv_fetch_ent((HV *)SvRV(*fields_svp), field_name_sv, 0, 0);
  if (!field_he || !SvROK(HeVAL(field_he)) || SvTYPE(SvRV(HeVAL(field_he))) != SVt_PVHV) {
    return NULL;
  }
  type_svp = hv_fetch((HV *)SvRV(HeVAL(field_he)), "type", 4, 0);
  return type_svp ? *type_svp : NULL;
}

static int
gql_validation_same_response_shape(pTHX_ SV *compiled_sv, SV *left_type_sv, SV *right_type_sv) {
  HV *left_hv;
  HV *right_hv;
  SV **left_kind_svp;
  SV **right_kind_svp;
  const char *left_kind;
  const char *right_kind;
  if (!left_type_sv || !right_type_sv || !SvROK(left_type_sv) || !SvROK(right_type_sv)
      || SvTYPE(SvRV(left_type_sv)) != SVt_PVHV || SvTYPE(SvRV(right_type_sv)) != SVt_PVHV) {
    return 0;
  }
  left_hv = (HV *)SvRV(left_type_sv);
  right_hv = (HV *)SvRV(right_type_sv);
  left_kind_svp = hv_fetch(left_hv, "kind", 4, 0);
  right_kind_svp = hv_fetch(right_hv, "kind", 4, 0);
  if (!left_kind_svp || !right_kind_svp || !SvOK(*left_kind_svp) || !SvOK(*right_kind_svp)) {
    return 0;
  }
  left_kind = SvPV_nolen(*left_kind_svp);
  right_kind = SvPV_nolen(*right_kind_svp);
  if (strEQ(left_kind, "NON_NULL") || strEQ(right_kind, "NON_NULL")
      || strEQ(left_kind, "LIST") || strEQ(right_kind, "LIST")) {
    SV **left_of_svp;
    SV **right_of_svp;
    if (!strEQ(left_kind, right_kind)) {
      return 0;
    }
    left_of_svp = hv_fetch(left_hv, "of", 2, 0);
    right_of_svp = hv_fetch(right_hv, "of", 2, 0);
    return left_of_svp && right_of_svp
      && gql_validation_same_response_shape(aTHX_ compiled_sv, *left_of_svp, *right_of_svp);
  }
  if (strEQ(left_kind, "NAMED") && strEQ(right_kind, "NAMED")) {
    SV **left_name_svp = hv_fetch(left_hv, "name", 4, 0);
    SV **right_name_svp = hv_fetch(right_hv, "name", 4, 0);
    HV *left_named_hv = left_name_svp
      ? gql_validation_compiled_type_hv(aTHX_ compiled_sv, *left_name_svp) : NULL;
    HV *right_named_hv = right_name_svp
      ? gql_validation_compiled_type_hv(aTHX_ compiled_sv, *right_name_svp) : NULL;
    SV **left_named_kind_svp = left_named_hv ? hv_fetch(left_named_hv, "kind", 4, 0) : NULL;
    SV **right_named_kind_svp = right_named_hv ? hv_fetch(right_named_hv, "kind", 4, 0) : NULL;
    int left_leaf = left_named_kind_svp && SvOK(*left_named_kind_svp)
      && (strEQ(SvPV_nolen(*left_named_kind_svp), "SCALAR")
        || strEQ(SvPV_nolen(*left_named_kind_svp), "ENUM"));
    int right_leaf = right_named_kind_svp && SvOK(*right_named_kind_svp)
      && (strEQ(SvPV_nolen(*right_named_kind_svp), "SCALAR")
        || strEQ(SvPV_nolen(*right_named_kind_svp), "ENUM"));
    if (left_leaf || right_leaf) {
      return left_leaf && right_leaf && left_name_svp && right_name_svp
        && sv_eq(*left_name_svp, *right_name_svp);
    }
    return 1;
  }
  return 0;
}

static void
gql_validation_validate_field_merging(
  pTHX_ AV *errors_av,
  SV *compiled_sv,
  AV *selections_av,
  SV *parent_type_name_sv,
  HV *fragments_hv
) {
  HV *fields_by_key_hv = newHV();
  HV *visited_fragments_hv = newHV();
  AV *fields_av = newAV();
  I32 i;
  gql_validation_collect_merge_fields(
    aTHX_ fields_av, selections_av, parent_type_name_sv,
    fragments_hv, visited_fragments_hv
  );
  for (i = 0; i <= av_len(fields_av); i++) {
    SV **entry_svp = av_fetch(fields_av, i, 0);
    HV *entry_hv;
    SV **selection_svp;
    SV **parent_svp;
    HV *selection_hv;
    SV **name_svp;
    SV **alias_svp;
    SV *response_key_sv;
    HE *previous_he;
    HV *bucket_hv;
    AV *previous_av;
    AV *merge_entries_av;
    I32 j;
    int keep_entry = 1;
    if (!entry_svp || !SvROK(*entry_svp) || SvTYPE(SvRV(*entry_svp)) != SVt_PVHV) {
      continue;
    }
    entry_hv = (HV *)SvRV(*entry_svp);
    selection_svp = hv_fetch(entry_hv, "field", 5, 0);
    parent_svp = hv_fetch(entry_hv, "parent_type", 11, 0);
    if (!selection_svp || !SvROK(*selection_svp) || SvTYPE(SvRV(*selection_svp)) != SVt_PVHV
        || !parent_svp || !SvOK(*parent_svp)) {
      continue;
    }
    selection_hv = (HV *)SvRV(*selection_svp);
    name_svp = hv_fetch(selection_hv, "name", 4, 0);
    alias_svp = hv_fetch(selection_hv, "alias", 5, 0);
    if (!name_svp || !SvOK(*name_svp)) {
      continue;
    }
    response_key_sv = alias_svp && SvOK(*alias_svp) ? *alias_svp : *name_svp;
    previous_he = hv_fetch_ent(fields_by_key_hv, response_key_sv, 0, 0);
    if (!previous_he) {
      bucket_hv = newHV();
      previous_av = newAV();
      merge_entries_av = newAV();
      gql_store_sv(bucket_hv, "entries", newRV_noinc((SV *)previous_av));
      gql_store_sv(bucket_hv, "merge_entries", newRV_noinc((SV *)merge_entries_av));
      (void)hv_store_ent(fields_by_key_hv, response_key_sv, newRV_noinc((SV *)bucket_hv), 0);
    } else {
      SV **entries_svp;
      SV **merge_entries_svp;
      SV **conflicted_svp;
      bucket_hv = (HV *)SvRV(HeVAL(previous_he));
      conflicted_svp = hv_fetch(bucket_hv, "conflicted", 10, 0);
      if (conflicted_svp && SvTRUE(*conflicted_svp)) {
        continue;
      }
      entries_svp = hv_fetch(bucket_hv, "entries", 7, 0);
      merge_entries_svp = hv_fetch(bucket_hv, "merge_entries", 13, 0);
      previous_av = (AV *)SvRV(*entries_svp);
      merge_entries_av = (AV *)SvRV(*merge_entries_svp);
    }
    av_push(merge_entries_av, newSVsv(*entry_svp));
    for (j = 0; j <= av_len(previous_av); j++) {
      SV **previous_svp = av_fetch(previous_av, j, 0);
      HV *previous_entry_hv = (HV *)SvRV(*previous_svp);
      SV **previous_field_svp = hv_fetch(previous_entry_hv, "field", 5, 0);
      SV **previous_parent_svp = hv_fetch(previous_entry_hv, "parent_type", 11, 0);
      HV *previous_hv = (HV *)SvRV(*previous_field_svp);
      SV **previous_name_svp = hv_fetch(previous_hv, "name", 4, 0);
      SV **arguments_svp = hv_fetch(selection_hv, "arguments", 9, 0);
      SV **previous_arguments_svp = hv_fetch(previous_hv, "arguments", 9, 0);
      SV *field_type_sv = gql_validation_field_type_sv(
        aTHX_ compiled_sv, *parent_svp, *name_svp
      );
      SV *previous_field_type_sv = gql_validation_field_type_sv(
        aTHX_ compiled_sv, *previous_parent_svp, *previous_name_svp
      );
      int same_name = previous_name_svp && SvOK(*previous_name_svp)
        && sv_eq(*name_svp, *previous_name_svp);
      int same_arguments = gql_validation_values_equal(
        aTHX_ arguments_svp ? *arguments_svp : NULL,
        previous_arguments_svp ? *previous_arguments_svp : NULL
      );
      int types_overlap = previous_parent_svp && SvOK(*previous_parent_svp)
        && gql_validation_selection_types_overlap(
          aTHX_ compiled_sv, *parent_svp, *previous_parent_svp
        );
      int same_shape = gql_validation_same_response_shape(
        aTHX_ compiled_sv, field_type_sv, previous_field_type_sv
      );
      if (!same_shape || (types_overlap && (!same_name || !same_arguments))) {
        SV **location_svp = hv_fetch(selection_hv, "location", 8, 0);
        SV *message = newSVpvf(
          "Fields '%s' conflict because they select different fields or arguments.",
          SvPV_nolen(response_key_sv)
        );
        av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
        SvREFCNT_dec(message);
        gql_store_sv(bucket_hv, "conflicted", newSViv(1));
        keep_entry = 0;
        break;
      }
      if (same_name && same_arguments && same_shape) {
        if (sv_eq(*parent_svp, *previous_parent_svp)) {
          /* Keep one comparison representative for an identical signature.
           * Composite selections remain in merge_entries and are validated
           * together once at the next depth. */
          keep_entry = 0;
        }
      }
    }
    if (keep_entry) {
      av_push(previous_av, newSVsv(*entry_svp));
    }
  }
  {
    HE *bucket_he;
    hv_iterinit(fields_by_key_hv);
    while ((bucket_he = hv_iternext(fields_by_key_hv))) {
      HV *bucket_hv = (HV *)SvRV(HeVAL(bucket_he));
      SV **conflicted_svp = hv_fetch(bucket_hv, "conflicted", 10, 0);
      SV **entries_svp = hv_fetch(bucket_hv, "merge_entries", 13, 0);
      AV *entries_av;
      AV *combined_av;
      SV *first_named_type_sv = NULL;
      I32 entry_i;
      if ((conflicted_svp && SvTRUE(*conflicted_svp)) || !entries_svp
          || !SvROK(*entries_svp) || SvTYPE(SvRV(*entries_svp)) != SVt_PVAV) {
        continue;
      }
      entries_av = (AV *)SvRV(*entries_svp);
      if (av_len(entries_av) < 1) {
        continue;
      }
      combined_av = newAV();
      for (entry_i = 0; entry_i <= av_len(entries_av); entry_i++) {
        SV **entry_svp = av_fetch(entries_av, entry_i, 0);
        HV *entry_hv;
        SV **field_svp;
        SV **parent_svp;
        HV *field_hv;
        SV **name_svp;
        SV **selections_svp;
        SV *field_type_sv;
        SV *named_type_sv;
        HV *inline_hv;
        if (!entry_svp || !SvROK(*entry_svp) || SvTYPE(SvRV(*entry_svp)) != SVt_PVHV) {
          continue;
        }
        entry_hv = (HV *)SvRV(*entry_svp);
        field_svp = hv_fetch(entry_hv, "field", 5, 0);
        parent_svp = hv_fetch(entry_hv, "parent_type", 11, 0);
        if (!field_svp || !SvROK(*field_svp) || !parent_svp) {
          continue;
        }
        field_hv = (HV *)SvRV(*field_svp);
        name_svp = hv_fetch(field_hv, "name", 4, 0);
        selections_svp = hv_fetch(field_hv, "selections", 10, 0);
        if (!name_svp || !selections_svp || !SvROK(*selections_svp)
            || SvTYPE(SvRV(*selections_svp)) != SVt_PVAV) {
          continue;
        }
        field_type_sv = gql_validation_field_type_sv(
          aTHX_ compiled_sv, *parent_svp, *name_svp
        );
        named_type_sv = gql_validation_named_type_name_sv(field_type_sv);
        if (!named_type_sv) {
          continue;
        }
        if (!first_named_type_sv) {
          first_named_type_sv = named_type_sv;
        }
        inline_hv = newHV();
        gql_store_sv(inline_hv, "kind", newSVpv("inline_fragment", 0));
        gql_store_sv(inline_hv, "on", newSVsv(named_type_sv));
        gql_store_sv(inline_hv, "selections", newSVsv(*selections_svp));
        av_push(combined_av, newRV_noinc((SV *)inline_hv));
      }
      if (av_len(combined_av) >= 1 && first_named_type_sv) {
        gql_validation_validate_field_merging(
          aTHX_ errors_av, compiled_sv, combined_av,
          first_named_type_sv, fragments_hv
        );
      }
      SvREFCNT_dec((SV *)combined_av);
    }
  }
  SvREFCNT_dec((SV *)fields_av);
  SvREFCNT_dec((SV *)visited_fragments_hv);
  SvREFCNT_dec((SV *)fields_by_key_hv);
}

static void gql_validation_validate_selections(
  pTHX_ AV *errors_av,
  SV *schema,
  SV *compiled_sv,
  AV *selections_av,
  SV *parent_type_name_sv,
  HV *variables_hv,
  HV *fragments_hv,
  HV *visited_fragments_hv
);

static void
gql_validation_validate_field_selection(
  pTHX_ AV *errors_av,
  SV *schema,
  SV *compiled_sv,
  HV *selection_hv,
  HV *parent_type_hv,
  HV *variables_hv,
  HV *fragments_hv,
  HV *visited_fragments_hv
) {
  SV **field_name_svp = hv_fetch(selection_hv, "name", 4, 0);
  SV **location_svp = hv_fetch(selection_hv, "location", 8, 0);
  SV **parent_name_svp = hv_fetch(parent_type_hv, "name", 4, 0);
  SV **fields_svp = hv_fetch(parent_type_hv, "fields", 6, 0);
  HE *field_he = NULL;

  if (!field_name_svp || !SvOK(*field_name_svp)) {
    return;
  }

  if (fields_svp && SvROK(*fields_svp) && SvTYPE(SvRV(*fields_svp)) == SVt_PVHV) {
    field_he = hv_fetch_ent((HV *)SvRV(*fields_svp), *field_name_svp, 0, 0);
  }

  if (!field_he) {
    const char *field_name = SvPV_nolen(*field_name_svp);
    int is_meta = strEQ(field_name, "__typename");
    if (!is_meta && (strEQ(field_name, "__schema") || strEQ(field_name, "__type"))) {
      /* __schema / __type exist on the query root only. Their subtrees
       * select over the introspection meta types, which are not part of
       * the compiled type index, so validation stops here (like the
       * __typename leaf) and the introspection executor takes over. */
      HV *compiled_hv = gql_validation_compiled_hv_from_sv(compiled_sv);
      SV **roots_svp = compiled_hv ? hv_fetch(compiled_hv, "roots", 5, 0) : NULL;
      if (roots_svp && SvROK(*roots_svp) && SvTYPE(SvRV(*roots_svp)) == SVt_PVHV) {
        SV **query_root_svp = hv_fetch((HV *)SvRV(*roots_svp), "query", 5, 0);
        is_meta = query_root_svp && SvOK(*query_root_svp)
          && parent_name_svp && SvOK(*parent_name_svp)
          && strEQ(SvPV_nolen(*query_root_svp), SvPV_nolen(*parent_name_svp));
      }
    }
    if (!is_meta) {
      SV *message = newSVpvf(
        "Field '%s' does not exist on type '%s'.",
        field_name,
        (parent_name_svp && SvOK(*parent_name_svp)) ? SvPV_nolen(*parent_name_svp) : ""
      );
      av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
      SvREFCNT_dec(message);
    }
    return;
  }

  if (SvROK(HeVAL(field_he)) && SvTYPE(SvRV(HeVAL(field_he))) == SVt_PVHV) {
    HV *field_hv = (HV *)SvRV(HeVAL(field_he));
    SV **arguments_svp = hv_fetch(selection_hv, "arguments", 9, 0);
    SV **arg_defs_svp = hv_fetch(field_hv, "args", 4, 0);
    HV *arguments_hv = (arguments_svp && SvROK(*arguments_svp) && SvTYPE(SvRV(*arguments_svp)) == SVt_PVHV) ? (HV *)SvRV(*arguments_svp) : newHV();
    HV *arg_defs_hv = (arg_defs_svp && SvROK(*arg_defs_svp) && SvTYPE(SvRV(*arg_defs_svp)) == SVt_PVHV) ? (HV *)SvRV(*arg_defs_svp) : newHV();
    SV **selections_svp = hv_fetch(selection_hv, "selections", 10, 0);
    SV **type_svp = hv_fetch(field_hv, "type", 4, 0);

    gql_validation_validate_arguments(aTHX_ errors_av, schema, compiled_sv, arguments_hv, arg_defs_hv, variables_hv, location_svp ? *location_svp : NULL);
    if ((!arguments_svp || arguments_hv != (HV *)SvRV(*arguments_svp))) {
      SvREFCNT_dec((SV *)arguments_hv);
    }
    if ((!arg_defs_svp || arg_defs_hv != (HV *)SvRV(*arg_defs_svp))) {
      SvREFCNT_dec((SV *)arg_defs_hv);
    }

    if (type_svp) {
      SV *next_type_name_sv = gql_validation_named_type_name_sv(*type_svp);
      HV *next_type_hv = gql_validation_compiled_type_hv(aTHX_ compiled_sv, next_type_name_sv);
      SV **next_kind_svp = next_type_hv ? hv_fetch(next_type_hv, "kind", 4, 0) : NULL;
      int has_selections = selections_svp && SvROK(*selections_svp)
        && SvTYPE(SvRV(*selections_svp)) == SVt_PVAV;
      int is_leaf = next_kind_svp && SvOK(*next_kind_svp) && SvPOK(*next_kind_svp)
        && (strEQ(SvPV_nolen(*next_kind_svp), "SCALAR")
          || strEQ(SvPV_nolen(*next_kind_svp), "ENUM"));
      int is_composite = next_kind_svp && SvOK(*next_kind_svp) && SvPOK(*next_kind_svp)
        && (strEQ(SvPV_nolen(*next_kind_svp), "OBJECT")
          || strEQ(SvPV_nolen(*next_kind_svp), "INTERFACE")
          || strEQ(SvPV_nolen(*next_kind_svp), "UNION"));

      if (is_leaf && has_selections) {
        SV *message = newSVpvf(
          "Field '%s' must not have a selection since type '%s' has no subfields.",
          SvPV_nolen(*field_name_svp),
          next_type_name_sv ? SvPV_nolen(next_type_name_sv) : ""
        );
        av_push(errors_av, gql_validation_error(
          aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL
        ));
        SvREFCNT_dec(message);
      } else if (is_composite && !has_selections) {
        SV *message = newSVpvf(
          "Field '%s' of type '%s' must have a selection of subfields.",
          SvPV_nolen(*field_name_svp),
          next_type_name_sv ? SvPV_nolen(next_type_name_sv) : ""
        );
        av_push(errors_av, gql_validation_error(
          aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL
        ));
        SvREFCNT_dec(message);
      }

      if (has_selections && next_type_name_sv && !is_leaf) {
        gql_validation_validate_selections(
          aTHX_ errors_av,
          schema,
          compiled_sv,
          (AV *)SvRV(*selections_svp),
          next_type_name_sv,
          variables_hv,
          fragments_hv,
          visited_fragments_hv
        );
      }
    }
  }
}

static void
gql_validation_validate_selections(
  pTHX_ AV *errors_av,
  SV *schema,
  SV *compiled_sv,
  AV *selections_av,
  SV *parent_type_name_sv,
  HV *variables_hv,
  HV *fragments_hv,
  HV *visited_fragments_hv
) {
  HV *parent_type_hv = gql_validation_compiled_type_hv(aTHX_ compiled_sv, parent_type_name_sv);
  I32 i;

  if (!parent_type_hv || !selections_av) {
    return;
  }

  gql_validation_validate_field_merging(
    aTHX_ errors_av, compiled_sv, selections_av,
    parent_type_name_sv, fragments_hv
  );

  for (i = 0; i <= av_len(selections_av); i++) {
    SV **selection_svp = av_fetch(selections_av, i, 0);
    HV *selection_hv;
    SV **kind_svp;
    if (!selection_svp || !SvROK(*selection_svp) || SvTYPE(SvRV(*selection_svp)) != SVt_PVHV) {
      continue;
    }
    selection_hv = (HV *)SvRV(*selection_svp);
    kind_svp = hv_fetch(selection_hv, "kind", 4, 0);
    if (!kind_svp || !SvOK(*kind_svp) || !SvPOK(*kind_svp)) {
      continue;
    }
    if (strEQ(SvPV_nolen(*kind_svp), "field")) {
      gql_validation_validate_field_selection(aTHX_ errors_av, schema, compiled_sv, selection_hv, parent_type_hv, variables_hv, fragments_hv, visited_fragments_hv);
      continue;
    }
    if (strEQ(SvPV_nolen(*kind_svp), "fragment_spread")) {
      SV **name_svp = hv_fetch(selection_hv, "name", 4, 0);
      SV **location_svp = hv_fetch(selection_hv, "location", 8, 0);
      HE *fragment_he = name_svp ? hv_fetch_ent(fragments_hv, *name_svp, 0, 0) : NULL;
      if (!fragment_he) {
        if (name_svp && SvOK(*name_svp)) {
          SV *message = newSVpvf("Unknown fragment '%s'.", SvPV_nolen(*name_svp));
          av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
          SvREFCNT_dec(message);
        }
        continue;
      }
      if (SvROK(HeVAL(fragment_he)) && SvTYPE(SvRV(HeVAL(fragment_he))) == SVt_PVHV) {
        HV *fragment_hv = (HV *)SvRV(HeVAL(fragment_he));
        SV **on_svp = hv_fetch(fragment_hv, "on", 2, 0);
        if (on_svp && SvOK(*on_svp) && gql_validation_compiled_type_hv(aTHX_ compiled_sv, *on_svp)
            && !gql_validation_selection_types_overlap(aTHX_ compiled_sv, parent_type_name_sv, *on_svp)) {
          SV *message = newSVpvf(
            "Fragment '%s' cannot be spread here because type '%s' can never apply to '%s'.",
            name_svp ? SvPV_nolen(*name_svp) : "",
            SvPV_nolen(*on_svp),
            SvPV_nolen(parent_type_name_sv)
          );
          av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
          SvREFCNT_dec(message);
        }
        if (visited_fragments_hv && name_svp && SvOK(*name_svp)) {
          STRLEN name_len;
          const char *name = SvPV(*name_svp, name_len);
          if (!hv_exists(visited_fragments_hv, name, (I32)name_len)) {
            SV **fragment_selections_svp = hv_fetch(fragment_hv, "selections", 10, 0);
            (void)hv_store(visited_fragments_hv, name, (I32)name_len, newSViv(1), 0);
            if (on_svp && SvOK(*on_svp) && fragment_selections_svp
                && SvROK(*fragment_selections_svp)
                && SvTYPE(SvRV(*fragment_selections_svp)) == SVt_PVAV) {
              AV *fragment_errors_av = newAV();
              I32 error_i;
              gql_validation_validate_selections(
                aTHX_ fragment_errors_av, schema, compiled_sv,
                (AV *)SvRV(*fragment_selections_svp), *on_svp,
                variables_hv, fragments_hv, visited_fragments_hv
              );
              for (error_i = 0; error_i <= av_len(fragment_errors_av); error_i++) {
                SV **error_svp = av_fetch(fragment_errors_av, error_i, 0);
                SV **message_svp;
                if (!error_svp || !SvROK(*error_svp)
                    || SvTYPE(SvRV(*error_svp)) != SVt_PVHV) {
                  continue;
                }
                message_svp = hv_fetch((HV *)SvRV(*error_svp), "message", 7, 0);
                if (message_svp && SvOK(*message_svp) && SvCUR(*message_svp) >= 11
                    && strnEQ(SvPV_nolen(*message_svp), "Variable '$", 11)) {
                  av_push(errors_av, newSVsv(*error_svp));
                }
              }
              SvREFCNT_dec((SV *)fragment_errors_av);
            }
          }
        }
      }
      continue;
    }
    if (strEQ(SvPV_nolen(*kind_svp), "inline_fragment")) {
      SV **on_svp = hv_fetch(selection_hv, "on", 2, 0);
      SV **nested_svp = hv_fetch(selection_hv, "selections", 10, 0);
      SV **location_svp = hv_fetch(selection_hv, "location", 8, 0);
      SV *target_type_name_sv = (on_svp && SvOK(*on_svp)) ? *on_svp : parent_type_name_sv;
      if (!gql_validation_compiled_type_hv(aTHX_ compiled_sv, target_type_name_sv)) {
        SV *message = newSVpvf("Inline fragment references unknown type '%s'.", SvPV_nolen(target_type_name_sv));
        av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
        SvREFCNT_dec(message);
        continue;
      }
      if (!gql_validation_selection_types_overlap(aTHX_ compiled_sv, parent_type_name_sv, target_type_name_sv)) {
        SV *message = newSVpvf(
          "Inline fragment on '%s' cannot be used where type '%s' is expected.",
          SvPV_nolen(target_type_name_sv),
          SvPV_nolen(parent_type_name_sv)
        );
        av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
        SvREFCNT_dec(message);
        continue;
      }
      if (nested_svp && SvROK(*nested_svp) && SvTYPE(SvRV(*nested_svp)) == SVt_PVAV) {
        gql_validation_validate_selections(aTHX_ errors_av, schema, compiled_sv, (AV *)SvRV(*nested_svp), target_type_name_sv, variables_hv, fragments_hv, visited_fragments_hv);
      }
    }
  }
}

static void
gql_validation_validate_variable_definitions(
  pTHX_ AV *errors_av,
  SV *schema,
  SV *compiled_sv,
  HV *variables_hv,
  SV *location_sv
) {
  I32 count = 0;
  SV **keys = gql_parser_sorted_hash_keys(aTHX_ variables_hv, &count);
  I32 i;

  if (!keys) {
    return;
  }

  for (i = 0; i < count; i++) {
    HE *he = hv_fetch_ent(variables_hv, keys[i], 0, 0);
    SV *type_sv = NULL;
    int has_error = 0;
    if (!he) {
      continue;
    }
    type_sv = gql_validation_lookup_type_sv(aTHX_ schema, HeVAL(he));
    if (SvTRUE(ERRSV)) {
      has_error = 1;
      sv_setsv(ERRSV, &PL_sv_undef);
    }
    if (has_error || !type_sv || !SvOK(type_sv)) {
      SV *message = newSVpvf("Variable '$%s' has an invalid type.", SvPV_nolen(keys[i]));
      av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
      SvREFCNT_dec(message);
      if (type_sv) {
        SvREFCNT_dec(type_sv);
      }
      continue;
    }
    {
      /* Role::Tiny provides DOES as an installed method, which C-level
       * sv_does (UNIVERSAL isa semantics) never dispatches - it reported
       * every Houtou type as non-input. Call the DOES method instead. */
      int is_input = gql_schema_does_role(aTHX_ type_sv, "GraphQL::Houtou::Role::Input")
        || gql_schema_does_role(aTHX_ type_sv, "GraphQL::Role::Input");
      if (!is_input) {
        dSP;
        int count_call;
        SV *type_string_sv;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVsv(type_sv)));
        PUTBACK;
        count_call = call_method("to_string", G_SCALAR);
        SPAGAIN;
        type_string_sv = count_call == 1 ? newSVsv(POPs) : newSVpv("", 0);
        PUTBACK;
        FREETMPS;
        LEAVE;
        {
          SV *message = newSVpvf(
            "Variable '$%s' is type '%s' which cannot be used as an input type.",
            SvPV_nolen(keys[i]),
            SvPV_nolen(type_string_sv)
          );
          av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_sv));
          SvREFCNT_dec(message);
        }
        SvREFCNT_dec(type_string_sv);
      } else if (SvROK(HeVAL(he)) && SvTYPE(SvRV(HeVAL(he))) == SVt_PVHV) {
        HV *variable_hv = (HV *)SvRV(HeVAL(he));
        SV **default_svp = hv_fetch(variable_hv, "default_value", 13, 0);
        if (default_svp) {
          SV *compiled_type_sv = gql_schema_compile_type_ref(aTHX_ type_sv);
          gql_validation_validate_value(
            aTHX_ errors_av, schema, compiled_sv, *default_svp,
            compiled_type_sv, NULL, location_sv
          );
          SvREFCNT_dec(compiled_type_sv);
        }
      }
    }
    SvREFCNT_dec(type_sv);
  }

  gql_parser_free_sorted_hash_keys(keys, count);
}

static void
gql_validation_validate_fragments(pTHX_ AV *errors_av, SV *compiled_sv, HV *fragments_hv) {
  I32 count = 0;
  SV **keys = gql_parser_sorted_hash_keys(aTHX_ fragments_hv, &count);
  I32 i;
  if (!keys) {
    return;
  }
  for (i = 0; i < count; i++) {
    HE *fragment_he = hv_fetch_ent(fragments_hv, keys[i], 0, 0);
    HV *fragment_hv;
    SV **on_svp;
    HV *type_hv;
    SV **kind_svp;
    if (!fragment_he || !SvROK(HeVAL(fragment_he)) || SvTYPE(SvRV(HeVAL(fragment_he))) != SVt_PVHV) {
      continue;
    }
    fragment_hv = (HV *)SvRV(HeVAL(fragment_he));
    on_svp = hv_fetch(fragment_hv, "on", 2, 0);
    type_hv = on_svp ? gql_validation_compiled_type_hv(aTHX_ compiled_sv, *on_svp) : NULL;
    if (!type_hv) {
      SV **location_svp = hv_fetch(fragment_hv, "location", 8, 0);
      SV *message = newSVpvf(
        "Fragment '%s' references unknown type '%s'.",
        SvPV_nolen(keys[i]),
        (on_svp && SvOK(*on_svp)) ? SvPV_nolen(*on_svp) : ""
      );
      av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
      SvREFCNT_dec(message);
      continue;
    }
    kind_svp = hv_fetch(type_hv, "kind", 4, 0);
    if (kind_svp && SvOK(*kind_svp) && SvPOK(*kind_svp)
        && !strEQ(SvPV_nolen(*kind_svp), "OBJECT")
        && !strEQ(SvPV_nolen(*kind_svp), "INTERFACE")
        && !strEQ(SvPV_nolen(*kind_svp), "UNION")) {
      SV **location_svp = hv_fetch(fragment_hv, "location", 8, 0);
      SV *message = newSVpvf(
        "Fragment '%s' cannot target non-composite type '%s'.",
        SvPV_nolen(keys[i]),
        (on_svp && SvOK(*on_svp)) ? SvPV_nolen(*on_svp) : ""
      );
      av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
      SvREFCNT_dec(message);
      continue;
    }
    {
      SV **selections_svp = hv_fetch(fragment_hv, "selections", 10, 0);
      if (selections_svp && SvROK(*selections_svp) && SvTYPE(SvRV(*selections_svp)) == SVt_PVAV) {
        HV *deferred_variables_hv = newHV();
        (void)hv_store(
          deferred_variables_hv, "__defer_fragment_variables", 26, newSViv(1), 0
        );
        gql_validation_validate_selections(
          aTHX_ errors_av, NULL, compiled_sv,
          (AV *)SvRV(*selections_svp), *on_svp,
          deferred_variables_hv, fragments_hv, NULL
        );
        SvREFCNT_dec((SV *)deferred_variables_hv);
      }
    }
  }
  gql_parser_free_sorted_hash_keys(keys, count);
}

static void
gql_validation_validate_operation(
  pTHX_ AV *errors_av,
  SV *schema,
  SV *compiled_sv,
  HV *operation_hv,
  HV *fragments_hv
) {
  HV *compiled_hv = gql_validation_compiled_hv_from_sv(compiled_sv);
  SV **operation_type_svp = hv_fetch(operation_hv, "operationType", 13, 0);
  const char *operation_type = (operation_type_svp && SvOK(*operation_type_svp)) ? SvPV_nolen(*operation_type_svp) : "query";
  SV **roots_svp = compiled_hv ? hv_fetch(compiled_hv, "roots", 5, 0) : NULL;
  SV *root_type_name_sv = NULL;
  HV *variables_hv = NULL;

  if (roots_svp && SvROK(*roots_svp) && SvTYPE(SvRV(*roots_svp)) == SVt_PVHV) {
    SV **root_type_svp = hv_fetch((HV *)SvRV(*roots_svp), operation_type, (I32)strlen(operation_type), 0);
    if (root_type_svp) {
      root_type_name_sv = *root_type_svp;
    }
  }

  if (!root_type_name_sv || !SvOK(root_type_name_sv)) {
    SV **location_svp = hv_fetch(operation_hv, "location", 8, 0);
    SV *message = newSVpvf("Schema does not define a root type for '%s'.", operation_type);
    av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
    SvREFCNT_dec(message);
    return;
  }

  {
    SV **variables_svp = hv_fetch(operation_hv, "variables", 9, 0);
    if (variables_svp && SvROK(*variables_svp) && SvTYPE(SvRV(*variables_svp)) == SVt_PVHV) {
      variables_hv = (HV *)SvRV(*variables_svp);
      gql_validation_validate_variable_definitions(
        aTHX_ errors_av,
        schema,
        compiled_sv,
        variables_hv,
        (hv_fetch(operation_hv, "location", 8, 0) ? *hv_fetch(operation_hv, "location", 8, 0) : NULL)
      );
    }
  }

  {
    SV **selections_svp = hv_fetch(operation_hv, "selections", 10, 0);
    if (selections_svp && SvROK(*selections_svp) && SvTYPE(SvRV(*selections_svp)) == SVt_PVAV) {
      HV *visited_fragments_hv = newHV();
      gql_validation_validate_selections(
        aTHX_ errors_av, schema, compiled_sv,
        (AV *)SvRV(*selections_svp), root_type_name_sv,
        variables_hv, fragments_hv, visited_fragments_hv
      );
      SvREFCNT_dec((SV *)visited_fragments_hv);
    }
  }
}

static SV *
gql_validation_compiled_directives_sv(SV *compiled_sv) {
  HV *compiled_hv = gql_validation_compiled_hv_from_sv(compiled_sv);
  SV **directives_svp = compiled_hv ? hv_fetch(compiled_hv, "directives", 10, 0) : NULL;
  return directives_svp ? *directives_svp : NULL;
}

static int
gql_validation_directive_has_location(HV *directive_hv, const char *location) {
  SV **locations_svp = hv_fetch(directive_hv, "locations", 9, 0);
  I32 i;
  if (!locations_svp || !SvROK(*locations_svp) || SvTYPE(SvRV(*locations_svp)) != SVt_PVAV) {
    return 0;
  }
  for (i = 0; i <= av_len((AV *)SvRV(*locations_svp)); i++) {
    SV **item_svp = av_fetch((AV *)SvRV(*locations_svp), i, 0);
    if (item_svp && SvOK(*item_svp) && strEQ(SvPV_nolen(*item_svp), location)) {
      return 1;
    }
  }
  return 0;
}

static int
gql_validation_value_contains_variable(SV *value_sv) {
  if (!value_sv || !SvROK(value_sv)) return 0;
  if (SvTYPE(SvRV(value_sv)) == SVt_PVAV) {
    AV *value_av = (AV *)SvRV(value_sv);
    I32 i;
    for (i = 0; i <= av_len(value_av); i++) {
      SV **item_svp = av_fetch(value_av, i, 0);
      if (item_svp && gql_validation_value_contains_variable(*item_svp)) return 1;
    }
    return 0;
  }
  if (SvTYPE(SvRV(value_sv)) == SVt_PVHV) {
    HV *value_hv = (HV *)SvRV(value_sv);
    HE *he;
    hv_iterinit(value_hv);
    while ((he = hv_iternext(value_hv))) {
      if (gql_validation_value_contains_variable(HeVAL(he))) return 1;
    }
    return 0;
  }
  return !SvROK(SvRV(value_sv)) && !sv_isobject(value_sv);
}

static void
gql_validation_validate_directive_list(
  pTHX_ AV *errors_av, SV *compiled_sv, SV *directives_sv,
  const char *location, HV *variables_hv, int validate_structure
) {
  SV *compiled_directives_sv = gql_validation_compiled_directives_sv(compiled_sv);
  HV *compiled_directives_hv;
  AV *directives_av;
  HV *seen_hv;
  I32 i;
  if (!directives_sv || !SvROK(directives_sv) || SvTYPE(SvRV(directives_sv)) != SVt_PVAV
      || !compiled_directives_sv || !SvROK(compiled_directives_sv)
      || SvTYPE(SvRV(compiled_directives_sv)) != SVt_PVHV) {
    return;
  }
  directives_av = (AV *)SvRV(directives_sv);
  compiled_directives_hv = (HV *)SvRV(compiled_directives_sv);
  seen_hv = newHV();
  for (i = 0; i <= av_len(directives_av); i++) {
    SV **directive_svp = av_fetch(directives_av, i, 0);
    HV *directive_hv;
    SV **name_svp;
    SV **location_svp;
    HE *def_he;
    HV *def_hv;
    STRLEN name_len;
    const char *name;
    if (!directive_svp || !SvROK(*directive_svp) || SvTYPE(SvRV(*directive_svp)) != SVt_PVHV) continue;
    directive_hv = (HV *)SvRV(*directive_svp);
    name_svp = hv_fetch(directive_hv, "name", 4, 0);
    location_svp = hv_fetch(directive_hv, "location", 8, 0);
    if (!name_svp || !SvOK(*name_svp)) continue;
    name = SvPV(*name_svp, name_len);
    def_he = hv_fetch_ent(compiled_directives_hv, *name_svp, 0, 0);
    if (!def_he || !SvROK(HeVAL(def_he)) || SvTYPE(SvRV(HeVAL(def_he))) != SVt_PVHV) {
      if (validate_structure) {
        SV *message = newSVpvf("Unknown directive '@%s'.", name);
        av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
        SvREFCNT_dec(message);
      }
      continue;
    }
    def_hv = (HV *)SvRV(HeVAL(def_he));
    if (validate_structure && !gql_validation_directive_has_location(def_hv, location)) {
      SV *message = newSVpvf("Directive '@%s' may not be used on %s.", name, location);
      av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
      SvREFCNT_dec(message);
    }
    {
      SV **repeatable_svp = hv_fetch(def_hv, "repeatable", 10, 0);
      if (validate_structure && hv_exists(seen_hv, name, (I32)name_len) && !(repeatable_svp && SvTRUE(*repeatable_svp))) {
        SV *message = newSVpvf("Directive '@%s' is not repeatable and cannot be used more than once at this location.", name);
        av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
        SvREFCNT_dec(message);
      }
      (void)hv_store(seen_hv, name, (I32)name_len, newSViv(1), 0);
    }
    {
      SV **arguments_svp = hv_fetch(directive_hv, "arguments", 9, 0);
      SV **arg_defs_svp = hv_fetch(def_hv, "args", 4, 0);
      HV *arguments_hv = arguments_svp && SvROK(*arguments_svp) ? (HV *)SvRV(*arguments_svp) : NULL;
      HV *arg_defs_hv = arg_defs_svp && SvROK(*arg_defs_svp) ? (HV *)SvRV(*arg_defs_svp) : NULL;
      I32 count = 0;
      SV **keys;
      I32 j;
      if (!arg_defs_hv) continue;
      if (validate_structure && arguments_hv) {
        keys = gql_parser_sorted_hash_keys(aTHX_ arguments_hv, &count);
        for (j = 0; keys && j < count; j++) {
          if (!hv_fetch_ent(arg_defs_hv, keys[j], 0, 0)) {
            SV *message = newSVpvf("Unknown argument '%s' on directive '@%s'.", SvPV_nolen(keys[j]), name);
            av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
            SvREFCNT_dec(message);
          }
        }
        gql_parser_free_sorted_hash_keys(keys, count);
      }
      keys = gql_parser_sorted_hash_keys(aTHX_ arg_defs_hv, &count);
      for (j = 0; keys && j < count; j++) {
        HE *arg_he = hv_fetch_ent(arg_defs_hv, keys[j], 0, 0);
        HV *arg_hv = arg_he && SvROK(HeVAL(arg_he)) ? (HV *)SvRV(HeVAL(arg_he)) : NULL;
        HE *value_he = arguments_hv ? hv_fetch_ent(arguments_hv, keys[j], 0, 0) : NULL;
        SV **type_svp = arg_hv ? hv_fetch(arg_hv, "type", 4, 0) : NULL;
        SV **default_svp = arg_hv ? hv_fetch(arg_hv, "has_default_value", 17, 0) : NULL;
        if (validate_structure && !value_he && type_svp && gql_validation_type_is_non_null(*type_svp)
            && !(default_svp && SvTRUE(*default_svp))) {
          SV *message = newSVpvf("Required argument '%s' was not provided to directive '@%s'.", SvPV_nolen(keys[j]), name);
          av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
          SvREFCNT_dec(message);
        } else if (value_he && type_svp) {
          SV *directive_value_sv = HeVAL(value_he);
          int contains_variable = gql_validation_value_contains_variable(directive_value_sv);
          AV *value_errors_av;
          if ((!validate_structure && !contains_variable)
              || (!variables_hv && contains_variable)) {
            continue;
          }
          gql_validation_validate_nested_variable_position(
            aTHX_ errors_av, directive_value_sv, *type_svp, variables_hv,
            default_svp && SvTRUE(*default_svp), "a directive argument",
            location_svp ? *location_svp : NULL
          );
          value_errors_av = newAV();
          gql_validation_validate_value(aTHX_ value_errors_av, NULL, compiled_sv, directive_value_sv, *type_svp, variables_hv, location_svp ? *location_svp : NULL);
          if (av_len(value_errors_av) >= 0) {
            if (contains_variable) {
              I32 error_i;
              for (error_i = 0; error_i <= av_len(value_errors_av); error_i++) {
                SV **value_error_svp = av_fetch(value_errors_av, error_i, 0);
                if (value_error_svp) av_push(errors_av, newSVsv(*value_error_svp));
              }
              SvREFCNT_dec((SV *)value_errors_av);
              continue;
            }
            SV *named_type_sv = gql_validation_named_type_name_sv(*type_svp);
            const char *type_name = named_type_sv && SvOK(named_type_sv) ? SvPV_nolen(named_type_sv) : "value";
            SV *message;
            if (strEQ(type_name, "Int") || strEQ(type_name, "Float")
                || strEQ(type_name, "String") || strEQ(type_name, "Boolean")
                || strEQ(type_name, "ID")) {
              message = newSVpvf(
                "Argument '%s' on directive '@%s' has invalid value: Not a %s.",
                SvPV_nolen(keys[j]), name, type_name
              );
            } else {
              SV **first_error_svp = av_fetch(value_errors_av, 0, 0);
              SV **first_message_svp = first_error_svp && SvROK(*first_error_svp)
                ? hv_fetch((HV *)SvRV(*first_error_svp), "message", 7, 0) : NULL;
              message = newSVpvf(
                "Argument '%s' on directive '@%s' has invalid value: %s",
                SvPV_nolen(keys[j]), name,
                first_message_svp ? SvPV_nolen(*first_message_svp) : "invalid value"
              );
            }
            av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL));
            SvREFCNT_dec(message);
          }
          SvREFCNT_dec((SV *)value_errors_av);
        }
      }
      gql_parser_free_sorted_hash_keys(keys, count);
    }
  }
  SvREFCNT_dec((SV *)seen_hv);
}

static void
gql_validation_validate_directives_in_selections(
  pTHX_ AV *errors_av, SV *compiled_sv, AV *selections_av,
  HV *variables_hv, HV *fragments_hv, HV *visited_fragments_hv,
  int validate_structure
) {
  I32 i;
  for (i = 0; selections_av && i <= av_len(selections_av); i++) {
    SV **selection_svp = av_fetch(selections_av, i, 0);
    HV *selection_hv;
    SV **kind_svp;
    SV **directives_svp;
    SV **nested_svp;
    const char *location;
    if (!selection_svp || !SvROK(*selection_svp) || SvTYPE(SvRV(*selection_svp)) != SVt_PVHV) continue;
    selection_hv = (HV *)SvRV(*selection_svp);
    kind_svp = hv_fetch(selection_hv, "kind", 4, 0);
    if (!kind_svp || !SvOK(*kind_svp)) continue;
    location = strEQ(SvPV_nolen(*kind_svp), "field") ? "FIELD"
      : strEQ(SvPV_nolen(*kind_svp), "fragment_spread") ? "FRAGMENT_SPREAD"
      : "INLINE_FRAGMENT";
    directives_svp = hv_fetch(selection_hv, "directives", 10, 0);
    gql_validation_validate_directive_list(aTHX_ errors_av, compiled_sv, directives_svp ? *directives_svp : NULL, location, variables_hv, validate_structure);
    if (strEQ(SvPV_nolen(*kind_svp), "fragment_spread")
        && fragments_hv && visited_fragments_hv && variables_hv) {
      SV **name_svp = hv_fetch(selection_hv, "name", 4, 0);
      if (name_svp && SvOK(*name_svp)) {
        STRLEN name_len;
        const char *name = SvPV(*name_svp, name_len);
        if (!hv_exists(visited_fragments_hv, name, (I32)name_len)) {
          HE *fragment_he = hv_fetch_ent(fragments_hv, *name_svp, 0, 0);
          (void)hv_store(visited_fragments_hv, name, (I32)name_len, newSViv(1), 0);
          if (fragment_he && SvROK(HeVAL(fragment_he)) && SvTYPE(SvRV(HeVAL(fragment_he))) == SVt_PVHV) {
            SV **fragment_selections_svp = hv_fetch((HV *)SvRV(HeVAL(fragment_he)), "selections", 10, 0);
            if (fragment_selections_svp && SvROK(*fragment_selections_svp)
                && SvTYPE(SvRV(*fragment_selections_svp)) == SVt_PVAV) {
              gql_validation_validate_directives_in_selections(
                aTHX_ errors_av, compiled_sv, (AV *)SvRV(*fragment_selections_svp),
                variables_hv, fragments_hv, visited_fragments_hv, 0
              );
            }
          }
        }
      }
    }
    nested_svp = hv_fetch(selection_hv, "selections", 10, 0);
    if (nested_svp && SvROK(*nested_svp) && SvTYPE(SvRV(*nested_svp)) == SVt_PVAV)
      gql_validation_validate_directives_in_selections(
        aTHX_ errors_av, compiled_sv, (AV *)SvRV(*nested_svp),
        variables_hv, fragments_hv, visited_fragments_hv, validate_structure
      );
  }
}

static void
gql_validation_validate_document_directives(
  pTHX_ AV *errors_av, SV *compiled_sv, AV *ast_av, HV *fragments_hv
) {
  I32 i;
  for (i = 0; i <= av_len(ast_av); i++) {
    SV **node_svp = av_fetch(ast_av, i, 0);
    HV *node_hv;
    SV **kind_svp;
    SV **directives_svp;
    SV **selections_svp;
    HV *variables_hv = NULL;
    const char *location;
    HV *visited_fragments_hv = NULL;
    if (!node_svp || !SvROK(*node_svp) || SvTYPE(SvRV(*node_svp)) != SVt_PVHV) continue;
    node_hv = (HV *)SvRV(*node_svp);
    kind_svp = hv_fetch(node_hv, "kind", 4, 0);
    if (!kind_svp || !SvOK(*kind_svp)) continue;
    if (strEQ(SvPV_nolen(*kind_svp), "operation")) {
      SV **operation_type_svp = hv_fetch(node_hv, "operationType", 13, 0);
      SV **variables_svp = hv_fetch(node_hv, "variables", 9, 0);
      location = operation_type_svp && SvOK(*operation_type_svp)
        && strEQ(SvPV_nolen(*operation_type_svp), "mutation") ? "MUTATION"
        : operation_type_svp && SvOK(*operation_type_svp)
          && strEQ(SvPV_nolen(*operation_type_svp), "subscription") ? "SUBSCRIPTION"
          : "QUERY";
      if (variables_svp && SvROK(*variables_svp)) variables_hv = (HV *)SvRV(*variables_svp);
      visited_fragments_hv = newHV();
      if (variables_hv) {
        HE *variable_he;
        hv_iterinit(variables_hv);
        while ((variable_he = hv_iternext(variables_hv))) {
          SV *variable_sv = HeVAL(variable_he);
          if (variable_sv && SvROK(variable_sv) && SvTYPE(SvRV(variable_sv)) == SVt_PVHV) {
            SV **variable_directives_svp = hv_fetch((HV *)SvRV(variable_sv), "directives", 10, 0);
            gql_validation_validate_directive_list(
              aTHX_ errors_av, compiled_sv,
              variable_directives_svp ? *variable_directives_svp : NULL,
              "VARIABLE_DEFINITION", variables_hv, 1
            );
          }
        }
      }
    } else {
      location = "FRAGMENT_DEFINITION";
    }
    directives_svp = hv_fetch(node_hv, "directives", 10, 0);
    gql_validation_validate_directive_list(aTHX_ errors_av, compiled_sv, directives_svp ? *directives_svp : NULL, location, variables_hv, 1);
    selections_svp = hv_fetch(node_hv, "selections", 10, 0);
    if (selections_svp && SvROK(*selections_svp) && SvTYPE(SvRV(*selections_svp)) == SVt_PVAV)
      gql_validation_validate_directives_in_selections(
        aTHX_ errors_av, compiled_sv, (AV *)SvRV(*selections_svp),
        variables_hv, fragments_hv, visited_fragments_hv, 1
      );
    if (visited_fragments_hv) SvREFCNT_dec((SV *)visited_fragments_hv);
  }
}

static int
gql_validation_type_is_list(SV *type_sv) {
  HV *type_hv;
  SV **kind_svp;
  if (!type_sv || !SvROK(type_sv) || SvTYPE(SvRV(type_sv)) != SVt_PVHV) {
    return 0;
  }
  type_hv = (HV *)SvRV(type_sv);
  kind_svp = hv_fetch(type_hv, "kind", 4, 0);
  if (!kind_svp || !SvOK(*kind_svp) || !SvPOK(*kind_svp)) {
    return 0;
  }
  if (strEQ(SvPV_nolen(*kind_svp), "LIST")) {
    return 1;
  }
  if (strEQ(SvPV_nolen(*kind_svp), "NON_NULL")) {
    SV **of_svp = hv_fetch(type_hv, "of", 2, 0);
    return of_svp ? gql_validation_type_is_list(*of_svp) : 0;
  }
  return 0;
}

static UV
gql_validation_cost_add(UV total, UV add, UV max_cost) {
  return add > max_cost - total ? max_cost + 1 : total + add;
}

static UV gql_validation_selection_cost(
  pTHX_ SV *compiled_sv, AV *selections_av, SV *parent_type_name_sv,
  HV *fragments_hv, HV *visited_hv, UV default_list_size, UV max_cost
);

static UV
gql_validation_selection_cost(
  pTHX_ SV *compiled_sv, AV *selections_av, SV *parent_type_name_sv,
  HV *fragments_hv, HV *visited_hv, UV default_list_size, UV max_cost
) {
  HV *parent_type_hv = gql_validation_compiled_type_hv(aTHX_ compiled_sv, parent_type_name_sv);
  SV **fields_svp = parent_type_hv ? hv_fetch(parent_type_hv, "fields", 6, 0) : NULL;
  HV *fields_hv = fields_svp && SvROK(*fields_svp)
    && SvTYPE(SvRV(*fields_svp)) == SVt_PVHV ? (HV *)SvRV(*fields_svp) : NULL;
  UV total = 0;
  I32 i;

  for (i = 0; i <= av_len(selections_av); i++) {
    SV **selection_svp = av_fetch(selections_av, i, 0);
    HV *selection_hv;
    SV **kind_svp;
    if (!selection_svp || !SvROK(*selection_svp)
        || SvTYPE(SvRV(*selection_svp)) != SVt_PVHV) {
      continue;
    }
    selection_hv = (HV *)SvRV(*selection_svp);
    kind_svp = hv_fetch(selection_hv, "kind", 4, 0);
    if (!kind_svp || !SvOK(*kind_svp) || !SvPOK(*kind_svp)) {
      continue;
    }

    if (strEQ(SvPV_nolen(*kind_svp), "field")) {
      SV **name_svp = hv_fetch(selection_hv, "name", 4, 0);
      HE *field_he = name_svp && fields_hv
        ? hv_fetch_ent(fields_hv, *name_svp, 0, 0) : NULL;
      UV own_cost = 1;
      UV multiplier = 1;
      UV child_cost = 0;
      int is_list = 0;
      if (field_he && SvROK(HeVAL(field_he))
          && SvTYPE(SvRV(HeVAL(field_he))) == SVt_PVHV) {
        HV *field_hv = (HV *)SvRV(HeVAL(field_he));
        SV **cost_svp = hv_fetch(field_hv, "cost", 4, 0);
        SV **type_svp = hv_fetch(field_hv, "type", 4, 0);
        SV **nested_svp = hv_fetch(selection_hv, "selections", 10, 0);
        if (cost_svp && SvOK(*cost_svp)) {
          own_cost = SvUV(*cost_svp);
        }
        if (type_svp && gql_validation_type_is_list(*type_svp)) {
          SV **list_size_svp = hv_fetch(field_hv, "list_size", 9, 0);
          multiplier = list_size_svp && SvOK(*list_size_svp)
            ? SvUV(*list_size_svp) : default_list_size;
          is_list = 1;
        }
        if (type_svp && nested_svp && SvROK(*nested_svp)
            && SvTYPE(SvRV(*nested_svp)) == SVt_PVAV) {
          SV *child_type_name_sv = gql_validation_named_type_name_sv(*type_svp);
          child_cost = gql_validation_selection_cost(
            aTHX_ compiled_sv, (AV *)SvRV(*nested_svp), child_type_name_sv,
            fragments_hv, visited_hv, default_list_size, max_cost
          );
        }
        if (is_list && child_cost == 0) {
          /* A scalar/enum list still serializes each result item. Charge one
           * unit per estimated item even though it has no sub-selection. */
          child_cost = 1;
        }
      }
      total = gql_validation_cost_add(total, own_cost, max_cost);
      if (total > max_cost) return total;
      if (child_cost) {
        if (multiplier > (max_cost - total) / child_cost) return max_cost + 1;
        total += multiplier * child_cost;
      }
      if (total > max_cost) return total;
      continue;
    }

    if (strEQ(SvPV_nolen(*kind_svp), "inline_fragment")) {
      SV **nested_svp = hv_fetch(selection_hv, "selections", 10, 0);
      SV **on_svp = hv_fetch(selection_hv, "on", 2, 0);
      if (nested_svp && SvROK(*nested_svp) && SvTYPE(SvRV(*nested_svp)) == SVt_PVAV) {
        UV nested_cost = gql_validation_selection_cost(
          aTHX_ compiled_sv, (AV *)SvRV(*nested_svp),
          on_svp && SvOK(*on_svp) ? *on_svp : parent_type_name_sv,
          fragments_hv, visited_hv, default_list_size, max_cost
        );
        total = gql_validation_cost_add(total, nested_cost, max_cost);
        if (total > max_cost) return total;
      }
      continue;
    }

    if (strEQ(SvPV_nolen(*kind_svp), "fragment_spread")) {
      SV **name_svp = hv_fetch(selection_hv, "name", 4, 0);
      HE *fragment_he;
      STRLEN name_len;
      const char *name;
      if (!name_svp || !SvOK(*name_svp)) continue;
      name = SvPV(*name_svp, name_len);
      if (hv_exists(visited_hv, name, (I32)name_len)) continue;
      fragment_he = hv_fetch_ent(fragments_hv, *name_svp, 0, 0);
      if (fragment_he && SvROK(HeVAL(fragment_he))
          && SvTYPE(SvRV(HeVAL(fragment_he))) == SVt_PVHV) {
        HV *fragment_hv = (HV *)SvRV(HeVAL(fragment_he));
        SV **nested_svp = hv_fetch(fragment_hv, "selections", 10, 0);
        SV **on_svp = hv_fetch(fragment_hv, "on", 2, 0);
        (void)hv_store(visited_hv, name, (I32)name_len, newSViv(1), 0);
        if (nested_svp && SvROK(*nested_svp) && SvTYPE(SvRV(*nested_svp)) == SVt_PVAV) {
          UV nested_cost = gql_validation_selection_cost(
            aTHX_ compiled_sv, (AV *)SvRV(*nested_svp),
            on_svp && SvOK(*on_svp) ? *on_svp : parent_type_name_sv,
            fragments_hv, visited_hv, default_list_size, max_cost
          );
          total = gql_validation_cost_add(total, nested_cost, max_cost);
        }
        (void)hv_delete(visited_hv, name, (I32)name_len, G_DISCARD);
        if (total > max_cost) return total;
      }
    }
  }
  return total;
}

static SV *
gql_validation_check_cost(pTHX_ SV *schema, SV *document, SV *options) {
  AV *errors_av = newAV();
  SV *ast_sv;
  SV *compiled_sv;
  AV *ast_av;
  HV *fragments_hv;
  HV *options_hv;
  SV **max_cost_svp;
  SV **default_list_size_svp;
  SV **operation_name_svp;
  UV max_cost;
  UV default_list_size = 10;
  I32 i;

  if (!options || !SvROK(options) || SvTYPE(SvRV(options)) != SVt_PVHV) {
    croak("query cost options must be a hash reference");
  }
  options_hv = (HV *)SvRV(options);
  max_cost_svp = hv_fetch(options_hv, "max_cost", 8, 0);
  if (!max_cost_svp || !SvOK(*max_cost_svp) || !SvIOK(*max_cost_svp)
      || SvIV(*max_cost_svp) < 0) {
    croak("max_cost must be a non-negative integer");
  }
  max_cost = SvUV(*max_cost_svp);
  default_list_size_svp = hv_fetch(options_hv, "default_list_size", 17, 0);
  if (default_list_size_svp) {
    if (!SvIOK(*default_list_size_svp) || SvIV(*default_list_size_svp) < 1) {
      croak("default_list_size must be a positive integer");
    }
    default_list_size = SvUV(*default_list_size_svp);
  }
  operation_name_svp = hv_fetch(options_hv, "operation_name", 14, 0);

  ast_sv = document && SvROK(document)
    ? newSVsv(document)
    : gql_parse_document(aTHX_ document, &PL_sv_undef);
  compiled_sv = gql_schema_compile_schema(aTHX_ schema);
  ast_av = (AV *)SvRV(ast_sv);
  fragments_hv = gql_validation_build_fragments_map(aTHX_ ast_av);
  for (i = 0; i <= av_len(ast_av); i++) {
    SV **node_svp = av_fetch(ast_av, i, 0);
    HV *node_hv;
    SV **kind_svp;
    SV **operation_type_svp;
    HV *compiled_hv;
    SV **roots_svp;
    SV **root_svp;
    SV **selections_svp;
    HV *visited_hv;
    UV cost;
    if (!node_svp || !SvROK(*node_svp) || SvTYPE(SvRV(*node_svp)) != SVt_PVHV) continue;
    node_hv = (HV *)SvRV(*node_svp);
    kind_svp = hv_fetch(node_hv, "kind", 4, 0);
    if (!kind_svp || !SvOK(*kind_svp) || !strEQ(SvPV_nolen(*kind_svp), "operation")) continue;
    if (operation_name_svp && SvOK(*operation_name_svp)) {
      SV **name_svp = hv_fetch(node_hv, "name", 4, 0);
      if (!name_svp || !SvOK(*name_svp)
          || !sv_eq(*name_svp, *operation_name_svp)) continue;
    }
    operation_type_svp = hv_fetch(node_hv, "operationType", 13, 0);
    compiled_hv = gql_validation_compiled_hv_from_sv(compiled_sv);
    roots_svp = compiled_hv ? hv_fetch(compiled_hv, "roots", 5, 0) : NULL;
    root_svp = roots_svp && SvROK(*roots_svp) && SvTYPE(SvRV(*roots_svp)) == SVt_PVHV
      ? hv_fetch((HV *)SvRV(*roots_svp),
          operation_type_svp && SvOK(*operation_type_svp) ? SvPV_nolen(*operation_type_svp) : "query",
          operation_type_svp && SvOK(*operation_type_svp) ? (I32)SvCUR(*operation_type_svp) : 5, 0)
      : NULL;
    selections_svp = hv_fetch(node_hv, "selections", 10, 0);
    if (!root_svp || !selections_svp || !SvROK(*selections_svp)
        || SvTYPE(SvRV(*selections_svp)) != SVt_PVAV) continue;
    visited_hv = newHV();
    cost = gql_validation_selection_cost(
      aTHX_ compiled_sv, (AV *)SvRV(*selections_svp), *root_svp,
      fragments_hv, visited_hv, default_list_size, max_cost
    );
    SvREFCNT_dec((SV *)visited_hv);
    if (cost > max_cost) {
      SV **name_svp = hv_fetch(node_hv, "name", 4, 0);
      SV *message = newSVpvf(
        "Query cost exceeds maximum of %" UVuf " in %s operation",
        max_cost, name_svp && SvOK(*name_svp) ? SvPV_nolen(*name_svp) : "anonymous"
      );
      av_push(errors_av, gql_validation_error(aTHX_ SvPV_nolen(message), NULL));
      SvREFCNT_dec(message);
    }
  }
  SvREFCNT_dec((SV *)fragments_hv);
  SvREFCNT_dec(ast_sv);
  SvREFCNT_dec(compiled_sv);
  return newRV_noinc((SV *)errors_av);
}

static SV *
gql_validation_validate(pTHX_ SV *schema, SV *document, SV *options) {
  AV *errors_av = newAV();
  SV *ast_sv = gql_validation_parse_ast(aTHX_ document, options, errors_av);
  SV *compiled_sv = gql_schema_compile_schema(aTHX_ schema);
  AV *operations_av = newAV();
  HV *fragments_hv;
  AV *operation_errors_av = newAV();
  AV *fragment_cycle_errors_av = newAV();
  AV *ast_av;
  I32 ast_len;
  I32 i;
  SV *ret;

  if (!SvROK(ast_sv) || SvTYPE(SvRV(ast_sv)) != SVt_PVAV) {
    SvREFCNT_dec(ast_sv);
    SvREFCNT_dec(compiled_sv);
    croak("Validation AST must be an array reference");
  }

  ast_av = (AV *)SvRV(ast_sv);
  ast_len = av_len(ast_av);
  if (ast_len >= 0) {
    av_extend(operations_av, ast_len);
  }

  for (i = 0; i <= ast_len; i++) {
    SV **node_svp = av_fetch(ast_av, i, 0);
    HV *node_hv;
    SV **kind_svp;

    if (!node_svp || !SvROK(*node_svp) || SvTYPE(SvRV(*node_svp)) != SVt_PVHV) {
      continue;
    }

    node_hv = (HV *)SvRV(*node_svp);
    kind_svp = hv_fetch(node_hv, "kind", 4, 0);
    if (!kind_svp || !SvOK(*kind_svp) || !SvPOK(*kind_svp)) {
      continue;
    }

    if (!strEQ(SvPV_nolen(*kind_svp), "operation")
        && !strEQ(SvPV_nolen(*kind_svp), "fragment")) {
      SV **location_svp = hv_fetch(node_hv, "location", 8, 0);
      SV *message = newSVpvf(
        "The '%s' definition is not executable.", SvPV_nolen(*kind_svp)
      );
      av_push(
        errors_av,
        gql_validation_error(aTHX_ SvPV_nolen(message), location_svp ? *location_svp : NULL)
      );
      SvREFCNT_dec(message);
      continue;
    }

    if (!strEQ(SvPV_nolen(*kind_svp), "operation")) {
      continue;
    }

    av_push(operations_av, newSVsv(*node_svp));
  }

  fragments_hv = gql_validation_build_fragments_map(aTHX_ ast_av);
  gql_validation_push_operation_errors(aTHX_ errors_av, operations_av);
  gql_validation_push_fragment_name_errors(aTHX_ errors_av, ast_av);
  gql_validation_push_usage_errors(aTHX_ errors_av, ast_av, operations_av, fragments_hv);
  gql_validation_push_subscription_errors(aTHX_ operation_errors_av, operations_av, fragments_hv);
  gql_validation_push_fragment_cycle_errors(aTHX_ fragment_cycle_errors_av, fragments_hv);
  gql_validation_validate_fragments(aTHX_ errors_av, compiled_sv, fragments_hv);
  gql_validation_validate_document_directives(aTHX_ errors_av, compiled_sv, ast_av, fragments_hv);

  {
    I32 fragment_len = av_len(fragment_cycle_errors_av);
    for (i = 0; i <= fragment_len; i++) {
      SV **err_svp = av_fetch(fragment_cycle_errors_av, i, 0);
      if (err_svp && SvOK(*err_svp)) {
        av_push(errors_av, newSVsv(*err_svp));
      }
    }
  }

  for (i = 0; i <= av_len(operations_av); i++) {
    SV **operation_svp = av_fetch(operations_av, i, 0);
    if (operation_svp && SvROK(*operation_svp) && SvTYPE(SvRV(*operation_svp)) == SVt_PVHV) {
      SV **seed_svp = av_fetch(operation_errors_av, i, 0);
      if (seed_svp && SvROK(*seed_svp) && SvTYPE(SvRV(*seed_svp)) == SVt_PVAV) {
        AV *seed_av = (AV *)SvRV(*seed_svp);
        I32 j;
        for (j = 0; j <= av_len(seed_av); j++) {
          SV **err_svp = av_fetch(seed_av, j, 0);
          if (err_svp && SvOK(*err_svp)) {
            av_push(errors_av, newSVsv(*err_svp));
          }
        }
      }
      gql_validation_validate_operation(aTHX_ errors_av, schema, compiled_sv, (HV *)SvRV(*operation_svp), fragments_hv);
    }
  }

  ret = newRV_noinc((SV *)errors_av);

  SvREFCNT_dec((SV *)operations_av);
  SvREFCNT_dec((SV *)fragments_hv);
  SvREFCNT_dec((SV *)operation_errors_av);
  SvREFCNT_dec((SV *)fragment_cycle_errors_av);
  SvREFCNT_dec(ast_sv);
  SvREFCNT_dec(compiled_sv);

  return ret;
}
