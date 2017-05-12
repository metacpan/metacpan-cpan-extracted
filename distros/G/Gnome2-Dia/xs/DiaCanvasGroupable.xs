/*
 * Copyright (C) 2004 by the gtk2-perl team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaCanvasGroupable.xs,v 1.2 2004/09/25 19:13:30 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

/* ------------------------------------------------------------------------- */

/* I'm pretty sure I'm leaking some SVs here.  Theoretically, the destroy
 * function should be called rather often, but it appears it's only called
 * once.  If I omit the SvREFCNT_inc()s, I get segfaults.  Fishy, fishy.
 */

static void
iter_destroy (DiaCanvasIter * iter)
{
	if (iter) {
		int i;
		for (i = 0; i <= 2; i++) {
			SV *sv = (SV *) iter->data[i];
			if (sv && SvOK (sv))
				SvREFCNT_dec (sv);
		}
	}
}

static gboolean
iter_from_sv (DiaCanvasIter *iter, SV *sv)
{
	if (sv && SvOK (sv)) {
		SV **svp;
		AV *av;
		int i;

		if (!SvROK (sv) || SvTYPE (SvRV (sv)) != SVt_PVAV)
			croak ("expecting a reference to an ARRAY to describe "
			       "a group iter, not a %s",
			       sv_reftype (SvRV (sv), 0));

		av = (AV *) SvRV (sv);

		if ((svp = av_fetch (av, 0, FALSE)))
			iter->stamp = SvIV (*svp);

		for (i = 0; i <= 2; i++) {
			if ((svp = av_fetch (av, i + 1, FALSE)) && SvOK (*svp))
				iter->data[i] = SvREFCNT_inc (*svp);
			else
				iter->data[i] = NULL;
		}

		iter->destroy_func = (GDestroyNotify) iter_destroy;

		return TRUE;
	} else {
		iter->stamp = 0;
		iter->data[0] = 0;
		iter->data[1] = 0;
		iter->data[2] = 0;
		iter->destroy_func = NULL;

		return FALSE;
	}
}

static SV *
sv_from_iter (DiaCanvasIter *iter)
{
	AV *av;

	if (!iter)
		return &PL_sv_undef;

	av = newAV ();
	av_push (av, newSViv (iter->stamp));
	av_push (av, iter->data[0] ? SvREFCNT_inc (iter->data[0]) : &PL_sv_undef);
	av_push (av, iter->data[1] ? SvREFCNT_inc (iter->data[1]) : &PL_sv_undef);
	av_push (av, iter->data[2] ? SvREFCNT_inc (iter->data[2]) : &PL_sv_undef);

	return newRV_noinc ((SV *) av);
}

/* ------------------------------------------------------------------------- */

#define PREP(group)	\
	dSP;		\
	ENTER;		\
	SAVETMPS;	\
	PUSHMARK (SP);	\
	PUSHs (sv_2mortal (newSVDiaCanvasGroupable (group)));

#define CALL(method)	\
	PUTBACK;	\
	call_method (method, G_VOID|G_DISCARD);

#define FINISH		\
	FREETMPS;	\
	LEAVE;

#define CALL_RETURN(method)		\
	PUTBACK;			\
	call_method (method, G_SCALAR);	\
	SPAGAIN;

#define FINISH_RETURN	\
	PUTBACK;	\
	FREETMPS;	\
	LEAVE;

static void
dia2perl_canvas_groupable_add (DiaCanvasGroupable *group,
                               DiaCanvasItem *item)
{
	PREP (group);
	XPUSHs (sv_2mortal (newSVDiaCanvasItem (item)));
	CALL ("ADD");
	FINISH;
}

static void
dia2perl_canvas_groupable_remove (DiaCanvasGroupable *group,
                                  DiaCanvasItem *item)
{
	PREP (group);
	XPUSHs (sv_2mortal (newSVDiaCanvasItem (item)));
	CALL ("REMOVE");
	FINISH;
}

static gboolean
dia2perl_canvas_groupable_get_iter (DiaCanvasGroupable *group,
                                    DiaCanvasIter *iter)
{
	gboolean ret;

	PREP (group);
	CALL_RETURN ("GET_ITER");

	ret = iter_from_sv (iter, POPs);

	FINISH_RETURN;
	return ret;
}

static gboolean
dia2perl_canvas_groupable_next (DiaCanvasGroupable *group,
                                DiaCanvasIter *iter)
{
	gboolean ret;

	PREP (group);
	XPUSHs (sv_2mortal (sv_from_iter (iter)));
	CALL_RETURN ("NEXT");

	ret = iter_from_sv (iter, POPs);

	FINISH_RETURN;
	return ret;
}

static DiaCanvasItem *
dia2perl_canvas_groupable_value (DiaCanvasGroupable *group,
                                 DiaCanvasIter *iter)
{
	SV *sv;
	DiaCanvasItem *ret;

	PREP (group);
	XPUSHs (sv_2mortal (sv_from_iter (iter)));
	CALL_RETURN ("VALUE");

	sv = POPs;
	ret = (sv && SvOK (sv)) ? SvDiaCanvasItem (sv) : NULL;

	FINISH_RETURN;
	return ret;
}

static void
dia2perl_canvas_groupable_init (DiaCanvasGroupableIface *iface)
{
	iface->add = dia2perl_canvas_groupable_add;
	iface->remove = dia2perl_canvas_groupable_remove;
	iface->get_iter = dia2perl_canvas_groupable_get_iter;
	iface->next = dia2perl_canvas_groupable_next;
	iface->value = dia2perl_canvas_groupable_value;
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::Dia::CanvasGroupable	PACKAGE = Gnome2::Dia::CanvasGroupable	PREFIX = dia_canvas_groupable_

##  void dia_canvas_groupable_add (DiaCanvasGroupable *group, DiaCanvasItem *item)
void
dia_canvas_groupable_add (group, item)
	DiaCanvasGroupable *group
	DiaCanvasItem *item

##  void dia_canvas_groupable_remove (DiaCanvasGroupable *group, DiaCanvasItem *item)
void
dia_canvas_groupable_remove (group, item)
	DiaCanvasGroupable *group
	DiaCanvasItem *item

##  gboolean dia_canvas_groupable_get_iter (DiaCanvasGroupable *group, DiaCanvasIter *iter)
DiaCanvasIter_copy *
dia_canvas_groupable_get_iter (group)
	DiaCanvasGroupable *group
    PREINIT:
	DiaCanvasIter iter;
    CODE:
	if (! dia_canvas_groupable_get_iter (group, &iter))
		XSRETURN_UNDEF;
	RETVAL = &iter;
    OUTPUT:
	RETVAL

##  gboolean dia_canvas_groupable_next (DiaCanvasGroupable *group, DiaCanvasIter *iter)
gboolean
dia_canvas_groupable_next (group, iter)
	DiaCanvasGroupable *group
	DiaCanvasIter *iter

##  DiaCanvasItem* dia_canvas_groupable_value (DiaCanvasGroupable *group, DiaCanvasIter *iter)
DiaCanvasItem *
dia_canvas_groupable_value (group, iter)
	DiaCanvasGroupable *group
	DiaCanvasIter *iter

##  gint dia_canvas_groupable_length (DiaCanvasGroupable *group)
gint
dia_canvas_groupable_length (group)
	DiaCanvasGroupable *group

##  gint dia_canvas_groupable_pos (DiaCanvasGroupable *group, DiaCanvasItem *item)
gint
dia_canvas_groupable_pos (group, item)
	DiaCanvasGroupable *group
	DiaCanvasItem *item

# --------------------------------------------------------------------------- #

=for apidoc __hide__
=cut
void
_ADD_INTERFACE (class, const char *target_class)
    PREINIT:
	static const GInterfaceInfo iface_info = {
		(GInterfaceInitFunc) dia2perl_canvas_groupable_init,
		(GInterfaceFinalizeFunc) NULL,
		(gpointer) NULL
	};
    CODE:
	GType type = gperl_object_type_from_package (target_class);
	g_type_add_interface_static (type, DIA_TYPE_CANVAS_GROUPABLE,
	                             &iface_info);
