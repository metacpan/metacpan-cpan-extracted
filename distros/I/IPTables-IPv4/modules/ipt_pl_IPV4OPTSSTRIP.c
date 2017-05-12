#define BUILD_TARGET
#define MODULE_DATATYPE int
#define MODULE_NAME "IPV4OPTSSTRIP"

#include "../module_iface.h"

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

ModuleDef _module = {
	.type			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IPT_ALIGN(sizeof(MODULE_DATATYPE)),
	.size_uspace	= IPT_ALIGN(sizeof(MODULE_DATATYPE)),
	.setup			= setup,
};

ModuleDef *init(void) {
	return(&_module);
}
/* vim: ts=4
 */
