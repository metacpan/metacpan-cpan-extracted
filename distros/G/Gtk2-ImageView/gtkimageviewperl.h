/*
 * Copyright (c) 2007 by Jeffrey Ratcliffe <Jeffrey.Ratcliffe@gmail.com>
 * see AUTHORS for complete list of contributors
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef _GTKIMAGEVIEWPERL_H_
#define _GTKIMAGEVIEWPERL_H_

/* Include all of gtkimageview's headers for internal consistency */
#include <gtkimageview/gtkimageview.h>
#include <gtkimageview/gtkimagenav.h>
#include <gtkimageview/gtkimagescrollwin.h>
#include <gtkimageview/gtkiimagetool.h>
#include <gtkimageview/gtkimagetooldragger.h>
#include <gtkimageview/gtkimagetoolpainter.h>
#include <gtkimageview/gtkimagetoolselector.h>
#include <gtkimageview/gtkanimview.h>
#include <gtkimageview/gdkpixbufdrawcache.h>
#include <gtkimageview/gtkimageview-typebuiltins.h>
#include <gtkimageview/cursors.h>
#include <gtkimageview/gtkzooms.h>

/* Get important stuff from gtk2-perl */
#include <gtk2perl.h>

/* Binding definitions -- order is important */
#include "gtkimageviewperl-autogen.h"
#define GDK_TYPE_PIXBUF_DRAW_OPTS (gdk_pixbuf_draw_opts_get_type ())
GType gdk_pixbuf_draw_opts_get_type (void) G_GNUC_CONST;
#define GDK_TYPE_PIXBUF_DRAW_CACHE (gdk_pixbuf_draw_cache_get_type ())
GType gdk_pixbuf_draw_cache_get_type (void) G_GNUC_CONST;

/* Only in very new versions of Glib-Perl */
#ifndef gperl_sv_is_hash_ref
#define gperl_sv_is_hash_ref(sv) \
    ((sv) && SvOK (sv) && SvROK (sv) && SvTYPE (SvRV (sv)) == SVt_PVHV)
#endif

/* need a prototype for this as it is used in several places */
GdkPixbufDrawOpts * SvGdkPixbufDrawOpts (SV * sv);
SV * newSVGdkPixbufDrawOpts (GdkPixbufDrawOpts * opts);

#endif /* _GTKIMAGEVIEWPERL_H_ */
