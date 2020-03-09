/* Copyright 2014 Kevin Ryde

   This file is part of I18N-Langinfo-Wide.

   I18N-Langinfo-Wide is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by the
   Free Software Foundation; either version 3, or (at your option) any later
   version.

   I18N-Langinfo-Wide is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License along
   with I18N-Langinfo-Wide.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdio.h>
#include <stdlib.h>
#include <locale.h>
#include <langinfo.h>

int
main (void)
{

  char *s;
  int i;
  const char *locale = "ja_JP.UTF8";

  if (setlocale (LC_ALL, locale) == NULL) {
    printf ("no locale %s\n", locale);
    exit (1);
  }

  s = nl_langinfo (ALT_DIGITS);
  /* printf ("ALT_DIGITS `%s'\n", s); */

  for (i = 0; i < 12; i++) {
    printf (" %02X", (int) (unsigned char) s[i]);
  }
  printf ("\n");

  return 0;
}
