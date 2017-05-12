/* -*- c -*- 
 * File: loadfile.h
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Thu Sep  8 17:16:48 2005
 *
 * $Id$
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef USE_MMAP

#ifdef WIN32
/* 
 * the win32 code of Viacheslav Sheveliov <slavash@aha.ru>
 * viy: should work for win64 too.
 */

#include <windows.h>
#include <stdio.h>

static PSTRING mmap_load_file(const char *filepath) {
        PSTRING memarea = { NULL, NULL };
        HANDLE hFile, hMapObject = NULL;

        hFile = CreateFile(
                TEXT(filepath), 
                GENERIC_READ, 
                FILE_SHARE_READ, 
                NULL,                      
                OPEN_EXISTING, 
                FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, 
                NULL
        );

        if (hFile != INVALID_HANDLE_VALUE) {
                hMapObject = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL);

                if (hMapObject) {
                        // Get a pointer to the file-mapped shared memory.
                        LPCTSTR lpvMem = (LPTSTR) MapViewOfFile(hMapObject, FILE_MAP_READ, 0, 0, 0);

                        if (lpvMem) {       
                                // Everything OK!

                                memarea.begin = (char *) lpvMem;
                                memarea.endnext = memarea.begin + GetFileSize(hFile, NULL);
                                // After MapViewOfFile we don't need file handles no more.
                                // Undocumented, but it works! (In read-only mode?)
                                CloseHandle(hMapObject);
                                CloseHandle(hFile);

                                return memarea;

                        }
                }
        }

        // Something goes wrong

        {
                // Save last error code, before any system call
                DWORD dwLastError = GetLastError();

                // Report error, if file size != 0
                // Mapping of zero-length file cause CreateFileMapping to fail.
                // So skip error messages in this case.
                if (hFile == INVALID_HANDLE_VALUE && GetFileSize(hFile, NULL) != 0)
                        fprintf(stderr, "Could not open file '%s'. (system error#%ld)\n", filepath, dwLastError);

        }
        // Close all opened handles
        if (hMapObject) CloseHandle(hMapObject);
        if (hFile != INVALID_HANDLE_VALUE) CloseHandle(hFile);  

        return memarea;
}

/* we use function, not define, because someday we may need its address */
static int mmap_unload_file(PSTRING memarea) { return UnmapViewOfFile((void*) memarea.begin) ? 0 : -1; };
/* define mmap_unload_file(map) (UnmapViewOfFile((LPCVOID) map.begin) ? 0 : -1) */

#else /* unix, sweet unix :) */
#if defined(HAVE_SYS_MMAN_H) && defined(HAVE_SYS_STAT_H)

/* # define NULL 0 */
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>  /* open  */
#include <unistd.h> /* close */

static 
PSTRING 
mmap_load_file (const char* filepath) {
  int fd;
  struct stat st;
  size_t size_in_bytes;
  PSTRING memarea={NULL,NULL};
  fd = open(filepath, O_RDONLY);
  if (fd == -1) return memarea; /* {NULL,NULL} */
  fstat(fd, &st);
  size_in_bytes = st.st_size;
  /* mmap size_in_bytes+1 to avoid crash with empty file */
  memarea.begin = (char *) mmap(0, size_in_bytes+1,  PROT_READ,  MAP_SHARED, fd, 0);
  close(fd);
  memarea.endnext=memarea.begin+size_in_bytes;
  return memarea;
}

static 
int 
mmap_unload_file (PSTRING memarea) {
  /* destroying */
  return munmap((void *)memarea.begin, memarea.endnext-memarea.begin);
}

#endif /* UNIX */
#endif /* WIN32 */

#else 
/*
 * system seems to have no mmap ;
 * we use standard C buffered read
 */
#include <stdio.h> 
static 
PSTRING 
mmap_load_file (const char* filepath) {
  FILE *stream;
  size_t size_in_bytes=0;
  size_t realsize;
  size_t chunksize=4096;
  size_t memsize=chunksize;
  PSTRING memarea={NULL,NULL};
  char* writepoint;
  /* text mode for HTML::Template compatibility */
  stream = fopen(filepath, "r");
  if (stream == NULL) return memarea; /* {NULL,NULL} */
  /* mmap size_in_bytes+1 to avoid crash with empty file */
  memarea.begin=(const char*) malloc(memsize+1);
  writepoint=(char*)memarea.begin;

  while (1) {
    realsize=fread(writepoint, 1, chunksize, stream);
    size_in_bytes+=realsize;
    if (realsize==chunksize) {
      writepoint+=chunksize;
      if (size_in_bytes+chunksize>memsize) {
	memsize*=2;
	memarea.begin=(char*) realloc((char*)memarea.begin, memsize+1);
	writepoint=((char*)memarea.begin)+size_in_bytes;
      }
    } else {
      fclose(stream);
      memarea.endnext=memarea.begin+size_in_bytes;
      return memarea;
    }
  }
}

static 
int 
mmap_unload_file (PSTRING memarea) {
  /* destroying */
  free((char*)memarea.begin);
  return 0;
}

#endif /* USE_MMAP */
