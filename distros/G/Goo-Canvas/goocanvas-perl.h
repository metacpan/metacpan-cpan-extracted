/* @(#)goocanvas-perl.h
 */

#ifndef _GOOCANVAS_PERL_H
#define _GOOCANVAS_PERL_H 1

#include "gperl.h"
#include "gtk2perl.h"
#include "cairo-perl.h"
#include "goocanvas.h"

/* FIXME: How to avoid compile error in autogen.h */
#define GooCairoPattern cairo_pattern_t
#define GooCairoMatrix cairo_matrix_t

#include "goocanvas-perl-version.h"
#include "goocanvas-perl-autogen.h"

#define GOOCANVAS_PERL_VALUE_GET(pspec, value)
       

#define GOOCANVAS_PERL_ADD_PROPETIES(narg)                            \
    {                                                                 \
        GValue value = {0, };                                         \
        int i;                                                        \
        if ( 0 != (items-(narg)) % 2 )                                \
            croak ("set method expects name => value pairs "          \
		       "(odd number of arguments detected)");                 \
        for (i = (narg); i < items; i += 2) {                         \
            char *name = SvPV_nolen (ST (i));                         \
            SV *newval = ST (i + 1);                                  \
            GParamSpec *pspec;                                        \
            pspec = g_object_class_find_property(G_OBJECT_GET_CLASS(G_OBJECT(RETVAL)), name); \
            if ( !pspec ) {                                           \
                const char * classname =                              \
                    gperl_object_package_from_type(G_OBJECT_TYPE (G_OBJECT(RETVAL))); \
                if (!classname)                                       \
                    classname = G_OBJECT_TYPE_NAME(G_OBJECT(RETVAL)); \
                croak ("type %s does not support property '%s'",      \
                       classname, name);                              \
            }                                                         \
            g_value_init (&value, G_PARAM_SPEC_VALUE_TYPE (pspec));   \
            gperl_value_from_sv (&value, newval);                     \
            g_object_set_property (G_OBJECT(RETVAL), name, &value);   \
            g_value_unset (&value);                                   \
        }                                                             \
    }
    

#endif /* _GOOCANVAS_PERL_H */

