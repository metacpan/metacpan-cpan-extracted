/* CCov: off */

#include <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>

typedef void (*CCOV_HITS_T)(int *hitp, int *maxp);
typedef void (*CCOV_REPORT_T)(unsigned long build, char *testname, 
			      unsigned long now, FILE *out, int verbose);

#undef MAXFILES
#define MAXFILES 100

typedef struct {
  char *file;
  CCOV_HITS_T hits;
  CCOV_REPORT_T report;
} CC;

static int num_files = 0;
static CC FInfo[MAXFILES];

typedef int (*qsort_cmp_t) (void *, void *);
static int CCcmp(CC *i, CC *j)
{ return strcmp(i->file, j->file); }

void ccov_report_results()
{
  char timestr[30];
  char *testname;
  char *ccov_log;
  FILE *out;
  time_t now = time(0);
  int hits=0, total=0;
  int verbose=0;

  if (getenv("CCOV_VERBOSE")) verbose++;

  testname = getenv("REGRESSION_TEST");
  if (!testname) testname = "?FAKE";

  ccov_log = getenv("CCOV_LOG");
  if (!ccov_log) ccov_log = "/tmp/ccov.log";
  out = fopen(ccov_log, "a+");
  if (!out) { fprintf(stderr, "CCov: can't open '%s' (%d)", ccov_log); }

  {
    int fx;
    qsort(FInfo, num_files, sizeof(CC), (qsort_cmp_t) CCcmp);
    for (fx=0; fx < num_files; fx++) {
      int hit, max;
      CC *ccp = FInfo + fx;
      (*ccp->hits)(&hit, &max);
      hits += hit; total += max;
      (*ccp->report)(%BUILD%, testname, now, out, verbose);
    }
  }
  if (verbose) {
    fprintf(stderr, "------------------------------------------------------\n");
    fprintf(stderr, "TOTAL: hit %d out of %d cases\n", hits, total);
  }
  fclose(out);
}

void ccov_register_file(char *file, CCOV_HITS_T f1, CCOV_REPORT_T f2)
{
  if (num_files == 0) {
#ifndef NO_ATEXIT
    atexit(ccov_report_results);
#else
    /* must call it yourself! */
#endif
  }
  if (num_files == MAXFILES) { fprintf(stderr, "too many files\n"); abort(); }
  FInfo[num_files].file = file;
  FInfo[num_files].hits = f1;
  FInfo[num_files].report = f2;
  ++num_files;
}
