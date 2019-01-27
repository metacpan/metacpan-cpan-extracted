#include "store.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h> /* for mlock/munlock */
#include <unistd.h>
#include <string.h>

AddressRegion *new(int nSize)
{
    AddressRegion *pAddressRegion = (AddressRegion *) malloc(sizeof (AddressRegion));
    pAddressRegion->nSize = nSize;
    pAddressRegion->nPageSize = getpagesize();

    pAddressRegion->nBytes = (nSize * pAddressRegion->nPageSize * sizeof(char));

    pAddressRegion->pBytes = (char *) malloc(pAddressRegion->nBytes); /* Allocate it */
    mlock(pAddressRegion->pBytes, pAddressRegion->nBytes); /* lock it to memory */
    memset(pAddressRegion->pBytes, 0, pAddressRegion->nBytes); /* clear it, this will stop copy on write as well */
    pAddressRegion->sBytes = 0;
    pAddressRegion->processLocked = 0;
    pAddressRegion->memLocked = 1;

    return pAddressRegion;
}

void DESTROY(AddressRegion *pAddressRegion)
{
    memset(pAddressRegion->pBytes, 0, pAddressRegion->nBytes); /* clear it before releasing it */
    pAddressRegion->sBytes = 0;
    if (pAddressRegion->memLocked)
        munlock(pAddressRegion->pBytes, pAddressRegion->nBytes); /* unlock it */
    if (pAddressRegion->processLocked)
        munlockall();
    free(pAddressRegion->pBytes); /* free it */
    free(pAddressRegion);
}

void dump(AddressRegion *pAddressRegion)
{
    int i;
    char *p;
    char *b = (char *)malloc(65);

    p=b;

    for (i=0; i<pAddressRegion->nBytes; i++)
    {
        if (!(i % 16))
        {
            if (i)
            {
                fprintf(stderr, " %s\n%2d\t", b, i);
                memset(b, 0, 65);
                p=b;
            } else {
                fprintf(stderr, "%2d\t", i);
                memset(b, 0, 65);
            }
        } else if (!(i % 8)) {
            fprintf(stderr, " ");
            *p++ = ' ';
        }
        fprintf(stderr, "%02x ", pAddressRegion->pBytes[i]);
        if ((pAddressRegion->pBytes[i]) > 31 && (pAddressRegion->pBytes[i]) < 127)
                *p++ = (pAddressRegion->pBytes[i]);
        else
                *p++ = '.';
    }
    fprintf(stderr, " %s\n", b);
    free(b);
}

char *get(AddressRegion *pAddressRegion)
{
    return pAddressRegion->pBytes;
}

int store(AddressRegion *pAddressRegion, char *data, int len)
{
        if (len > pAddressRegion->nBytes)
                return 0;
        memcpy(pAddressRegion->pBytes, data, (size_t) len);
        pAddressRegion->sBytes = len;
        return 1;
}

int unlockall(AddressRegion *pAddressRegion)
{
    if (pAddressRegion->processLocked)
    {
        munlockall(); /* unlock the process */
        if (pAddressRegion->memLocked)
            mlock(pAddressRegion->pBytes, pAddressRegion->nBytes); /* relock it to memory */
        pAddressRegion->processLocked = 0;
    }
}

int lockall(AddressRegion *pAddressRegion)
{
    int r;
    r = mlockall(MCL_CURRENT | MCL_FUTURE); /* Lock everything now and future */
    if (!r)
        pAddressRegion->processLocked = 1; /* Record that it's locked if it succeeded */
    return r;
}
