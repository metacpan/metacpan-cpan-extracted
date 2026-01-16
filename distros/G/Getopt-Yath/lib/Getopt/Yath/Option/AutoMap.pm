package Getopt::Yath::Option::AutoMap;
use strict;
use warnings;

our $VERSION = '2.000007';

use parent 'Getopt::Yath::Option::Map';
use Getopt::Yath::HashBase;

sub allows_arg        { 1 }
sub requires_arg      { 0 }
sub allows_default    { 1 }
sub allows_autofill   { 1 }
sub requires_autofill { 1 }

sub default_long_examples  { ['', '=key=val'] }
sub default_short_examples { ['', 'key=val', '=key=val'] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Yath::Option::AutoMap - Options that accept multiple values, but also
provide a default if no values are provided.

=head1 DESCRIPTION

This is a combination of 'Auto' and 'Map' types. The no-arg form C<--opt> will
add the default key+value pairs to the hash. The C<--opt=KEY=VAL> form will add
additional values.

=head1 SYNOPSIS

    option env_var => (
        field          => 'env_vars',
        short          => 'E',
        type           => 'Map',
        long_examples  => [' VAR=VAL'],
        short_examples => ['VAR=VAL', ' VAR=VAL'],
        description    => 'Set environment variables',
        autofill       => sub { +{ HOME => $ENV{HOME}, USER => $ENV{USER} } },
    );

=head1 SOURCE

The source code repository for Getopt-Yath can be found at
L<http://github.com/Test-More/Getopt-Yath/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
