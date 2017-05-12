#define INET6
#define BUILD_MATCH
#define MODULE_DATATYPE int
#define MODULE_NAME "eui64"

#include "../module_iface.h"

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

ModuleDef _module = {
	.type			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IP6T_ALIGN(MODULE_DATATYPE),
	.size_uspace	= IP6T_ALIGN(MODULE_DATATYPE),
	.setup			= setup,
};

ModuleDef *init(void) {
	return(&_module);
}
/* vim: ts=4
 */
