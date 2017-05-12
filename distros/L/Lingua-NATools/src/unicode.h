/* NATools - Package with parallel corpora tools
 * Copyright (C) 1998-2001  Djoerd Hiemstra
 * Copyright (C) 2002-2012  Alberto Simões
 *
 * This package is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#ifndef __UNICODE_H__
#define __UNICODE_H__ 1

/**
 * @file
 * @brief Header file for unicode-aware methods
 */

wchar_t *wcs_dup(const wchar_t *string);

/* ------ Strings ------- */

#define NAT_STRING_START_SIZE 100
#define NAT_STRING_INCREMENT  50

typedef struct _nat_string {
    wchar_t *str;
    int buffer_size;
    int length;
} nat_string, nat_string_t;

nat_string_t*  nat_string_new();
nat_string_t*  nat_string_append(nat_string_t *str, const wchar_t *format, ...);
void           nat_string_free(nat_string_t *str);

//

wchar_t*       ReadText(const char *filename);
unsigned short NextTextSentence(wchar_t **sen, wchar_t **text,
                                unsigned short maxLen,
                                wchar_t sd, wchar_t hd);
void           init_locale(void);

#endif /* __UNICODE_H__ */
