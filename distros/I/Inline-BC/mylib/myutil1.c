/* util.c: Utility routines for bc. */

/*  This file is part of GNU bc.
    Copyright (C) 1991-1994, 1997, 2000 Free Software Foundation, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License , or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; see the file COPYING.  If not, write to
      The Free Software Foundation, Inc.
      59 Temple Place, Suite 330
      Boston, MA 02111 USA

    You may contact the author by:
       e-mail:  philnelson@acm.org
      us-mail:  Philip A. Nelson
                Computer Science Department, 9062
                Western Washington University
                Bellingham, WA 98226-9062
       
*************************************************************************/

#include "bcdefs.h"
//#ifndef VARARGS
//#include <stdarg.h>
//#else
//#include <varargs.h>
//#endif
#include "global.h"
//#include "proto.h"

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "inlinebc.h"


SV* my_perl_parse_stash = NULL;


SV* my_perl_output = NULL;


/* generate code STR for the machine. */

void
generate (str)
      char *str;
{
  did_gen = TRUE;
  if (compile_only)
    {
      //printf ("%s",str);
      my_addto_parse_stash(str);
      //fprintf(stderr, " my GENERATE we got here 1: %s ...\n", str);
      out_count += strlen(str);
      if (out_count > 60)
	{
          my_addto_parse_stash("\n");
	  //printf ("\n");
	  out_count = 0;
	}
    }
  else
    load_code (str);
}


/* Initialize the code generator the parser. */

void
init_gen ()
{
  /* Get things ready. */
  break_label = 0;
  continue_label = 0;
  next_label  = 1;
  out_count = 2;
  if (compile_only) 
  {
    //printf ("@i");
    my_addto_parse_stash("@i");
  }
  else
    init_load ();
  had_error = FALSE;
  did_gen = FALSE;
}


/* Execute the current code as loaded. */

void
run_code()
{
  /* If no compile errors run the current code. */
  if (!had_error && did_gen)
    {
      if (compile_only)
	{
	  //printf ("@r\n"); 
          my_addto_parse_stash("@r\n");
      //fprintf(stderr, "we got here @r ...\n");
	  out_count = 0;
	}
      else
	execute ();
    }

  /* Reinitialize the code generation and machine. */
  if (did_gen)
    init_gen();
  else
    had_error = FALSE;
}


/* Output routines: Write a character CH to the standard output.
   It keeps track of the number of characters output and may
   break the output with a "\<cr>".  Always used for numbers. */

void
out_char (ch)
     int ch;
{
  //fprintf(stderr, "out_char: %c \n", ch);
  if (ch == '\n')
    {
      out_col = 0;
      //putchar ('\n');
      my_addto_output ('\n');
    }
  else
    {
      out_col++;
      if (out_col == line_size-1)
	{
	  //putchar ('\\');
	  my_addto_output ('\\');
	  //putchar ('\n');
	  my_addto_output ('\n');
	  out_col = 1;
	}
      //putchar (ch);
      my_addto_output (ch);
    }
}


void
my_init_parse_stash(void)
{
  //fprintf(stderr, "INITIALISE PARSE STASH...\n");
  if (my_perl_parse_stash == NULL){
    //fprintf(stderr, "CREATING A NEW STASH\n");
    my_perl_parse_stash = newSVpvn("",0);
  } else {
    sv_setpv(my_perl_parse_stash, "");
    //fprintf(stderr, "CURRENT INIT STASH: %s \n", SvPV(my_perl_parse_stash, SvCUR(my_perl_parse_stash)));
  }
}


void
my_init_output(void)
{
  //fprintf(stderr, "INITIALISE OUTPUT...\n");
  if (my_perl_output == NULL){
    //fprintf(stderr, "CREATING A NEW OUTPUT\n");
    my_perl_output = newSVpvn("",0);
  } else {
    sv_setpv(my_perl_output, "");
    //fprintf(stderr, "CURRENT INIT OUTPUT: %s \n", SvPV(my_perl_output, SvCUR(my_perl_output)));
  }
}


void
my_addto_parse_stash(char * str)
{
  //fprintf(stderr, "ADDTO PARSE STASH: %s ...\n", str);
  sv_catpv(my_perl_parse_stash, str);
  //fprintf(stderr, "STASH NOW: %s ...\n", SvPV(my_perl_parse_stash, SvCUR(my_perl_parse_stash)));
}


void
my_addto_output(char ch)
{
  sv_catpvf(my_perl_output, "%c", ch);
}


char *
my_current_stash(void)
{
  //fprintf(stderr, "CURRENT STASH: %s \n", SvPV(my_perl_parse_stash, SvCUR(my_perl_parse_stash)));
  return SvPV(my_perl_parse_stash, SvCUR(my_perl_parse_stash));
}


char *
my_current_output(void)
{
  return SvPV(my_perl_output, SvCUR(my_perl_output));
}
