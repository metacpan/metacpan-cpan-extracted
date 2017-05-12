#ifndef __TIMECONV_H
#define __TIMECONV_H

#include "common.h"

#include <time.h>

#ifdef __cplusplus
extern "C" {
#endif
time_t FileTimeToUnixTime( const FILETIME *filetime, DWORD *remainder );
#ifdef __cplusplus
}
#endif

#endif
