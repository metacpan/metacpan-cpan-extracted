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
 * MERCHNTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <wchar.h>

#include <NATools.h>

#include "unicode.h"

/**
 * @file
 * @brief Code file to parse corpora using UTF-8
 *
 * @todo Fix Documentation
 */

#include <locale.h>
#include <langinfo.h>

void init_locale(void) {
    setlocale(LC_CTYPE, "");
    if (strcmp(nl_langinfo(CODESET), "UTF-8")) {
        /* failed, try en_US.UTF-8 */
        setlocale(LC_CTYPE, "en_US.UTF-8");
        if (strcmp(nl_langinfo(CODESET), "UTF-8")) {
            fprintf(stderr, "Could not find an UTF-8 locale \n"
                    "(check LC_CTYPE env var, or the availability of en_US.UTF-8 locale)\n");
            exit(1);
        }
    }
}

static nat_boolean_t InWord(wchar_t ch)
{
    /* tokenising now by perl script */
    return (ch != L' ' && ch != L'\n' && ch != L'\t'); 
}

/**
 * @brief Searches begin of first word, skipping leading spaces, etc.
 *
 * @param text text to search
 * @param funct function to check if a char is from a word
 *
 * @return pointer to the beginning of the word on the text.
 */
static wchar_t *FirstTextWord(wchar_t *text, nat_boolean_t (*funct)(wchar_t))

{
    while (*text != L'\0' && !(*funct)(*text)) 	text++;

    if (*text == L'\0') return NULL;
    else                return text;
}

/**
 * @brief Searches begin of next word, marking the current word with a \0 character 
 *
 * @param text text to search
 * @param funct function to check if a char is from a word
 *
 * @return pointer to the beginning of the word on the text
 */
static wchar_t *NextTextWord(wchar_t *text, nat_boolean_t (*funct)(wchar_t))
{
    wchar_t* bow;
    bow = text;
    /* we are in the beginning of a word. Find its end! */
    while (*text != L'\0' && (*funct)(*text)) text++;

    /* if we end the buffer, return NULL */
    if (*text == L'\0') return NULL;

    /* Mark end of the current word */
    *text++ = L'\0';

    /* Search for the beginning of the next word */
    while (*text != L'\0' && !(*funct)(*text)) text++;

    /* if we end the buffer, return NULL */
    if (*text == L'\0') return NULL;
    else                return text;
}

/**
 * @brief ??
 *  
 * @param sen pointer to a buffer where the resulting sentence will be returned (list of words)
 * @param text pointer to a buffer where is the text to be searched
 * @param maxLen maximum size of the string
 * @param sd SoftDelimiter
 * @param hd HardDelimiter
 * @param funct function saying if a char is in a word, or not.
 */
static unsigned short NextTextString(wchar_t **sen, wchar_t **text,
                                     unsigned short maxLen,
				     wchar_t sd, wchar_t hd, nat_boolean_t (*funct)(wchar_t))
{
    wchar_t *word;
    unsigned short len = 0;

    if (*text != NULL) {
	word = FirstTextWord(*text, funct);
	while (word != NULL && *word != sd) {
	    if (len < maxLen) {
		if (*word != hd) sen[(len)++] = word;
	    } 
	    else { 
		len ++;                              /* DUMMY stat */
	    }
	    word = NextTextWord(word, funct);
	}
	if (word != NULL)
	    word = NextTextWord(word, funct);
	if (word != NULL && *word == hd)
	    word = NextTextWord(word, funct);
	*text = word;
    }
    return len;
}

/**
 * @brief Gets a sentence at a time
 *
 * @param sen  pointer to buffer where sentence will be returned;
 * @param text pointer to the text where to search;
 * @param maxLen maximum size of the Sentence;
 * @param sd SoftDelimiter
 * @param hd HardDelimiter
 */
unsigned short NextTextSentence(wchar_t **sen, wchar_t **text,
                                unsigned short maxLen, wchar_t sd, wchar_t hd)
{
    return NextTextString(sen, text, maxLen, sd, hd, InWord);
}

/**
 * @brief Reads all text from file to a text buffer
 *
 * @param filename Filename of the text file to be read
 * @return A big null-terminated buffer with the text file
 */
wchar_t *ReadText(const char *filename)
{
    FILE *fd;
    long len;
    struct stat stat_buf;
    wchar_t *result;
    wchar_t *pos;
    
    fd = fopen(filename, "r");
    if (fd == NULL) {
        fprintf(stderr, "failed opening file\n");
        return NULL;
    }
    if (fstat(fileno(fd), &stat_buf) == -1) {
        fprintf(stderr, "failed stating file\n");
        return NULL;
    }

    len = stat_buf.st_size;
    result = (wchar_t*)malloc(sizeof(wchar_t) * (len+1));
    pos = result;
    if (result == NULL) {
        fprintf(stderr, "could not allocate buffer\n");
        return NULL;
    }

    while (!feof(fd)) {
        wchar_t c = fgetwc(fd);
        if (!feof(fd)) *pos = c;
        pos++;
    }

    if (fclose(fd)) {
        fprintf(stderr, "problem closing filehandle\n");
        return NULL;
    }
    *pos = '\0';

    return result;
}

/* Nat_string */

nat_string_t *nat_string_new() {
    nat_string_t *string;

    string = g_new(nat_string_t, 1);
    string->str = g_new(wchar_t, NAT_STRING_START_SIZE);
    string->buffer_size = NAT_STRING_START_SIZE;
    string->length = 0;

    return string;
}

void nat_string_free(nat_string_t *str) {
    if (str) {
        if (str->str) g_free(str->str);
        g_free(str);
    }
}

nat_string_t*  nat_string_append(nat_string_t *str, const wchar_t *format, ...) {
    va_list args;
    va_start(args, format);
    int r;
    do {
        r = vswprintf(str->str + str->length, str->buffer_size - str->length - 1,
                      format, args);
        if (r <= 0) {
            str->buffer_size += NAT_STRING_INCREMENT;
            str->str = (wchar_t*) g_realloc(str->str, sizeof(wchar_t) * str->buffer_size);
            if (!str->str) report_error("No mem?!?!?");
        }
    } while (r<=0);
    str->length += r;
    str->str[str->length] = L'\0';
    return str;
}

#ifdef MISSES_WCSDUP
wchar_t *wcs_dup(const wchar_t *wstr) {
    wchar_t *mem;
    mem = (wchar_t*) calloc(wcslen(wstr) + 1, sizeof(wchar_t));
    if (!mem)
        report_error("error allocating memory");
    wcscpy(mem, wstr);
    return mem;
}
#else
wchar_t *wcs_dup(const wchar_t *wstr) { return wcsdup(wstr); }
#endif
