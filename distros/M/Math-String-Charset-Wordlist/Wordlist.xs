#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>

/*

  Math::String::Charset::Wordlist XS code
  (C) 2003-2004 by Tels <http://bloodgate.com/perl/>

  Provide routines that let us get the offsets and records from a file
  containing a list of words (one word on each line)

*/

struct Offsets
  {
  /* offsets into the file, for each line one*/
  long* record_offsets;

  /* how many do we have? */
  long max_offsets;

  /* how many slots for offsets to we have allocated in record_offsets? */
  long cur_size;

  /* set to 1 when we saw the EOF */
  unsigned int eof;

  /* the wordlist file */
  FILE* file;
  };

/* if buffer below grows bigger than 8192 bytes, adapt test in testsuite! */
#define READ_BUFFER_SIZE 8 * 1024

#define BUFFER_SIZE 8192

MODULE = Math::String::Charset::Wordlist PACKAGE = Math::String::Charset::Wordlist

PROTOTYPES: ENABLE

 #############################################################################
 # 2003-04-26 0.01 Tels
 #   * first try
 # 2003-04-27 0.02 Tels
 #   * _offset(): return undef on negative indices
 #   * removed unused global variables (esp. 8K buffer)
 #   * _file(): read block-wise

##############################################################################
# _file() - set the filename (open the file, ed all the offsets, close it)
# return number of records on success, undef on failure

void
_file(n)
  SV*	n
  INIT:
	int c;
	long i;
	int len;
	unsigned char *name;
	struct Offsets* offset;
	long buffer[BUFFER_SIZE];
	unsigned char read_buffer[READ_BUFFER_SIZE];
	long buffered, idx, base, ofs;
        size_t read;

  PPCODE:
    name = SvPVX(n);				/* get ptr to storage */

    len = sizeof (struct Offsets);
    ST(0) = newSV(len);		/* alloc enough to store one ptr */
    SvPOK_on(ST(0));
    offset = (struct Offsets*) SvPVX(ST(0));	/* get ptr to storage */
    SvCUR_set(ST(0), len);		/* and set real length */

    offset->file = fopen( name, "r");
    if (offset->file == NULL)
      {
      printf ("Cannot open file %s\n", SvPV_nolen(n));
      ST(0) = &PL_sv_undef;
      XSRETURN(1);
      }
    /* printf ("Opening %s\n", name); */

    offset->eof = 1;
    offset->max_offsets = 0;
    New( 42, offset->record_offsets, BUFFER_SIZE, long);

    /* printf ("size of one offset: %i\n",sizeof(long)); */

    offset->cur_size = BUFFER_SIZE;
    buffered = 0;
    ofs = 0;					/* 0 for first record */
    base = 0;					/* 0 for first block */
    read = fread(
      read_buffer, sizeof(unsigned char), READ_BUFFER_SIZE, offset->file);
    idx = 0;
    while (read != 0)
      {
      c = read_buffer[idx]; idx++;
      # line end?
      if (c == 0x0a)
        {
        buffer[buffered++] = ofs + base; ofs = idx;
        if (buffered >= BUFFER_SIZE)
          {
          if (offset->max_offsets + buffered > offset->cur_size)
            {
            Renew( offset->record_offsets, offset->cur_size + buffered, long);
            offset->cur_size += buffered;
            }
	  /* copy over the buffered records to our offset storage */
          for (i = 0; i < buffered; i++)
	    {
            offset->record_offsets[offset->max_offsets++] = buffer[i];
	    }
          buffered = 0;
          }
        }
      if (idx == read)
        {
        read = fread(
          read_buffer, sizeof(unsigned char), READ_BUFFER_SIZE, offset->file);
        base += idx; ofs -= idx; idx = 0;
        }
      }
    if (buffered != 0)
      {
      if (offset->max_offsets + buffered > offset->cur_size)
        {
        Renew( offset->record_offsets, offset->cur_size + buffered, long);
        offset->cur_size += buffered;
        }

      /* copy over the buffered records to our offset storage */
      for (i = 0; i < buffered; i++)
        {
        offset->record_offsets[offset->max_offsets++] = buffer[i];
        }
      }
    if (c != 0x0a)
      {
      /* TODO: last character in file was not line end, so we missed the last
         record */
      }

    XSRETURN(1);

void
_free(ptr)
  SV* ptr
  INIT:
	struct Offsets* offset;
  CODE:
    offset = (struct Offsets*) SvPVX(ptr);	/* get ptr to storage */
    if (offset != NULL)
      {
      fclose(offset->file);
      Safefree(offset->record_offsets);
      }

##############################################################################
# _records(ptr,n), return the number of records

void
_records(ptr)
  SV*	ptr

  INIT:
	struct Offsets* offset;
  PPCODE:
    offset = (struct Offsets*) SvPVX(ptr);	/* get ptr to storage */
    ST(0) = sv_2mortal( newSVnv( offset->max_offsets ));
    XSRETURN(1);

##############################################################################
# _offset(n), return the offset for record n. If the offset was not yet read,
# and we did not see the EOF yet, read all ofsets until n. Returns either
# the offset, or undef for "record does not exists" (e.g. file has fewer
# records than n).

void
_offset(ptr,n)
  SV*	ptr
  SV*	n
  INIT:
	long N;
	struct Offsets* offset;
  PPCODE:
    N = SvNV(n);

    offset = (struct Offsets*) SvPVX(ptr);	/* get ptr to storage */

    /* offset exists? */
    if (N >= 0 && N < offset->max_offsets)
      {
      ST(0) = sv_2mortal( newSVnv( offset->record_offsets[N] ));
      }
    else
      {
      /* offset for record N does not exist, and file read completely */
      ST(0) = &PL_sv_undef;
      }
    XSRETURN(1);

##############################################################################
# _record(n), return the record number N

void
_record(ptr,n)
  SV*	ptr
  SV*	n

  INIT:
	unsigned int N;
	unsigned int ofs,len;
	char* buf;
	struct Offsets* offset;

  PPCODE:
    N = (int)SvNV(n);

    offset = (struct Offsets*) SvPVX(ptr);	/* get ptr to storage */

    if (offset == NULL)
      {
      printf ("Offset is empty!");
      ST(0) = &PL_sv_undef;
      XSRETURN(1);
      }
    //printf ("Fetching record %i (%p)\n",N,offset);

    if (N >= offset->max_offsets)
      {
      # offset (and thus record) does not exist
      ST(0) = &PL_sv_undef;
      XSRETURN(1);
      }
    ofs = offset->record_offsets[N];

    //printf ("Offset is %i\n",ofs);

    /* seek to the position */
    fseek (offset->file, ofs, SEEK_SET);

    ST(0) = sv_2mortal(newSV(READ_BUFFER_SIZE)); /* alloc scratch buffer */
    SvPOK_on(ST(0));

    buf = SvPVX(ST(0));				 /* get ptr to storage */
    //printf ("Buffer %p\n",buf);

    fgets(buf, READ_BUFFER_SIZE, offset->file);	 /* read in the record */
    len = strlen(buf);
    if (len > 0 && buf[len-1] == 0x0a)
      {
      len--;				/* kill the 0x0a character at end */
      buf[len] = 0;
      }
    if (len > 0 && buf[len-1] == 0x0d)
      {
      len--;				/* kill the 0x0d character at end */
      buf[len] = 0;
      }

    SvCUR_set(ST(0), len);		/* and set real length */
    XSRETURN(1);
