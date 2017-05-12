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

#ifndef TEMPI_VARS_H
#define TEMPI_VARS_H 1

/*Note: this structs are declared in tempi.h:
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
*/

bool init_run = false, init_done = false, free_memory_done = false;
block fblock, *ablock;
string temp_string, flex_output, block_names[MAX_BLOCK_DEP], a_file, *out,
  parst;
YY_BUFFER_STATE temp_buffer;
int block_counter, _yyi, line_counter, block_counter_real;
FILE *track_file = NULL;

#endif
