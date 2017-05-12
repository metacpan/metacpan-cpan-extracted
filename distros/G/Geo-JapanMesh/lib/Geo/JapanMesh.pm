package Geo::JapanMesh;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.2');
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Exporter;
@ISA = qw(Exporter);
@EXPORT      = qw(latlng2japanmesh japanmesh2latlng japanmesh2rect);
@EXPORT_OK   = qw(
    latlng2iareamesh iareamesh2latlng iareamesh2rect
);
%EXPORT_TAGS = (
    iareamesh => [qw(latlng2iareamesh iareamesh2latlng iareamesh2rect)], 
    japanmesh => [qw(latlng2japanmesh japanmesh2latlng japanmesh2rect)],
);

# Export function for JapanMesh

sub latlng2japanmesh {
    my $lat   = shift;
    my $lng   = shift;
    my $num   = shift || 1;

    croak("Level number must be between 1 and 3") if ( $num !~ /^[1-3]$/ );

    my ( $slat, $slng ) = _latlng2msec( $lat, $lng );

    return _latlng2japanmesh( $slat, $slng, $num );
}

sub japanmesh2latlng{
    my @rect = japanmesh2rect(@_);
    return @rect[4..6];
}

sub japanmesh2rect  {
    my $jmesh = shift;
    my @res = grep { defined($_) } ( $jmesh =~ /(\d{2})(\d{2})\-?(?:(\d)(\d)\-?(?:(\d)(\d))?)?/ );
    
    croak("Maybe format is wrong: $jmesh") if ( @res < 2 || @res > 6 || @res % 2 != 0 );

    my ( $mny, $mnx, $mxy, $mxx, $lvl ) = _japanmesh2rect( @res );

    ( $mny, $mnx, $mxy, $mxx )          = _msec2latlng( $mny, $mnx, $mxy, $mxx );
    my ( $cy,  $cx  ) = ( ( $mny + $mxy ) / 2, ( $mnx + $mxx ) / 2 );

    return ( $mny, $mnx, $mxy, $mxx, $cy, $cx, $lvl );
}

# Export function for iAreaMesh

sub latlng2iareamesh {
    my $lat   = shift;
    my $lng   = shift;
    my $num   = shift || 1;

    croak("Level number must be between 1 and 8") if ( $num !~ /^[1-8]$/ );

    my ( $slat, $slng ) = _latlng2msec( $lat, $lng );

    return _latlng2japanmesh( $slat, $slng, $num ) if ( $num < 3 );

    my ( $ret, $a, $b ) = _latlng2japanmesh( $slat, $slng, -2 );
    $ret =~ s/\-//g;
    return _latlng2iareamesh( $ret, $a, $b, $num - 2, 1 );
}

sub iareamesh2latlng{
    my @rect = iareamesh2rect(@_);
    return @rect[4..6];
}

sub iareamesh2rect  {
    my $imesh = shift;
    my @res = grep { defined($_) } ( $imesh =~ /(\d{2})(\d{2})(?:(\d)(\d)(?:(\d{1,6}))?)?/ );

    croak("Maybe format is wrong: $imesh") if ( @res < 2 || @res > 5 );

    my ( $mny, $mnx, $mxy, $mxx, $lvl )  = _japanmesh2rect( splice( @res, 0, 4 ) );

    if ( @res ) {
        ( $mny, $mnx, $mxy, $mxx, $lvl ) = _iareamesh2rect( $res[0], $mny, $mnx, 1 );
    }

    ( $mny, $mnx, $mxy, $mxx )           = _msec2latlng( $mny, $mnx, $mxy, $mxx );
    my ( $cy,  $cx  ) = ( ( $mny + $mxy ) / 2, ( $mnx + $mxx ) / 2 );

    return ( $mny, $mnx, $mxy, $mxx, $cy, $cx, $lvl );
}

# Internal function for Common Use

sub _latlng2msec { map { $_ * 3600000 } @_; }

sub _msec2latlng { map { $_ / 3600000 } @_; }

# Internal function for JapanMesh

sub _latlng2japanmesh {
    my $lat   = shift;
    my $lng   = shift;
    my $num   = shift;

    my $p = int( $lat / 2400000 );
    my $a = $lat - $p * 2400000;
    my $s = int( $lng / 3600000 ) - 100;
    my $c = $lng - ( $s + 100 ) *  3600000;

    my $ret  = $p.$s;
    return $ret if ( $num == 1 );

    my $q = int( $a / 300000 );
    my $t = int( $c / 450000 );

    $ret .= "-$q$t";
    return $ret           if ( $num == 2 );

    my $b = $a - $q * 300000;
    my $d = $c - $t * 450000;

    return ($ret, $b, $d) if ( $num == -2 );

    my $r = int( $b / 30000 );
    my $u = int( $d / 45000 );

    $ret .= "-$r$u";
    return $ret           if ( $num == 3 );

    my $e = $b - $r * 30000;
    my $f = $d - $u * 45000;

    return ($ret, $e, $f) if ( $num == -3 );
}

sub _japanmesh2rect {
    my @codes = @_;

    my ( $mny, $mnx ) = ( 0.0, 100.0 * 3600000 );

    my ( $cy1, $cx1 ) = splice( @codes, 0, 2 );
    ( $mny, $mnx )    = ( $mny + $cy1 * 2400000, $mnx + $cx1 * 3600000 );
    my ( $mxy, $mxx ) = ( $mny + 2400000, $mnx + 3600000 );

    return ( $mny, $mnx, $mxy, $mxx, 1 ) unless ( @codes );

    my ( $cy2, $cx2 ) = splice( @codes, 0, 2 );
    ( $mny, $mnx )    = ( $mny + $cy2 * 300000, $mnx + $cx2 * 450000 );
    ( $mxy, $mxx )    = ( $mny + 300000, $mnx + 450000 );

    return ( $mny, $mnx, $mxy, $mxx, 2 ) unless ( @codes );

    my ( $cy3, $cx3 ) = @codes;
    ( $mny, $mnx )    = ( $mny + $cy3 * 30000, $mnx + $cx3 * 45000 );
    ( $mxy, $mxx )    = ( $mny + 30000, $mnx + 45000 );

    return ( $mny, $mnx, $mxy, $mxx, 3 );
}

# Internal function for iAreaMesh

sub _latlng2iareamesh {
    my $ret   = shift;
    my $y     = shift;
    my $x     = shift;
    my $num   = shift;
    my $depth = shift;

    my $divy  = 300000 / 2 ** $depth;
    my $divx  = 450000 / 2 ** $depth;

    my $rety  = int( $y / $divy );
    my $nxty  = $y - $rety * $divy;
    my $retx  = int( $x / $divx );
    my $nxtx  = $x - $retx * $divx;

    $ret     .= $retx + $rety * 2;

    return    $depth >= $num ? $ret
                             : _latlng2iareamesh( $ret, $nxty, $nxtx, $num, $depth + 1 ); 

}

sub _iareamesh2rect {
    my ( $code, $mny, $mnx, $depth ) = @_;

    my $divy  = 300000 / 2 ** $depth;
    my $divx  = 450000 / 2 ** $depth;

    my ( $this, $rest ) = $code =~ /^([0-3])(?:([0-3]+))?$/;

    croak("Maybe format is wrong") unless ( defined( $this ) );

    my $dy = int( $this / 2 );
    my $dx = $this % 2;

    ( $mny, $mnx )    = ( $mny + $dy * $divy, $mnx + $dx * $divx );

    return _iareamesh2rect( $rest, $mny, $mnx, $depth + 1 ) if ( defined( $rest ) );

    my ( $mxy, $mxx ) = ( $mny + $divy, $mnx + $divx );

    return ( $mny, $mnx, $mxy, $mxx, $depth + 2 );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Geo::JapanMesh - Convert between latitude/longitude and Japanese geographical mesh code


=head1 SYNOPSIS

    # To convert Japanese geographical mesh code
    use Geo::JapanMesh;
    
    # From latitude/longitude to mesh code
    
    my $code = latlng2japanmesh( $lat, $lng, $level );
    
    # From mesh code to latitude/longitude rectangle
    
    my ( $minlat, $minlng, $maxlat, $maxlng, $centlat, $centlng, $level ) = japanmesh2rect( $code );
    
    # From mesh code to center latitude/longitude 
    
    my ( $centlat, $centlng, $level ) = japanmesh2latlng( $code );

    # To convert DoCoMo iArea mesh code
    use Geo::JapanMesh qw(:iareamesh);
    
    # From latitude/longitude to mesh code
    
    my $code = latlng2iareamesh( $lat, $lng, $level );
    
    # From mesh code to latitude/longitude rectangle
    
    my ( $minlat, $minlng, $maxlat, $maxlng, $centlat, $centlng, $level ) = iareamesh2rect( $code );
    
    # From mesh code to center latitude/longitude 
    
    my ( $centlat, $centlng, $level ) = iareamesh2latlng( $code );
    
    # To use both Japanese geographical and DoCoMo iArea mesh code
    use Geo::JapanMesh qw(:DEFAULT :iareamesh);


=head1 EXPORT

=head2 DEFAULT

=over

=item C<< latlng2japanmesh( $lat, $lng, $level ) >>

Convert latitude/longitude to Japanese geographical mesh code.
Level value must be 1 to 3.
You can see the definition on L<<http://www.biodic.go.jp/kiso/col_mesh.html>>.

=item C<< japanmesh2rect( $code ) >>

Convert mesh code to latitude/longitude rectangle data.
Returns minimum latitude, minimum longitude, maximum latitude, maximum longitude,
center latitude, center longitude and mesh code level.

=item C<< japanmesh2latlng( $code ) >>

Convert mesh code to center latitude/longitude data.
Returns center latitude, center longitude and mesh code level.

=back

=head2 TAG: iareamesh

=over

=item C<< latlng2iareamesh( $lat, $lng, $level ) >>

Convert latitude/longitude to DoCoMo iArea mesh code.
Level value must be 1 to 8, and code of 1 and 2 are same with Japanese geographical 
mesh code. 
You can see the definition on L<<http://www.nttdocomo.co.jp/service/imode/make/content/iarea/>>.

=item C<< iareamesh2rect( $code ) >>

Convert mesh code to latitude/longitude rectangle data.
Returns minimum latitude, minimum longitude, maximum latitude, maximum longitude,
center latitude, center longitude and mesh code level.

=item C<< iareamesh2latlng( $code ) >>

Convert mesh code to center latitude/longitude data.
Returns center latitude, center longitude and mesh code level.

=back


=head1 DEPENDENCIES

Exporter


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
