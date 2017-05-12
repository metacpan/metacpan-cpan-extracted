
/* Copyright (C) 1997, Kenneth Albanowski.
   This code may be distributed under the same terms as Perl itself. */

#ifndef _Gdk_Types_h_
#define _Gdk_Types_h_

#ifndef PerlGtkDeclareFunc
#include "PerlGtkInt.h"
#endif
   
typedef GdkGC * Gtk__Gdk__GC;
typedef GdkGCValues * Gtk__Gdk__GCValues;
typedef GdkDeviceInfo * Gtk__Gdk__DeviceInfo;
typedef GdkTimeCoord * Gtk__Gdk__TimeCoord;
typedef GdkImage * Gtk__Gdk__Image;
typedef GdkImage * Gtk__Gdk__Image_OrNULL;

typedef GdkRegion * Gtk__Gdk__Region;
typedef GdkRectangle * Gtk__Gdk__Rectangle;
typedef GdkAtom Gtk__Gdk__Atom;
typedef GdkGCValuesMask Gtk__Gdk__ValuesMask;
typedef GdkGCValues Gtk__Gdk__Values;

PerlGtkDeclareFunc(SV *, newSVGdkGCValues)(GdkGCValues * v);
PerlGtkDeclareFunc(GdkGCValues *, SvGdkGCValues)(SV * data, GdkGCValues * v, GdkGCValuesMask * m);

PerlGtkDeclareFunc(SV *, newSVGdkDeviceInfo)(GdkDeviceInfo * i);
PerlGtkDeclareFunc(SV *, newSVGdkTimeCoord)(GdkTimeCoord * i);

PerlGtkDeclareFunc(SV *, newSVGdkRectangle)(GdkRectangle * rect);
PerlGtkDeclareFunc(GdkRectangle *, SvGdkRectangle)(SV * data, GdkRectangle * rect);
PerlGtkDeclareFunc(SV *, newSVGdkAtom)(GdkAtom a);
PerlGtkDeclareFunc(GdkAtom, SvGdkAtom)(SV * data);
PerlGtkDeclareFunc(SV *, newSVGdkRegion)(GdkRegion * e);
PerlGtkDeclareFunc(GdkRegion *, SvGdkRegion)(SV * data);
PerlGtkDeclareFunc(GdkWindowAttr *, SvGdkWindowAttr)(SV * data, GdkWindowAttr * attr, gint * mask);

#define newSVGdkImage(data) newSVMiscRef((void*)data, "Gtk::Gdk::Image", 0)
#define SvGdkImage(data) (GdkImage*)SvMiscRef(data,0)

PerlGtkDeclareFunc(SV *, newSVGdkWindow)(GdkWindow * value);
PerlGtkDeclareFunc(GdkWindow *, SvGdkWindow)(SV * value);

#if GTK_HVER > 0x010200

typedef GdkGeometry* Gtk__Gdk__Geometry;
PerlGtkDeclareFunc(GdkGeometry *, SvGdkGeometry)(SV * value);

PerlGtkDeclareFunc(GdkDragContext *, SvGdkDragContextRef)(SV * value);
PerlGtkDeclareFunc(SV *, newSVGdkDragContextRef)(GdkDragContext * e);

#endif

#endif /*_Gdk_Types_h_*/

