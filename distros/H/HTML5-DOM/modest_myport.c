#include "modest_config.h"

// myport
#ifdef MyCORE_OS_WINDOWS_NT
	#include "third_party/modest/source/myport/windows_nt/mycore/io.c"
	#include "third_party/modest/source/myport/windows_nt/mycore/utils/mcsync.c"
	#include "third_party/modest/source/myport/windows_nt/mycore/memory.c"
	#include "third_party/modest/source/myport/windows_nt/mycore/thread.c"
	#include "third_party/modest/source/myport/windows_nt/mycore/perf.c"
#else
	#include "third_party/modest/source/myport/posix/mycore/io.c"
	
	#if MyCORE_USE_SEMAPHORE_INSTEAD_OF_MUTEX
		#include "port/openbsd/mcsync.c"
	#else
		#include "third_party/modest/source/myport/posix/mycore/utils/mcsync.c"
	#endif
	
	#include "third_party/modest/source/myport/posix/mycore/memory.c"
	#include "third_party/modest/source/myport/posix/mycore/thread.c"
	#include "third_party/modest/source/myport/posix/mycore/perf.c"
#endif
