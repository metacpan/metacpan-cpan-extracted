/*
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/xs/GtkGLInit.xs,v 1.2 2003/11/25 03:08:08 rwmcfa1 Exp $
 */

#include "gtkglextperl.h"

MODULE = Gtk2::GLExt::Init	PACKAGE = Gtk2::GLExt	PREFIX = gtk_gl_

##  void gtk_gl_init (int *argc, char ***argv)
##  gboolean gtk_gl_init_check (int *argc, char ***argv)
##  gboolean gtk_gl_parse_args (int *argc, char ***argv)
gboolean
gtk_gl_inits(class)
    ALIAS:
	Gtk2::GLExt::init = 0
	Gtk2::GLExt::init_check = 1
	Gtk2::GLExt::parse_args = 2
    PREINIT:
	AV * ARGV;
	SV * ARGV0;
	int argc, len, i;
	char ** argv, ** shadow;
    CODE:
	/*
	 * heavily borrowed from gtk-perl, and then from Gtk2-Perl's Gtk2
	 *
	 * given the way perl handles the refcounts on SVs and the strings
	 * to which they point, i'm not certain that the g_strdup'ing of
	 * the string values is entirely necessary; however, this compiles
	 * and runs and doesn't appear either to leak or segfault, so i'll
	 * leave it.
	 */
	RETVAL = FALSE;
	argv = NULL;
	ARGV = get_av ("ARGV", FALSE);
	ARGV0 = get_sv ("0", FALSE);

	/* construct the argv argument... we'll have to prepend @ARGV with $0
	 * to make it look real. */
	len = av_len (ARGV) + 1;
	argc = len + 1;
	shadow = g_new0 (char*, len + 1);
	argv = g_new0 (char*, argc);
	argv[0] = SvPV_nolen (ARGV0);
	/*warn ("argc = %d\n", argc);*/
	/*warn ("argv[0] = %s\n", argv[0]);*/
	for (i = 0 ; i < len ; i++) {
		SV * sv = av_shift (ARGV);
		shadow[i] = argv[i+1] = g_strdup (SvPV_nolen (sv));
		/*warn ("argv[%d] = %s\n", i+1, argv[i+1]);*/
	}
	/* note that we've emptied @ARGV. */
	/* use it... */
	switch( ix )
	{
	case 0:
		gtk_gl_init (&argc, &argv);
		/* if this fails, it does not return. */
		RETVAL = TRUE;
		break;
	case 1:
		RETVAL = gtk_gl_init_check (&argc, &argv);
		break;
	case 2:
		RETVAL = gtk_gl_parse_args (&argc, &argv);
		break;
	}

	/* refill @ARGV with whatever wasn't stolen above. */
	for (i = 1 ; i < argc ; i++) {
		av_push (ARGV, newSVpv (argv[i], 0));
		/*warn ("pushing back %s\n", argv[i]);*/
	}
	g_free (argv);
	g_strfreev (shadow);
    OUTPUT:
	RETVAL
