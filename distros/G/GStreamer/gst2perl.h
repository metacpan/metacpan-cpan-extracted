/*
 * Copyright (C) 2005 by the gtk2-perl team
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
 * Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * $Id$
 */

#ifndef _GST2PERL_H_
#define _GST2PERL_H_

#include <gperl.h>

#include <gst/gst.h>

/* Starting with 0.10.17, libgstreamer provides this macro. */
#ifndef GST_CHECK_VERSION
# include "gst2perl-version.h"
#endif

#include "gst2perl-autogen.h"

/* GstMiniObject support. */
void gst2perl_register_mini_object (GType type, const char *package);

typedef const char * (*Gst2PerlMiniObjectPackageLookupFunc) (GstMiniObject *object);
void gst2perl_register_mini_object_package_lookup_func (GType type, Gst2PerlMiniObjectPackageLookupFunc func);

SV * gst2perl_sv_from_mini_object (GstMiniObject *object, gboolean own);
GstMiniObject * gst2perl_mini_object_from_sv (SV *sv);

/* Custom enum handling. */
#undef newSVGstFormat
#undef SvGstFormat
SV * newSVGstFormat (GstFormat format);
GstFormat SvGstFormat (SV *sv);

#undef newSVGstQueryType
#undef SvGstQueryType
SV * newSVGstQueryType (GstQueryType type);
GstQueryType SvGstQueryType (SV *sv);

/* Custom type converters. */
SV * newSVGstStructure (const GstStructure *structure);
GstStructure * SvGstStructure (SV *sv);

SV * newSVGstIterator (const GstIterator *iter);
GstIterator * SvGstIterator (SV *sv);

SV * newSVGstClockTime (GstClockTime time);
GstClockTime SvGstClockTime (SV *time);

SV * newSVGstClockTimeDiff (GstClockTimeDiff diff);
GstClockTimeDiff SvGstClockTimeDiff (SV *diff);

SV * newSVGstClockID (GstClockID id);
GstClockID SvGstClockID (SV *sv);

#endif /* _GST2PERL_H_ */
