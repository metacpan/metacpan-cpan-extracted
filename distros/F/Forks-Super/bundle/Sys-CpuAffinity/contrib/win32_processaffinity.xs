#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <windows.h>
#include <winbase.h>

#if (_WIN32_WINNT < 0x0500) && (_WIN32_WINDOWS < 0x0490)
WINBASEAPI HANDLE WINAPI OpenThread(DWORD,BOOL,DWORD);
#endif




int win32_set_process_affinity(DWORD process_id, DWORD mask)
{
  HANDLE handle;
  BOOL result1;

  if (process_id <= 0) {
    process_id = GetCurrentProcessId();
  }
  handle = OpenProcess(0x0600, 0, process_id);

#ifdef DEBUG
	fprintf(stderr, "win32_set_process_affinity(%d,%d) called\n",
		process_id, mask);
	fprintf(stderr, "HANDLE(%d) IS %d.\n", (int) process_id, (int) handle);
#endif

  if (handle == NULL) {
    return 0;
  }
  result1 = SetProcessAffinityMask(handle, mask);

#ifdef DEBUG
	if (result1 == 0) {
		fprintf(stderr, "win32_set_process_affinity: Error %d\n", 
			GetLastError());
	}
	fprintf(stderr,"SetProcessAffinityMask(%d,0x%x) => %d\n",
		(int) handle, mask, (int) result1);
#endif

  CloseHandle(handle);
  return (int) result1;
}

int win32_get_process_affinity(DWORD process_id)
{
  DWORD_PTR procMask = 0;
  DWORD_PTR sysMask = 0;
  HANDLE handle;
  BOOL result1;

  if (process_id <= 0) {
    process_id = GetCurrentProcessId();
  }
  handle = OpenProcess(0x0400, 0, process_id);
  if (handle == NULL) {
    handle = OpenProcess(0x1000, 0, process_id);
  }
  if (handle == NULL) {
    return 0;
  }
  result1 = GetProcessAffinityMask(handle, &procMask, &sysMask);
#ifdef DEBUG
	fprintf(stderr, "win32_get_process_affinity(%d) called\n", process_id);
	fprintf(stderr, "HANDLE (%d) IS %d\n", (int) process_id, (int) handle);
	fprintf(stderr, "GetProcessAffinityMask(%d) => %d %d: %d\n",
		handle, procMask, sysMask, (int) result1);
	if (result1 == 0) {
		fprintf(stderr, "win32_get_process_affinity: %d\n", 
			GetLastError());
	}
#endif
  CloseHandle(handle);
  return (int) procMask;
}

MODULE = Sys::CpuAffinity        PACKAGE = Sys::CpuAffinity

int
xs_win32_getAffinity_proc(pid)
	int pid
	CODE:
		RETVAL = win32_get_process_affinity(pid);
	OUTPUT:
		RETVAL

int
xs_win32_setAffinity_proc(pid,mask)
	int pid
	int mask
	CODE:
		RETVAL = win32_set_process_affinity(pid,mask);
	OUTPUT:
		RETVAL


