/* Copyright 2012 Kevin Ryde

   This file is part of Math-NumSeq.

   Math-NumSeq is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3, or (at your option) any later
   version.

   Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
   more details.

   You should have received a copy of the GNU General Public License along
   with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.  */

/* A033909 - steps or -1 if infinite
   A033861 - seq of 316
   A033863 - first of length n
   A033909 - sort add count steps to sorted
   A033908 - first of length n

   ./exe-sortadd 10 65 64 175 98 240 325 302 387 198 180 550 806 855

   */
#define _GNU_SOURCE

#define DEBUG 0
#if ! DEBUG
#define NDEBUG
#endif

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>


#define LIKELY(cond)    __builtin_expect ((cond) != 0, 1)
#define UNLIKELY(cond)  __builtin_expect ((cond) != 0, 0)

char *numstr = "316"; /* default */
char *filename;
char *tmpname;

#define DIGITS_MAX 32768

static struct {
  unsigned long long count;
  int digits_len;
  int digits[DIGITS_MAX];
} state;

void
dump (void)
{
  for (int i = state.digits_len-1; i >= 0; i--) {
    printf ("%d,", state.digits[i]);
  }
  printf ("\n");
}

void
save (void)
{
  FILE *fp = fopen (tmpname, "w");
  if (! fp) {
    printf ("Cannot write %s\n", tmpname);
    perror ("fopen");
    abort();
  }
  if (fwrite(&state, sizeof(state), 1, fp) != 1) {
    perror ("fwrite");
    abort();
  }
  if (fclose(fp) != 0) {
    perror ("fclose");
    abort();
  }
  if (rename (tmpname, filename) < 0) {
    printf ("Cannot rename %s to %s\n", tmpname, filename);
    perror ("rename");
    abort();
  }
  printf ("save count %Lu len %d\n", state.count, state.digits_len);
}

void
load (void)
{
  FILE *fp = fopen (filename, "r");
  if (! fp) {
    printf ("new state\n");
    state.count = 0;
    state.digits_len = strlen(numstr);
    for (int i = 0; i < state.digits_len; i++) {   /* high to low */
      char c = numstr[i];
      int n = c - '0';
      state.digits[state.digits_len-1 - i] = n;  /* low to high */
    }
    printf ("initial: ");
    dump();
    return;
  }
  if (fread(&state, sizeof(state), 1, fp) != 1) {
    perror ("fread");
    abort();
  }
  if (fclose(fp) != 0) {
    perror ("fclose");
    abort();
  }
  printf ("load state, count %Lu len %d\n", state.count, state.digits_len);
}

int
is_sorted (void)
{
  int prev = state.digits[0];
  int i;
  for (i = 1; i < state.digits_len; i++) {
    int d = state.digits[i];
    if (d > prev) {
      return 0;
    }
    prev = d;
  }
  return 1;
}

void
iterate (void)
{
  time_t prevt = time(NULL);
  int digits_len = state.digits_len;
  
  if (is_sorted()) {
    printf ("len %d count %Lu\n", state.digits_len, state.count);
    printf ("already sorted: ");
    dump();
    exit(0);
  }

  for (;;) {
    if (UNLIKELY ((state.count & 0xFFFF) == 0)) {
      time_t newt = time(NULL);
      if (newt != prevt) {
        prevt = newt;
        save();
      }
    }
        
    if (DEBUG) {
      int i;
      printf ("at count=%Lu len=%d: ", state.count, state.digits_len);
      for (i = state.digits_len-1; i >= 0; i--) {
        printf ("%d,", state.digits[i]);
      }
      printf ("\n");
    }

    state.count++;

    static int bucket[10];
    bucket[0] = 0;
    bucket[1] = 0;
    bucket[2] = 0;
    bucket[3] = 0;
    bucket[4] = 0;
    bucket[5] = 0;
    bucket[6] = 0;
    bucket[7] = 0;
    bucket[8] = 0;
    bucket[9] = 0;
    /* memset (bucket, 0, sizeof(int)*10); */
    for (int i = 0; i < digits_len; i++) {
      bucket[(int) state.digits[i]]++;
    }

    {
      int carry = 0;
      int i = 0;
      int prev_d = 10;
      int sorted = 1;
      for (int b = 9; LIKELY (b >= 0); b--) {
        int count = bucket[b];
        while (LIKELY (count--)) {
          int d = state.digits[i] + b - carry;
          carry = ((9 - d) >> 5); /* 0 or -1 */
          assert (carry == 0 || carry == -1);

          d -= (carry & 10);
          assert (d >= 0 && d < 10);

          state.digits[i] = d;
          sorted &= (d - prev_d - 1) >> 5; /* -1 if d smaller or equal */
          prev_d = d;
          i++;
        }
      }
      if (UNLIKELY(carry)) {
        digits_len++;
        state.digits_len++;
        if (UNLIKELY (digits_len > DIGITS_MAX)) {
          printf ("DIGITS_MAX exceeded\n");
        }
        state.digits[digits_len-1] = -carry;
        printf ("len %d at count %Lu\n", state.digits_len , state.count);
      }

      if (UNLIKELY(sorted)) {
        save();
        printf ("now sorted: ");
        dump();
        printf ("len %d count %Lu\n", state.digits_len, state.count);
        return;
      }
    }

  }
}

void
one (void)
{
  printf ("----------\n");
  if (asprintf (&filename, "/z/state/exe-sortadd.%s", numstr) < 0) {
    perror ("asprintf");
    abort();
  }
  if (asprintf (&tmpname, "%s.tmp", filename) < 0) {
    perror ("asprintf");
    abort();
  }
  printf ("filename %s\n", filename);
  printf ("tmpname %s\n", tmpname);
  load();
  iterate();
}

int
main (int argc, char **argv)
{
  if (nice(20) < 0) {
    perror("nice");
    abort();
  }
  if (argc > 1) {
    for (int i = 1; i < argc; i++) {
      numstr = argv[i];
      one();
    }
  } else {
    one();
  }

  return 0;
}


  /* char *sorted = xmalloc(digits_len); */
    /* memcpy (sorted, digits, digits_len); */
    /* qsort (sorted, digits_len, 1, char_cmp); */

    /* if (DEBUG) { */
    /*   int i; */
    /*   printf ("sorted: "); */
    /*   for (i = digits_len-1; i >= 0; i--) { */
    /*     printf ("%d,", sorted[i]); */
    /*   } */
    /*   printf ("\n"); */
    /* } */
            
    /* { */
    /*   int carry = 0; */
    /*   size_t i; */
    /*   for (i = 0; i < digits_len; i++) { */
    /*     int d = digits[i] + sorted[i] + carry; */
    /*     carry = (d >= 10); */
    /*     d -= (-carry) & 10; */
    /*     digits[i] = d; */
    /*   } */
    /*   if (carry) { */
    /*     digits = xrealloc(digits,++digits_len); */
    /*     sorted = xrealloc(sorted,digits_len); */
    /*     digits[digits_len-1] = carry; */
    /*     printf ("len %d\n", digits_len); */
    /*   } */
    /* } */

/* char * */
/* xmalloc (size_t len) */
/* { */
/*   char *p = malloc(len); */
/*   if (! p) { */
/*     printf ("Out of memory\n"); */
/*     abort(); */
/*   } */
/*   return p; */
/* } */
/*  */
/* inline */
/* char * */
/* xrealloc (char *p, size_t len) */
/* { */
/*   p = realloc(p,len); */
/*   if (! p) { */
/*     printf ("Out of memory\n"); */
/*     abort(); */
/*   } */
/*   return p; */
/* } */
/*  */
/* int */
/* char_cmp (const void *p, const void *q) */
/* { */
/*   char pc = * (char*) p; */
/*   char qc = * (char*) q; */
/*   if (pc > qc) { */
/*     return -1; */
/*   } */
/*   if (pc < qc) { */
/*     return 1; */
/*   } */
/*   return 0; */
/* } */

