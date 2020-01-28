//-*- Mode: C++ -*-
#include "cof-compile.h"

#ifndef DIACOLLO_COF2BIN_BITS
# define DIACOLLO_COF2BIN_BITS 32
#endif

//======================================================================
// bit-width dispatch
#if DIACOLLO_COF2BIN_BITS == 32
typedef CofCompiler32 MyCofCompiler;
#elif DIACOLLO_COF2BIN_BITS == 64
typedef CofCompiler64 MyCofCompiler;
#else
# error unsupported value for DIACOLLO_COF2BIN_BITS
typedef CofCompiler32 MyCofCompiler;
#endif


#define stringify(x) #x

//======================================================================
// globals
const char *prog = "dcdb-cofgen" stringify(DIACOLLO_COF2BIN_BITS);
const char *infile = NULL;
const char *outbase = NULL;
size_t fmin = 2;

//======================================================================
int main(int argc, const char **argv)
{
    //-- c2b_init
    prog = *argv;
    for (int argi=1; argi < argc; ++argi) {
        string arg(argv[argi]);
        if (arg == "-h" || arg == "-help" || arg == "--help") {
            fprintf(stderr,
                    "\n"
                    "Usage: %s [OPTIONS] [INFILE.dat=- [OUTBASE=cof.d/cof]]\n"
                    "\n"
                    "Options:\n"
                    "  -h, -help       # this help message\n"
                    "  -f, -fmin FMIN  # minimum co-occurrence frequency (default=%zd)\n"
                    "\n",
                    prog, fmin);
            exit(1);
        }
        else if (arg == "-f" || arg == "-cfmin" || arg == "-fmin") {
            fmin = strtoul(argv[argi+1], NULL, 0);
            ++argi;
        }
        else if (arg[0] != '-') {
            if (infile == NULL) {
                infile = argv[argi];
            } else if (outbase == NULL) {
                outbase = argv[argi];
            } else {
                fprintf(stderr, "%s WARNING: unhandled non-option argument '%s'", prog, argv[argi]);
            }
        }
        else {
            fprintf(stderr, "%s WARNING: unknown argument '%s'", prog, argv[argi]);
        }
    }

    //-- guts
    MyCofCompiler::main(prog, infile, outbase, fmin);

    return 0;
}
