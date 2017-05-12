
void savestate_vars(pTHX_ pMY_CXT);
AV *get_cells(pTHX_ pMY_CXT);
AV *get_vars(pTHX_ pMY_CXT);
void clear_vars(pTHX_ pMY_CXT);
void cut_anonymous_vars(pTHX_ pMY_CXT);
SV *get_var(pTHX_ pMY_CXT_ SV *name);
void set_vars(pTHX_ pMY_CXT_ AV *refs, AV *cells);
