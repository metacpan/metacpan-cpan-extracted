/*
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/xs/GdkGLShapes.xs,v 1.2 2003/11/25 03:08:08 rwmcfa1 Exp $
 */

#include "gtkglextperl.h"

MODULE = Gtk2::Gdk::GLExt::Shapes	PACKAGE = Gtk2::Gdk::GLExt::Shapes	PREFIX = gdk_gl_

void
gdk_gl_draw_cube (class, solid, size)
	gboolean solid
	double   size
    C_ARGS:
	solid, size

void
gdk_gl_draw_sphere (class, solid, radius, slices, stacks)
	gboolean solid
	double   radius
	int      slices
	int      stacks
    C_ARGS:
	solid, radius, slices, stacks

void
gdk_gl_draw_cone (class, solid, base, height, slices, stacks)
	gboolean solid
	double   base
	double   height
	int      slices
	int      stacks
    C_ARGS:
	solid, base, height, slices, stacks

void
gdk_gl_draw_torus (class, solid, inner_radius, outer_radius, nsides, rings)
	gboolean solid
	double   inner_radius
	double   outer_radius
	int      nsides
	int      rings
    C_ARGS:
	solid, inner_radius, outer_radius, nsides, rings

void
gdk_gl_draw_tetrahedron (class, solid)
	gboolean solid
    C_ARGS:
	solid

void
gdk_gl_draw_octahedron (class, solid)
	gboolean solid
    C_ARGS:
	solid

void
gdk_gl_draw_dodecahedron (class, solid)
	gboolean solid
    C_ARGS:
	solid

void
gdk_gl_draw_icosahedron (solid)
	gboolean solid
    C_ARGS:
	solid

void
gdk_gl_draw_teapot (solid, scale)
	gboolean solid
	double   scale
    C_ARGS:
	solid, scale

