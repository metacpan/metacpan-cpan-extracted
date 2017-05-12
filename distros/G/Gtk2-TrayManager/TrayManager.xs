#include "gtk2perl.h"
#include "eggtraymanager.h"
#include "traymanager-autogen.h"

#define SvEggTrayManagerChild           (EggTrayManagerChild*)SvGtkSocket
#define newSVEggTrayManagerChild        newSVGtkSocket

MODULE = Gtk2::TrayManager	PACKAGE = Gtk2::TrayManager	PREFIX = egg_tray_manager_

##  gboolean egg_tray_manager_check_running (GdkScreen *screen) 
gboolean
egg_tray_manager_check_running (class,screen)
	GdkScreen* screen
	C_ARGS:
		screen

##  EggTrayManager *egg_tray_manager_new (void) 
EggTrayManager_noinc*
egg_tray_manager_new (class)
	C_ARGS:

##  gboolean egg_tray_manager_manage_screen (EggTrayManager *manager, GdkScreen *screen) 
gboolean
egg_tray_manager_manage_screen (manager, screen)
	EggTrayManager *manager
	GdkScreen *screen

##  char *egg_tray_manager_get_child_title (EggTrayManager *manager, EggTrayManagerChild *child) 
char *
egg_tray_manager_get_child_title (manager, child)
	EggTrayManager* manager
	EggTrayManagerChild* child

##  void egg_tray_manager_set_orientation (EggTrayManager *manager, GtkOrientation orientation) 
void
egg_tray_manager_set_orientation (manager, orientation)
	EggTrayManager* manager
	GtkOrientation orientation

##  GtkOrientation egg_tray_manager_get_orientation (EggTrayManager *manager) 
GtkOrientation
egg_tray_manager_get_orientation (manager)
	EggTrayManager* manager

BOOT:
#include "register.xsh"
#include "boot.xsh"

