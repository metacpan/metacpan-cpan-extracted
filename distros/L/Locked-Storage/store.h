typedef struct
{
    int   nSize;     /* Number of pages requested */
    int   nBytes;    /* Number of bytes available */
    int   sBytes;    /* Stored bytes */
    int   nPageSize; /* Page size in bytes */
    char *pBytes;    /* pointer to available memory */
    int   memLocked;     /* mlock() has been called on a specific memory region */
    int   processLocked; /* mlockall() has been called */
} AddressRegion;

extern AddressRegion *new      (int nSize);
extern void           DESTROY  (AddressRegion *pAddressRegion);
extern void           dump     (AddressRegion *pAddressRegion);
extern int            store    (AddressRegion *pAddressRegion, char *data, int len);
extern char          *get      (AddressRegion *pAddressRegion);
extern int            lockall  (AddressRegion *pAddressRegion);
