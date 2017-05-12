#include "phatperl.h"

MODULE = Gtk2::Phat	PACKAGE = Gtk2::Phat	PREFIX = phat_

PROTOTYPES: DISABLE

BOOT:
#include "register.xsh"
#include "boot.xsh"
