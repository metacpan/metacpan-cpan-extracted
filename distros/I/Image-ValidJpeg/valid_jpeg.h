#ifndef VALID_JPEG_H_
#define VALID_JPEG_H_

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

enum vj_status_
  {
    GOOD_ = 0,
    BAD_,
    SHORT_,
    EXTRA_,
  };


int check_tail (PerlIO*);
int valid_jpeg (PerlIO*, unsigned char);
int check_jpeg (PerlIO*);
int check_all (PerlIO*);
int max_seek(int);
void set_valid_jpeg_debug(int);

#endif
