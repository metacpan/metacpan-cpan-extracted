#define INET6
#define BUILD_TARGET
#define MODULE_DATATYPE void
#define MODULE_NAME "TRACE"

#include "../module_iface.h"

ModuleDef _module = {
	.type			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IP6T_ALIGN(0),
	.size_uspace	= IP6T_ALIGN(0),
};

ModuleDef *init(void) {
	return(&_module);
}

/* vim: ts=4
 */
