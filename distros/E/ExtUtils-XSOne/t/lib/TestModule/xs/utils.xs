/*
 * TestModule::Utils - Utility functions
 *
 * Demonstrates another submodule accessing the same shared registry.
 */

MODULE = TestModule    PACKAGE = TestModule::Utils

PROTOTYPES: DISABLE

int
registry_count()
CODE:
    /* Access shared state from _header.xs */
    RETVAL = get_registry_count();
OUTPUT:
    RETVAL

int
is_registry_initialized()
CODE:
    RETVAL = registry_initialized;
OUTPUT:
    RETVAL

void
reset_registry()
CODE:
    /* Clear all items */
    for (int i = 0; i < MAX_REGISTRY; i++) {
        if (item_registry[i]) {
            if (item_registry[i]->name) {
                free(item_registry[i]->name);
            }
            free(item_registry[i]);
            item_registry[i] = NULL;
        }
    }
    registry_count = 0;

SV *
get_item_name(id)
    int id
CODE:
    TestItem *item = get_item(id);
    if (item && item->active && item->name) {
        RETVAL = newSVpv(item->name, 0);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL
