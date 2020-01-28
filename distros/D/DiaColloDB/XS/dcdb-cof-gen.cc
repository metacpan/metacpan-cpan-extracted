//-*- Mode: C++ -*-
#include "cof-gen.h"

//======================================================================
// globals
const char *prog = "dcdb-cof-gen";
const char *ifile = "-";
const char *ofile = "-";
size_t dmax = DMAX_DEFAULT;

//======================================================================
int main(int argc, const char **argv)
{
    //-- t2c_init
    prog = *argv;
    if (argc < 2 || strcmp(argv[1],"-h")==0 || strcmp(argv[1],"--help")==0) {
        fprintf(stderr, "Usage: %s DMAX INFILE [OUTFILE=-]\n", prog);
        exit(1);
    }
    dmax = strtoul(argv[1], NULL,0);
    if (argc > 2) ifile = argv[2];
    if (argc > 3) ofile = argv[3];

    return CofGenerator<>(prog).main(ifile,ofile,dmax);
}
