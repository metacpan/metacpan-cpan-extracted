#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "store.h"

typedef AddressRegion *Locked__Storage;

MODULE = Locked::Storage		PACKAGE = Locked::Storage		

PROTOTYPES: ENABLE

Locked::Storage
new(package, nSize)
	char *package
	int   nSize
	CODE:
	RETVAL = new(nSize);
	OUTPUT:
	RETVAL

void 
DESTROY(pAddressRegion)
	Locked::Storage pAddressRegion

void 
dump(pAddressRegion)
	Locked::Storage pAddressRegion

char *
get(pAddressRegion)
	Locked::Storage pAddressRegion

int
store(pAddressRegion, data, len)
	Locked::Storage pAddressRegion
	int	 len
	char	*data

int
lockall(pAddressRegion)
	Locked::Storage pAddressRegion

void
unlockall(pAddressRegion)
	Locked::Storage pAddressRegion

