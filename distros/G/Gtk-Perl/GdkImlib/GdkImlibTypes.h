
#ifndef __GDKIMLIBTYPES_H__
#define __GDKIMLIBTYPES_H__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>
#include <gdk_imlib.h>

#include "GtkDefs.h"

typedef GdkImlibImage * Gtk__Gdk__ImlibImage;
typedef GdkImlibSaveInfo * Gtk__Gdk__Imlib__SaveInfo;
typedef GdkImlibColorModifier * Gtk__Gdk__Imlib__ColorModifier;

PerlGtkDeclareFunc(SV*, newSVGdkImlibImage) (GdkImlibImage * value);
PerlGtkDeclareFunc(GdkImlibImage*, SvGdkImlibImage)(SV * value);
PerlGtkDeclareFunc(SV*, newSVGdkImlibColorModifier)(GdkImlibColorModifier * m);
PerlGtkDeclareFunc(GdkImlibColorModifier*, SvGdkImlibColorModifier)(SV * data);
PerlGtkDeclareFunc(SV*, newSVGdkImlibSaveInfo)(GdkImlibSaveInfo * m);
PerlGtkDeclareFunc(GdkImlibSaveInfo*, SvGdkImlibSaveInfo)(SV * data);


#endif

