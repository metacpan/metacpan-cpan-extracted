package Devel::AssertOS::OSFeatures::SupportsSiebel;

use 5.010;
use strict;
use warnings;
use Devel::CheckOS;

our $VERSION = '0.01';

sub matches { return qw(Linux AIX Solaris HPUX MSWin32); }
sub os_is   { Devel::CheckOS::os_is( matches() ); }
Devel::CheckOS::die_unsupported() unless ( os_is() );

sub expn { "The operating system can run Siebel CRM" }

1;
__END__

=head1 NAME

Devel::AssertOS::OSFeatures::SupportsSiebel - Perl extension to test if an OS is supported by Siebel CRM

=head1 SYNOPSIS

  use Devel::AssertOS::OSFeatures::SupportsSiebel;

=head1 DESCRIPTION

This module checks, only by importing it, if the OS running the code is supported by Siebel or not. If not, the module will C<die>, 
forcing the code to stop being executed.

This module was proposed by David Cantrell in L<http://www.mail-archive.com/cpan-testers-discuss%40perl.org/msg03089.html>.

=head2 EXPORT

None, but the functions below can be used by calling them with the complete package name (Devel::AssertOS::OSFeatures::SupportsSiebel::<function>).

=head3 matches

Returns a list of the OS that are supported by Siebel CRM.

It will execute C<os_is> with the operational system name, calling C<die_unsuported> if the return value from C<os_is> is false.

Beware that the given parameter must follow the same provided by $^O, including case and format.
C<die_if_os_isnt> is called by default when the module is imported to another package.

=head1 CAVEATS

Beware that Siebel is supported by specific versions of OS. This module does not check OS version.

=head1 SEE ALSO

=over

=item *

Oracle documentation about supported OS: L<http://docs.oracle.com/cd/E11886_01/V8/CORE/SRSP_81/SRSP_81_ServerEnv4.html#wp1009117>

=item *

L<Devel::CheckOS>

=item *

Project website: L<https://code.google.com/p/siebel-gnu-tools/>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

This file is part of Siebel COM project.

Siebel COM is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel COM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel COM.  If not, see <http://www.gnu.org/licenses/>.

=cut
