#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>

#include "GtkTypes.h"
#include "GdkTypes.h"
#include "MiscTypes.h"
#include "GtkDefs.h"

HV * pGtkType[60];
char * pGtkTypeName[60];
HV * pG_EnumHash;
HV * pG_FlagsHash;

AV * gtk_typecasts = 0;
static HV * types = 0;

void add_typecast(int type, char * perlName)
{
	/*GtkObjectClass * klass = gtk_type_class(type);*/
	av_extend(gtk_typecasts, type/* klass->type*/);
	av_store(gtk_typecasts, type/*klass->type*/, newSVpv(perlName, 0));
	hv_store(types, perlName, strlen(perlName), newSViv(type), 0);
}

int type_name(char * name) {
	SV ** s = hv_fetch(types, name, strlen(name), 0);
	if (s)
		return SvIV(*s);
	else
		return 0;
}


SV * newSVGdkBitmap(GdkBitmap * value) {
	int n = 0;
	SV * result = newSVMiscRef(value, "Gtk::Gdk::Bitmap", &n);
	if (n)
		gdk_window_ref(value);
	return result;
}

GdkBitmap * SvGdkBitmap(SV * value) { return (GdkBitmap*)SvMiscRef(value, "Gtk::Gdk::Bitmap"); }

SV * newSVGdkColormap(GdkColormap * value) {
	int n = 0;
	SV * result = newSVMiscRef(value, "Gtk::Gdk::Colormap", &n);
	if (n)
		gdk_colormap_ref(value);
	return result;
}

GdkColormap * SvGdkColormap(SV * value) { return (GdkColormap*)SvMiscRef(value, "Gtk::Gdk::Colormap"); }

SV * newSVGdkFont(GdkFont * value) {
	int n = 0;
	SV * result = newSVMiscRef(value, "Gtk::Gdk::Font", &n);
	if (n)
		gdk_font_ref(value);
	return result;
}

GdkFont * SvGdkFont(SV * value) { return (GdkFont*)SvMiscRef(value, "Gtk::Gdk::Font"); }

SV * newSVGdkPixmap(GdkPixmap * value) {
	int n = 0;
	SV * result = newSVMiscRef(value, "Gtk::Gdk::Pixmap", &n);
	if (n)
		gdk_window_ref(value);
	return result;
}

GdkPixmap * SvGdkPixmap(SV * value) { return (GdkPixmap*)SvMiscRef(value, "Gtk::Gdk::Pixmap"); }

SV * newSVGdkVisual(GdkVisual * value) {
	int n = 0;
	SV * result = newSVMiscRef(value, "Gtk::Gdk::Visual", &n);
	if (n)
		gdk_visual_ref(value);
	return result;
}

GdkVisual * SvGdkVisual(SV * value) { return (GdkVisual*)SvMiscRef(value, "Gtk::Gdk::Visual"); }

SV * newSVGdkWindow(GdkWindow * value) {
	int n = 0;
	SV * result = newSVMiscRef(value, "Gtk::Gdk::Window", &n);
	if (n)
		gdk_window_ref(value);
	return result;
}

GdkWindow * SvGdkWindow(SV * value) { return (GdkWindow*)SvMiscRef(value, "Gtk::Gdk::Window"); }

SV * newSVGtkAcceleratorTable(GtkAcceleratorTable * value) {
	int n = 0;
	SV * result = newSVMiscRef(value, "Gtk::AcceleratorTable", &n);
	if (n)
		gtk_accelerator_table_ref(value);
	return result;
}

GtkAcceleratorTable * SvGtkAcceleratorTable(SV * value) { return (GtkAcceleratorTable*)SvMiscRef(value, "Gtk::AcceleratorTable"); }

SV * newSVGtkStyle(GtkStyle * value) {
	int n = 0;
	SV * result = newSVMiscRef(value, "Gtk::Style", &n);
	if (n)
		gtk_style_ref(value);
	return result;
}

GtkStyle * SvGtkStyle(SV * value) { return (GtkStyle*)SvMiscRef(value, "Gtk::Style"); }

SV * GtkGetArg(GtkArg * a)
{
	SV * result;
	switch (GTK_FUNDAMENTAL_TYPE(a->type)) {
		case GTK_TYPE_BOOL:	result = newSViv(GTK_VALUE_BOOL(*a)); break;
		case GTK_TYPE_CHAR:	result = newSViv(GTK_VALUE_CHAR(*a)); break;
		case GTK_TYPE_INT:	result = newSViv(GTK_VALUE_INT(*a)); break;
		case GTK_TYPE_LONG:	result = newSViv(GTK_VALUE_LONG(*a)); break;
		case GTK_TYPE_UINT:	result = newSViv(GTK_VALUE_UINT(*a)); break;
		case GTK_TYPE_ULONG:	result = newSViv(GTK_VALUE_ULONG(*a)); break;
		case GTK_TYPE_FLOAT:	result = newSVnv(GTK_VALUE_FLOAT(*a)); break;	
		case GTK_TYPE_STRING:	result = newSVpv(GTK_VALUE_STRING(*a),0); break;
		case GTK_TYPE_POINTER:	result = newSVpv(GTK_VALUE_POINTER(*a),0); break;
		case GTK_TYPE_OBJECT:	result = newSVGtkObjectRef(GTK_VALUE_OBJECT(*a), 0); break;
		case GTK_TYPE_SIGNAL:
		{
			AV * args = (AV*)GTK_VALUE_SIGNAL(*a).d;
			SV ** s;
			if ((GTK_VALUE_SIGNAL(*a).f != 0) ||
				(!args) ||
				(SvTYPE(args) != SVt_PVAV) ||
				(av_len(args) < 3) ||
				!(s = av_fetch(args, 2, 0))
				)
				croak("Unable to return a foreign signal type to Perl");

			result = newSVsv(*s);
			return;
		}
		case GTK_TYPE_ENUM:
#ifdef GTK_TYPE_GDK_AXIS_USE
			if (a->type == GTK_TYPE_GDK_AXIS_USE)
				result = newSVGdkAxisUse(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_BYTE_ORDER
			if (a->type == GTK_TYPE_GDK_BYTE_ORDER)
				result = newSVGdkByteOrder(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_CAP_STYLE
			if (a->type == GTK_TYPE_GDK_CAP_STYLE)
				result = newSVGdkCapStyle(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_CURSOR_TYPE
			if (a->type == GTK_TYPE_GDK_CURSOR_TYPE)
				result = newSVGdkCursorType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_EVENT_TYPE
			if (a->type == GTK_TYPE_GDK_EVENT_TYPE)
				result = newSVGdkEventType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_FILL
			if (a->type == GTK_TYPE_GDK_FILL)
				result = newSVGdkFill(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_FUNCTION
			if (a->type == GTK_TYPE_GDK_FUNCTION)
				result = newSVGdkFunction(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_IMAGE_TYPE
			if (a->type == GTK_TYPE_GDK_IMAGE_TYPE)
				result = newSVGdkImageType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_INPUT_MODE
			if (a->type == GTK_TYPE_GDK_INPUT_MODE)
				result = newSVGdkInputMode(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_INPUT_SOURCE
			if (a->type == GTK_TYPE_GDK_INPUT_SOURCE)
				result = newSVGdkInputSource(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_JOIN_STYLE
			if (a->type == GTK_TYPE_GDK_JOIN_STYLE)
				result = newSVGdkJoinStyle(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_LINE_STYLE
			if (a->type == GTK_TYPE_GDK_LINE_STYLE)
				result = newSVGdkLineStyle(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_NOTIFY_TYPE
			if (a->type == GTK_TYPE_GDK_NOTIFY_TYPE)
				result = newSVGdkNotifyType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_OVERLAP_TYPE
			if (a->type == GTK_TYPE_GDK_OVERLAP_TYPE)
				result = newSVGdkOverlapType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_PROP_MODE
			if (a->type == GTK_TYPE_GDK_PROP_MODE)
				result = newSVGdkPropMode(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_PROPERTY_STATE
			if (a->type == GTK_TYPE_GDK_PROPERTY_STATE)
				result = newSVGdkPropertyState(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_SELECTION
			if (a->type == GTK_TYPE_GDK_SELECTION)
				result = newSVGdkSelection(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_STATUS
			if (a->type == GTK_TYPE_GDK_STATUS)
				result = newSVGdkStatus(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_SUBWINDOW_MODE
			if (a->type == GTK_TYPE_GDK_SUBWINDOW_MODE)
				result = newSVGdkSubwindowMode(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_VISUAL_TYPE
			if (a->type == GTK_TYPE_GDK_VISUAL_TYPE)
				result = newSVGdkVisualType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW_CLASS
			if (a->type == GTK_TYPE_GDK_WINDOW_CLASS)
				result = newSVGdkWindowClass(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW_TYPE
			if (a->type == GTK_TYPE_GDK_WINDOW_TYPE)
				result = newSVGdkWindowType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_ARROW_TYPE
			if (a->type == GTK_TYPE_ARROW_TYPE)
				result = newSVGtkArrowType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_BUTTON_BOX_STYLE
			if (a->type == GTK_TYPE_BUTTON_BOX_STYLE)
				result = newSVGtkButtonBoxStyle(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_CELL_TYPE
			if (a->type == GTK_TYPE_CELL_TYPE)
				result = newSVGtkCellType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_CURVE_TYPE
			if (a->type == GTK_TYPE_CURVE_TYPE)
				result = newSVGtkCurveType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_DIRECTION_TYPE
			if (a->type == GTK_TYPE_DIRECTION_TYPE)
				result = newSVGtkDirectionType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_FUNDAMENTAL_TYPE
			if (a->type == GTK_TYPE_FUNDAMENTAL_TYPE)
				result = newSVGtkFundamentalType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_JUSTIFICATION
			if (a->type == GTK_TYPE_JUSTIFICATION)
				result = newSVGtkJustification(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_MENU_FACTORY_TYPE
			if (a->type == GTK_TYPE_MENU_FACTORY_TYPE)
				result = newSVGtkMenuFactoryType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_METRIC_TYPE
			if (a->type == GTK_TYPE_METRIC_TYPE)
				result = newSVGtkMetricType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_ORIENTATION
			if (a->type == GTK_TYPE_ORIENTATION)
				result = newSVGtkOrientation(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_PACK_TYPE
			if (a->type == GTK_TYPE_PACK_TYPE)
				result = newSVGtkPackType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_POLICY_TYPE
			if (a->type == GTK_TYPE_POLICY_TYPE)
				result = newSVGtkPolicyType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_POSITION_TYPE
			if (a->type == GTK_TYPE_POSITION_TYPE)
				result = newSVGtkPositionType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_PREVIEW_TYPE
			if (a->type == GTK_TYPE_PREVIEW_TYPE)
				result = newSVGtkPreviewType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_SCROLL_TYPE
			if (a->type == GTK_TYPE_SCROLL_TYPE)
				result = newSVGtkScrollType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_SELECTION_MODE
			if (a->type == GTK_TYPE_SELECTION_MODE)
				result = newSVGtkSelectionMode(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_SHADOW_TYPE
			if (a->type == GTK_TYPE_SHADOW_TYPE)
				result = newSVGtkShadowType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_STATE_TYPE
			if (a->type == GTK_TYPE_STATE_TYPE)
				result = newSVGtkStateType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_SUBMENU_DIRECTION
			if (a->type == GTK_TYPE_SUBMENU_DIRECTION)
				result = newSVGtkSubmenuDirection(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_SUBMENU_PLACEMENT
			if (a->type == GTK_TYPE_SUBMENU_PLACEMENT)
				result = newSVGtkSubmenuPlacement(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_TOOLBAR_CHILD_TYPE
			if (a->type == GTK_TYPE_TOOLBAR_CHILD_TYPE)
				result = newSVGtkToolbarChildType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_TOOLBAR_STYLE
			if (a->type == GTK_TYPE_TOOLBAR_STYLE)
				result = newSVGtkToolbarStyle(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_TREE_VIEW_MODE
			if (a->type == GTK_TYPE_TREE_VIEW_MODE)
				result = newSVGtkTreeViewMode(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_TROUGH_TYPE
			if (a->type == GTK_TYPE_TROUGH_TYPE)
				result = newSVGtkTroughType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_UPDATE_TYPE
			if (a->type == GTK_TYPE_UPDATE_TYPE)
				result = newSVGtkUpdateType(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_WINDOW_POSITION
			if (a->type == GTK_TYPE_WINDOW_POSITION)
				result = newSVGtkWindowPosition(GTK_VALUE_ENUM(*a));
			else
#endif
#ifdef GTK_TYPE_WINDOW_TYPE
			if (a->type == GTK_TYPE_WINDOW_TYPE)
				result = newSVGtkWindowType(GTK_VALUE_ENUM(*a));
			else
#endif
				goto d_fault;
			break;
		case GTK_TYPE_FLAGS:
#ifdef GTK_TYPE_GDK_EVENT_MASK
			if (a->type == GTK_TYPE_GDK_EVENT_MASK)
				result = newSVGdkEventMask(GTK_VALUE_FLAGS(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_GCVALUES_MASK
			if (a->type == GTK_TYPE_GDK_GCVALUES_MASK)
				result = newSVGdkGCValuesMask(GTK_VALUE_FLAGS(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_INPUT_CONDITION
			if (a->type == GTK_TYPE_GDK_INPUT_CONDITION)
				result = newSVGdkInputCondition(GTK_VALUE_FLAGS(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_MODIFIER_TYPE
			if (a->type == GTK_TYPE_GDK_MODIFIER_TYPE)
				result = newSVGdkModifierType(GTK_VALUE_FLAGS(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_WMDECORATION
			if (a->type == GTK_TYPE_GDK_WMDECORATION)
				result = newSVGdkWMDecoration(GTK_VALUE_FLAGS(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_WMFUNCTION
			if (a->type == GTK_TYPE_GDK_WMFUNCTION)
				result = newSVGdkWMFunction(GTK_VALUE_FLAGS(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW_ATTRIBUTES_TYPE
			if (a->type == GTK_TYPE_GDK_WINDOW_ATTRIBUTES_TYPE)
				result = newSVGdkWindowAttributesType(GTK_VALUE_FLAGS(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW_HINTS
			if (a->type == GTK_TYPE_GDK_WINDOW_HINTS)
				result = newSVGdkWindowHints(GTK_VALUE_FLAGS(*a));
			else
#endif
#ifdef GTK_TYPE_ATTACH_OPTIONS
			if (a->type == GTK_TYPE_ATTACH_OPTIONS)
				result = newSVGtkAttachOptions(GTK_VALUE_FLAGS(*a));
			else
#endif
#ifdef GTK_TYPE_SIGNAL_RUN_TYPE
			if (a->type == GTK_TYPE_SIGNAL_RUN_TYPE)
				result = newSVGtkSignalRunType(GTK_VALUE_FLAGS(*a));
			else
#endif
#ifdef GTK_TYPE_SPIN_BUTTON_UPDATE_POLICY
			if (a->type == GTK_TYPE_SPIN_BUTTON_UPDATE_POLICY)
				result = newSVGtkSpinButtonUpdatePolicy(GTK_VALUE_FLAGS(*a));
			else
#endif
				goto d_fault;
			break;
		case GTK_TYPE_BOXED:
			if (a->type == GTK_TYPE_GDK_EVENT)
				result = newSVGdkEvent(GTK_VALUE_BOXED(*a));
			else
#ifdef GTK_TYPE_GDK_WINDOW
			if (a->type == GTK_TYPE_GDK_WINDOW)
				result = newSVGdkBitmap(GTK_VALUE_BOXED(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_COLORMAP
			if (a->type == GTK_TYPE_GDK_COLORMAP)
				result = newSVGdkColormap(GTK_VALUE_BOXED(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_FONT
			if (a->type == GTK_TYPE_GDK_FONT)
				result = newSVGdkFont(GTK_VALUE_BOXED(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW
			if (a->type == GTK_TYPE_GDK_WINDOW)
				result = newSVGdkPixmap(GTK_VALUE_BOXED(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_VISUAL
			if (a->type == GTK_TYPE_GDK_VISUAL)
				result = newSVGdkVisual(GTK_VALUE_BOXED(*a));
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW
			if (a->type == GTK_TYPE_GDK_WINDOW)
				result = newSVGdkWindow(GTK_VALUE_BOXED(*a));
			else
#endif
#ifdef GTK_TYPE_ACCELERATOR_TABLE
			if (a->type == GTK_TYPE_ACCELERATOR_TABLE)
				result = newSVGtkAcceleratorTable(GTK_VALUE_BOXED(*a));
			else
#endif
#ifdef GTK_TYPE_STYLE
			if (a->type == GTK_TYPE_STYLE)
				result = newSVGtkStyle(GTK_VALUE_BOXED(*a));
			else
#endif
				goto d_fault;
			break;
		d_fault:
		default:
			croak("Cannot get argument of type %s (fundamental type %s)", gtk_type_name(a->type), gtk_type_name(GTK_FUNDAMENTAL_TYPE(a->type)));
	}
	return result;
}

void GtkSetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object)
{
	switch (GTK_FUNDAMENTAL_TYPE(a->type)) {
		case GTK_TYPE_CHAR:		GTK_VALUE_CHAR(*a) = SvIV(v); break;
		case GTK_TYPE_BOOL:		GTK_VALUE_BOOL(*a) = SvIV(v); break;
		case GTK_TYPE_INT:		GTK_VALUE_INT(*a) = SvIV(v); break;
		case GTK_TYPE_UINT:		GTK_VALUE_UINT(*a) = SvIV(v); break;
		case GTK_TYPE_LONG:		GTK_VALUE_LONG(*a) = SvIV(v); break;
		case GTK_TYPE_ULONG:	GTK_VALUE_ULONG(*a) = SvIV(v); break;
		case GTK_TYPE_FLOAT:	GTK_VALUE_FLOAT(*a) = SvNV(v); break;	
		case GTK_TYPE_STRING:	GTK_VALUE_STRING(*a) = g_strdup(SvPV(v,na)); break;
		case GTK_TYPE_POINTER:	GTK_VALUE_POINTER(*a) = SvPV(v,na); break;
		case GTK_TYPE_OBJECT:	GTK_VALUE_OBJECT(*a) = SvGtkObjectRef(v, "Gtk::Object"); break;
		case GTK_TYPE_SIGNAL:
		{
			AV * args;
			int i,j;
			int type;
			char * c = strchr(a->name, ':');
			c+=2;
			c = strchr(c, ':');
			c += 2;
			args = newAV();

			type = gtk_signal_lookup(c, Object->klass->type);

			av_push(args, newSVsv(Class));
			av_push(args, newSVpv(c, 0));
			av_push(args, newSVsv(v));
			av_push(args, newSViv(type));

			GTK_VALUE_SIGNAL(*a).f = 0;
			GTK_VALUE_SIGNAL(*a).d = args;
			return;
		}
		case GTK_TYPE_ENUM:
#ifdef GTK_TYPE_GDK_AXIS_USE
			if (a->type == GTK_TYPE_GDK_AXIS_USE)
				GTK_VALUE_ENUM(*a) = SvGdkAxisUse(v);
			else
#endif
#ifdef GTK_TYPE_GDK_BYTE_ORDER
			if (a->type == GTK_TYPE_GDK_BYTE_ORDER)
				GTK_VALUE_ENUM(*a) = SvGdkByteOrder(v);
			else
#endif
#ifdef GTK_TYPE_GDK_CAP_STYLE
			if (a->type == GTK_TYPE_GDK_CAP_STYLE)
				GTK_VALUE_ENUM(*a) = SvGdkCapStyle(v);
			else
#endif
#ifdef GTK_TYPE_GDK_CURSOR_TYPE
			if (a->type == GTK_TYPE_GDK_CURSOR_TYPE)
				GTK_VALUE_ENUM(*a) = SvGdkCursorType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_EVENT_TYPE
			if (a->type == GTK_TYPE_GDK_EVENT_TYPE)
				GTK_VALUE_ENUM(*a) = SvGdkEventType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_FILL
			if (a->type == GTK_TYPE_GDK_FILL)
				GTK_VALUE_ENUM(*a) = SvGdkFill(v);
			else
#endif
#ifdef GTK_TYPE_GDK_FUNCTION
			if (a->type == GTK_TYPE_GDK_FUNCTION)
				GTK_VALUE_ENUM(*a) = SvGdkFunction(v);
			else
#endif
#ifdef GTK_TYPE_GDK_IMAGE_TYPE
			if (a->type == GTK_TYPE_GDK_IMAGE_TYPE)
				GTK_VALUE_ENUM(*a) = SvGdkImageType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_INPUT_MODE
			if (a->type == GTK_TYPE_GDK_INPUT_MODE)
				GTK_VALUE_ENUM(*a) = SvGdkInputMode(v);
			else
#endif
#ifdef GTK_TYPE_GDK_INPUT_SOURCE
			if (a->type == GTK_TYPE_GDK_INPUT_SOURCE)
				GTK_VALUE_ENUM(*a) = SvGdkInputSource(v);
			else
#endif
#ifdef GTK_TYPE_GDK_JOIN_STYLE
			if (a->type == GTK_TYPE_GDK_JOIN_STYLE)
				GTK_VALUE_ENUM(*a) = SvGdkJoinStyle(v);
			else
#endif
#ifdef GTK_TYPE_GDK_LINE_STYLE
			if (a->type == GTK_TYPE_GDK_LINE_STYLE)
				GTK_VALUE_ENUM(*a) = SvGdkLineStyle(v);
			else
#endif
#ifdef GTK_TYPE_GDK_NOTIFY_TYPE
			if (a->type == GTK_TYPE_GDK_NOTIFY_TYPE)
				GTK_VALUE_ENUM(*a) = SvGdkNotifyType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_OVERLAP_TYPE
			if (a->type == GTK_TYPE_GDK_OVERLAP_TYPE)
				GTK_VALUE_ENUM(*a) = SvGdkOverlapType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_PROP_MODE
			if (a->type == GTK_TYPE_GDK_PROP_MODE)
				GTK_VALUE_ENUM(*a) = SvGdkPropMode(v);
			else
#endif
#ifdef GTK_TYPE_GDK_PROPERTY_STATE
			if (a->type == GTK_TYPE_GDK_PROPERTY_STATE)
				GTK_VALUE_ENUM(*a) = SvGdkPropertyState(v);
			else
#endif
#ifdef GTK_TYPE_GDK_SELECTION
			if (a->type == GTK_TYPE_GDK_SELECTION)
				GTK_VALUE_ENUM(*a) = SvGdkSelection(v);
			else
#endif
#ifdef GTK_TYPE_GDK_STATUS
			if (a->type == GTK_TYPE_GDK_STATUS)
				GTK_VALUE_ENUM(*a) = SvGdkStatus(v);
			else
#endif
#ifdef GTK_TYPE_GDK_SUBWINDOW_MODE
			if (a->type == GTK_TYPE_GDK_SUBWINDOW_MODE)
				GTK_VALUE_ENUM(*a) = SvGdkSubwindowMode(v);
			else
#endif
#ifdef GTK_TYPE_GDK_VISUAL_TYPE
			if (a->type == GTK_TYPE_GDK_VISUAL_TYPE)
				GTK_VALUE_ENUM(*a) = SvGdkVisualType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW_CLASS
			if (a->type == GTK_TYPE_GDK_WINDOW_CLASS)
				GTK_VALUE_ENUM(*a) = SvGdkWindowClass(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW_TYPE
			if (a->type == GTK_TYPE_GDK_WINDOW_TYPE)
				GTK_VALUE_ENUM(*a) = SvGdkWindowType(v);
			else
#endif
#ifdef GTK_TYPE_ARROW_TYPE
			if (a->type == GTK_TYPE_ARROW_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkArrowType(v);
			else
#endif
#ifdef GTK_TYPE_BUTTON_BOX_STYLE
			if (a->type == GTK_TYPE_BUTTON_BOX_STYLE)
				GTK_VALUE_ENUM(*a) = SvGtkButtonBoxStyle(v);
			else
#endif
#ifdef GTK_TYPE_CELL_TYPE
			if (a->type == GTK_TYPE_CELL_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkCellType(v);
			else
#endif
#ifdef GTK_TYPE_CURVE_TYPE
			if (a->type == GTK_TYPE_CURVE_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkCurveType(v);
			else
#endif
#ifdef GTK_TYPE_DIRECTION_TYPE
			if (a->type == GTK_TYPE_DIRECTION_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkDirectionType(v);
			else
#endif
#ifdef GTK_TYPE_FUNDAMENTAL_TYPE
			if (a->type == GTK_TYPE_FUNDAMENTAL_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkFundamentalType(v);
			else
#endif
#ifdef GTK_TYPE_JUSTIFICATION
			if (a->type == GTK_TYPE_JUSTIFICATION)
				GTK_VALUE_ENUM(*a) = SvGtkJustification(v);
			else
#endif
#ifdef GTK_TYPE_MENU_FACTORY_TYPE
			if (a->type == GTK_TYPE_MENU_FACTORY_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkMenuFactoryType(v);
			else
#endif
#ifdef GTK_TYPE_METRIC_TYPE
			if (a->type == GTK_TYPE_METRIC_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkMetricType(v);
			else
#endif
#ifdef GTK_TYPE_ORIENTATION
			if (a->type == GTK_TYPE_ORIENTATION)
				GTK_VALUE_ENUM(*a) = SvGtkOrientation(v);
			else
#endif
#ifdef GTK_TYPE_PACK_TYPE
			if (a->type == GTK_TYPE_PACK_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkPackType(v);
			else
#endif
#ifdef GTK_TYPE_POLICY_TYPE
			if (a->type == GTK_TYPE_POLICY_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkPolicyType(v);
			else
#endif
#ifdef GTK_TYPE_POSITION_TYPE
			if (a->type == GTK_TYPE_POSITION_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkPositionType(v);
			else
#endif
#ifdef GTK_TYPE_PREVIEW_TYPE
			if (a->type == GTK_TYPE_PREVIEW_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkPreviewType(v);
			else
#endif
#ifdef GTK_TYPE_SCROLL_TYPE
			if (a->type == GTK_TYPE_SCROLL_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkScrollType(v);
			else
#endif
#ifdef GTK_TYPE_SELECTION_MODE
			if (a->type == GTK_TYPE_SELECTION_MODE)
				GTK_VALUE_ENUM(*a) = SvGtkSelectionMode(v);
			else
#endif
#ifdef GTK_TYPE_SHADOW_TYPE
			if (a->type == GTK_TYPE_SHADOW_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkShadowType(v);
			else
#endif
#ifdef GTK_TYPE_STATE_TYPE
			if (a->type == GTK_TYPE_STATE_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkStateType(v);
			else
#endif
#ifdef GTK_TYPE_SUBMENU_DIRECTION
			if (a->type == GTK_TYPE_SUBMENU_DIRECTION)
				GTK_VALUE_ENUM(*a) = SvGtkSubmenuDirection(v);
			else
#endif
#ifdef GTK_TYPE_SUBMENU_PLACEMENT
			if (a->type == GTK_TYPE_SUBMENU_PLACEMENT)
				GTK_VALUE_ENUM(*a) = SvGtkSubmenuPlacement(v);
			else
#endif
#ifdef GTK_TYPE_TOOLBAR_CHILD_TYPE
			if (a->type == GTK_TYPE_TOOLBAR_CHILD_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkToolbarChildType(v);
			else
#endif
#ifdef GTK_TYPE_TOOLBAR_STYLE
			if (a->type == GTK_TYPE_TOOLBAR_STYLE)
				GTK_VALUE_ENUM(*a) = SvGtkToolbarStyle(v);
			else
#endif
#ifdef GTK_TYPE_TREE_VIEW_MODE
			if (a->type == GTK_TYPE_TREE_VIEW_MODE)
				GTK_VALUE_ENUM(*a) = SvGtkTreeViewMode(v);
			else
#endif
#ifdef GTK_TYPE_TROUGH_TYPE
			if (a->type == GTK_TYPE_TROUGH_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkTroughType(v);
			else
#endif
#ifdef GTK_TYPE_UPDATE_TYPE
			if (a->type == GTK_TYPE_UPDATE_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkUpdateType(v);
			else
#endif
#ifdef GTK_TYPE_WINDOW_POSITION
			if (a->type == GTK_TYPE_WINDOW_POSITION)
				GTK_VALUE_ENUM(*a) = SvGtkWindowPosition(v);
			else
#endif
#ifdef GTK_TYPE_WINDOW_TYPE
			if (a->type == GTK_TYPE_WINDOW_TYPE)
				GTK_VALUE_ENUM(*a) = SvGtkWindowType(v);
			else
#endif
				goto d_fault;
			break;
		case GTK_TYPE_FLAGS:
#ifdef GTK_TYPE_GDK_EVENT_MASK
			if (a->type == GTK_TYPE_GDK_EVENT_MASK)
				GTK_VALUE_FLAGS(*a) = SvGdkEventMask(v);
			else
#endif
#ifdef GTK_TYPE_GDK_GCVALUES_MASK
			if (a->type == GTK_TYPE_GDK_GCVALUES_MASK)
				GTK_VALUE_FLAGS(*a) = SvGdkGCValuesMask(v);
			else
#endif
#ifdef GTK_TYPE_GDK_INPUT_CONDITION
			if (a->type == GTK_TYPE_GDK_INPUT_CONDITION)
				GTK_VALUE_FLAGS(*a) = SvGdkInputCondition(v);
			else
#endif
#ifdef GTK_TYPE_GDK_MODIFIER_TYPE
			if (a->type == GTK_TYPE_GDK_MODIFIER_TYPE)
				GTK_VALUE_FLAGS(*a) = SvGdkModifierType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WMDECORATION
			if (a->type == GTK_TYPE_GDK_WMDECORATION)
				GTK_VALUE_FLAGS(*a) = SvGdkWMDecoration(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WMFUNCTION
			if (a->type == GTK_TYPE_GDK_WMFUNCTION)
				GTK_VALUE_FLAGS(*a) = SvGdkWMFunction(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW_ATTRIBUTES_TYPE
			if (a->type == GTK_TYPE_GDK_WINDOW_ATTRIBUTES_TYPE)
				GTK_VALUE_FLAGS(*a) = SvGdkWindowAttributesType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW_HINTS
			if (a->type == GTK_TYPE_GDK_WINDOW_HINTS)
				GTK_VALUE_FLAGS(*a) = SvGdkWindowHints(v);
			else
#endif
#ifdef GTK_TYPE_ATTACH_OPTIONS
			if (a->type == GTK_TYPE_ATTACH_OPTIONS)
				GTK_VALUE_FLAGS(*a) = SvGtkAttachOptions(v);
			else
#endif
#ifdef GTK_TYPE_SIGNAL_RUN_TYPE
			if (a->type == GTK_TYPE_SIGNAL_RUN_TYPE)
				GTK_VALUE_FLAGS(*a) = SvGtkSignalRunType(v);
			else
#endif
#ifdef GTK_TYPE_SPIN_BUTTON_UPDATE_POLICY
			if (a->type == GTK_TYPE_SPIN_BUTTON_UPDATE_POLICY)
				GTK_VALUE_FLAGS(*a) = SvGtkSpinButtonUpdatePolicy(v);
			else
#endif
				goto d_fault;
			break;
		case GTK_TYPE_BOXED:
			if (a->type == GTK_TYPE_GDK_EVENT)
				GTK_VALUE_BOXED(*a) = SvGdkEvent(v);
			else
#ifdef GTK_TYPE_GDK_WINDOW
			if (a->type == GTK_TYPE_GDK_WINDOW)
				GTK_VALUE_BOXED(*a) = SvGdkBitmap(v);
			else
#endif
#ifdef GTK_TYPE_GDK_COLORMAP
			if (a->type == GTK_TYPE_GDK_COLORMAP)
				GTK_VALUE_BOXED(*a) = SvGdkColormap(v);
			else
#endif
#ifdef GTK_TYPE_GDK_FONT
			if (a->type == GTK_TYPE_GDK_FONT)
				GTK_VALUE_BOXED(*a) = SvGdkFont(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW
			if (a->type == GTK_TYPE_GDK_WINDOW)
				GTK_VALUE_BOXED(*a) = SvGdkPixmap(v);
			else
#endif
#ifdef GTK_TYPE_GDK_VISUAL
			if (a->type == GTK_TYPE_GDK_VISUAL)
				GTK_VALUE_BOXED(*a) = SvGdkVisual(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW
			if (a->type == GTK_TYPE_GDK_WINDOW)
				GTK_VALUE_BOXED(*a) = SvGdkWindow(v);
			else
#endif
#ifdef GTK_TYPE_ACCELERATOR_TABLE
			if (a->type == GTK_TYPE_ACCELERATOR_TABLE)
				GTK_VALUE_BOXED(*a) = SvGtkAcceleratorTable(v);
			else
#endif
#ifdef GTK_TYPE_STYLE
			if (a->type == GTK_TYPE_STYLE)
				GTK_VALUE_BOXED(*a) = SvGtkStyle(v);
			else
#endif
				goto d_fault;
			break;
		d_fault:
		default:
			croak("Cannot set argument of type %s (fundamental type %s)", gtk_type_name(a->type), gtk_type_name(GTK_FUNDAMENTAL_TYPE(a->type)));
	}
}

void GtkSetRetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object)
{
	switch (GTK_FUNDAMENTAL_TYPE(a->type)) {
		case GTK_TYPE_CHAR:		*GTK_RETLOC_CHAR(*a) = SvIV(v); break;
		case GTK_TYPE_BOOL:		*GTK_RETLOC_BOOL(*a) = SvIV(v); break;
		case GTK_TYPE_INT:		*GTK_RETLOC_INT(*a) = SvIV(v); break;
		case GTK_TYPE_UINT:		*GTK_RETLOC_UINT(*a) = SvIV(v); break;
		case GTK_TYPE_LONG:		*GTK_RETLOC_LONG(*a) = SvIV(v); break;
		case GTK_TYPE_ULONG:	*GTK_RETLOC_ULONG(*a) = SvIV(v); break;
		case GTK_TYPE_FLOAT:	*GTK_RETLOC_FLOAT(*a) = SvNV(v); break;	
		case GTK_TYPE_STRING:	*GTK_RETLOC_STRING(*a) = SvPV(v,na); break;
		case GTK_TYPE_POINTER:	*GTK_RETLOC_POINTER(*a) = SvPV(v,na); break;
		case GTK_TYPE_OBJECT:	*GTK_RETLOC_OBJECT(*a) = SvGtkObjectRef(v, "Gtk::Object"); break;
		case GTK_TYPE_ENUM:
#ifdef GTK_TYPE_GDK_AXIS_USE
			if (a->type == GTK_TYPE_GDK_AXIS_USE)
				*GTK_RETLOC_ENUM(*a) = SvGdkAxisUse(v);
			else
#endif
#ifdef GTK_TYPE_GDK_BYTE_ORDER
			if (a->type == GTK_TYPE_GDK_BYTE_ORDER)
				*GTK_RETLOC_ENUM(*a) = SvGdkByteOrder(v);
			else
#endif
#ifdef GTK_TYPE_GDK_CAP_STYLE
			if (a->type == GTK_TYPE_GDK_CAP_STYLE)
				*GTK_RETLOC_ENUM(*a) = SvGdkCapStyle(v);
			else
#endif
#ifdef GTK_TYPE_GDK_CURSOR_TYPE
			if (a->type == GTK_TYPE_GDK_CURSOR_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGdkCursorType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_EVENT_TYPE
			if (a->type == GTK_TYPE_GDK_EVENT_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGdkEventType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_FILL
			if (a->type == GTK_TYPE_GDK_FILL)
				*GTK_RETLOC_ENUM(*a) = SvGdkFill(v);
			else
#endif
#ifdef GTK_TYPE_GDK_FUNCTION
			if (a->type == GTK_TYPE_GDK_FUNCTION)
				*GTK_RETLOC_ENUM(*a) = SvGdkFunction(v);
			else
#endif
#ifdef GTK_TYPE_GDK_IMAGE_TYPE
			if (a->type == GTK_TYPE_GDK_IMAGE_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGdkImageType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_INPUT_MODE
			if (a->type == GTK_TYPE_GDK_INPUT_MODE)
				*GTK_RETLOC_ENUM(*a) = SvGdkInputMode(v);
			else
#endif
#ifdef GTK_TYPE_GDK_INPUT_SOURCE
			if (a->type == GTK_TYPE_GDK_INPUT_SOURCE)
				*GTK_RETLOC_ENUM(*a) = SvGdkInputSource(v);
			else
#endif
#ifdef GTK_TYPE_GDK_JOIN_STYLE
			if (a->type == GTK_TYPE_GDK_JOIN_STYLE)
				*GTK_RETLOC_ENUM(*a) = SvGdkJoinStyle(v);
			else
#endif
#ifdef GTK_TYPE_GDK_LINE_STYLE
			if (a->type == GTK_TYPE_GDK_LINE_STYLE)
				*GTK_RETLOC_ENUM(*a) = SvGdkLineStyle(v);
			else
#endif
#ifdef GTK_TYPE_GDK_NOTIFY_TYPE
			if (a->type == GTK_TYPE_GDK_NOTIFY_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGdkNotifyType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_OVERLAP_TYPE
			if (a->type == GTK_TYPE_GDK_OVERLAP_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGdkOverlapType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_PROP_MODE
			if (a->type == GTK_TYPE_GDK_PROP_MODE)
				*GTK_RETLOC_ENUM(*a) = SvGdkPropMode(v);
			else
#endif
#ifdef GTK_TYPE_GDK_PROPERTY_STATE
			if (a->type == GTK_TYPE_GDK_PROPERTY_STATE)
				*GTK_RETLOC_ENUM(*a) = SvGdkPropertyState(v);
			else
#endif
#ifdef GTK_TYPE_GDK_SELECTION
			if (a->type == GTK_TYPE_GDK_SELECTION)
				*GTK_RETLOC_ENUM(*a) = SvGdkSelection(v);
			else
#endif
#ifdef GTK_TYPE_GDK_STATUS
			if (a->type == GTK_TYPE_GDK_STATUS)
				*GTK_RETLOC_ENUM(*a) = SvGdkStatus(v);
			else
#endif
#ifdef GTK_TYPE_GDK_SUBWINDOW_MODE
			if (a->type == GTK_TYPE_GDK_SUBWINDOW_MODE)
				*GTK_RETLOC_ENUM(*a) = SvGdkSubwindowMode(v);
			else
#endif
#ifdef GTK_TYPE_GDK_VISUAL_TYPE
			if (a->type == GTK_TYPE_GDK_VISUAL_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGdkVisualType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW_CLASS
			if (a->type == GTK_TYPE_GDK_WINDOW_CLASS)
				*GTK_RETLOC_ENUM(*a) = SvGdkWindowClass(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW_TYPE
			if (a->type == GTK_TYPE_GDK_WINDOW_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGdkWindowType(v);
			else
#endif
#ifdef GTK_TYPE_ARROW_TYPE
			if (a->type == GTK_TYPE_ARROW_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkArrowType(v);
			else
#endif
#ifdef GTK_TYPE_BUTTON_BOX_STYLE
			if (a->type == GTK_TYPE_BUTTON_BOX_STYLE)
				*GTK_RETLOC_ENUM(*a) = SvGtkButtonBoxStyle(v);
			else
#endif
#ifdef GTK_TYPE_CELL_TYPE
			if (a->type == GTK_TYPE_CELL_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkCellType(v);
			else
#endif
#ifdef GTK_TYPE_CURVE_TYPE
			if (a->type == GTK_TYPE_CURVE_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkCurveType(v);
			else
#endif
#ifdef GTK_TYPE_DIRECTION_TYPE
			if (a->type == GTK_TYPE_DIRECTION_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkDirectionType(v);
			else
#endif
#ifdef GTK_TYPE_FUNDAMENTAL_TYPE
			if (a->type == GTK_TYPE_FUNDAMENTAL_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkFundamentalType(v);
			else
#endif
#ifdef GTK_TYPE_JUSTIFICATION
			if (a->type == GTK_TYPE_JUSTIFICATION)
				*GTK_RETLOC_ENUM(*a) = SvGtkJustification(v);
			else
#endif
#ifdef GTK_TYPE_MENU_FACTORY_TYPE
			if (a->type == GTK_TYPE_MENU_FACTORY_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkMenuFactoryType(v);
			else
#endif
#ifdef GTK_TYPE_METRIC_TYPE
			if (a->type == GTK_TYPE_METRIC_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkMetricType(v);
			else
#endif
#ifdef GTK_TYPE_ORIENTATION
			if (a->type == GTK_TYPE_ORIENTATION)
				*GTK_RETLOC_ENUM(*a) = SvGtkOrientation(v);
			else
#endif
#ifdef GTK_TYPE_PACK_TYPE
			if (a->type == GTK_TYPE_PACK_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkPackType(v);
			else
#endif
#ifdef GTK_TYPE_POLICY_TYPE
			if (a->type == GTK_TYPE_POLICY_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkPolicyType(v);
			else
#endif
#ifdef GTK_TYPE_POSITION_TYPE
			if (a->type == GTK_TYPE_POSITION_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkPositionType(v);
			else
#endif
#ifdef GTK_TYPE_PREVIEW_TYPE
			if (a->type == GTK_TYPE_PREVIEW_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkPreviewType(v);
			else
#endif
#ifdef GTK_TYPE_SCROLL_TYPE
			if (a->type == GTK_TYPE_SCROLL_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkScrollType(v);
			else
#endif
#ifdef GTK_TYPE_SELECTION_MODE
			if (a->type == GTK_TYPE_SELECTION_MODE)
				*GTK_RETLOC_ENUM(*a) = SvGtkSelectionMode(v);
			else
#endif
#ifdef GTK_TYPE_SHADOW_TYPE
			if (a->type == GTK_TYPE_SHADOW_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkShadowType(v);
			else
#endif
#ifdef GTK_TYPE_STATE_TYPE
			if (a->type == GTK_TYPE_STATE_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkStateType(v);
			else
#endif
#ifdef GTK_TYPE_SUBMENU_DIRECTION
			if (a->type == GTK_TYPE_SUBMENU_DIRECTION)
				*GTK_RETLOC_ENUM(*a) = SvGtkSubmenuDirection(v);
			else
#endif
#ifdef GTK_TYPE_SUBMENU_PLACEMENT
			if (a->type == GTK_TYPE_SUBMENU_PLACEMENT)
				*GTK_RETLOC_ENUM(*a) = SvGtkSubmenuPlacement(v);
			else
#endif
#ifdef GTK_TYPE_TOOLBAR_CHILD_TYPE
			if (a->type == GTK_TYPE_TOOLBAR_CHILD_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkToolbarChildType(v);
			else
#endif
#ifdef GTK_TYPE_TOOLBAR_STYLE
			if (a->type == GTK_TYPE_TOOLBAR_STYLE)
				*GTK_RETLOC_ENUM(*a) = SvGtkToolbarStyle(v);
			else
#endif
#ifdef GTK_TYPE_TREE_VIEW_MODE
			if (a->type == GTK_TYPE_TREE_VIEW_MODE)
				*GTK_RETLOC_ENUM(*a) = SvGtkTreeViewMode(v);
			else
#endif
#ifdef GTK_TYPE_TROUGH_TYPE
			if (a->type == GTK_TYPE_TROUGH_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkTroughType(v);
			else
#endif
#ifdef GTK_TYPE_UPDATE_TYPE
			if (a->type == GTK_TYPE_UPDATE_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkUpdateType(v);
			else
#endif
#ifdef GTK_TYPE_WINDOW_POSITION
			if (a->type == GTK_TYPE_WINDOW_POSITION)
				*GTK_RETLOC_ENUM(*a) = SvGtkWindowPosition(v);
			else
#endif
#ifdef GTK_TYPE_WINDOW_TYPE
			if (a->type == GTK_TYPE_WINDOW_TYPE)
				*GTK_RETLOC_ENUM(*a) = SvGtkWindowType(v);
			else
#endif
				goto d_fault;
			break;
		case GTK_TYPE_FLAGS:
#ifdef GTK_TYPE_GDK_EVENT_MASK
			if (a->type == GTK_TYPE_GDK_EVENT_MASK)
				*GTK_RETLOC_FLAGS(*a) = SvGdkEventMask(v);
			else
#endif
#ifdef GTK_TYPE_GDK_GCVALUES_MASK
			if (a->type == GTK_TYPE_GDK_GCVALUES_MASK)
				*GTK_RETLOC_FLAGS(*a) = SvGdkGCValuesMask(v);
			else
#endif
#ifdef GTK_TYPE_GDK_INPUT_CONDITION
			if (a->type == GTK_TYPE_GDK_INPUT_CONDITION)
				*GTK_RETLOC_FLAGS(*a) = SvGdkInputCondition(v);
			else
#endif
#ifdef GTK_TYPE_GDK_MODIFIER_TYPE
			if (a->type == GTK_TYPE_GDK_MODIFIER_TYPE)
				*GTK_RETLOC_FLAGS(*a) = SvGdkModifierType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WMDECORATION
			if (a->type == GTK_TYPE_GDK_WMDECORATION)
				*GTK_RETLOC_FLAGS(*a) = SvGdkWMDecoration(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WMFUNCTION
			if (a->type == GTK_TYPE_GDK_WMFUNCTION)
				*GTK_RETLOC_FLAGS(*a) = SvGdkWMFunction(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW_ATTRIBUTES_TYPE
			if (a->type == GTK_TYPE_GDK_WINDOW_ATTRIBUTES_TYPE)
				*GTK_RETLOC_FLAGS(*a) = SvGdkWindowAttributesType(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW_HINTS
			if (a->type == GTK_TYPE_GDK_WINDOW_HINTS)
				*GTK_RETLOC_FLAGS(*a) = SvGdkWindowHints(v);
			else
#endif
#ifdef GTK_TYPE_ATTACH_OPTIONS
			if (a->type == GTK_TYPE_ATTACH_OPTIONS)
				*GTK_RETLOC_FLAGS(*a) = SvGtkAttachOptions(v);
			else
#endif
#ifdef GTK_TYPE_SIGNAL_RUN_TYPE
			if (a->type == GTK_TYPE_SIGNAL_RUN_TYPE)
				*GTK_RETLOC_FLAGS(*a) = SvGtkSignalRunType(v);
			else
#endif
#ifdef GTK_TYPE_SPIN_BUTTON_UPDATE_POLICY
			if (a->type == GTK_TYPE_SPIN_BUTTON_UPDATE_POLICY)
				*GTK_RETLOC_FLAGS(*a) = SvGtkSpinButtonUpdatePolicy(v);
			else
#endif
				goto d_fault;
			break;
		case GTK_TYPE_BOXED:
			if (a->type == GTK_TYPE_GDK_EVENT)
				*GTK_RETLOC_BOXED(*a) = SvGdkEvent(v);
			else
#ifdef GTK_TYPE_GDK_WINDOW
			if (a->type == GTK_TYPE_GDK_WINDOW)
				GTK_VALUE_BOXED(*a) = SvGdkBitmap(v);
			else
#endif
#ifdef GTK_TYPE_GDK_COLORMAP
			if (a->type == GTK_TYPE_GDK_COLORMAP)
				GTK_VALUE_BOXED(*a) = SvGdkColormap(v);
			else
#endif
#ifdef GTK_TYPE_GDK_FONT
			if (a->type == GTK_TYPE_GDK_FONT)
				GTK_VALUE_BOXED(*a) = SvGdkFont(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW
			if (a->type == GTK_TYPE_GDK_WINDOW)
				GTK_VALUE_BOXED(*a) = SvGdkPixmap(v);
			else
#endif
#ifdef GTK_TYPE_GDK_VISUAL
			if (a->type == GTK_TYPE_GDK_VISUAL)
				GTK_VALUE_BOXED(*a) = SvGdkVisual(v);
			else
#endif
#ifdef GTK_TYPE_GDK_WINDOW
			if (a->type == GTK_TYPE_GDK_WINDOW)
				GTK_VALUE_BOXED(*a) = SvGdkWindow(v);
			else
#endif
#ifdef GTK_TYPE_ACCELERATOR_TABLE
			if (a->type == GTK_TYPE_ACCELERATOR_TABLE)
				GTK_VALUE_BOXED(*a) = SvGtkAcceleratorTable(v);
			else
#endif
#ifdef GTK_TYPE_STYLE
			if (a->type == GTK_TYPE_STYLE)
				GTK_VALUE_BOXED(*a) = SvGtkStyle(v);
			else
#endif
				goto d_fault;
			break;
		d_fault:
		default:
			croak("Cannot set argument of type %s (fundamental type %s)", gtk_type_name(a->type), gtk_type_name(GTK_FUNDAMENTAL_TYPE(a->type)));
	}
}

void initPerlGtkDefs(void) {
	int i;
	HV * h;
	pG_EnumHash = newHV();
	pG_FlagsHash = newHV();
	

	h = newHV();
	pGtkType[0] = h;
	pGtkTypeName[0] = "Gtk::Gdk::AxisUse";
	hv_store(h, "ignore", 6, newSViv(GDK_AXIS_IGNORE), 0);
	hv_store(h, "x", 1, newSViv(GDK_AXIS_X), 0);
	hv_store(h, "y", 1, newSViv(GDK_AXIS_Y), 0);
	hv_store(h, "pressure", 8, newSViv(GDK_AXIS_PRESSURE), 0);
	hv_store(h, "x-tilt", 6, newSViv(GDK_AXIS_XTILT), 0);
	hv_store(h, "y-tilt", 6, newSViv(GDK_AXIS_YTILT), 0);
	hv_store(h, "last", 4, newSViv(GDK_AXIS_LAST), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::AxisUse", 17, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[1] = h;
	pGtkTypeName[1] = "Gtk::Gdk::ByteOrder";
	hv_store(h, "lsb-first", 9, newSViv(GDK_LSB_FIRST), 0);
	hv_store(h, "msb-first", 9, newSViv(GDK_MSB_FIRST), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::ByteOrder", 19, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[2] = h;
	pGtkTypeName[2] = "Gtk::Gdk::CapStyle";
	hv_store(h, "not-last", 8, newSViv(GDK_CAP_NOT_LAST), 0);
	hv_store(h, "butt", 4, newSViv(GDK_CAP_BUTT), 0);
	hv_store(h, "round", 5, newSViv(GDK_CAP_ROUND), 0);
	hv_store(h, "projecting", 10, newSViv(GDK_CAP_PROJECTING), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::CapStyle", 18, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[3] = h;
	pGtkTypeName[3] = "Gtk::Gdk::CursorType";
	hv_store(h, "cursor", 6, newSViv(GDK_LAST_CURSOR), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::CursorType", 20, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[4] = h;
	pGtkTypeName[4] = "Gtk::Gdk::EventType";
	hv_store(h, "nothing", 7, newSViv(GDK_NOTHING), 0);
	hv_store(h, "delete", 6, newSViv(GDK_DELETE), 0);
	hv_store(h, "destroy", 7, newSViv(GDK_DESTROY), 0);
	hv_store(h, "expose", 6, newSViv(GDK_EXPOSE), 0);
	hv_store(h, "motion-notify", 13, newSViv(GDK_MOTION_NOTIFY), 0);
	hv_store(h, "button-press", 12, newSViv(GDK_BUTTON_PRESS), 0);
	hv_store(h, "2button-press", 13, newSViv(GDK_2BUTTON_PRESS), 0);
	hv_store(h, "3button-press", 13, newSViv(GDK_3BUTTON_PRESS), 0);
	hv_store(h, "button-release", 14, newSViv(GDK_BUTTON_RELEASE), 0);
	hv_store(h, "key-press", 9, newSViv(GDK_KEY_PRESS), 0);
	hv_store(h, "key-release", 11, newSViv(GDK_KEY_RELEASE), 0);
	hv_store(h, "enter-notify", 12, newSViv(GDK_ENTER_NOTIFY), 0);
	hv_store(h, "leave-notify", 12, newSViv(GDK_LEAVE_NOTIFY), 0);
	hv_store(h, "focus-change", 12, newSViv(GDK_FOCUS_CHANGE), 0);
	hv_store(h, "configure", 9, newSViv(GDK_CONFIGURE), 0);
	hv_store(h, "map", 3, newSViv(GDK_MAP), 0);
	hv_store(h, "unmap", 5, newSViv(GDK_UNMAP), 0);
	hv_store(h, "property-notify", 15, newSViv(GDK_PROPERTY_NOTIFY), 0);
	hv_store(h, "selection-clear", 15, newSViv(GDK_SELECTION_CLEAR), 0);
	hv_store(h, "selection-request", 17, newSViv(GDK_SELECTION_REQUEST), 0);
	hv_store(h, "selection-notify", 16, newSViv(GDK_SELECTION_NOTIFY), 0);
	hv_store(h, "other-event", 11, newSViv(GDK_OTHER_EVENT), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::EventType", 19, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[5] = h;
	pGtkTypeName[5] = "Gtk::Gdk::Fill";
	hv_store(h, "solid", 5, newSViv(GDK_SOLID), 0);
	hv_store(h, "tiled", 5, newSViv(GDK_TILED), 0);
	hv_store(h, "stippled", 8, newSViv(GDK_STIPPLED), 0);
	hv_store(h, "opaque-stippled", 15, newSViv(GDK_OPAQUE_STIPPLED), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::Fill", 14, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[6] = h;
	pGtkTypeName[6] = "Gtk::Gdk::Function";
	hv_store(h, "copy", 4, newSViv(GDK_COPY), 0);
	hv_store(h, "invert", 6, newSViv(GDK_INVERT), 0);
	hv_store(h, "xor", 3, newSViv(GDK_XOR), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::Function", 18, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[7] = h;
	pGtkTypeName[7] = "Gtk::Gdk::ImageType";
	hv_store(h, "normal", 6, newSViv(GDK_IMAGE_NORMAL), 0);
	hv_store(h, "shared", 6, newSViv(GDK_IMAGE_SHARED), 0);
	hv_store(h, "fastest", 7, newSViv(GDK_IMAGE_FASTEST), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::ImageType", 19, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[8] = h;
	pGtkTypeName[8] = "Gtk::Gdk::InputMode";
	hv_store(h, "disabled", 8, newSViv(GDK_MODE_DISABLED), 0);
	hv_store(h, "screen", 6, newSViv(GDK_MODE_SCREEN), 0);
	hv_store(h, "window", 6, newSViv(GDK_MODE_WINDOW), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::InputMode", 19, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[9] = h;
	pGtkTypeName[9] = "Gtk::Gdk::InputSource";
	hv_store(h, "mouse", 5, newSViv(GDK_SOURCE_MOUSE), 0);
	hv_store(h, "pen", 3, newSViv(GDK_SOURCE_PEN), 0);
	hv_store(h, "eraser", 6, newSViv(GDK_SOURCE_ERASER), 0);
	hv_store(h, "cursor", 6, newSViv(GDK_SOURCE_CURSOR), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::InputSource", 21, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[10] = h;
	pGtkTypeName[10] = "Gtk::Gdk::JoinStyle";
	hv_store(h, "miter", 5, newSViv(GDK_JOIN_MITER), 0);
	hv_store(h, "round", 5, newSViv(GDK_JOIN_ROUND), 0);
	hv_store(h, "bevel", 5, newSViv(GDK_JOIN_BEVEL), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::JoinStyle", 19, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[11] = h;
	pGtkTypeName[11] = "Gtk::Gdk::LineStyle";
	hv_store(h, "solid", 5, newSViv(GDK_LINE_SOLID), 0);
	hv_store(h, "on-off-dash", 11, newSViv(GDK_LINE_ON_OFF_DASH), 0);
	hv_store(h, "double-dash", 11, newSViv(GDK_LINE_DOUBLE_DASH), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::LineStyle", 19, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[12] = h;
	pGtkTypeName[12] = "Gtk::Gdk::NotifyType";
	hv_store(h, "ancestor", 8, newSViv(GDK_NOTIFY_ANCESTOR), 0);
	hv_store(h, "virtual", 7, newSViv(GDK_NOTIFY_VIRTUAL), 0);
	hv_store(h, "inferior", 8, newSViv(GDK_NOTIFY_INFERIOR), 0);
	hv_store(h, "nonlinear", 9, newSViv(GDK_NOTIFY_NONLINEAR), 0);
	hv_store(h, "nonlinear-virtual", 17, newSViv(GDK_NOTIFY_NONLINEAR_VIRTUAL), 0);
	hv_store(h, "unknown", 7, newSViv(GDK_NOTIFY_UNKNOWN), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::NotifyType", 20, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[13] = h;
	pGtkTypeName[13] = "Gtk::Gdk::OverlapType";
	hv_store(h, "in", 2, newSViv(GDK_OVERLAP_RECTANGLE_IN), 0);
	hv_store(h, "out", 3, newSViv(GDK_OVERLAP_RECTANGLE_OUT), 0);
	hv_store(h, "part", 4, newSViv(GDK_OVERLAP_RECTANGLE_PART), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::OverlapType", 21, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[14] = h;
	pGtkTypeName[14] = "Gtk::Gdk::PropMode";
	hv_store(h, "replace", 7, newSViv(GDK_PROP_MODE_REPLACE), 0);
	hv_store(h, "prepend", 7, newSViv(GDK_PROP_MODE_PREPEND), 0);
	hv_store(h, "append", 6, newSViv(GDK_PROP_MODE_APPEND), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::PropMode", 18, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[15] = h;
	pGtkTypeName[15] = "Gtk::Gdk::PropertyState";
	hv_store(h, "new-value", 9, newSViv(GDK_PROPERTY_NEW_VALUE), 0);
	hv_store(h, "delete", 6, newSViv(GDK_PROPERTY_DELETE), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::PropertyState", 23, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[16] = h;
	pGtkTypeName[16] = "Gtk::Gdk::Selection";
	hv_store(h, "primary", 7, newSViv(GDK_SELECTION_PRIMARY), 0);
	hv_store(h, "secondary", 9, newSViv(GDK_SELECTION_SECONDARY), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::Selection", 19, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[17] = h;
	pGtkTypeName[17] = "Gtk::Gdk::Status";
	hv_store(h, "ok", 2, newSViv(GDK_OK), 0);
	hv_store(h, "error", 5, newSViv(GDK_ERROR), 0);
	hv_store(h, "error-param", 11, newSViv(GDK_ERROR_PARAM), 0);
	hv_store(h, "error-file", 10, newSViv(GDK_ERROR_FILE), 0);
	hv_store(h, "error-mem", 9, newSViv(GDK_ERROR_MEM), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::Status", 16, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[18] = h;
	pGtkTypeName[18] = "Gtk::Gdk::SubwindowMode";
	hv_store(h, "clip-by-children", 16, newSViv(GDK_CLIP_BY_CHILDREN), 0);
	hv_store(h, "include-inferiors", 17, newSViv(GDK_INCLUDE_INFERIORS), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::SubwindowMode", 23, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[19] = h;
	pGtkTypeName[19] = "Gtk::Gdk::VisualType";
	hv_store(h, "static-gray", 11, newSViv(GDK_VISUAL_STATIC_GRAY), 0);
	hv_store(h, "grayscale", 9, newSViv(GDK_VISUAL_GRAYSCALE), 0);
	hv_store(h, "static-color", 12, newSViv(GDK_VISUAL_STATIC_COLOR), 0);
	hv_store(h, "pseudo-color", 12, newSViv(GDK_VISUAL_PSEUDO_COLOR), 0);
	hv_store(h, "true-color", 10, newSViv(GDK_VISUAL_TRUE_COLOR), 0);
	hv_store(h, "direct-color", 12, newSViv(GDK_VISUAL_DIRECT_COLOR), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::VisualType", 20, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[20] = h;
	pGtkTypeName[20] = "Gtk::Gdk::WindowClass";
	hv_store(h, "input-output", 12, newSViv(GDK_INPUT_OUTPUT), 0);
	hv_store(h, "input-only", 10, newSViv(GDK_INPUT_ONLY), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::WindowClass", 21, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[21] = h;
	pGtkTypeName[21] = "Gtk::Gdk::WindowType";
	hv_store(h, "root", 4, newSViv(GDK_WINDOW_ROOT), 0);
	hv_store(h, "toplevel", 8, newSViv(GDK_WINDOW_TOPLEVEL), 0);
	hv_store(h, "child", 5, newSViv(GDK_WINDOW_CHILD), 0);
	hv_store(h, "dialog", 6, newSViv(GDK_WINDOW_DIALOG), 0);
	hv_store(h, "temp", 4, newSViv(GDK_WINDOW_TEMP), 0);
	hv_store(h, "pixmap", 6, newSViv(GDK_WINDOW_PIXMAP), 0);
	hv_store(pG_EnumHash, "Gtk::Gdk::WindowType", 20, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[22] = h;
	pGtkTypeName[22] = "Gtk::ArrowType";
	hv_store(h, "up", 2, newSViv(GTK_ARROW_UP), 0);
	hv_store(h, "down", 4, newSViv(GTK_ARROW_DOWN), 0);
	hv_store(h, "left", 4, newSViv(GTK_ARROW_LEFT), 0);
	hv_store(h, "right", 5, newSViv(GTK_ARROW_RIGHT), 0);
	hv_store(pG_EnumHash, "Gtk::ArrowType", 14, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[23] = h;
	pGtkTypeName[23] = "Gtk::ButtonBoxStyle";
	hv_store(h, "default-style", 13, newSViv(GTK_BUTTONBOX_DEFAULT_STYLE), 0);
	hv_store(h, "spread", 6, newSViv(GTK_BUTTONBOX_SPREAD), 0);
	hv_store(h, "edge", 4, newSViv(GTK_BUTTONBOX_EDGE), 0);
	hv_store(h, "start", 5, newSViv(GTK_BUTTONBOX_START), 0);
	hv_store(h, "end", 3, newSViv(GTK_BUTTONBOX_END), 0);
	hv_store(pG_EnumHash, "Gtk::ButtonBoxStyle", 19, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[24] = h;
	pGtkTypeName[24] = "Gtk::CellType";
	hv_store(h, "empty", 5, newSViv(GTK_CELL_EMPTY), 0);
	hv_store(h, "text", 4, newSViv(GTK_CELL_TEXT), 0);
	hv_store(h, "pixmap", 6, newSViv(GTK_CELL_PIXMAP), 0);
	hv_store(h, "pixtext", 7, newSViv(GTK_CELL_PIXTEXT), 0);
	hv_store(h, "widget", 6, newSViv(GTK_CELL_WIDGET), 0);
	hv_store(pG_EnumHash, "Gtk::CellType", 13, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[25] = h;
	pGtkTypeName[25] = "Gtk::CurveType";
	hv_store(h, "linear", 6, newSViv(GTK_CURVE_TYPE_LINEAR), 0);
	hv_store(h, "spline", 6, newSViv(GTK_CURVE_TYPE_SPLINE), 0);
	hv_store(h, "free", 4, newSViv(GTK_CURVE_TYPE_FREE), 0);
	hv_store(pG_EnumHash, "Gtk::CurveType", 14, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[26] = h;
	pGtkTypeName[26] = "Gtk::DirectionType";
	hv_store(h, "tab-forward", 11, newSViv(GTK_DIR_TAB_FORWARD), 0);
	hv_store(h, "tab-backward", 12, newSViv(GTK_DIR_TAB_BACKWARD), 0);
	hv_store(h, "up", 2, newSViv(GTK_DIR_UP), 0);
	hv_store(h, "down", 4, newSViv(GTK_DIR_DOWN), 0);
	hv_store(h, "left", 4, newSViv(GTK_DIR_LEFT), 0);
	hv_store(h, "right", 5, newSViv(GTK_DIR_RIGHT), 0);
	hv_store(pG_EnumHash, "Gtk::DirectionType", 18, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[27] = h;
	pGtkTypeName[27] = "Gtk::FundamentalType";
	hv_store(h, "invalid", 7, newSViv(GTK_TYPE_INVALID), 0);
	hv_store(h, "none", 4, newSViv(GTK_TYPE_NONE), 0);
	hv_store(h, "char", 4, newSViv(GTK_TYPE_CHAR), 0);
	hv_store(h, "bool", 4, newSViv(GTK_TYPE_BOOL), 0);
	hv_store(h, "int", 3, newSViv(GTK_TYPE_INT), 0);
	hv_store(h, "uint", 4, newSViv(GTK_TYPE_UINT), 0);
	hv_store(h, "long", 4, newSViv(GTK_TYPE_LONG), 0);
	hv_store(h, "ulong", 5, newSViv(GTK_TYPE_ULONG), 0);
	hv_store(h, "float", 5, newSViv(GTK_TYPE_FLOAT), 0);
	hv_store(h, "string", 6, newSViv(GTK_TYPE_STRING), 0);
	hv_store(h, "enum", 4, newSViv(GTK_TYPE_ENUM), 0);
	hv_store(h, "flags", 5, newSViv(GTK_TYPE_FLAGS), 0);
	hv_store(h, "boxed", 5, newSViv(GTK_TYPE_BOXED), 0);
	hv_store(h, "foreign", 7, newSViv(GTK_TYPE_FOREIGN), 0);
	hv_store(h, "callback", 8, newSViv(GTK_TYPE_CALLBACK), 0);
	hv_store(h, "args", 4, newSViv(GTK_TYPE_ARGS), 0);
	hv_store(h, "pointer", 7, newSViv(GTK_TYPE_POINTER), 0);
	hv_store(h, "signal", 6, newSViv(GTK_TYPE_SIGNAL), 0);
	hv_store(h, "c-callback", 10, newSViv(GTK_TYPE_C_CALLBACK), 0);
	hv_store(h, "object", 6, newSViv(GTK_TYPE_OBJECT), 0);
	hv_store(pG_EnumHash, "Gtk::FundamentalType", 20, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[28] = h;
	pGtkTypeName[28] = "Gtk::Justification";
	hv_store(h, "left", 4, newSViv(GTK_JUSTIFY_LEFT), 0);
	hv_store(h, "right", 5, newSViv(GTK_JUSTIFY_RIGHT), 0);
	hv_store(h, "center", 6, newSViv(GTK_JUSTIFY_CENTER), 0);
	hv_store(h, "fill", 4, newSViv(GTK_JUSTIFY_FILL), 0);
	hv_store(pG_EnumHash, "Gtk::Justification", 18, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[29] = h;
	pGtkTypeName[29] = "Gtk::MenuFactoryType";
	hv_store(h, "menu", 4, newSViv(GTK_MENU_FACTORY_MENU), 0);
	hv_store(h, "menu-bar", 8, newSViv(GTK_MENU_FACTORY_MENU_BAR), 0);
	hv_store(h, "option-menu", 11, newSViv(GTK_MENU_FACTORY_OPTION_MENU), 0);
	hv_store(pG_EnumHash, "Gtk::MenuFactoryType", 20, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[30] = h;
	pGtkTypeName[30] = "Gtk::MetricType";
	hv_store(h, "pixels", 6, newSViv(GTK_PIXELS), 0);
	hv_store(h, "inches", 6, newSViv(GTK_INCHES), 0);
	hv_store(h, "centimeters", 11, newSViv(GTK_CENTIMETERS), 0);
	hv_store(pG_EnumHash, "Gtk::MetricType", 15, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[31] = h;
	pGtkTypeName[31] = "Gtk::Orientation";
	hv_store(h, "horizontal", 10, newSViv(GTK_ORIENTATION_HORIZONTAL), 0);
	hv_store(h, "vertical", 8, newSViv(GTK_ORIENTATION_VERTICAL), 0);
	hv_store(pG_EnumHash, "Gtk::Orientation", 16, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[32] = h;
	pGtkTypeName[32] = "Gtk::PackType";
	hv_store(h, "start", 5, newSViv(GTK_PACK_START), 0);
	hv_store(h, "end", 3, newSViv(GTK_PACK_END), 0);
	hv_store(pG_EnumHash, "Gtk::PackType", 13, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[33] = h;
	pGtkTypeName[33] = "Gtk::PolicyType";
	hv_store(h, "always", 6, newSViv(GTK_POLICY_ALWAYS), 0);
	hv_store(h, "automatic", 9, newSViv(GTK_POLICY_AUTOMATIC), 0);
	hv_store(pG_EnumHash, "Gtk::PolicyType", 15, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[34] = h;
	pGtkTypeName[34] = "Gtk::PositionType";
	hv_store(h, "left", 4, newSViv(GTK_POS_LEFT), 0);
	hv_store(h, "right", 5, newSViv(GTK_POS_RIGHT), 0);
	hv_store(h, "top", 3, newSViv(GTK_POS_TOP), 0);
	hv_store(h, "bottom", 6, newSViv(GTK_POS_BOTTOM), 0);
	hv_store(pG_EnumHash, "Gtk::PositionType", 17, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[35] = h;
	pGtkTypeName[35] = "Gtk::PreviewType";
	hv_store(h, "color", 5, newSViv(GTK_PREVIEW_COLOR), 0);
	hv_store(h, "grayscale", 9, newSViv(GTK_PREVIEW_GRAYSCALE), 0);
	hv_store(pG_EnumHash, "Gtk::PreviewType", 16, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[36] = h;
	pGtkTypeName[36] = "Gtk::ScrollType";
	hv_store(h, "none", 4, newSViv(GTK_SCROLL_NONE), 0);
	hv_store(h, "step-backward", 13, newSViv(GTK_SCROLL_STEP_BACKWARD), 0);
	hv_store(h, "step-forward", 12, newSViv(GTK_SCROLL_STEP_FORWARD), 0);
	hv_store(h, "page-backward", 13, newSViv(GTK_SCROLL_PAGE_BACKWARD), 0);
	hv_store(h, "page-forward", 12, newSViv(GTK_SCROLL_PAGE_FORWARD), 0);
	hv_store(pG_EnumHash, "Gtk::ScrollType", 15, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[37] = h;
	pGtkTypeName[37] = "Gtk::SelectionMode";
	hv_store(h, "single", 6, newSViv(GTK_SELECTION_SINGLE), 0);
	hv_store(h, "browse", 6, newSViv(GTK_SELECTION_BROWSE), 0);
	hv_store(h, "multiple", 8, newSViv(GTK_SELECTION_MULTIPLE), 0);
	hv_store(h, "extended", 8, newSViv(GTK_SELECTION_EXTENDED), 0);
	hv_store(pG_EnumHash, "Gtk::SelectionMode", 18, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[38] = h;
	pGtkTypeName[38] = "Gtk::ShadowType";
	hv_store(h, "none", 4, newSViv(GTK_SHADOW_NONE), 0);
	hv_store(h, "in", 2, newSViv(GTK_SHADOW_IN), 0);
	hv_store(h, "out", 3, newSViv(GTK_SHADOW_OUT), 0);
	hv_store(h, "etched-in", 9, newSViv(GTK_SHADOW_ETCHED_IN), 0);
	hv_store(h, "etched-out", 10, newSViv(GTK_SHADOW_ETCHED_OUT), 0);
	hv_store(pG_EnumHash, "Gtk::ShadowType", 15, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[39] = h;
	pGtkTypeName[39] = "Gtk::StateType";
	hv_store(h, "normal", 6, newSViv(GTK_STATE_NORMAL), 0);
	hv_store(h, "active", 6, newSViv(GTK_STATE_ACTIVE), 0);
	hv_store(h, "prelight", 8, newSViv(GTK_STATE_PRELIGHT), 0);
	hv_store(h, "selected", 8, newSViv(GTK_STATE_SELECTED), 0);
	hv_store(h, "insensitive", 11, newSViv(GTK_STATE_INSENSITIVE), 0);
	hv_store(pG_EnumHash, "Gtk::StateType", 14, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[40] = h;
	pGtkTypeName[40] = "Gtk::SubmenuDirection";
	hv_store(h, "left", 4, newSViv(GTK_DIRECTION_LEFT), 0);
	hv_store(h, "right", 5, newSViv(GTK_DIRECTION_RIGHT), 0);
	hv_store(pG_EnumHash, "Gtk::SubmenuDirection", 21, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[41] = h;
	pGtkTypeName[41] = "Gtk::SubmenuPlacement";
	hv_store(h, "top-bottom", 10, newSViv(GTK_TOP_BOTTOM), 0);
	hv_store(h, "left-right", 10, newSViv(GTK_LEFT_RIGHT), 0);
	hv_store(pG_EnumHash, "Gtk::SubmenuPlacement", 21, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[42] = h;
	pGtkTypeName[42] = "Gtk::ToolbarChildType";
	hv_store(h, "space", 5, newSViv(GTK_TOOLBAR_CHILD_SPACE), 0);
	hv_store(h, "button", 6, newSViv(GTK_TOOLBAR_CHILD_BUTTON), 0);
	hv_store(h, "toggle-button", 13, newSViv(GTK_TOOLBAR_CHILD_TOGGLEBUTTON), 0);
	hv_store(h, "radio-button", 12, newSViv(GTK_TOOLBAR_CHILD_RADIOBUTTON), 0);
	hv_store(h, "widget", 6, newSViv(GTK_TOOLBAR_CHILD_WIDGET), 0);
	hv_store(pG_EnumHash, "Gtk::ToolbarChildType", 21, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[43] = h;
	pGtkTypeName[43] = "Gtk::ToolbarStyle";
	hv_store(h, "icons", 5, newSViv(GTK_TOOLBAR_ICONS), 0);
	hv_store(h, "text", 4, newSViv(GTK_TOOLBAR_TEXT), 0);
	hv_store(h, "both", 4, newSViv(GTK_TOOLBAR_BOTH), 0);
	hv_store(pG_EnumHash, "Gtk::ToolbarStyle", 17, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[44] = h;
	pGtkTypeName[44] = "Gtk::TreeViewMode";
	hv_store(h, "line", 4, newSViv(GTK_TREE_VIEW_LINE), 0);
	hv_store(h, "item", 4, newSViv(GTK_TREE_VIEW_ITEM), 0);
	hv_store(pG_EnumHash, "Gtk::TreeViewMode", 17, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[45] = h;
	pGtkTypeName[45] = "Gtk::TroughType";
	hv_store(h, "none", 4, newSViv(GTK_TROUGH_NONE), 0);
	hv_store(h, "start", 5, newSViv(GTK_TROUGH_START), 0);
	hv_store(h, "end", 3, newSViv(GTK_TROUGH_END), 0);
	hv_store(pG_EnumHash, "Gtk::TroughType", 15, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[46] = h;
	pGtkTypeName[46] = "Gtk::UpdateType";
	hv_store(h, "continuous", 10, newSViv(GTK_UPDATE_CONTINUOUS), 0);
	hv_store(h, "discontinuous", 13, newSViv(GTK_UPDATE_DISCONTINUOUS), 0);
	hv_store(h, "delayed", 7, newSViv(GTK_UPDATE_DELAYED), 0);
	hv_store(pG_EnumHash, "Gtk::UpdateType", 15, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[47] = h;
	pGtkTypeName[47] = "Gtk::WindowPosition";
	hv_store(h, "none", 4, newSViv(GTK_WIN_POS_NONE), 0);
	hv_store(h, "center", 6, newSViv(GTK_WIN_POS_CENTER), 0);
	hv_store(h, "mouse", 5, newSViv(GTK_WIN_POS_MOUSE), 0);
	hv_store(pG_EnumHash, "Gtk::WindowPosition", 19, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[48] = h;
	pGtkTypeName[48] = "Gtk::WindowType";
	hv_store(h, "toplevel", 8, newSViv(GTK_WINDOW_TOPLEVEL), 0);
	hv_store(h, "dialog", 6, newSViv(GTK_WINDOW_DIALOG), 0);
	hv_store(h, "popup", 5, newSViv(GTK_WINDOW_POPUP), 0);
	hv_store(pG_EnumHash, "Gtk::WindowType", 15, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[49] = h;
	pGtkTypeName[49] = "Gtk::Gdk::EventMask";
	hv_store(h, "exposure-mask", 13, newSViv(GDK_EXPOSURE_MASK), 0);
	hv_store(h, "pointer-motion-mask", 19, newSViv(GDK_POINTER_MOTION_MASK), 0);
	hv_store(h, "pointer-motion-hint-mask", 24, newSViv(GDK_POINTER_MOTION_HINT_MASK), 0);
	hv_store(h, "button-motion-mask", 18, newSViv(GDK_BUTTON_MOTION_MASK), 0);
	hv_store(h, "button1-motion-mask", 19, newSViv(GDK_BUTTON1_MOTION_MASK), 0);
	hv_store(h, "button2-motion-mask", 19, newSViv(GDK_BUTTON2_MOTION_MASK), 0);
	hv_store(h, "button3-motion-mask", 19, newSViv(GDK_BUTTON3_MOTION_MASK), 0);
	hv_store(h, "button-press-mask", 17, newSViv(GDK_BUTTON_PRESS_MASK), 0);
	hv_store(h, "button-release-mask", 19, newSViv(GDK_BUTTON_RELEASE_MASK), 0);
	hv_store(h, "key-press-mask", 14, newSViv(GDK_KEY_PRESS_MASK), 0);
	hv_store(h, "key-release-mask", 16, newSViv(GDK_KEY_RELEASE_MASK), 0);
	hv_store(h, "enter-notify-mask", 17, newSViv(GDK_ENTER_NOTIFY_MASK), 0);
	hv_store(h, "leave-notify-mask", 17, newSViv(GDK_LEAVE_NOTIFY_MASK), 0);
	hv_store(h, "focus-change-mask", 17, newSViv(GDK_FOCUS_CHANGE_MASK), 0);
	hv_store(h, "structure-mask", 14, newSViv(GDK_STRUCTURE_MASK), 0);
	hv_store(h, "all-events-mask", 15, newSViv(GDK_ALL_EVENTS_MASK), 0);
	hv_store(pG_FlagsHash, "Gtk::Gdk::EventMask", 19, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[50] = h;
	pGtkTypeName[50] = "Gtk::Gdk::GCValuesMask";
	hv_store(h, "foreground", 10, newSViv(GDK_GC_FOREGROUND), 0);
	hv_store(h, "background", 10, newSViv(GDK_GC_BACKGROUND), 0);
	hv_store(h, "font", 4, newSViv(GDK_GC_FONT), 0);
	hv_store(h, "function", 8, newSViv(GDK_GC_FUNCTION), 0);
	hv_store(h, "fill", 4, newSViv(GDK_GC_FILL), 0);
	hv_store(h, "tile", 4, newSViv(GDK_GC_TILE), 0);
	hv_store(h, "stipple", 7, newSViv(GDK_GC_STIPPLE), 0);
	hv_store(h, "clip-mask", 9, newSViv(GDK_GC_CLIP_MASK), 0);
	hv_store(h, "subwindow", 9, newSViv(GDK_GC_SUBWINDOW), 0);
	hv_store(h, "ts-x-origin", 11, newSViv(GDK_GC_TS_X_ORIGIN), 0);
	hv_store(h, "ts-y-origin", 11, newSViv(GDK_GC_TS_Y_ORIGIN), 0);
	hv_store(h, "clip-x-origin", 13, newSViv(GDK_GC_CLIP_X_ORIGIN), 0);
	hv_store(h, "clip-y-origin", 13, newSViv(GDK_GC_CLIP_Y_ORIGIN), 0);
	hv_store(h, "exposures", 9, newSViv(GDK_GC_EXPOSURES), 0);
	hv_store(h, "line-width", 10, newSViv(GDK_GC_LINE_WIDTH), 0);
	hv_store(h, "line-style", 10, newSViv(GDK_GC_LINE_STYLE), 0);
	hv_store(h, "cap-style", 9, newSViv(GDK_GC_CAP_STYLE), 0);
	hv_store(h, "join-style", 10, newSViv(GDK_GC_JOIN_STYLE), 0);
	hv_store(pG_FlagsHash, "Gtk::Gdk::GCValuesMask", 22, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[51] = h;
	pGtkTypeName[51] = "Gtk::Gdk::InputCondition";
	hv_store(h, "read", 4, newSViv(GDK_INPUT_READ), 0);
	hv_store(h, "write", 5, newSViv(GDK_INPUT_WRITE), 0);
	hv_store(h, "exception", 9, newSViv(GDK_INPUT_EXCEPTION), 0);
	hv_store(pG_FlagsHash, "Gtk::Gdk::InputCondition", 24, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[52] = h;
	pGtkTypeName[52] = "Gtk::Gdk::ModifierType";
	hv_store(h, "shift-mask", 10, newSViv(GDK_SHIFT_MASK), 0);
	hv_store(h, "lock-mask", 9, newSViv(GDK_LOCK_MASK), 0);
	hv_store(h, "control-mask", 12, newSViv(GDK_CONTROL_MASK), 0);
	hv_store(h, "mod1-mask", 9, newSViv(GDK_MOD1_MASK), 0);
	hv_store(h, "mod2-mask", 9, newSViv(GDK_MOD2_MASK), 0);
	hv_store(h, "mod3-mask", 9, newSViv(GDK_MOD3_MASK), 0);
	hv_store(h, "mod4-mask", 9, newSViv(GDK_MOD4_MASK), 0);
	hv_store(h, "mod5-mask", 9, newSViv(GDK_MOD5_MASK), 0);
	hv_store(h, "button1-mask", 12, newSViv(GDK_BUTTON1_MASK), 0);
	hv_store(h, "button2-mask", 12, newSViv(GDK_BUTTON2_MASK), 0);
	hv_store(h, "button3-mask", 12, newSViv(GDK_BUTTON3_MASK), 0);
	hv_store(h, "button4-mask", 12, newSViv(GDK_BUTTON4_MASK), 0);
	hv_store(h, "button5-mask", 12, newSViv(GDK_BUTTON5_MASK), 0);
	hv_store(pG_FlagsHash, "Gtk::Gdk::ModifierType", 22, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[53] = h;
	pGtkTypeName[53] = "Gtk::Gdk::WMDecoration";
	hv_store(h, "all", 3, newSViv(GDK_DECOR_ALL), 0);
	hv_store(h, "border", 6, newSViv(GDK_DECOR_BORDER), 0);
	hv_store(h, "resizeh", 7, newSViv(GDK_DECOR_RESIZEH), 0);
	hv_store(h, "title", 5, newSViv(GDK_DECOR_TITLE), 0);
	hv_store(h, "menu", 4, newSViv(GDK_DECOR_MENU), 0);
	hv_store(h, "minimize", 8, newSViv(GDK_DECOR_MINIMIZE), 0);
	hv_store(h, "maximize", 8, newSViv(GDK_DECOR_MAXIMIZE), 0);
	hv_store(pG_FlagsHash, "Gtk::Gdk::WMDecoration", 22, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[54] = h;
	pGtkTypeName[54] = "Gtk::Gdk::WMFunction";
	hv_store(h, "all", 3, newSViv(GDK_FUNC_ALL), 0);
	hv_store(h, "resize", 6, newSViv(GDK_FUNC_RESIZE), 0);
	hv_store(h, "move", 4, newSViv(GDK_FUNC_MOVE), 0);
	hv_store(h, "minimize", 8, newSViv(GDK_FUNC_MINIMIZE), 0);
	hv_store(h, "maximize", 8, newSViv(GDK_FUNC_MAXIMIZE), 0);
	hv_store(h, "close", 5, newSViv(GDK_FUNC_CLOSE), 0);
	hv_store(pG_FlagsHash, "Gtk::Gdk::WMFunction", 20, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[55] = h;
	pGtkTypeName[55] = "Gtk::Gdk::WindowAttributesType";
	hv_store(h, "title", 5, newSViv(GDK_WA_TITLE), 0);
	hv_store(h, "x", 1, newSViv(GDK_WA_X), 0);
	hv_store(h, "y", 1, newSViv(GDK_WA_Y), 0);
	hv_store(h, "cursor", 6, newSViv(GDK_WA_CURSOR), 0);
	hv_store(h, "colormap", 8, newSViv(GDK_WA_COLORMAP), 0);
	hv_store(h, "visual", 6, newSViv(GDK_WA_VISUAL), 0);
	hv_store(pG_FlagsHash, "Gtk::Gdk::WindowAttributesType", 30, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[56] = h;
	pGtkTypeName[56] = "Gtk::Gdk::WindowHints";
	hv_store(h, "pos", 3, newSViv(GDK_HINT_POS), 0);
	hv_store(h, "min-size", 8, newSViv(GDK_HINT_MIN_SIZE), 0);
	hv_store(h, "max-size", 8, newSViv(GDK_HINT_MAX_SIZE), 0);
	hv_store(pG_FlagsHash, "Gtk::Gdk::WindowHints", 21, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[57] = h;
	pGtkTypeName[57] = "Gtk::AttachOptions";
	hv_store(h, "expand", 6, newSViv(GTK_EXPAND), 0);
	hv_store(h, "shrink", 6, newSViv(GTK_SHRINK), 0);
	hv_store(h, "fill", 4, newSViv(GTK_FILL), 0);
	hv_store(pG_FlagsHash, "Gtk::AttachOptions", 18, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[58] = h;
	pGtkTypeName[58] = "Gtk::SignalRunType";
	hv_store(h, "first", 5, newSViv(GTK_RUN_FIRST), 0);
	hv_store(h, "last", 4, newSViv(GTK_RUN_LAST), 0);
	hv_store(h, "both", 4, newSViv(GTK_RUN_BOTH), 0);
	hv_store(h, "mask", 4, newSViv(GTK_RUN_MASK), 0);
	hv_store(h, "no-recurse", 10, newSViv(GTK_RUN_NO_RECURSE), 0);
	hv_store(pG_FlagsHash, "Gtk::SignalRunType", 18, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	h = newHV();
	pGtkType[59] = h;
	pGtkTypeName[59] = "Gtk::SpinButtonUpdatePolicy";
	hv_store(h, "always", 6, newSViv(GTK_UPDATE_ALWAYS), 0);
	hv_store(h, "if-valid", 8, newSViv(GTK_UPDATE_IF_VALID), 0);
	hv_store(h, "snap-to-ticks", 13, newSViv(GTK_UPDATE_SNAP_TO_TICKS), 0);
	hv_store(pG_FlagsHash, "Gtk::SpinButtonUpdatePolicy", 27, newRV((SV*)h), 0);
 SvREFCNT_dec(h);

	/*for(i=0;i<60;i++) {
		HV * p = perl_get_hv(pGtkTypeName[i], TRUE);
		sv_setsv((SV*)p, (SV*)pGtkType[i]);
	}*/

	gtk_typecasts = newAV();
	types = newHV();

#ifdef GTK_ADJUSTMENT
	add_typecast(gtk_adjustment_get_type(),	"Gtk::Adjustment");
#endif
#ifdef GTK_ALIGNMENT
	add_typecast(gtk_alignment_get_type(),	"Gtk::Alignment");
#endif
#ifdef GTK_ARROW
	add_typecast(gtk_arrow_get_type(),	"Gtk::Arrow");
#endif
#ifdef GTK_ASPECT_FRAME
	add_typecast(gtk_aspect_frame_get_type(),	"Gtk::AspectFrame");
#endif
#ifdef GTK_BIN
	add_typecast(gtk_bin_get_type(),	"Gtk::Bin");
#endif
#ifdef GTK_BOX
	add_typecast(gtk_box_get_type(),	"Gtk::Box");
#endif
#ifdef GTK_BUTTON
	add_typecast(gtk_button_get_type(),	"Gtk::Button");
#endif
#ifdef GTK_BUTTON_BOX
	add_typecast(gtk_button_box_get_type(),	"Gtk::ButtonBox");
#endif
#ifdef GTK_CLIST
	add_typecast(gtk_clist_get_type(),	"Gtk::CList");
#endif
#ifdef GTK_CHECK_BUTTON
	add_typecast(gtk_check_button_get_type(),	"Gtk::CheckButton");
#endif
#ifdef GTK_CHECK_MENU_ITEM
	add_typecast(gtk_check_menu_item_get_type(),	"Gtk::CheckMenuItem");
#endif
#ifdef GTK_COLOR_SELECTION
	add_typecast(gtk_color_selection_get_type(),	"Gtk::ColorSelection");
#endif
#ifdef GTK_COLOR_SELECTION_DIALOG
	add_typecast(gtk_color_selection_dialog_get_type(),	"Gtk::ColorSelectionDialog");
#endif
#ifdef GTK_COMBO
	add_typecast(gtk_combo_get_type(),	"Gtk::Combo");
#endif
#ifdef GTK_CONTAINER
	add_typecast(gtk_container_get_type(),	"Gtk::Container");
#endif
#ifdef GTK_CURVE
	add_typecast(gtk_curve_get_type(),	"Gtk::Curve");
#endif
#ifdef GTK_DATA
	add_typecast(gtk_data_get_type(),	"Gtk::Data");
#endif
#ifdef GTK_DIALOG
	add_typecast(gtk_dialog_get_type(),	"Gtk::Dialog");
#endif
#ifdef GTK_DRAWING_AREA
	add_typecast(gtk_drawing_area_get_type(),	"Gtk::DrawingArea");
#endif
#ifdef GTK_EDITABLE
	add_typecast(gtk_editable_get_type(),	"Gtk::Editable");
#endif
#ifdef GTK_ENTRY
	add_typecast(gtk_entry_get_type(),	"Gtk::Entry");
#endif
#ifdef GTK_EVENT_BOX
	add_typecast(gtk_event_box_get_type(),	"Gtk::EventBox");
#endif
#ifdef GTK_FILE_SELECTION
	add_typecast(gtk_file_selection_get_type(),	"Gtk::FileSelection");
#endif
#ifdef GTK_FIXED
	add_typecast(gtk_fixed_get_type(),	"Gtk::Fixed");
#endif
#ifdef GTK_FRAME
	add_typecast(gtk_frame_get_type(),	"Gtk::Frame");
#endif
#ifdef GTK_GAMMA_CURVE
	add_typecast(gtk_gamma_curve_get_type(),	"Gtk::GammaCurve");
#endif
#ifdef GTK_HBOX
	add_typecast(gtk_hbox_get_type(),	"Gtk::HBox");
#endif
#ifdef GTK_HBUTTON_BOX
	add_typecast(gtk_hbutton_box_get_type(),	"Gtk::HButtonBox");
#endif
#ifdef GTK_HPANED
	add_typecast(gtk_hpaned_get_type(),	"Gtk::HPaned");
#endif
#ifdef GTK_HRULER
	add_typecast(gtk_hruler_get_type(),	"Gtk::HRuler");
#endif
#ifdef GTK_HSCALE
	add_typecast(gtk_hscale_get_type(),	"Gtk::HScale");
#endif
#ifdef GTK_HSCROLLBAR
	add_typecast(gtk_hscrollbar_get_type(),	"Gtk::HScrollbar");
#endif
#ifdef GTK_HSEPARATOR
	add_typecast(gtk_hseparator_get_type(),	"Gtk::HSeparator");
#endif
#ifdef GTK_HANDLE_BOX
	add_typecast(gtk_handle_box_get_type(),	"Gtk::HandleBox");
#endif
#ifdef GTK_IMAGE
	add_typecast(gtk_image_get_type(),	"Gtk::Image");
#endif
#ifdef GTK_INPUT_DIALOG
	add_typecast(gtk_input_dialog_get_type(),	"Gtk::InputDialog");
#endif
#ifdef GTK_ITEM
	add_typecast(gtk_item_get_type(),	"Gtk::Item");
#endif
#ifdef GTK_LABEL
	add_typecast(gtk_label_get_type(),	"Gtk::Label");
#endif
#ifdef GTK_LIST
	add_typecast(gtk_list_get_type(),	"Gtk::List");
#endif
#ifdef GTK_LIST_ITEM
	add_typecast(gtk_list_item_get_type(),	"Gtk::ListItem");
#endif
#ifdef GTK_MENU
	add_typecast(gtk_menu_get_type(),	"Gtk::Menu");
#endif
#ifdef GTK_MENU_BAR
	add_typecast(gtk_menu_bar_get_type(),	"Gtk::MenuBar");
#endif
#ifdef GTK_MENU_ITEM
	add_typecast(gtk_menu_item_get_type(),	"Gtk::MenuItem");
#endif
#ifdef GTK_MENU_SHELL
	add_typecast(gtk_menu_shell_get_type(),	"Gtk::MenuShell");
#endif
#ifdef GTK_MISC
	add_typecast(gtk_misc_get_type(),	"Gtk::Misc");
#endif
#ifdef GTK_NOTEBOOK
	add_typecast(gtk_notebook_get_type(),	"Gtk::Notebook");
#endif
#ifdef GTK_OBJECT
	add_typecast(gtk_object_get_type(),	"Gtk::Object");
#endif
#ifdef GTK_OPTION_MENU
	add_typecast(gtk_option_menu_get_type(),	"Gtk::OptionMenu");
#endif
#ifdef GTK_PANED
	add_typecast(gtk_paned_get_type(),	"Gtk::Paned");
#endif
#ifdef GTK_PIXMAP
	add_typecast(gtk_pixmap_get_type(),	"Gtk::Pixmap");
#endif
#ifdef GTK_PREVIEW
	add_typecast(gtk_preview_get_type(),	"Gtk::Preview");
#endif
#ifdef GTK_PROGRESS_BAR
	add_typecast(gtk_progress_bar_get_type(),	"Gtk::ProgressBar");
#endif
#ifdef GTK_RADIO_BUTTON
	add_typecast(gtk_radio_button_get_type(),	"Gtk::RadioButton");
#endif
#ifdef GTK_RADIO_MENU_ITEM
	add_typecast(gtk_radio_menu_item_get_type(),	"Gtk::RadioMenuItem");
#endif
#ifdef GTK_RANGE
	add_typecast(gtk_range_get_type(),	"Gtk::Range");
#endif
#ifdef GTK_RULER
	add_typecast(gtk_ruler_get_type(),	"Gtk::Ruler");
#endif
#ifdef GTK_SCALE
	add_typecast(gtk_scale_get_type(),	"Gtk::Scale");
#endif
#ifdef GTK_SCROLLBAR
	add_typecast(gtk_scrollbar_get_type(),	"Gtk::Scrollbar");
#endif
#ifdef GTK_SCROLLED_WINDOW
	add_typecast(gtk_scrolled_window_get_type(),	"Gtk::ScrolledWindow");
#endif
#ifdef GTK_SEPARATOR
	add_typecast(gtk_separator_get_type(),	"Gtk::Separator");
#endif
#ifdef GTK_SPIN_BUTTON
	add_typecast(gtk_spin_button_get_type(),	"Gtk::SpinButton");
#endif
#ifdef GTK_STATUSBAR
	add_typecast(gtk_statusbar_get_type(),	"Gtk::Statusbar");
#endif
#ifdef GTK_TABLE
	add_typecast(gtk_table_get_type(),	"Gtk::Table");
#endif
#ifdef GTK_TEXT
	add_typecast(gtk_text_get_type(),	"Gtk::Text");
#endif
#ifdef GTK_TIPS_QUERY
	add_typecast(gtk_tips_query_get_type(),	"Gtk::TipsQuery");
#endif
#ifdef GTK_TOGGLE_BUTTON
	add_typecast(gtk_toggle_button_get_type(),	"Gtk::ToggleButton");
#endif
#ifdef GTK_TOOLBAR
	add_typecast(gtk_toolbar_get_type(),	"Gtk::Toolbar");
#endif
#ifdef GTK_TOOLTIPS
	add_typecast(gtk_tooltips_get_type(),	"Gtk::Tooltips");
#endif
#ifdef GTK_TREE
	add_typecast(gtk_tree_get_type(),	"Gtk::Tree");
#endif
#ifdef GTK_TREE_ITEM
	add_typecast(gtk_tree_item_get_type(),	"Gtk::TreeItem");
#endif
#ifdef GTK_VBOX
	add_typecast(gtk_vbox_get_type(),	"Gtk::VBox");
#endif
#ifdef GTK_VBUTTON_BOX
	add_typecast(gtk_vbutton_box_get_type(),	"Gtk::VButtonBox");
#endif
#ifdef GTK_VPANED
	add_typecast(gtk_vpaned_get_type(),	"Gtk::VPaned");
#endif
#ifdef GTK_VRULER
	add_typecast(gtk_vruler_get_type(),	"Gtk::VRuler");
#endif
#ifdef GTK_VSCALE
	add_typecast(gtk_vscale_get_type(),	"Gtk::VScale");
#endif
#ifdef GTK_VSCROLLBAR
	add_typecast(gtk_vscrollbar_get_type(),	"Gtk::VScrollbar");
#endif
#ifdef GTK_VSEPARATOR
	add_typecast(gtk_vseparator_get_type(),	"Gtk::VSeparator");
#endif
#ifdef GTK_VIEWPORT
	add_typecast(gtk_viewport_get_type(),	"Gtk::Viewport");
#endif
#ifdef GTK_WIDGET
	add_typecast(gtk_widget_get_type(),	"Gtk::Widget");
#endif
#ifdef GTK_WINDOW
	add_typecast(gtk_window_get_type(),	"Gtk::Window");
#endif
}
