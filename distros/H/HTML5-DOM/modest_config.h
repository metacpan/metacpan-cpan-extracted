#define _BSD_SOURCE 1
#define _POSIX_C_SOURCE 199309L

#if (defined(_WIN32) || defined(_WIN64))
	#define MyCORE_OS_WINDOWS_NT
#endif
