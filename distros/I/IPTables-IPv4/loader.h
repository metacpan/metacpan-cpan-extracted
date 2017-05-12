#include "module_iface.h"
#include "local_types.h"

#define STD_TARGET "standard"
#define MATCH_RAW_POSTFIX "-match-raw"
#define TARGET_RAW_POSTFIX "-target-raw"

void ipt_loader_setup(void);
ModuleDef *ipt_find_module(char *, ModuleType, HANDLE *);
void ipt_release_modules(void);
