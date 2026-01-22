/*
 * TestModule - BOOT section and module initialization
 *
 * This is processed last when combining XS files.
 */

MODULE = TestModule    PACKAGE = TestModule

PROTOTYPES: DISABLE

const char *
version()
CODE:
    RETVAL = "0.01";
OUTPUT:
    RETVAL

BOOT:
    /* Initialize shared registry on module load */
    init_registry();
