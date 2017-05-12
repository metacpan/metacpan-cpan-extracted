#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <string.h>
#include <sys/mman.h>

struct smaps_sizes {
    int KernelPageSize;
    int MMUPageSize;
    int Private_Clean;
    int Private_Dirty;
    int Pss;
    int Referenced;
    int Rss;
    int Shared_Clean;
    int Shared_Dirty;
    int Size;
    int Swap;
};

MODULE = Linux::Smaps::Tiny PACKAGE = Linux::Smaps::Tiny
PROTOTYPES: DISABLE

SV*
get_smaps_summary(char* process = "self")
PPCODE:
    struct smaps_sizes sizes;
    memset(&sizes, 0, sizeof sizes);

    char filename[100];
    memset(&filename, 0, sizeof filename);
    strcat(filename, "/proc/");
    strcat(filename, process);
    strcat(filename, "/smaps");

    FILE *file = fopen(filename, "r");
    if (!file) {
        croak("Failed to read '%s': [%d] %s", filename, errno, strerror(errno));
    }

    char line[100];
    while (fgets(line, sizeof line, file))
    {
        char substr[32];
        int n;
        if (sscanf(line, "%32[^:]: %d", substr, &n) == 2)
        {
            /* I'm counting on a modern compiler like GCC or clang to
             * optimize this to a jump table. They can actually do
             * that these days with their fancy technology.
             */
            if      (strcmp(substr, "KernelPageSize") == 0) { sizes.KernelPageSize += n; }
            else if (strcmp(substr, "MMUPageSize")    == 0) { sizes.MMUPageSize    += n; }
            else if (strcmp(substr, "Private_Clean")  == 0) { sizes.Private_Clean  += n; }
            else if (strcmp(substr, "Private_Dirty")  == 0) { sizes.Private_Dirty  += n; }
            else if (strcmp(substr, "Pss")            == 0) { sizes.Pss            += n; }
            else if (strcmp(substr, "Referenced")     == 0) { sizes.Referenced     += n; }
            else if (strcmp(substr, "Rss")            == 0) { sizes.Rss            += n; }
            else if (strcmp(substr, "Shared_Clean")   == 0) { sizes.Shared_Clean   += n; }
            else if (strcmp(substr, "Shared_Dirty")   == 0) { sizes.Shared_Dirty   += n; }
            else if (strcmp(substr, "Size")           == 0) { sizes.Size           += n; }
            else if (strcmp(substr, "Swap")           == 0) { sizes.Swap           += n; }
        }
    }
    fclose(file);

    HV* hash = newHV();
    (void)hv_store(hash, "KernelPageSize", strlen("KernelPageSize"), newSViv(sizes.KernelPageSize), 0);
    (void)hv_store(hash, "MMUPageSize",    strlen("MMUPageSize"),    newSViv(sizes.MMUPageSize),    0);
    (void)hv_store(hash, "Private_Clean",  strlen("Private_Clean"),  newSViv(sizes.Private_Clean),  0);
    (void)hv_store(hash, "Private_Dirty",  strlen("Private_Dirty"),  newSViv(sizes.Private_Dirty),  0);
    (void)hv_store(hash, "Pss",            strlen("Pss"),            newSViv(sizes.Pss),            0);
    (void)hv_store(hash, "Referenced",     strlen("Referenced"),     newSViv(sizes.Referenced),     0);
    (void)hv_store(hash, "Rss",            strlen("Rss"),            newSViv(sizes.Rss),            0);
    (void)hv_store(hash, "Shared_Clean",   strlen("Shared_Clean"),   newSViv(sizes.Shared_Clean),   0);
    (void)hv_store(hash, "Shared_Dirty",   strlen("Shared_Dirty"),   newSViv(sizes.Shared_Dirty),   0);
    (void)hv_store(hash, "Size",           strlen("Size"),           newSViv(sizes.Size),           0);
    (void)hv_store(hash, "Swap",           strlen("Swap"),           newSViv(sizes.Swap),           0);

    /* CPAN RT #78029 */
    sv_2mortal((SV*) hash);

    XPUSHs(newRV_noinc((SV*) hash));
