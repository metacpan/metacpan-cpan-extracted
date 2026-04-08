package Getopt::Yath::Option::Scalar;
use strict;
use warnings;

our $VERSION = '2.000009';

use parent 'Getopt::Yath::Option';
use Getopt::Yath::HashBase;

sub allows_default    { 1 }
sub allows_arg        { 1 }
sub requires_arg      { 1 }
sub allows_autofill   { 0 }
sub requires_autofill { 0 }

sub is_populated { defined(${$_[1]}) ? 1 : 0 }

sub add_value { ${$_[1]} = $_[2] }

sub can_set_env   { 1 }

sub get_env_value {
    my $opt = shift;
    my ($var, $ref) = @_;

    return $$ref unless $var =~ m/^!/;
    return $$ref ? 0 : 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Yath::Option::Scalar - Option type for basic scalar values.

=head1 DESCRIPTION

Takes a scalar value. A value is required. Can be used as C<--opt VAL> or
C<--opt=val>. C<--no-opt> can be used to clear the value.

=head1 SYNOPSIS

    option name => (
        short => 'n',
        type => 'Scalar',
        description => 'Specify the name',
        long_examples => [ ' foo'],
        short_examples => [ ' foo'],
        default => 'john',
    );

=head1 METHODS

All methods from L<Getopt::Yath::Option> are inherited. The following are
overridden or noteworthy:

=over 4

=item requires_arg: true

A value must be provided (C<--opt VALUE> or C<--opt=VALUE>).

=item can_set_env: true

Scalar options can set environment variables. Negated env vars (C<!VAR>) are
supported.

=back

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
