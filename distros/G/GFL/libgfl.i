%module GFL
%{
#include "libgfl.h"
GFL_RECT *new_Rect (GFL_INT32 x,GFL_INT32 y,GFL_INT32 w,GFL_INT32 h);
typedef unsigned long GFL_MEMALLOC;
void free_GflStruct(GFL_MEMALLOC *ptr);
%}
%include libgfl.h
%inline %{

void free_GflStruct(GFL_MEMALLOC *ptr)
{
	gflMemoryFree((void *)ptr);
}

GFL_FILE_INFORMATION *new_FileInformation()
{
	return (GFL_FILE_INFORMATION *)gflMemoryAlloc(sizeof(GFL_FILE_INFORMATION));
}
GFL_FORMAT_INFORMATION *new_FormatInformation()
{
	return (GFL_FORMAT_INFORMATION *)gflMemoryAlloc(sizeof(GFL_FORMAT_INFORMATION));
}

GFL_LOAD_PARAMS *new_LoadParams()
{
	return (GFL_LOAD_PARAMS *)gflMemoryAlloc(sizeof(GFL_LOAD_PARAMS));
}

GFL_SAVE_PARAMS *new_SaveParams()
{
	return (GFL_SAVE_PARAMS *)gflMemoryAlloc(sizeof(GFL_SAVE_PARAMS));
}

GFL_RECT *new_Rect (GFL_INT32 x,GFL_INT32 y,GFL_INT32 w,GFL_INT32 h)
{
	GFL_RECT rect;
	GFL_RECT *rectPtr;
	rect.x = x;
	rect.y = y;
	rect.w = w;
	rect.h = h;
	rectPtr = (GFL_RECT *)gflMemoryAlloc(sizeof(GFL_RECT));
	return (GFL_RECT *)memmove( rectPtr, &rect, sizeof(GFL_RECT));
}

GFL_BITMAP **new_BitmapPtr()
{
	return (GFL_BITMAP **)gflMemoryAlloc(sizeof(GFL_BITMAP *));
}

GFL_BITMAP *addr_of_Bitmap(GFL_BITMAP **bitmap)
{
	return *bitmap;
}

%}
