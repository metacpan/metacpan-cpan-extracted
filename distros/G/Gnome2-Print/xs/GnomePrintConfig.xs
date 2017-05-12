#include "gnomeprintperl.h"

MODULE = Gnome2::Print::Config	PACKAGE = Gnome2::Print::Config PREFIX = gnome_print_config_

### some convenience keys to be used with set/get...
### the key's string returned is constant, so we don't need to think about it.
char *
constants (class)
    ALIAS:
    	Gnome2::Print::Config::key_paper_size = 1
	Gnome2::Print::Config::key_paper_width = 2
	Gnome2::Print::Config::key_paper_height = 3
	Gnome2::Print::Config::key_paper_orientation = 4
	Gnome2::Print::Config::key_paper_orientation_matrix = 5
	Gnome2::Print::Config::key_page_orientation = 6
	Gnome2::Print::Config::key_page_orientation_matrix = 7
	Gnome2::Print::Config::key_orientation = 8
	Gnome2::Print::Config::key_layout = 9
	Gnome2::Print::Config::key_layout_width = 10
	Gnome2::Print::Config::key_layout_height = 11
	Gnome2::Print::Config::key_resolution = 12
	Gnome2::Print::Config::key_resolution_dpi = 13
	Gnome2::Print::Config::key_resolution_dpi_x = 14
	Gnome2::Print::Config::key_resolution_dpi_y = 15
	Gnome2::Print::Config::key_num_copies = 16
	Gnome2::Print::Config::key_collate = 17
	Gnome2::Print::Config::key_page_margin_right = 18
	Gnome2::Print::Config::key_page_margin_left = 19
	Gnome2::Print::Config::key_page_margin_top = 20
	Gnome2::Print::Config::key_page_margin_bottom = 21
	Gnome2::Print::Config::key_paper_margin_right = 22
	Gnome2::Print::Config::key_paper_margin_left = 23
	Gnome2::Print::Config::key_paper_margin_top = 24
	Gnome2::Print::Config::key_paper_margin_bottom = 25
	Gnome2::Print::Config::key_output_filename = 26
	Gnome2::Print::Config::key_document_name = 27
	Gnome2::Print::Config::key_prefered_unit = 28
    CODE:
    	switch (ix) {
		case  1: RETVAL = GNOME_PRINT_KEY_PAPER_SIZE; break;
		case  2: RETVAL = GNOME_PRINT_KEY_PAPER_WIDTH; break;
		case  3: RETVAL = GNOME_PRINT_KEY_PAPER_HEIGHT; break;
		case  4: RETVAL = GNOME_PRINT_KEY_PAPER_ORIENTATION; break;
		case  5: RETVAL = GNOME_PRINT_KEY_PAPER_ORIENTATION_MATRIX; break;
		case  6: RETVAL = GNOME_PRINT_KEY_PAGE_ORIENTATION; break;
		case  7: RETVAL = GNOME_PRINT_KEY_PAGE_ORIENTATION_MATRIX; break;
		case  8: RETVAL = GNOME_PRINT_KEY_ORIENTATION; break;
		case  9: RETVAL = GNOME_PRINT_KEY_LAYOUT; break;
		case 10: RETVAL = GNOME_PRINT_KEY_LAYOUT_WIDTH; break;
		case 11: RETVAL = GNOME_PRINT_KEY_LAYOUT_HEIGHT; break;
		case 12: RETVAL = GNOME_PRINT_KEY_RESOLUTION; break;
		case 13: RETVAL = GNOME_PRINT_KEY_RESOLUTION_DPI; break;
		case 14: RETVAL = GNOME_PRINT_KEY_RESOLUTION_DPI_X; break;
		case 15: RETVAL = GNOME_PRINT_KEY_RESOLUTION_DPI_Y; break;
		case 16: RETVAL = GNOME_PRINT_KEY_NUM_COPIES; break;
		case 17: RETVAL = GNOME_PRINT_KEY_COLLATE; break;
		case 18: RETVAL = GNOME_PRINT_KEY_PAGE_MARGIN_LEFT; break;
		case 19: RETVAL = GNOME_PRINT_KEY_PAGE_MARGIN_RIGHT; break;
		case 20: RETVAL = GNOME_PRINT_KEY_PAGE_MARGIN_TOP; break;
		case 21: RETVAL = GNOME_PRINT_KEY_PAGE_MARGIN_BOTTOM; break;
		case 22: RETVAL = GNOME_PRINT_KEY_PAPER_MARGIN_LEFT; break;
		case 23: RETVAL = GNOME_PRINT_KEY_PAPER_MARGIN_RIGHT; break;
		case 24: RETVAL = GNOME_PRINT_KEY_PAPER_MARGIN_TOP; break;
		case 25: RETVAL = GNOME_PRINT_KEY_PAPER_MARGIN_BOTTOM; break;
		case 26: RETVAL = GNOME_PRINT_KEY_OUTPUT_FILENAME; break;
		case 27: RETVAL = GNOME_PRINT_KEY_DOCUMENT_NAME; break;
		case 28: RETVAL = GNOME_PRINT_KEY_PREFERED_UNIT; break;

		default: RETVAL = NULL;
	}
    OUTPUT:
	RETVAL

GnomePrintConfig_noinc *
gnome_print_config_default (class);
    C_ARGS:
	/* void */

gchar_own *
gnome_print_config_to_string (gpc, flags)
	GnomePrintConfig	* gpc
	guint			flags

GnomePrintConfig_noinc *
gnome_print_config_from_string (str, flags)
	const gchar	* str
	guint		flags

void
gnome_print_config_dump (gpc)
	GnomePrintConfig	* gpc

=for apidoc
=signature ($width, $height) = $gpc->get_page_size
=cut
void
gnome_print_config_get_page_size (gpc)
	GnomePrintConfig	* gpc
    PREINIT:
    	gdouble width;
	gdouble height;
    PPCODE:
    	if (!gnome_print_config_get_page_size (gpc, &width, &height))
		XSRETURN_EMPTY;
	
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVnv (width)));
	PUSHs (sv_2mortal (newSVnv (height)));


### The get* methods should all FALSE if the key is not found (except
### gnome_print_config_get, which returns NULL), and use the "value"
### argument for storing the key's value. Here, we change it a little
### bit, and make the method return undef in case of failure, or the
### wanted scalar in case of success.
void
gnome_print_config_gets (config, key)
	GnomePrintConfig * config
	const guchar * key
    ALIAS:
    	Gnome2::Print::Config::get = 0
	Gnome2::Print::Config::get_int = 1
	Gnome2::Print::Config::get_boolean = 2
	Gnome2::Print::Config::get_double = 3
    PPCODE:
    	switch (ix) {
		case 0: {
			gchar_own *value;
			value = (gchar_own *) gnome_print_config_get (config, key);
			if (! value)
				XSRETURN_UNDEF;
			EXTEND (SP, 1);
			PUSHs (sv_2mortal (newSVGChar (value)));
			break;
		}
		case 1: {
			gint value;
			if (! gnome_print_config_get_int (config, key, &value))
				XSRETURN_UNDEF;
			EXTEND (SP, 1);
			PUSHs (sv_2mortal (newSViv (value)));
			break;
		}
		case 2: {
			gboolean value;
			if (! gnome_print_config_get_boolean (config, key, &value))
				XSRETURN_UNDEF;
			EXTEND (SP, 1);
			PUSHs (sv_2mortal (newSViv (value)));
			break;
		}
		case 3: {
			gdouble value;
			if (! gnome_print_config_get_double (config, key, &value))
				XSRETURN_UNDEF;
			EXTEND (SP, 1),
			PUSHs (sv_2mortal (newSVnv (value)));
			break;
		}
	}

##guchar * gnome_print_config_get (GnomePrintConfig *config, const guchar *key);
##gboolean gnome_print_config_set (GnomePrintConfig *config, const guchar *key, const guchar *value);

gboolean
gnome_print_config_set (config, key, value)
	GnomePrintConfig * config
	const guchar * key
	const guchar * value

##gboolean gnome_print_config_get_boolean (GnomePrintConfig *config, const guchar *key, gboolean *val)

##gboolean gnome_print_config_get_int     (GnomePrintConfig *config, const guchar *key, gint *val);
##gboolean gnome_print_config_get_double  (GnomePrintConfig *config, const guchar *key, gdouble *val);
##gboolean gnome_print_config_get_length  (GnomePrintConfig *config, const guchar *key, gdouble *val, const GnomePrintUnit **unit);

### The set* methods are just fine returning a boolean, so we bind them as they
### are.
gboolean
gnome_print_config_set_boolean (config, key, val)
	GnomePrintConfig 	* config
	const guchar 		* key
	gboolean 		val

gboolean
gnome_print_config_set_int (config, key, val)
	GnomePrintConfig 	* config
	const guchar 		* key
	gint val
	
gboolean
gnome_print_config_set_double (config, key, val)
	GnomePrintConfig 	* config
	const guchar 		* key
	gdouble 		val

##gboolean gnome_print_config_set_length (GnomePrintConfig *config, const guchar *key, gdouble val, const GnomePrintUnit *unit);
gboolean
gnome_print_config_set_length (config, key, val, unit)
	GnomePrintConfig	* config
	const guchar		* key
	gdouble			val
	const GnomePrintUnit	* unit
