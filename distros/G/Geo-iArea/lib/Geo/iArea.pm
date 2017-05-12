package Geo::iArea;

use warnings;
use strict;
use Carp;

use Geo::JapanMesh qw(latlng2iareamesh);
use CDB_File;
use File::ShareDir 'dist_file';
use base qw(Class::Accessor::Fast);
use Encode;

use version; 
our $VERSION = qv('0.0.1');

__PACKAGE__->mk_accessors(qw(code name region pref min_lat min_lng max_lat max_lng cen_lat cen_lng));

sub new {
    my ($class, $lat, $lng) = @_;

    my $code;

    unless ( defined($lng) ) {
        $code = $lat;
    } else {
        $code = latlng2iareamesh( $lat, $lng, 7 );
    }

    return unless ( defined($code) );

    my $cdbfile;
    {
        local $^W; # To avoid File::Spec::Unix error
        $cdbfile = dist_file('Geo-iArea', 'iarea.cdb');
    }
    my $cdb     = CDB_File->TIEHASH($cdbfile);

    unless ( $code =~ /^\d{5}$/ ) {
        my @meshes = reverse grep { $_ } ( $code =~ /((((((\d{6})\d?)\d?)\d?)\d?)\d?)/ ) or return;

        my $acode;
        foreach my $mesh ( @meshes ) {
            if ( $cdb->EXISTS($mesh) ) {
                $acode = $cdb->FETCH($mesh);
                last;
            }
        }   
        return unless ( defined($acode) );
        $code = $acode;
    }

    return unless( $cdb->EXISTS($code) );

    my ( $rcode, $name, $region, $pref, $minlat, $minlng, $maxlat, $maxlng ) 
      = split( /,/, $cdb->FETCH($code) );

    ( $name, $region, $pref ) = map { Encode::decode('utf8',$_) } ( $name, $region, $pref );

    my ( $cenlat, $cenlng ) = map { sprintf('%.6f',$_) }
      ( ( $minlat + $maxlat ) / 2, ( $minlng + $maxlng ) / 2 );

    return bless {
        code    => $rcode,
        name    => $name,
        region  => $region,
        pref    => $pref,
        min_lat => $minlat,
        max_lat => $maxlat,
        min_lng => $minlng,
        max_lng => $maxlng,
        cen_lat => $cenlat,
        cen_lng => $cenlng,
    }, $class;
}

sub rectangle {
    map { $_[0]->$_ } qw( min_lat min_lng max_lat max_lng );
}

sub center {
    map { $_[0]->$_ } qw( cen_lat cen_lng );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Geo::iArea - Convert latitude/longitude data to NTT DoCoMo's iArea data


=head1 SYNOPSIS

    use Geo::iArea;

    # Convert from latitude/longitude data
    # If specified 2 arguments, judge them as latitude/longitude.
    # latitude/longitude must be wgs84 datum.

    my $ia = Geo::iArea->new(35.0000,135.0000);

    # You can also make iArea object from iArea code.
    # If argument is only 1 and it is 5 digits, it is judged as iArea code.

    my $ia = Geo::iArea->new('25100');

    # You can also make iArea object from 2~7 level mesh code.
    # If argument is only 1 and it is 6~11 digits, it is judged as mesh code.

    my $ia = Geo::iArea->new('52354000000');

    # After create iArea object, you can access to iArea property.
    my $name   = $ia->name   # Name of area.
    my $region = $ia->region # Name of Japanese region which the area is included.
    my $pref   = $ia->pref   # Name of prefecture which the area is included.
    my ( $min_lat, $min_lng, $max_lat, $max_lng ) = $ia->rectangle();
                             # Return MBR rectange data of given iArea.
    my ( $cen_lat, $cen_lng ) = $ia->center();
                             # Return center data of given iArea.

=head1 CONSTRUCTOR

=over

=item * new

=back


=head1 FUNCTIONS

=over

=item * name

=item * region>

=item * pref

=item * rectangle

=item * center

=back
  
Geo::iArea requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-geo-iarea@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. 

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
