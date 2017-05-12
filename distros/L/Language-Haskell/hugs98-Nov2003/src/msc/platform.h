/*
 * configure-sussed platform #defines.
 */
#ifndef __PLATFORM_H__
#define __PLATFORM_H__

#define HostPlatform   i386_unknown_msvc
#define TargetPlatform i386_unknown_msvc
#define BuildPlatform  i386_unknown_msvc

/* Definitions suitable for use in CPP conditionals */
#define i386_unknown_msvc_HOST 1
#define i386_unknown_msvc_TARGET 1
#define i386_unknown_msvc_BUILD   1

#define i386_HOST 1
#define i386_TARGET 1
#define i386_BUILD 1

#define msvc_HOST_OS 1
#define msvc_TARGET_OS 1
#define msvc_BUILD_OS 1

#endif /* __PLATFORM_H__ */
