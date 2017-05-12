#include "EXTERN.h"
#include "perl.h"
#include "ppport.h"
#include "XSUB.h"

static void
crash_now_for_real(char *suicide_message)
{
    int *p = NULL;
    printf("%d", *p); /* cause a segfault */
}


static void
crash_now(char *suicide_message, int attempt_num)
{
    crash_now_for_real(suicide_message);
}

MODULE=Debug::DumpCore PACKAGE=Debug::DumpCore PREFIX=dump_core_

void
dump_core_segv()

    CODE:
    crash_now("Cannot stand this life anymore", 42);

