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

#ifndef __MPLIB_H
#define __MPLIB_H


/* __BEGIN_DECLS should be used at the beginning of your declarations,
   so that C++ compilers don't mangle their names.  Use __END_DECLS at
   the end of C declarations. */
#undef __BEGIN_DECLS
#undef __END_DECLS
#ifdef __cplusplus
# define __BEGIN_DECLS extern "C" {
# define __END_DECLS }
#else
# define __BEGIN_DECLS /* empty */
# define __END_DECLS /* empty */
#endif

/* __P is a macro used to wrap function prototypes, so that compilers
   that don't understand ANSI C prototypes still work, and ANSI C
   compilers can issue warnings about type mismatches. */
#undef __P
#if defined (__STDC__) || defined (_AIX) \
        || (defined (__mips) && defined (_SYSTYPE_SVR4)) \
        || defined(WIN32) || defined(__cplusplus)
# define __P(protos) protos
#else
# define __P(protos) ()
#endif


__BEGIN_DECLS



/*************************************/
/*             Defines               */
/*************************************/

#define MP_ARTIST 1
#define MP_TITLE 2
#define MP_ALBUM 3
#define MP_GENRE 4
#define MP_COMMENT 5
#define MP_YEAR 6
#define MP_TRACK 7

#define ISO_8859_1 0
#define UTF16 1
#define UTF16BE 2
#define UTF8 3


/*************************************/
/*              errno values         */
/*************************************/
#define MP_EERROR 1
#define MP_EFNF 2
#define MP_EFCOMPR 3
#define MP_EFENCR 4
/*define MP_EUNICODE 5*/
#define MP_EVERSION 6


/*************************************/
/*        Structs and company        */
/*************************************/

/* Header structure with 4 segments containing 32 bit header information */
typedef struct _mpeg_header 
{
  unsigned int syncword; /* Sync Word */
  unsigned int version; /* Version number */
  unsigned int layer; /* Layer number */
  unsigned int protbit; /* Protection Bit */
  unsigned int bitrate; /* kbit/sec */
  unsigned int samplingfreq; /* hz */
  unsigned int padbit; /* Padding bit */
  unsigned int privbit; /* Private Bit */
  unsigned int mode; /* Stereo, Joint-Stereo, Dual-Channel, Mono */
  unsigned int mode_ext; /* Mode extension */
  unsigned int copyright; /* Copyright yes/no */
  unsigned int originalhome; /* Original datastream yes/no */
  unsigned int emphasis; /* Emphasis bits */
} mpeg_header;


/* Generic tag structure */
typedef struct _id3_tag
{
  int version; /* tags version, either 1 or 2 or -1 if not supported */
  void *tag; /* pointer to specific struct */
} id3_tag;


/* list of tags found in file */
typedef struct _id3_tag_list
{
  id3_tag *tag;
  struct _id3_tag_list *next;
  struct _id3_tag_list *first;
} id3_tag_list;


/*
 * The following structures are ment as low-level data holders. I strongly
 * suggest you to use the appropriate generic functions below to access them.
 */

/* V 1 */

/* ID3v1 tag structure */
typedef struct _id3v1_tag
{
  char *title;
  char *artist;
  char *album;
  char *year;
  char *comment;
  unsigned char track; /* track binary encoded */
  unsigned char genre; /* index on genre list - 0xFF for null */
} id3v1_tag;


/* V 2 */

/* ID3v2 Frame structure */
typedef struct _id3v2_frame
{
  char* frame_id; /* The frame id e.g. TALB */
  unsigned char status_flag;
  unsigned char format_flag;
  char *data;
  unsigned int data_size; /* frame size excluding header, incl. enc.,lang.,etc.
				  (total frame size - 10) */
} id3v2_frame;

/* single linked list referencing a number of frames */
typedef struct _id3v2_frame_list
{
  struct _id3v2_frame *data;
  struct _id3v2_frame_list *next;
  struct _id3v2_frame_list *start;
} id3v2_frame_list;

/* ID3v2 Extended Header structure */
typedef struct _id3v2_extended_header
{
  unsigned long size;
  char *flag_bytes;
  unsigned int no_flag_bytes;
  unsigned int is_update;
  unsigned int crc_data_present;
  unsigned char crc_data_length;
  unsigned char* crc_data;
  unsigned int restrictions;
  unsigned char restrictions_data_length;
  unsigned char* restrictions_data;
} id3v2_extended_header;

/* ID3v2 Header structure */
typedef struct _id3v2_header
{
  /* Version 2.minor.revision */
  unsigned int version_minor;
  unsigned int version_revision;
  char flags; /* Flags - should only be set by mplib and does only contain 
		   the following infos */
  unsigned int unsyncronization;
  unsigned int has_extended_header;
  unsigned int is_experimental;
  unsigned int has_footer;
  unsigned long total_tag_size; /* is size of all tag elements including 
				   header and footer (each 10 bytes) */
  id3v2_extended_header *extended_header;   /* Extended header */
} id3v2_header;


/* ID3v2 tag structure */
typedef struct _id3v2_tag
{
  id3v2_header *header;
  id3v2_frame_list *frame_list;
} id3v2_tag;

/* A fields content unparsed */
typedef struct _id3_content
{
  unsigned int compressed;
  unsigned int encrypted;
  char *data;
  unsigned int length;
} id3_content;

typedef enum _id3_encoding
{
  iso_8859_1 = ISO_8859_1,
  utf16 = UTF16,
  utf16be = UTF16BE,
  utf8 = UTF8
} id3_encoding;

typedef struct _id3_text_content
{
  id3_encoding encoding;
  char *text; /* Null terminated text */
} id3_text_content;

typedef struct _id3_comment_content
{
  id3_encoding encoding;
  char *language; /* ISO Language code */
  char *short_descr; /* Null term. content short description */
  char *text; /* Null terminated text */
} id3_comment_content;

typedef struct _id3_wxxx_content
{
  id3_encoding encoding;
  char *description;
  char *url;
} id3_wxxx_content;

/***************************************/
/*               Functions             */
/***************************************/

/* Gets the MPEG header structure from a file
 *  Arg 1   - The filename
 *  Returns - A pointer to a new initialized header structure - NULL on IO Error
 */
extern mpeg_header *mp_get_mpeg_header_from_file __P((const char*));


/* Gets the header structure from a file descriptor
 *  Arg 1   - The file descriptor
 *  Returns - A pointer to a new initialized header structure - NULL on IO Error 
 */
extern mpeg_header *mp_get_mpeg_header_from_fd __P((int));


/* Frees a mpeg header structure
 *  Arg 1   - The allocated mpeg header
 */
#define mp_free_mpeg_header(str) xfree(str)


/* Allocates a label with the appropriate header field value as a string */
extern char *mp_get_str_version __P((const mpeg_header*));
extern char *mp_get_str_layer __P((const mpeg_header*));
extern char *mp_get_str_bitrate __P((const mpeg_header*));
extern char *mp_get_str_samplingfreq __P((const mpeg_header*));
extern char *mp_get_str_mode __P((const mpeg_header*));


/* Allocates and fills a list of tags found in the given file. This list
 * will contain at least one and at most two tags or is NULL if no tags
 * have been found.
 *  Arg 1   - The files name/file descriptor to search for tags
 *  Returns - A pointer to a initialized list struct or null if no tags have
 *            been found
 */
extern id3_tag_list* mp_get_tag_list_from_file __P((const char*));
extern id3_tag_list* mp_get_tag_list_from_fd __P((int));


/* Frees a tag list beginning with the given element XXX */
extern void mp_free_list __P((id3_tag_list*));


/* Gets the first content found of a specified field in the given tag and
 * allocates a struct.
 *  Arg 1   - The tag
 *  Arg 2   - The fields identifier
 *
 * Returns    The new allocated content for the specified field or NULL
 * On NULL:  errno set to the following values
 *  MP_EERROR   - General failure: may occure on wrong usage, but should never happen
 *  MP_EFNF     - Field does not exists in tag /invalid identifier
 *  MP_EVERSION - Tag has a version set that is not supported by the library
 */
extern id3_content* mp_get_content __P((const id3_tag*, int));

/* It's posible that a tag has multiple ocurances of a field.
 * Use this function to get a specified field by position. The first
 * ocurance of the field in the tag is 0.
 * e.g.: To get the third comment in an id3v2 tag use
 * mp_get_content_at_pos(tag, MP_COMMENT, 2);
 *  Arg 1   - The tag
 *  Arg 2   - The fields identifier
 *  Arg 3   - The content position in the tag
 *  Returns - see mp_get_content
 */
extern id3_content* mp_get_content_at_pos __P((const id3_tag*, int, int));

/* Gets a custom fields content and allocates a struct. This function can
 * only be applied to ID3v2 tags. It will lookup a by the given identifier
 * and return its content.
 *  Arg 1   - The tag
 *  Arg 2   - The field names identifier e.g. ENCR
 *  Returns - see mp_get_content
 */ 
extern id3_content* mp_get_content_custom __P((const id3_tag*, const char*));

/* See mp_get_content_at_pos() and mp_get_content_custom()
 *  Arg 1   - The tag
 *  Arg 2   - The field names identifier e.g. ENCR
 *  Arg 3   - The content position in the tag
 *  Returns - see mp_get_content
 */ 
extern id3_content* mp_get_content_custom_at_pos __P((const id3_tag*, const char*, int));

/* Frees a content struct */
extern void mp_free_content __P((id3_content*));
extern void mp_free_text_content __P((id3_text_content*));
extern void mp_free_comment_content __P((id3_comment_content*));


/* Copys the value of a specified field into the given tag. The content
 * argument may be freed after using this function. The way a content
 * is represented in a tag depends from the tags version and kind of field.
 * I.e. it may be nessecary to represent a track number as a binary value in a v1
 * tag or to embeded it into a frame for a v2 tag. The caller just needs to
 * give the correct identifier with the value as a id3_content and to take
 * care of freeing the id3_content value afterwards.
 *  Arg 1   - The tag to edit
 *  Arg 2   - The fields identifier
 *  Arg 3   - The fields new content
 *  Returns - 0  success or one of the following errors
 *   MP_EERROR   - General failure: may occure on wrong usage, but should never happen
 *   MP_EFNF     - Field does not exists in tag /invalid identifier
 *   MP_EVERSION - Function isn't able to handle a tag of this version
 */
extern int mp_set_content __P((id3_tag*, int, id3_content*));
extern int mp_set_content_at_pos __P((id3_tag*, int, id3_content*, int));

/* Sets up a new custom field with the given value 
 *  Arg 1   - The tag to edit
 *  Arg 2   - The new fields name - A four chars upper case identifier e.g. ENCR
 *  Arg 3   - The fields new content
 *  Returns - See mp_set_content
 */ 
extern int mp_set_custom_content __P((id3_tag*, char*, id3_content*));
extern int mp_set_custom_content_at_pos __P((id3_tag*, char*, id3_content*, int));

/* Writes the tag to the specified file
 *  Arg 1   - The tag list to be added to file - may be NULL for deleting all tags
 *  Arg 2   - The files name/file descriptor
 *  Returns - 0 on success or one of the following errors
 *   MP_EERROR   - General failure: may occure on wrong usage, but should never happen
 *   MP_EVERSION - Function isn't able to handle a tag of this version
 */
extern int mp_write_to_file __P((const id3_tag_list*, const char*));
extern int mp_write_to_fd __P((const id3_tag_list*, int));

/* Deletes all tags in file
 *  Arg 1   - The filename of fd
 *  Return  - 0 on success
 */
extern int mp_del_tags_from_file __P((const char*));
extern int mp_del_tags_from_fd __P((int));

/* Deletes all tags in file with the specified version
 *  Arg 1   - The filename or fd
 *  Arg 2   - The version
 */
extern int mp_del_tags_by_ver_from_file __P((const char*, int));
extern int mp_del_tags_by_ver_from_fd __P((int, int));

/* Converts a tag to id3v1 or id3v2 tag format
 *  Arg 1   - The tag to be converted
 *  Returns - 0 on success or one of the following errors
 *   MP_EVERSION - Function isn't able to handle a tag of this version
 */
extern int mp_convert_to_v1 __P((id3_tag*));
extern int mp_convert_to_v2 __P((id3_tag*));

/* Checks wether the given value would be a valid v1 field
 *  Arg 1  - The field
 *  Arg 2  - The value
 *  Returns  - 0 if test failed
 */
extern int mp_is_valid_v1_value __P((int, char*));

/* Parses a content field
 *  Arg 1   - the content to parse
 *  Returns - A pointer to a new initialized structure suitable for the content
 *            or NULL
 * On NULL:  errno set to the following values
 *  MP_EERROR   - General failure: may occure on wrong usage, but should never happen
 *  MP_EFENCR   - The value for this field has been encrypted and can thus not be retrieved
 *  MP_EFCOMPR  - The value for this field has been compressed and can thus not be retrieved
 */
extern id3_text_content *mp_parse_artist __P((const id3_content*));
extern id3_text_content *mp_parse_title __P((const id3_content*));
extern id3_text_content *mp_parse_album __P((const id3_content*));
extern id3_text_content *mp_parse_year __P((const id3_content*));
extern id3_text_content *mp_parse_genre __P((const id3_content*));
extern id3_text_content *mp_parse_track __P((const id3_content*));
extern id3_text_content *mp_parse_text __P((const id3_content*));
extern id3_comment_content *mp_parse_comment __P((const id3_content*));

/* patched into by me */
extern id3_wxxx_content *mp_parse_wxxx __P((const id3_content*));

/* Assembles content from a comont text content
 *  Arg 1   - the text
 *  Arg 2   - the texts encoding (NULL)
 *  Returns - A pointer to a new initialized content structure
 */
extern id3_content *mp_assemble_text_content __P((const char*, id3_encoding));

/* Assembles content from a comment
 *  Arg 1   - the text
 *  Arg 2   - a short describtion to the text (NULL)
 *  Arg 3   - the texts encoding
 *  Arg 4   - the comments language (NULL)
 *  Returns - A pointer to a new initialized content structure
 */
extern id3_content *mp_assemble_comment_content __P((const char*, const char*, id3_encoding, const char*));

/* patched into by me */
extern id3_content *mp_assemble_wxxx_content __P((const char*, const char*, id3_encoding));

/* Gets a new allocated tag */
extern id3_tag* mp_alloc_tag __P((void));
extern id3_tag* mp_alloc_tag_with_version __P((int));

/* Frees tag struct */
extern void mp_free_tag __P((id3_tag *));

__END_DECLS

#endif /* __MPLIB_H */
