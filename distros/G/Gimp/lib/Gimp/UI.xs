#include "config.h"

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "gppport.h"

#include <gperl.h>

#include <libgimp/gimp.h>
#include <libgimp/gimpui.h>
#ifdef GIMP_HAVE_EXPORT
#include <libgimp/gimpexport.h>
#endif

#include <glib-object.h>

#include <gtk2perl-autogen.h>

/* need to factor these out, otherwise we always need gtk :( */
#include <libgimpwidgets/gimpwidgets.h>
#include <libgimpbase/gimpbasetypes.h>

#include "gimp-perl.h"

static void
sv_color3 (SV *sv, gdouble *e, gdouble *f, gdouble *g, gdouble *a)
{
  if (!SvROK (sv)
      || SvTYPE (SvRV (sv)) != SVt_PVAV
      || av_len ((AV *)SvRV (sv)) < 2
      || av_len ((AV *)SvRV (sv)) > 3)
    croak ("GimpRGB/HSV/HLS must be specified as an arrayref with length three or four");

  *e = SvNV (*av_fetch ((AV *)SvRV (sv), 0, 1));
  *f = SvNV (*av_fetch ((AV *)SvRV (sv), 1, 1));
  *g = SvNV (*av_fetch ((AV *)SvRV (sv), 2, 1));
  *a = av_len ((AV *)SvRV (sv)) < 3
             ? 1.
             : SvNV (*av_fetch ((AV *)SvRV (sv), 3, 1));
}

static SV *
newSV_color3 (gdouble e, gdouble f, gdouble g, gdouble a)
{
  AV *av = newAV ();

  av_push (av, newSVnv (e));
  av_push (av, newSVnv (f));
  av_push (av, newSVnv (g));
  av_push (av, newSVnv (a));

  return newRV_noinc ((SV *)av);
}

#define ENUM(name)          \
  static GType t_ ## name;      \
  static GType name ## _type (void) \
  {                 \
    if (!t_ ## name)            \
      t_ ## name = g_enum_register_static (# name, _ ## name ## _values);   \
    return t_ ## name;          \
  }

static const GEnumValue _gimp_unit_values[] = {
  { GIMP_UNIT_PIXEL, "GIMP_UNIT_PIXEL", "pixel" },
  { GIMP_UNIT_INCH, "GIMP_UNIT_INCH", "inch" },
  { GIMP_UNIT_MM, "GIMP_UNIT_MM", "mm" },
  { GIMP_UNIT_POINT, "GIMP_UNIT_POINT", "point" },
  { GIMP_UNIT_PICA, "GIMP_UNIT_PICA", "pica" },
  { GIMP_UNIT_END, "GIMP_UNIT_END", "end" },
  { 0, NULL, NULL }
};
ENUM(gimp_unit)
static const GEnumValue _gimp_chain_position_values[] = {
  { GIMP_CHAIN_TOP, "GIMP_CHAIN_TOP", "top" },
  { GIMP_CHAIN_LEFT, "GIMP_CHAIN_LEFT", "left" },
  { GIMP_CHAIN_BOTTOM, "GIMP_CHAIN_BOTTOM", "bottom" },
  { GIMP_CHAIN_RIGHT, "GIMP_CHAIN_RIGHT", "right" },
  { 0, NULL, NULL }
};
ENUM(gimp_chain_position)
static const GEnumValue _gimp_color_area_type_values[] = {
  { GIMP_COLOR_AREA_FLAT, "GIMP_COLOR_AREA_FLAT", "flat" },
  { GIMP_COLOR_AREA_SMALL_CHECKS, "GIMP_COLOR_AREA_SMALL_CHECKS", "small-checks" },
  { GIMP_COLOR_AREA_LARGE_CHECKS, "GIMP_COLOR_AREA_LARGE_CHECKS", "large-checks" },
  { 0, NULL, NULL }
};
ENUM(gimp_color_area_type)
static const GEnumValue _gimp_color_selector_channel_values[] = {
  { GIMP_COLOR_SELECTOR_HUE, "GIMP_COLOR_SELECTOR_HUE", "hue" },
  { GIMP_COLOR_SELECTOR_SATURATION, "GIMP_COLOR_SELECTOR_SATURATION", "saturation" },
  { GIMP_COLOR_SELECTOR_VALUE, "GIMP_COLOR_SELECTOR_VALUE", "value" },
  { GIMP_COLOR_SELECTOR_RED, "GIMP_COLOR_SELECTOR_RED", "red" },
  { GIMP_COLOR_SELECTOR_GREEN, "GIMP_COLOR_SELECTOR_GREEN", "green" },
  { GIMP_COLOR_SELECTOR_BLUE, "GIMP_COLOR_SELECTOR_BLUE", "blue" },
  { GIMP_COLOR_SELECTOR_ALPHA, "GIMP_COLOR_SELECTOR_ALPHA", "alpha" },
  { 0, NULL, NULL }
};
ENUM(gimp_color_selector_channel)
static const GEnumValue _gimp_size_entry_update_policy_values[] = {
  { GIMP_SIZE_ENTRY_UPDATE_NONE, "GIMP_SIZE_ENTRY_UPDATE_NONE", "none" },
  { GIMP_SIZE_ENTRY_UPDATE_SIZE, "GIMP_SIZE_ENTRY_UPDATE_SIZE", "size" },
  { GIMP_SIZE_ENTRY_UPDATE_RESOLUTION, "GIMP_SIZE_ENTRY_UPDATE_RESOLUTION", "resolution" },
  { 0, NULL, NULL }
};
ENUM(gimp_size_entry_update_policy)

#define SvGimpRGB(sv, color) sv_color3 ((sv), &(color).r, &(color).g, &(color).b, &(color).a)
#define SvGimpHSV(sv, color) sv_color3 ((sv), &(color).h, &(color).s, &(color).v, &(color).a)

#define newSVGimpRGB(color) newSV_color3 ((color).r, (color).g, (color).b, (color).a)
#define newSVGimpHSV(color) newSV_color3 ((color).h, (color).s, (color).v, (color).a)

typedef GtkWidget GimpMemsizeEntry_own;
typedef GtkWidget GimpButton_own;
typedef GtkWidget GimpChainButton_own;
typedef GtkWidget GimpColorArea_own;
typedef GtkWidget GimpColorButton_own;
typedef GtkWidget GimpColorDisplay_own;
typedef GtkWidget GimpColorNotebook_own;
typedef GtkWidget GimpColorScale_own;
typedef GtkWidget GimpColorSelect_own;
typedef GtkWidget GimpColorSelector_own;
typedef GtkWidget GimpDialog_own;
typedef GtkWidget GimpFileEntry_own;
typedef GtkWidget GimpFontSelectButton_own;
typedef GtkWidget GimpOffsetArea_own;
typedef GtkWidget GimpPathEditor_own;
typedef GtkWidget GimpPickButton_own;
typedef GtkWidget GimpPixmap_own;
typedef GtkWidget GimpSizeEntry_own;
typedef GtkWidget GimpUnitMenu_own;

MODULE = Gimp::UI	PACKAGE = Gimp::UI

BOOT:
	gimp_ui_init (g_strdup (SvPV_nolen (get_sv("0", 0))), 0);

PROTOTYPES: ENABLE

void
set_transient(window)
  GtkWindow *window
  CODE:
    if (gimp_display_name())
      gimp_window_set_transient (window);

gint32
export_image(image_ID, drawable_ID, format_name, capabilities)
	SV *	image_ID
        SV *	drawable_ID
        gchar *	format_name
        gint	capabilities
        PREINIT:
          gint32 image;
          gint32 drawable;
        CODE:
          image = SvIV (SvRV (image_ID));
          drawable = SvIV (SvRV (drawable_ID));
	  if (gimp_display_name())
	    RETVAL = gimp_export_image (&image, &drawable, format_name, capabilities);
	  else
	    RETVAL = GIMP_EXPORT_IGNORE; /* fake if no UI */
          sv_setiv (SvRV (image_ID), image);
          sv_setiv (SvRV (drawable_ID), drawable);
	OUTPUT:
        image_ID
        drawable_ID
        RETVAL

MODULE = Gimp::UI	PACKAGE = Gimp::UI::MemsizeEntry	PREFIX = gimp_memsize_entry_

BOOT:
	gperl_register_object (GIMP_TYPE_MEMSIZE_ENTRY, "Gimp::UI::MemsizeEntry");

GimpMemsizeEntry_own * gimp_memsize_entry_new (SV *unused_class, gulong value, gulong lower, gulong upper)
	C_ARGS: value, lower, upper

void gimp_memsize_entry_set_value (GimpMemsizeEntry *entry, gulong value)

gulong gimp_memsize_entry_get_value (GimpMemsizeEntry *entry)

MODULE = Gimp::UI	PACKAGE = Gimp::UI::Button	PREFIX = gimp_button_

BOOT:
	gperl_register_object (GIMP_TYPE_BUTTON, "Gimp::UI::Button");

GimpButton_own * gimp_button_new (SV *unused_class)
	C_ARGS:

void gimp_button_extended_clicked (GimpButton *button, GdkModifierType state);

MODULE = Gimp::UI	PACKAGE = Gimp::UI::ChainButton	PREFIX = gimp_chain_button_

BOOT:
	gperl_register_object (GIMP_TYPE_CHAIN_BUTTON, "Gimp::UI::ChainButton");

GimpChainButton_own * gimp_chain_button_new (SV *unused_class, GimpChainPosition position)
	C_ARGS: position

void gimp_chain_button_set_active (GimpChainButton *button, gboolean active);

gboolean gimp_chain_button_get_active (GimpChainButton *button);

MODULE = Gimp::UI	PACKAGE = Gimp::UI::ColorArea	PREFIX = gimp_color_area_

BOOT:
	gperl_register_object (GIMP_TYPE_COLOR_AREA, "Gimp::UI::ColorArea");

GimpColorArea_own * gimp_color_area_new (SV *unused_class, GimpRGB &color, GimpColorAreaType type, GdkModifierType drag_mask)
	C_ARGS: color, type, drag_mask

void gimp_color_area_set_color (GimpColorArea *area, GimpRGB &color)

void gimp_color_area_get_color (GimpColorArea *area, OUTLIST GimpRGB color)

gboolean gimp_color_area_has_alpha (GimpColorArea *area)

void gimp_color_area_set_type (GimpColorArea *area, GimpColorAreaType type)

void gimp_color_area_set_draw_border (GimpColorArea *area, gboolean draw_border)

MODULE = Gimp::UI	PACKAGE = Gimp::UI::ColorButton	PREFIX = gimp_color_button_

BOOT:
	gperl_register_object (GIMP_TYPE_COLOR_BUTTON, "Gimp::UI::ColorButton");

GimpColorButton_own * gimp_color_button_new (SV *unused_class, utf8_str title, gint width, gint height, \
                                             GimpRGB &color, GimpColorAreaType type)
	C_ARGS: title, width, height, color, type

void gimp_color_button_set_color (GimpColorButton *button, GimpRGB &color)

void gimp_color_button_get_color (GimpColorButton *button, OUTLIST GimpRGB color)

gboolean gimp_color_button_has_alpha (GimpColorButton *button)

void gimp_color_button_set_type (GimpColorButton *button, GimpColorAreaType type);

MODULE = Gimp::UI	PACKAGE = Gimp::UI::ColorDisplay	PREFIX = gimp_color_display_

BOOT:
	gperl_register_object (GIMP_TYPE_COLOR_DISPLAY, "Gimp::UI::ColorDisplay");
#
#GimpColorDisplay_own * gimp_color_display_new (SV *unused_class)
#	C_ARGS: gimp_color_display_type ()
#
#GimpColorDisplay_own * gimp_color_display_clone (GimpColorDisplay *display)
#
#void gimp_color_display_convert (GimpColorDisplay *display, guchar *buf, gint width, gint height, gint bpp, gint bpl)
#
#void gimp_color_display_load_state (GimpColorDisplay *display, GimpParasite *state)
#
#GimpParasite * gimp_color_display_save_state (GimpColorDisplay *display)
#
#GtkWidget * gimp_color_display_configure (GimpColorDisplay *display)
#
#void gimp_color_display_configure_reset (GimpColorDisplay *display)
#
#void gimp_color_display_changed (GimpColorDisplay *display)

MODULE = Gimp::UI	PACKAGE = Gimp::UI::ColorNotebook	PREFIX = gimp_color_notebook_

BOOT:
	gperl_register_object (GIMP_TYPE_COLOR_NOTEBOOK, "Gimp::UI::ColorNotebook");

GimpColorNotebook_own *new (SV *unused_class)
	CODE:
        RETVAL = (GimpColorNotebook_own *)g_object_new (GIMP_TYPE_COLOR_NOTEBOOK, (gchar *)0);
        OUTPUT:
        RETVAL

# not the slightest idea...
#GtkWidget * gimp_color_notebook_set_has_page (GimpColorNotebook *notebook,
#                                              GType              page_type,
#                                              gboolean           has_page);

MODULE = Gimp::UI	PACKAGE = Gimp::UI::ColorScale	PREFIX = gimp_color_scale_

BOOT:
	gperl_register_object (GIMP_TYPE_COLOR_SCALE, "Gimp::UI::ColorScale");

GimpColorScale_own * gimp_color_scale_new (SV *unused_class, GtkOrientation orientation, GimpColorSelectorChannel channel)
	C_ARGS: orientation, channel

void gimp_color_scale_set_channel (GimpColorScale *scale, GimpColorSelectorChannel channel)

void gimp_color_scale_set_color (GimpColorScale *scale, GimpRGB &rgb, GimpHSV &hsv)

MODULE = Gimp::UI	PACKAGE = Gimp::UI::ColorSelect	PREFIX = gimp_color_select_

BOOT:
	gperl_register_object (GIMP_TYPE_COLOR_SELECT, "Gimp::UI::ColorSelect");

GimpColorSelect_own *new(SV *unused_class)
	CODE:
        RETVAL = (GimpColorSelect_own *)g_object_new (GIMP_TYPE_COLOR_SELECT, (gchar *)0);
        OUTPUT:
        RETVAL

MODULE = Gimp::UI	PACKAGE = Gimp::UI::ColorSelector	PREFIX = gimp_color_selector_

BOOT:
	gperl_register_object (GIMP_TYPE_COLOR_SELECTOR, "Gimp::UI::ColorSelector");

GimpColorSelector_own * gimp_color_selector_new (SV *unused_class, GimpRGB &rgb, GimpHSV &hsv, \
                                                 GimpColorSelectorChannel channel)
	C_ARGS: GIMP_TYPE_COLOR_SELECTOR, rgb, hsv, channel

void gimp_color_selector_set_toggles_visible (GimpColorSelector *selector, gboolean visible)

void gimp_color_selector_set_toggles_sensitive (GimpColorSelector *selector, gboolean sensitive)

void gimp_color_selector_set_show_alpha (GimpColorSelector *selector, gboolean show_alpha)

void gimp_color_selector_set_color (GimpColorSelector *selector, GimpRGB &rgb, GimpHSV &hsv)

void gimp_color_selector_set_channel (GimpColorSelector *selector, GimpColorSelectorChannel channel)

void gimp_color_selector_color_changed (GimpColorSelector *selector)

void gimp_color_selector_channel_changed (GimpColorSelector *selector)

MODULE = Gimp::UI	PACKAGE = Gimp::UI::Dialog	PREFIX = gimp_dialog_

BOOT:
	gperl_register_object (GIMP_TYPE_DIALOG, "Gimp::UI::Dialog");

#GimpDialog_own * gimp_dialog_new (SV *unused_class,
#                                  utf8_str wmclass_name, GimpHelpFunc help_func, utf8_str help_data,
#                                  GtkWindowPosition position, gint allow_shrink = 1, gint allow_grow = 1, gint auto_shrink = 1)
#	C_ARGS:wmclass_name, help_func, help_data, position, allow_shrink, allow_grow, auto_shrink

#					     /* specify action area buttons
#					      * as va_list:
#					      *  const gchar    *label,
#					      *  GCallback       callback,
#					      *  gpointer        callback_data,
#					      *  GObject        *slot_object,
#					      *  GtkWidget     **widget_ptr,
#					      *  gboolean        default_action,
#					      *  gboolean        connect_delete,
#					      */

#					     ...);

#GtkWidget * gimp_dialog_newv                (const gchar        *title,
#					     const gchar        *wmclass_name,
#					     GimpHelpFunc        help_func,
#					     const gchar        *help_data,
#					     GtkWindowPosition   position,
#					     gint                allow_shrink,
#					     gint                allow_grow,
#					     gint                auto_shrink,
#					     va_list             args);

#void        gimp_dialog_create_action_area  (GimpDialog         *dialog,

#					     /* specify action area buttons
#					      * as va_list:
#					      *  const gchar    *label,
#					      *  GCallback       callback,
#					      *  gpointer        callback_data,
#					      *  GObject        *slot_object,
#					      *  GtkWidget     **widget_ptr,
#					      *  gboolean        default_action,
#					      *  gboolean        connect_delete,
#					      */

#					     ...);

#void        gimp_dialog_create_action_areav (GimpDialog         *dialog,
#					     va_list             args);

MODULE = Gimp::UI	PACKAGE = Gimp::UI::FileEntry	PREFIX = gimp_file_entry_

BOOT:
	gperl_register_object (GIMP_TYPE_FILE_ENTRY, "Gimp::UI::FileEntry");

GimpFileEntry_own * gimp_file_entry_new (SV *unused_class, utf8_str title, utf8_str filename, \
                                                 gboolean dir_only = 0, gboolean check_valid = 0)
	C_ARGS: title, filename, dir_only, check_valid

utf8_str gimp_file_entry_get_filename (GimpFileEntry *entry)

void gimp_file_entry_set_filename (GimpFileEntry *entry, utf8_str filename)

MODULE = Gimp::UI	PACKAGE = Gimp::UI::FontSelectButton	PREFIX = gimp_font_select_button_

BOOT:
	gperl_register_object (GIMP_TYPE_FONT_SELECT_BUTTON, "Gimp::UI::FontSelectButton");

GimpFontSelectButton_own * gimp_font_select_button_new (SV *unused_class, utf8_str title, utf8_str font_name)
	C_ARGS: title, font_name

utf8_str_const gimp_font_select_button_get_font (GimpFontSelectButton *button)

void gimp_font_select_button_set_font (GimpFontSelectButton *button, utf8_str font_name)

MODULE = Gimp::UI	PACKAGE = Gimp::UI::OffsetArea	PREFIX = gimp_offset_area_

BOOT:
	gperl_register_object (GIMP_TYPE_OFFSET_AREA, "Gimp::UI::OffsetArea");

GimpOffsetArea_own * gimp_offset_area_new (SV *unused_class, gint orig_width, gint orig_height)
	C_ARGS: orig_width, orig_width

void gimp_offset_area_set_size (GimpOffsetArea *offset_area, gint width, gint height)

void gimp_offset_area_set_offsets (GimpOffsetArea *offset_area, gint offset_x, gint offset_y)

MODULE = Gimp::UI	PACKAGE = Gimp::UI::PathEditor	PREFIX = gimp_path_editor_

BOOT:
	gperl_register_object (GIMP_TYPE_PATH_EDITOR, "Gimp::UI::PathEditor");

GimpPathEditor_own * gimp_path_editor_new (SV *unused_class, utf8_str filesel_title, utf8_str path)
	C_ARGS: filesel_title, path

utf8_str gimp_path_editor_get_path (GimpPathEditor *gpe)

void gimp_path_editor_set_path (GimpPathEditor *gpe, utf8_str path)

MODULE = Gimp::UI	PACKAGE = Gimp::UI::PickButton	PREFIX = gimp_pick_button_

BOOT:
	gperl_register_object (GIMP_TYPE_PICK_BUTTON, "Gimp::UI::PickButton");

GimpPickButton_own * gimp_pick_button_new (SV *unused_class)
	C_ARGS:

MODULE = Gimp::UI	PACKAGE = Gimp::UI::Pixmap	PREFIX = gimp_pixmap_

BOOT:
	gperl_register_object (GIMP_TYPE_PIXMAP, "Gimp::UI::Pixmap");

#GimpPixmap_own * gimp_pixmap_new (SV *unused_class, char **xpm_data)
#	C_ARGS:

#GtkWidget * gimp_pixmap_new      (gchar      **xpm_data);

#void        gimp_pixmap_set      (GimpPixmap  *pixmap,
#				  gchar      **xpm_data);

MODULE = Gimp::UI	PACKAGE = Gimp::UI::SizeEntry	PREFIX = gimp_size_entry_

BOOT:
	gperl_register_object (GIMP_TYPE_SIZE_ENTRY, "Gimp::UI::SizeEntry");

GimpSizeEntry_own * gimp_size_entry_new (SV *unused_class, gint number_of_fields, GimpUnit unit, char *unit_format, \
                                         gboolean menu_show_pixels, gboolean menu_show_percent, gboolean show_refval, \
                                         gint spinbutton_width, GimpSizeEntryUpdatePolicy update_policy)
	C_ARGS: number_of_fields, unit, unit_format, menu_show_pixels, menu_show_percent, show_refval, spinbutton_width, update_policy

void gimp_size_entry_add_field (GimpSizeEntry *gse, GtkSpinButton *value_spinbutton, GtkSpinButton *refval_spinbutton)

void gimp_size_entry_attach_label (GimpSizeEntry *gse, utf8_str text, gint row, gint column, gfloat alignment)

void gimp_size_entry_set_resolution (GimpSizeEntry *gse, gint field, gdouble resolution, gboolean keep_size)

void gimp_size_entry_set_size (GimpSizeEntry *gse, gint field, gdouble lower, gdouble upper)

void gimp_size_entry_set_value_boundaries (GimpSizeEntry *gse, gint field, gdouble lower, gdouble upper)

gdouble gimp_size_entry_get_value (GimpSizeEntry *gse, gint field)

void gimp_size_entry_set_value (GimpSizeEntry *gse, gint field, gdouble value)

void gimp_size_entry_set_refval_boundaries (GimpSizeEntry *gse, gint field, gdouble lower, gdouble upper)

void gimp_size_entry_set_refval_digits (GimpSizeEntry *gse, gint field, gint digits)

gdouble gimp_size_entry_get_refval (GimpSizeEntry *gse, gint field)

void gimp_size_entry_set_refval (GimpSizeEntry *gse, gint field, gdouble refval)

GimpUnit gimp_size_entry_get_unit (GimpSizeEntry *gse)

void gimp_size_entry_set_unit (GimpSizeEntry *gse, GimpUnit unit)

void gimp_size_entry_grab_focus (GimpSizeEntry *gse)

MODULE = Gimp::UI	PACKAGE = Gimp::UI::Stock	PREFIX = gimp_stock_

BOOT:
	gimp_stock_init();
	CARGS:

MODULE = Gimp::UI	PACKAGE = Gimp::UI::UnitMenu	PREFIX = gimp_unit_menu_

BOOT:
	gperl_register_object (GIMP_TYPE_UNIT_MENU, "Gimp::UI::UnitMenu");

GimpUnitMenu_own * gimp_unit_menu_new (SV *unused_class, char *format, GimpUnit unit, \
                                       gboolean show_pixels, gboolean show_percent, gboolean show_custom)
	C_ARGS: format, unit, show_pixels, show_percent, show_custom

void gimp_unit_menu_set_unit (GimpUnitMenu *menu, GimpUnit unit)

GimpUnit gimp_unit_menu_get_unit (GimpUnitMenu *menu)

