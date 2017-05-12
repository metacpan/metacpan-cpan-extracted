#ifndef __GUILE_WRAP_H__
#define __GUILE_WRAP_H__

SV * newSVscm (SCM scm);
SCM  newSCMsv (SV *arg, char *type);

#endif
