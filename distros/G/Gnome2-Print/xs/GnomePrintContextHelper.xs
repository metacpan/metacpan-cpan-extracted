/* This file is necessary, since all these functions, that are placed inside
 * libgnomeprint/gnome-print.h, belong to GnomePrintContext.
 */
#include "gnomeprintperl.h"


MODULE = Gnome2::Print::ContextHelper PACKAGE = Gnome2::Print::Context PREFIX = gnome_print_


gint
gnome_print_newpath    (pc)
	GnomePrintContext	* pc
	
gint
gnome_print_moveto     (pc, x,  y)
	GnomePrintContext	* pc
	gdouble		x
	gdouble		y

gint
gnome_print_lineto     (pc, x, y)
	GnomePrintContext	* pc
	gdouble		x
	gdouble		y
	
gint
gnome_print_curveto    (pc, x1, y1, x2, y2, x3, y3)
	GnomePrintContext	* pc
	gdouble		x1
	gdouble		y1
	gdouble		x2
	gdouble		y2
	gdouble		x3
	gdouble		y3
	
gint
gnome_print_closepath  (pc)
	GnomePrintContext	* pc
	
gint
gnome_print_strokepath (pc)
	GnomePrintContext	* pc
	
##gint gnome_print_bpath      (GnomePrintContext *pc, const ArtBpath *bpath, gboolean append)
##gint gnome_print_vpath      (GnomePrintContext *pc, const ArtVpath *vpath, gboolean append)

gint
gnome_print_arcto      (pc, x, y, radius, angle1, angle2, direction)
	GnomePrintContext	* pc
	gdouble		x
	gdouble		y
	gdouble		radius
	gdouble		angle1
	gdouble		angle2
	gint 		direction

gint
gnome_print_setrgbcolor   (pc, r, g, b)
	GnomePrintContext	* pc
	gdouble		r
	gdouble		g
	gdouble		b
	
gint
gnome_print_setopacity    (pc, opacity)
	GnomePrintContext	* pc
	gdouble		opacity
	
gint
gnome_print_setlinewidth  (pc, width)
	GnomePrintContext	* pc
	gdouble		width
	
gint
gnome_print_setmiterlimit (pc, limit)
	GnomePrintContext	* pc
	gdouble		limit
	
gint
gnome_print_setlinejoin   (pc, jointype)
	GnomePrintContext	* pc
	gint	jointype
	
gint
gnome_print_setlinecap    (pc, captype)
	GnomePrintContext	* pc
	gint	captype
	
##gint gnome_print_setdash       (GnomePrintContext *pc, gint n_values, const gdouble *values, gdouble offset);

gint
gnome_print_setfont       (pc, font)
	GnomePrintContext	* pc
	GnomeFont		* font
	
gint
gnome_print_clip          (pc)
	GnomePrintContext	* pc
	
gint
gnome_print_eoclip        (pc)
	GnomePrintContext	* pc

##gint gnome_print_concat    (GnomePrintContext *pc, const gdouble *matrix);

gint
gnome_print_scale     (pc, sx, sy)
	GnomePrintContext	* pc
	gdouble		sx
	gdouble		sy
	
gint
gnome_print_rotate    (pc, theta)
	GnomePrintContext	* pc
	gdouble		theta
	
gint
gnome_print_translate (pc, x, y)
	GnomePrintContext	* pc
	gdouble		x
	gdouble		y

gint
gnome_print_gsave    (pc)
	GnomePrintContext	* pc
	
gint
gnome_print_grestore (pc)
	GnomePrintContext	* pc

gint
gnome_print_fill   (pc)
	GnomePrintContext	* pc
	
gint
gnome_print_eofill (pc)
	GnomePrintContext	* pc
	
gint
gnome_print_stroke (pc)
	GnomePrintContext	* pc

gint
gnome_print_show       (pc, text)
	GnomePrintContext	* pc
	const guchar		* text
	
gint
gnome_print_show_sized (pc, text, bytes)
	GnomePrintContext	* pc
	const guchar		* text
	gint			bytes
	
gint
gnome_print_glyphlist  (pc, glyphlist)
	GnomePrintContext	* pc
	GnomeGlyphList		* glyphlist

gint
gnome_print_grayimage (pc, data, width, height, rowstride)
	GnomePrintContext	* pc
	const guchar		* data
	gint			width
	gint			height
	gint			rowstride
	
gint
gnome_print_rgbimage  (pc, data, width, height, rowstride)
	GnomePrintContext	* pc
	const guchar		* data
	gint			width
	gint			height
	gint			rowstride
	
gint
gnome_print_rgbaimage (pc, data, width, height, rowstride)
	GnomePrintContext	* pc
	const guchar		* data
	gint			width
	gint			height
	gint			rowstride

gint
gnome_print_beginpage (pc, name)
	GnomePrintContext	* pc
	const guchar		* name
	
gint
gnome_print_showpage (pc)
	GnomePrintContext	* pc

gint
gnome_print_line_stroked (pc, x0, y0, x1, y1)
	GnomePrintContext	* pc
	gdouble		x0
	gdouble		y0
	gdouble		x1
	gdouble		y1
	
gint
gnome_print_rect_stroked (pc, x, y, width, height)
	GnomePrintContext	* pc
	gdouble		x
	gdouble		y
	gdouble		width
	gdouble		height
	
gint
gnome_print_rect_filled  (pc, x, y, width, height)
	GnomePrintContext	* pc
	gdouble		x
	gdouble		y
	gdouble		width
	gdouble		height
