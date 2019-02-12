#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "store.h"

typedef AddressRegion *Locked__Storage;

MODULE = Locked::Storage		PACKAGE = Locked::Storage		

PROTOTYPES: ENABLE

Locked::Storage
new(package, nSize = 0)
	char *package
	int   nSize;
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

int
unlockall(pAddressRegion)
	Locked::Storage pAddressRegion

int
is_locked(pAddressRegion)
	Locked::Storage pAddressRegion

int
process_locked(pAddressRegion)
	Locked::Storage pAddressRegion

int
initialize(pAddressRegion)
	Locked::Storage pAddressRegion

int
set_pages(pAddressRegion, pages)
	Locked::Storage pAddressRegion
	int	 pages

int
set_size(pAddressRegion, bytes)
	Locked::Storage pAddressRegion
	int	 bytes

int
pagesize(pAddressRegion)
	Locked::Storage pAddressRegion

