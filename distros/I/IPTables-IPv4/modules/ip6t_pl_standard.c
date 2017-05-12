#define INET6
#define BUILD_TARGET
#define MODULE_DATATYPE int
#define MODULE_NAME "standard"

#include "../module_iface.h"

ModuleDef _module = {
	.type			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IP6T_ALIGN(sizeof(MODULE_DATATYPE)),
	.size_uspace	= IP6T_ALIGN(sizeof(MODULE_DATATYPE)),
};

ModuleDef *init(void) {
	return(&_module);
}
/* vim: ts=4
 */
