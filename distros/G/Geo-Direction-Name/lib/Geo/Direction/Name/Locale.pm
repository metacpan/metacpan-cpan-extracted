package Geo::Direction::Name::Locale;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.4');

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; import utf8;
    }
}

sub new {
    my $class = shift;
    my $dev   = shift || 32;

    my $dir  = $class->dir_string();
    my $abbr = $class->abbr_string();

    my $dev1 = $dev - 1;
    my %dirs = ();
    my @strs = map { 
        $dirs{lc($dir->[$_])}  = $_;
        $dirs{lc($abbr->[$_])} = $_;
        [ $dir->[$_], $abbr->[$_],] 
    } (0..$dev1);

    bless {
        dirs => \%dirs,
        strs => \@strs,
        dev  => $dev, 
    }, $class;
}

sub string {
    my $self = shift;
    my ($i,$abbr) = @_;

    $self->{strs}->[$i]->[$abbr];
}

sub direction {
    my $self = shift;
    my ($str) = @_;

    my $i = $self->{dirs}->{lc($str)};
    return unless (defined($i));
    return $i * 360.0 / $self->{dev};
}

sub dir_string {
[
    '0.00',
    '11.25',
    '22.50',
    '33.75',
    '45.00',
    '56.25',
    '67.50',
    '78.75',
    '90.00',
    '101.25',
    '112.50',
    '123.75',
    '135.00',
    '146.25',
    '157.50',
    '168.75',
    '180.00',
    '191.25',
    '202.50',
    '213.75',
    '225.00',
    '236.25',
    '247.50',
    '258.75',
    '270.00',
    '281.25',
    '292.50',
    '303.75',
    '315.00',
    '326.25',
    '337.50',
    '348.75',
]
}

sub abbr_string {
    $_[0]->dir_string();
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Geo::Direction::Name::Locale - Base class of Geo::Direction::Name's locale class.


=head1 CONSTRUCTOR

=over 4

=item * new

=back


=head1 BASE METHODS

=over 4

=item * string

=item * direction

=item * dir_string

=item * abbr_string

=back


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

