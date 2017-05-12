


int pl_unify_perl_sv(pTHX_ term_t t, SV *sv, AV *refs, AV *cells);
int pl_unify_perl_av(pTHX_ term_t t, AV *array, int u, AV *refs, AV *cells);

int perl2swi_module(pTHX_ SV *sv, module_t *m);
int perl2swi_new_atom(pTHX_ SV *sv, atom_t *a);
