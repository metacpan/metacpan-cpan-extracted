package Geo::Converter::WKT2KML;

use warnings;
use strict;
use Carp;
use XML::Simple;
$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

use version; our $VERSION = qv('0.0.3');
use base 'Exporter';

our @EXPORT = qw(
    wkt2kml
    kml2wkt
);

my $coord = qr{[\+\-]?\d+(?:\.\d+)?};
my $formatter;
$formatter = {
    'point' => sub {
        '<Point><coordinates>' . coordformatter( $_[0] ) . '</coordinates></Point>'
    },
    'multipoint' => sub {
        $formatter->{geometrycollection}->([
            map { $formatter->{point}->([$_]) } @{$_[0]}
        ]);
    },
    'linestring' => sub {
        '<LineString><coordinates>' . coordformatter( $_[0] ) . '</coordinates></LineString>'
    },
    'multilinestring' => sub {
        $formatter->{geometrycollection}->([
            map { $formatter->{linestring}->($_) } @{$_[0]}
        ]);
    },
    'polygon' => sub {
        my @lnr;
        push @lnr, $formatter->{LinearRing}->([shift(@{$_[0]})],'outerBoundaryIs');
        push @lnr, $formatter->{LinearRing}->($_[0],'innerBoundaryIs') if ( @{ $_[0] } );
        "<Polygon>\n" . join( "\n", @lnr ) . "\n</Polygon>";
    },
    'LinearRing' => sub {
        my $bound = $_[1];
        join ( "\n", map { "<$bound><LinearRing><coordinates>" . coordformatter( $_ ) . "</coordinates></LinearRing></$bound>" } @{$_[0]} );
    },
    'multipolygon' => sub {
        $formatter->{geometrycollection}->([
            map { $formatter->{polygon}->($_) } @{$_[0]}
        ]);
    },
    'geometrycollection' => sub {
        "<MultiGeometry>\n" . join( "\n", @{$_[0]} ) . "\n</MultiGeometry>"
    },
};

sub coordformatter {
    my @coords = @{$_[0]};
    join( "\n", map { my $s = $_; $s =~ s/\s+/,/g; $s } @coords );
}

sub wkt2kmlparser {
    return wkt2kmlformatter($_[1]) unless $_[0];
    $_[0] =~ s{\A                         # start of the string
               \s*                        # spaces
               (  [\(\)]                  # paren
                  | [a-zA-Z]+             # command
                  | (?:$coord\s+)+$coord  # coordinate
                  | ,                     # delimiter
               )
              }{}x;
    return wkt2kmlformatter($_[1]) if $1 eq ')';
    my $token =
      $1 eq '(' ? wkt2kmlparser( $_[0], [] ) :
      $1 ne ',' ? lc($1) 
                : undef;
    push @{ $_[1] }, $token if ( defined( $token ) );
    goto &wkt2kmlparser;
}

sub wkt2kmlformatter {
    return $_[0] if ( !ref($_[0]) || $_[0]->[0] !~ /^[a-z]+$/ );

    my @args    = @{$_[0]};
    my @reslt;

    while ( my $command = shift(@args) ) {
        if ( my $format = $formatter->{$command} ) {
            push ( @reslt, $format->( shift @args ) );
        } else {
            croak "WKT $command cannot be interpreted";
        }
    }

    return @reslt > 1 ? \@reslt : $reslt[0];
}

sub wkt2kml { wkt2kmlparser( $_[0], []) }

my $builder;
$builder = {
    'Point' => sub {
        my $buf = 'POINT(' . join( ',', map { coordbuilder($_->{coordinates}) } @{$_[0]} ) . ')';
        $buf    = 'MULTI' . $buf if ( @{$_[0]} > 1 );
        $buf;
    },
    'LineString' => sub {
        my $buf = '(' . join( '),(', map { coordbuilder($_->{coordinates}) } @{$_[0]} ) . ')';
        $buf    = @{$_[0]} > 1 ? "MULTILINESTRING($buf)" : "LINESTRING$buf";
        $buf;
    },
    'Polygon' => sub {
        my $buf = '(' . join( '),(', map { $builder->{linearring}->($_) } @{$_[0]} ) . ')';
        $buf    = @{$_[0]} > 1 ? "MULTIPOLYGON($buf)" : "POLYGON$buf";
        $buf;
    },
    'linearring' => sub {
        my @lnr;
        push( @lnr, $_[0]->{outerBoundaryIs}->{LinearRing}->{coordinates} );
        push( @lnr, map { $_->{LinearRing}->{coordinates} } ( ref($_[0]->{innerBoundaryIs}) eq 'ARRAY' ? @{$_[0]->{innerBoundaryIs}} : ($_[0]->{innerBoundaryIs}) ) )
            if ( defined($_[0]->{innerBoundaryIs}) );
        '(' . join( '),(', map { coordbuilder($_) } @lnr ) . ')';
    },
    'MultiGeometry' => sub {
        my @key = grep { $builder->{$_} } keys %{$_[0]->[0]};
        my $buf = join( ',', map { kml2wktbuilder( $_, $_[0]->[0]->{$_} ) } @key );
        $buf    = "GEOMETRYCOLLECTION($buf)" if ( @key > 1 );
        $buf;
    },
};

sub coordbuilder {
    my $coords = $_[0];
    $coords =~ s/^[\s\n]*(.+)[\s\n]*$/$1/m;
    my @coords = split( /[\s\n]+/, $coords );
    join( ",", map { my $s = $_; $s =~ s/,/ /g; $s } @coords );
}

sub kml2wktbuilder {
    my $key = shift;
    my $arg = shift;

    if ( my $build = $builder->{$key} ) {
        my @reslt = $build->( ref($arg) eq 'ARRAY' ? $arg : [$arg]);
        return @reslt > 1 ? \@reslt : $reslt[0];
    } else {
        croak "KML $key element cannot be interpreted";
    }
}

sub kml2wkt { 
    my $xml = XMLin($_[0],KeepRoot => 1); 
    my ($key) = keys %{$xml};
    kml2wktbuilder( $key, $xml->{$key} );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Geo::Converter::WKT2KML - Simple converter between WKT and KML


=head1 SYNOPSIS

    use Geo::Converter::WKT2KML;
    
    # Convert WKT to KML's geometry fragment
    wkt2kml('POINT(135 35)');
    
    # Convert KML's geometry fragment to KML
    kml2wkt('<Point><coordinates>135,35</coordinates></Point>');
  
  
=head1 DESCRIPTION

    This module provides two functions, wkt2kml and kml2wkt.
    These are convert geometry formats WKT (Well-Known Text) and KML 
    each other.
    
    This module can interpret only geometry fragment of KML, cannot
    interpret full spec KML.
    Only elements can be understood are:

     * Point
     * LineString
     * Polygon
     * MultiGeometry
     * (Belows are child elements of aboves)
     * coordinates
     * LinearRing
     * outerBoundaryIs
     * innerBoundaryIs 

    WKT is also understood full spec one.
    "POINT ZM ..." or "POLYGON EMPTY" are cannot interpreted.
    Only commands can be understood are:

     * POINT
     * MULTIPOINT
     * LINESTRING
     * MULTILINESTRING
     * POLYGON
     * MULTIPOLYGON
     * GEOMETRYCOLLECTION


=head1 EXPORT 

=over

=item C<< wkt2kml($wkt) >>

Returns KML geometry fragment.

=item C<< kml2wkt($kml_fragment) >>

Returns WKT.

=back
 
=head1 INTERNAL METHOD

=over

=item C<< wkt2kmlparser >>

=item C<< wkt2kmlformatter >>

=item C<< coordformatter >>

=item C<< kml2wktbuilder >>

=item C<< coordbuilder >>

=back


=head1 DEPENDENCIES

=over

=item C<< Exporter >>

=item C<< XML::Simple >>

=item C<< Test::Base >>

=item C<< XML::Parser >>

=back


=head1 BUGS AND LIMITATIONS

This module is under test phase, need many test case to find bug.
Send test cases are welcome.


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
