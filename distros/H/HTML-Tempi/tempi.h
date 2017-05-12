/*   
		Tempi - A HTML Template system
    Copyright (C) 2002  Roger Faust <roger_faust@bluewin.ch>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
		
*/

#ifndef TEMPI_H
#define TEMPI_H 1

#include "tempi_pub.h"

#define ECHO get_flex_output()

#define MAIN_BLOCK_NAME "MAIN"

#define MAX_FILE_DEP 8
#define MAX_BLOCK_DEP 10
#define REALLOC_STRING_BIG 1024

#define ERROR_DURING_PARSING 99 

typedef struct _block
{
  char *name;
  char *value;
  bool is_var;
  bool is_last;
  struct _block *next;
}
block;

struct
{
  FILE *files[MAX_FILE_DEP];
  int open;
}
files;

struct
{
  YY_BUFFER_STATE buffers[MAX_FILE_DEP];
  int open;
}
buffers;

void get_flex_output (void);
void add_block_value (char *value);
void add_block_name (char *name);
void make_out_struct (void);
void free_memory_rest (void);

#endif
