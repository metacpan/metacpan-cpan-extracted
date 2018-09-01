#ifndef PL_STATS_H
#define PL_STATS_H

#include "V8Context.h"

struct Perf {
    double t0, t1;
    double m0, m1;
};

void pl_stats_start(pTHX_ V8Context* ctx, Perf* perf);
void pl_stats_stop(pTHX_ V8Context* ctx, Perf* perf, const char* name);

#endif
