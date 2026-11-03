#include "spike.h"

int spike_helper_switch(int n)
{
    switch (n) {
    case 0:
        return spike_only_helper(0);
    case 1:
        return 10;
    case 2:
        return 20;
    default:
        return spike_square(n);
    }
}
