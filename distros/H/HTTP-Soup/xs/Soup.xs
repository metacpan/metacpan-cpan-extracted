#include "soup-perl.h"


MODULE = HTTP::Soup  PACKAGE = HTTP::Soup  PREFIX = soup_


BOOT:
#include "register.xsh"
#include "boot.xsh"

