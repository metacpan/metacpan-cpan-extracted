package Linux::NFS::BigDir::Syscalls;
use strict;
use Exporter 'import';
our @EXPORT = qw(SYS_getdents);
our $VERSION = '0.003'; # VERSION

=pod

=head1 NAME

Linux::Syscalls - exports syscalls numbers defined during distribution setup

=head1 EXPORTS

Currently, only C<SYS_getdents> is exported by default.

=head1 FUNCTIONS

=head2 SYS_getdents

Returns a integer that corresponds to the C<getdents> syscall defined in the C header file.

The value is defined dynamically during the setup of L<Linux::NFS::BigDir> distribution with the
corresponding Makefile.PL.

=head1 SEE ALSO

=over

=item *

L<Linux::NFS::BigDir>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Linux-NFS-BigDir distribution.

Linux-NFS-BigDir is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Linux-NFS-BigDir is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Linux-NFS-BigDir. If not, see <http://www.gnu.org/licenses/>.

=cut

