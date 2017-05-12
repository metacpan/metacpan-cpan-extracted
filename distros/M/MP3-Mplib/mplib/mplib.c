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

#include "xmalloc.h"
#include "mplib.h"
#include "mplib_s.h"
#include "mplib_s.c"



/*******************************************************************************************
 *                                   Extern functions
 *******************************************************************************************/



/*******************************************************************************************
 *                                         Get
 *******************************************************************************************/

 mpeg_header*
 mp_get_mpeg_header_from_file(const char* filename)
 {
	 mpeg_header *ret;
	 int fd;
	 
	 if(!filename) return NULL;
	 
	 fd = open(filename, O_RDONLY);
	 if(fd == -1) return NULL;
	 
	 ret = mp_get_mpeg_header_from_fd(fd);
	 close(fd);
	 return ret;
 }
 

mpeg_header*
mp_get_mpeg_header_from_fd(int fd)
{
	mpeg_header *h;
	unsigned char c[5];
	
	h = XMALLOCD(mpeg_header, "mp_get_mpeg_header_from_fd:h");
	
	if(id3_lseek_syncword(fd)) goto exit_on_error;
	
	if(read(fd, c, 4) < 4) goto exit_on_error;
	
	memset(h, 0, sizeof(h));
	h->syncword = (c[1] & 240);
	h->syncword <<= 8;
	h->syncword |= c[0]; 
	h->version = (c[1] & 8) >> 3;
	h->layer = (c[1] & 6) >> 1;
	h->protbit = (c[1] & 1);
	h->bitrate = (c[2] & 240) >> 4;
	h->samplingfreq = (c[2] & 12) >> 2;
	h->padbit = (c[2] & 2) >> 1;
	h->privbit = (c[2] & 1);
	h->mode = (c[3] & 192) >> 6;
	h->mode_ext = (c[3] & 48) >> 4;
	h->copyright = (c[3] & 8) >> 3;
	h->originalhome = (c[3] & 4) >> 2;
	h->emphasis = (c[3] & 3);
	
	return h;

 exit_on_error:
	xfree(h);
	return NULL;
}

char*
mp_get_str_version(const mpeg_header *h) 
{
	return h->version == 0 ? "MPEG 2" : "MPEG 1";
}

char* 
mp_get_str_layer(const mpeg_header *h) 
{
	switch(h->layer) 
	{
		case 1: return "Layer III";
		case 2: return "Layer II";
		case 3: return "Layer I";
		default: return "undefined";
	}
}

char*
mp_get_str_bitrate(const mpeg_header *h) 
{
	char *buf = (char *)xmallocd0(11, "mp_get_str_bitrate:buf");
	
	if(h->version == 1) /* MPEG 1 */
	{ 
		switch(h->layer) 
		{
			case 1:
				snprintf(buf, sizeof buf, "%d kBit/s", br_1_3[h->bitrate]);
				return buf;
			case 2:
				snprintf(buf, sizeof buf, "%d kBit/s", br_1_2[h->bitrate]);
				return buf;
			case 3:
				snprintf(buf, sizeof buf, "%d kBit/s", br_1_1[h->bitrate]);
				return buf;
			default:
				return "undefined";
		}
	} 
	else /* MPEG 2 */
	{ 
		switch(h->layer) 
		{
			case 1:
				snprintf(buf, sizeof buf, "%d kBit/s", br_2_3[h->bitrate]);
				return buf;
			case 2:
				snprintf(buf, sizeof buf, "%d kBit/s", br_2_2[h->bitrate]);
				return buf;
			case 3:
				snprintf(buf, sizeof buf, "%d kBit/s", br_2_1[h->bitrate]);
				return buf;
			default:
				return "undefined";
		}
	}
}

char*
mp_get_str_samplingfreq(const mpeg_header *h) 
{
	if(h->version == 1) 
	{
		switch(h->samplingfreq) 
		{
			case 0: return "44100 Hz";
			case 1: return "48000 Hz";
			case 2: return "32000 Hz";
			default: return "undefined";
		}
	} 
	else 
	{
		switch(h->samplingfreq) 
		{
			case 0: return "22050 Hz";
			case 1: return "24000 Hz";
			case 2: return "16000 Hz";
			default: return "undefined";
		}
	}
}

char*
mp_get_str_mode(const mpeg_header *h) 
{
	switch(h->mode) 
	{
		case 0: return "Stereo";
		case 1: return "Joint-Stereo";
		case 2: return "Dual-Channel";
		case 3: return "Mono";
		default: return "undefined";
	}
}

id3_tag_list* 
mp_get_tag_list_from_file(const char* filename)
{
	id3_tag_list *ret;
	int fd;
	
	if(!filename) return NULL;
	
	fd = open(filename, O_RDONLY);
	if(fd == -1) return NULL;
	
	ret = mp_get_tag_list_from_fd(fd);
	close(fd);
	return ret;
}

id3_tag_list* 
mp_get_tag_list_from_fd(int fd)
{
	id3_tag_list *tag_list = NULL;
	id3_tag_list *tag_list2 = NULL;
	id3v2_tag *v2tag = NULL;
	id3v1_tag *v1tag = NULL;
	id3_tag *tag = NULL;
	
	v2tag = id3v2_get_tag(fd);
	if(v2tag)
	{
		tag = XMALLOCD0(id3_tag, "mp_get_tag_list_from_fd:tag");
		if(v2tag->header->version_minor == 3 || v2tag->header->version_minor == 4)
			tag->version = 2;
		else
			tag->version = -1;
		tag->tag = v2tag;
			
		tag_list = XMALLOCD(id3_tag_list, "mp_get_tag_list_from_fd:tag_list");
		tag_list->tag = tag;
		tag_list->next = NULL;
		tag_list->first = tag_list;
	}
	
	v1tag = id3v1_get_tag(fd);
	if(v1tag)
	{
		tag = XMALLOCD(id3_tag, "mp_get_tag_list_from_fd:tag");
		tag->version = 1;
		tag->tag = v1tag;
		
		if(tag_list)
		{
			tag_list2 = XMALLOCD(id3_tag_list, "mp_get_tag_list_from_fd:tag_list2");
			tag_list2->tag = tag;
			tag_list2->next = NULL;
			tag_list2->first = tag_list;
			tag_list->next = tag_list2;
		}
		else
		{
			tag_list = XMALLOCD(id3_tag_list, "mp_get_tag_list_from_fd:tag_list");
			tag_list->tag = tag;
			tag_list->next = NULL;
			tag_list->first = tag_list;
		}
	}
	
	return tag_list;
}

id3_content*
mp_get_content(const id3_tag *tag, int field)
{
	return mp_get_content_at_pos(tag, field, 0);
}

id3_content*
mp_get_content_at_pos(const id3_tag *tag, int field, int pos)
{
	int i;
	char *c;
	id3_content *ret;
	
	if(!tag || !tag->tag)
	{
		errno = MP_EERROR;
		return NULL;
	}
	
	if(tag->version == 1)
	{
		if(pos != 0)
		{
			errno = MP_EERROR;
			return NULL; 
		}
		else return id3v1_get_content(tag->tag, field);
	}
	else if(tag->version == 2)
	{
		id3v2_tag *v2 = tag->tag;
		char *val;
		
		switch(field)
		{
			case MP_ARTIST:
				return mp_get_content_custom_at_pos(tag, "TPE1", pos);
			case MP_TITLE:
				return mp_get_content_custom_at_pos(tag, "TIT2", pos);
			case MP_ALBUM:
				return mp_get_content_custom_at_pos(tag, "TALB", pos);
			case MP_GENRE:
				return mp_get_content_custom_at_pos(tag, "TCON", pos);
			case MP_COMMENT:
				return mp_get_content_custom_at_pos(tag, "COMM", pos);
			case MP_YEAR:
				return mp_get_content_custom_at_pos(tag, "TYER", pos);
			case MP_TRACK:
				return mp_get_content_custom_at_pos(tag, "TRCK", pos);
		}
		errno = MP_EFNF;
		return NULL;
	}
	else
	{
		errno = MP_EVERSION;
		return NULL;
	}
}

id3_content*
mp_get_content_custom(const id3_tag* tag, const char*field)
{
	if(!tag)
	{
		errno = MP_EERROR;
		return NULL;
	} 
	else if(tag->version != 2)
	{		
		errno = MP_EVERSION;
		return NULL;
	}
	
	return id3v2_get_content_at_pos(tag->tag, field, 0);
	
}

id3_content*
mp_get_content_custom_at_pos(const id3_tag* tag, const char*field, int pos)
{
	if(!tag)
	{
		errno = MP_EERROR;
		return NULL;
	} 
	else if(tag->version != 2)
	{		
		errno = MP_EVERSION;
		return NULL;
	}
	
	
	return id3v2_get_content_at_pos(tag->tag, field, pos);
}


/*******************************************************************************************
 *                                         Set
 *******************************************************************************************/

 int
 mp_set_content(id3_tag* tag, const int field, id3_content* new_content)
 {
	 id3v1_tag *v1;
	 id3v2_tag *v2;
	 
	 
	 if(!tag) return MP_EERROR;
	 
	 if(tag->version == 2)
	 {
		 return mp_set_content_at_pos(tag, field, new_content, 0);
	 }
	 else if(tag->version == 1)
	 {
		unsigned char c;
		char *my_val;
		int len, j;
		 
		v1 = tag->tag;
		 
		 switch(field)
		 {

#define FLD(str1, str2, str3, str4) \
			case str1:\
				if(!new_content) v1->str2 = NULL;\
				else\
				{\
					id3_text_content *tc = str4(new_content);\
					if(strlen(tc->text) > str3 || tc->encoding != ISO_8859_1)\
					{\
						mp_convert_to_v2(tag);\
						mp_free_text_content(tc);\
						return mp_set_content(tag, field, new_content);\
					}\
					\
				 	v1->str2 = tc->text;\
					xfree(tc);\
				}\
				break;
			 
			 FLD(MP_ARTIST, artist, 30, mp_parse_artist);
			 FLD(MP_TITLE, title, 30, mp_parse_title);
			 FLD(MP_ALBUM, album, 30, mp_parse_album);
			 FLD(MP_YEAR, year, 4, mp_parse_year);
				 
			 case MP_COMMENT:
				 if(!new_content) v1->comment = NULL;
				 else
				 {
					 id3_comment_content *tc = mp_parse_comment(new_content);
					 if(strlen(tc->text) > 30 || tc->short_descr || tc->encoding != ISO_8859_1)
					 {
						 mp_convert_to_v2(tag);
						 mp_free_comment_content(tc);
						 return mp_set_content(tag, field, new_content);
					 }
					 v1->comment = xmallocd0(strlen(tc->text)+1,
						       "mp_set_content:v1->comment");
					 memcpy(v1->comment, tc->text, strlen(tc->text));
					 mp_free_comment_content(tc);
				 }
				 break;

			 case MP_TRACK:
				 if(!new_content) v1->track = 0;
				 else
				 {
					 id3_text_content *tc = mp_parse_track(new_content);
#ifdef HAVE_STRTOL
					 errno = 0;
					 j = strtol(tc->text, (char **)NULL, 10);
					 if(errno != ERANGE) v1->track = j;
					 else return MP_EERROR;
#else
					 v1->track = atoi(tc->text);
#endif
					 mp_free_text_content(tc);
				 }
				 break;

			 case MP_GENRE:
				 if(!new_content) v1->genre = 0xFF;
				 else
				 {
					 int b = 0, i;
					 id3_text_content *tc = mp_parse_genre(new_content);
					 /* i = strlen(tc->text); */
					 for(c = 0; c < GLL; c++) {
						 if(!strcmp(genre_list[c], tc->text))
						 {
							 v1->genre = c;
							 b = 1;
						 }
					 }
					 mp_free_text_content(tc);
					 if(!b)
					 {
						 mp_convert_to_v2(tag);
						 return mp_set_content(tag, field, new_content);
					 }
					 break;
				 }
			 }
	 }
	 else if(tag->version == -1) return MP_EVERSION;
	 else return MP_EFNF;
	 
	 return 0;
 }

int
mp_set_content_at_pos(id3_tag* tag, const int field, id3_content* new_content, int pos)
{
	char* c;
	
	if(!tag) return MP_EERROR;
	if(field < MP_ARTIST || field > MP_TRACK) return MP_EFNF;
	
	if(tag->version == 1 && pos == 0) return mp_set_content(tag, field, new_content);

	switch(field)
	{
		case MP_ARTIST: c = "TPE1"; break;
		case MP_TITLE: c = "TIT2"; break;
		case MP_ALBUM: c = "TALB"; break;
		case MP_TRACK: c = "TRCK"; break;
		case MP_YEAR: c = "TYER"; break;
		case MP_COMMENT: c = "COMM"; break;
		case MP_GENRE: c = "TCON"; break;
	}
	return mp_set_custom_content_at_pos(tag, c, new_content, pos);
}

int 
mp_set_custom_content(id3_tag* tag, char* field, id3_content* new_content)
{
	return mp_set_custom_content_at_pos(tag, field, new_content, 0);
}

int 
mp_set_custom_content_at_pos(id3_tag* tag, char* field, id3_content* new_content, int pos)
{
	id3v2_tag *v2;
	
	if(!tag || !field || strlen(field) != 4) return MP_EERROR;
	
	if(tag->version == 1)
	{
		if(mp_convert_to_v2(tag))
			return MP_EERROR;
	}
	else if(tag->version == -1) return MP_EVERSION;
	
	v2 = (id3v2_tag*)tag->tag;
	if(!v2->frame_list)
	{
		v2->frame_list = XMALLOCD0(id3v2_frame_list, 
				 "mp_set_custom_content_at_pos:v2->frame_list");
		id3_add_frame(v2->frame_list, field, new_content->data, new_content->length);
	}
	else
	{
		id3v2_frame *frame;
		
		if((frame = id3_lookup_frame(v2->frame_list, field, pos)))
		{
			if(new_content) 
			{
				long len, len_sync;
				/* make sync safe */
				len = new_content->length;
				len_sync = id3_sync(new_content->data, len);
				
				xfree(frame->data);
				frame->data = xmallocd(new_content->length,
					      "mp_set_custom_content_at_pos:frame->data");
				memcpy(frame->data, new_content->data, new_content->length);
				frame->status_flag = 0;
				if(len != len_sync) frame->format_flag = 64;
				else frame->format_flag = 0;
				frame->data_size = len_sync;
			}
			else id3_remove_frame(v2->frame_list, frame);
		}
		else if(pos == 0) id3_add_frame(v2->frame_list, field, new_content->data, new_content->length);
		else return MP_EFNF;
	}
	
	return 0;
}

/*******************************************************************************************
 *                                   Write & delete
 *******************************************************************************************/
 int
 mp_write_to_file(const id3_tag_list* tag_list, const char *filename)
 {
	 int ret;
	 int fd;
	 
	 if(!filename) return MP_EERROR;
	 
	 fd = open(filename, O_RDWR);
	 if(fd == -1) return MP_EERROR;
	 
	 ret = mp_write_to_fd(tag_list, fd);
	 close(fd);
	 return ret;
 }
 
 
 int
 mp_write_to_fd(const id3_tag_list* tag_list, const int fd)
 {
	 id3_tag *tag;
	 id3v1_tag *v1;
	 id3v2_tag *v2;
	 id3_tag_list *mylist;
	 int ret = 0;
	 
	 if(!tag_list) {
		 ret |= id3v1_del_tag(fd);
		 ret |= id3v2_del_tag(fd, NULL);
		 return ret;
	 }
	 
	 while(tag_list)
	 {
		 tag = tag_list->tag;
		 if(!tag)
		 {
			 tag_list = tag_list->next;
			 continue;
		 }
		 
		 if(tag->version == 1) 
		 {
		     id3v1_del_tag(fd);
		     ret |= id3v1_add_tag(fd, tag->tag);
		 }
		 else if(tag->version == 2) 
		 {
			 int pad = 0;
			 id3v2_frame_list *frame_list;
			 id3v2_tag *old_v2;
			 id3v2_tag *v2 = tag->tag;
			 
			 /* calculate tag size */
			 v2->header->total_tag_size = 10;
			 if(v2->header->has_footer) v2->header->total_tag_size += 10;
			 if(v2->header->has_extended_header) v2->header->total_tag_size += v2->header->extended_header->size;
			 frame_list = v2->frame_list;
			 while(frame_list)
			 {
				 v2->header->total_tag_size += frame_list->data->data_size + 10;
				 frame_list = frame_list->next;
			 }
			 
			 /* this is where padding handling takes place */
			 /* we must get the old tag to see if padding can be used */
			 old_v2 = id3v2_get_tag(fd);
			 if(old_v2) {
				 if(v2->header->total_tag_size > old_v2->header->total_tag_size)
				 {
					 /* padding not sufficent */
					 ret |= id3v2_del_tag(fd, old_v2);
					 ret |= id3v2_add_tag(fd, v2, NULL);
				 }
				 else
				 {
					 ret |= id3v2_add_tag(fd, v2, old_v2);
				 }
				 id3v2_free_tag(old_v2);
			 } else {
				 ret |= id3v2_add_tag(fd, v2, NULL);
			 }
			 
		 }
		 else
		 {
			 ret |= MP_EVERSION;
		 }
		 
		 tag_list = tag_list->next;
	 } /* tag list */
	 
	 return ret;
 }

int 
mp_del_tags_from_file(const char* filename)
{
	int ret, fd;
	
	if(!filename) return 1;
	
	fd = open(filename, O_RDWR);
	if(fd == -1) return 1;
	
	ret = mp_del_tags_from_fd(fd);
	close(fd);
	return ret;
}

int
mp_del_tags_from_fd(const int fd)
{
	int ret = 0;
	
	ret |= id3v1_del_tag(fd);
	ret |= id3v2_del_tag(fd, NULL);
	
	return ret;
}

int 
mp_del_tags_by_ver_from_file(const char* filename, const int version)
{
	int fd, ret;
	
	if(!filename) return 1;
	
	fd = open(filename, O_RDWR);
	if(fd == -1) return 1;
	
	ret = mp_del_tags_by_ver_from_fd(fd, version);
	close(fd);
	return ret;
}

int
mp_del_tags_by_ver_from_fd(const int fd, const int version)
{
	if(version == 1) return id3v1_del_tag(fd);
	else if(version == 2) return id3v2_del_tag(fd, NULL);
	else return MP_EVERSION;
}




/*******************************************************************************************
 *                                          Misc
 *******************************************************************************************/

 int 
 mp_convert_to_v2(id3_tag *tag)
 {
	 id3v1_tag *v1;
	 id3_tag *tmp;
	 id3_content* content;
	 
	 if(tag->version == 2) return 0;
	 else if(tag->version == -1) return MP_EVERSION;
	 
	 tmp = mp_alloc_tag_with_version(2);
	 
	 v1 = (id3v1_tag*)tag->tag;
	 
	 content = mp_assemble_text_content(v1->artist, ISO_8859_1);
	 if(v1->artist) mp_set_content(tmp, MP_ARTIST, content);
	 
	 content = mp_assemble_text_content(v1->title, ISO_8859_1);
	 if(v1->title) mp_set_content(tmp, MP_TITLE, content);
	 
	 content = mp_assemble_text_content(v1->album, ISO_8859_1);
	 if(v1->album) mp_set_content(tmp, MP_ALBUM, content);
	 
	 content = mp_assemble_text_content(v1->year, ISO_8859_1);
	 if(v1->year) mp_set_content(tmp, MP_YEAR, content);
	 
	 content = mp_assemble_comment_content(v1->comment, NULL, ISO_8859_1, NULL);
	 if(v1->comment) mp_set_content(tmp, MP_COMMENT, content);
	 
	 if(v1->genre != 0xFF)
	 {
		 char *c = xmallocd(strlen(genre_list[v1->genre]) + 1,
				    "mp_convert_to_v2:c");
		 strcpy(c, genre_list[v1->genre]);
		 content = mp_assemble_text_content(c, ISO_8859_1);
		 mp_set_content(tmp, MP_GENRE, content);
	 }
	 if(v1->track > 0)
	 {
		 char *trk = (char *)xmallocd(4, "mp_convert_to_v2:trk");
		 snprintf(trk, 3, "%d", v1->track);
		 trk[3] = 0;
		 content = mp_assemble_text_content(trk, ISO_8859_1);
		 mp_set_content(tmp, MP_TRACK, content);
	 }
	 
	 tag->version = 2;
	 tag->tag = tmp->tag;
	 
	 id3v1_free_tag(v1);
	 xfree(tmp);
	 
	 return 0;
 }
 
int 
mp_convert_to_v1(id3_tag *tag)
{
	id3v1_tag *v1;
	id3_tag* tmp;
	id3_content* content;
	id3_text_content* tc;
	id3_comment_content* cc;
	char* c;
	int j, k = 0;
	
	if(tag->version == 1) return 0;
	else if(tag->version == -1) return MP_EVERSION;
	
	v1 = XMALLOCD0(id3v1_tag, "mp_convert_to_v1:v1");
	
	content = mp_get_content(tag, MP_ARTIST);
	tc = mp_parse_artist(content);
	v1->artist = tc->text;
	xfree(tc);
	mp_free_content(content);
	
	content = mp_get_content(tag, MP_TITLE);
	tc = mp_parse_title(content);
	v1->title = tc->text;
	xfree(tc);
	mp_free_content(content);
	
	content = mp_get_content(tag, MP_ALBUM);
	tc = mp_parse_album(content);
	v1->album = tc->text;
	xfree(tc);
	mp_free_content(content);
	
	content = mp_get_content(tag, MP_YEAR);
	tc = mp_parse_year(content);
	v1->year = tc->text;
	xfree(tc);
	mp_free_content(content);
	
	content = mp_get_content(tag, MP_COMMENT);
	cc = mp_parse_comment(content);
	v1->comment = cc->text;
	xfree(cc->language);
	xfree(cc->short_descr);
	xfree(cc);
	mp_free_content(content);
	
	content = mp_get_content(tag, MP_TRACK);
	tc = mp_parse_track(content);
	c = tc->text;
	if(c)
	{
#ifdef HAVE_STRTOL
		errno = 0;
		j = strtol(c, (char **)NULL, 10);
		if(errno != ERANGE) v1->track = j;
		else v1->track = 0;
#else
		v1->track = atoi(c);
#endif
	}
	else v1->track = 0;
	xfree(c);
	mp_free_text_content(tc);
	mp_free_content(content);
	
	content = mp_get_content(tag, MP_GENRE);
	tc = mp_parse_genre(content);
	c = tc->text;
	for(j = 0; c, j < GLL; j++) {
		if(!strcmp(genre_list[j], c))
		{
			v1->genre = j;
			k = 1;
		}
	}
	if(!c) v1->genre = 0xFF;
	xfree(c);
	mp_free_text_content(tc);
	mp_free_content(content);
	
	id3v1_truncate_tag(v1);
	
	id3v2_free_tag(tag->tag);
	
	tag->version = 1;
	tag->tag = v1;
	
	return 0;
}

int
mp_is_valid_v1_value(int field, char *value)
{
	int len = 30;
	int j;
	
	switch(field) {
		case MP_YEAR:
			len = 4;
			break;
			
		case MP_TRACK:
#ifdef HAVE_STRTOL
			errno = 0;
			j = strtol(value, (char **)NULL, 10);
			if(errno != ERANGE) return 1;
			else return 0;
#else
			 return 1; /* poor fellow */
#endif

		case MP_GENRE:
			for(j = 0; j < GLL; j++) {
				if(!strcmp(genre_list[j], value))
				{
					return 1;
				}
				return 0;
			}
	}

	/* Check string length */
	if(strlen(value) > len) return 0;
	else return 1;	 
}


void
mp_free_list(id3_tag_list *list)
{
	if(!list) return;
	
	/* free tag */
	if(list->tag) mp_free_tag(list->tag);

	/* free next element */
	if(list->next) mp_free_list(list->next);

	/* free this element */
	xfree(list); 
}

id3_tag*
mp_alloc_tag(void)
{
	/* The tags initialized version makes a different. Generally spoken, we 
	like to make id3v1 tags if possible and therefor set the version to 1
	here. This matters in mp_set_content(). */
	return mp_alloc_tag_with_version(1);
}

id3_tag*
mp_alloc_tag_with_version(int v)
{
	id3_tag* ret;
	
	if(v != 1 && v != 2) return NULL;
	
	ret = XMALLOCD(id3_tag, "mp_alloc_tag_with_version:ret");
	ret->version = v;
	if(v == 1)
	{
		ret->tag = XMALLOCD0(id3v1_tag, "mp_alloc_tag_with_version:ret->tag");
		((id3v1_tag*)ret->tag)->genre = 0xFF;
	}
	else
	{
		id3v2_tag *v2;
		/* XXX */
		ret->tag = XMALLOCD0(id3v2_tag, "mp_alloc_tag_with_version:ret->tag");
		v2 = (id3v2_tag*)ret->tag;
		v2->header = XMALLOCD0(id3v2_header, "mp_alloc_tag_with_version:v2->header");
//if ID3VERSION == "2.4"
		v2->header->version_minor = 4;
//else
		v2->header->version_minor = 3;
//endif
		v2->header->version_revision = 0;
		v2->header->unsyncronization = 1;
		v2->header->has_extended_header = 0;
		v2->header->is_experimental = 1;
		v2->header->has_footer = 0;
		v2->header->flags = 0;
		v2->header->total_tag_size = 0;
		v2->header->extended_header = NULL;
		v2->frame_list = NULL;
	}
	return ret;
}

void 
mp_free_tag(id3_tag *tag)
{
	if(!tag) return;
	
	if(tag->version == 1)
	{
		id3v1_free_tag(tag->tag);
	}
	else if(tag->version == 2)
	{
		id3v2_free_tag(tag->tag);
	}
	xfree(tag);
}

void
mp_free_content(id3_content *content)
{
	if(!content) return;
	xfree(content->data);
	xfree(content);
}

void
mp_free_text_content(id3_text_content *content)
{
	if(!content) return;
	xfree(content->text);
	xfree(content);
}

void 
mp_free_comment_content(id3_comment_content *content)
{
	if(!content) return;
	xfree(content->language);
	xfree(content->short_descr);
	xfree(content->text);
	xfree(content);
}

void
mp_free_wxxx_content(id3_wxxx_content *content)
{
    if (!content) return;
    xfree(content->description);
    xfree(content->url);
    xfree(content);
}

