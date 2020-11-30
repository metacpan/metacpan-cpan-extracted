package Linux::Utils;
$Linux::Utils::VERSION = '0.002';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka 'method';
use Data::Printer alias => 'pdump';

########################################################

=head1 NAME

Linux::Utils - An collection of utilities for working with Linux.

=head1 VERSION

version 0.002

=cut

=head1 INCLUDED MODULES

=over

=item L<Linux::Utils::RPM>

=item L<Linux::Utils::Systemd>

=item L<Linux::Utils::YUM>

=back

=cut

########################################################

__PACKAGE__->meta->make_immutable;

1;
