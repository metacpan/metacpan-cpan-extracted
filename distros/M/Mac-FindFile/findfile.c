
/* findfile.c

   Created by John Chang on 2007-06-18. 
   This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
   http://creativecommons.org/licenses/publicdomain/
   Adapted for SWIG by Kevin Walzer/WordTech Communications LLC, (c) 2015.*/

#include "findfile.h"

void find_file(char *query, char * volumeRoot)
{
  OSErr err;
  char* s = "/tmp/mac_findfile_output.txt";
 	
  if (volumeRoot == NULL)
    volumeRoot = "/";
	
  FSRef container;
  err = FSPathMakeRef((const UInt8 *) volumeRoot, &container, NULL);
  if (err == fnfErr) {
      fprintf(stderr, "No such volume '%s'\n", volumeRoot);
      return;
    }
  assert(err == noErr);

  FSIterator iterator;
  err = FSOpenIterator(&container, kFSIterateSubtree, &iterator);
  assert(err == noErr);

  CFStringRef searchquery;
  searchquery = CFStringCreateWithCString(kCFAllocatorDefault,
					  query, kCFStringEncodingUTF8);

  FSSearchParams searchParams = {};
  searchParams.searchBits = fsSBPartialName;
  searchParams.searchNameLength = CFStringGetLength(searchquery);
  searchParams.searchName = (UniChar *)malloc(searchParams.searchNameLength * sizeof(UniChar));
  CFStringGetCharacters(searchquery, CFRangeMake(0, searchParams.searchNameLength), searchParams.searchName);

  long pathMaxLength = pathconf(volumeRoot, _PC_PATH_MAX);
  char *utf8Path = (char *)malloc( (pathMaxLength + 1) * sizeof(char));

  assert(err == noErr || err == errFSNoMoreItems);


  /* Call FSCatalogSearch until the iterator is exhausted. */
  ItemCount maximumObjects = 1; 
  while (err != errFSNoMoreItems) {
      ItemCount count;
				
      FSRef refs[maximumObjects];
      err = FSCatalogSearch(iterator, &searchParams, maximumObjects, &count, NULL, kFSCatInfoNone, NULL, refs, NULL, NULL);

      int i;
      for (i=0; i<count; i++)
	{
	  FSRef ref = refs[i];
	  err = FSRefMakePath(&refs[i], utf8Path, pathMaxLength);
	  FILE *f;
	  f = fopen(s, "a");
	  fprintf(f, "%s\n", utf8Path);
	  fclose(f);
	}
    }


  CFRelease(searchquery);
  free((void *)searchParams.searchName);
  free(utf8Path);
	
  FSCloseIterator(iterator);
}

