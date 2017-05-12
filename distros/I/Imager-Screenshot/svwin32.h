#ifndef SVWIN32_H
#define SVWIN32_H

#include "EXTERN.h"
#include <windows.h>
#include "perl.h"

typedef unsigned SSHWND;

SSHWND
hwnd_from_sv(pTHX_ SV *sv);

#endif
