#ifndef COVER_H_
#define COVER_H_

/*
 * Handle a list of file names, and for each of them the set of lines in that
 * file that were actually executed.
 */

/* Needed for FILE declaration. */
#include <stdio.h>

/* for U32 */
#include  <EXTERN.h>
#include  <perl.h>
#include  "ppport.h"

/*
 * We will have one of these per sub, stored in a singly linked list.
 */
typedef struct SubCoverNode {
  char* sub;                  /* sub name */
  int line;                   /* sub first line */
  int phase;                  /* covered in phase */
  U32 hash;                   /* hash of the sub_name/line */
} SubCoverNode;

/*
 * A placeholder for the linked list with sub coverage information.
 */
typedef struct SubCoverList {
  SubCoverNode** list;
  unsigned int used;
  unsigned int size;
} SubCoverList;

/*
 * We will have one of these per file, stored in a singly linked list.
 */
typedef struct CoverNode {
  char* file;                 /* file name */
  U32            hash;        /* hash of the file_name */
  unsigned char* lines;       /* bit set with the "covered lines" */
  unsigned short alen;        /* current length of lines array */
  unsigned short bmax;        /* value of largest bit (line) seen so far */
  unsigned short bcnt;        /* number of different bits (lines) seen so far */
  SubCoverList subs;          /* subroutines in this file */
} CoverNode;

/*
 * A placeholder for the linked list with file coverage information.
 */
typedef struct CoverList {
  CoverNode** list;
  unsigned int used;
  unsigned int size;
} CoverList;

/*
 * Create a CoverList object.
 */
CoverList* cover_create(void);

/*
 * Destroy a CoverList object.
 */
void cover_destroy(CoverList* cover);

/*
 * Add an executed file:line to the CoverList; will create CoverNode
 * for file, if it doesn't already exist.
 */
void cover_add_covered_line(CoverList* cover, const char* file, U32 file_hash, int line, int phase);

/*
 * Add a file:line to the CoverList; will create CoverNode for file, if it
 * doesn't already exist.
 */
void cover_add_line(CoverList* cover, const char* file, U32 file_hash, int line);

/*
 * Dump all data to a given file stream.
 */
void cover_dump(CoverList* cover, FILE* fp);

/*
 * Same as the above, but for SubCoverList*
 */
void cover_sub_add_covered_sub(CoverList* cover, const char* file, U32 file_hash, const char* name, U32 name_hash, U32 line, int phase);
void cover_sub_add_sub(CoverList* cover, const char* file, U32 file_hash, const char* name, U32 name_hash, U32 line);

#endif
