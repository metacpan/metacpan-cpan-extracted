package Getopt::Yath::Option::Auto;
use strict;
use warnings;

our $VERSION = '2.000007';

use parent 'Getopt::Yath::Option::Scalar';
use Getopt::Yath::HashBase;

sub allows_default    { 1 }
sub allows_arg        { 1 }
sub requires_arg      { 0 }
sub allows_autofill   { 1 }
sub requires_autofill { 1 }

sub can_set_env   { 1 }

sub get_env_value {
    my $opt = shift;
    my ($var, $ref) = @_;

    return $$ref unless $var =~ m/^!/;
    return $ref ? 0 : 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Yath::Option::Auto - Options with default values that also accept arguments.

=head1 DESCRIPTION

This type has an 'autofill' value that is used if no argument is provided to
the parameter, IE C<--opt>. But can also be given a specific value using
C<--opt=val>. It B<DOES NOT> support C<--opt VAL> which will most likely result
in an exception.

=head1 SYNOPSIS

    option help => (
        type     => 'Auto',
        autofill => 'ALL',    # Default to all if no subtitle
        short    => 'h',

        description    => "Show help, optionally just show a specific subtitle from help output",
        short_examples => ['', '=Subtitle'],
        long_examples  => ['', '=Subtitle'],
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
