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

#ifndef LIBS_C
#define LIBS_C 1
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <math.h>

#include "libs.h"

/*
 * a more save malloc version
 */
void *
s_malloc (size_t size)
{
  void *temp_p;
  int temp_i;
  temp_i = errno;
  errno = 0;
  if ((temp_p = malloc (size)) == NULL)
    {
      s_error (NULL);
      return (NULL);
    }
  errno = temp_i;
  return temp_p;
}

/*
 * a more save realloc version
 */
void *
s_realloc (void *p, size_t size)
{
  void *temp_p;
  int temp_i;
  temp_i = errno;
  errno = 0;
  if ((temp_p = realloc (p, size)) == NULL)
    {
      s_error (NULL);
      return NULL;
    }
  errno = temp_i;
  return temp_p;
}


/*
 * for a more . like string feeling
 */
string *
s_strcat (string * dest, char *source)
{
  size_t size_dest, size_source;
  if (source == NULL)
    return dest;
  if (dest->value == NULL)
    {
      dest->size = 1;
      dest->memory = 0;
    }
  size_source = strlen (source);
  size_dest = size_source + dest->size;
  if (dest->memory < size_dest)
    {
      dest->memory += REALLOC_STRING * ((size_t)
					ceil ((double)
					      (size_dest -
					       dest->memory) /
					      REALLOC_STRING));
    }
  if (dest->value == NULL)
    {
      dest->value = s_malloc (dest->memory);
      strcpy (dest->value, source);
    }
  else
    {
      dest->value = s_realloc (dest->value, dest->memory);
      memcpy (dest->value + dest->size - 1, source, size_source + 1);
    }
  dest->size = size_dest;
  return dest;
}

/*
 * will free a string
 */
void
s_strfree (string * str)
{
  free (str->value);
  str->value = NULL;
  str->size = 0;
  str->memory = 0;
}


/*
 * error handling function
 */
void
s_error (char *msg)
{
  printf ("ERROR: %s\n", strerror (errno));
  if (msg != NULL)
    printf ("user message:%s\n", msg);
  exit (1);
}
