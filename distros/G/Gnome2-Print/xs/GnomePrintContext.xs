#include "gnomeprintperl.h"

MODULE = Gnome2::Print::Context	PACKAGE = Gnome2::Print::Context PREFIX = gnome_print_context_


BOOT:
	gperl_object_set_no_warn_unreg_subclass (GNOME_TYPE_PRINT_CONTEXT, TRUE);


GnomePrintContext_noinc *
gnome_print_context_new (class, config)
	GnomePrintConfig	* config
    C_ARGS:
	config

gint gnome_print_context_close (pc)
	GnomePrintContext	* pc

gint gnome_print_context_create_transport (ctx)
	GnomePrintContext	* ctx
