/*
 * mplib - a library that enables you to edit ID3 tags
 * Copyright (C) 2001,2002  Stefan Podkowinski
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; version 2.1.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#if STDC_HEADERS
# include <stdlib.h>
# include <string.h>
#elif HAVE_STRINGS_H
# include <strings.h>
#endif /*STDC_HEADERS*/

#if HAVE_UNISTD_H
# include <unistd.h>
# include <sys/types.h>
#endif

#include <errno.h>
#include <stdio.h>
#include <fcntl.h>

#include "mplib.h"
#include "xmalloc.h"



/*******************************************************************************************
 *                                    Parse functions
 *******************************************************************************************/
 
 id3_text_content*
 mp_parse_artist(const id3_content* content)
 {
	 return mp_parse_text(content);
 }
 
 id3_text_content*
 mp_parse_title(const id3_content* content)
 {
	 return mp_parse_text(content);
 }
 
 id3_text_content*
 mp_parse_album(const id3_content* content)
 {
	 return mp_parse_text(content);
 }
 
 id3_text_content*
 mp_parse_year(const id3_content* content)
 {
	 return mp_parse_text(content);
 }
 
 id3_text_content*
 mp_parse_genre(const id3_content* content)
 {
	 return mp_parse_text(content);
 }
 
 id3_text_content*
 mp_parse_track(const id3_content* content)
 {
	 return mp_parse_text(content);
 }
 
 id3_comment_content*
 mp_parse_comment(const id3_content* content)
 {
	 id3_comment_content* cc;
	 int i, e;
	 
	 if(!content || !content->data)
	 {
		 errno = MP_EERROR;
		 return NULL;
	 }
	 
	 if(content->encrypted)
	 {
		 errno = MP_EFENCR;
		 return NULL;
	 }
	 if(content->compressed)
	 {
		 errno = MP_EFCOMPR;
		 return NULL;
	 }
	 
	 cc = XMALLOCD0(id3_comment_content, "mp_parse_comment:cc");
	 
	 e = content->data[0];
	 if(e >= ISO_8859_1 && e <= UTF8) cc->encoding = e;
	 else cc->encoding = 0;
	 
	 cc->language = xmallocd(4, "mp_parse_comment:cc->language");
	 cc->language[0] = content->data[1];
	 cc->language[1] = content->data[2];
	 cc->language[2] = content->data[3];
	 cc->language[3] = 0;
	 
	 if(content->data[4]) /* short descr. */
	 {
		 i = strlen(content->data + 4) + 1;
		 cc->short_descr = xmallocd(i, "mp_parse_comment:cc->short_descr");
		 strncpy(cc->short_descr, content->data + 4, i);
	 }
	 else
	 {
		 cc->short_descr = NULL;
		 i = 1;
	 }
	 
	 cc->text = xmallocd(content->length - 4 - i + 1, "mp_parse_comment:cc->text");
	 memcpy(cc->text, content->data + 4 + i, content->length - 4 - i);
	 cc->text[content->length - 4 - i] = 0;
	 
	 return cc;
 }
 
id3_wxxx_content*
mp_parse_wxxx(const id3_content* content)
{
    id3_wxxx_content* wx;
    int e;
    int deslen, urlen;
    
    if (!content || !content->data)
    {
        errno = MP_EERROR;
        return NULL;
    }

    if(content->encrypted)
    {
        errno = MP_EFENCR;
        return NULL;
    }
    if(content->compressed)
    {
        errno = MP_EFCOMPR;
        return NULL;
    }

    wx = XMALLOCD0(id3_wxxx_content, "mp_parse_wxxx:wx");
    e = content->data[0];
    if(e >= ISO_8859_1 && e <= UTF8) 
        wx->encoding = e;
    else 
        wx->encoding = 0;
    
    deslen = strlen(content->data + 1) + 1;
    wx->description = xmallocd(deslen, "mp_parse_wxxx:wx->description");
    strncpy(wx->description, content->data + 1, deslen);
    wx->description[deslen - 1] = 0;

    /* urlen = content->length - length(enc) - length(description) + \000*/
    urlen = content->length - 1 - deslen + 1;
    wx->url = xmalloc(urlen);
    strncpy(wx->url, content->data + 1 + deslen, urlen);
    wx->url[urlen-1] = 0;
    
    return wx;
}

 id3_text_content*
 mp_parse_text(const id3_content* content)
 {
	 id3_text_content* tc;
	 int e;
	 
	 if(!content || !content->data)
	 {
		 errno = MP_EERROR;
		 return NULL;
	 }
	 
	 if(content->encrypted)
	 {
		 errno = MP_EFENCR;
		 return NULL;
	 }
	 if(content->compressed)
	 {
		 errno = MP_EFCOMPR;
		 return NULL;
	 }
	 
	 tc = XMALLOCD0(id3_text_content, "mp_parse_text:tc");
	 tc->text = xmallocd(content->length, "mp_parse_text:tc->text");
	 e = content->data[0];
	 if(e >= ISO_8859_1 && e <= UTF8) tc->encoding = e;
	 else tc->encoding = 0;
	 
	 memcpy(tc->text, content->data + 1, content->length - 1);
	 tc->text[content->length - 1] = 0;
	 /* XXX multiple entries */
	 return tc;
 }
 
 /*******************************************************************************************
 *                                    Assemble functions
 *******************************************************************************************/
 
 id3_content*
 mp_assemble_artist_content(const char* text, id3_encoding enc)
 {
	 return mp_assemble_text_content(text, enc);
 }
 
 id3_content*
 mp_assemble_title_content(const char* text, id3_encoding enc)
 {
	 return mp_assemble_text_content(text, enc);
 }
 
 id3_content*
 mp_assemble_album_content(const char* text, id3_encoding enc)
 {
	 return mp_assemble_text_content(text, enc);
 }
 
 id3_content*
 mp_assemble_year_content(const char* text, id3_encoding enc)
 {
	 return mp_assemble_text_content(text, enc);
 }
 
 id3_content*
 mp_assemble_genre_content(const char* text, id3_encoding enc)
 {
	 return mp_assemble_text_content(text, enc);
 }
 
 id3_content*
 mp_assemble_text_content(const char* text, id3_encoding enc)
 {
	 id3_content *ret;
	 
	 if(!text) return NULL;
	 
	 ret = XMALLOCD0(id3_content, "mp_assemble_text_content:ret");
	 ret->length = strlen(text) + 1;
	 ret->data = xmallocd(ret->length, "mp_asseble_text_content:ret->data");
	 ret->data[0] = enc;
	 strncpy(ret->data + 1, text, strlen(text));
	 
	 return ret;
 }
 
 id3_content*
 mp_assemble_comment_content(const char* text, const char* short_descr, id3_encoding enc, const char* lang)
 {
	 id3_content *ret;
	 
	 if(!text) return NULL;
	 
	 ret = XMALLOCD0(id3_content, "mp_assemble_comment_content:ret");
	 ret->length = strlen(text) + 5;
	 if(short_descr) ret->length += strlen(short_descr);
	 
	 ret->data = xmallocd(ret->length, "mp_assemble_comment_content:ret->data");
	 ret->data[0] = enc;
	 if(lang && strlen(lang) == 3)
	 {
		 ret->data[1] = lang[0];
		 ret->data[2] = lang[1];
		 ret->data[3] = lang[2];
	 }
	 else
	 {
		 ret->data[1] = 'X';
		 ret->data[2] = 'X';
		 ret->data[3] = 'X';
	 }
	 if(short_descr) strcpy(ret->data + 4, short_descr);
	 else ret->data[4] = 0;
	 
	 if(short_descr) strncpy(ret->data + 5 + strlen(short_descr), text, strlen(text));
	 else strncpy(ret->data + 5, text, strlen(text));
	 
	 return ret;
	 
 }

id3_content*
mp_assemble_wxxx_content(const char* url, const char* description, 
                         id3_encoding enc) {

    id3_content *ret; 
    if (!url)
        return NULL;
   
    ret = XMALLOCD0(id3_content, "mp_assemble_wxxx_content:ret");
    ret->length = strlen(url) + 2;
    if (description) 
        ret->length += strlen(description) + 1;
    
    ret->data = xmallocd(ret->length, "mp_assemble_wxxx_content:ret->data");

    ret->data[0] = enc;
    if(description) 
        strcpy(ret->data + 1, description);
    else 
        ret->data[1] = 0;
    strcpy(ret->data + 2 + strlen(description), url);
    return ret;
}
