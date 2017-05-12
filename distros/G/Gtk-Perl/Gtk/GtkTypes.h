
/* Copyright (C) 1997-1999 Kenneth Albanowski.
   This code may be distributed under the same terms as Perl itself. */

#ifndef _Gtk_Types_h_
#define _Gtk_Types_h_

#ifndef PerlGtkDeclareFunc
#include "PerlGtkInt.h"
#endif

#if (GTK_MAJOR_VERSION < 1) || ((GTK_MAJOR_VERSION == 1) && (GTK_MINOR_VERSION < 1))
# define GTK_1_0
#else
# define GTK_1_1
#endif

typedef gchar * gstring;

struct PerlGtkTypeHelper {
	SV * (*GtkGetArg_f)(GtkArg *);
	int (*GtkSetArg_f)(GtkArg * a, SV * v, SV * Class, GtkObject * Object);
	int (*GtkSetRetArg_f)(GtkArg * a, SV * v, SV * Class, GtkObject * Object);
	SV * (*GtkGetRetArg_f)(GtkArg * a);
	int (*GtkFreeArg_f)(GtkArg *);
	
	struct PerlGtkTypeHelper * next;
};

struct PerlGtkSignalHelper {
	GtkType type;
	char ** signals;
	int (*Unpacker_f)(SV ** * _sp, int match, GtkObject * object, char * signame, guint nparams, GtkArg * args, GtkType * arg_types, GtkType return_type);
	int (*Repacker_f)(SV ** * _sp, int count, int match, GtkObject * object, char * signame, guint nparams, GtkArg * args, GtkType * arg_types, GtkType return_type);
	
	struct PerlGtkSignalHelper * next;
};

PerlGtkDeclareVar(struct PerlGtkTypeHelper *, PerlGtkTypeHelpers);
PerlGtkDeclareFunc(void, AddTypeHelper)(struct PerlGtkTypeHelper * h);

PerlGtkDeclareVar(struct PerlGtkSignalHelper *, PerlGtkSignalHelpers);
PerlGtkDeclareFunc(void, AddSignalHelper)(struct PerlGtkSignalHelper * h);
PerlGtkDeclareFunc(void, AddSignalHelperParts)(GtkType type, char ** names, void * unpacker, void * repacker);

PerlGtkDeclareFunc(SV *, GtkGetArg)(GtkArg *);
PerlGtkDeclareFunc(void, GtkSetArg)(GtkArg * a, SV * v, SV * Class, GtkObject * Object);
PerlGtkDeclareFunc(void, GtkSetRetArg)(GtkArg * a, SV * v, SV * Class, GtkObject * Object);
PerlGtkDeclareFunc(SV *, GtkGetRetArg)(GtkArg * a);

PerlGtkDeclareVar(int, pgtk_did_we_init_gdk);
PerlGtkDeclareVar(int, pgtk_did_we_init_gtk);
PerlGtkDeclareFunc(void, GtkInit_internal)(void);

typedef GtkMenuFactory * Gtk__MenuFactory;
typedef GtkSelectionData * Gtk__SelectionData;

typedef GtkWidget * Gtk__Widget_Up;
typedef GtkWidget * Gtk__Widget_Sink_Up;
typedef GtkWidget * Gtk__Widget_OrNULL_Up;

#define CastupGtk__Widget GTK_WIDGET

typedef GtkObject * Gtk__Object_Up;
typedef GtkObject * Gtk__Object_Sink_Up;
typedef GtkObject * Gtk__Object_OrNULL_Up;

#define CastupGtk__Object GTK_OBJECT

PerlGtkDeclareFunc(SV *, newSVGtkObjectRef)(GtkObject * object, char * classname);
PerlGtkDeclareFunc(GtkObject *, SvGtkObjectRef)(SV * o, char * name);

PerlGtkDeclareFunc(SV *, newSVGtkMenuEntry)(GtkMenuEntry * o);
PerlGtkDeclareFunc(GtkMenuEntry *, SvGtkMenuEntry)(SV * o, GtkMenuEntry * e);

PerlGtkDeclareFunc(SV *, newSVGtkSelectionDataRef)(GtkSelectionData * o);
PerlGtkDeclareFunc(GtkSelectionData *, SvGtkSelectionDataRef)(SV * data);

PerlGtkDeclareFunc(int, GCGtkObjects)(void);

PerlGtkDeclareFunc(void, FreeHVObject)(HV * hv_object);

typedef guint (*gtkTypeInitFunc)(void);

PerlGtkDeclareFunc(void, pgtk_link_types)(char * gtkName, char * perlName, int gtkTypeNumber, gtkTypeInitFunc init);
PerlGtkDeclareFunc(int, gtnumber_for_ptname)(char * name);
PerlGtkDeclareFunc(int, gtnumber_for_gtname)(char * name);
PerlGtkDeclareFunc(char *, ptname_for_gtnumber)(int number);
PerlGtkDeclareFunc(char *, gtname_for_ptname)(char * name);
PerlGtkDeclareFunc(char *, ptname_for_gtname)(char * name);
PerlGtkDeclareFunc(int, pgtk_class_size_for_gtname)(char * gtkTypeName);
PerlGtkDeclareFunc(int, pgtk_obj_size_for_gtname)(char * gtkTypeName);

PerlGtkDeclareFunc(GtkType, FindArgumentTypeWithObject)(GtkObject * object, SV * name, GtkArg * result);
PerlGtkDeclareFunc(GtkType, FindArgumentTypeWithClass)(GtkObjectClass * klass, SV * name, GtkArg * result);

#if GTK_HVER >= 0x010200

PerlGtkDeclareFunc(SV *, newSVGtkTargetEntry)(GtkTargetEntry * o);
PerlGtkDeclareFunc(GtkTargetEntry *, SvGtkTargetEntry)(SV * o);

#endif

#define newSVgchar(x) newSViv(x)
#define Svgchar(x) SvIV(x)

#define newSVgshort(x) newSViv(x)
#define Svgshort(x) SvIV(x)

#define newSVglong(x) newSViv(x)
#define Svglong(x) SvIV(x)

#define newSVgint(x) newSViv(x)
#define Svgint(x) SvIV(x)

#define newSVgboolean(x) newIV(x)
#define Svgboolean(x) SvIV(x)

#define newSVgfloat(x) newSVnv(x)
#define Svgfloat(x) SvNV(x)

#define newSVgdouble(x) newSVnv(x)
#define Svgdouble(x) SvNV(x)

#define newSVguchar(x) newSViv(x)
#define Svguchar(x) SvIV(x)

#define newSVgushort(x) newSViv(x)
#define Svgushort(x) SvIV(x)

#define newSVgulong(x) newSViv(x)
#define Svgulong(x) SvIV(x)

#define newSVguint(x) newSViv(x)
#define Svguint(x) SvIV(x)

#define newSVgint8(x) newSViv(x)
#define Svgint8(x) SvIV(x)

#define newSVgint16(x) newSViv(x)
#define Svgint16(x) SvIV(x)

#define newSVgint32(x) newSViv(x)
#define Svgint32(x) SvIV(x)

#define newSVguint8(x) newSViv(x)
#define Svguint8(x) SvIV(x)

#define newSVguint16(x) newSViv(x)
#define Svguint16(x) SvIV(x)

#define newSVguint32(x) newSViv(x)
#define Svguint32(x) SvIV(x)

#endif /*_Gtk_Types_h_*/

