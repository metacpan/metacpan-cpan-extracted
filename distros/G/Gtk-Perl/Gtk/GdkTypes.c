#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Copyright (C) 1997, Kenneth Albanowski.
   This code may be distributed under the same terms as Perl itself. */

#if !defined(PERLIO_IS_STDIO) && defined(HASATTRIBUTE)
# undef printf
#endif
    
#include <gdk/gdk.h>
#include <gtk/gtk.h>

#if !defined(PERLIO_IS_STDIO) && defined(HASATTRIBUTE)
# define printf PerlIO_stdoutf
#endif

#include "PerlGtkInt.h"
#include "MiscTypes.h"
#include "GdkTypes.h"
#include "GtkTypes.h"
#include "GtkDefs.h"

SV * newSVGdkBitmap(GdkBitmap * x) { return newSVGdkWindow(x); }
GdkBitmap * SvGdkBitmap(SV * x) { return SvGdkWindow(x); }
SV * newSVGdkPixmap(GdkPixmap * x) { return newSVGdkWindow(x); }
GdkPixmap * SvGdkPixmap(SV * x) { return SvGdkWindow(x); }

/*SV * newSVGdkWindowRef(GdkWindow * w) { return newSVMiscRef(w, "Gtk::Gdk::Window",0); }
GdkWindow * SvGdkWindowRef(SV * data) { return SvMiscRef(data, "Gtk::Gdk::Window"); }

SV * newSVGdkPixmapRef(GdkPixmap * w) { return newSVMiscRef(w, "Gtk::Gdk::Pixmap",0); }
GdkPixmap * SvGdkPixmapRef(SV * data) { return SvMiscRef(data, "Gtk::Gdk::Pixmap"); }

SV * newSVGdkBitmapRef(GdkBitmap * w) { return newSVMiscRef(w, "Gtk::Gdk::Bitmap",0); }
GdkBitmap * SvGdkBitmapRef(SV * data) { return SvMiscRef(data, "Gtk::Gdk::Bitmap"); }

SV * newSVGdkColormapRef(GdkColormap * w) { return newSVMiscRef(w, "Gtk::Gdk::Colormap",0); }
GdkColormap * SvGdkColormapRef(SV * data) { return SvMiscRef(data, "Gtk::Gdk::Colormap"); }*/

/*SV * newSVGdkColor(GdkColor * c) { return newSVMiscRef(c, "Gtk::Gdk::Color",0); }
GdkColor * SvGdkColor(SV * data) { return SvMiscRef(data, "Gtk::Gdk::Color"); }*/

SV * newSVGdkRegion(GdkRegion * c) { return newSVMiscRef(c, "Gtk::Gdk::Region",0); }
GdkRegion * SvGdkRegion(SV * data) { return SvMiscRef(data, "Gtk::Gdk::Region"); }

SV * newSVGdkCursorRef(GdkCursor * w) { return newSVMiscRef(w, "Gtk::Gdk::Cursor",0); }
GdkCursor * SvGdkCursorRef(SV * data) { return SvMiscRef(data, "Gtk::Gdk::Cursor"); }

SV * newSVGdkVisualRef(GdkVisual * w) { return newSVMiscRef(w, "Gtk::Gdk::Visual",0); }
GdkVisual * SvGdkVisualRef(SV * data) { return SvMiscRef(data, "Gtk::Gdk::Visual"); }

SV * newSVGdkGCRef(GdkGC * g) { return newSVMiscRef(g, "Gtk::Gdk::GC",0); }
GdkGC * SvGdkGCRef(SV * data) { return SvMiscRef(data, "Gtk::Gdk::GC"); }

SV * newSVGdkFontRef(GdkFont * f) { return newSVMiscRef(f, "Gtk::Gdk::Font",0); }
GdkFont * SvGdkFontRef(SV * data) { return SvMiscRef(data, "Gtk::Gdk::Font"); }

/*SV * newSVGdkImageRef(GdkImage * i) { return newSVMiscRef(i, "Gtk::Gdk::Image",0); }
GdkImage * SvGdkImageRef(SV * data) { return SvMiscRef(data, "Gtk::Gdk::Image"); }*/

SV * newSVGdkWindow(GdkWindow * value) {
	int n = 0;
	SV * result;
	result = newSVMiscRef(value, 
		(value && (gdk_window_get_type(value) == GDK_WINDOW_PIXMAP)) ? 
			"Gtk::Gdk::Pixmap" :
			"Gtk::Gdk::Window"
		, &n);
	if (n && value)
		gdk_window_ref(value);
	return result;
}

GdkWindow * SvGdkWindow(SV * value) { return (GdkWindow*)SvMiscRef(value, "Gtk::Gdk::Pixmap"); }


SV * newSVGdkRectangle(GdkRectangle * rect)
{
	AV * a;
	SV * r;
	
	if (!rect)
		return newSVsv(&PL_sv_undef);
		
	a = newAV();
	r = newRV((SV*)a);
	SvREFCNT_dec(a);
	
	av_push(a, newSViv(rect->x));
	av_push(a, newSViv(rect->y));
	av_push(a, newSViv(rect->width));
	av_push(a, newSViv(rect->height));
	
	return r;
}

GdkRectangle * SvGdkRectangle(SV * data, GdkRectangle * rect)
{
	AV * a;
	SV ** s;

	if ((!data) || (!SvOK(data)) || (!SvRV(data)) || (SvTYPE(SvRV(data)) != SVt_PVAV))
		return 0;
		
	a = (AV*)SvRV(data);

	if (av_len(a) != 3)
		croak("rectangle must have four elements");

	if (!rect)
		rect = pgtk_alloc_temp(sizeof(GdkRectangle));
	
	rect->x = SvIV(*av_fetch(a, 0, 0));
	rect->y = SvIV(*av_fetch(a, 1, 0));
	rect->width = SvIV(*av_fetch(a, 2, 0));
	rect->height = SvIV(*av_fetch(a, 3, 0));
	
	return rect;
}

SV * newSVGdkGCValues(GdkGCValues * v)
{
	HV * h;
	SV * r;
	
	if (!v)
		return newSVsv(&PL_sv_undef);
		
	h = newHV();
	r = newRV((SV*)h);
	SvREFCNT_dec(h);

	hv_store(h, "foreground", 10, newSVMiscRef(&v->foreground, "Gtk::Gdk::Color",0), 0);
	hv_store(h, "background", 10, newSVMiscRef(&v->background, "Gtk::Gdk::Color",0), 0);
	hv_store(h, "font", 4, newSVMiscRef(v->font, "Gtk::Gdk::Font",0), 0);
	hv_store(h, "function", 8, newSVGdkFunction(v->function), 0);
	hv_store(h, "fill", 4, newSVGdkFill(v->fill), 0);
	hv_store(h, "tile", 4, newSVMiscRef(v->tile, "Gtk::Gdk::Pixmap",0), 0);
	hv_store(h, "stipple", 7, newSVMiscRef(v->stipple, "Gtk::Gdk::Pixmap",0), 0);
	hv_store(h, "clip_mask", 9, newSVMiscRef(v->clip_mask, "Gtk::Gdk::Pixmap",0), 0);
	hv_store(h, "subwindow_mode", 14, newSVGdkSubwindowMode(v->subwindow_mode), 0);
	hv_store(h, "ts_x_origin", 11, newSViv(v->ts_x_origin), 0);
	hv_store(h, "ts_y_origin", 11, newSViv(v->ts_y_origin), 0);
	hv_store(h, "clip_x_origin", 13, newSViv(v->clip_x_origin), 0);
	hv_store(h, "clip_x_origin", 13, newSViv(v->clip_y_origin), 0);
	hv_store(h, "graphics_exposures", 18, newSViv(v->graphics_exposures), 0);
	hv_store(h, "line_width", 10, newSViv(v->line_width), 0);
	hv_store(h, "line_style", 10, newSVGdkLineStyle(v->line_style), 0);
	hv_store(h, "cap_style", 9, newSVGdkCapStyle(v->cap_style), 0);
	hv_store(h, "join_style", 10, newSVGdkJoinStyle(v->join_style), 0);
	
	return r;
}

GdkGCValues * SvGdkGCValues(SV * data, GdkGCValues * v, GdkGCValuesMask * m)
{
	HV * h;
	SV ** s;

	if ((!data) || (!SvOK(data)) || (!SvRV(data)) || (SvTYPE(SvRV(data)) != SVt_PVHV))
		return 0;
		
	h = (HV*)SvRV(data);

	if (!v)
		v = pgtk_alloc_temp(sizeof(GdkGCValues));
	
	memset(v,0,sizeof(GdkGCValues));

	if ((s=hv_fetch(h, "foreground", 10, 0)) && SvOK(*s)) {
		SvSetGdkColor(*s, &v->foreground);
		*m |= GDK_GC_FOREGROUND;
	}
	if ((s=hv_fetch(h, "background", 10, 0)) && SvOK(*s)) {
		SvSetGdkColor(*s, &v->background);
		*m |= GDK_GC_BACKGROUND;
	}
	if ((s=hv_fetch(h, "font", 4, 0)) && SvOK(*s)) {
		v->font = SvMiscRef(*s, "Gtk::Gdk::Font");
		*m |= GDK_GC_FONT;
	}
	if ((s=hv_fetch(h, "function", 8, 0)) && SvOK(*s)) {
		v->function = SvGdkFunction(*s);
		*m |= GDK_GC_FUNCTION;
	}
	if ((s=hv_fetch(h, "fill", 4, 0)) && SvOK(*s)) {
		v->function = SvGdkFill(*s);
		*m |= GDK_GC_FILL;
	}
	if ((s=hv_fetch(h, "tile", 4, 0)) && SvOK(*s)) {
		v->tile = SvMiscRef(*s, "Gtk::Gdk::Pixmap");
		*m |= GDK_GC_TILE;
	}
	if ((s=hv_fetch(h, "stipple", 7, 0)) && SvOK(*s)) {
		v->stipple = SvMiscRef(*s, "Gtk::Gdk::Pixmap");
		*m |= GDK_GC_STIPPLE;
	}
	if ((s=hv_fetch(h, "clip_mask", 9, 0)) && SvOK(*s)) {
		v->clip_mask = SvMiscRef(*s, "Gtk::Gdk::Pixmap");
		*m |= GDK_GC_CLIP_MASK;
	}
	if ((s=hv_fetch(h, "subwindow_mode", 14, 0)) && SvOK(*s)) {
		v->subwindow_mode = SvGdkSubwindowMode(*s);
		*m |= GDK_GC_SUBWINDOW;
	}
	if ((s=hv_fetch(h, "ts_x_origin", 11, 0)) && SvOK(*s)) {
		v->ts_x_origin = SvIV(*s);
		*m |= GDK_GC_TS_X_ORIGIN;
	}
	if ((s=hv_fetch(h, "ts_y_origin", 11, 0)) && SvOK(*s)) {
		v->ts_y_origin = SvIV(*s);
		*m |= GDK_GC_TS_Y_ORIGIN;
	}
	if ((s=hv_fetch(h, "clip_x_origin", 13, 0)) && SvOK(*s)) {
		v->clip_x_origin = SvIV(*s);
		*m |= GDK_GC_CLIP_X_ORIGIN;
	}
	if ((s=hv_fetch(h, "clip_y_origin", 13, 0)) && SvOK(*s)) {
		v->clip_y_origin = SvIV(*s);
		*m |= GDK_GC_CLIP_Y_ORIGIN;
	}
	if ((s=hv_fetch(h, "graphics_exposures", 18, 0)) && SvOK(*s)) {
		v->graphics_exposures = SvIV(*s);
		*m |= GDK_GC_EXPOSURES;
	}
	if ((s=hv_fetch(h, "line_width", 10, 0)) && SvOK(*s)) {
		v->line_width= SvIV(*s);
		*m |= GDK_GC_LINE_WIDTH;
	}
	if ((s=hv_fetch(h, "line_style", 10, 0)) && SvOK(*s)) {
		v->line_style= SvGdkLineStyle(*s);
		*m |= GDK_GC_LINE_STYLE;
	}
	if ((s=hv_fetch(h, "cap_style", 9, 0)) && SvOK(*s)) {
		v->cap_style = SvGdkCapStyle(*s);
		*m |= GDK_GC_CAP_STYLE;
	}
	if ((s=hv_fetch(h, "join_style", 10, 0)) && SvOK(*s)) {
		v->join_style = SvGdkJoinStyle(*s);
		*m |= GDK_GC_JOIN_STYLE;
	}
	return v;
}

SV * newSVGdkDeviceInfo(GdkDeviceInfo * v)
{
	HV * h;
	SV * r;
	
	if (!v)
		return newSVsv(&PL_sv_undef);
		
	h = newHV();
	r = newRV((SV*)h);
	SvREFCNT_dec(h);

	hv_store(h, "deviceid", 8, newSViv(v->deviceid), 0);
	hv_store(h, "name", 4, newSVpv(v->name, 0), 0);
	hv_store(h, "source", 6, newSVGdkInputSource(v->source), 0);
	hv_store(h, "mode", 4, newSVGdkInputMode(v->mode), 0);
	hv_store(h, "has_cursor", 10, newSViv(v->has_cursor), 0);
	hv_store(h, "num_axes", 8, newSViv(v->num_axes), 0);
	if (v->axes) {
		int i;
		AV * a = newAV();
		for(i=0;i<v->num_axes;i++) {
			av_push(a, newSVGdkAxisUse(v->axes[i]));
		}
		hv_store(h, "axes", 4, newRV((SV*)a), 0);
		SvREFCNT_dec(a);
	}

	return r;
}

SV * newSVGdkTimeCoord(GdkTimeCoord * v)
{
	HV * h;
	SV * r;
	
	if (!v)
		return newSVsv(&PL_sv_undef);
		
	h = newHV();
	r = newRV((SV*)h);
	SvREFCNT_dec(h);

	hv_store(h, "time", 4, newSViv(v->time), 0);
	hv_store(h, "x", 1, newSVnv(v->x), 0);
	hv_store(h, "y", 1, newSVnv(v->y), 0);
	hv_store(h, "pressure", 8, newSVnv(v->pressure), 0);
	hv_store(h, "xtilt", 5, newSVnv(v->xtilt), 0);
	hv_store(h, "ytilt", 5, newSVnv(v->ytilt), 0);

	return r;
}

SV * newSVGdkAtom(GdkAtom a)
{
	SV *s = newSViv(0);
	sv_setuv(s, a);
	return s;
}

GdkAtom SvGdkAtom(SV * data)
{
	return SvUV(data);
}

SV * newSVGdkEvent(GdkEvent * e)
{
	HV * h;
	GdkEvent * e2;
	SV * r;
	int n;
	
	if (!e)
		return newSVsv(&PL_sv_undef);
	/* gdk_event_copy() will segfault otherwise */
	if (!e->any.window)
		return newSVsv(&PL_sv_undef);
 
 
        h = newHV();
        /*r = newSVMiscRef(e, "Gtk::Gdk::Event", &n);*/

	/*h = (HV*)SvRV(r);*/
	r = newRV((SV*)h);
	SvREFCNT_dec(h);

	sv_bless(r, gv_stashpv("Gtk::Gdk::Event", FALSE));
 
	e2 = gdk_event_copy(e);
	
	hv_store(h, "_ptr", 4, newSViv((long)e2), 0);
	
	/*printf("Turning GdkEvent %d, type %d, into SV %d, ptr %d\n", e, e->type, r, e2);*/
	
	hv_store(h, "type", 4, newSVGdkEventType(e->type), 0);
	hv_store(h, "window", 6, newSVGdkWindow(e->any.window), 0);
	hv_store(h, "send_event", 10, newSViv(e->any.send_event), 0);
	switch (e->type) {
	case GDK_EXPOSE:
		hv_store(h, "area", 4, newSVGdkRectangle(&e->expose.area), 0);
		hv_store(h, "count", 5, newSViv(e->expose.count), 0);
		break;
	case GDK_VISIBILITY_NOTIFY:
		hv_store(h, "state", 5, newSVGdkVisibilityState(e->visibility.state), 0);
		break;
	case GDK_MOTION_NOTIFY:
		hv_store(h, "is_hint", 7, newSViv(e->motion.is_hint), 0);
		hv_store(h, "x", 1, newSVnv(e->motion.x), 0);
		hv_store(h, "y", 1, newSVnv(e->motion.y), 0);
		hv_store(h, "pressure", 8, newSVnv(e->motion.pressure), 0);
		hv_store(h, "xtilt", 5, newSVnv(e->motion.xtilt), 0);
		hv_store(h, "ytilt", 5, newSVnv(e->motion.ytilt), 0);
		hv_store(h, "time", 4, newSViv(e->motion.time), 0);
		hv_store(h, "state", 5, newSViv(e->motion.state), 0);
		hv_store(h, "source", 6, newSVGdkInputSource(e->motion.source), 0);
		hv_store(h, "deviceid", 8, newSViv(e->motion.deviceid), 0);
		hv_store(h, "x_root", 6, newSVnv(e->motion.x_root), 0);
		hv_store(h, "y_root", 6, newSVnv(e->motion.y_root), 0);
		break;
	case GDK_BUTTON_PRESS:
	case GDK_2BUTTON_PRESS:
	case GDK_3BUTTON_PRESS:
	case GDK_BUTTON_RELEASE:
		hv_store(h, "x", 1, newSViv(e->button.x), 0);
		hv_store(h, "y", 1, newSViv(e->button.y), 0);
		hv_store(h, "time", 4, newSViv(e->button.time), 0);
		hv_store(h, "pressure", 8, newSVnv(e->button.pressure), 0);
		hv_store(h, "xtilt", 5, newSVnv(e->button.xtilt), 0);
		hv_store(h, "ytilt", 5, newSVnv(e->button.ytilt), 0);
		hv_store(h, "state", 5, newSViv(e->button.state), 0);
		hv_store(h, "button", 6, newSViv(e->button.button), 0);
		hv_store(h, "source", 6, newSVGdkInputSource(e->button.source), 0);
		hv_store(h, "deviceid", 8, newSViv(e->button.deviceid), 0);
		hv_store(h, "x_root", 6, newSVnv(e->button.x_root), 0);
		hv_store(h, "y_root", 6, newSVnv(e->button.y_root), 0);
		break;
	case GDK_KEY_PRESS:
	case GDK_KEY_RELEASE:
		hv_store(h, "time", 4, newSViv(e->key.time), 0);
		hv_store(h, "state", 5, newSVnv(e->key.state), 0);
		hv_store(h, "keyval", 6, newSViv(e->key.keyval), 0);
		hv_store(h, "string", 6, newSVpvn(e->key.string, e->key.length), 0);
		break;
	case GDK_FOCUS_CHANGE:
		hv_store(h, "in", 2, newSViv(e->focus_change.in), 0);
		break;
	case GDK_ENTER_NOTIFY:
	case GDK_LEAVE_NOTIFY:
		hv_store(h, "window", 6, newSVGdkWindow(e->crossing.window), 0);
		hv_store(h, "subwindow", 9, newSVGdkWindow(e->crossing.subwindow), 0);
		hv_store(h, "time", 4, newSViv(e->crossing.time), 0);
		hv_store(h, "x", 1, newSVnv(e->crossing.x), 0);
		hv_store(h, "y", 1, newSVnv(e->crossing.y), 0);
		hv_store(h, "x_root", 6, newSVnv(e->crossing.x_root), 0);
		hv_store(h, "y_root", 6, newSVnv(e->crossing.y_root), 0);
		hv_store(h, "detail", 6, newSVGdkNotifyType(e->crossing.detail), 0);
		hv_store(h, "mode", 4, newSVGdkCrossingMode(e->crossing.mode), 0);
		hv_store(h, "focus", 5, newSVnv(e->crossing.focus), 0);
		hv_store(h, "state", 5, newSVnv(e->crossing.state), 0);
		break;
	case GDK_CONFIGURE:
		hv_store(h, "x", 1, newSViv(e->configure.x), 0);
		hv_store(h, "y", 1, newSViv(e->configure.y), 0);
		hv_store(h, "width", 5, newSViv(e->configure.width), 0);
		hv_store(h, "height", 6, newSViv(e->configure.height), 0);
		break;
	case GDK_PROPERTY_NOTIFY:
		hv_store(h, "time", 4, newSViv(e->property.time), 0);
		hv_store(h, "state", 5, newSVnv(e->property.state), 0);
		hv_store(h, "atom", 4, newSVGdkAtom(e->property.atom), 0);
		break;
	case GDK_SELECTION_CLEAR:
	case GDK_SELECTION_REQUEST:
	case GDK_SELECTION_NOTIFY:
		hv_store(h, "requestor", 9, newSViv(e->selection.requestor), 0);
		hv_store(h, "time", 4, newSViv(e->selection.time), 0);
		hv_store(h, "selection", 9, newSVGdkAtom(e->selection.selection), 0);
		hv_store(h, "property", 8, newSVGdkAtom(e->selection.property), 0);
		hv_store(h, "target", 6, newSVGdkAtom(e->selection.target), 0);
		break;
	case GDK_PROXIMITY_IN:
	case GDK_PROXIMITY_OUT:
		hv_store(h, "time", 4, newSViv(e->proximity.time), 0);
		hv_store(h, "source", 6, newSVGdkInputSource(e->proximity.source), 0);
		hv_store(h, "deviceid", 8, newSViv(e->proximity.deviceid), 0);
		break;
	case GDK_CLIENT_EVENT:
		hv_store(h, "message_type", 12, newSVGdkAtom(e->client.message_type), 0);
		hv_store(h, "data_format", 11, newSViv(e->client.data_format), 0);
		hv_store(h, "data", 4, newSVpvn(e->client.data.b, 20), 0);
		break;
	case GDK_DRAG_ENTER:
	case GDK_DRAG_LEAVE:
	case GDK_DRAG_MOTION:
	case GDK_DRAG_STATUS:
	case GDK_DROP_START:
	case GDK_DROP_FINISHED:
		hv_store(h, "time", 4, newSVnv(e->dnd.time), 0);
		hv_store(h, "x_root", 6, newSViv(e->dnd.x_root), 0);
		hv_store(h, "y_root", 6, newSViv(e->dnd.y_root), 0);
		hv_store(h, "context", 7, newSVGdkDragContext(e->dnd.context), 0);
		break;
	default:
		/*g_message("event type %d not handled", e->type);*/
		break;
	}
	
	return r;
}

GdkEvent * SvSetGdkEvent(SV * data, GdkEvent * e)
{
	HV * h;
	SV ** s;

      	if (!data || !SvOK(data) || !(h=(HV*)SvRV(data)) || (SvTYPE(h) != SVt_PVHV))
                return 0;
        
        if (!e)
        	e = pgtk_alloc_temp(sizeof(GdkEvent));
        
        s = hv_fetch(h, "_ptr", 4, 0);
        if (!s || !SvIV(*s))
                croak("event is damaged");
        
	e = (GdkEvent*)SvIV(*s);

        /*printf("Composing GdkEvent HV %d to pointer %d\n", h, e);*/
	
	if ((s=hv_fetch(h, "type", 4, 0)))
		e->type = SvGdkEventType(*s);
	else
		croak("event must contain type");
	if ((s=hv_fetch(h, "window", 6, 0)))
		e->any.window = SvGdkWindow(*s);
	else
		croak("event must contain window");
	if ((s=hv_fetch(h, "send_event", 10, 0)))
		e->any.send_event = SvIV(*s);
	
	switch (e->type) {
	case GDK_MAP:
	case GDK_UNMAP:
	case GDK_DELETE:
	case GDK_DESTROY:
	case GDK_NO_EXPOSE:
		break;
	case GDK_EXPOSE:
		if ((s=hv_fetch(h, "area", 4, 0)))
			SvGdkRectangle(*s, &e->expose.area);
		else
			croak("event must contain area");
		if ((s=hv_fetch(h, "count", 5, 0)))
			e->expose.count = SvIV(*s);
		else
			croak("event must contain count");
		break;
	case GDK_VISIBILITY_NOTIFY:
		if ((s=hv_fetch(h, "state", 5, 0)))
			e->visibility.state = SvGdkVisibilityState(*s);
		else
			croak("event must contain state");
		break;
	case GDK_MOTION_NOTIFY:
		if ((s=hv_fetch(h, "x", 1, 0)))
			e->motion.x = SvNV(*s);
		else
			croak("event must contain x ordinate");
		if ((s=hv_fetch(h, "y", 1, 0)))
			e->motion.y = SvNV(*s);
		else
			croak("event must contain y ordinate");
		if ((s=hv_fetch(h, "pressure", 8, 0)))
			e->motion.pressure = SvNV(*s);
		else
			e->motion.pressure = 0;
		if ((s=hv_fetch(h, "xtilt", 5, 0)))
			e->motion.xtilt = SvNV(*s);
		else
			e->motion.xtilt = 0;
		if ((s=hv_fetch(h, "ytilt", 5, 0)))
			e->motion.ytilt = SvNV(*s);
		else
			e->motion.ytilt = 0;
		if ((s=hv_fetch(h, "time", 4, 0)))
			e->motion.time = SvIV(*s);
		else
			croak("event must contain time");
		if ((s=hv_fetch(h, "state", 5, 0)))
			e->motion.state = SvIV(*s);
		else
			croak("event must contain state");
		if ((s=hv_fetch(h, "is_hint", 7, 0)))
			e->motion.is_hint = SvIV(*s);
		else
			croak("event must contain is_hint");
		if ((s=hv_fetch(h, "source", 6, 0)))
			e->motion.source = SvGdkInputSource(*s);
		else
			e->motion.source = 0;
		if ((s=hv_fetch(h, "deviceid", 8, 0)) && SvOK(*s))
			e->motion.deviceid = SvIV(*s);
		else
			e->motion.deviceid = GDK_CORE_POINTER;
		if ((s=hv_fetch(h, "x_root", 6, 0)))
			e->motion.x_root = SvIV(*s);
		else
			croak("event must contain x_root");
		if ((s=hv_fetch(h, "y_root", 6, 0)))
			e->motion.y_root = SvIV(*s);
		else
			croak("event must contain y_root");
		break;
	case GDK_BUTTON_PRESS:
	case GDK_2BUTTON_PRESS:
	case GDK_3BUTTON_PRESS:
	case GDK_BUTTON_RELEASE:
		if ((s=hv_fetch(h, "x", 1, 0)))
			e->button.x = SvNV(*s);
		else
			croak("event must contain x ordinate");
		if ((s=hv_fetch(h, "y", 1, 0)))
			e->button.y = SvNV(*s);
		else
			croak("event must contain y ordinate");
		if ((s=hv_fetch(h, "pressure", 8, 0)))
			e->button.button = SvNV(*s);
		else
			e->button.pressure = 0;
		if ((s=hv_fetch(h, "xtilt", 5, 0)))
			e->button.xtilt = SvNV(*s);
		else
			e->button.xtilt = 0;
		if ((s=hv_fetch(h, "ytilt", 5, 0)))
			e->button.ytilt = SvNV(*s);
		else
			e->button.ytilt = 0;
		if ((s=hv_fetch(h, "time", 4, 0)))
			e->button.time = SvIV(*s);
		else
			croak("event must contain time");
		if ((s=hv_fetch(h, "state", 5, 0)))
			e->button.state = SvIV(*s);
		else
			croak("event must contain state");
		if ((s=hv_fetch(h, "button", 6, 0)))
			e->button.button = SvIV(*s);
		else
			croak("event must contain state");
		if ((s=hv_fetch(h, "source", 6, 0)))
			e->button.source = SvGdkInputSource(*s);
		else
			e->button.source = 0;
		if ((s=hv_fetch(h, "deviceid", 8, 0)) && SvOK(*s))
			e->button.deviceid = SvIV(*s);
		else
			e->button.deviceid = GDK_CORE_POINTER;
		if ((s=hv_fetch(h, "x_root", 6, 0)))
			e->button.x_root = SvIV(*s);
		else
			croak("event must contain x_root");
		if ((s=hv_fetch(h, "y_root", 6, 0)))
			e->button.y_root = SvIV(*s);
		else
			croak("event must contain y_root");
		break;
	case GDK_KEY_PRESS:
	case GDK_KEY_RELEASE:
		if ((s=hv_fetch(h, "time", 4, 0)))
			e->key.time = SvIV(*s);
		else
			croak("event must contain time");
		if ((s=hv_fetch(h, "state", 5, 0)))
			e->key.state = SvIV(*s);
		else
			croak("event must contain state");
		if ((s=hv_fetch(h, "keyval", 6, 0)))
			e->key.keyval = SvIV(*s);
		else
			croak("event must contain keyval");
		if ((s=hv_fetch(h, "string", 6, 0))) {
			STRLEN len;
			/* FIXME: need to free e->key.string? */
			e->key.string = g_strdup(SvPV(*s, len));
			e->key.length = len;
		} else
			croak("event must contain string");
		break;
	case GDK_FOCUS_CHANGE:
		if ((s=hv_fetch(h, "in", 2, 0)))
			e->focus_change.in = SvIV(*s);
		else
			croak("event must contain in");
		break;
	case GDK_ENTER_NOTIFY:
	case GDK_LEAVE_NOTIFY:
		if ((s=hv_fetch(h, "subwindow", 9, 0)))
			e->crossing.subwindow = SvGdkWindow(*s);
		else
			croak("event must contain subwindow");
		if ((s=hv_fetch(h, "detail", 6, 0)))
			e->crossing.detail = SvGdkNotifyType(*s);
		else
			croak("event must contain detail");
		if ((s=hv_fetch(h, "x", 1, 0)))
			e->crossing.x = SvIV(*s);
		else
			croak("event must contain x ordinate");
		if ((s=hv_fetch(h, "y", 1, 0)))
			e->crossing.y = SvIV(*s);
		else
			croak("event must contain y ordinate");
		if ((s=hv_fetch(h, "x_root", 6, 0)))
			e->crossing.x_root = SvIV(*s);
		else
			croak("event must contain x_root ordinate");
		if ((s=hv_fetch(h, "y_root", 6, 0)))
			e->crossing.y_root = SvIV(*s);
		else
			croak("event must contain y_root ordinate");
		if ((s=hv_fetch(h, "time", 4, 0)))
			e->crossing.time = SvIV(*s);
		else
			croak("event must contain time");
		if ((s=hv_fetch(h, "state", 5, 0)))
			e->crossing.state = SvIV(*s);
		else
			croak("event must contain state");
		if ((s=hv_fetch(h, "mode", 4, 0)))
			e->crossing.time = SvGdkCrossingMode(*s);
		else
			croak("event must contain time");
		if ((s=hv_fetch(h, "focus", 5, 0)))
			e->crossing.focus = SvIV(*s);
		else
			croak("event must contain focus");
		break;
	case GDK_CONFIGURE:
		if ((s=hv_fetch(h, "x", 1, 0)))
			e->configure.x = SvIV(*s);
		else
			croak("event must contain x ordinate");
		if ((s=hv_fetch(h, "y", 1, 0)))
			e->configure.y = SvIV(*s);
		else
			croak("event must contain y ordinate");
		if ((s=hv_fetch(h, "width", 5, 0)))
			e->configure.width = SvIV(*s);
		else
			croak("event must contain width");
		if ((s=hv_fetch(h, "height", 6, 0)))
			e->configure.height = SvIV(*s);
		else
			croak("event must contain height");
		break;
	case GDK_PROPERTY_NOTIFY:
		if ((s=hv_fetch(h, "time", 4, 0)))
			e->property.time = SvIV(*s);
		else
			croak("event must contain time");
		if ((s=hv_fetch(h, "state", 5, 0)))
			e->property.state = SvIV(*s);
		else
			croak("event must contain state");
		if ((s=hv_fetch(h, "atom", 4, 0)))
			e->property.atom = SvGdkAtom(*s);
		else
			croak("event must contain atom");
		break;
	case GDK_SELECTION_CLEAR:
	case GDK_SELECTION_REQUEST:
	case GDK_SELECTION_NOTIFY:
		if ((s=hv_fetch(h, "requestor", 9, 0)))
			e->selection.requestor = SvIV(*s);
		else
			croak("event must contain requestor");
		if ((s=hv_fetch(h, "time", 4, 0)))
			e->selection.time = SvIV(*s);
		else
			croak("event must contain time");
		if ((s=hv_fetch(h, "selection", 9, 0)))
			e->selection.selection = SvGdkAtom(*s);
		else
			croak("event must contain selection");
		if ((s=hv_fetch(h, "property", 8, 0)))
			e->selection.property = SvGdkAtom(*s);
		else
			croak("event must contain property");
		if ((s=hv_fetch(h, "target", 6, 0)))
			e->selection.target = SvGdkAtom(*s);
		else
			croak("event must contain target");
		break;
	case GDK_PROXIMITY_IN:
	case GDK_PROXIMITY_OUT:
		if ((s=hv_fetch(h, "time", 4, 0)))
			e->proximity.time = SvIV(*s);
		else
			croak("event must contain time");
		if ((s=hv_fetch(h, "deviceid", 8, 0)))
			e->proximity.deviceid = SvIV(*s);
		else
			croak("event must contain deviceid");
		if ((s=hv_fetch(h, "source", 6, 0)))
			e->proximity.source = SvGdkInputSource(*s);
		else
			croak("event must contain source");
		break;
	case GDK_CLIENT_EVENT:
		if ((s=hv_fetch(h, "message_type", 12, 0)))
			e->client.message_type = SvGdkAtom(*s);
		else
			croak("event must contain message_type");
		if ((s=hv_fetch(h, "data_format", 11, 0)))
			e->client.data_format = SvIV(*s);
		else
			croak("event must contain data_format");
		if ((s=hv_fetch(h, "data", 4, 0))) {
			STRLEN len;
			char *p = SvPV(*s, len);
			memcpy(e->client.data.b, p, len>20?20:len);
		} else
			croak("event must contain data");
		break;
	case GDK_DRAG_ENTER:
	case GDK_DRAG_LEAVE:
	case GDK_DRAG_MOTION:
	case GDK_DRAG_STATUS:
	case GDK_DROP_START:
	case GDK_DROP_FINISHED:
		if ((s=hv_fetch(h, "time", 4, 0)))
			e->dnd.time = SvIV(*s);
		else
			croak("event must contain time");
		if ((s=hv_fetch(h, "x_root", 6, 0)))
			e->dnd.x_root = SvIV(*s);
		else
			croak("event must contain x_root");
		if ((s=hv_fetch(h, "y_root", 6, 0)))
			e->dnd.y_root = SvIV(*s);
		else
			croak("event must contain y_root");
		if ((s=hv_fetch(h, "context", 7, 0)))
			e->dnd.context = SvGdkDragContext(*s);
		else
			croak("event must contain context");
		break;
	}
	
	return e;
}

GdkWindowAttr * SvGdkWindowAttr(SV * data, GdkWindowAttr * attr, gint * mask)
{
	dTHR;	

	HV * h;
	SV ** s;

	if ((!data) || (!SvOK(data)) || (!SvRV(data)) || (SvTYPE(SvRV(data)) != SVt_PVHV))
		return 0;
	
	if (!attr)
		attr = pgtk_alloc_temp(sizeof(GdkWindowAttr));
	
	memset(attr, 0, sizeof(GdkWindowAttr));
	
	*mask = 0;

	h = (HV*)SvRV(data);
	
	if ((s=hv_fetch(h, "title", 5, 0))) {
		attr->title = SvPV(*s,PL_na);
		*mask |= GDK_WA_TITLE;
	}
	
	if ((s=hv_fetch(h, "x", 1, 0))) {
		attr->x = SvIV(*s);
		*mask |= GDK_WA_X;
	}
	
	if ((s=hv_fetch(h, "y", 1, 0))) {
		attr->y = SvIV(*s);
		*mask |= GDK_WA_Y;
	}
	
	if ((s=hv_fetch(h, "cursor", 6, 0))) {
		attr->cursor = SvGdkCursorRef(*s);
		*mask |= GDK_WA_CURSOR;
	}
	
	if ((s=hv_fetch(h, "colormap", 8, 0))) {
		attr->colormap = SvGdkColormap(*s);
		*mask |= GDK_WA_COLORMAP;
	}
	
	if ((s=hv_fetch(h, "visual", 6, 0))) {
		attr->visual = SvGdkVisual(*s);
		*mask |= GDK_WA_VISUAL;
	}

	if ((s=hv_fetch(h, "window_type",11, 0)))
		attr->window_type = SvGdkWindowType(*s);
	else
		croak("window attribute must have window_type");
	if ((s=hv_fetch(h, "event_mask",10, 0)))
		attr->event_mask = SvGdkEventMask(*s);
	else
		croak("window attribute must have event_mask");
	if ((s=hv_fetch(h, "width",5, 0)))
		attr->width = SvIV(*s);
	else
		croak("window attribute must have width");
	if ((s=hv_fetch(h, "height",6, 0)))
		attr->height = SvIV(*s);
	else
		croak("window attribute must have height");
	if ((s=hv_fetch(h, "wclass",6, 0)))
		attr->wclass = SvGdkWindowClass(*s);
	else
		attr->wclass = GDK_INPUT_OUTPUT;

	return attr;
}

#if GTK_HVER >= 0x010200

SV * newSVGdkDragContextRef(GdkDragContext* f) { return newSVMiscRef(f, "Gtk::Gdk::DragContext", 0); }
GdkDragContext* SvGdkDragContextRef(SV * data) { return SvMiscRef(data, "Gtk::Gdk::DragContext"); }

#endif
