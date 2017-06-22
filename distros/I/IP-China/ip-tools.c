#include <stdio.h>
#include <stdlib.h>

#include "ip-tools.h"

#ifdef HEADER

/* '0.0.0.0' is not a valid IP address, so this uses the value 0 to
   indicate an invalid IP address. */

#define INVALID_IP 0
#define NOTFOUND -1

typedef struct {
    unsigned start;
    unsigned end;
}
ip_block_t;

#endif /* HEADER */

/* Convert the character string in "ip" into an unsigned integer.

   This assumes that an unsigned integer contains at least 32 bits. */

unsigned int ip_tools_ip_to_int (const char * ip)
{
    /* The return value. */
    unsigned v = 0;
    /* The count of the number of bytes processed. */
    int i;
    /* A pointer to the next digit to process. */
    const char * start;

    start = ip;
    for (i = 0; i < 4; i++) {
        /* The digit being processed. */
        char c;
        /* The value of this byte. */
        int n = 0;
        while (1) {
            c = * start;
            start++;
            if (c >= '0' && c <= '9') {
                n *= 10;
                n += c - '0';
            }
            /* We insist on stopping at "." if we are still parsing
               the first, second, or third numbers. If we have reached
               the end of the numbers, we will allow any character. */
            else if ((i < 3 && c == '.') || i == 3) {
                break;
            }
            else {
                return INVALID_IP;
            }
        }
        if (n >= 256) {
            return INVALID_IP;
        }
        v *= 256;
        v += n;
    }
    return v;
}

/* Search for "ip" in the structure "ip_blocks". "n_ip_ranges" is the
   total number of members in "ip_blocks". */

int ip_tools_ip_range (ip_block_t * ip_blocks, int n_ip_ranges, unsigned ip)
{
    int i;
    int division;
    int count = 0;

    division = n_ip_ranges / 2;
    i = division;
    while (1) {
        count++;
        if (count > 100) {
            /* Trap for possible errors. 2^100 should be big
               enough. */
            fprintf (stderr, "There is bad logic in the search.\n");
            return NOTFOUND;
        }
        division /= 2;
        if (division == 0) {
            division = 1;
        }
        // printf ("i is %d/%d; Division is %d\n", i, n_ip_ranges, division);
        if (ip >= ip_blocks[i].start) {
            if (ip <= ip_blocks[i].end) {
                /* "ip" is between the start and end of block i. */
                return i;
            }
            else if (ip < ip_blocks[i + 1].start) {
                /* "ip" is between the end of block i and the start of
                    block i+1 */
                return NOTFOUND;
            }
            else {
                /* Go up a bit and continue searching. */
                i += division;
            }
        }
        else {
            /* Go down a bit and continue searching. */
            i -= division;
        }
        if (i > n_ip_ranges - 1 || i < 0) {
            /* "i" has gone outside the boundaries. */
            return NOTFOUND;
        }
    }
}

