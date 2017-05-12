SV *call_method__sv(pTHX_ SV *object, char *method);

int call_method__int(pTHX_ SV *object, char *method);

SV *call_method_int__sv(pTHX_ SV *object, char *method, int i);

SV *call_method_sv__sv(pTHX_ SV *object, char *method, SV *arg);

SV *call_sub_sv__sv(pTHX_ char *name, SV *arg);
