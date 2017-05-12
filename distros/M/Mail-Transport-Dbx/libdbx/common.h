#ifndef __COMMON_H
#define __COMMON_H

/* perl5.5.3 already has WORD as a #define somewhere: get rid of it */
#undef WORD

#ifndef _WIN32
    typedef unsigned int DWORD;
    typedef unsigned short int WORD;
    typedef unsigned char BYTE;
    typedef unsigned int UINT32;
#else
# include <Windows.h>
#endif

#pragma pack (1)

#ifndef _WIN32
#ifndef FILETIME_DEFINED
#define FILETIME_DEFINED
/* Win32 Filetime struct - copied from WINE */
typedef struct {
	unsigned int dwLowDateTime;
    unsigned int dwHighDateTime;
} FILETIME;
#endif /* _WIN32 */
#endif

#endif
