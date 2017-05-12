
#ifndef _PerlGtk_DERIVED_H_
#define _PerlGtk_DERIVED_H_

#if !defined(LAZY_LOAD) && !defined(NEED_DERIVED)
#define PerlGtk_sv_derived_from(sv,name) sv_derived_from(sv,name)
#endif

#endif
