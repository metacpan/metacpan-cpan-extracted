#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Language::Befunge::lib::TIME;
# ABSTRACT: date / time extension
$Language::Befunge::lib::TIME::VERSION = '5.000';
use DateTime;
sub new { return bless {}, shift; }


sub D {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $dt = DateTime->now( time_zone => _tz($interp) );
    $ip->spush( $dt->day );
}

sub F {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $dt = DateTime->now( time_zone => _tz($interp) );
    $ip->spush( $dt->day_of_year );
}

sub G {
    my (undef, $interp) = @_;
    $interp->get_curip->extdata('TIME', 'UTC');
}

sub H {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $dt = DateTime->now( time_zone => _tz($interp) );
    $ip->spush( $dt->hour );
}

sub L {
    my (undef, $interp) = @_;
    $interp->get_curip->extdata('TIME', 'local');
}


sub M {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $dt = DateTime->now( time_zone => _tz($interp) );
    $ip->spush( $dt->minute );
}

sub O {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $dt = DateTime->now( time_zone => _tz($interp) );
    $ip->spush( $dt->month );
}

sub S {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $dt = DateTime->now( time_zone => _tz($interp) );
    $ip->spush( $dt->second );
}

sub W {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $dt = DateTime->now( time_zone => _tz($interp) );
    $ip->spush( $dt->day_of_week + 1 );
}

sub Y {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    my $dt = DateTime->now( time_zone => _tz($interp) );
    $ip->spush( $dt->year );
}

sub _tz {
    my $interp = shift;
    return $interp->get_curip->extdata('TIME') // 'local'; # // FIXME: padre syntax highlight
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::TIME - date / time extension

=head1 VERSION

version 5.000

=head1 DESCRIPTION

The TIME fingerprint (0x54494D45) allows to work with date & time.

=head1 FUNCTIONS

=head2 new

Create a new TIME instance.

=head2 Date subroutines

=over 4

=item Y() - push current year on the stack

=item O() - push current month on the stack

=item D() - push current day of month on the stack

=item F() - push current day of year on the stack

=item W() - push current week day on the stack (1 = sunday)

=back

=head2 Time subroutines

=over 4

=item H() - push current hour on the stack

=item M() - push current minute on the stack

=item S() - push current second on the stack

=back

=head2 Timezone subroutines

All previous functions work with local time by default. One can change
the timezone with the following:

=over 4

=item G() - set time functions to GMT

=item L() - set time functions to local time

=back

=head1 SEE ALSO

L<http://www.rcfunge98.com/rcsfingers.html#TIME>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
