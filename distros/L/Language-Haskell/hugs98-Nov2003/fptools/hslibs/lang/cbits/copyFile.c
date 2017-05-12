/*
 * Copying a file from 'A' to 'B'.
 */
#include "HsBase.h"
#ifdef _WIN32
#include <windows.h>
#endif
#include <string.h>

#ifndef _WIN32
/* re-use the system() implementation used by System.system */
extern HsInt systemCmd(HsAddr cmd);
#endif

HsInt
primCopyFile(char* from, char* to)
{
#ifndef _WIN32
  /* Don't even try to re-implement the functionality
     of cp(1) -- it would have been nice to have its
     functionality available as an API though..
  */
  char* stuff;
  char* ptr;
  int i;

  stuff = (char*)alloca(sizeof(char) * (strlen(from) + strlen(to) + 6));
  
  /* Construct the string: ("cp " ++ from ++ ' ':to) */
  strcpy(stuff, "cp "); /* It better be called 'cp' ! */
  i = 3;

  ptr = from;
  while (*ptr) {
    stuff[i++] = *ptr++;
  }
  stuff[i++] = ' ';
  
  ptr = to;
  while (*ptr) {
    stuff[i++] = *ptr++;
  }
  stuff[i] = '\0';

  return systemCmd(stuff);
#else
  return CopyFile(from,to,TRUE/*fail if exists*/);
#endif
}

#ifdef _WIN32
HsAddr primGetLastErrorString()
{
  LPVOID msgBuf;
  
  FormatMessageA( FORMAT_MESSAGE_ALLOCATE_BUFFER |
		  FORMAT_MESSAGE_FROM_SYSTEM |
		  FORMAT_MESSAGE_IGNORE_INSERTS,
		  NULL,
		  GetLastError(),
		  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
		  (LPSTR)&msgBuf,
		  0,
		  NULL);
  return msgBuf;
}

void
primLocalFree(HsAddr ptr)
{
  LocalFree((LPVOID)ptr);
}

#endif
