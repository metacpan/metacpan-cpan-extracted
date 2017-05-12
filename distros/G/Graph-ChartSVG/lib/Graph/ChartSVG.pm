package  Graph::ChartSVG::Layer;
use Moose;

has 'data'    => ( isa => 'Graph::ChartSVG::Data',    is => 'rw', required => 0 );
has 'glyph'   => ( isa => 'Graph::ChartSVG::Glyph',   is => 'rw', required => 0 );
has 'overlay' => ( isa => 'Graph::ChartSVG::Overlay', is => 'rw', required => 0 );

1;

package  Graph::ChartSVG::Data;
use Moose;

has 'data_set'  => ( isa => 'ArrayRef',       is => 'rw', required => 0 );
has 'type'      => ( isa => 'Str',            is => 'rw', required => 0, default => 'line' );
has 'thickness' => ( isa => 'Num',            is => 'rw', required => 0, default => 1 );
has 'color'     => ( isa => 'Str | ArrayRef', is => 'rw', required => 0, default => '00000000' );
has 'opacity'   => ( isa => 'Num',            is => 'rw', required => 0, default => 1 );
has 'max'       => ( isa => 'Int',            is => 'rw', required => 0 );
has 'last'      => ( isa => 'Int',            is => 'rw', required => 0 );
has 'label'     => ( isa => 'Str',            is => 'rw', required => 0 );
has 'offset'    => ( isa => 'Num',            is => 'rw', required => 0, default => 0 );
has 'scale'     => ( isa => 'Num | ArrayRef', is => 'rw', required => 0, default => 1 );

1;

package Graph::ChartSVG::Frame;
use Moose;

has 'type'      => ( isa => 'Str', is => 'rw', required => 0, default => 'line' );
has 'thickness' => ( isa => 'Num', is => 'rw', required => 0, default => 0 );
has 'color'     => ( isa => 'Str', is => 'rw', required => 0, default => '00000000' );

1;

package  Graph::ChartSVG::Glyph;
use Moose;

has 'x'    => ( isa => 'Str', is => 'rw', required => 1, default => 0 );
has 'y'    => ( isa => 'Str', is => 'rw', required => 1, default => 0 );
has 'type' => ( isa => 'Str', is => 'rw', required => 0, default => 'line' );
has 'filled'    => ( isa => 'Bool',     is => 'rw', required => 0 );
has 'color'     => ( isa => 'Str',      is => 'rw', required => 0, default => '00000000' );
has 'anchor'    => ( isa => 'Str',      is => 'rw', required => 0, default => 'start' );
has 'data_set'  => ( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'thickness' => ( isa => 'Num',      is => 'rw', required => 0, default => 1 );
has 'font'           => ( isa => 'Str', is => 'rw' );
has 'size'           => ( isa => 'Num', is => 'rw' );
has 'font_weight'    => ( isa => 'Str', is => 'rw' );
has 'stretch'        => ( isa => 'Str', is => 'rw' );
has 'letter_spacing' => ( isa => 'Num', is => 'rw' );
has 'word_spacing'   => ( isa => 'Num', is => 'rw' );
has 'label'          => ( isa => 'Str', is => 'rw', required => 0 );

1;

package  Graph::ChartSVG::Border;
use Moose;

has 'left'   => ( isa => 'Num', is => 'rw', required => 0, default => 0 );
has 'right'  => ( isa => 'Num', is => 'rw', required => 0, default => 0 );
has 'top'    => ( isa => 'Num', is => 'rw', required => 0, default => 0 );
has 'bottom' => ( isa => 'Num', is => 'rw', required => 0, default => 0 );

1;

package  Graph::ChartSVG::Label;
use Moose;

has 'color' => ( isa => 'Str', is => 'rw', required => 0, default => '00000000' );
has 'text' => ( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'font' => ( isa => 'Str', is => 'rw' );
has 'font_scaling'       => ( isa => 'Num', is => 'rw', required => 0, default => 1 );
has 'style'              => ( isa => 'Str', is => 'rw', required => 0 );
has 'space'              => ( isa => 'Num', is => 'rw', required => 0, default => 0 );
has 'size'               => ( isa => 'Num', is => 'rw', required => 0, default => 10 );
has 'align'              => ( isa => 'Str', is => 'rw', required => 0, default => 'left' );
has 'rotation'           => ( isa => 'Num', is => 'rw', required => 0, default => 0 );
has 'kerning_correction' => ( isa => 'Num', is => 'rw', required => 0, default => 0 );

1;

package  Graph::ChartSVG::Grid_def;
use Moose;

has 'color' => ( isa => 'Str', is => 'rw', required => 0, default => '00000000' );
has 'number'    => ( isa => 'Num',   is => 'rw', required => 1 );
has 'thickness' => ( isa => 'Num',   is => 'rw', required => 0, default => 1 );
has 'label'     => ( isa => 'Graph::ChartSVG::Label', is => 'rw', required => 0 );
has 'label2'    => ( isa => 'Graph::ChartSVG::Label', is => 'rw', required => 0 );

1;

package  Graph::ChartSVG::Grid;
use Moose;

has 'x'      => ( isa => 'Graph::ChartSVG::Grid_def', is => 'rw', required => 0 );
has 'y'      => ( isa => 'Graph::ChartSVG::Grid_def', is => 'rw', required => 0 );
has 'y_up'   => ( isa => 'Graph::ChartSVG::Grid_def', is => 'rw', required => 0 );
has 'y_down' => ( isa => 'Graph::ChartSVG::Grid_def', is => 'rw', required => 0 );
has 'x_up'   => ( isa => 'Graph::ChartSVG::Grid_def', is => 'rw', required => 0 );
has 'x_down' => ( isa => 'Graph::ChartSVG::Grid_def', is => 'rw', required => 0 );
has 'debord' => ( isa => 'Graph::ChartSVG::Border',   is => 'rw', required => 0, default => sub { Graph::ChartSVG::Border->new } );

1;

package  Graph::ChartSVG::Overlay;
use Moose;

has 'type'     => ( isa => 'Str', is => 'rw', required => 0, default => 'v' );
has 'debord_1' => ( isa => 'Num', is => 'rw', required => 0, default => 0 );
has 'debord_2' => ( isa => 'Num', is => 'rw', required => 0, default => 0 );
has 'data_set' => ( isa => 'HashRef', is => 'rw', required => 0 );
has 'color' => ( isa => 'Str', is => 'rw', required => 0, default => '00000000' );

1;

package Graph::ChartSVG;
use Moose;

use constant PI => 4 * atan2( 1, 1 );

use SVG;
use SVG::Parser qw(SAX=XML::LibXML::SAX::Parser);

use List::Util qw( max  min sum );
# use Math::Complex;
# use Compress::Zlib;
use Hash::Merge qw( merge );
use Data::Serializer;

# use Carp::Clan;
use Carp;
#use Data::Dumper;
# use Devel::Size qw(size total_size);
# use Clone qw(clone);

use MIME::Base64;

use vars qw( $VERSION );

$VERSION = '2.07';

has 'active_size' => ( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'total_size'  => ( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'bg_color'    => ( isa => 'Str',      is => 'rw', required => 0, default => 'ffffffff' );
has 'frame'       => ( isa => 'Graph::ChartSVG::Frame',    is => 'rw', required => 0, default => sub { Graph::ChartSVG::Frame->new } );
has 'grid'        => ( isa => 'Graph::ChartSVG::Grid',     is => 'rw', required => 0 );
#has 'reticle'     => ( isa => 'HashRef',  is => 'rw', required => 0 );
has 'overlay' => ( isa => 'Graph::ChartSVG::Overlay',  is => 'rw', required => 0 );
has 'glyph'   => ( isa => 'ArrayRef', is => 'rw', required => 0 );
#has 'layer'    => ( isa => 'ArrayRef', is => 'rw' ,default => sub { [ Layer->new]} );
has 'layer'   => ( isa => 'ArrayRef[Layer]', is => 'rw' );
has 'image'   => ( isa => 'Str',             is => 'rw' );
has 'svg_raw' => ( isa => 'Str',             is => 'rw' );
has 'border'  => ( isa => 'Graph::ChartSVG::Border',          is => 'rw', required => 0, default => sub { Graph::ChartSVG::Border->new } );
has 'tag' => ( isa => 'Bool', is => 'rw', required => 0 );
#has 'tag' => ( isa => 'Tag', is => 'rw', required => 0 );
#has 'tag' =>  ( isa => 'HashRef', is => 'rw', required => 0 );

sub Tag
{
    my $self = shift;
    my $args = shift;
    if ( exists $self->{ tag } )
    {
        $self->{ tag } = merge( $self->{ tag }, $args );
    }
    else
    {
        $self->{ tag } = $args;
    }
    bless $self;
}

sub label
{
    my $self  = shift;
    my $label = shift;
    foreach my $l ( 1 .. ( scalar @{ $self->{ Layer } } ) )
    {

        my $m = $l - 1;

        if (   defined $self->{ Layer }->[$m]
            && exists $self->{ Layer }->[$m]->{ label }
            && $self->{ Layer }->[$m]->{ label } eq $label )
        {
# carp "$l =>  ".Dumper($self->{ Layer }->[$m]->{ data_set });
            return wantarray
              ? ( $self->{ Layer }->[$m]->{ data_set }, $m )
              : $self->{ Layer }->[$m]->{ data_set };
        }
    }
    return ();
}

sub move
{
    my $self = shift;
    my $from = shift;
    my $to   = shift;
    my $type = 'Layer';
    my @tmp;
    if ( exists $self->{ $type } )
    {
        my $elem = splice @{ $self->{ $type } }, $from, 1;
        @tmp = ( @{ $self->{ $type } }[ 0 .. ( $to - 1 ) ], $elem, @{ $self->{ $type } }[ ( $to ) .. $#{ $self->{ $type } } ] );
    }

    $self->{ $type } = \@tmp;
}

sub add
{
    my $self   = shift;
    my $what   = shift;
    my $where  = shift;
    my $insert = shift;

    my $type = 'Layer';
    my @tmp;
    if ( exists $self->{ $type } )
    {
        @tmp = @{ $self->{ $type } };
    }
    if ( defined $where )
    {
        if ( $where >= 0 )
        {
            if ( !exists $what->{ label } )
            {
                $what->{ label } = $where;
            }
            if ( defined $insert )
            {
                my @t = ( @tmp[ 0 .. ( $where - 1 ) ], $what, @tmp[ $where .. $#tmp ] );
                @tmp = @t;
            }
            else
            {
                $tmp[$where] = $what;
            }
        }
        else
        {
            if ( !exists $what->{ label } )
            {
                $what->{ label } = 0;
            }
            unshift @tmp, $what;
        }
    }
    else
    {
        push @tmp, $what;
    }

    $self->{ $type } = \@tmp;
}

sub render
{
    my $self = shift;
    my @tmp = ( $self->active_size->[0] + $self->border->right + $self->border->left, $self->active_size->[1] + $self->border->top + $self->border->bottom );
    $self->total_size( \@tmp );

    my $svg = SVG->new(
        width      => $self->total_size->[0],
        height     => $self->total_size->[1],
        standalone => 'yes',
# border => 1,
    );

    if ( $self->bg_color )
    {
        my $tag = $svg->rectangle(
            x      => 0,
            y      => 0,
            width  => $self->total_size->[0],
            height => $self->total_size->[1],
            fill   => '#' . ( unpack "a6", $self->bg_color ) || 0,
            id     => 'background'
        );
    }

    my $layer_ind = 0;
    my $data_goup = $svg->group(
        id        => "data",
        transform => "matrix(1,0,0,-1," . ( $self->border->left ) . "," . ( $self->border->top + $self->active_size->[1] ) . ")"
    );
#     my $layer_goup = $svg->group(
#         id        => "layer",
#         transform => "matrix(1,0,0,-1," . ( $self->border->left ) . "," . ( $self->border->top + $self->active_size->[1] ) . ")"
#     );

    my @list_data;
    foreach my $layer ( @{ $self->{ Layer } } )
    {
        my $layer_goup;
        push @list_data, "data_$layer_ind";
        if ( ( ref $layer ) eq 'Graph::ChartSVG::Data' )
        {
            if ( defined $layer->{ data_set } )
            {
                my $scale = $layer->{ scale };

                if ( $layer->{ type } =~ /_up$/ )
                {
                    $scale *= 0.5;
                    $layer_goup = $data_goup->group( id => 'data_' . $layer_ind, transform => "matrix(1,0,0,$scale,0," . ( ( $self->active_size->[1] / 2 ) + $layer->{ offset } ) . " )" );
                }
                elsif ( $layer->{ type } =~ /_down$/ )
                {
                    $scale *= -0.5;
# carp "scale=$scale   act=".$self->active_size->[1]."  off=" .$layer->{ offset };
                    $layer_goup = $data_goup->group( id => 'data_' . $layer_ind, transform => "matrix(1,0,0,$scale,0," . ( ( ( $self->active_size->[1] / 2 ) - $layer->{ offset } ) ) . " )" );
                }
                else
                {
                    if ( $layer->{ offset } )
                    {
                        $layer_goup = $data_goup->group( id => 'data_' . $layer_ind, transform => "matrix(1,0,0,$scale,0," . ( $layer->{ offset } ) . " )" );
                    }
                    else
                    {
                        $layer_goup = $data_goup->group( id => 'data_' . $layer_ind, transform => "matrix(1,0,0,$scale,0,0)" );
                    }
                }

                if ( ref( $layer->{ data_set }->[0] ) eq 'ARRAY' )
                {

                    my @all_xv;
                    my @all_yv;
                    my @all_style;
                    my $stack_size = scalar @{ $layer->{ data_set } };
                    if ( $layer->{ type } =~ /_stack/ )
                    {
                        if ( $layer->{ type } =~ /line|bar/ )
                        {
                            my $max = 0;
                            for my $stack_idx ( 0 .. $#{ $layer->{ data_set } } )
                            {
                                $max = max( $max, $#{ $layer->{ data_set }->[$stack_idx] } );
                            }

                            for my $stack_idx ( 0 .. $#{ $layer->{ data_set } } )
                            {
                                my @xv;
                                my @yv;
                                my $dot = -1;
                                for my $raw_val_idx ( 0 .. $max )
                                {
                                    my $raw_val = $layer->{ data_set }->[$stack_idx][$raw_val_idx];
                                    $dot++;
                                    last if $dot >= $self->active_size->[0];
                                    my $plot_val = ( $raw_val || 0 );
                                    $plot_val =
                                        $plot_val * $scale > $self->active_size->[1]
                                      ? $self->active_size->[1]
                                      : $plot_val;

                                    $xv[$raw_val_idx] = $dot;
                                    $yv[$raw_val_idx] = sum_array( $stack_idx, $raw_val_idx, $layer->{ data_set } );

                                }
                                my %style;
                                if ( $layer->{ type } =~ /bar/ )
                                {

                                    push @xv, $dot;
                                    push @yv, 0;
                                    push @xv, 0;
                                    push @yv, 0;

                                    %style = (
                                        'opacity' => eval( hex( ( unpack "a6 a2", $layer->{ color }->[$stack_idx] ) ) / 255 ) || 1,
                                        'stroke' => '#' . ( unpack "a6", $layer->{ color }->[$stack_idx] ) || 0,
                                        'stroke-width' => $layer->{ thickness },
                                        'fill'         => '#' . ( unpack "a6", $layer->{ color }->[$stack_idx] ) || 0,
                                        'fill-opacity' => eval( hex( ( unpack "a6 a2", $layer->{ color }->[$stack_idx] )[1] ) / 255 ) || 1,
                                        'fill-rule'    => 'nonzero'
                                    );
                                }
                                else
                                {
                                    %style = (
                                        'opacity' => eval( hex( ( unpack "a6 a2", $layer->{ color }->[$stack_idx] )[1] ) / 255 ) || 1,
                                        'stroke' => '#' . ( unpack "a6", $layer->{ color }->[$stack_idx] ) || 0,
                                        'stroke-width' => $layer->{ thickness },
                                        'fill'         => '#ff0000',
                                        'fill-opacity' => 0,
                                        'fill-rule'    => 'nonzero'
                                    );
                                }
                                push @all_xv,    \@xv;
                                push @all_yv,    \@yv;
                                push @all_style, \%style;

                            }

                            foreach ( my $idx = $#all_xv ; $idx >= 0 ; $idx-- )
                            {
                                my $points = $layer_goup->get_path(
                                    x       => $all_xv[$idx],
                                    y       => $all_yv[$idx],
                                    -type   => 'polyline',
                                    -closed => 'true'           #specify that the polyline is NOT closed.
                                );

                                my $id_data;
                                if ( exists $layer->{ label } )
                                {
                                    $id_data = $layer->{ label } . '_' . $idx;
                                }
                                else
                                {
                                    $id_data = 'layerdata_' . $layer_ind . '_' . $idx;
                                }
                                my $tag = $layer_goup->polyline(
                                    %$points,
                                    id    => $id_data,
                                    style => $all_style[$idx]
                                );
                            }
                        }
                    }
                    else
                    {
                        carp( "if data_set not arayref_of_arrayref it should be stack type " );
                    }
                }
                else
                {
                    if ( $layer->{ type } =~ /line|bar/ )
                    {
                        my @xv;
                        my @yv;
                        my $dot = -1;

                        foreach my $raw_val ( @{ $layer->{ data_set } } )
                        {
                            $dot++;

                            last if $dot >= $self->active_size->[0];
                            my $plot_val = ( $raw_val || 0 );
                            $plot_val =
                                $plot_val * $scale > $self->active_size->[1]
                              ? $self->active_size->[1]
                              : $plot_val;

                            push @xv, $dot;
                            push @yv, $plot_val;
                        }
                        my %style;
                        if ( $layer->{ type } =~ /bar/ )
                        {

                            push @xv, $dot;
                            push @yv, 0;
                            push @xv, 0;
                            push @yv, 0;

                            %style = (
                                'opacity' => eval( hex( ( unpack "a6 a2", $layer->{ color } )[1] ) / 255 ) || 1,
                                'stroke' => '#' . ( unpack "a6", $layer->{ color } ) || 0,
                                'stroke-width' => $layer->{ thickness },
                                'fill'         => '#' . ( unpack "a6", $layer->{ color } ) || 0,
                                'fill-opacity' => eval( hex( ( unpack "a6 a2", $layer->{ color } )[1] ) / 255 ) || 1,
                                'fill-rule'    => 'nonzero'
                            );
                        }
                        else
                        {
                            %style = (
                                'opacity' => eval( hex( ( unpack "a6 a2", $layer->{ color } )[1] ) / 255 ) || 1,
                                'stroke' => '#' . ( unpack "a6", $layer->{ color } ) || 0,
                                'stroke-width' => $layer->{ thickness },
                                'fill'         => '#ff0000',
                                'fill-opacity' => 0,
                                'fill-rule'    => 'nonzero'
                            );
                        }
                        my $points = $layer_goup->get_path(
                            x       => \@xv,
                            y       => \@yv,
                            -type   => 'polyline',
                            -closed => 'true'        #specify that the polyline is NOT closed.
                        );

                        my $id_data;
                        if ( exists $layer->{ label } )
                        {
                            $id_data = $layer->{ label };
                        }
                        else
                        {
                            $id_data = 'layerdata_' . $layer_ind;
                        }
                        my $tag = $layer_goup->polyline(
                            %$points,
                            id    => $id_data,
                            style => \%style
                        );
                    }
                }
            }
        }

#######################################
################ Glyph ################
#######################################
        if ( ( ref $layer ) eq 'Graph::ChartSVG::Glyph' )
        {
            $layer_goup = $data_goup->group( id => "data_$layer_ind" );
            my $X = 0;
            my $Y = 0;
            # if ( $layer->{ x } eq 'active_min' )
            # {
# #                  $X += $self->border->left;
            # }
            # elsif ( $layer->{ x } eq 'active_max' )
            # {
                # $X += $self->active_size->[0];
            # }
            # else
            # {
                # if ( exists $layer->{ type } && $layer->{ type } eq 'image' )
                # {
                    # $X = $layer->{ x };
                # }
                # else
                # {
                    # $X += $layer->{ x } - $self->border->left;
                # }
            # }
            # if ( $layer->{ y } eq 'active_max' )
            # {
                # $Y += $self->active_size->[1];
            # }
            # elsif ( $layer->{ y } eq 'active_min' )
            # {
# #                  $Y += $self->border->bottom;
            # }
            # else
            # {
                # if ( exists $layer->{ type } && $layer->{ type } eq 'image' )
                # {
                    # $Y = $layer->y;
                # }
                # else
                # {
                    # $Y += $layer->y - $self->border->bottom;
                # }
            # }

                if ( exists $layer->{ type } && $layer->{ type } eq 'image' )
                { 
                    $X = $layer->{ x };
                    $Y = $layer->y;
                }
                else
                {
                     $X += $layer->{ x } - $self->border->left;
                    $Y += $layer->y - $self->border->bottom;
                }

            if ( exists $layer->{ type } && $layer->{ type } eq 'text' )
            {
                foreach my $set ( @{ $layer->data_set } )
                {
                    my $text_angle  = exists( $set->{ rotation } ) && $set->{ rotation } || 0;
                    my $font_style  = 'normal';
                    my $font_weight = $set->{ font_weight } || $layer->font_weight || 'normal';

                    my $f_style = $set->{ style } || $layer->style;
                    if ( $f_style =~ /(italic)|(oblique)/ )
                    {
                        $font_style = 'italic';
                    }
                    if ( $f_style =~ /bold/ )
                    {
                        $font_weight = 'bold';
                    }

                    my $letter_spacing = $set->{ letter_spacing } || $layer->letter_spacing || 'normal';
                    my $word_spacing   = $set->{ word_spacing }   || $layer->word_spacing   || 'normal';
                    my $font_stretch   = $set->{ stretch }        || $layer->stretch        || 'normal';

                    my $txt = $layer_goup->text(
                        x => $set->{ x }  || 0,
                        y => -$set->{ y } || 0,
                        style => {
                            'font-family' => $set->{ font } || $layer->font,
                            'font-size'   => $set->{ size } || $layer->size,
                            'font-style'  => $font_style,
                            'font-weight' => $font_weight,
                            'font-stretch'   => $font_stretch,
                            'letter-spacing' => $letter_spacing,
                            'word-spacing'   => $word_spacing,
                            'fill'           => '#' . ( $set->{ color } || $layer->color || 'ffffff' ),
                            'stroke'         => '#' . ( $set->{ stroke } || $set->{ color } || $layer->color || '000000' ),
                            'writing-mode'   => 'lr',
                            'text-anchor' => $set->{ anchor } || $layer->anchor
                        },
                        transform => "matrix(1,0,0,-1," . ( $X ) . "," . ( $Y ) . ") rotate($text_angle)"
                    );
                    $txt->tspan( dy => "0" )->cdata( $set->{ text } );

                }
            }
            elsif ( exists $layer->{ type } && $layer->{ type } eq 'line' )
            {
                my $ind = 0;
                foreach my $set ( @{ $layer->data_set } )
                {
                    my @xv;
                    my @yv;
                    my $dot = -1;

                    foreach my $point ( @{ $set->{ data } } )
                    {
                        next unless ( ref $point eq 'ARRAY' );
                        push @xv, $point->[0] + $X;
                        push @yv, $point->[1] + $Y;
                        $dot++;
                    }
                    my %style;
                    my $color_hex = $set->{ color } || $layer->{ color };
                    if ( exists $layer->{ filled } && $layer->{ filled } == 1 )
                    {
                        push @xv, $xv[0];
                        push @yv, $yv[0];
                        %style = (
                            'opacity' => eval( hex( ( unpack "a6 a2", $color_hex )[1] ) / 255 ) || 1,
                            'stroke' => '#' . ( unpack "a6", $color_hex ) || 0,
                            'stroke-width' => ( $set->{ thickness } || $layer->{ thickness } ),
                            'fill' => '#' . ( unpack "a6", $color_hex ) || 0,
                            'fill-opacity' => eval( hex( ( unpack "a6 a2", $color_hex )[1] ) / 255 ) || 1,
                            'fill-rule' => 'nonzero'
                        );
                    }
                    else
                    {
                        %style = (
                            'opacity' => eval( hex( ( unpack "a6 a2", $color_hex )[1] ) / 255 )
                              || 1,
                            'stroke' => '#' . ( unpack "a6", $color_hex )
                              || 0,
                            'stroke-width' => ( $set->{ thickness } || $layer->{ thickness } ),
#                         'fill'         => '#ff0000',
                            'fill-opacity' => 0,
                            'fill-rule'    => 'nonzero'
                        );
                    }
                    my $points = $layer_goup->get_path(
                        x       => \@xv,
                        y       => \@yv,
                        -type   => 'polyline',
                        -closed => 'true',
                    );
                    my $id_data;
                    if ( exists $layer->{ label } )
                    {
                        $id_data = $layer->{ label };
                    }
                    else
                    {
                        $id_data = 'glyph_' . $layer_ind . '_' . $ind;
                    }
                    my $tag = $layer_goup->polyline(
                        %$points,
                        id    => $id_data,
                        style => \%style,
                    );
                    $ind++;
                }
            }
            elsif ( exists $layer->{ type } && $layer->{ type } eq 'ellipse' )
            {
                my $ind = 0;
                foreach my $set ( @{ $layer->data_set } )
                {
                    my $cx = ( $set->{ cx } + $X ) || 0;
                    my $cy = ( $set->{ cy } )      || 0;
                    my $rx = $set->{ rx }          || 0;
                    my $ry = $set->{ ry }          || 0;
                    my %style;

                    my $color_hex = $set->{ color } || $layer->{ color };
                    if ( exists $layer->{ filled } && $layer->{ filled } == 1 )
                    {
                        %style = (
                            'opacity' => eval( hex( ( unpack "a6 a2", $color_hex )[1] ) / 255 ) || 1,
                            'stroke' => '#' . ( unpack "a6", $color_hex ) || 0,
                            'stroke-width' => ( $set->{ thickness } || $layer->{ thickness } ),
                            'fill' => '#' . ( unpack "a6", $color_hex ) || 0,
                            'fill-opacity' => eval( hex( ( unpack "a6 a2", $color_hex )[1] ) / 255 ) || 1,
                            'fill-rule' => 'nonzero'
                        );
                    }
                    else
                    {
                        %style = (
                            'opacity' => eval( hex( ( unpack "a6 a2", $color_hex )[1] ) / 255 )
                              || 1,
                            'stroke' => '#' . ( unpack "a6", $color_hex )
                              || 0,
                            'stroke-width' => ( $set->{ thickness } || $layer->{ thickness } ),
#                        'fill'         => '#ff0000',
                            'fill-opacity' => 0,
                            'fill-rule'    => 'nonzero'
                        );
                    }

                    my $tag = $layer_goup->ellipse(
                        cx    => $cx,
                        cy    => $cy,
                        rx    => $rx,
                        ry    => $ry,
                        id    => 'ellipse_' . $layer_ind . '_' . $ind,
                        style => \%style,
#                         transform => "matrix(1,0,0,-1," . $self->border->left . "," . ( $self->total_size->[1] - $Y - $self->border->bottom ) . ")",
                    );
                    $ind++;
                }
            }
            elsif ( exists $layer->{ type } && $layer->{ type } eq 'image' )
            {
                my $image_nbr = 1;
                foreach my $set ( @{ $layer->data_set } )
                {
                    my $raw_img = $set->{ image };
                    my $img64   = encode_base64( $raw_img, "\n" );
                    my $tag     = $svg->image(
                        x => $set->{ x }  || 0,
                        y => -$set->{ y } || 0,
                        width     => $set->{ width },
                        height    => $set->{ height },
                        id        => 'image_' . $layer_ind . '_' . $image_nbr,
                        '-href'   => "data:image/png;base64," . $img64,
                        transform => "matrix(1,0,0,1," . $X . "," . $Y . ")",
                    );
                    $image_nbr++;
                }
# $tag = $svg->image(
# x=>100, y=>100,
# width=>300, height=>200,
# '-href'=>"image.png", #may also embed SVG, e.g. "image.svg"
# id=>'image_1'
# );

            }
        }

#######################################
############## Overlay ################
#######################################
        if ( ( ref $layer ) eq 'Graph::ChartSVG::Overlay' )
        {
            $layer_goup = $data_goup->group( id => "data_$layer_ind" );
            my $ind       = 0;
            my $color_hex = $layer->{ color };
            if ( $layer->{ type } eq 'v' )
            {
                foreach my $start ( keys %{ $layer->{ data_set } } )
                {
                    my $stop = $layer->{ data_set }->{ $start };
                    my $k    = $layer_goup->rectangle(
                        x      => $start,
                        y      => -$layer->{ debord_1 },
                        width  => $stop - $start,
                        height => $self->{ active_size }->[1] + $layer->{ debord_1 } + $layer->{ debord_2 },
                        style  => {

                            'opacity' => eval( hex( ( unpack "a6 a2", $color_hex )[1] ) / 255 ) || 1,
                            'fill' => '#' . ( unpack "a6", $color_hex ) || 0,
                            'fill-opacity' => eval( hex( ( unpack "a6 a2", $color_hex )[1] ) / 255 ) || 1,
                            'fill-rule' => 'nonzero'
                        },
                        id => 'v_overlay_' . $layer_ind . '_' . $ind
                    );
                    $ind++;
                }
            }
            if ( $layer->{ type } eq 'h' )
            {
                foreach my $start ( keys %{ $layer->{ data_set } } )
                {
                    my $stop = $layer->{ data_set }->{ $start };
                    my $k    = $layer_goup->rectangle(
                        x      => -$layer->{ debord_1 },
                        y      => $start,
                        width  => $self->{ active_size }->[0] + $layer->{ debord_1 } + $layer->{ debord_2 },
                        height => $stop - $start,
                        style  => {
                            'opacity' => eval( hex( ( unpack "a6 a2", $color_hex )[1] ) / 255 ) || 1,
                            'fill' => '#' . ( unpack "a6", $color_hex ) || 0,
                            'fill-opacity' => eval( hex( ( unpack "a6 a2", $color_hex )[1] ) / 255 ) || 1,
                            'fill-rule' => 'nonzero'
                        },
                        id => 'h_overlay_' . $layer_ind . '_' . $ind
                    );
                    $ind++;
                }
            }
        }
        $layer_ind++;
    }

    my $info_data_group = $svg->group( id => "info_data" );
    my $obj = Data::Serializer->new( 'compress' => 1 );
    my $tag = $obj->serialize( \@list_data );
    $info_data_group->comment( $tag );

#######################################
## grid
#######################################
    if ( defined $self->grid )
    {
        if ( defined $self->grid->x )
        {
            my $x_grid_group = $svg->group( id => "x_grid" );
            my $x_grid_text = $x_grid_group->group(
                id        => "x_grid_text",
                transform => "matrix(1,0,0,1, 0," . ( $self->border->bottom ) . " )"
            );
            my $thickness = $self->grid->x->thickness || 1;
            my $color_hex = $self->grid->x->color;
            my $max_length_x;
            $max_length_x = max( map( length, @{ $self->grid->x->label->text } ) )
              if ( defined( $self->grid->x->label )
                && ( ref( $self->grid->x->label->text ) eq 'ARRAY' ) );
            my $max_length_x2;
            $max_length_x2 = max( map( length, @{ $self->grid->x->label2->text } ) )
              if ( defined( $self->grid->x->label2 )
                && ( ref( $self->grid->x->label2->text ) eq 'ARRAY' ) );

            for ( my $nbr = $self->grid->x->number - 1 ; $nbr >= 0 ; $nbr-- )
            {
                my $val = $nbr * ( ( ( $self->active_size->[1] ) / ( $self->grid->x->number - 1 ) ) );
                my $text_indx = $self->grid->x->number - $nbr - 1;

                my $tag = $x_grid_group->line(
                    id    => 'x_grid_' . $nbr,
                    x1    => $self->border->left - $self->grid->debord->left,
                    y1    => $self->border->bottom + $val,
                    x2    => $self->border->left + $self->active_size->[0] + $self->grid->debord->right,
                    y2    => $self->border->bottom + $val,
                    style => {
                        'fill'            => 'none',
                        'opacity'         => eval( hex( ( unpack "a6 a2", $color_hex )[1] ) / 255 ) || 1,
                        'stroke'          => '#' . ( unpack "a6", $color_hex ) || 0,
                        'stroke-width'    => $thickness,
                        'stroke-linecap'  => 'butt',
                        'stroke-linejoin' => 'miter',
                        'stroke-opacity'  => 1
                    },
                    transform => "matrix(1,0,0,-1," . ( 0 ) . "," . ( $self->total_size->[1] ) . ")",
                );

                if ( defined $self->grid->x->label && defined $self->grid->x->label->text->[$text_indx] )
                {
                    my $text_color = ( $self->grid->x->label->color || $color_hex );
                    my $radian = ( $self->grid->x->label->rotation / 180 ) * PI || 0;
                    my $cos    = cos( $radian );
                    my $sin    = sin( $radian );
                    my $len    = length( $self->grid->x->label->text->[$text_indx] );

                    my $font_style  = 'normal';
                    my $font_weight = 'normal';
                    my $f_style     = $self->grid->x->label->style || '';
                    if ( $f_style =~ /(italic)|(oblique)/ )
                    {
                        $font_style = 'italic';
                    }
                    if ( $f_style =~ /bold/ )
                    {
                        $font_weight = 'bold';
                    }

                    my $x_offset = 0;
                    my $y_offset = 0;

                    my %style;
                    if ( $self->grid->x->label->align =~ /left/i )
                    {
                        %style = (
                            'font-family'  => $self->grid->x->label->font,
                            'font-size'    => $self->grid->x->label->size,
                            'font-style'   => $font_style,
                            'font-weight'  => $font_weight,
                            'fill'         => '#' . ( $text_color || 'ffffff' ),
                            'stroke'       => '#' . ( $text_color || '000000' ),
                            'writing-mode' => 'lr',
                            'text-anchor'  => 'start',
#                             'baseline-shift'=> '-10%',
                        );
                        $x_offset = $self->grid->x->label->size * ( $max_length_x - 1 );
                        if ( $self->grid->x->label->rotation )
                        {
                            $y_offset = ( $sin * $len * $self->grid->x->label->size ) - ( $sin * $self->grid->x->label->size );
                        }
                    }
                    else
                    {
                        %style = (
                            'font-family'  => $self->grid->x->label->font,
                            'font-size'    => $self->grid->x->label->size,
                            'font-style'   => $font_style,
                            'font-weight'  => $font_weight,
                            'fill'         => '#' . ( $text_color || 'ffffff' ),
                            'stroke'       => '#' . ( $text_color || '000000' ),
                            'writing-mode' => 'lr',
                            'text-anchor'  => 'end',
#                             'baseline-shift'=> '-10%',
                        );
                    }

                    my $txt = $x_grid_text->text(
                        x     => $self->border->left - $self->grid->debord->left - $self->grid->x->label->space - $x_offset,
                        y     => $self->border->top - $self->border->bottom + $val + ( $self->grid->x->label->size * 0.3 ) - $y_offset,
                        style => \%style,
# transform => " rotate( " . $self->grid->x->label->rotation . "," . ( $self->border->left - $self->grid->debord->left - $self->grid->x->label->space - $x_offset ) . "," . ( $self->border->bottom + $val - $y_offset ) . " ) ",
                        transform => " rotate( " . $self->grid->x->label->rotation . "," . ( $self->border->left - $self->grid->debord->left - $self->grid->x->label->space - $x_offset ) . "," . ( $self->border->bottom + $val - $y_offset ) . " ) ",

                    );
                    $txt->tspan( dy => "0" )->cdata( $self->grid->x->label->text->[$text_indx] );
                }

##########################################
# second x label ( right side )
##########################################
                if ( defined $self->grid->x->label2 && defined $self->grid->x->label2->text->[$text_indx] )
                {
                    my $text_color = ( $self->grid->x->label2->color || $color_hex );
                    my $radian      = ( $self->grid->x->label2->rotation / 180 ) * PI || 0;
                    my $cos         = cos( $radian );
                    my $sin         = sin( $radian );
                    my $len         = length( $self->grid->x->label2->text->[$text_indx] );
                    my $font_style  = 'normal';
                    my $font_weight = 'normal';
                    my $f_style     = $self->grid->x->label2->style || '';

                    if ( $f_style =~ /(italic)|(oblique)/ )
                    {
                        $font_style = 'italic';
                    }
                    if ( $f_style =~ /bold/ )
                    {
                        $font_weight = 'bold';
                    }
                    my $x_offset = 0;
                    my $y_offset = 0;

                    my %style;
                    if ( $self->grid->x->label2->align =~ /right/i )
                    {
                        %style = (
                            'font-family'  => $self->grid->x->label2->font,
                            'font-size'    => $self->grid->x->label2->size,
                            'font-style'   => $font_style,
                            'font-weight'  => $font_weight,
                            'fill'         => '#' . ( $text_color || 'ffffff' ),
                            'stroke'       => '#' . ( $text_color || '000000' ),
                            'writing-mode' => 'lr',
                            'text-anchor'  => 'end',
#                             'baseline-shift'=> '-10%',
                        );
                        $x_offset = $self->grid->x->label2->size * ( $max_length_x2 - 1 );
                        if ( $self->grid->x->label2->rotation )
                        {
                            $y_offset = ( $sin * ( $max_length_x2 - 1 ) * $self->grid->x->label2->size ) - ( $sin * $self->grid->x->label2->size );
                        }
                    }
                    else
                    {
                        %style = (
                            'font-family'  => $self->grid->x->label2->font,
                            'font-size'    => $self->grid->x->label2->size,
                            'font-style'   => $font_style,
                            'font-weight'  => $font_weight,
                            'fill'         => '#' . ( $text_color || 'ffffff' ),
                            'stroke'       => '#' . ( $text_color || '000000' ),
                            'writing-mode' => 'lr',
                            'text-anchor'  => 'start',
#                             'baseline-shift'=> '-10%',
                        );
                    }
                    my $txt = $x_grid_text->text(
                        x => $self->border->left + $self->grid->debord->right + $self->grid->x->label2->space + $x_offset + $self->active_size->[0],
# y         => $self->border->bottom + $val + ( $self->grid->x->label2->size * 0.3 ) + $y_offset,
                        y => $self->border->top - $self->border->bottom + $val + ( $self->grid->x->label2->size * 0.3 ) - $y_offset,

                        style     => \%style,
                        transform => " rotate( " . $self->grid->x->label2->rotation . "," . ( $self->border->left + $self->grid->debord->right + $self->grid->x->label2->space + $x_offset + $self->active_size->[0] ) . "," . ( $self->border->bottom + $val + $y_offset ) . " ) ",
                    );
                    $txt->tspan( dy => "0" )->cdata( $self->grid->x->label2->text->[$text_indx] );
                }
            }
        }

####################################
## grid Y ( vertical )
####################################
        if ( defined $self->grid->y )
        {
            my $y_grid_group = $svg->group( id => "y_grid", transform => "matrix(1,0,0,-1, 0," . ( $self->total_size->[1] ) . " )" );
            my $y_grid_text = $y_grid_group->group(
                id        => "y_grid_text",
                transform => "matrix(1,0,0,-1, 0," . ( $self->border->bottom ) . " )"
            );
            my $thickness = $self->grid->y->thickness || 1;
            my $color_hex = $self->grid->y->color;
            my $max_length_y;
            $max_length_y = max( map( length, @{ $self->grid->y->label->text } ) )
              if ( defined( $self->grid->y->label )
                && ( ref( $self->grid->y->label->text ) eq 'ARRAY' ) );
            my $max_length_y2;
            $max_length_y2 = max( map( length, @{ $self->grid->y->label2->text } ) )
              if ( defined( $self->grid->y->label2 )
                && ( ref( $self->grid->y->label2->text ) eq 'ARRAY' ) );

            for my $nbr ( 0 .. ( $self->grid->y->number - 1 ) )
            {
                my $val = ( ( $nbr ) * ( $self->active_size->[0] / ( $self->grid->y->number - 1 ) ) );

                my $tag = $y_grid_group->line(
                    id    => 'y_grid_' . $nbr,
                    x1    => $self->border->left + $val,
                    y1    => $self->border->bottom - $self->grid->debord->bottom,
                    x2    => $self->border->left + $val,
                    y2    => $self->border->bottom + $self->active_size->[1] + $self->grid->debord->top,
                    style => {
                        'fill'            => 'none',
                        'opacity'         => eval( hex( ( unpack "a6 a2", $color_hex )[1] ) / 255 ) || 1,
                        'stroke'          => '#' . ( unpack "a6", $color_hex ) || 0,
                        'stroke-width'    => $thickness,
                        'stroke-linecap'  => 'butt',
                        'stroke-linejoin' => 'miter',
                        'stroke-opacity'  => 1
                    },
                );

                if ( defined $self->grid->y->label && defined $self->grid->y->label->text->[$nbr] )
                {
                    my $text_color  = $self->grid->y->label->color || $color_hex;
                    my $font_style  = 'normal';
                    my $font_weight = 'normal';
                    my $f_style     = $self->grid->y->label->style || '';

                    if ( $f_style =~ /(italic)|(oblique)/ )
                    {
                        $font_style = 'italic';
                    }
                    if ( $f_style =~ /bold/ )
                    {
                        $font_weight = 'bold';
                    }

                    my $radian   = ( $self->grid->y->label->rotation / 180 ) * PI || 0;
                    my $cos      = cos( $radian );
                    my $sin      = sin( $radian );
                    my $len      = length( $self->grid->y->label->text->[$nbr] );
                    my $x_offset = 0;
                    my $y_offset = 0;

                    my $l = ( 0.628 * $self->grid->y->label->size * $max_length_y ) - 5.052;
                    my %style;
                    if ( $self->grid->y->label->align =~ /left/i )
                    {
                        %style = (
                            'font-family'  => $self->grid->y->label->font,
                            'font-size'    => $self->grid->y->label->size,
                            'font-style'   => $font_style,
                            'font-weight'  => $font_weight,
                            'fill'         => '#' . ( $text_color || 'ffffff' ),
                            'stroke'       => '#' . ( $text_color || '000000' ),
                            'writing-mode' => 'lr',
                            'text-anchor'  => 'end',
#                             'baseline-shift'=> '-10%',
                        );
                        if ( $self->grid->y->label->rotation )
                        {
                            $y_offset = ( $self->grid->debord->bottom + $self->grid->y->label->space ) * 2;
                        }
                    }
                    else
                    {
                        %style = (
                            'font-family'  => $self->grid->y->label->font,
                            'font-size'    => $self->grid->y->label->size,
                            'font-style'   => $font_style,
                            'font-weight'  => $font_weight,
                            'fill'         => '#' . ( $text_color || 'ffffff' ),
                            'stroke'       => '#' . ( $text_color || '000000' ),
                            'writing-mode' => 'lr',
                            'text-anchor'  => 'start',
#                             'baseline-shift'=> '-10%',
                        );
                        $x_offset = $self->grid->y->label->size * ( ( 0.7025 * $max_length_y ) - 1.601 ) * $cos;
                        $y_offset = ( $l * $sin ) + ( $self->grid->debord->bottom + $self->grid->y->label->space ) + ( $l / $cos );

                    }

                    my $txt = $y_grid_text->text(
                        x         => $self->border->left + $val - $x_offset,
                        y         => $y_offset,
                        style     => \%style,
                        transform => " rotate( " . $self->grid->y->label->rotation . "," . ( $self->border->left + $val - $x_offset ) . ", " . $y_offset . " ) ",
                    );
                    $txt->tspan( dy => "0" )->cdata( $self->grid->y->label->text->[$nbr] );

                }

                if ( defined $self->grid->y->label2 && defined $self->grid->y->label2->text->[$nbr] )
                {
                    my $text_color  = $self->grid->y->label2->color || $color_hex;
                    my $font_style  = 'normal';
                    my $font_weight = 'normal';
                    my $f_style     = $self->grid->y->label2->style || '';

                    if ( $f_style =~ /(italic)|(oblique)/ )
                    {
                        $font_style = 'italic';
                    }
                    if ( $f_style =~ /bold/ )
                    {
                        $font_weight = 'bold';
                    }

                    my $radian   = ( $self->grid->y->label2->rotation / 180 ) * PI || 0;
                    my $cos      = cos( $radian );
                    my $sin      = sin( $radian );
                    my $len      = length( $self->grid->y->label2->text->[$nbr] );
                    my $x_offset = 0;
                    my $y_offset = 0;
#                     my $l        = ( 0.628 * $self->grid->y->label2->size * $max_length_y2 ) - 5.052;
                    my $l = $self->grid->y->label2->size * $max_length_y2 * $self->grid->y->label2->font_scaling;
                    my %style;

                    if ( $self->grid->y->label2->align =~ /left/i )
                    {
                        %style = (
                            'font-family'  => $self->grid->y->label2->font,
                            'font-size'    => $self->grid->y->label2->size,
                            'font-style'   => $font_style,
                            'font-weight'  => $font_weight,
                            'fill'         => '#' . ( $text_color || 'ffffff' ),
                            'stroke'       => '#' . ( $text_color || '000000' ),
                            'writing-mode' => 'lr',
                            'text-anchor'  => 'start',
#                             'baseline-shift'=> '-10%',
                        );
                        if ( $self->grid->y->label2->rotation )
                        {
                            $y_offset = -( $self->active_size->[1] + $self->grid->debord->top + $self->grid->y->label2->space );
                        }
                    }
                    else
                    {
                        %style = (
                            'font-family'  => $self->grid->y->label2->font,
                            'font-size'    => $self->grid->y->label2->size,
                            'font-style'   => $font_style,
                            'font-weight'  => $font_weight,
                            'fill'         => '#' . ( $text_color || 'ffffff' ),
                            'stroke'       => '#' . ( $text_color || '000000' ),
                            'writing-mode' => 'lr',
                            'text-anchor'  => 'end',
#                             'baseline-shift'=> '-10%',
                        );
                        $x_offset = ( $l * $cos ) + $val + $self->border->left;
                        $y_offset = ( $l * $sin ) - $self->grid->debord->bottom - $self->active_size->[1] - $self->grid->debord->top - $self->grid->y->label2->space;
                    }
                    my $txt = $y_grid_text->text(
                        x         => $x_offset,
                        y         => $y_offset,
                        style     => \%style,
                        transform => " rotate( " . $self->grid->y->label2->rotation . "," . ( $x_offset ) . ", " . $y_offset . " ) ",
                    );
                    $txt->tspan( dy => "0" )->cdata( $self->grid->y->label2->text->[$nbr] );
                }
            }
        }
    }

#######################################
####### Frame #######
#######################################
    if ( defined $self->frame )
    {
        my $k = $svg->rectangle(
            x      => $self->{ border }->left,
            y      => $self->{ border }->top,
            width  => $self->{ active_size }->[0],
            height => $self->{ active_size }->[1],
#               rx    => 10, ry     => 5,
            style => {
                stroke => '#' . ( ( $self->frame )->{ color } ),
                fill => 'none',
                'stroke-width' => ( $self->frame )->{ thickness } || 0,
            },
            id => 'frame'
        );
    }

#######################################
####### TAG #######
#######################################
    if ( exists $self->{ tag } && $self->{ tag } )
    {
        my $tag_group = $svg->group( id => "serial_tag" );
        my $obj = Data::Serializer->new( 'compress' => 1 );
        my $tag = $obj->serialize( $self->{ tag } );
        $tag_group->comment( $tag );
    }

    $self->image(
        $svg->xmlify(
            -namespace  => "svg",
            -pubid      => "-//W3C//DTD SVG 1.0//EN",
            -standalone => "no",
            -inline     => 1
        )
    );
    $self->{ svg_raw } = $svg;
}

sub sum_array
{
    my $col  = shift;
    my $line = shift;
    my $data = shift;
    my $res  = 0;
    for my $c_idx ( 0 .. $col )
    {
        $res += $data->[$c_idx][$line] || 0;
    }
    return $res;
}

sub reduce
{
    my $self = shift;
    my %object_hash = ( @_ );
    
    my $object      = \%object_hash;

    my $width_out   = $self->{ active_size }->[0];
    my $start            = $object->{ start }      || 0;
    my $percentile_value = $object->{ percentile } || 0.95;
    my $end              = $object->{ end }        || $width_out;
    my @data_in          = @{ $object->{ data } };
    my $data_in_size     = scalar @data_in;
 
    no warnings "all";
    my @perc = sort { $a <=> $b } @data_in[ $start .. $end ];
    my $prec_ind = int( scalar( @perc ) * $percentile_value );
    my @data_out;
    my %STATS;
    $STATS{ perc } = $perc[$prec_ind] || 0;
    $STATS{ min } = ( min @data_in ) || 0;
    $STATS{ max } = max @data_in;
    $STATS{ sum } = sum @data_in;
    $STATS{ avg } = $STATS{ sum } / scalar( @data_in );
    use warnings "all";
    
    my $width_in = $end - $start + 1;

    my $data_dot     = ( scalar @data_in ) / $width_in;
    my $data_dot_int = int( $data_dot + 0.5 );
    my @chars;

    if ( exists $object->{ init } )
    {
        # @data_out = map( $object->{ init }, @data_out );
        @data_out = (  $object->{ init } || 0  ) x $width_out;
    }

    if ( $#data_out <= $#data_in )
    {
        my $old_val = 0;
        for ( my $dot = $start ; $dot <= $end ; $dot++ )
        {
            my $s     = ( $dot - $start ) * $data_dot;
            my $e     = $s + $data_dot - 1;
            my @slice = @data_in[ $s .. $e ];

            if ( scalar( @slice ) )
            {
                if ( exists $object->{ type } && $object->{ type } =~ /^nrz$/i )
                {
                    foreach my $idx ( 0 .. $#slice )
                    {
                        if ( $slice[$idx] == 0 )
                        {
                            $slice[$idx] = $old_val;
                        }
                        else
                        {
                            $old_val = $slice[$idx];
                        }
                    }
                }
                if ( scalar( @slice ) > 1 )
                {
                    $data_out[$dot] = sum( @slice ) / scalar( @slice );
                }
                else
                {
                    $data_out[$dot] = 0;
                }
            }
            else
            {
                $data_out[$dot] = 0;
            }
            $STATS{ last }     = $dot;
            $STATS{ last_val } = $data_in[ $end - 1 ];
        }
    }
    else
    {
        if ( exists $object->{ type } && $object->{ type } =~ /^line|nrz$/i )
        {
            my $dot     = 0;
            my $old_val = 0;
          W: while ( $dot <= $width_in )
            {
                my $ind = ( int( ( $dot / ( $width_in / $data_in_size ) ) ) );
                my $val1 = ( $ind > $#data_in ? $data_in[-1] : $data_in[$ind] ) || 0;
                my $val2 = ( ( $ind + 1 ) > $#data_in ? $data_in[-1] : $data_in[ ( $ind + 1 ) ] ) || 0;

                my $inc = ( $val2 - $val1 ) / ( ( $width_in / $data_in_size ) );
                my $val = $val1 || 0;
                for ( 0 .. ( $width_in / $data_in_size ) )
                {
                    $STATS{ last } = $dot;
                    last W if ( $dot >= $width_in );
                    if ( $object->{ type } =~ /^nrz$/i && ( !$val2 || !$val ) )
                    {
                        carp "in nrz  [ $dot + $start ] = $old_val";
                        $data_out[ $dot + 1 ] = $old_val;
# $data_out[ $dot ] = $val;
# $start = $dot;
                    }
# else
# {
                    $data_out[ $dot + $start ] = $val;
                    $old_val = $val;
                    $val += $inc;
# }

                    if ( $inc > 0 )
                    {
                        $val = $val > $val2 ? $val2 : $val;
                    }
                    else
                    {
                        $val = $val < $val2 ? $val2 : $val;
                    }

                    $dot++;
                }
            }
        }
        else
        {
            $STATS{ last } = $width_in;
            for ( my $dot = 1 ; $dot <= $width_in ; $dot++ )
            {
                my $ind = ( int( ( $dot / ( $width_in / $data_in_size ) ) ) );
                $data_out[ $dot + $start - 1 ] = $ind > $#data_in ? $data_in[-1] || 0 : $data_in[$ind] || 0;
            }
        }
    }
    return wantarray ? ( \@data_out, \%STATS ) : \@data_out;
}

sub img_from
{
    my $self = shift;
    my $file = shift;
    my $obj  = Data::Serializer->new( 'compress' => 1 );

    my $svg = SVG::Parser->new()->parsefile( $file );

    my $info_data = $svg->getElementByID( 'info_data' );
# my  $element = $info_data->cloneNode( 1 );
# my  $c = ($element->getElements('comment'))[0];
    my $kid = $info_data->getFirstChild();

    my $com = $kid->xmlify();

    $com =~ s/^\s*<!--\s*//m;
    $com =~ s/\s*-->$//;

# my  @comments = $kid->getElements('comment');
# carp "**" x 50;
#   carp Dumper(\@c);
# my $comments = $c->{ '-comment' };
# foreach my $comment ( @comments )
# {
# # $comment =~ s/^\s*//;
# carp "<$comment>";
#
    my $tag = $obj->deserialize( $com );
# carp Dumper($comment->{ '-comment' });
    foreach my $data_tag ( @$tag )
    {
# carp Dumper( $data_tag );
        my $data     = $svg->getElementByID( $data_tag );
        my $kid_data = $data->getFirstChild();
# carp Dumper($kid_data);
# carp $kid_data->xmlify();
        my $data_element = $kid_data->cloneNode( 1 );
# carp Dumper( $data_element );
# my $parser=new SVG::Parser();
#
# my $svg1=$parser->parse_string($kid_data->xmlify());
# carp Dumper($svg1);

# # my  $data_element = $data->cloneNode( 2 );
# carp Dumper($data);
    }
#
# }

#   my @rectangles=$data->getElements("");
# carp Dumper(\@rectangles);
# foreach my $sib1 ( @$ref)
# {
# carp "**" x 50;
# foreach my $sib2 ( @{$sib1->getSiblings()} )
# {
# carp Dumper($sib2);
#
# }
#
# }
    $self;
}

# __PACKAGE__->meta->make_immutable;
#
1;

=head1 METHODS
	
	OO interface

=head2 Graph::ChartSVG->new

=over

Create a new Chart 

possible parameters are :

=back

=head3  active_size 

=over 

=back

    an array ref with x,y size of the active graph ( without the reserved border for label )
    
 
=head3  bg_color
 
=over 

=back

  an hex color for the global background color
 
=head3      frame
 
=over 

=back

  a Frame object to surround the active part of the graph

=head3      grid
 
=over 

=back

  a Grid oject to add to the graph
  
  
=head3     overlay
 
=over 

=back

 a Overlay to add on top of the graph ( useful to enhance a period in alarm )
  
=head3     layer
 
=over

=back

 a Layer object
  
=head3     border
 
=over 

=back

 a Border object ( = some extra space to fit aroubd the active graph to allow label.
                This increase the actual_size and create the total_size)
 
=head3      tag
 
=over 

=back

 a Tag objet ( if missing create a automatically incremented one )
 
=head3      glyph
 
=over 

=back

 a Glyph object to add on the graph ( like a arrow to point at the end of the current data )
    


my $graph = Graph::ChartSVG->new( active_size => \@size, bg_color => 'FCF4C6', frame => $f, png_tag => 1 );


=over 

=back

=head2 Frame->new

=over

=back
 
=head3      color
 
=over 

=back

 a hex color of the frame
 
=head3     thickness
 
=over 

=back

 thickness of the frame

my $f = Frame->new( color => 'ff0000', thickness => 3 );

=over 

=back

=head2 Border->new

=over

=back
 
=head3      top

 space between the active part of the graph and the top of the image
 
=over

=back
 
=head3      bottom

 space between the active part of the graph and the bottom of the image
 
=over

=back
 
=head3      left

 space between the active part of the graph and the left of the image

=over

=back
 
=head3      right

space between the active part of the graph and the right of the image
 
my $b = Border->new( top => 200, bottom => 100, left => 80, right => 200 );

=over 

=back

=head2 $graph->border

method to add or change a border on the graph
 
=over 

=back

=head2  Data->new

 create a new set of data 
 
=over

=back
 
=head3 type

 the type of graph used for that data set.
 could be :
 
=over 

=item

line  

a normal line

=item  

line_up     

a line with zero starting at the middle of the active graph with increasing value in the top direction 

=item 

line_down 

a line with zero starting at the middle of the active graph with increasing value in the bottom direction 

=item     

bar

a filled graph 

=item     

bar_up 

a filled graph with zero starting at the middle of the active graph with increasing value in the top direction 

=item      

bar_down 

a filled graph with zero starting at the middle of the active graph with increasing value in the bottom direction 
   
=item     

line_stack  

a set of line stacked under each other 

=item     

line_stack_up 

a set of line stacked under each other with zero starting at the middle of the active graph with increasing value in the top direction 

=item     

line_stack_down 

a set of line stacked under each otherwith zero starting at the middle of the active graph with increasing value in the bottom direction 
    
=item     

bar_stack

a set of filled graph stacked under each other 

=item     

bar_stack_up 

a set of filled graph stacked under each other with zero starting at the middle of the active graph with increasing value in the top direction 

=item     

bar_stack_down

a set of filled graph stacked under each other  with zero starting at the middle of the active graph with increasing value in the bottom direction 
  

=back
 
=head3 color

the hex color of the graph

if Data is stack type, it should be a array ref with all the hex color

=over

=back
 
=head3 thickness

the thickness of the line used 

in bar the thickness of the border


=over

=back
 
=head3 label

a label to set to the SVG object

=over

=back
 
=head3 offset

a vertical offset ( where the zero start )

=over 

=back

=head4 example:
 
    my $l = Data->new( type => 'line', color => 'ff9800A0', thickness => 3, label => 'oblique' ,  offset    => 50 );

=over 

=back

=head2  $l->data_set( ... )

include a set of data to a Data object

it is an array ref with all data

or an array ref of array ref  for the stack type of Graph

=over 

=back

=head4 example:

  $l->data_set( \@data1 );
  
  
=over 

=back

=head2  $graph->add( ... )

add a element in the graph 

the element could be:

=over 

=item

data_set

=item

Glyph

=item

Overlay


=back

=head4 example:

 $graph->add( $l );
 
method to add an object to a graph

=over 

=back

=head2 graph->grid( 
    debord => ...,
    x => Grid_object,
    y = > Grid_object,
    )

    $graph->grid(

        Grid->new(
            debord => Border->new( # the debord size of the grid ( = the grid is greater than the active size )
                top => 20, 
                bottom => 10, 
                left => 10,
                right => 10 ), 

            x => Grid_def->new(         # label on the left border of the graph
                color     => '1292FF',
                number    => 10,
                thickness => 2,
                label     => Label->new(
                    font  => 'verdana',
                    color => '0000ff',
                    size  => 15,
                    text  => \@text,    # a array ref with all the text to set on the left border of the graph
                    space => 10,        # space between the end of the label and the start of the grid
                    align => 'right',
                    rotation => -30,
                ),
                    label2 => Label->new(   # label on the right border of the graph
                    font  => 'times',
                    color => '0000ff',
                    s ize  => 20,
                    text  => \@text2,
                    space => 10,
                    # align => 'right',
                    # rotation => -45,
                ),
            ),

            y => Grid_def->new(
                color     => '00fff0',
                number    => $VERT_GRID,
                thickness => 1,
                label     => Label->new(  # label on the left bottom of the graph
                    font     => 'verdana',
                    color    => 'ff00ff',
                    size     => 14,
                    text     => \@DATE,
                    space    => 10,
                    rotation => -30,
                    align    => 'right',
                ),
                label2 => Label->new( # label on the left top of the graph
                    font         => 'verdana',
                    font_scaling => 0.558,
                    color        => 'B283FF',
                    size         => 16,
                    text         => \@DATE2,
                    align        => 'right',
                    space        => 0,
                    rotation     => -30,
                ),
            )
        )
    );

 
=over 

=back

=head2 $graph->label( label_name);

search for the layer with the label = label_name

in array context return ( ref_data, layer_level)
in scalar context return ref_data

(ref_data = an array ref with the data set )


 my ( $Mal, $Mlan ) = $graph->label( 'src_all' );
 
=over 

=back

=head2  $graph->move( from, to );

Move a speciied layer to another level.

the other layer are shifted to allow the insert

=over 

=back

=head2 Glyph->new

3 type of glyph are available:

'line'   draw a polyline or polygon
'text'   draw a text
'image' include  a PNG image Embeded in the SVG

To draw an arrow:

    my $g1 = Glyph->new(
        x        => $graph->border->left ,  
        y        =>$graph->active_size->[1] +$graph->border->bottom ,       
        type     => 'line',
        filled   => 1,                  # if 1 = fill the polygon ( be sure to correctly close the path )
        color    => '0faFff',
        data_set => [
            {
                data => [ [ 0, 0 ], [ 8, 10 ], [ 0, 10 ], [ 0, 10 + 20 ], [ 0, 10 ], [ -8, 10 ], [ 0, 0 ] ], # the list of point to create the polyline
                thickness => 3
            }
        ]
    );


To write 2 text label ( in one Glyph )

        $g = Glyph->new(
            label =>'label_max',
            x => 100 ,
            y        =>200,
            type     => 'text',
            color    =>0xff0000,
            size     => 9,                              # if the glyph's type is 'text', this is the font size
            font     => 'Verdana',                      # the TrueType font to use
            data_set => [                               # the data set contain an array with all the text to plot followed by the relative position + the optional rotation
                {
                    text   => "hello text 1",
                    x      => 0,                                # the relative position in x for that specific text
                    y      => 15,                               # the relative position in yfor that specific text
                    anchor => 'end',                                    # the text anchor ( could be  start, middle or end )
                    rotation => -45,                            # a rotation in ° in trigonometric direction ( anti-clock )
                    style => 'oblique'                          # could be 	normal (default) ,| italic = oblique
                },
                {
                    text =>"Bye text 2",
                    x      => 60,                                # the relative position in x for that specific text
                    y      => 15,                              # the relative position in yfor that specific text
                    anchor => 'end',
                    # rotation => -45,
                    style => 'oblique'
                },
            ],
        );
        
       
 To inlude a PNG image ( the image is encoded with MIME::Base64 )
      
         $g = Glyph->new(
            label => 'port_label',
            x     => $graph->active_size->[0] + $graph->border->left + 250,
            y     => $graph->active_size->[1] + $graph->border->top+$graph->border->bottom  -4,
            type  => 'image',
            data_set => [    
                {
                    image  => $img_bin,   
                    x      => 0,
                    y      => -5,
                    width  => $buf_x,           # the width of the image
                    height => $buf_y,           # the height of the image
                },
            ],
        ); 
        
=over 

=back

=head2 $graph>image

return the SVG image ( to be writed in a file )

    open( my $IMG, '>', $file_svg ) or die $!;
    binmode $IMG;
    print $IMG $graph>image;
    close $IMG;
    
!!!!    This object is only available after the render method !!!!

=over 

=back

=head2 $graph->reduce(        data  => \@dot1,
        start => 50,
        end   => 360,
        init  => 300 );
        
This method allow to create a set of data directly usable a a data_set.
If there are more plotting value in the input data then the size of the graph, use some average to create the plotting dot
If there are lower plotting value in the input data then the size of the graph, fill the gap to smooth the graph
data = an array ref with the input data        
start =  where the data start in the reduced data ( if missing =0 )
end = where the data end in the reduced data ( f missing = end of the active size graph )
init = a default value to set the element when there is no data to add, like before start or after end ( if missing use undef )


return a array of 2  element 

The first one contains an array refwith the reduced set of data
The second a hash ref with the statistic info

$VAR1 = {
          'perc' => 345,
          'last_val' => 359,
          'avg' => '400',
          'min' => 0,
          'last' => 360,
          'max' => 800,
          'sum' => 320400
        };



=over 

=back

=head2 $graph->render

create the SVG from all the objects

=over 

=back
