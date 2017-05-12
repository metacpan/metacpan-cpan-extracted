/*   
		libs - An allocation library
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

#ifndef LIBS_H
#define LIBS_H 1

#define REALLOC_STRING 256

typedef struct
{
  char *value;
  int memory;
  int size;
}
string;

#ifndef LIBS_P_C

void *s_malloc (size_t size);
void *s_realloc (void *p, size_t size);
string *s_strcat (string * dest, char *source);
void s_strfree (string * str);
void s_error (char *msg);
void s_free (void *ptr);

/*macro for compatibility with libs_p*/
#define s_free(ptr) \
free(ptr)

#else

#ifndef MEM_TRACK_FILE
#define MEM_TRACK_FILE "mem.txt"
#endif

#define s_malloc(size) \
s_malloc_p(size, __LINE__, __FILE__)

#define s_realloc(p, size) \
s_realloc_p(p, size, __LINE__, __FILE__)

#define s_strcat(dest, source) \
s_strcat_p(dest, source, __LINE__, __FILE__)

#define s_strfree(str) \
s_strfree_p(str, __LINE__, __FILE__)

#define s_error(msg) \
s_error_p(msg, __LINE__, __FILE__)

#define s_free(ptr) \
s_free_p(ptr, __LINE__, __FILE__)


void *s_malloc_p (size_t size, int line, char *file);
void *s_realloc_p (void *p, size_t size, int line, char *file);
string *s_strcat_p (string * dest, char *source, int line, char *file);
void s_strfree_p (string * str, int line, char *file);
void s_error_p (char *msg, int line, char *file);
void s_free_p (void *ptr, int line, char *file);

#endif

#endif
