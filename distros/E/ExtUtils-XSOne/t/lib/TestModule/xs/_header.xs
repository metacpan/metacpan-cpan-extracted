/*
 * TestModule - Test XS module for ExtUtils::XSOne
 *
 * This is the header section containing shared types and state.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ============================================================================
 * Shared State - accessible from all module files
 * ============================================================================ */

#define MAX_REGISTRY 256

typedef struct {
    int id;
    char *name;
    int active;
} TestItem;

static TestItem *item_registry[MAX_REGISTRY];
static int registry_count = 0;
static int registry_initialized = 0;

/* ============================================================================
 * Helper Functions - shared across all modules
 * ============================================================================ */

static void init_registry(void) {
    if (!registry_initialized) {
        memset(item_registry, 0, sizeof(item_registry));
        registry_initialized = 1;
    }
}

static int register_item(TestItem *item) {
    init_registry();
    if (registry_count >= MAX_REGISTRY) return -1;

    item->id = registry_count;
    item->active = 1;
    item_registry[registry_count] = item;
    return registry_count++;
}

static TestItem *get_item(int id) {
    if (id < 0 || id >= MAX_REGISTRY) return NULL;
    return item_registry[id];
}

static void unregister_item(int id) {
    if (id >= 0 && id < MAX_REGISTRY && item_registry[id]) {
        item_registry[id]->active = 0;
        item_registry[id] = NULL;
    }
}

static int get_registry_count(void) {
    return registry_count;
}
