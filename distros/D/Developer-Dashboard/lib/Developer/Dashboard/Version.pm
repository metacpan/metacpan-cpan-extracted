package Developer::Dashboard::Version;

use strict;
use warnings;

our $VERSION = '6.06';

1;

__END__

=head1 NAME

Developer::Dashboard::Version - lightweight distribution version metadata

=head1 PURPOSE

Provides the Developer Dashboard version scalar without loading the dashboard
application, web stack, or command runtime.

=head1 WHY IT EXISTS

Small commands such as C<dashboard version> need release metadata only. Keeping
that scalar in this dependency-free module avoids loading the full public
module graph just to print one value. C<Developer::Dashboard> aliases the same
value so the library and command report one version.

=head1 WHEN TO USE

Use this module when a lightweight caller needs only the installed or source
distribution version. Load C<Developer::Dashboard> instead when using its API.

=head1 HOW TO USE

Add the distribution's C<lib> directory to C<@INC> (or install the distribution
normally), load this module, and read C<$Developer::Dashboard::Version::VERSION>.
It provides metadata only: it defines no runtime services and intentionally
does not load the dashboard handle, web application, or command helpers.

=head1 WHAT USES IT

C<bin/dashboard> uses the scalar for the C<version> command, and
C<Developer::Dashboard> exposes the same scalar as its public module version.

=head1 EXAMPLES

Print the current package version:

  perl -Ilib -MDeveloper::Dashboard::Version -e 'print "$Developer::Dashboard::Version::VERSION\n"'

Compare it with the main module version:

  perl -Ilib -MDeveloper::Dashboard::Version -MDeveloper::Dashboard -e 'die unless $Developer::Dashboard::Version::VERSION eq $Developer::Dashboard::VERSION'

=cut
