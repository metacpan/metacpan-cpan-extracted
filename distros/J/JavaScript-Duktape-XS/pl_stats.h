#ifndef PL_STATS_H
#define PL_STATS_H

#include "pl_duk.h"

typedef struct Stats {
    double t0, t1;
    double m0, m1;
} Stats;

void pl_stats_start(pTHX_ Duk* duk, Stats* stats);
void pl_stats_stop(pTHX_ Duk* duk, Stats* stats, const char* name);

#endif
