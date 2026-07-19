/*
 * Shared parser AST helpers.
 *
 * Responsibility: small AST node constructors and sorted hash-key helpers
 * used by parser/IR/schema code paths. These are not graphqljs compatibility
 * transforms by themselves; they are common utilities that remain in use even
 * as compatibility layers shrink.
 */

static HV *
gql_parser_new_node_hv_sized(const char *kind, I32 keys) {
  HV *hv = newHV();
  if (keys > 1) {
    hv_ksplit(hv, keys);
  }
  gql_store_sv(hv, "kind", newSVpv(kind, 0));
  return hv;
}

static HV *
gql_parser_new_node_hv(const char *kind) {
  return gql_parser_new_node_hv_sized(kind, 1);
}

static SV *
gql_parser_new_node_ref(const char *kind) {
  return newRV_noinc((SV *)gql_parser_new_node_hv(kind));
}

static SV *
gql_parser_new_name_node_sv(pTHX_ SV *value_sv) {
  HV *hv = gql_parser_new_node_hv_sized("Name", 2);
  gql_store_sv(hv, "value", SvREFCNT_inc_simple_NN(value_sv));
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parser_new_named_type_node_sv(pTHX_ SV *value_sv) {
  HV *hv = gql_parser_new_node_hv_sized("NamedType", 2);
  hv_stores(hv, "name", gql_parser_new_name_node_sv(aTHX_ value_sv));
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parser_new_variable_node_sv(pTHX_ SV *value_sv) {
  HV *hv = gql_parser_new_node_hv_sized("Variable", 2);
  hv_stores(hv, "name", gql_parser_new_name_node_sv(aTHX_ value_sv));
  return newRV_noinc((SV *)hv);
}

static int
gql_parser_cmp_sv_ptrs(const void *a, const void *b) {
  SV *const *left = (SV *const *)a;
  SV *const *right = (SV *const *)b;
  STRLEN left_len, right_len;
  const char *left_str = SvPV(*left, left_len);
  const char *right_str = SvPV(*right, right_len);
  STRLEN min_len = left_len < right_len ? left_len : right_len;
  int cmp = memcmp(left_str, right_str, min_len);
  if (cmp != 0) {
    return cmp;
  }
  if (left_len < right_len) {
    return -1;
  }
  if (left_len > right_len) {
    return 1;
  }
  return 0;
}

static SV **
gql_parser_sorted_hash_keys(pTHX_ HV *hv, I32 *count_out) {
  I32 count;
  I32 i = 0;
  HE *he;
  SV **keys;

  *count_out = 0;
  if (!hv) {
    return NULL;
  }

  count = hv_iterinit(hv);
  if (count <= 0) {
    return NULL;
  }

  Newxz(keys, count, SV *);
  hv_iterinit(hv);
  while ((he = hv_iternext(hv))) {
    keys[i++] = newSVsv(hv_iterkeysv(he));
  }
  qsort(keys, count, sizeof(SV *), gql_parser_cmp_sv_ptrs);
  *count_out = count;
  return keys;
}

static void
gql_parser_free_sorted_hash_keys(SV **keys, I32 count) {
  I32 i;
  if (!keys) {
    return;
  }
  for (i = 0; i < count; i++) {
    if (keys[i]) {
      SvREFCNT_dec(keys[i]);
    }
  }
  Safefree(keys);
}
