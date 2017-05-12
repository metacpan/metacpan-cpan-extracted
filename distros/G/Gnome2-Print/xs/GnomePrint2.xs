#include "gnomeprintperl.h"


MODULE = Gnome2::Print	PACKAGE = Gnome2::Print	PREFIX = gnome_print_

=for object Gnome2::Print::main

=cut

BOOT:
#include "register.xsh"
#include "boot.xsh"

=for apidoc
=signature (major_version, minor_version, micro_version) = Gnome2::Print->GET_VERSION_INFO
=cut
void
GET_VERSION_INFO (class)
    PPCODE:
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSViv (GNOMEPRINT_MAJOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GNOMEPRINT_MINOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GNOMEPRINT_MICRO_VERSION)));
	PERL_UNUSED_VAR (ax);

bool
CHECK_VERSION (class, major, minor, micro)
	int major
	int minor
	int micro
    CODE:
	RETVAL = GNOMEPRINT_CHECK_VERSION (major, minor, micro);
    OUTPUT:
	RETVAL
