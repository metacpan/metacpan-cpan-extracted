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
#include <ctype.h>
#include <sys/stat.h>

#include "mplib_s.h"
#include "xmalloc.h"



/******************************/
/*      Static functions           */
/******************************/

static id3v1_tag*
id3v1_get_tag(int fd)
{
	id3v1_tag *tag;
	char *c;
	
	tag = XMALLOCD0(id3v1_tag, "id3v1_get_tag:tag");
	
	c = (char *)xmallocd(3, "id3v1_get_tag:c");
	
	if(lseek(fd, -128L, SEEK_END) == -1) goto exit_on_error;
	if(read(fd, c, 3) < 3) goto exit_on_error;
	if(strncmp(c, "TAG", 3) != 0) goto exit_on_error;

	tag->title = (char *)xmallocd(31, "id3v1_get_tag:tag->title");
	if(read(fd, tag->title, 30) < 30) goto exit_on_error;
	if(tag->title[0] == 0 || id3_is_only_space(tag->title, 30)) {
	    xfree(tag->title);
	    tag->title = NULL;
	} else tag->title[30] = 0;
	
	tag->artist = (char*)xmallocd(31, "id3v1_get_tag:tag->artist");
	if(read(fd, tag->artist, 30) < 30) goto exit_on_error;
	if(tag->artist[0] == 0 || id3_is_only_space(tag->artist, 30)) {
	    xfree(tag->artist);
	    tag->artist = NULL;
	} else tag->artist[30] = 0;
	
	tag->album = (char*)xmallocd(31, "id3v1_get_tag:tag->album");
	if(read(fd, tag->album, 30) < 30) goto exit_on_error;
	if(tag->album[0] == 0 || id3_is_only_space(tag->album, 30)) {
	    xfree(tag->album);
	    tag->album = NULL;
	} else tag->album[30] = 0;
	
	tag->year = (char*)xmallocd(5, "id3v1_get_tag:tag->year");
	if(read(fd, tag->year, 4) < 4) goto exit_on_error;
	if(tag->year[0] == 0 || id3_is_only_space(tag->year, 4)) {
	    xfree(tag->year);
	    tag->year = NULL;
	} else tag->year[4] = 0;
	
	tag->comment = (char*)xmallocd(31, "id3v1_get_tag:tag->comment");
	if(read(fd, tag->comment, 30) < 30) goto exit_on_error;
	tag->comment[30] = 0;
	
	if(read(fd, &(tag->genre), 1) < 1) goto exit_on_error;
	
	/* Looking for v1.1 track info */
	if(tag->comment && tag->comment[28] == 0 && tag->comment[29] != 0)
	{
		tag->track = tag->comment[29];
		tag->comment[29] = 0;
	} 
	else 
	{
		tag->track = 0;
	}
	
	/* Set comment to NULL if not set - this happens at this point because */
	/* there maybe a track info anyway */
	if(tag->comment[0] == 0 || id3_is_only_space(tag->comment, 28)) {
	    xfree(tag->comment);
	    tag->comment = NULL;
	}
	
	xfree(c);
	return tag;

	exit_on_error:
	
	xfree(c);
	id3v1_free_tag(tag);
	return NULL;
}

static int 
id3v1_add_tag(int fd, id3v1_tag *tag) 
{
	int i, j;
	void *blank, *set;
	char *b_tag, *b_tag_start;
	
	blank = xmallocd0(30, "id3v1_add_tag:blank");
	set = xmallocd(30, "id3v1_add_tag:set");
	memset(set, 0xFF, 30);
	b_tag = b_tag_start = (char *)xmallocd0(128, "id3v1_add_tag:b_tag");
	
	strncpy(b_tag, "TAG", 3); b_tag += 3;
	
	if(tag->title) 
	{
		j = strlen(tag->title);
		strncpy(b_tag, tag->title, j); b_tag += j;
		i = 30 - j;
		if(i > 0) 
		{
			strncpy(b_tag, blank, i); b_tag += i;
		}
	}
	else 
	{
		strncpy(b_tag, blank, 30); b_tag += 30;
	}
	
	if(tag->artist) 
	{
		j = strlen(tag->artist);
		strncpy(b_tag, tag->artist, j); b_tag += j;
		i = 30 - j;
		if(i > 0) 
		{
			strncpy(b_tag, blank, i); b_tag += i;
		}
	} 
	else
	{
		strncpy(b_tag, blank, 30); b_tag += 30;
	}
	
	if(tag->album)
	{
		j = strlen(tag->album);
		strncpy(b_tag, tag->album, j); b_tag += j;
		i = 30 - j;
		if(i > 0)
		{
			strncpy(b_tag, blank, i); b_tag += i;
		}
	}
	else
	{
		strncpy(b_tag, blank, 30); b_tag += 30;
	}
	
	if(tag->year) 
	{
		j = strlen(tag->year);
		strncpy(b_tag, tag->year, j); b_tag += j;
		i = 4 - j;
		if(i > 0) 
		{
			strncpy(b_tag, blank, i); b_tag += i;
		}
	}
	else 
	{
		strncpy(b_tag, blank, 4); b_tag += 4;
	}
	
	if(tag->comment)
	{
		int hastrack = 0;
		j = strlen(tag->comment);
		if(tag->track > 0) hastrack = 1;
		if(hastrack && j > 28) 
		{
			strncpy(b_tag, tag->comment, 28); b_tag += 28;
		}
		else
		{
			strncpy(b_tag, tag->comment, j); b_tag += j;
			i = ((tag->track > 0) ? 28 : 30) - j;
		}
		if(i > 0)
		{
			strncpy(b_tag, blank, i); b_tag += i;
		}
	} 
	else 
	{ 
		strncpy(b_tag, blank, (tag->track > 0) ? 28 : 30); 
		b_tag += (tag->track > 0) ? 28 : 30;
	}
	
	if(tag->track > 0) 
	{
		strncpy(b_tag, blank, 1); b_tag += 1;
		strncpy(b_tag, &(tag->track), 1); b_tag += 1;
	}
	if(tag->genre != 0xFF) 
	{
		strncpy(b_tag, &(tag->genre), 1); b_tag += 1;
	}
	else 
	{
		strncpy(b_tag, set, 1); b_tag += 1;
	}
	
	j = 0;
	
	if(lseek(fd, 0L, SEEK_END) != -1)
	{
	    if(write(fd, b_tag - 128, 128) < 128) j = 1;
	}
	else j = 1;

	xfree(b_tag_start);
	xfree(blank);
	xfree(set);
	
	return j;
}

static int 
id3v2_add_tag(int fd, id3v2_tag *tag, id3v2_tag *old)
{
	unsigned char *btag, *btag_start;
	unsigned char flag = 0;
	int i, j;
	char *b_tag, *b_tag_start, *d;
	id3v2_frame_list *frame_list;
	id3v2_frame *frame;

	/* at first we are going to write the tags raw data into
	the btag byte array */
	btag = btag_start = xmallocd0(tag->header->total_tag_size,
			    "id3v2_add_tag:btag");
	strncpy(btag, "ID3", 3); btag += 3;
	*btag = (char)tag->header->version_minor; btag += 1;
	*btag = (char)tag->header->version_revision; btag += 1;
	flag |= ((tag->header->unsyncronization & 1) << 7);
	flag |= ((tag->header->has_extended_header & 1) << 6);
	flag |= ((tag->header->is_experimental & 1) << 5);
	flag |= ((tag->header->has_footer & 1) << 4);
	memcpy(btag, &flag, 1); btag += 1;
	
	if(old)
	{
		i = old->header->total_tag_size - 10;
		if(old->header->has_footer) i -= 10;
	}
	else
	{
		i = tag->header->total_tag_size - 10;
		if(tag->header->has_footer) i -= 10;
		/* add padding to total size we mean to store on disk */
		/* mplib does not use any kind of padding internaly */
		i += 1024;
	}
	
	d = id3_sync32(i); 
	btag[0] = d[0];
	btag[1] = d[1];
	btag[2] = d[2];
	btag[3] = d[3];
	xfree(d);
	btag += 4;
	
	if(tag->header->has_extended_header)
	{
		d = id3_sync32(tag->header->extended_header->size);
		btag[0] = d[0];
		btag[1] = d[1];
		btag[2] = d[2];
		btag[3] = d[3];
		xfree(d);
		btag += 4;
		
		*btag = (char)tag->header->extended_header->no_flag_bytes; btag += 1;
		flag = ((tag->header->extended_header->is_update & 1) << 6);
		flag |= ((tag->header->extended_header->crc_data_present & 1) << 5);
		flag |= ((tag->header->extended_header->restrictions & 1) << 4);
		memcpy(btag, &flag, 1); btag += 1;
		if(tag->header->extended_header->is_update) 
		{
			btag[0] = 0; btag += 1;
		}
		if(tag->header->extended_header->crc_data_present) 
		{
			int length = tag->header->extended_header->crc_data_length ? tag->header->extended_header->crc_data_length : 5;
			*btag = (char)length; btag += 1;
			memcpy(btag, tag->header->extended_header->crc_data, length); btag += 1;
		}
		if(tag->header->extended_header->restrictions) 
		{
			int length = tag->header->extended_header->restrictions_data_length ? tag->header->extended_header->restrictions_data_length : 5;
			*btag = (char)length; btag += 1;
			memcpy(btag, tag->header->extended_header->restrictions_data, length); btag += 1;
		}
	}
	
	frame_list = tag->frame_list;
	while(frame_list) {
		int j;
		frame = frame_list->data;
		
		strncpy(btag, frame->frame_id, 4); btag += 4;
		d = id3_sync32(frame->data_size);
		btag[0] = d[0];
		btag[1] = d[1];
		btag[2] = d[2];
		btag[3] = d[3];
		xfree(d);
		btag += 4;
		memcpy(btag, &frame->status_flag, 1); btag += 1;
		memcpy(btag, &frame->format_flag, 1); btag += 1;
		
		memcpy(btag, frame->data, frame->data_size); btag += frame->data_size;
		
		frame_list = frame_list->next;
	}
	
	/* XXX footer not supported yet */
	
	/* if an old tag was provided it is desired to overwrite it */
	/* else this is a brand new tag */
	if(old) {  
		FILE *file;
		void *ptr = xmallocd0(old->header->total_tag_size - tag->header->total_tag_size, "id3v2_add_tag:ptr");
		if(!(file = fdopen(fd, "r+b")))
		{
		    xfree(ptr);
		    goto exit_on_error;
		}
		
		fseek(file, 0, SEEK_SET);
		if(fwrite(btag_start, tag->header->total_tag_size, 1, file) < 1)
		{
		    xfree(ptr);
		    goto exit_on_error;
		}
		
		/* write padding till end of old tag */
		if(fwrite(ptr, old->header->total_tag_size - tag->header->total_tag_size, 1, file) < 1) {
		    xfree(ptr);
		    goto exit_on_error;
		}
		
		fflush(file);
		xfree(ptr);
				
	} else {
		FILE *file, *tmp;
		int read;
		void *ptr, *blank;
		unsigned char *c;

		ptr = xmallocd(4096, "id3v2_add_tag:ptr");
		blank = xmallocd0(1024, "id3v2_add_tag:blank");

		file = fdopen(fd, "r+b");
		tmp = tmpfile();
		if(!(file && tmp)) 
		{
		    fflush(file);
		    fclose(tmp);
		    xfree(ptr);
		    xfree(blank);
		    goto exit_on_error;
		}

		fseek(file, 0, SEEK_SET);
		fseek(tmp, 0, SEEK_SET);

		/* write tag in tmp file */
		fwrite(btag_start, tag->header->total_tag_size, 1, tmp);

		/* Write 1024b padding */
		fwrite(blank, 1024, 1, tmp);

		/* write rest of file */
		while(!feof(file))
		{
			read = fread(ptr, 1, 4096, file);
			if(fwrite(ptr, 1, read, tmp) != read && !feof(file))
			{
			    fflush(file);
			    fclose(tmp);
			    xfree(ptr);
			    xfree(blank);
			    goto exit_on_error;
			}
		}

		fflush(tmp);

		fseek(file, 0, SEEK_SET);
		fseek(tmp, 0, SEEK_SET);
		while(!feof(tmp))
		{
			read = fread(ptr, 1, 4096, tmp);
			if(fwrite(ptr, 1, read, file) != read && !feof(tmp))
			{
			    fflush(file);
			    fclose(tmp);
			    xfree(ptr);
			    xfree(blank);
			    goto exit_on_error;
			}
		}

		fflush(file);
		fclose(tmp);

		xfree(ptr);
		xfree(blank);
	    }

	xfree(btag_start);
	return 0;

 exit_on_error:
	xfree(btag_start);
	return MP_EERROR;
}

static int
id3v1_del_tag(int fd) 
{
	int nlength;
	unsigned char *c;
	struct stat fs;
	
	if(fstat(fd, &fs)) return 1;
	
	if(fs.st_size < 128) return 1; /* Hardly a valid mpeg file.. */

	c = (char *)xmallocd(3, "id3v1_del_tag:c");
	if(lseek(fd, -128L, SEEK_END) == -1) goto exit_on_error;
	if(read(fd, c, 3) < 3) goto exit_on_error;
	if(strncmp(c, "TAG", 3)) goto exit_on_error;
	xfree(c);
		
	nlength = fs.st_size - 128;
		
	if(ftruncate(fd, nlength)) return 1;  
		
	return 0;

 exit_on_error:
	xfree(c);
	return 1;
}


static int
id3v2_del_tag(int fd, id3v2_tag *t)
{
	unsigned char *c;
	long tag_len, file_len;
	FILE *file, *tmp;
	int read;
	void *ptr;
	id3v2_tag *tfound = NULL;;
	
	if(!t)
	{
	    t = id3v2_get_tag(fd);
	    if(!t) return 0;
	    else tfound = t;
	}
	
	ptr =  xmallocd(4096, "id3v2_del_tag:ptr");
	
	tag_len = t->header->total_tag_size;
	file_len = lseek(fd, 0, SEEK_END);
	if(file_len < 1 || tag_len < 1) goto exit_on_error;
	
	/* use os system buffering */
	file = fdopen(fd, "r+b");
	tmp = tmpfile();
	if(!(file && tmp)) goto exit_on_error;
	
	fseek(file, tag_len, SEEK_SET);
	fseek(tmp, 0, SEEK_SET);
	while(!feof(file))
	{
		read = fread(ptr, 1, 4096, file);
		if(fwrite(ptr, 1, read, tmp) != read && !feof(file))
		    goto exit_on_error;
	}
	
	fflush(tmp);
	
	fseek(file, 0, SEEK_SET);
	fseek(tmp, 0, SEEK_SET);
	while(!feof(tmp))
	{
		read = fread(ptr, 1, 4096, tmp);
		if(fwrite(ptr, 1, read, file) != read && !feof(tmp)) 
		    goto exit_on_error;
	}
	
	fclose(tmp);
	xfree(ptr);
	if(tfound) id3v2_free_tag(tfound);
	return 0;

 exit_on_error:
	fclose(tmp);
	xfree(ptr);
	if(tfound) id3v2_free_tag(tfound);
	return 1;
}


static int
id3v1_truncate_tag(id3v1_tag *tag)
{
	int notrunc = 0;
	int len = 0;
	void *ptr;
	
	if(tag->title && (len = strlen(tag->title)) > 30) 
	{
		realloc(tag->title, 31);
		tag->title[30] = 0;
	}
	
	if(tag->artist && (len = strlen(tag->artist)) > 30) 
	{
		realloc(tag->artist, 31);
		tag->artist[30] = 0;
	}
	
	if(tag->album && (len = strlen(tag->album)) > 30) 
	{
		realloc(tag->album, 31);
		tag->album[30] = 0;
	}
	
	if(tag->year && (len = strlen(tag->year)) > 4) 
	{
		realloc(tag->title, 5);
		tag->title[4] = 0;
	}
	
	if(tag->comment) 
	{
		int max = (tag->track > 0) ? 28 : 30;
		if((len = strlen(tag->comment)) > max) 
		{
			realloc(tag->comment, max + 1);
			tag->comment[max] = 0;
		}
	}
	
	return notrunc;
}

static int
id3_is_only_space(char *str, int strlen) 
{
	int i = 0;
	
	while(i < strlen)
	{
		if(str[i] != 0x20) return 0;
		i++;
	}
	
	return 1;
}

static id3v2_tag*
id3v2_get_tag(int fd)
{
	unsigned char *c;
	id3v2_header *header;
	id3v2_frame_list *frame_list;
	id3v2_frame *frame;
	id3v2_tag *tag = NULL;
	int i;
	
	if(lseek(fd, 0L, SEEK_SET) == -1) return NULL;
	
	c = (unsigned char*)xmallocd0(1024, "id3v2_get_tag:c");
	
	if(read(fd, c, 10) < 10) goto exit_on_error;

	c[10] = 0;
	
	if(strncmp(c, "ID3", 3)) goto exit_on_error;

	header = XMALLOCD0(id3v2_header, "id3v2_get_tag:header");
	header->version_minor = c[3];
	header->version_revision = c[4];
	header->flags = c[5];
	header->unsyncronization = (c[5] & 128) >> 7;
	header->has_extended_header = (c[5] & 64) >> 6;
	header->is_experimental = (c[5] & 32) >> 5;
	header->has_footer = (c[5] & 16) >> 4;
	
	header->total_tag_size = id3_unsync32(c, 6) + 10;
	if(header->has_footer) header->total_tag_size += 10;
	
	tag = XMALLOCD0(id3v2_tag, "id3v2_get_tag:tag");
	
	/* check if version is supported */
	if(c[3] != 3 && c[3] != 4)
	{
		xfree(c);
		tag->header = header;
		tag->frame_list = NULL;
		return tag;
	}

	frame_list = XMALLOCD0(id3v2_frame_list, "id3v2_get_tag:frame_list");
	frame_list->start = frame_list;
	
	/* assigning header and frame list to tag */
	tag->header = header;
	tag->frame_list = frame_list;

	if(header->has_extended_header)
	{
		id3v2_extended_header *xt_header = XMALLOCD0(id3v2_extended_header,
						   "id3v2_get_tag:id3v2_extended_header");
		
		header->extended_header = xt_header;
		
		read(fd, c, 4); /* get length of extended header */
		xt_header->size = id3_unsync32(c, 0);
		
		read(fd, c, 1); /* get number of flags */
		xt_header->no_flag_bytes = (c[0] > 0) ? c[0] : 1;
		
		read(fd, c, xt_header->no_flag_bytes); /* get flag bytes */
		xt_header->is_update = (c[0] & 64) >> 6;
		xt_header->crc_data_present = (c[0] & 32) >> 5;
		xt_header->restrictions = (c[0] & 16) >> 4;
		
		/* Flag data */
		if(xt_header->is_update) read(fd, c, 1); /* Data length ind. is 0 -skip */
		if(xt_header->crc_data_present) {
			read(fd, c, 1); /* data length - shoud be 5 */
			if(*c != 5) goto exit_on_error; /*  else things might
			break badly */
			xt_header->crc_data_length = *c;
			xt_header->crc_data = xmallocd0(*c, "id3v2_get_tag:xt_header->crc_data");
			read(fd, xt_header->crc_data, *c);
		}
		if(xt_header->restrictions) {
			read(fd, c, 1); /* data length - shoud be 1 */
			if(*c != 1) goto exit_on_error;
			xt_header->restrictions_data_length = *c;
			xt_header->restrictions_data = xmallocd0(*c,
						       "id3v2_get_tag:xt_header->restrictions_data");
			read(fd, xt_header->restrictions_data, *c); 
		}
	}

	/* Read frames */
	while(lseek(fd, 0L, SEEK_CUR) < header->total_tag_size)
	{
		int hasEnc = 0, hasLang = 0, d;
		
		read(fd, c, 10); /* Read header */
		
		/* break if padding is reached - this should never happen here.. */
		if(c[0] == 0 && c[1] == 0 && c[2] ==  0 && c[3] == 0) break;
		
		/* Check if possible id is alpha numeric */
		if(!isalnum(c[0]) || !isalnum(c[1]) || !isalnum(c[2]) || !isalnum(c[3])) break;
		
		frame = XMALLOCD(id3v2_frame, "id3v2_get_tag:frame");
		frame->frame_id = xmallocd(4, "id3v2_get_tag:frame->frame_id");
		strncpy(frame->frame_id, c, 4);
		frame->data_size = id3_unsync32(c, 4);
		frame->status_flag = c[8];
		frame->format_flag = c[9];
		
		/* Getting frame content */
		frame->data = xmallocd(frame->data_size, "id3v2_get_tag:frame->data_size");
		read(fd, frame->data, frame->data_size);
		
		/* Add frame to list */
		if(frame_list->data)
		{
			frame_list->next = XMALLOCD(id3v2_frame_list, "id3v2_get_tag:frame_list->next");
			frame_list->next->start = frame_list->start;
			frame_list = frame_list->next;
			frame_list->next = NULL;
		}
		frame_list->data = frame;
	}
	
	xfree(c);
	return tag;
	
	exit_on_error:
	
	xfree(c);
	id3v2_free_tag(tag);
	return NULL;
}

static char **
id3v2_get_names(id3v2_tag *tag)
{
	id3v2_frame *frame;
	id3v2_frame_list *frame_list;
	char **clist;
	int i;
	
	if(!tag->frame_list) return NULL;
	
	frame_list = tag->frame_list;
	
	i =  id3_get_no_frames(tag);
	clist = xmallocd(sizeof(char*) * i+1, "id3v2_get_names:clist");
	clist[i] = 0;
	
	for(i = 0; frame_list; i++)
	{
		if(!frame_list->data) continue;
		frame = frame_list->data;
		
		if(!frame->frame_id) continue;
		clist[i] = xmallocd(5, "id3v2_get_names:clist[i]");
		strncpy(clist[i], frame->frame_id, 4);
		clist[i][4] = 0;
		frame_list = frame_list->next;
	}
	return clist;
}


static id3_content*
id3v1_get_content(id3v1_tag *tag, int field)
{
	int i;
	char *c;
	id3_content *ret;
	
		switch(field)
		{
			case MP_ARTIST:
				if(!tag->artist)
				{
					errno = MP_EFNF;
					return NULL;
				}
				return mp_assemble_text_content(tag->artist, ISO_8859_1);			
			
			case MP_TITLE:
				if(!tag->title)
				{
					errno = MP_EFNF;
					return NULL;
				}
				return mp_assemble_text_content(tag->title, ISO_8859_1);			
			
			case MP_ALBUM:
				if(!tag->album)
				{
					errno = MP_EFNF;
					return NULL;
				}
				return mp_assemble_text_content(tag->album, ISO_8859_1);
				
			case MP_YEAR:
				if(!tag->year)
				{
					errno = MP_EFNF;
					return NULL;
				}
				return mp_assemble_text_content(tag->year, ISO_8859_1);
			
			case MP_COMMENT:
				if(!tag->comment)
				{
					errno = MP_EFNF;
					return NULL;
				}
				return mp_assemble_comment_content(tag->comment, NULL, ISO_8859_1, NULL);
				
			case MP_GENRE:
				if(tag->genre < GLL)
				{
					return mp_assemble_text_content(genre_list[tag->genre], ISO_8859_1);
				}
				else 
				{
					errno = MP_EFNF;
					return NULL;
				}
					
			case MP_TRACK:
				if(!tag->track) 
				{
					errno = MP_EFNF;
					return NULL;
				}
						
				if(tag->track < 10) i = 2;
				else if(tag->track < 100) i = 3;
				else i = 4;
				c = xmallocd(i, "id3v1_get_content:c");
				snprintf(c, i, "%d", tag->track);
				ret = mp_assemble_text_content(c, ISO_8859_1);
				xfree(c);
				return ret;
						
			default:
				errno = MP_EFNF;
				return NULL;
		}
}

static id3_content*
id3v2_get_content_at_pos(id3v2_tag *tag, const char *field, int pos)
{
	id3v2_frame_list *frame_list;
	id3v2_frame *frame;
	int i, found, j;
	
	if(!tag->frame_list || !field) 
	{
		errno = MP_EERROR;
		return NULL;
	}
	
	frame_list = tag->frame_list;
	
	for(i = 0, found = 0; frame_list; i++, frame_list = frame_list->next)
	{
		if(!frame_list->data) continue;
		frame = frame_list->data;
		
		if(!frame->frame_id || !frame->data) continue;
		if(strncmp(frame->frame_id, field, 4)) continue;
		
		if(found == pos)
		{
		        id3_content *ret = XMALLOCD0(id3_content,
					   "id3v2_get_content_at_pos:ret");
			if(frame_is_compressed(frame)) ret->compressed = 1;
			else ret->compressed = 0;
			
			if(frame_is_encrypted(frame)) ret->encrypted = 1;
			else ret->encrypted = 0;
			
			ret->length = frame->data_size;
			ret->data = xmallocd(frame->data_size, "id3v2_get_content_at_pos:ret->data");
			ret->data = memcpy(ret->data, frame->data, frame->data_size);
			
			return ret;
		}
		
		found++;
	}
	
	errno = MP_EFNF;
	return NULL;
}

static long
id3_sync(unsigned char* data, long length)
{
	int i;
	
	for(i = 0; i < length - 1; i++)
	{
		if(((data[i] & 0xFF) == 0xFF && (data[i+1] & 0xE0) == 0xE0) ||
			(i+2 < length && (data[i] & 0xFF) == 0xFF && data[i+1] == 0 && data[i+2] != 0))
			{
				
				realloc(data, length + 1); length++;
				memmove(data + i+2, data + i+1, length - i - 2);
				memset(data + i+1, 0, 1);
			} 
	}
	
	return length;
}

static long
id3_unsync(unsigned char* data, long length)
{
	/* TODO */
	/* this function is supposed to make syncsafe values normal again */
	/* we don't need this yet, because there are no fields supported that will */
	/* have the unsynchronization scheme applied */
	
	
}

static unsigned int
id3_unsync32(unsigned char* c, int start)
{
	return c[start+3] + (c[start+2] << 7) + (c[start+1] << 14) + (c[start] << 21);
}

int
id3_get_no_frames(id3v2_tag *tag)
{
	int i;
	id3v2_frame_list *frame_list = tag->frame_list;
	
	for(i = 0; frame_list; i++)
		frame_list = frame_list->next;  
		
		return i;
}

static unsigned char *
id3_sync32(unsigned int i)
{
	unsigned char *c = (unsigned char *)xmallocd0(4, "id3_sync32:c");
	
	c[3] = (i & 0x7f);
	c[2] = ((i & 0x80) >> 7) | (((i & 0x7f00) >> 8) << 1);
	c[1] = ((i & 0x8000) >> 15) | (((i & 0x7f0000) >> 16) << 1);
	c[0] = ((i & 0x800000) >> 23) | (((i & 0x7f000000) >> 24) << 1);
	
	return c;
}

id3v2_frame* 
id3_lookup_frame(id3v2_frame_list *list, const char *field, const int pos)
{
	int cur = 0;
	
	if(!list || !field) return NULL;
	
	do
	{
		if(!strcmp(list->data->frame_id, field))
		{
			if(cur == pos) return list->data;
			cur++;
		}
	} while((list = list->next));
	
	return NULL;
}

int 
id3_remove_frame(id3v2_frame_list *list, id3v2_frame *frame)
{
	if(!list || !frame) return MP_EERROR;
	
	/* Frame is first element in list */
	if(list->data == frame)
	{
		xfree(list->data);
		list->next->start = list->next;
		xfree(list);
		return 0;
	}
	
	/* Iterate through others */
	do
	{
		if(list->next->data == frame)
		{
			list->next = list->next->next;
			xfree(frame);
			return 0;
		}
	} while((list = list->next));
	
	return 1;
}


int 
id3_add_frame(id3v2_frame_list *list, char *field, char *new_value, int len)
{
	id3v2_frame *frame;
	char *new_valuecp;
	long len_sync;
	
	if(!list || !new_value || !field || strlen(field) != 4) return MP_EERROR;
	
	// make a copy of the given value to include it in the frame
	new_valuecp = xmallocd(len,
		      "id3_add_frame:new_valuecp");
	memcpy(new_valuecp, new_value, len);
	new_value = new_valuecp;

	/* make sync safe */
	len_sync = id3_sync(new_value, len);
	
	frame = XMALLOCD(id3v2_frame, "id3_add_frame:frame");
	frame->frame_id = xmallocd(4, "id3_add_frame:frame->frame_id");
	strncpy(frame->frame_id, field, 4);
	frame->data = new_value;
	frame->status_flag = 0;
	
	if(len != len_sync) frame->format_flag = 64;
	else frame->format_flag = 0;
	frame->data_size = len_sync;
	
	/* Empty list */
	if(!list->data)
	{
		list->data = frame;
		return 0;
	}
	
	/* iterate to last element */
	while(list->next) list = list->next;
	
	list->next = XMALLOCD(id3v2_frame_list, "id3_add_frame:list->next");
	list->next->start = list->start;
	list = list->next;
	list->next = NULL;
	list->data = frame;
	
	return 0;
}


#define BUF_SIZE 4096

static int
id3_lseek_syncword(int fd)
{
	unsigned char *data = (unsigned char*) xmallocd(BUF_SIZE, "id3_lseek_syncword:data");
	int ret;

	// Reset the reading offset of the fd
	lseek(fd, SEEK_SET, 0);

	if(read(fd, data, BUF_SIZE) < 1)
	{
		xfree(data);
		return 0; /* return false on EOF */
	}
	
	ret = id3_lseek_syncword_r(fd, data, 0);
	xfree(data);
	return ret;
}

static int
id3_lseek_syncword_r(int fd, unsigned char *data, int checked)
{
	unsigned char lastchar;
	int i;
	
	for(i = 0; i + 1 < BUF_SIZE; i++)
	{
		if(((data[i] & 0xFF)== 0xFF) && ((data[i+1] & 0xE0)== 0xE0))
		{
			lseek(fd, checked + i, SEEK_SET);
			return 0;
		}
	}
	
	lastchar = data[BUF_SIZE - 1];
	
	if(read(fd, data, BUF_SIZE) < 1) return 0; /* return false on EOF */
	
	if(((lastchar & 0xFF)== 0xFF) && ((data[0] & 0xE0)== 0xE0))
	{
		lseek(fd, checked + BUF_SIZE - 1, SEEK_SET);
		return 0;
	}
	
	return id3_lseek_syncword_r(fd, data, checked + BUF_SIZE);
}

static id3_tag* 
id3v1_alloc_tag(void)
{
	id3_tag *tag = XMALLOCD(id3_tag, "id3v1_alloc_tag:tag");
	id3v1_tag *v1 = XMALLOCD0(id3v1_tag, "id3v1_alloc_tag:v1");
	
	tag->tag = v1;
	tag->version = 1;
	
	v1->genre = 0xFF;
	
	return tag;
}

static id3_tag* 
id3v2_alloc_tag(void)
{
	id3_tag *tag = XMALLOCD(id3_tag, "id3v2_alloc_tag:tag");
	id3v2_tag *v2 = XMALLOCD0(id3v2_tag, "id3v2_alloc_tag:v2");
	
	tag->tag = v2;
	tag->version = 2;
	
	return tag;
}

static void
id3v1_free_tag(id3v1_tag* v1)
{
	xfree(v1->artist);
	xfree(v1->album);
	xfree(v1->title);
	xfree(v1->year);
	xfree(v1->comment);
	xfree(v1);
}

static void
id3v2_free_tag(id3v2_tag* v2)
{
	id3v2_frame_list* doomed;
	id3v2_frame *frame;

	if(!v2) return;
	
	xfree(v2->header->extended_header);
	xfree(v2->header);
	
	if(!v2->frame_list) 
	{
		xfree(v2);
		return;
	}
	
	/* Freeing frames */
	do
	{
		frame = (id3v2_frame*)v2->frame_list->data;
		if(frame->frame_id) xfree(frame->frame_id);
		if(frame->data) xfree(frame->data);
		xfree(v2->frame_list->data);

		doomed = v2->frame_list->next;
		xfree(v2->frame_list);
		
	} while((v2->frame_list = doomed));
	
	xfree(v2);
}
