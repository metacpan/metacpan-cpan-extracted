#define BUILD_MATCH
#define MODULE_DATATYPE void
#define MODULE_NAME "unclean"

#include "../module_iface.h"

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

ModuleDef _module = {
	.type			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IPT_ALIGN(0),
	.size_uspace	= IPT_ALIGN(0),
	.setup			= setup,
};

ModuleDef *init(void) {
	return(&_module);
}
/* vim: ts=4
 */
