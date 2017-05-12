package Lego::From::PNG;

use strict;
use warnings;

BEGIN {
    $Lego::From::PNG::VERSION = '0.04';
}

use Image::PNG::Libpng qw(:all);
use Image::PNG::Const qw(:all);

use Lego::From::PNG::Const qw(:all);

use Lego::From::PNG::Brick;

use Data::Debug;

use Memoize;
memoize('_find_lego_color', INSTALL => '_find_lego_color_fast');

sub new {
    my $class = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my $hash = {};

    $hash->{'filename'} = $args{'filename'};

    $hash->{'unit_size'} = $args{'unit_size'} || 1;

    # Brick depth and height defaults
    $hash->{'brick_depth'} = 1;

    $hash->{'brick_height'} = 1;

    # White list default
    $hash->{'whitelist'} = ($args{'whitelist'} && ref($args{'whitelist'}) eq 'ARRAY' && scalar(@{$args{'whitelist'}}) > 0) ? $args{'whitelist'} : undef;

    # Black list default
    $hash->{'blacklist'} = ($args{'blacklist'} && ref($args{'blacklist'}) eq 'ARRAY' && scalar(@{$args{'blacklist'}}) > 0) ? $args{'blacklist'} : undef;

    # Dimension measurement formats
    $hash->{'metric'} = $args{'metric'} || 0;

    $hash->{'imperial'} = $args{'imperial'} || 0;

    $hash->{'metric'} = 1 if ! $hash->{'metric'} && ! $hash->{'imperial'};

    my $self = bless ($hash, ref ($class) || $class);

    return $self;
}

sub lego_dimensions {
    my $self = shift;

    return $self->{'lego_dimensions'} ||= do {
        my $hash = {};

        for my $type (qw/imperial metric/) {
            my $lego_unit_length =
                Lego::From::PNG::Const->LEGO_UNIT
                * Lego::From::PNG::Const->LEGO_UNIT_LENGTH
                * ($type eq 'imperial' ? Lego::From::PNG::Const->MILLIMETER_TO_INCH : 1);

            my $lego_unit_depth =
                Lego::From::PNG::Const->LEGO_UNIT
                * Lego::From::PNG::Const->LEGO_UNIT_DEPTH
                * ($type eq 'imperial' ? Lego::From::PNG::Const->MILLIMETER_TO_INCH : 1);

            my $lego_unit_height =
                Lego::From::PNG::Const->LEGO_UNIT
                * Lego::From::PNG::Const->LEGO_UNIT_HEIGHT
                * ($type eq 'imperial' ? Lego::From::PNG::Const->MILLIMETER_TO_INCH : 1);

            my $lego_unit_stud_diameter =
                Lego::From::PNG::Const->LEGO_UNIT
                * Lego::From::PNG::Const->LEGO_UNIT_STUD_DIAMETER
                * ($type eq 'imperial' ? Lego::From::PNG::Const->MILLIMETER_TO_INCH : 1);

            my $lego_unit_stud_height =
                Lego::From::PNG::Const->LEGO_UNIT
                * Lego::From::PNG::Const->LEGO_UNIT_STUD_HEIGHT
                * ($type eq 'imperial' ? Lego::From::PNG::Const->MILLIMETER_TO_INCH : 1);

            my $lego_unit_stud_spacing =
                Lego::From::PNG::Const->LEGO_UNIT
                * Lego::From::PNG::Const->LEGO_UNIT_STUD_SPACING
                * ($type eq 'imperial' ? Lego::From::PNG::Const->MILLIMETER_TO_INCH : 1);

            my $lego_unit_edge_to_stud =
                Lego::From::PNG::Const->LEGO_UNIT
                * Lego::From::PNG::Const->LEGO_UNIT_EDGE_TO_STUD
                * ($type eq 'imperial' ? Lego::From::PNG::Const->MILLIMETER_TO_INCH : 1);

            $hash->{$type} = {
                lego_unit_length        => $lego_unit_length,
                lego_unit_depth         => $lego_unit_depth,
                lego_unit_height        => $lego_unit_height,
                lego_unit_stud_diameter => $lego_unit_stud_diameter,
                lego_unit_stud_height   => $lego_unit_stud_height,
                lego_unit_stud_spacing  => $lego_unit_stud_spacing,
                lego_unit_edge_to_stud  => $lego_unit_edge_to_stud,
            };
        }

        $hash;
    };
}

sub lego_colors {
    my $self = shift;

    return $self->{'lego_colors'} ||= do {
        my $hash = {};

        for my $color ( LEGO_COLORS ) {
            my ($on_key, $cn_key, $hex_key, $r_key, $g_key, $b_key) = (
                $color . '_OFFICIAL_NAME',
                $color . '_COMMON_NAME',
                $color . '_HEX_COLOR',
                $color . '_RGB_COLOR_RED',
                $color . '_RGB_COLOR_GREEN',
                $color . '_RGB_COLOR_BLUE',
            );

            no strict 'refs';

            $hash->{ $color } = {
                'cid'           => $color,
                'official_name' => Lego::From::PNG::Const->$on_key,
                'common_name'   => Lego::From::PNG::Const->$cn_key,
                'hex_color'     => Lego::From::PNG::Const->$hex_key,
                'rgb_color'     => [
                    Lego::From::PNG::Const->$r_key,
                    Lego::From::PNG::Const->$g_key,
                    Lego::From::PNG::Const->$b_key,
                ],
            };
        }

        $hash;
    };
}

sub lego_bricks {
    my $self = shift;

    return $self->{'lego_bricks'} ||= do {
        my $hash = {};

        for my $color ( LEGO_COLORS ) {
            for my $length ( LEGO_BRICK_LENGTHS ) {
                my $brick = Lego::From::PNG::Brick->new( color => $color, length => $length );

                $hash->{ $brick->identifier } = $brick;
            }
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

sub block_row_length {
    my $self = shift;

    return $self->{'block_row_length'} ||= $self->png_info->{'width'} / $self->{'unit_size'};
}

sub block_row_height {
    my $self = shift;

    return $self->{'block_row_height'} ||= $self->png_info->{'height'} / $self->{'unit_size'};
}

sub process {
    my $self = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my $tally = {
        bricks => {},
        plan   => [],
    };

    if($self->{'filename'}) {
        my @blocks = $self->_png_blocks_of_color;

        my @units = $self->_approximate_lego_colors( blocks => \@blocks );

        my @bricks = $self->_generate_brick_list(units => \@units);

        $tally->{'plan'} = [ map { $_->flatten } @bricks ];

        my %list;
        for my $brick(@bricks) {
            if(! exists $list{ $brick->identifier }) {
                $list{ $brick->identifier } = $brick->flatten;

                delete $list{ $brick->identifier }{'meta'}; # No need for meta in brick list

                $list{ $brick->identifier }{'quantity'} = 1;
            }
            else {
                $list{ $brick->identifier }{'quantity'}++;
            }
        }

        $tally->{'bricks'} = \%list;

        $tally->{'info'} = $self->_plan_info();
    }

    if($args{'view'}) {
        my $view   = $args{'view'};
        my $module = "Lego::From::PNG::View::$view";

        $tally = eval {
            (my $file = $module) =~ s|::|/|g;
            require $file . '.pm';

            $module->new($self)->print($tally);
        };

        die "Failed to format as a view ($view). $@" if $@;
    }

    return $tally;
}

sub whitelist { shift->{'whitelist'} }

sub has_whitelist {
    my $self    = shift;
    my $allowed = shift; # arrayref listing filters we can use

    my $found = 0;
    for my $filter(values $self->_list_filters($allowed)) {
        $found += scalar( grep { /$filter/ } @{ $self->whitelist || [] } );
    }

    return $found;
}

sub is_whitelisted {
    my $self    = shift;
    my $val     = shift;
    my $allowed = shift; # arrayref listing filters we can use

    return 1 if ! $self->has_whitelist($allowed); # return true if there is no whitelist

    for my $entry( @{ $self->whitelist || [] } ) {
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

    for my $filter(values $self->_list_filters($allowed)) {
        $found += scalar( grep { /$filter/ } @{ $self->blacklist || [] } );
    }

    return $found;
}

sub is_blacklisted {
    my $self    = shift;
    my $val     = shift;
    my $allowed = shift; # optional filter restriction

    return 0 if ! $self->has_blacklist($allowed); # return false if there is no blacklist

    for my $entry( @{ $self->blacklist || [] } ) {
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

    for my $pixel_row( @{$self->png->get_rows} ) {
        $y++;

        next unless ($y % $self->{'unit_size'}) == 0;

        my $row = $y / $self->{'unit_size'}; # get actual row of blocks we are current on

        my @values = unpack 'C*', $pixel_row;

        my $row_width = ( scalar(@values) / $pixel_bytecount ) / $self->{'unit_size'};

        for(my $col = 0; $col < $row_width; $col++) {
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

sub _find_lego_color {
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
        values %{ $self->lego_colors };

    my ($optimal_color) = grep {
        $self->is_whitelisted( $_, 'color' )
        && ! $self->is_blacklisted( $_, 'color' )
    } @optimal_color; # first color in list that passes whitelist and blacklist should be the optimal color for tested block

    return $optimal_color;
}

sub _approximate_lego_colors {
    my $self = shift;
    my %args = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    die 'blocks not valid' unless $args{'blocks'} && ref( $args{'blocks'} ) eq 'ARRAY';

    my @colors;

    for my $block(@{ $args{'blocks'} }) {
        push @colors, $self->_find_lego_color_fast( $block->{'r'}, $block->{'g'}, $block->{'b'} );
    }

    return @colors;
}

sub _generate_brick_list {
    my $self = shift;
    my %args = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    die 'units not valid' unless $args{'units'} && ref( $args{'units'} ) eq 'ARRAY';

    my $unit_count   = scalar(@{ $args{'units'} });
    my @units        = @{ $args{'units'} };
    my $row_width    = $self->block_row_length;
    my $brick_height = 1; # bricks are only one unit high
    my @brick_list;

    for(my $y = 0; $y < ($unit_count / $row_width); $y++) {
        my @row = splice @units, 0, $row_width;

        my $push_color = sub {
           my ($color, $length) = @_;

           if($color) {
                push @brick_list, Lego::From::PNG::Brick->new(
                    color  => $color,
                    depth  => $self->{'brick_depth'},
                    length => $length,
                    height => $self->{'brick_height'},
                    meta   => {
                        y => $y,
                    },
                );
            }
        };

        my $process_color_sample = sub {
            my ($color, $length) = @_;

            return if $length <= 0;

            # Now make sure we find bricks we are allowed to use
            FIND_BRICKS: {
                for( 1 .. $length) { # Only need to loop at least the number of times equal to the length of color found
                    my $valid_length = $length;
                    FIND_VALID_LENGTH: {
                        for(;$valid_length > 0;$valid_length--) {
                            my $dim = join('x',$self->{'brick_depth'},$valid_length,$self->{'brick_height'});
                            my $brk = join('_', $color, $dim);

                            next FIND_VALID_LENGTH if $self->is_blacklisted( $dim, 'dimension' ) || $self->is_blacklisted( $brk, 'brick' );

                            last FIND_VALID_LENGTH if $self->is_whitelisted( $dim, 'dimension' ) && $self->is_whitelisted( $brk, 'brick' );
                        }
                    }

                    $push_color->($color, $valid_length);
                    $length -= $valid_length;

                    last FIND_BRICKS if $length <= 0; # No need to push more bricks, we found them all
                }
            }

            die "No valid bricks found for remaining units of color" if $length > 0; # Catch if we have gremlins in our whitelist/blacklist
        };

        # Run through rows and process colors
        my $next_brick_color = '';
        my $next_brick_length = 0;

        for my $color(@row) {
            if( $color ne $next_brick_color ) {
                $process_color_sample->($next_brick_color, $next_brick_length);

                $next_brick_color = $color;
                $next_brick_length = 0;
            }

            $next_brick_length++;
        }

        $process_color_sample->($next_brick_color, $next_brick_length); # Process last color found
    }

    return @brick_list;
}

sub _list_filters {
    my $self    = shift;
    my $allowed = $_[0] && ref($_[0]) eq 'ARRAY' ? $_[0]
                    : ($_[0]) ? [ shift ]
                    : []; # optional filter restriction

    my $filters = {
        color     => qr{^([A-Z_]+)(?:_\d+x\d+x\d+)?$}i,
        dimension => qr{^(\d+x\d+x\d+)$}i,
        brick     => qr{^([A-Z_]+_\d+x\d+x\d+)$}i,
    };

    $filters = +{ map { $_ => $filters->{$_} } @$allowed } if scalar @$allowed;

    return $filters;
}

sub _plan_info {
    my $self = shift;

    my %info;

    for my $type (qw/metric imperial/) {
        if ($self->{$type}) {
            $info{$type} = {
                depth  => $self->{'brick_depth'} * $self->lego_dimensions->{$type}->{'lego_unit_depth'},
                length => $self->block_row_length * $self->lego_dimensions->{$type}->{'lego_unit_length'},
                height => ($self->block_row_height * $self->lego_dimensions->{$type}->{'lego_unit_height'}) + $self->lego_dimensions->{$type}->{'lego_unit_stud_height'},
            };
        }
    }

    return \%info;
}

=pod

=head1 NAME

Lego::From::PNG - Convert PNGs into plans to build a two dimensional lego replica.

=head1 SYNOPSIS

  use Lego::From::PNG;

  my $object = Lego::From::PNG;

  $object->brick_tally();

=head1 DESCRIPTION

Convert a PNG into a block list and plans to build a two dimensional replica of the PNG. The plans are built with brick
 knobs pointed vertically so the picture will look like a flat surface to the viewer. Meaning the only dimension
 of the brick being determined is the length. Depth and height are all the same for all bricks.

$hash->{'filename'} = $args{'filename'};

    $hash->{'unit_size'} = $args{'unit_size'} || 1;

    # Brick depth and height defaults
    $hash->{'brick_depth'} = 1;

    $hash->{'brick_height'} = 1;

    # White list default
    $hash->{'whitelist'} = ($args{'whitelist'} && ref($args{'whitelist'}) eq 'ARRAY' && scalar(@{$args{'whitelist'}}) > 0) ? $args{'whitelist'} : undef;

    # Black list default
    $hash->{'blacklist'} = ($args{'blacklist'} && ref($args{'blacklist'}) eq 'ARRAY' && scalar(@{$args{'blacklist'}}) > 0) ? $args{'blacklist'} : undef;

=head1 USAGE

=head2 new

 Usage     : ->new()
 Purpose   : Returns Lego::From::PNG object

 Returns   : Lego::From::PNG object
 Argument  :
    filename - Optional. The file name of the PNG to process. Optional but if not provided, can't process the png.
        e.g. filename => '/location/of/the.png'

    unit_size - Optional. The size of pixels squared to determine a single unit of a brick. Defaults to 1.
        e.g. unit_size => 2 # pixelated colors are 2x2 in size

    brick_depth - Optional. The depth of all generated bricks. Defaults to 1.
        e.g. brick_depth => 2 # final depth of all bricks are 2. So 2 x length x height

    brick_height - Optional. The height of all generated bricks. Defaults to 1.
        e.g. brick_height => 2 # final height of all bricks are 2. So depth x length x 2

    whitelist - Optional. Array ref of colors, dimensions or color and dimensions that are allowed in the final plan output.
        e.g. whitelist => [ 'BLACK', 'WHITE', '1x1x1', '1x2x1', '1x4x1', 'BLACK_1x6x1' ]

    blacklist - Optional. Array ref of colors, dimensions or color and dimensions that are not allowed in the final plan output.
        e.g. blacklist => [ 'RED', '1x10x1', '1x12x1', '1x16x1', 'BLUE_1x8x1' ]

 Throws    :

 Comment   :
 See Also  :

=head2 lego_dimensions

 Usage     : ->lego_dimensions()
 Purpose   : returns a hashref with lego dimension information in millimeters (metric) or inches (imperial)

 Returns   : hashref with lego dimension information, millimeters is default
 Argument  : $type - if set to imperial then dimension information is returned in inches
 Throws    :

 Comment   :
 See Also  :

=head2 lego_colors

 Usage     : ->lego_colors()
 Purpose   : returns lego color constants consolidated as a hash.

 Returns   : hashref with color constants keyed by the official color name in key form.
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 lego_bricks

 Usage     : ->lego_bricks()
 Purpose   : Returns a list of all possible lego bricks

 Returns   : Hash ref with L<Lego::From::PNG::Brick> objects keyed by their identifier
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

=head2 block_row_length

 Usage     : ->block_row_length()
 Purpose   : Return the width of one row of blocks. Since a block list is a single dimension array this is useful to figure out whict row a block is on.

 Returns   : The length of a row of blocks (image width / unit size)
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 block_row_height

 Usage     : ->block_row_height()
 Purpose   : Return the height in blocks.

 Returns   : The height of a row of blocks (image height / unit size)
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 process

 Usage     : ->process()
 Purpose   : Convert a provided PNG into a list of lego blocks that will allow building of a two dimensional lego replica.

 Returns   : Hashref containing information about particular lego bricks found to be needed based on the provided PNG.
             Also included is the build order for those bricks.
 Argument  : view => 'a view' - optionally format the return data. options include: JSON and HTML
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

=head2 _find_lego_color

 Usage     : ->_find_lego_color
 Purpose   : given an rgb params, finds the optimal lego color

 Returns   : A lego color common name key that can then reference lego color information using L<Lego::From::PNG::lego_colors>
 Argument  : $r - the red value of a color
             $g - the green value of a color
             $b - the blue value of a color
 Throws    :

 Comment   : this subroutine is memoized as the name _find_lego_color_fast
 See Also  :

=head2 _approximate_lego_colors

 Usage     : ->_approximate_lego_colors()
 Purpose   : Generate a list of lego colors based on a list of blocks ( array of hashes containing rgb values )

 Returns   : A list of lego color common name keys that can then reference lego color information using L<Lego::From::PNG::lego_colors>
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 _generate_brick_list

 Usage     : ->_approximate_lego_colors()
 Purpose   : Generate a list of lego colors based on a list of blocks ( array of hashes containing rgb values )

 Returns   : A list of lego color common name keys that can then reference lego color information using L<Lego::From::PNG::lego_colors>
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
    https://github.com/gaudeon/Lego-From-Png

=head1 COPYRIGHT

This program is free software licensed under the...

    The MIT License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

1;
