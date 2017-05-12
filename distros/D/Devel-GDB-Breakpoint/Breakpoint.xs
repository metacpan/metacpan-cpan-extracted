#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

void bp(int val) {}

MODULE = Devel::GDB::Breakpoint		PACKAGE = Devel::GDB::Breakpoint		

PROTOTYPES: ENABLE

int breakpoint(val)
        int val
    CODE:
        bp(val);
