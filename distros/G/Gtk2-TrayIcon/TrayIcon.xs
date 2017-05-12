#include "gtk2perl.h"
#include "eggtrayicon.h"
#include "trayicon-autogen.h"

MODULE = Gtk2::TrayIcon	PACKAGE = Gtk2::TrayIcon	PREFIX = egg_tray_icon_

#ifdef GDK_TYPE_SCREEN

##  EggTrayIcon *egg_tray_icon_new_for_screen (GdkScreen *screen, const gchar *name) 
EggTrayIcon *
egg_tray_icon_new_for_screen (class, screen, name)
		GdkScreen *screen
		const gchar *name
	C_ARGS:
		screen, name

#endif

##  EggTrayIcon *egg_tray_icon_new (const gchar *name) 
EggTrayIcon *
egg_tray_icon_new (class, name)
		const gchar *name
	C_ARGS:
		name
	

##  guint egg_tray_icon_send_message (EggTrayIcon *icon, gint timeout, const char *message, gint len) 
guint
egg_tray_icon_send_message (icon, timeout, message)
		EggTrayIcon *icon
		gint timeout
		const gchar *message
	C_ARGS:
		icon, timeout, message, -1

##  void egg_tray_icon_cancel_message (EggTrayIcon *icon, guint id) 
void
egg_tray_icon_cancel_message (icon, id)
	EggTrayIcon *icon
	guint id

##  GtkOrientation egg_tray_icon_get_orientation (EggTrayIcon *icon) 
GtkOrientation
egg_tray_icon_get_orientation (icon)
	EggTrayIcon *icon

BOOT:
#include "register.xsh"
#include "boot.xsh"

