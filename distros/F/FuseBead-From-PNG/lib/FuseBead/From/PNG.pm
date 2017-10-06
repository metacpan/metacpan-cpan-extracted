package FuseBead::From::PNG;

use strict;
use warnings;

BEGIN {
    $FuseBead::From::PNG::VERSION = '0.03';
}

use Image::PNG::Libpng qw(:all);
use Image::PNG::Const qw(:all);

use FuseBead::From::PNG::Const qw(:all);

use FuseBead::From::PNG::Bead;

use Data::Debug;

use Memoize;
memoize('_find_bead_color', INSTALL => '_find_bead_color_fast');

sub new {
    my $class = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my $hash = {};

    $hash->{'filename'} = $args{'filename'};

    $hash->{'unit_size'} = $args{'unit_size'} || 1;

    # mirror plans compared to image by default
    $hash->{'mirror'} = defined $args{'mirror'} ? $args{'mirror'}
                                                    ? 1
                                                    : 0
                                                : 1;

    # White list default
    $hash->{'whitelist'} = ($args{'whitelist'} && ref($args{'whitelist'}) eq 'ARRAY' && scalar(@{$args{'whitelist'}}) > 0) ? $args{'whitelist'} : undef;

    # Black list default
    $hash->{'blacklist'} = ($args{'blacklist'} && ref($args{'blacklist'}) eq 'ARRAY' && scalar(@{$args{'blacklist'}}) > 0) ? $args{'blacklist'} : undef;

    my $self = bless ($hash, ref ($class) || $class);

    return $self;
}

sub bead_dimensions {
    my $self = shift;

    return $self->{'bead_dimensions'} ||= do {
        my $hash = {};

        for my $type (qw/imperial metric/) {
            my $bead_diameter =
                FuseBead::From::PNG::Const->BEAD_DIAMETER
                * ($type eq 'imperial' ? FuseBead::From::PNG::Const->MILLIMETER_TO_INCH : 1);

            $hash->{$type} = {
                bead_diameter => $bead_diameter,
            };
        }

        $hash;
    };
}

sub bead_colors {
    my $self = shift;

    return $self->{'bead_colors'} ||= do {
        my $hash = {};

        for my $color ( BEAD_COLORS ) {
            my ($n_key, $hex_key, $r_key, $g_key, $b_key) = (
                $color . '_NAME',
                $color . '_HEX_COLOR',
                $color . '_RGB_COLOR_RED',
                $color . '_RGB_COLOR_GREEN',
                $color . '_RGB_COLOR_BLUE',
            );

            no strict 'refs';

            $hash->{ $color } = {
                'cid'         => $color,
                'name'        => FuseBead::From::PNG::Const->$n_key,
                'hex_color'   => FuseBead::From::PNG::Const->$hex_key,
                'rgb_color'   => [
                    FuseBead::From::PNG::Const->$r_key,
                    FuseBead::From::PNG::Const->$g_key,
                    FuseBead::From::PNG::Const->$b_key,
                ],
            };
        }

        $hash;
    };
}

sub beads {
    my $self = shift;

    return $self->{'beads'} ||= do {
        my $hash = {};

        for my $color ( BEAD_COLORS ) {
            my $bead = FuseBead::From::PNG::Bead->new( color => $color );

            $hash->{ $bead->identifier } = $bead;
        }

        $hash;
    };
}

sub png {
    my $self = shift;

    return $self->{'png'} ||= do {
        my $png = read_png_file($self->{'filename'}, transforms => PNG_TRANSFORM_STRIP_ALPHA);

        $png;
    };
};

sub png_info {
    my $self = shift;

    return $self->{'png_info'} ||= $self->png->get_IHDR;
}

sub bead_row_length {
    my $self = shift;

    return $self->{'bead_row_length'} ||= $self->png_info->{'width'} / $self->{'unit_size'};
}

sub bead_col_height {
    my $self = shift;

    return $self->{'bead_col_height'} ||= $self->png_info->{'height'} / $self->{'unit_size'};
}

sub process {
    my $self = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my $tally = {
        beads => {},
        plan   => [],
    };

    if ($self->{'filename'}) {
        my @blocks = $self->_png_blocks_of_color;

        my @units = $self->_approximate_bead_colors( blocks => \@blocks );

        my @beads = $self->_generate_bead_list(units => \@units);

        $tally->{'plan'} = [ map { $_->flatten } @beads ];

        my %list;
        for my $bead (@beads) {
            if(! exists $list{ $bead->identifier }) {
                $list{ $bead->identifier } = $bead->flatten;

                delete $list{ $bead->identifier }{'meta'}; # No need for meta in bead list

                $list{ $bead->identifier }{'quantity'} = 1;
            }
            else {
                $list{ $bead->identifier }{'quantity'}++;
            }
        }

        $tally->{'beads'} = \%list;

        $tally->{'info'} = $self->_plan_info();
    }

    if ($args{'view'}) {
        my $view   = $args{'view'};
        my $module = "FuseBead::From::PNG::View::$view";

        $tally = eval {
            (my $file = $module) =~ s|::|/|g;
            require $file . '.pm';

            $module->new($self)->print($tally);
        };

        die "Failed to format as a view ($view). $@" if $@;
    }

    return $tally;
}

sub mirror {
    my $self = shift;
    my $arg  = shift;

    if (defined $arg) {
        $self->{'mirror'} = $arg ? 1 : 0;
    }

    return $self->{'mirror'};
}

sub whitelist { shift->{'whitelist'} }

sub has_whitelist {
    my $self    = shift;
    my $allowed = shift; # arrayref listing filters we can use

    my $found = 0;
    for my $filter ( values %{ $self->_list_filters($allowed) } ) {
        $found += scalar( grep { /$filter/ } @{ $self->whitelist || [] } );
    }

    return $found;
}

sub is_whitelisted {
    my $self    = shift;
    my $val     = shift;
    my $allowed = shift; # arrayref listing filters we can use

    return 1 if ! $self->has_whitelist($allowed); # return true if there is no whitelist

    for my $entry ( @{ $self->whitelist || [] } ) {
        for my $filter( values %{ $self->_list_filters($allowed) } ) {
            next unless $entry =~ /$filter/; # if there is at least a letter at the beginning then this entry has a color we can check

            my $capture = $entry;
            $capture =~ s/$filter/$1/;

            return 1 if $val eq $capture;
        }
    }

    return 0; # value is not in whitelist
}

sub blacklist { shift->{'blacklist'} }

sub has_blacklist {
    my $self    = shift;
    my $allowed = shift; # optional filter restriction

    my $found = 0;

    for my $filter ( values %{ $self->_list_filters($allowed) } ) {
        $found += scalar( grep { /$filter/ } @{ $self->blacklist || [] } );
    }

    return $found;
}

sub is_blacklisted {
    my $self    = shift;
    my $val     = shift;
    my $allowed = shift; # optional filter restriction

    return 0 if ! $self->has_blacklist($allowed); # return false if there is no blacklist

    for my $entry ( @{ $self->blacklist || [] } ) {
        for my $filter( values %{ $self->_list_filters($allowed) } ) {
            next unless $entry =~ /$filter/; # if there is at least a letter at the beginning then this entry has a color we can check

            my $capture = $1 || $entry;

            return 1 if $val eq $capture;
        }
    }

    return 0; # value is not in blacklist
}

sub _png_blocks_of_color {
    my $self = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my @blocks;

    return @blocks unless $self->{'filename'}; # No file, no blocks

    my $pixel_bytecount = 3;

    my $y = -1;

    for my $pixel_row ( @{$self->png->get_rows} ) {
        $y++;

        next unless ($y % $self->{'unit_size'}) == 0;

        my $row = $y / $self->{'unit_size'}; # get actual row of blocks we are current on

        my @values = unpack 'C*', $pixel_row;

        my $row_width = ( scalar(@values) / $pixel_bytecount ) / $self->{'unit_size'};

        for (my $col = 0; $col < $row_width; $col++) {
            my ($r, $g, $b) = (
                $values[ ($self->{'unit_size'} * $pixel_bytecount * $col)     ],
                $values[ ($self->{'unit_size'} * $pixel_bytecount * $col) + 1 ],
                $values[ ($self->{'unit_size'} * $pixel_bytecount * $col) + 2 ]
            );

            $blocks[ ($row * $row_width) + $col ] = {
                r => $r,
                g => $g,
                b => $b,
            };
        }
    }

    return @blocks;
}

sub _color_score {
    my $self      = shift;
    my ($c1, $c2) = @_;

    return abs( $c1->[0] - $c2->[0] ) + abs( $c1->[1] - $c2->[1] ) + abs( $c1->[2] - $c2->[2] );
}

sub _find_bead_color {
    my $self  = shift;
    my $rgb   = [ @_ ];

    my @optimal_color =
        map  { $_->{'cid'} }
        sort { $a->{'score'} <=> $b->{'score'} }
        map  {
            +{
                cid => $_->{'cid'},
                score => $self->_color_score($rgb, $_->{'rgb_color'}),
            };
        }
        values %{ $self->bead_colors };

    my ($optimal_color) = grep {
        $self->is_whitelisted( $_, 'color' )
        && ! $self->is_blacklisted( $_, 'color' )
    } @optimal_color; # first color in list that passes whitelist and blacklist should be the optimal color for tested block

    return $optimal_color;
}

sub _approximate_bead_colors {
    my $self = shift;
    my %args = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    die 'blocks not valid' unless $args{'blocks'} && ref( $args{'blocks'} ) eq 'ARRAY';

    my @colors;

    for my $block (@{ $args{'blocks'} }) {
        push @colors, $self->_find_bead_color_fast( $block->{'r'}, $block->{'g'}, $block->{'b'} );
    }

    return @colors;
}

sub _generate_bead_list {
    my $self = shift;
    my %args = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    die 'units not valid' unless $args{'units'} && ref( $args{'units'} ) eq 'ARRAY';

    my @beads = $self->_bead_list($args{'units'});

    return @beads;
}

sub _bead_list {
    my $self  = shift;
    my @units = ref($_[0]) eq 'ARRAY' ? @{ $_[0] } : @_;

    my $unit_count   = scalar(@units);
    my $row_width    = $self->bead_row_length;
    my $bead_ref     = -1; # artificial auto-incremented id
    my @beads;

    for (my $y = 0; $y < ($unit_count / $row_width); $y++) {
        my @row = splice @units, 0, $row_width;
        my $x   = 0;

        # mirror each row as it is set in the plan if we are mirroring the output
        @row = reverse @row if $self->mirror;

        for my $color ( @row ) {
            push @beads, FuseBead::From::PNG::Bead->new(
                color  => $color,
                meta   => {
                    x   => $x,
                    y   => $y,
                    ref => ++$bead_ref,
                },
            );
            $x++;
        }
    }

    return @beads;
}

sub _list_filters {
    my $self    = shift;
    my $allowed = $_[0] && ref($_[0]) eq 'ARRAY' ? $_[0]
                    : ($_[0]) ? [ shift ]
                    : []; # optional filter restriction

    my $filters = {
        color => qr{^([A-Z_]+)$}i,
        bead  => qr{^([A-Z_]+)$}i,
    };

    $filters = +{ map { $_ => $filters->{$_} } @$allowed } if scalar @$allowed;

    return $filters;
}

sub _plan_info {
    my $self = shift;

    my %info;

    for my $type (qw/metric imperial/) {
        $info{$type} = {
            length        => $self->bead_row_length * $self->bead_dimensions->{$type}->{'bead_diameter'},
            height        => $self->bead_col_height * $self->bead_dimensions->{$type}->{'bead_diameter'},
        };
    }

    $info{'rows'} = $self->bead_row_length;
    $info{'cols'} = $self->bead_col_height;

    return \%info;
}

=pod

=head1 NAME

FuseBead::From::PNG - Convert PNGs into plans to build a two dimensional fuse bead replica.

=head1 SYNOPSIS

  use FuseBead::From::PNG;

  my $object = FuseBead::From::PNG;

  $object->bead_tally();

=head1 DESCRIPTION

Convert a PNG into a block list and plans to build a fuse bead replica of the PNG. This is for projects that use fuse bead such as perler or hama.

The RGB values where obtained from Bead List with RGB Values (https://docs.google.com/spreadsheets/d/1f988o68HDvk335xXllJD16vxLBuRcmm3vg6U9lVaYpA/edit#gid=0).
Which was posted in the bead color subreddit beadsprites (https://www.reddit.com/r/beadsprites) under this post Bead List with RGB Values (https://www.reddit.com/r/beadsprites/comments/291495/bead_list_with_rgb_values/).

The generate_instructions.pl script under bin/ has been setup to optimally be used the 22k bucket of beads from Perler. (http://www.perler.com/22000-beads-multi-mix-_17000/17000.html)

$hash->{'filename'} = $args{'filename'};

    $hash->{'unit_size'} = $args{'unit_size'} || 1;

    # White list default
    $hash->{'whitelist'} = ($args{'whitelist'} && ref($args{'whitelist'}) eq 'ARRAY' && scalar(@{$args{'whitelist'}}) > 0) ? $args{'whitelist'} : undef;

    # Black list default
    $hash->{'blacklist'} = ($args{'blacklist'} && ref($args{'blacklist'}) eq 'ARRAY' && scalar(@{$args{'blacklist'}}) > 0) ? $args{'blacklist'} : undef;

=head1 USAGE

=head2 new

 Usage     : ->new()
 Purpose   : Returns FuseBead::From::PNG object

 Returns   : FuseBead::From::PNG object
 Argument  :
    filename - Optional. The file name of the PNG to process. Optional but if not provided, can't process the png.
        e.g. filename => '/location/of/the.png'

    unit_size - Optional. The size of pixels squared to determine a single unit of a bead. Defaults to 1.
        e.g. unit_size => 2 # pixelated colors are 2x2 in size

    whitelist - Optional. Array ref of colors, dimensions or color and dimensions that are allowed in the final plan output.
        e.g. whitelist => [ 'BLACK', 'WHITE', '1x1x1', '1x2x1', '1x4x1', 'BLACK_1x6x1' ]

    blacklist - Optional. Array ref of colors, dimensions or color and dimensions that are not allowed in the final plan output.
        e.g. blacklist => [ 'RED', '1x10x1', '1x12x1', '1x16x1', 'BLUE_1x8x1' ]

 Throws    :

 Comment   :
 See Also  :

=head2 bead_dimensions

 Usage     : ->bead_dimensions()
 Purpose   : returns a hashref with bead dimension information in millimeters (metric) or inches (imperial)

 Returns   : hashref with bead dimension information, millimeters is default
 Argument  : $type - if set to imperial then dimension information is returned in inches
 Throws    :

 Comment   :
 See Also  :

=head2 bead_colors

 Usage     : ->bead_colors()
 Purpose   : returns bead color constants consolidated as a hash.

 Returns   : hashref with color constants keyed by the official color name in key form.
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 beads

 Usage     : ->beads()
 Purpose   : Returns a list of all possible bead beads

 Returns   : Hash ref with L<FuseBead::From::PNG::Bead> objects keyed by their identifier
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 png

 Usage     : ->png()
 Purpose   : Returns Image::PNG::Libpng object.

 Returns   : Returns Image::PNG::Libpng object. See L<Image::PNG::Libpng> for more details.
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 png_info

 Usage     : ->png_info()
 Purpose   : Returns png IHDR info from the Image::PNG::Libpng object

 Returns   : A hash of values containing information abou the png such as width and height. See get_IHDR in L<Image::PNG::Libpng> for more details.
 Argument  : filename  => the PNG to load and part
             unit_size => the pixel width and height of one unit, blocks are generally identified as Nx1 blocks where N is the number of units of the same color
 Throws    :

 Comment   :
 See Also  :

=head2 bead_row_length

 Usage     : ->bead_row_length()
 Purpose   : Return the width of one row of beads. Since a bead list is a single dimension array this is useful to figure out whict row a bead is on.

 Returns   : The length of a row of beads (image width / unit size)
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 bead_col_height

 Usage     : ->bead_col_height()
 Purpose   : Return the height in beads.

 Returns   : The height of a col of beads (image height / unit size)
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 process

 Usage     : ->process()
 Purpose   : Convert a provided PNG into a list of bead blocks that will allow building of a two dimensional bead replica.

 Returns   : Hashref containing information about particular bead beads found to be needed based on the provided PNG.
             Also included is the build order for those beads.
 Argument  : view => 'a view' - optionally format the return data. options include: JSON and HTML
 Throws    :

 Comment   :
 See Also  :

=head2 mirror

 Usage     : ->mirror()
 Purpose   : Getter / Setter for the mirror option. Set to 1 (true) by default. This option will mirror the image when displaying it as plans. The reason is then the mirror of the image is what is placed on the peg board so that side can be ironed and, when turned over, the image is represented in it's proper orientation.

 Returns   : Either 1 or 0
 Argument  : a true or false value that will set whether the plans are mirrored to the image or not
 Throws    :

 Comment   :
 See Also  :

=head2 whitelist

 Usage     : ->whitelist()
 Purpose   : return any whitelist settings stored in this object

 Returns   : an arrayref of whitelisted colors and/or blocks, or undef
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 has_whitelist

 Usage     : ->has_whitelist(), ->has_whitelist($filter)
 Purpose   : return a true value if there is a whitelist with at least one entry in it based on the allowed filters, otherwise a false value is returned

 Returns   : 1 or 0
 Argument  : $filter - optional scalar containing the filter to restrict test to
 Throws    :

 Comment   :
 See Also  :

=head2 is_whitelisted

 Usage     : ->is_whitelisted($value), ->is_whitelisted($value, $filter)
 Purpose   : return a true if the value is whitelisted, otherwise false is returned

 Returns   : 1 or 0
 Argument  : $value - the value to test, $filter - optional scalar containing the filter to restrict test to
 Throws    :

 Comment   :
 See Also  :

=head2 blacklist

 Usage     : ->blacklist
 Purpose   : return any blacklist settings stored in this object

 Returns   : an arrayref of blacklisted colors and/or blocks, or undef
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 has_blacklist

 Usage     : ->has_blacklist(), ->has_whitelist($filter)
 Purpose   : return a true value if there is a blacklist with at least one entry in it based on the allowed filters, otherwise a false value is returned

 Returns   : 1 or 0
 Argument  : $filter - optional scalar containing the filter to restrict test to
 Throws    :

 Comment   :
 See Also  :

=head2 is_blacklisted

 Usage     : ->is_blacklisted($value), ->is_whitelisted($value, $filter)
 Purpose   : return a true if the value is blacklisted, otherwise false is returned

 Returns   : 1 or 0
 Argument  : $value - the value to test, $filter - optional scalar containing the filter to restrict test to
 Throws    :

 Comment   :
 See Also  :

=head2 _png_blocks_of_color

 Usage     : ->_png_blocks_of_color()
 Purpose   : Convert a provided PNG into a list of rgb values based on [row][color]. Size of blocks are determined by 'unit_size'

 Returns   : A list of hashes contain r, g and b values. e.g. ( { r => #, g => #, b => # }, { ... }, ... )
 Argument  :
 Throws    :

 Comment   :
 See Also  :

 =head2  _color_score

 Usage     : ->_color_score()
 Purpose   : returns a score indicating the likeness of one color to another. The lower the number the closer the colors are to each other.

 Returns   : returns a positive integer score
 Argument  : $c1 - array ref with rgb color values in that order
             $c2 - array ref with rgb color values in that order
 Throws    :

 Comment   :
 See Also  :

=head2 _find_bead_color

 Usage     : ->_find_bead_color
 Purpose   : given an rgb params, finds the optimal bead color

 Returns   : A bead color common name key that can then reference bead color information using L<FuseBead::From::PNG::bead_colors>
 Argument  : $r - the red value of a color
             $g - the green value of a color
             $b - the blue value of a color
 Throws    :

 Comment   : this subroutine is memoized as the name _find_bead_color_fast
 See Also  :

=head2 _approximate_bead_colors

 Usage     : ->_approximate_bead_colors()
 Purpose   : Generate a list of bead colors based on a list of blocks ( array of hashes containing rgb values )

 Returns   : A list of bead color common name keys that can then reference bead color information using L<FuseBead::From::PNG::bead_colors>
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 _generate_bead_list

 Usage     : ->_approximate_bead_colors()
 Purpose   : Generate a list of bead colors based on a list of blocks ( array of hashes containing rgb values ) for either knob orientation (calls _knob_forward_bead_list or _knob_up_bead_list)

 Returns   : A list of bead color common name keys that can then reference bead color information using L<FuseBead::From::PNG::bead_colors>
 Argument  :
 Throws    :

 Comment   :
 See Also  :

 =head2 _bead_list

 Usage     : ->_bead_list()
 Purpose   : Generate a list of bead colors based on a list of blocks ( array of hashes containing rgb values ) for knob up orientation

 Returns   : A list of bead color common name keys that can then reference bead color information using L<FuseBead::From::PNG::bead_colors>
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 _list_filters

 Usage     : ->_list_filters()
 Purpose   : return whitelist/blacklist filters

 Returns   : an hashref of filters
 Argument  : an optional filter restriction to limit set of filters returned to just one
 Throws    :

 Comment   :
 See Also  :

=head1 BUGS

=head1 SUPPORT

=head1 AUTHOR

    Travis Chase
    CPAN ID: GAUDEON
    gaudeon@cpan.org
    https://github.com/gaudeon/FuseBead-From-Png

=head1 COPYRIGHT

This program is free software licensed under the...

    The MIT License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

1;
