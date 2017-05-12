#ifndef __DICT_ZIP_LIB_H__
#define __DICT_ZIP_LIB_H__

#include <zlib.h>
#include <time.h>

#ifdef __cplusplus
extern "C"
{
#endif				/* __cplusplus */


#define DICT_CACHE_SIZE 5

typedef struct dictCache {
   int           chunk;
   char          *inBuffer;
   int           stamp;
   int           count;
} dictCache;

typedef struct dictData {
   int           fd;		/* file descriptor */
   const char    *start;	/* start of mmap'd area */
   const char    *end;		/* end of mmap'd area */
   unsigned long size;		/* size of mmap */
   
   int           type;
   char    *filename;
   z_stream      zStream;
   int           initialized;
   
   int           headerLength;
   int           method;
   int           flags;
   time_t        mtime;
   int           extraFlags;
   int           os;
   int           version;
   int           chunkLength;
   int           chunkCount;
   int           *chunks;
   unsigned long *offsets;	/* Sum-scan of chunks. */
   char    *origFilename;
   char    *comment;
   unsigned long crc;
   unsigned long length;
   unsigned long compressedLength;
   dictCache     cache[DICT_CACHE_SIZE];
} dictData;

dictData *dict_data_open( const char *filename, int computeCRC );
void dict_data_close( dictData *header );
void dict_data_read ( dictData *h, char *buffer, unsigned long start, unsigned long size);

#ifdef __cplusplus
}
#endif				/* __cplusplus */


#endif
