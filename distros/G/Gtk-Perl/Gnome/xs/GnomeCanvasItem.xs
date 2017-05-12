
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


static int GnomeCanvasItem_SetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object)
{
	int result = 1;
	if (a->type == GTK_TYPE_GNOME_CANVAS_POINTS)
		{
			AV * av;
			int i;
			GnomeCanvasPoints * p;
			
			if (!SvOK(v) || !SvROK(v) || (SvTYPE(SvRV(v)) != SVt_PVAV) )
				croak("points should be an array reference of coords");
			
			av = (AV*)SvRV(v);
			p = gnome_canvas_points_new((av_len(av)+1)/2);

			for (i=0; i<=av_len(av); i++)
				p->coords[i] = SvNV(*av_fetch(av, i, 0));

			GTK_VALUE_POINTER(*a) = p;
		}
	else if (a->type == GTK_TYPE_GDK_IMLIB_IMAGE)
		{
			GTK_VALUE_POINTER(*a) = SvGdkImlibImage(v);
		}
	else
		result = 0;
	
	return result;
}

static int GnomeCanvasItem_FreeArg(GtkArg * a)
{
	if (a->type == GTK_TYPE_GNOME_CANVAS_POINTS) {
			gnome_canvas_points_free((GnomeCanvasPoints*)GTK_VALUE_POINTER(*a));
			return 1;
	} else if (a->type == GTK_TYPE_GDK_IMLIB_IMAGE)
		return 1;
	
	return 0;
}

static SV * GnomeCanvasItem_GetArg (GtkArg * a) {
	if (a->type == GTK_TYPE_GNOME_CANVAS_POINTS) {
		AV * av = newAV();
		SV *r = newRV((SV*)av);
		int i;
		GnomeCanvasPoints * points = (GnomeCanvasPoints*)GTK_VALUE_POINTER(*a);
		
		SvREFCNT_dec(av);
		for(i=0; i < points->num_points*2; ++i)
			av_push(av, newSVnv(points->coords[i]));
		return r;
	} else if (a->type == GTK_TYPE_GDK_IMLIB_IMAGE)
		return newSVGdkImlibImage(GTK_VALUE_POINTER(*a));
	
	return NULL;
}

static struct PerlGtkTypeHelper type_help =
{
	GnomeCanvasItem_GetArg,
	GnomeCanvasItem_SetArg,
	0/*GnomeCanvasItem_SetRetArg*/,
	0/*GnomeCanvasItem_GetRetArg*/,
	GnomeCanvasItem_FreeArg,
	0
};

MODULE = Gnome::CanvasItem		PACKAGE = Gnome::CanvasItem		PREFIX = gnome_canvas_item_

#ifdef GNOME_CANVAS

Gtk::Object_Sink_Up
gnome_canvas_item_new(Class, parent, type, ...)
	Gnome::CanvasGroup	parent
	SV*	type
	CODE:
	{
		GtkArg	*argv;
		int	p, argc, i;
		GtkType realtype;

		SV * fixtypename = type;

		argc = items -3;
		if ( argc % 2 )
			croak("too few arguments");

		realtype = gtnumber_for_ptname(SvPV(type,PL_na));
		if(!realtype) {
			fixtypename = newSVpv("Gnome::Canvas", 0);
			sv_catsv(fixtypename, type);
			realtype = gtnumber_for_ptname(SvPV(fixtypename,PL_na));
		}
		
		if(!realtype) {
			croak("Invalid canvas item type '%s'", SvPV(type, PL_na));
		}
		
		RETVAL = gnome_canvas_item_new(parent, realtype, 0); /*i, argv);*/

		argv = malloc(sizeof(GtkArg)*argc);

		i=0;
		for(p=3; p<items;++i) {
			/* g_warning("NEW SETTING: %s -> %s\n", SvPV(ST(p), PL_na), SvPV(ST(p+1),PL_na)); */
			FindArgumentTypeWithObject(GTK_OBJECT(RETVAL), ST(p), &argv[i]);
			GtkSetArg(&argv[i], ST(p+1), fixtypename, GTK_OBJECT(RETVAL));

			p += 2;
		}

		gnome_canvas_item_setv(RETVAL, i, argv);
		
		for (p=0; p<i; p++)
			GtkFreeArg(&argv[i]);

		free(argv);

		if (fixtypename != type)
			SvREFCNT_dec(fixtypename);
		
	}
	OUTPUT:
	RETVAL

#if 1 
# This code is needed, as Gtk::Object::set() behaves differently from Gnome::CanvasItem::set(), which is a bug IMO. 

void
gnome_canvas_item_set (item, name, value,...)
	Gnome::CanvasItem	item
	CODE:
	{
		GtkArg	*argv;
		int	p, argc, i;
		GtkObject *obj;
		
		argc = items -1;
		if ( argc % 2 )
			croak("too few arguments");
		
		obj = GTK_OBJECT(item);
		argv = malloc(sizeof(GtkArg)*argc);

		i=0;
		for(p=1; p<items;++i) {
			/* g_warning("SETTING: %s -> %s\n", SvPV(ST(p), PL_na), SvPV(ST(p+1),PL_na)); */
			FindArgumentTypeWithObject(obj, ST(p), &argv[i]);
			GtkSetArg(&argv[i], ST(p+1), ST(0), obj);
			p += 2;
		}
		gnome_canvas_item_setv(item, i, argv);
		
		for(p=0;p<i;p++)
			GtkFreeArg(&argv[i]);
		
		free(argv);
	}

#endif

void
gnome_canvas_item_move(item, dx, dy)
	Gnome::CanvasItem	item
	double	dx
	double	dy

#if GNOME_HVER >= 0x010200

void
gnome_canvas_item_affine_relative (item, aff0, aff1, aff2, aff3, aff4, aff5)
	Gnome::CanvasItem	item
	double	aff0
	double	aff1
	double	aff2
	double	aff3
	double	aff4
	double	aff5
	ALIAS:
		Gnome::CanvasItem::affine_relative = 0
		Gnome::CanvasItem::affine_absolute = 1
	CODE:
	{
		double affine[6];
		affine[0] = aff0; affine[1] = aff1; affine[2] = aff2;
		affine[3] = aff3; affine[4] = aff4; affine[5] = aff5;
		if (ix == 0)
			gnome_canvas_item_affine_relative(item, affine);
		else if (ix == 1)
			gnome_canvas_item_affine_absolute(item, affine);
	}

void
gnome_canvas_item_i2w_affine (item)
	Gnome::CanvasItem	item
	ALIAS:
		Gnome::CanvasItem::i2w_affine = 0
		Gnome::CanvasItem::i2c_affine = 1
	PPCODE:
	{
		double affine[6];
		int i;
		if (ix == 0)
			gnome_canvas_item_i2w_affine(item, affine);
		else if (ix == 1)
			gnome_canvas_item_i2c_affine (item, affine);
		EXTEND(sp, 6);
		for(i=0; i < 6; ++i)
			PUSHs(sv_2mortal(newSVnv(affine[i])));
	}

#if 0

void
gnome_canvas_item_scale (item, x, y, scale_x, scale_y)
	Gnome::CanvasItem	item
	double	x
	double	y
	double	scale_x
	double	scale_y

void
gnome_canvas_item_rotate (item, x, y, angle)
	Gnome::CanvasItem	item
	double	x
	double	y
	double	angle

#endif

#endif

void
gnome_canvas_item_raise(item, positions)
	Gnome::CanvasItem	item
	int	positions
	ALIAS:
		Gnome::CanvasItem::raise = 0
		Gnome::CanvasItem::lower = 1
	CODE:
	if (ix == 0)
		gnome_canvas_item_raise(item, positions);
	else if (ix == 1)
		gnome_canvas_item_lower(item, positions);

void
gnome_canvas_item_raise_to_top(item)
	Gnome::CanvasItem	item
	ALIAS:
		Gnome::CanvasItem::raise_to_top = 0
		Gnome::CanvasItem::lower_to_bottom = 1
		Gnome::CanvasItem::show = 2
		Gnome::CanvasItem::hide = 3
		Gnome::CanvasItem::grab_focus = 4
		Gnome::CanvasItem::request_update = 5
	CODE:
	switch (ix) {
	case 0: gnome_canvas_item_raise_to_top(item); break;
	case 1: gnome_canvas_item_lower_to_bottom(item); break;
	case 2: gnome_canvas_item_show(item); break;
	case 3: gnome_canvas_item_hide(item); break;
	case 4: gnome_canvas_item_grab_focus(item); break;
	case 5: gnome_canvas_item_request_update(item); break;
	}

int
gnome_canvas_item_grab(item, event_mask, cursor, time)
	Gnome::CanvasItem	item
	Gtk::Gdk::EventMask	event_mask
	Gtk::Gdk::Cursor	cursor
	int		time

void
gnome_canvas_item_ungrab(item, time)
	Gnome::CanvasItem	item
	int		time

void
gnome_canvas_item_reparent (item, new_group)
	Gnome::CanvasItem	item
	Gnome::CanvasGroup	new_group

void
gnome_canvas_item_get_bounds (item)
	Gnome::CanvasItem	item
	PPCODE:
	{
		double x1, y1, x2, y2;
		gnome_canvas_item_get_bounds(item, &x1, &y1, &x2, &y2);
		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSVnv(x1)));
		PUSHs(sv_2mortal(newSVnv(y1)));
		PUSHs(sv_2mortal(newSVnv(x2)));
		PUSHs(sv_2mortal(newSVnv(y2)));
	}

void
gnome_canvas_item_w2i(item, x, y)
	Gnome::CanvasItem	item
	double	x
	double	y
	ALIAS:
		Gnome::CanvasItem::w2i = 0
		Gnome::CanvasItem::i2w = 1
	PPCODE:
	{
		if (ix == 0)
			gnome_canvas_item_w2i(item, &x, &y);
		else if (ix == 1)
			gnome_canvas_item_i2w(item, &x, &y);
		EXTEND(sp,2);
		PUSHs(sv_2mortal(newSVnv(x)));
		PUSHs(sv_2mortal(newSVnv(y)));
	}

BOOT:
	AddTypeHelper(&type_help);



#endif

