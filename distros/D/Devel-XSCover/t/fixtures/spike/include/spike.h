#ifndef SPIKE_H
#define SPIKE_H

static inline int spike_square(int x)
{
    if (x < 0)
        x = -x;
    return x * x;
}

static inline int spike_only_helper(int x)
{
    return x + 1;
}

int spike_helper_switch(int n);

#endif
