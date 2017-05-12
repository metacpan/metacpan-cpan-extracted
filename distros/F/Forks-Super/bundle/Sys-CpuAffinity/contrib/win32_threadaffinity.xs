#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <windows.h>
#include <winbase.h>

#if (_WIN32_WINNT < 0x0500) && (_WIN32_WINDOWS < 0x0490)
WINBASEAPI HANDLE WINAPI OpenThread(DWORD,BOOL,DWORD);
#endif




int win32_set_thread_affinity(DWORD thread_id, DWORD mask)
{
  HANDLE handle;
  DWORD result1, result2;

  if (thread_id <= 0) {
    thread_id = GetCurrentThreadId();
  }
  handle = OpenThread(0x0060, 0, thread_id);

#ifdef DEBUG
	fprintf(stderr, "win32_set_thread_affinity(%d,%d) called\n",
		thread_id, mask);
	fprintf(stderr, "HANDLE (%d) IS %d.\n", (int) thread_id, (int) handle);
#endif

  if (handle == NULL) {
    return 0;
  }
  result1 = SetThreadAffinityMask(handle, mask);
  result2 = SetThreadAffinityMask(handle, mask);
#ifdef DEBUG
	fprintf(stderr,"SetThreadAffinityMask(%d,0x%x) => %d %d\n",
		(int) handle, mask, (int) result1, (int) result2);
	if (result1 == 0 || result2 == 0) {
	    fprintf(stderr, "win32_set_thread_affinity: Error %d\n", 
			GetLastError());
	}
#endif
  CloseHandle(handle);
  return (int) result1;
}

int win32_get_thread_affinity(DWORD thread_id)
{
  DWORD mask = 1;
  HANDLE handle;
  DWORD result1, result2, result3;

  if (thread_id <= 0) {
    thread_id = GetCurrentThreadId();
  }
  handle = OpenThread(0x0040, 0, thread_id);
  if (handle == NULL) {
    handle = OpenThread(0x0200, 0, thread_id);
  }
  if (handle == NULL) {
    fprintf(stderr, "could not obtain handle for thread id %d\n",
		thread_id);
    return 0;
  }
  result1 = SetThreadAffinityMask(handle, mask);
  result2 = SetThreadAffinityMask(handle, result1);
  result3 = SetThreadAffinityMask(handle, result1);
#ifdef DEBUG
	fprintf(stderr, "win32_get_thread_affinity(%d) called\n", thread_id);
	fprintf(stderr, "HANDLE (%d) IS %d\n", (int) thread_id, (int) handle);
	fprintf(stderr, 
	   "SetThreadAffinityMask(%d,[0x%x,0x%x,0x%x]) => 0x%x, 0x%x, 0x%x\n", 
	   (int) handle, mask, result1, result1, result1, result2, result3);
  if (result1 == 0 || result2 == 0 || result3 == 0) {
    fprintf(stderr, "win32_get_thread_affinity: %d\n", GetLastError());
  }
  if (result3 != result1) {
    fprintf(stderr, "win32_get_thread_affinity: %d != %d\n",
	    result1, result3);
  }
#endif
  CloseHandle(handle);
  return (int) result1;
}

MODULE = Sys::CpuAffinity        PACKAGE = Sys::CpuAffinity

int
xs_win32_getAffinity_thread(pid)
	int pid
	CODE:
		RETVAL = win32_get_thread_affinity(pid);
	OUTPUT:
		RETVAL

int
xs_win32_setAffinity_thread(pid,mask)
	int pid
	int mask
	CODE:
		RETVAL = win32_set_thread_affinity(pid,mask);
	OUTPUT:
		RETVAL



