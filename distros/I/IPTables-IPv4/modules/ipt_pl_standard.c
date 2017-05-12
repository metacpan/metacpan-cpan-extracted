#define BUILD_TARGET
#define MODULE_DATATYPE int
#define MODULE_NAME "standard"

#include "../module_iface.h"

ModuleDef _module = {
	.type			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IPT_ALIGN(sizeof(MODULE_DATATYPE)),
	.size_uspace	= IPT_ALIGN(sizeof(MODULE_DATATYPE)),
};

ModuleDef *init(void) {
	return(&_module);
}
/* vim: ts=4
 */
