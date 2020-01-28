#/*-*- Mode: C++ -*-*/

MODULE = DiaColloDB::XS		PACKAGE = DiaColloDB::XS::CofUtils

##-- enable perl prototypes
PROTOTYPES: ENABLE

##--------------------------------------------------------------
## cof-gen.h
int
generatePairsTmpXS(char *ifile, char *ofile, size_t dmax)
 CODE:
  RETVAL = CofGenerator<>("DiaCollODB::XS::CofUtils::generatePairsTmpXS()").main(ifile,ofile,dmax);
 OUTPUT:
  RETVAL

##--------------------------------------------------------------
## cof-compile.h
int
loadTextFhXS32(FILE *infh, char *infilename, char *outbasename, size_t fmin)
 CODE:
  RETVAL = CofCompiler32::main("DiaCollODB::XS::CofUtils::loadTextFileXS32()", infh, infilename, outbasename, fmin);
 OUTPUT:
  RETVAL

int
loadTextFhXS64(FILE *infh, char *infilename, char *outbasename, size_t fmin)
 CODE:
  RETVAL = CofCompiler32::main("DiaCollODB::XS::CofUtils::loadTextFileXS64()", infh, infilename, outbasename, fmin);
 OUTPUT:
  RETVAL

