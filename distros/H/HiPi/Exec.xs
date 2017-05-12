///////////////////////////////////////////////////////////////////////////////////////
// File          Exec.xs
// Description:  XS module for HiPi::Utils::Exec
// Copyright:    Copyright (c) 2013-2017 Mark Dootson
// License:      This is free software; you can redistribute it and/or modify it under
//               the same terms as the Perl 5 programming language system itself.
///////////////////////////////////////////////////////////////////////////////////////

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_nolen
#include "mylib/include/ppport.h"

#include "zlib.h"

MODULE=HiPi::Utils::Exec PACKAGE=HiPi::Utils::Exec

PROTOTYPES:  DISABLE

void
_compress_buffer(SV* inputsv)
  PPCODE:
    unsigned char* outputbuffer;
    SV* output = sv_newmortal();
    unsigned inputsize = SvCUR(inputsv);
    unsigned char* inputbuffer = (unsigned char *)SvPVX(inputsv);
    unsigned outputsize = inputsize + (inputsize * 0.1) + 12;
    
   /* allocate the output buffers */
    SvUPGRADE(output, SVt_PV);
    outputbuffer = (unsigned char *)SvGROW(output, outputsize + sizeof(unsigned char) );
    
   /* do the compression */
    uLongf compressedsize = (uLongf)(outputsize + sizeof(unsigned char));
    compress((Bytef*)outputbuffer, (uLongf*)&compressedsize,(const Bytef*)inputbuffer, (uLongf)inputsize);
    
   /* fixup output */
    SvCUR_set(output, compressedsize);
    *SvEND(output) = '\0';
    (void) SvPOK_only(output);
    
  /* return SVs */
    EXTEND(SP, 2);
    PUSHs(output);
    PUSHs(sv_2mortal(newSViv(inputsize)));
    PUSHs(sv_2mortal(newSViv(compressedsize)));
  

void
_decompress_buffer(SV* inputsv, unsigned outputsize)
  PPCODE:
    unsigned char* outputbuffer;
    SV* output = sv_newmortal();
    unsigned inputsize = SvCUR(inputsv);
    unsigned char* inputbuffer = (unsigned char *)SvPVX(inputsv);
    
  /* allocate the output buffers */
    SvUPGRADE(output, SVt_PV);
    outputbuffer = (unsigned char *)SvGROW(output, outputsize + sizeof(unsigned char) );
    
  /* do the decompression */
    uLongf uncompressedsize = (uLongf)outputsize;
    uncompress((Bytef*)outputbuffer, &uncompressedsize, (const Bytef*)inputbuffer, (uLongf)inputsize);
    
   /* fixup output */
    SvCUR_set(output, outputsize);
    *SvEND(output) = '\0';
    (void) SvPOK_only(output);
    
  /* return SVs */
    EXTEND(SP, 1);
    PUSHs(output);

