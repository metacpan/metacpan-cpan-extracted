/*
 * mplib - a library that enables you to edit ID3 tags
 * Copyright (C) 2001,2002  Stefan Podkowinski
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; version 2.1.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <sys/types.h>
#include <stdio.h>
/* define XMALLOC_CHECK 1 */
#include "xmalloc.h"
#ifdef USE_GC
# include <gc.h>
# define malloc(str) GC_MALLOC(str)
#endif

#ifdef XMALLOC_CHECK
typedef struct _xdelem {
    void* alloced;
    void* freed;
    char* descrl;
    struct _xdelem* next;
} xdelem;

xdelem* first = NULL;
#endif

#define errmsg "mplib: Memory exhausted: Could not allocate %d bytes\n"

void *
xmalloc(size_t s)
{
    return xmallocd(s, NULL);
}

void *
xmallocd(size_t s, char* descrl)
{
  void *new = (void*)malloc(s);
#ifdef XMALLOC_CHECK
  xdelem* cur = (xdelem*)malloc(sizeof(xdelem));
  cur->next = NULL;
  cur->freed = NULL;
  cur->descrl = descrl;
#endif
  if(!new) fprintf(stderr, errmsg, s);

#ifdef XMALLOC_CHECK
  cur->alloced = new;
 exists:
  if(!first) first = cur;
  else {
      xdelem* last = first;
      do {
	  if(last->alloced == cur->alloced) {
	      last->freed = NULL;
	      last->descrl = descrl;
	      free(cur);
	      goto exists;
	  }
      } while(last->next && (last = last->next));
      last->next = cur;
  }
#endif

  return new;
}

void *
xmallocd0(size_t s, char* descr)
{
#ifdef XMALLOC_CHECK
    void *new = (void*)xmallocd(s, descr);
#else
    void *new = (void*)malloc(s);
#endif
    if(!new) fprintf(stderr, errmsg, s);
    else memset(new, 0, s);
    return new;
}

void *
xmalloc0(size_t s)
{
#ifdef XMALLOC_CHECK
  void *new = (void*)xmalloc(s);
#else
  void *new = (void*)malloc(s);
#endif
  if(!new) fprintf(stderr, errmsg, s);
  else memset(new, 0, s);
  return new;
}

void *
xrealloc(void * ptr, size_t s)
{
  void *new;

  if(!ptr) return xmalloc(s);

  new = (void*)realloc(ptr, s);
  if(!new) fprintf(stderr, errmsg, s);
  return new;
}

void
xfree(void* ptr) {
    if(!ptr) return;
#ifdef XMALLOC_CHECK
    if(first) {
	xdelem* el = first;
	do {
	    if(el->freed == ptr) {
		if(el->descrl)
		    printf("XMALLOC: (%s) memory allready freed\n", el->descrl);
		else
		    printf("XMALLOC: memory allready freed at %h\n", ptr);
		break;
	    }
	    if(el->alloced == ptr) {
		el->freed = ptr;
		break;
	    }
	} while(el->next && (el = el->next));
    }
#endif
    free(ptr);
}


#ifdef XMALLOC_CHECK
void
xprint_malloc_stat(void) {
    long kb_alloc = 0;
    long kb_freed = 0;
    long kb_used = 0;
    int count_used = 0;
    xdelem* el = first;

    if(!first) {
	puts("XMALLOC: No statistic available");
    }
    puts("xmalloc statistic:");
    do {	
	if(!el->freed) {
	    if(el->descrl && !strstr(el->descrl, "ignore")) 
		printf("%s (not freed)\n", el->descrl);
	    else if(!el->descrl) printf("%p (not freed)\n", el->alloced);
	} else {
	    //if(el->descrl) printf("%s (freed)\n", el->descrl);
	    //else printf("%p (freed)\n", el->alloced);
	}
    } while(el->next && (el = el->next));
}
#endif
