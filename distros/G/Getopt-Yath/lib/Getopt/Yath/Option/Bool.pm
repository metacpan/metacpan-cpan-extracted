package Getopt::Yath::Option::Bool;
use strict;
use warnings;

our $VERSION = '2.000011';

use parent 'Getopt::Yath::Option';
use Getopt::Yath::HashBase;

sub allows_shortval   { 0 }
sub allows_default    { 1 }
sub allows_arg        { 0 }
sub requires_arg      { 0 }
sub allows_autofill   { 0 }
sub requires_autofill { 0 }

sub no_arg_value { 1 }    # --bool

# undef is not populated, otherwise we have 1 or 0
sub is_populated { defined(${$_[1]}) ? 1 : 0 }

sub add_value   { ${$_[1]} = $_[2] }
sub clear_field { ${$_[1]} = 0 }       # --no-bool

# Default to 0 unless otherwise specified
sub get_default_value {
    my $self = shift;
    return undef if $self->{+MAYBE};
    return $self->SUPER::get_default_value(@_) ? 1 : 0;
}

sub can_set_env   { 1 }

sub get_env_value {
    my $opt = shift;
    my ($var, $ref) = @_;

    my $b = $$ref ? 1 : 0;
    return $b unless $var =~ m/^!/;
    return $b ? 0 : 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Yath::Option::Bool - Option type for boolean values (no arguments)

=head1 DESCRIPTION

Is either on or off. C<--opt> will turn it on. C<--no-opt> will turn it off.
Default is off unless the C<default> is parameter is provided.

=head1 SYNOPSIS

    option dry_run => (
        type => 'Bool',
        description => "Only pretend to do stuff",
        default => 0,
    );

=head1 METHODS

All methods from L<Getopt::Yath::Option> are inherited. The following are
overridden or noteworthy:

=over 4

=item requires_arg: false

=item allows_arg: false

Bool options take no argument. C<--opt> turns it on, C<--no-opt> turns it off.

=item can_set_env: true

Bool options can set environment variables. Negated env vars (C<!VAR>) are
supported and will invert the boolean value.

=item get_default_value

Returns C<0> by default unless a custom C<default> is provided.

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
