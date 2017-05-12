#ifndef FTPPARSE_H
#define FTPPARSE_H

/* a replacement for daniel bernsteins ftpparse library. */

/*
 * ftpparse(&fp,buf,len) tries to parse one line of LIST output.
 *
 * The line is an array of len characters stored in buf.
 * It should not include the terminating CR LF; so buf[len] is typically CR.
 *
 * If ftpparse() can't find a filename, it returns 0.

 * If ftpparse() can find a filename, it fills in fp and returns 1.
 * fp is a struct ftpparse, defined below.
 * The name is an array of fp.namelen characters stored in fp.name;
 * fp.name points somewhere within buf.
 */

/* differences between Bernsteins and this version:
 * a) use tai, not time_t.
 * b) included format flag.
 * c) size is now an uint64 (was signed long).
 * d) added FTPPARSE_MTIME_REMOTESECOND: time zone is unknown, seconds known
 * e) much more formats understood.
 * f) much more picky about some details.
 * g) there's a function to parse MLSX.
 */
#include "tai.h"
#include "uint64.h"

struct ftpparse {
  char *name; /* not necessarily 0-terminated */
  unsigned int namelen;
  int flagtrycwd; /* 0 if cwd is definitely pointless, 1 otherwise */
  int flagtryretr; /* 0 if retr is definitely pointless, 1 otherwise */
  int sizetype;
  uint64 size; /* number of octets */
  int mtimetype;
  struct tai mtime; /* modification time */
  int idtype;
  char *id; /* not necessarily 0-terminated */
  unsigned int idlen;
  int format;
  int flagbrokenmlsx;
  char *symlink; /* 0: no symlink. !=0: offset to start of it */
  unsigned int symlinklen;
} ;

#define FTPPARSE_FORMAT_UNKNOWN 0
#define FTPPARSE_FORMAT_EPLF  1
#define FTPPARSE_FORMAT_MLSX  2
#define FTPPARSE_FORMAT_LS    3

#define FTPPARSE_SIZE_UNKNOWN 0
#define FTPPARSE_SIZE_BINARY 1 /* size is the number of octets in TYPE I */
#define FTPPARSE_SIZE_ASCII 2 /* size is the number of octets in TYPE A */

/*
 * When a time zone is unknown, it is assumed to be GMT. You may want
 * to use localtime() for LOCAL times, along with an indication that the
 * time is correct in the local time zone, and gmtime() for REMOTE* times.
 */
#define FTPPARSE_MTIME_UNKNOWN 0
#define FTPPARSE_MTIME_LOCAL 1 /* time is correct */
#define FTPPARSE_MTIME_REMOTEMINUTE 2 /* time zone and secs are unknown */
#define FTPPARSE_MTIME_REMOTEDAY 3 /* time zone and time of day are unknown */
#define FTPPARSE_MTIME_REMOTESECOND 4 /* time zone is unknown */

#define FTPPARSE_ID_UNKNOWN 0
#define FTPPARSE_ID_FULL 1 /* unique identifier for files on this FTP server */

extern int ftpparse(struct ftpparse *fp, char *buf,int len, 
  int eat_leading_spaces);
/* MLST listings start with a space */
extern int ftpparse_mlsx(struct ftpparse *fp, char *buf,int len, int is_mslt);

#endif
