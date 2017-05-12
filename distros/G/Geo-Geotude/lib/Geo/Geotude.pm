# $Id: Geotude.pm,v 1.5 2007/08/09 02:10:54 asc Exp $

use strict;
package Geo::Geotude;

$Geo::Geotude::VERSION = '1.0';

=head1 NAME

Geo::Geotude - OOP for performing geotude location conversions.

=head1 SYNOPSIS

 my $lat = '3.106254';
 my $lon = '101.630517';

 my $geo = Geo::Geotude->new('latitude' => $lat, 'longitude' => $lon);
 print $geo->geotude();

 # prints '53281.86.93.30.75.41.67'

=head1 DESCRIPTION

Geowhat? A Geotude is : "permanent and hierarchical. [As] a trade-off: A Geotude
is less intuitive than address, but more intuitive than latitude/longitude. A
Geotude is more precise than address, but less precise than latitude/longitude."

This package provides OOP methods for converting a decimal latitude and longitude
in to Geotude and vice versa.

=cut

use POSIX qw (floor);
use Memoize;

memoize("geotude2point", "point2geotude");

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(%args)

Valid arguments are :

=over 4 

=item * B<geotude>

A Geotude string.

Must be present if neither I<latitude> or I<longitude> are
defined.

=item * B<latitude>

A latitude, in decimal format.

Must be present if I<longitude> is defined.

=item * B<longitude>

A longitude, in decimal format.

Must be present if I<latitude> is defined.

=back 

Returns a I<Geo::Geotude> object.

=cut
        
sub new {
        my $pkg = shift;
        my %self = @_;
        return bless \%self, $pkg;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->point()

Returns a comma-separated string when called in a scalar context.

When called in an array context, returns a list containing decimal 
latitude and longitude.

=cut

sub point {
        my $self = shift;
        return &geotude2point($self->{'geotude'});
}

=head2 $obj->geotude()

Returns a geotude string when called in scalar context.

When called in an array context, returns a list containing the 
major and minor (or sub) geotudes. 

=cut

sub geotude {
        my $self = shift;
        return &point2geotude($self->{'latitude'}, $self->{'longitude'});
}

sub geotude2point {
        my $gt = shift;

        my @parts = split(/\./, $gt);

        $gt  = shift @parts;
        $gt -= 10000;

        my $dlat = '';
        my $dlon = '';

        foreach my $str (@parts) {
                $dlat .= substr($str, 0, 1);
                $dlon .= substr($str, 1, 1);
        }

        my $lat  = ($gt - $gt % 500) / 500;
        $lat    .= ".$dlat";

        my $lon  = $gt % 500;
        $lon    .= ".$dlon";

        $lat = 90 - $lat;
        $lon = $lon - 180;

        my $fmt = "%." . length($dlat) . "f";

        $lat = sprintf($fmt, $lat);
        $lon = sprintf($fmt, $lon);

        return (wantarray) ? ($lat, $lon) : "$lat,$lon";
}

sub point2geotude {
        my $lat = shift;
        my $lon = shift;
        
        $lat = 90 - $lat;
        $lon = $lon + 180;

        my $flat = floor($lat);
        my $flon = floor($lon);

        # kind of dirty, but easier
        # than dealing with math-isms

        $lat =~ s/$flat\.//;
        $lon =~ s/$flon\.//;
        
        my $gt = 500 * $flat + $flon + 10000;

        my $pts = length($lat);
        my @sub = ();

        for (my $i=0; $i < $pts; $i++) {
                my $slat = substr($lat, $i, 1);
                my $slon = substr($lon, $i, 1);
                push @sub, $slat.$slon;
        }

        my $major = $gt;
        my $minor = join(".", @sub);
        my @res   = ($major, $minor);

        return (wantarray) ? @res : join(".", @res);
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2007/08/09 02:10:54 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<http://www.geotude.com/>

=head1 BUGS

Please report all bugs via http://rt.cpan.org/

=head1 LICENSE

Copyright (c) 2007 Aaron Straup Cope. All Rights Reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

return 1;
