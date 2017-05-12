#include "sexyperl.h"

MODULE = Gtk2::Sexy::Tooltip	PACKAGE = Gtk2::Sexy::Tooltip	PREFIX = sexy_tooltip_

PROTOTYPES: disable

GtkWidget *
sexy_tooltip_new (class);
	C_ARGS:

GtkWidget *
sexy_tooltip_new_with_label (class, text)
		gchar *text
	C_ARGS: text

void
sexy_tooltip_position_to_widget (tooltip, widget)
		SexyTooltip *tooltip
		GtkWidget *widget

void
sexy_tooltip_position_to_rect (tooltip, rect, screen)
		SexyTooltip *tooltip
		GdkRectangle *rect
		GdkScreen *screen
