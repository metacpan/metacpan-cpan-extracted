/*
 * TestModule::Context - Context management
 *
 * Demonstrates a submodule that uses shared registry from _header.xs
 */

MODULE = TestModule    PACKAGE = TestModule::Context

PROTOTYPES: DISABLE

SV *
new(class, ...)
    char *class
PREINIT:
    char *name = "unnamed";
    int i;
CODE:
    /* Parse options */
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            if (strcmp(key, "name") == 0) {
                name = SvPV_nolen(ST(i + 1));
            }
        }
    }

    /* Allocate item */
    TestItem *item = (TestItem *)malloc(sizeof(TestItem));
    if (!item) croak("Failed to allocate TestItem");

    item->name = strdup(name);

    /* Register in shared registry */
    int id = register_item(item);
    if (id < 0) {
        free(item->name);
        free(item);
        croak("Registry full");
    }

    /* Return blessed reference to ID */
    SV *sv = newSViv(id);
    SV *rv = newRV_noinc(sv);
    HV *stash = gv_stashpv(class, GV_ADD);
    sv_bless(rv, stash);

    RETVAL = rv;
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
CODE:
    if (!SvROK(self)) XSRETURN_EMPTY;
    SV *obj = SvRV(self);
    if (!SvIOK(obj)) XSRETURN_EMPTY;

    int id = SvIV(obj);
    TestItem *item = get_item(id);

    if (item && item->active) {
        if (item->name) free(item->name);
        unregister_item(id);
        free(item);
    }

int
id(self)
    SV *self
CODE:
    if (!SvROK(self)) croak("Invalid context");
    RETVAL = SvIV(SvRV(self));
OUTPUT:
    RETVAL

const char *
name(self)
    SV *self
CODE:
    if (!SvROK(self)) croak("Invalid context");
    int id = SvIV(SvRV(self));
    TestItem *item = get_item(id);
    if (!item) croak("Item not found");
    RETVAL = item->name;
OUTPUT:
    RETVAL
