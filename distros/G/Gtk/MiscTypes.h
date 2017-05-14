
/* Copyright (C) 1997, Kenneth Albanowski.
   This code may be distributed under the same terms as Perl itself. */
   

void UnregisterMisc(HV * hv_object, void * misc_object);
void RegisterMisc(HV * hv_object, void * misc_object);
HV * RetrieveMisc(void * gtk_object);

SV * newSVMiscRef(void * object, char * classname, int * newref);
void * SvMiscRef(SV * o, char * classname);

struct opts { int value; char * name; };

void CroakOpts(char * name, char * value, struct opts * o);
long SvOpt(SV * name, char * optname, struct opts * o);
SV * newSVOpt(long value, char * optname, struct opts * o);

long SvOptFlags(SV * name, char * optname, struct opts * o);
SV * newSVOptFlags(long value, char * optname, struct opts * o, int hash);

long SvOptsHash(SV * name, char * optname, HV * o);
SV * newSVOptsHash(long value, char * optname, HV * o);
long SvFlagsHash(SV * name, char * optname, HV * o);
SV * newSVFlagsHash(long value, char * optname, HV * o, int hash);

void * alloc_temp(int length);
