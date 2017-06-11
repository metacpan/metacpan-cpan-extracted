package Geo::Coordinates::OSGB::Grid;

use Geo::Coordinates::OSGB::Maps qw{%maps %name_for_map_series};
use Geo::Coordinates::OSGB qw{is_grid_in_ostn02};

use base qw(Exporter);
use strict;
use warnings;
use Carp;
use 5.008; # At least Perl 5.8 please

our $VERSION = '2.17';

our %EXPORT_TAGS = (all => [qw( 
        parse_grid 
        format_grid

        parse_trad_grid 
        parse_GPS_grid 
        parse_landranger_grid
        parse_map_grid
        
        format_grid_trad 
        format_grid_GPS 
        format_grid_landranger
        format_grid_map
        
        random_grid 
        )]);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

use constant GRID_SQ_LETTERS => 'VWXYZQRSTULMNOPFGHJKABCDE';
use constant GRID_SIZE => sqrt length GRID_SQ_LETTERS;
use constant MINOR_GRID_SQ_SIZE => 100_000;
use constant MAJOR_GRID_SQ_SIZE => GRID_SIZE * MINOR_GRID_SQ_SIZE;
use constant MAJOR_GRID_SQ_EASTING_OFFSET  => 2 * MAJOR_GRID_SQ_SIZE;
use constant MAJOR_GRID_SQ_NORTHING_OFFSET => 1 * MAJOR_GRID_SQ_SIZE;
use constant MAX_GRID_SIZE => MINOR_GRID_SQ_SIZE * length GRID_SQ_LETTERS;

# Produce a random GR 
# A simple approach would pick 0 < E < 700000 and 0 < N < 1250000 but that way
# many GRs produced would be in the sea, so pick a random map, and then find a
# random GR within its bbox and finally check that the resulting pair is
# inside the OSTN02 boundary and actually on some map.

sub random_grid {
    my @preferred_sheets = @_;
    # assume plain sheet numbers are Landranger
    for my $s (@preferred_sheets) {
        if ($s =~ m{\A\d+\Z}xsmio) {
            $s =~ s/\A/A:/xsmio
        }
    }
    my @sheets;
    if (@preferred_sheets) {
        @sheets = grep { exists $maps{$_} } @preferred_sheets;
    }
    else {
        @sheets = keys %maps;
    }
    my ($map, $lle, $lln, $ure, $urn, $easting, $northing);
    while (1) {
        $map = $maps{$sheets[int rand @sheets]};
        ($lle, $lln) = @{$map->{bbox}->[0]};
        ($ure, $urn) = @{$map->{bbox}->[1]};
        $easting  = sprintf "%.3f", $lle + rand ($ure-$lle);
        $northing = sprintf "%.3f", $lln + rand ($urn-$lln);
        last if is_grid_in_ostn02($easting, $northing) 
             && 0 != _winding_number($easting, $northing, $map->{polygon});
    }
    return ($easting, $northing);
}

sub format_grid {
    my ($easting, $northing, $options) = @_;

    my $form      = exists $options->{form}   ? uc $options->{form}   : 'SS EEE NNN';
    my $with_maps = exists $options->{maps}   ?    $options->{maps}   : 0;
    my $map_keys  = exists $options->{series} ? uc $options->{series} : join '', sort keys %name_for_map_series;

    my $sq = _grid_to_sq($easting,$northing);
    if ( !$sq ) {
        croak "Too far off the grid: $easting $northing\n";
    }

    my ($e,$n) = map { int } map { $_ % MINOR_GRID_SQ_SIZE } ($easting, $northing);

    my @sheets = ();
    if ( $with_maps ) {
        while (my ($k,$m) = each %maps) {
            next if index($map_keys, substr($k,0,1)) == -1;
            if ($m->{bbox}->[0][0] <= $easting  && $easting  < $m->{bbox}->[1][0]
             && $m->{bbox}->[0][1] <= $northing && $northing < $m->{bbox}->[1][1]) {
                my $w = _winding_number($easting, $northing, $m->{polygon});
                if ($w != 0) { 
                    push @sheets, $k;
                }
            }
        }
        @sheets = sort @sheets;
    } 

    # special cases
    if ( $form eq 'TRAD' ) {
        $form = 'SS EEE NNN';
    }
    elsif ( $form eq 'GPS' ) {
        $form = 'SS EEEEE NNNNN';
    }
    elsif ( $form eq 'SS' ) {
        return $sq;
    }

    if ( my ($space_a, $e_spec, $space_b, $n_spec) = $form =~ m{ \A S{1,2}(\s*)(E{1,5})(\s*)(N{1,5}) \Z }iosxm ) {
        my $e_len = length $e_spec;
        my $n_len = length $n_spec;
        $e = int($e / 10**(5 - $e_len));
        $n = int($n / 10**(5 - $n_len));

        if ( wantarray ) {
            return ($sq, $e, $n, @sheets)
        }

        my $gr = sprintf "%s%s%0.*d%s%0.*d", $sq, $space_a, $e_len, $e, $space_b, $n_len, $n;
        $gr =~ s/\s+/ /g;

        if ( $with_maps ) {
            if ( @sheets ) {
                return sprintf '%s on %s', $gr, join ', ', @sheets; 
            }
            else {
                return sprintf '%s is not on any maps in series %s', $gr, $map_keys;
            }
        }
        else {
            return $gr;
        }
    }

    croak "Format $form was not recognized";
}

sub format_grid_trad {
    my ($easting, $northing) = @_;
    return format_grid($easting, $northing, { form => 'SS EEE NNN' })
}

sub format_grid_GPS {
    my ($easting, $northing) = @_;
    return format_grid($easting, $northing, { form => 'SS EEEEE NNNNN' })
}

sub format_grid_map {
    my ($easting, $northing, $options) = @_;
    if ( defined $options ) {
        $options->{maps} = 1
    }
    else {
        $options = { maps => 1 }
    }
    return format_grid($easting, $northing, $options)
}

sub format_grid_landranger {
    my ($easting,$northing) = @_;

    my ($sq, $e, $n, @sheets) = format_grid($easting, $northing, { form => 'SS EEE NNN', maps => 1, series => 'A' });

    for my $s (@sheets) {
        $s =~ s/\AA://xsm;
    }
    
    return ($sq, $e, $n, @sheets) if wantarray;

    if (!@sheets )    { return sprintf '%s %03d %03d is not on any Landranger sheet', $sq, $e, $n }
    if ( @sheets==1 ) { return sprintf '%s %03d %03d on Landranger sheet %s'        , $sq, $e, $n, $sheets[0] }
    if ( @sheets==2 ) { return sprintf '%s %03d %03d on Landranger sheets %s and %s', $sq, $e, $n, @sheets }

    my $phrase = join ', ', @sheets[0..($#sheets-1)], "and $sheets[-1]";
    return sprintf '%s %03d %03d on Landranger sheets %s', $sq, $e, $n, $phrase;

}

sub _grid_to_sq {
    my ($e, $n) = @_;
    
    $e += MAJOR_GRID_SQ_EASTING_OFFSET;
    $n += MAJOR_GRID_SQ_NORTHING_OFFSET;
    return if !(0 <= $e && $e < MAX_GRID_SIZE && 0 <= $n && $n < MAX_GRID_SIZE);

    my $major_index = int $e / MAJOR_GRID_SQ_SIZE + GRID_SIZE * int $n / MAJOR_GRID_SQ_SIZE;
    $e = $e % MAJOR_GRID_SQ_SIZE;
    $n = $n % MAJOR_GRID_SQ_SIZE;
    my $minor_index = int $e / MINOR_GRID_SQ_SIZE + GRID_SIZE * int $n / MINOR_GRID_SQ_SIZE;
    return 
       substr(GRID_SQ_LETTERS, $major_index, 1) .
       substr(GRID_SQ_LETTERS, $minor_index, 1);
}

sub _get_grid_square_offsets {
    my $s = shift;
    return unless length $s > 1;
    
    my $a = index GRID_SQ_LETTERS, uc substr $s, 0, 1;
    return if 0 > $a;

    my $b = index GRID_SQ_LETTERS, uc substr $s, 1, 1;
    return if 0 > $b;

    my ($X, $Y) = ($a % GRID_SIZE, int $a / GRID_SIZE);
    my ($x, $y) = ($b % GRID_SIZE, int $b / GRID_SIZE);

    return (
        MAJOR_GRID_SQ_SIZE * $X - MAJOR_GRID_SQ_EASTING_OFFSET  + MINOR_GRID_SQ_SIZE * $x, 
        MAJOR_GRID_SQ_SIZE * $Y - MAJOR_GRID_SQ_NORTHING_OFFSET + MINOR_GRID_SQ_SIZE * $y
    );
}

sub _get_eastnorthings {
    my $s = shift;
    my $numbers = $s;
    $numbers =~ tr/0-9//cd; # avoid using "r" here as it requires perl >= 5.14
    my $len = length $numbers;
    croak "No easting or northing found" if $len == 0;
    croak "Easting and northing have different lengths in $s" if $len % 2;
    croak "Too many digits in $s" if $len > 10;

    # this trick lets us pad with zeros on the right
    my $e = reverse sprintf "%05d", scalar reverse substr $numbers, 0, $len/2;
    my $n = reverse sprintf "%05d", scalar reverse substr $numbers,    $len/2;
    return ($e, $n)
}

sub parse_grid {

    my $options = 'HASH' eq ref $_[-1] ? pop @_ : { };

    my $figs = exists $options->{figs} ? $options->{figs} : 3;

    my @out;

    my $s = @_ < 3 ? "@_" : sprintf "%s %0.*d %0.*d", $_[0], $figs, $_[1], $figs, $_[2];

    # normal case : TQ 123 456 etc
    if ( my ($E, $N) = _get_grid_square_offsets($s) ) {
        my ($e, $n) = length $s > 2 ? _get_eastnorthings(substr $s, 2) : (0,0);
        @out = ($E+$e, $N+$n);
        return wantarray ? @out : "@out";
    }

    # sheet id instead of grid sq
    my $sheet_ref_pattern = qr'\A([A-Z]:)?([0-9NEWSOL/]+?)(\.[a-z]+)?(?:[ -/.]([ 0-9]+))?\Z'msxio;
    my ($prefix, $sheet, $suffix, $numbers) = $s =~ m/$sheet_ref_pattern/;

    if (defined $sheet) {

        $prefix //= "A:";
        $suffix //= "";
        $sheet = $prefix . $sheet . $suffix;

        if (exists $maps{$sheet}) { 
            my ($E, $N)  = @{$maps{$sheet}->{bbox}[0]};  # NB we need the bbox corner so that it is left and below all points on the map

            if (defined $numbers) {
                my ($e, $n) = _get_eastnorthings($numbers);
                $E = $E + ($e-$E) % MINOR_GRID_SQ_SIZE;
                $N = $N + ($n-$N) % MINOR_GRID_SQ_SIZE;

                my $w = _winding_number($E, $N, $maps{$sheet}->{polygon});
                if ($w == 0) {
                    croak sprintf "Grid reference %s = (%d, %d) is not on sheet %s", scalar format_grid($E,$N), $e, $n, $sheet;
                }
            }
            return wantarray ? ($E, $N) : "$E $N";
        }
    }

    # just a pair of numbers
    if ( @out = $s =~ m{\A (\d+(?:\.\d+)?) \s+ (\d+(?:\.\d+)?) \Z}xsmio ) { # eee nnn
        return wantarray ? @out : "@out";
    }

    croak "Failed to parse a grid reference from $s";
}

*parse_trad_grid       = \&parse_grid;
*parse_GPS_grid        = \&parse_grid;
*parse_landranger_grid = \&parse_grid;
*parse_map_grid        = \&parse_grid;

# is $pt left of $a--$b?
sub _is_left {
    my ($x, $y, $a, $b) = @_;
    return ( ($b->[0] - $a->[0]) * ($y - $a->[1]) - ($x - $a->[0]) * ($b->[1] - $a->[1]) );
}

# adapted from http://geomalgorithms.com/a03-_inclusion.html
sub _winding_number {
    my ($x, $y, $poly) = @_;
    my $w = 0;
    for (my $i=0; $i < $#$poly; $i++ ) {
        if ( $poly->[$i][1] <= $y ) {
            if ($poly->[$i+1][1]  > $y && _is_left($x, $y, $poly->[$i], $poly->[$i+1]) > 0 ) {
                $w++;
            }
        }
        else {
            if ($poly->[$i+1][1] <= $y && _is_left($x, $y, $poly->[$i], $poly->[$i+1]) < 0 ) {
                $w--;
            }
        }
    }
    return $w;
}

1;

__END__

=pod

=head1 NAME

Geo::Coordinates::OSGB::Grid - Format and parse British National Grid references

=head1 VERSION

2.17

=head1 SYNOPSIS

  use Geo::Coordinates::OSGB::Grid qw/parse_grid format_grid/;

  my ($e,$n) = parse_grid('TQ 23451 09893');
  my $gr     = format_grid($e, $n); # "TQ 234 098"     

=head1 DESCRIPTION

This module provides useful functions for parsing and formatting OSGB
grid references.  Some detailed background is given in C<background.pod>
and on the OS web site.  

=head1 SUBROUTINES AND METHODS

=head2 C<format_grid(e, n)>

Formats an (easting, northing) pair into traditional `full national grid
reference' with two letters and two sets of three numbers, like this `SU
387 147'.  

    $gridref = format_grid(438710.908, 114792.248); # SU 387 147

If you want the individual components call it in a list context.

    ($sq, $e, $n) = format_grid(438710.908, 114792.248); # ('SU', 387, 147)

Note that rather than being rounded, the easting and northing are
B<truncated> to hectometres (as the OS system demands), so the grid
reference refers to the lower left corner of the relevant 100m square.
The system is described below the legend on all OS Landranger maps.

The format grid routine takes an optional third argument to control the
form of grid reference returned.  This should be a hash reference with
one or more of the keys shown below (with the default values).

    format_grid(e, n, {form => 'SS EEE NNN', maps => 0, series => 'ABCHJ'})

=head3 Options for C<format_grid>

=over 4

=item form  

Controls the format of the grid reference.  With C<$e, $n> set as above:

    Format          produces        Format            produces       
    ----------------------------------------------------------------
    'SS'            SU
    'SSEN'          SU31            'SS E N'          SU 3 1         
    'SSEENN'        SU3814          'SS EE NN'        SU 38 14       
    'SSEEENNN'      SU387147        'SS EEE NNN'      SU 387 147     
    'SSEEEENNNN'    SU38711479      'SS EEEE NNNN'    SU 3871 1479 
    'SSEEEEENNNNN'  SU3871014792    'SS EEEEE NNNNN'  SU 38710 14792 

You can't leave out the SS, you can't have N before E, and there must be
the same number of Es and Ns.

There are two other special formats:

     form => 'TRAD' is equivalent to form => 'SS EEE NNN'
     form => 'GPS'  is equivalent to form => 'SS EEEEE NNNNN'

In a list context, this option means that the individual components are
returned appropriately truncated as shown.  So with C<SS EEE NNN> you
get back C<('SU', 387, 147)> and B<not> C<('SU', 387.10908, 147.92248)>.
The format can be given as upper case or lower case or a mixture.  If
you want just the local easting and northing without the grid square,
get the individual parts in a list context and format them yourself:

    my $gr = sprintf('Grid ref %2$s %3$s on Sheet %4$s', format_grid_landranger($e, $n))
    # returns: Grid ref 387 147 on Sheet 196 

=item maps

Controls whether to include a list of map sheets after the grid
reference.  Set it to 1 (or any true value) to include the list, and to
0 (or any false value) to leave it out.  The default is C<< maps => 0
>>.

In a scalar context you get back a string like this:

    SU 387 147 on A:196, B:OL22E, C:180

In a list context you get back a list like this:

    ('SU', 387, 147, A:196, B:OL22E, C:180)

=item series

This option is only used when C<maps> is true.  It controls which series
of maps to include in the list of sheets.  Currently the series included
are:

C<A> : OS Landranger 1:50000 maps

C<B> : OS Explorer 1:25000 maps (some of these are designated as `Outdoor Leisure' maps)

C<C> : OS Seventh Series One-Inch 1:63360 maps

C<H> : Harvey British Mountain maps - mainly at 1:40000

C<J> : Harvey Super Walker maps - mainly at 1:25000

so if you only want Explorer maps use: C<< series => 'B' >>, and if you
want only Explorers and Landrangers use: C<< series => 'AB' >>, and so
on. 

Note that the numbers returned for the Harvey maps have been invented
for the purposes of this module.  They do not appear on the maps
themselves; instead the maps have titles.  You can use the numbers
returned as an index to the data in L<Geo::Coordinates::OSGB::Maps> to
find the appropriate title.

=back 

=head2 C<format_grid_trad(e,n)>

Equivalent to C<< format_grid(e,n, { form => 'trad' }) >>.

=head2 C<format_grid_GPS(e,n)>

Equivalent to C<< format_grid(e,n, { form => 'gps' }) >>.

=head2 C<format_grid_map(e,n)>

Equivalent to C<< format_grid(e,n, { maps => 1 }) >>.

=head2 C<format_grid_landranger(e,n)>

Equivalent to

   format_grid(e,n,{ form => 'ss eee nnn', maps => 1, series => 'A' }) 

except that the leading "A:" will be stripped from any sheet names
returned, and you get a slightly fancier set of phrases in a scalar
context depending on how many map numbers are in the list of sheets.


=head2 C<parse_grid>

The C<parse_grid> routine extracts a (easting, northing) pair from a
string, or a list of arguments, representing a grid reference.  The pair
returned are in units of metres from the false origin of the grid, so
that you can pass them to C<format_grid> or C<grid_to_ll>.

The arguments should be in one of the following forms

=over 4

=item * 

A single string representing a grid reference

  String                        ->  interpreted as   
  --------------------------------------------------
  parse_grid("TA 123 678")      ->  (512300, 467800) 
  parse_grid("TA 12345 67890")  ->  (512345, 467890) 

The spaces are optional in all cases.  You can also refer to a 100km
square as C<TA> which will return C<(500000,400000)>, a 10km square as
C<TA16> which will return C<(510000, 460000)>, or to a kilometre square
as C<TA1267> which gives C<(512000, 467000)>.  For completeness you can
also use C<TA 1234 6789> to refer to a decametre square C<(512340,
467890)> but you might struggle to find a use for that one.

=item * 

A list representing a grid reference

  List                             ->  interpreted as   
  -----------------------------------------------------
  parse_grid('TA', 0, 0)           ->  (500000, 400000) 
  parse_grid('TA', 123, 678)       ->  (512300, 467800) 
  parse_grid('TA', 12345, 67890)   ->  (512345, 467890) 
  parse_grid('TA', '123 678')      ->  (512300, 467800) 
  parse_grid('TA', '12345 67890')  ->  (512345, 467890) 

If you are processing grid references from some external data source
beware that if you use a list with bare numbers you may lose any leading
zeros for grid references close to the SW corner of a grid square.  This
can lead to some ambiguity.  Either make the numbers into strings to
preserve the leading digits or supply a hash of options as a fourth
argument with the `figs' option to define how many figures are supposed
to be in each easting and northing.  Like this:

  List                                     ->  interpreted as   
  -------------------------------------------------------------
  parse_grid('TA', 123, 8)                 ->  (512300, 400800) 
  parse_grid('TA', 123, 8, { figs => 5 })  ->  (500123, 400008) 

The default setting of figs is 3, which assumes you are using
hectometres as in a traditional grid reference.

=item * 

A string or list representing a map sheet and a grid reference on that
sheet

     Map input                      ->  interpreted as    
     ----------------------------------------------------
     parse_grid('A:164/352194')     ->  (435200, 219400) 
     parse_grid('B:OL43E/914701')   ->  (391400, 570100) 
     parse_grid('B:OL43E 914 701')  ->  (391400, 570100) 
     parse_grid('B:OL43E','914701') ->  (391400, 570100) 
     parse_grid('B:OL43E',914,701)  ->  (391400, 570100)

Again spaces are optional, but you need some non-digit between the map
identifier and the grid reference.  There are also some constraints: the
map identifier must be one defined in L<Geo::Coordinates::OSGB::Maps>;
and the following grid reference must actually be on the given sheet.
Note also that you need to supply a specific sheet for a map that has
more than one.  The given example would fail if the map was given as
`B:OL43', since that map has two sheets: `B:OL43E' and `B:OL43W'.

If you give the identifier as just a number, it's assumed that you
wanted a Landranger map;

     parse_grid('176/224711')  ->  (522400, 171100) 
     parse_grid(164,513,62)    ->  (451300, 206200) 

C<parse_grid> will croak of you pass it a sheet identifier that is not
defined in L<Geo::Coordinates::OSGB::Maps>.  It will also croak if the
supplied easting and northing are not actually on the sheet.

If you just want the corner of a particular map, just pass the sheet name:

     parse_grid('A:82')        -> (195000, 530000)
     parse_grid(161)           -> (309000, 205000)

Again, it's assumed that you want a Landranger map.  The grid reference returned
is the SW corner of the particular sheet.  This is usually obvious, but less so
for some of the oddly shaped 1:25000 sheets, or Harvey's maps.  What you actually get
is the first point defined in the maps polygon, as defined in Maps.  If in doubt you
should work directly with the data in L<Geo::Coordinates::OSGB::Maps>.

=back  

=head2 C<parse_trad_grid(grid_ref)>

This is included only for backward compatibility.  It is now just a
synonym for C<parse_grid>.

=head2 C<parse_GPS_grid(grid_ref)>

This is included only for backward compatibility.  It is now just a
synonym for C<parse_grid>.

=head2 C<parse_landranger_grid(sheet, e, n)>

This is included only for backward compatibility.  It is now just a
synonym for C<parse_grid>.

=head2 C<parse_map_grid(sheet, e, n)>

This is included only for backward compatibility.  It is now just a
synonym for C<parse_grid>.

=head2 C<random_grid([sheet1, sheet2, ...])>

Takes an optional list of map sheet identifiers, and returns a random
easting and northing for some place covered by one of the maps.  There's
no guarantee that the point will not be in the sea, but it will be
within the bounding box of one of the maps and it should be within one
of the areas covered by the OSTN02 data set.

=over 4

=item *

If you omit the list of sheets, then one of map sheets defined in
L<Geo::Coordinates::OSGB::Maps> will be picked at random.  

=item *

As a convenience whole numbers in the range 1..204 will be interpreted
as Landranger sheets, as if you had written C<A:1>, C<A:2>, etc. 

=item *

Any sheet identifiers in the list that are not defined in
L<Geo::Coordinates::OSGB::Maps> will be (silently) ignored.  

=item *

The easting and northing are returned as meters from the grid origin, so
that they are suitable for input to the C<format_grid> routines.

=back


=head1 EXAMPLES

  use Geo::Coordinates::OSGB::Grid 
     qw/parse_grid 
        format_grid 
        format_grid_landranger/;

  # Get full coordinates in metres from GR
  my ($e,$n) = parse_grid('TQ 23451 09893');

  # Reading and writing grid references
  # Format full easting and northing into traditional formats
  my $gr1 = format_grid($e, $n);                              # "TQ 234 098"     
  my $gr2 = format_grid($e, $n, { form => 'SSEEENNN' } );     # "TQ234098"       
  my $gr3 = format_grid($e, $n, { form => 'SSEEEEENNNNN'} );  # "TQ 23451 09893" 
  my $gr4 = format_grid($e, $n, { form => 'gps'} );           # "TQ 23451 09893" 
  my $gr5 = format_grid_landranger($e, $n);# "TQ 234 098 on Landranger sheet 198"

  # or call in list context to get the individual parts
  my ($sq, $ee, $nn) = format_grid($e, $n); # ('TQ', 234, 98)

  # parse routines to convert from these formats to full e,n
  ($e,$n) = parse_grid('TQ 234 098');
  ($e,$n) = parse_grid('TQ234098'); # spaces optional
  ($e,$n) = parse_grid('TQ',234,98); # or even as a list
  ($e,$n) = parse_grid('TQ 23451 09893'); # as above..

  # You can also get grid refs from individual maps.
  # Sheet between 1..204; gre & grn must be 3 or 5 digits long
  ($e,$n) = parse_grid(176,123,994);
  # put leading zeros in quotes 
  ($e,$n) = parse_grid(196,636,'024');

For more examples of parsing and formatting look at the test files.

=head1 BUGS AND LIMITATIONS

The useful area of these routines is confined to the British Isles, not
including Ireland or the Channel Islands.  But very little range checking is
done, so you can generate pseudo grid references for points that are some way
outside this useful area.  For example we have St Peter Port in Guernsey at
C<XD 611 506> and Rockall at C<MC 035 165>.  The working area runs from square
C<AA> in the far north west to C<ZZ> in the far south east.  In WGS84 terms the
corners run from 64.75N 32.33W (Iceland) to 65.8N 22.65E (Norway) to 44.5N
11.8E (Venice) to 44N 19.5W (the Western Approaches).  This is something of a 
geodesy toy rather than a useful function.

=head1 DIAGNOSTICS

=head2 Messages from C<format_grid>

In case of error C<format_grid> will die with a message.  Possible
messages are:

=over 4

=item *

Format ... was not recognized

The format code you supplied with C<< { form => ... } >> did not match
any of the expected patterns.

=item * 

Too far off the grid: ...

The (easting, northing) pair you supplied are too far away from the OS
grid to be formatted with a valid grid square letter combination.

=back

=head2 Messages from C<parse_grid>

In case of error C<parse_grid> will die with one of the following
messages:

=over 4

=item *

No easting or northing found

This means you passed something more than a 2-letter grid square but
there were no numbers found in the latter part of the string.

=item * 

Easting and northing have different lengths in ...

The easting and northing you supply must have same length to avoid
ambiguity.

=item *

Too many digits in ...

You have supplied more than 10 digits.

=item *

Grid reference .... is not on sheet ...

You can get this if you pass a map sheet identifier and a short grid
ref, but the grid ref is not actually on that particular sheet.

=item *

Failed to parse a grid reference from ...

This is the catch all message issued if none of the patterns matches
your input.

=back

If you get an unexpected result from any of these subroutines, please
generate a test case to reproduce your result and get in touch to ask me
about it.

=head1 CONFIGURATION AND ENVIRONMENT

There is no configuration required either of these modules or your
environment.  It should work on any recent version of Perl better than
5.8, on any platform.

=head1 DEPENDENCIES

Perl 5.08 or better.

=head1 INCOMPATIBILITIES

None known.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2002-2016 Toby Thurston

OSTN02 transformation data included in this module is freely available
from the Ordnance Survey but remains Crown Copyright (C) 2002

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=head1 AUTHOR

Toby Thurston -- 16 Feb 2016 

toby@cpan.org

=head1 SEE ALSO

See L<Geo::Coordinates::OSGB>. 

=cut
