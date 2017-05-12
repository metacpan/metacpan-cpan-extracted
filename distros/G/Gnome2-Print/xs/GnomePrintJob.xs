#include "gnomeprintperl.h"


MODULE = Gnome2::Print::Job	PACKAGE = Gnome2::Print::Job	PREFIX = gnome_print_job_


GnomePrintJob_noinc *
gnome_print_job_new (class, config=NULL)
	GnomePrintConfig_ornull	* config
    C_ARGS:
	config

GnomePrintConfig_noinc * gnome_print_job_get_config (job)
	GnomePrintJob 	* job
	
GnomePrintContext_noinc * gnome_print_job_get_context (job)
	GnomePrintJob 	* job

gint gnome_print_job_close (job)
	GnomePrintJob	* job
	
gint gnome_print_job_print (job)
	GnomePrintJob	* job
	
gint gnome_print_job_render (job, ctx)
	GnomePrintJob		* job
	GnomePrintContext	* ctx

gint gnome_print_job_render_page (job, ctx, page, pageops)
	GnomePrintJob		* job
	GnomePrintContext	* ctx
	gint			page
	gboolean		pageops
	
gint gnome_print_job_get_pages (job)
	GnomePrintJob	* job

gint gnome_print_job_print_to_file (GnomePrintJob *job, gchar *output);

=for apidoc
=signature ($width, $height) = $job->get_page_size
=cut
void
gnome_print_job_get_page_size (job)
	GnomePrintJob	* job
    PREINIT:
	gdouble width;
	gdouble height;
    PPCODE:
	if (!gnome_print_job_get_page_size (job, &width, &height))
		XSRETURN_EMPTY;
	
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVnv (width)));
	PUSHs (sv_2mortal (newSVnv (height)));
