#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include "tables.h"

uint tab[33][33], freq[33];

void decode(uchar *, size_t);

main()
{
  size_t len;
  uchar *str;
  int rus=28, cur, i, j, prev;

  for (i=0; i<33; i++)
  {
    freq[i]=0;
    for (j=0; j<33; j++)
      tab[i][j]=0;
  }
  
  while (str=fgetln(stdin, &len))
    for (prev=0; len; len--)
    {
      cur=ord[str[len]];
      if (cur > rus) rus=33;
      if (!prev && !cur)
        continue;
      tab[cur][prev]++;
      freq[prev]++;
      prev=cur;
    }
  tab[0][0]=freq[0];
  for (i=0; i<rus; i++)
  {
    for (j=0; j<rus; j++)
      printf(" %-15.12f", ((double)tab[i][j])/freq[i]);
      //printf(" %-.12g", ((double)tab[i][j])/freq[i]);
    printf("\n");
  }
}

