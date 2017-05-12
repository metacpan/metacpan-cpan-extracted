package Graph::Chart;

###########################################################
# RPN package with DICT
# Gnu GPL2 license
#
# Fabrice Dulaunoy <fabrice@dulaunoy.com>
###########################################################
# ChangeLog:
#
###########################################################

=head1 SYNOPSIS

=over 3

B<Graph::Chart>

	A Wrapper around GD to easyly graph chart

=back

=cut

use strict;

use Carp;
use Data::Dumper;

use Clone qw(clone);
use Compress::Zlib;
use Data::Serializer;
# use fields qw{ size   };
use GD;
use GD::Polyline;
use List::Util qw[min max sum];
use POSIX;

use vars qw( $VERSION );

use constant PI => 4 * atan2( 1, 1 );
# use constant NEPER => 2.718281828459045;
# use constant LOG10 => 2.30258509299405;

$VERSION = '0.65';

###########################################################################

###########################################################################
### 			class creator					###
###########################################################################

=head1 METHODS
	
	OO interface

=head2 new

=over

Create a new Chart 

=over

my $graph = Graph::Chart->new( \%options );

  %options could be defined like this:



  size => [ W, H ] 							# the size ( Width, Height ) in pixel of the real graph ( without border ) 
  bg_color => '0xfffff0'						#  an ARRAY with all possible section
  frame  => { color => '0xff00ff', thickness => 1 },			# an optional frame around the real chart
  border => [ 150,  80,            100,      100 ],			# extra space around the graph in pixel [ left side, right side , top side, bottom side ]"
  
      grid   => {							# a grid over the graph
	  debord => [ 5, 20, 10, 30 ],					# some extension of the grid size ( same order as border ) B<test>
	  x      => {							# vertical grid
	    color  => '0xff00ff'					# color of the grid ( hex HTML value )
	    number => 5,						# number of grid division
           thickness => 1,						# size of the division's line ( default = 1 )
           type => log,							# create a log graduation (only one modules). If missing, normal graduation.
           
	    label  => {							# an optional label on the left side
		font  => '/usr/lib/cinelerra/fonts/trebucbi.ttf',	# a TrueType font to use
		color => '0xff0000',					# the color of the label
		size  => 10,						# the size of the font
		text  => [ 'toto', undef, 'truc', 'bazar', 122 ],	# the text to render ( a undef element is not ploted, this allow to skip some label )
		space => 80,						# an extra space between the division and the text
		align    => 'right',					# align the text on the right ( = aligned on the division )
		rotation => 30,						# a rotation of the text in degree
		kerning_correction => 0.85,				# a kerning correcting to correct align of text when rotated ( default 0.91 ) 
		surround => { color => '0x0000ff' , thickness => 1 },	# create a frame around the text with the specified color and thickness
	    },
	    
	x_up      => {							# vertical grid on the upper half of the graph ( to use with up_ graph)
	    color  => '0xff00ff'					# color of the grid ( hex HTML value )
	    number => 5,						# number of grid division
           thickness => 1,						# size of the division's line ( default = 1 )
           type => log,							# create a log graduation (only one modules). If missing, normal graduation.
           
	    label  => {							# an optional label on the left side
		font  => '/usr/lib/cinelerra/fonts/trebucbi.ttf',	# a TrueType font to use
		color => '0xff0000',					# the color of the label
		size  => 10,						# the size of the font
		text  => [ 'toto', undef, 'truc', 'bazar', 122 ],	# the text to render ( a undef element is not ploted, this allow to skip some label )
		space => 80,						# an extra space between the division and the text
		align    => 'right',					# align the text on the right ( = aligned on the division )
		rotation => 30,						# a rotation of the text in degree
		kerning_correction => 0.85,				# a kerning correcting to correct align of text when rotated ( default 0.91 ) 
		surround => { color => '0x0000ff' , thickness => 1 },	# create a frame around the text with the specified color and thickness
	    },
	    
	x_down      => {						# vertical grid on the lower half of the graph ( to use with down_ graph)
	    color  => '0xff00ff'					# color of the grid ( hex HTML value )
	    number => 5,						# number of grid division
           thickness => 1,						# size of the division's line ( default = 1 )
           type => log,							# create a log graduation (only one modules). If missing, normal graduation.
           
	    label  => {							# an optional label on the left side
		font  => '/usr/lib/cinelerra/fonts/trebucbi.ttf',	# a TrueType font to use
		color => '0xff0000',					# the color of the label
		size  => 10,						# the size of the font
		text  => [ 'toto', undef, 'truc', 'bazar', 122 ],	# the text to render ( a undef element is not ploted, this allow to skip some label )
		space => 80,						# an extra space between the division and the text
		align    => 'right',					# align the text on the right ( = aligned on the division )
		rotation => 30,						# a rotation of the text in degree
		kerning_correction => 0.85,				# a kerning correcting to correct align of text when rotated ( default 0.91 ) 
		surround => { color => '0x0000ff' , thickness => 1 },	# create a frame around the text with the specified color and thickness
	    },
	    
	    label2 => {							# an optional label on the right side
		font  => '/usr/lib/cinelerra/fonts/lucon.ttf',		# a TrueType font to use
		color => '0xff0000',					# the color of the label
		size  => 10,						# the size of the font
		text  => [ 'toto', undef, 'truc', 'bazar', 122 ],,	# the text to render ( a undef element is not ploted, this allow to skip some label )
		space => 50,						# an extra space between the division and the text
		align => 'right',					# align the text on the right ( not really useful )
		rotation => -30,					# an rotation of the text in degree
		kerning_correction => 0.85,				# a kerning correcting to correct align of text when rotated ( default 0.91 ) 
		surround => { color => '0x0000ff' , thickness => 1 },	# create a frame around the text with the specified color and thickness

	    },
	},	  	"
       y => {								# horizontal grid
           color     => '0x00fff0','					# color of the grid ( hex HTML value )
           number    => 8,						# number of grid division
           thickness => 1,						# size of the division's line ( default = 1 )
           label     => {						# an optional label on the bottom side
		font  => '/usr/lib/cinelerra/fonts/trebuc.ttf',		# a TrueType font to use
		color => '0xff0000',',					# the color of the label
		size  => 12,						# the size of the font
		text  => [ 100, undef, '20', undef, 1585, undef, 555 ],	# the text to render ( a undef element is not ploted, this allow to skip some label )
# 		space => 10,						# an extra space between the division and the text
		rotation => 45,						# an rotation of the text in degree
		kerning_correction => 0.85,				# a kerning correcting to correct align of text when rotated ( default 0.91 ) 
		surround => { color => '0x0000ff' , thickness => 1 },	# create a frame around the text with the specified color and thickness
           },
#	     label2     => {						# an optional label on the top side
#		font  => '/usr/lib/cinelerra/fonts/trebuc.ttf',	# a TrueType font to use
		color => '0xff0000',',					# the color of the label
		size  => 12,						# the size of the font
		text  => [ 100, undef, '20', undef, 1585, undef, 555 ],	# the text to render ( a undef element is not ploted, this allow to skip some label )
# 		space => 10,						# an extra space between the division and the text
		rotation => 45,						# an rotation of the text in degree
		kerning_correction => 0.85,				# a kerning correcting to correct align of text when rotated ( default 0.91 ) 
		surround => { color => '0x0000ff' , thickness => 1 },	# create a frame around the text with the specified color and thickness
#             }
         }


	reticle => { 							# when the Chart's type is of any circular shape, create polar division 
	debord => 30,							# the extra debord of the division
	color => '0xff0000',						# the color of the division
	number => 10,							# the number of division
	label_middle => {						# the label to write between 2 division
		font  => '/usr/lib/cinelerra/fonts/lucon.ttf',		# a TrueType font to use
		kerning_correction => 0.85,				# a kerning correcting to correct align of text when rotated ( default 0.91 ) 
		color => '0xff0000',					# the text color
                size  => 10,						# the font size to use
#		space => 10,						# an extra space between the division and the text
#		rotate => 'follow',					# rotate the text to be following the division direction
		rotate => 'perpendicular',				# rotate the the to be perpendicular to the division
									# if missing write the text without rotation
                text => [700031220,45,90,135,180,225,270,31500 , 1 ,2], #  the text to render ( a undef element is not ploted, this allow to skip some label )
		},
#	label => {							# the label to write at the division
		font  => '/usr/lib/cinelerra/fonts/lucon.ttf',		# a TrueType font to use
		kerning_correction => 0.85,				# a kerning correcting to correct align of text when rotated ( default 0.91 ) 
		color => '0xff0000',					# the text color
                size  => 10,						# the font size to use
#		space => 10,						# an extra space between the division and the text
#		rotate => 'follow',					# rotate the text to be following the division direction
		rotate => 'perpendicular',				# rotate the the to be perpendicular to the division
									# if missing write the text without rotation
                text => [700031220,45,90,135,180,225,270,31500 , 1 ,2], #  the text to render ( a undef element is not ploted, this allow to skip some label )
#		},	

	overlay=> {							# add an overlay to the graph (useful to show an alert period )
	  layer => 10, 							# the layer where the data is plotted ( the lowest number is the deepest layer ) If missing, the layer is created by call order of the method data 
	  set   => \@alarm,						# a array ref with the data ( the number of dot plotted is the number  W provided by the size parameter/method
	  type  => 'pie',						# the type of graph ( dot, line, bar, up_dot, up_bar, up_line , down_dot,down_line, down_bar, pie, target, radial )
	  color => '0xFFD2D2',						# color of the plotted element
	  type => 'pie',						# if missing normal overlay are used, if present use a polar structure ( data are in the range of 0 to 360 ° ) 
	  merge  => 1,							# if present and not = 0 all overlay are overwrited by the overlay from a higer layer
	  opacity => 100,						# when merge is missing, the overlay % of opacity copied on the chart
	  debord => 50,							# the debord of the overlay. if missing use the full graph height and in polar ( pie ) use the smallest vertical border ( top or bottom ) 
	  },
	  
	  glyph => {							# add some ornament on the graph like line, text or polygon
        x     => $graph->{x}{min}+200,						# the origin of the glyph, all other position are relative to this origin
	y     => $graph->{x}{max} ,						# either in pixel  x =>0 , y=> 0 = corner lower left
									# see the active method
        type  => 'filled',						# type of glyph ( missing = open polygyn, 'filled' = filled polygon, 'text' = text )
        color => '0x00FFff',						# color of the glyph
        data  => [							# if one of the polygon type, the data is a set of point to plot ( value relative to the origin )
            [ 0,  0 ],
            [ 8,  10 ],
            [ 0,  10 ],
            [ 0,  10 + 20 ],
            [ 0,  10 ],
            [ -8, 10 ],
            [ 0,  0 ]
          ],
          
        glyph => {	
           x     => 100,
        y     => 'active_max',
        type  => 'text',
        color => '0xff0000',
        size  => 12,							# if the glyph's type is 'text', this is the font size 
        font  => '/usr/lib/cinelerra/fonts/lucon.ttf',			# the TrueType font to use
        data  => [ 	 						# the data set contain an array with all the text to plot followed by the relative position + the optional rotation
	     [ 'hello world', 0, 0, 30 ],				# 
	     [ 'hello universe', 100, 0, 0 ], 
	],
        },
   },
},

all these parameters are optional except the size

my $a  = B<Graph::Chart>->new( size => [ 800,400 ] 
);	

=back

=back

=cut

sub new
{
    my ( $class ) = shift;
#     no strict "refs";
#     my $fields_ref = \%{ "${class}::FIELDS" };
#     my $self      = $fields_ref;
    my $self;

    $self->{ size } = { @_ }->{ size };
    $self->{ bg_color } = _re_color( { @_ }->{ bg_color }, 'ffffffff' );
    if ( exists { @_ }->{ frame } )
    {
        $self->{ frame } = { @_ }->{ frame };
        if ( exists { @_ }->{ frame }{ color } )
        {
            $self->{ frame }{ color } = _re_color( { @_ }->{ frame }{ color }, '00000000' );
        }
        $self->{ frame }{ thickness } = { @_ }->{ frame }{ thickness } || 1;
    }

    $self->{ border } = { @_ }->{ border } || [ 0, 0, 0, 0 ];

    if ( exists { @_ }->{ grid } )
    {
        $self->{ grid } = { @_ }->{ grid };
        unless ( exists $self->{ grid }->{ debord } )
        {
            $self->{ grid }->{ debord } = [ 0, 0, 0, 0 ];
        }
    }
    if ( exists { @_ }->{ reticle } )
    {
        $self->{ reticle } = { @_ }->{ reticle };
        if ( !exists { @_ }->{ reticle }->{ debord } )
        {
            $self->{ reticle }{ debord } = 0;
        }
        if ( !exists $self->{ reticle }{ number } )
        {
            $self->{ reticle }->{ number } = 2;
        }
    }

    if ( exists { @_ }->{ overlay } )
    {
        if ( exists { @_ }->{ overlay }{ layer } )
        {
            $self->{ overlay }[ { @_ }->{ overlay }{ layer } ] = clone( { @_ }->{ overlay } );
        }
        else
        {
            push @{ $self->{ overlay } }, clone( { @_ }->{ overlay } );
        }
    }
    if ( exists { @_ }->{ glyph } )
    {
        if ( exists { @_ }->{ glyph }{ layer } )
        {
            $self->{ glyph }[ { @_ }->{ glyph }{ layer } ] = clone( { @_ }->{ glyph } );
        }
        else
        {
            push @{ $self->{ glyph } }, clone( { @_ }->{ glyph } );
        }
    }

    bless( $self, $class );
     return $self;
}

sub _color_allocate
{
    my $col   = shift;
    my $def   = shift;
    my $graph = shift;

    if ( ref $col eq 'ARRAY' )
    {
        my @style;
        foreach my $c ( @{ $col } )
        {
            my ( $r, $g, $b, $a ) = unpack "a2 a2 a2 a2 ", _re_color( $c, 'ffffffff' );
            push @style, $graph->colorAllocateAlpha( hex $r, hex $g, hex $b, hex $a );
        }
        $graph->setStyle( @style );
        return gdStyled;
    }
    else
    {
        if ( $col =~ /^(0x)??([[:xdigit:]]{6})$/i )
        {
            $col = $2 . '00';
        }
        elsif ( $col =~ /^(0x)??([[:xdigit:]]{8})$/i )
        {
            $col = $2;
        }
        else
        {
            $col = $def;
        }
        my ( $r, $g, $b, $a ) = unpack "a2 a2 a2 a2 ", $col;
        return $graph->colorAllocateAlpha( hex $r, hex $g, hex $b, hex $a );
    }
}

sub _re_color
{
    my $col   = shift;
    my $def   = shift;
    my $graph = shift;

    if ( $col =~ /^(0x)??([[:xdigit:]]{6})$/i )
    {
        $col = $2 . '00';
    }
    elsif ( $col =~ /^(0x)??([[:xdigit:]]{8})$/i )
    {
        $col = $2;
    }
    else
    {
        $col = $def;
    }
    return $col;
}
###########################################################################

###########################################################################
sub img_from
{
    my $self   = shift;
    my $object = shift;

    my $file = $object->{ file };
    my $image;
    {
        local $/ = undef;
        open IMG, $file;
        binmode IMG;
        $image = <IMG>;
        close IMG;
    }
    my $image_gd  = GD::Image->new( $image );
    my $image_png = $image_gd->png;
    my @chunks;
    my $chunks_nbr = 0;
    substr( $image, 0, 33, '' );
    while ( 1 )
    {
        my $slice = substr( $image, 0, 8, '' );
        my ( $len, $type ) = unpack( "Na4", $slice );
        last if $type eq 'IEND';
        if ( $type eq 'tEXt' )
        {
            my $tEXt = substr( $image, 0, $len, '' );
            my @all  = split( /\0/, $tEXt, 2 );
            my $obj  = Data::Serializer->new();
            my $tags = $obj->deserialize( $all[1] );
            foreach my $tag ( keys %{ $tags } )
            {
                next if ( $tag eq 'Graph::Chart' );
                $self->{ $tag } = $tags->{ $tag };
            }
            foreach my $tag ( keys %{ $tags->{ 'Graph::Chart' } } )
            {
                $self->{ $tag } = $tags->{ 'Graph::Chart' }{ $tag };
            }
            last;
        }
    }
    $self->{ img } = $image_png;
    if ( !exists $self->{ size_tot } )
    {
        ( $self->{ size_tot }->[0], $self->{ size_tot }->[1] ) = ( $image_gd->getBounds() )[ 0, 1 ];
    }
    $self;
}

###########################################################################
### 			method to reduce a set of data 		###
### 			with specific polling time  			###
### 			to fit the dot size				###
###########################################################################

=head2 reduce

  get a set of data as input and return the data to fill the array with the plotting values
  if more input data then the dot in the graph, process by averaging for a sample calculated on the target size
  if lower input data then the dot in the graph, repeat the input data in the slice related
  if called in array context return a ref to the array with reduced data and a ref to a hash with the statistical data
  in sclar context return a ref to the array with reduced data
  
  my $dr= $graph->reduce( 
    {
	  start => 5,				# start to fill the destination array at that element ( optional, default = 0 )
	  end => 50,				# fill the destination array until that element ( optional, default = plot width )
	  data => \@dot,			# the input data set 
	  init => 0,				# a default value for the destination set if not filled ( optional, default = undef )
	  type => 'line'			# type of interpollation if lower element in the input data set then in the target
						# default = step, the value is duplicate to fill-in all the destination dot for the slice
						# if line, the dot are filled with an increasing/decreasing step created by the to adjacent value/ by the number of dot in the slice 
						# if nrz = keep the previous value if now value == 0
	 percentile =>  0.90                    # a percentile to use (default = 0.95 )
    }
 );

=cut	

sub reduce
{
    my $self   = shift;
    my $object = shift;

    my $width_out = $self->{ size }->[0];
    my $start = $object->{ start } || 0;
    my $percentile_value = $object->{ percentile } || 0.95;
    my $end = $object->{ end } || $width_out;
    my @data_in = @{ $object->{ data } };
    my $data_in_size = scalar @data_in;
    my @perc = sort { $a <=> $b }  @data_in[$start .. $end ] ;
    my $prec_ind   = int( scalar( @perc )  * $percentile_value);
           
    my @data_out;
    my %STATS;    
   
    $STATS{ percentile } = $perc[$prec_ind];
    $STATS{ min } = min @perc;
    $STATS{ max } = max @data_in;
    $STATS{ sum } = sum @data_in;

    $STATS{ avg } = $STATS{ sum } / scalar( @perc );
  
    $#data_out = $width_out;
    my $width_in     = $end - $start + 1;
    
    my $data_dot     = ( scalar @data_in ) / $width_in;
    my $data_dot_int = int( $data_dot + 0.5 );
    my @chars;

    if ( exists $object->{ init } )
    {
        @data_out = map( $object->{ init }, @data_out );
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
                if ( $object->{ type } =~ /^nrz$/i )
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
                $data_out[$dot] = sum( @slice ) / scalar( @slice );
            }
            else
            {
                $data_out[$dot] = 0;
            }
            $STATS{ last } = $dot;
            $STATS{ last_val } = $data_in[ -1 ] ;
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
                my $val1 = $ind > $#data_in ? $data_in[-1] : $data_in[$ind];
                my $val2 = ( $ind + 1 ) > $#data_in ? $data_in[-1] : $data_in[ ( $ind + 1 ) ];
                my $inc = ( $val2 - $val1 ) / ( ( $width_in / $data_in_size ) );
                my $val = $val1 || 0;
                for ( 0 .. ( $width_in / $data_in_size ) )
                {
                    $STATS{ last } = $dot;
                    last W if ( $dot >= $width_in );
                    if ( $object->{ type } =~ /^nrz$/i && ( !$val2 || !$val ) )
                    {
                        $data_out[ $dot + $start ] = $old_val;
                    }
                    else
                    {
                        $data_out[ $dot + $start ] = $val;
                        $old_val = $val;
                        $val += $inc;
                    }
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
            for ( my $dot = 1 ; $dot <= $width_in ; $dot++ )
            {
                $STATS{ last } = $dot;
                my $ind = ( int( ( $dot / ( $width_in / $data_in_size ) ) ) );
                $data_out[ $dot + $start - 1 ] = $ind > $#data_in ? $data_in[-1] : $data_in[$ind];
            }
        }
    }
    return wantarray ? ( \@data_out, \%STATS ) : \@data_out;
#     return \@data_out, \%STATS;
}
###########################################################################

###########################################################################
### 			method to set the grid  			###
###########################################################################

=head2 grid

	set the grid 

  use the same parameter as the new()
  if the option is already present, overwrite this option

=cut	

sub grid
{
    my $self   = shift;
    my $object = shift;

    if ( $object )
    {
        foreach my $item ( keys %{ $object } )
        {
            if ( ref( $object->{ $item } ) eq 'HASH' )
            {
                foreach my $sub_item ( keys %{ $object->{ $item } } )
                {
                    $self->{ grid }{ $item }{ $sub_item } = $object->{ $item }{ $sub_item };
                }
            }
            else
            {
                $self->{ grid }{ $item } = $object->{ $item };
            }
            unless ( exists $self->{ grid }->{ debord } )
            {
                $self->{ grid }->{ debord } = [ 0, 0, 0, 0 ];
            }
        }
    }
    return $self->{ grid };
}

###########################################################################

###########################################################################
### 			method to set the reticle   			###
###########################################################################

=head2 reticle

	set the reticle 
	the reticle are the division when using a polar chart ( pie, target .... )

  use the same parameter as the new()
  if the option is already present, overwrite this option

=cut

sub reticle
{
    my $self   = shift;
    my $object = shift;

    if ( $object )
    {
        foreach my $item ( keys %{ $object } )
        {
            if ( ref( $object->{ $item } ) eq 'HASH' )
            {
                foreach my $sub_item ( %{ $object->{ $item } } )
                {
                    $self->{ reticle }{ $item }{ $sub_item } = $object->{ $item }{ $sub_item };
                }
            }
            else
            {
                $self->{ reticle }{ $item } = $object->{ $item };
            }
            unless ( exists $self->{ reticle }->{ debord } )
            {
                $self->{ reticle }->{ debord } = 0;
            }
        }
    }
    return $self->{ reticle };
}

###########################################################################

###########################################################################
### 			method to set the frame  			###
###########################################################################

=head2 frame

	set the frame 

  use the same parameter as the new()
  if the option is already present, overwrite this option

=cut

sub frame
{
    my $self   = shift;
    my $object = shift;

    if ( $object )
    {
        $self->{ frame } = $object;
        foreach my $item ( keys %{ $object } )
        {
            if ( ref( $object->{ $item } ) eq 'HASH' )
            {
                foreach my $sub_item ( %{ $object->{ $item } } )
                {
                    $self->{ frame }{ $item }{ $sub_item } = $object->{ $item }{ $sub_item };
                }
            }
            else
            {
                $self->{ frame }{ $item } = $object->{ $item };
            }
        }
        if ( exists $object->{ color } )
        {
            $self->{ frame }{ color } = _re_color( $object->{ color }, '00000000' );
        }
    }
    return $self->{ frame };
}

###########################################################################

###########################################################################
### 			method to set the size  			###
###########################################################################

=head2 size

	set the size ( this is the only mandatory option ) 

  use the same parameter as the new()
  if the option is already present, overwrite this option

=cut

sub size
{
    my $self   = shift;
    my $object = shift;

    if ( $object )
    {
        $self->{ size } = $object;
    }
    return $self->{ size };
}
###########################################################################

###########################################################################
### 			method to get the active border size 			###
###########################################################################

=head2 active

	get the active border size

 return a hash ref with 
  $ref->{ x }{ max }  ==> left border of the main graph
  $ref->{ x }{ min }  ==> right border of the main graph
  $ref->{ y }{ max }  ==> upper border of the main graph
  $ref->{ y }{ min }  ==> lower border of the main graph
  
=cut

sub active
{
    my $self = shift;
    my %tmp;
    $tmp{ x }{ max } = $self->{ border }->[0] + $self->{ size }->[0];
    $tmp{ x }{ min } = $self->{ border }->[0];
    $tmp{ y }{ max } = $self->{ border }->[3] + $self->{ size }->[1];
    $tmp{ y }{ min } = $self->{ border }->[2];
    return \%tmp;
}
###########################################################################

###########################################################################
### 			method to set the bg_color  			###
###########################################################################

=head2 bg_color

	set the bg_color
	set the background color of the graph

  use the same parameter as the new()
  if the option is already present, overwrite this option

=cut

sub bg_color
{
    my $self   = shift;
    my $object = shift;

    if ( $object )
    {
        $self->{ bg_color } = $object;
    }
    return $self->{ bg_color };
}
###########################################################################

###########################################################################
### 			method to provide the data to plot  		###
###########################################################################

=head2 data

	set the data to be plotted 


  $graph->data(
    {
	  layer => 10, 			# the layer where the data is plotted ( the lowest number is the deepest layer ) If missing, the layer is created by call order of the method data 
	  set   => \@dot,		# a array ref with the data ( the number of dot plotted is the number  W provided by the size parameter/method
	  type  => 'pie',		# the type of graph ( dot, line, bar, up_dot, up_bar, up_line , down_dot,down_line, down_bar, pie, target, radial )
	  bar_size => 1,		# if any type of bar used, this is an extra width of the bar created, if not defined, the bar width= 1 if set to 1 the size of the bar became 3 ( 1 before, 1 for the bar and one after )
	  color => '0x0000ff',		# color of the plotted element
	  thickness => 1,		# for any type of dot and line, the thiskness to used ( default = 1 )
	  scale => '90%',		# a vertical scale on the value provided ( a decimal number scale all the data value using the value ( data could be outside of the graph) 1 = 100%
					# a percent value like, '90%' scale the graph to that percentage ( lower then 100% = some data are plotted outside the graph )
					# missing or '100%' resize the graph using the maximal value 
					# 'auto' or '110%' allow to always have a small extra gap and never reach to extremity of the graph area, 
	  max => 3000,   		# a maximal value to use to create the graph ( if missing, max = maximal value from the data set )
	  
	  }
);
=cut

sub data
{
    my $self   = shift;
    my $object = shift;

    if ( $object )
    {
        if ( exists $object->{ layer } )
        {
            $self->{ data }[ $object->{ layer } ] = clone( $object );
        }
        else
        {
            push @{ $self->{ data } }, clone( $object );
        }
    }
    return $self->{ data };
}

###########################################################################

###########################################################################
### 		method to put an overlay on top of the graph  		###
###########################################################################

=head2 overlay

	method to put an overlay on top of the graph ( to show alarm period ... )


  use the same parameter as the new()
  if the same layer is already present, overwrite this layer

=cut

sub overlay
{
    my $self   = shift;
    my $object = shift;

    if ( $object )
    {
        if ( exists $object->{ layer } )
        {
            $self->{ overlay }[ $object->{ layer } ] = clone( $object );
        }
        else
        {
            push @{ $self->{ overlay } }, clone( $object );
        }
    }
    return $self->{ overlay };
}
###########################################################################

###########################################################################
### 		method to put a glyph on the graph  		###
###########################################################################

=head2 overlay

	method to put a glyph on the graph ( to show the latest data polled, or a trend value, ... )


  use the same parameter as the new()
  if the same layer is already present, overwrite this layer

=cut

sub glyph
{
    my $self   = shift;
    my $object = shift;

    if ( $object )
    {
        if ( exists $object->{ layer } )
        {
            $self->{ glyph }[ $object->{ layer } ] = clone( $object );
        }
        else
        {
            push @{ $self->{ glyph } }, clone( $object );
        }
    }
    return $self->{ glyph };
}
###########################################################################

###########################################################################
### 		method to add a png data TAG ( not standard )  		###
###########################################################################

=head2 png_zEXt

	method to add a png data TAG 
	This tag is not a PNG standard, but allowed by the RFC
	see code in img_info.pl 
	
	my $png_out1 =$graph->png_zEXt( { eerer => 1, ggg => 'zed' } );
	this overwrite the png TAG data with the new value and return the new image

=cut

sub png_zEXt
{
    my $self   = shift;
    my $object = shift;
    $self->{ size_tot }->[0] = $self->{ size }->[0] + $self->{ border }->[0] + $self->{ border }->[1];
    $self->{ size_tot }->[1] = $self->{ size }->[1] + $self->{ border }->[2] + $self->{ border }->[3];
    my $tmp = clone( $self );
#     delete $tmp->{ data };
    foreach my $idx (0 .. scalar @{$tmp->{ data }})
    {
    
     next if ( ! defined  $tmp->{ data }[ $idx ] );
    delete $tmp->{ data }[ $idx]{ set};
    }
    delete $tmp->{ img };

    my $obj = Data::Serializer->new( 'compress' => 1 );
    $object->{ 'Graph::Chart' } = $tmp;
    my $tag = $obj->serialize( $object );
    my $png_out;
    my $ihdr;       # IHDR chunk
    my %tEXt;       # tEXt chunks to insert
    my $sig;        # PNG signature
    my $pos;        # position in $png
    my $pngsize;    # Total size of png
    my $text;       # 'string' of all tEXt chunks with CRC, etc.
    my $tchunk;     # content of text chunk
    $tEXt{ data } = $tag;
    ( $sig, $ihdr, $png_out ) = unpack "a8 a25 a*", $self->{ img };
    $png_out =~ /(.*)(....PLTE.*)/s;

    my $old_tag = $1;
    my $end_png = $2;

    foreach my $keyword ( keys %tEXt )
    {

#*    A tEXt chunk contains:
#*
#*       Keyword:            1-79 bytes (character string)
#*       Null separator:     1 byte
#*       Compression method: 1 byte
#*       Compressed text:    n bytes
        my $tbuffer;
        $tbuffer = $tEXt{ $keyword };
        $tbuffer =~ s/\\([tnrfbae])/control_char($1)/eg;
        $tchunk = sprintf "%s%c%s", $keyword, 0, $tbuffer;
        $text .= pack "N A* N", ( length( $tchunk ), 'tEXt' . $tchunk, &crc32( 'tEXt' . $tchunk ) );
        $pngsize += length( $tchunk ) + 8;
    }
    $png_out = $sig . $ihdr . $text . $end_png;
    $self->{ img } = $png_out;
    return $self->{ img };
}

###########################################################################
sub update
{
    my $self   = shift;
    my $object = shift;
#     carp Dumper($self);
     my $image_gd  = GD::Image->new( $self->{img});
#     carp $image_gd;
#     
#      $image->copy($sourceImage,$dstX,$dstY,  $srcX,$srcY,$width,$height)

}




###########################################################################
### 			method to render the Chart 			###
###########################################################################

=head2 render

	render the chart and return a png image


  my $img = $graph->render( \%tag )
   
   
  the hash ref contain data to put in the PNG meta tag.
  the tools img_info.pl allow to see the result.
  the tag is serialized in the png
  
  the returned value could be writted in a file like this:
  my $png_out = $graph->render();
  
    open( my $IMG, '>', $file ) or die $!;
    binmode $IMG;
    print $IMG $png_out;
    close $IMG;
);

=cut

sub render
{
    my $self   = shift;
    my $object = shift;

    my $frame = new GD::Image( $self->{ size }->[0] + $self->{ border }->[0] + $self->{ border }->[1], $self->{ size }->[1] + $self->{ border }->[2] + $self->{ border }->[3] );
    my $bg_color = _color_allocate( $self->{ bg_color }, 'ffffffff', $frame );
    my $bg_color = _color_allocate( $self->{ bg_color }, 'ffffffff', $frame );
    $frame->transparent( $bg_color );
    $frame->interlaced( 'true' );

### plot overlay
    if ( exists $self->{ overlay } )
    {
        foreach my $layer ( @{ $self->{ overlay } } )
        {
            next unless ( ref $layer eq 'HASH' );
            my $col_graph;
            my $frame_over;
            if ( exists $layer->{ merge } && $layer->{ merge } )
            {
                $col_graph = _color_allocate( $layer->{ color }, '00000000', $frame );
            }
            else
            {
                $frame_over = new GD::Image( $self->{ size }->[0] + $self->{ border }->[0] + $self->{ border }->[1], $self->{ size }->[1] + $self->{ border }->[2] + $self->{ border }->[3] );
                my ( $r, $g, $b, $a ) = unpack "a2 a2 a2 a2 ", $self->{ bg_color };
                my $bg_color_over = $frame_over->colorAllocateAlpha( hex $r, hex $g, hex $b, hex $a );
                $frame_over->transparent( $bg_color_over );
                $frame_over->interlaced( 'true' );
                $frame_over->setThickness( 1 );

                $col_graph = _color_allocate( $layer->{ color }, '00000000', $frame );
            }
            my $extra =
                $self->{ border }->[2] > $self->{ border }->[3]
              ? $self->{ border }->[3]
              : $self->{ border }->[2];
            if ( exists $layer->{ debord } )
            {
                $extra = $layer->{ debord };
            }
            my $dot = -1;
            my $last_pie;
            foreach my $raw_val ( @{ $layer->{ set } } )
            {
                $dot++;
                next if ( !defined $raw_val || !$raw_val );
                my $plot_dot = $self->{ border }->[0] + $dot;
                my $plot_val = $self->{ border }->[2] + $self->{ border }->[3] + $self->{ size }->[1];

                if ( exists $layer->{ merge } && $layer->{ merge } )
                {
                    if ( exists $layer->{ type } && $layer->{ type } eq 'pie' )
                    {
                        $frame->filledArc( $self->{ size }->[0] / 2 + $self->{ border }->[0], ( $self->{ size }->[1] / 2 ) + $self->{ border }->[2], ( $self->{ size }->[1] + ( 2 * $extra ) ), ( $self->{ size }->[1] + ( 2 * $extra ) ), $dot, $dot + 1, $col_graph, gdEdged );
                        $last_pie = $dot;
                    }
                    else
                    {
                        $frame->line( $plot_dot, 0, $plot_dot, $plot_val, $col_graph );
                    }
                }
                else
                {
                    if ( exists $layer->{ type } && $layer->{ type } eq 'pie' )
                    {
                        $frame_over->filledArc( $self->{ size }->[0] / 2 + $self->{ border }->[0], ( $self->{ size }->[1] / 2 ) + $self->{ border }->[2], ( $self->{ size }->[1] + ( 2 * $extra ) ), ( $self->{ size }->[1] + ( 2 * $extra ) ), $dot, $dot + 1, $col_graph, gdEdged );
                    }
                    else
                    {
                        $frame_over->line( $plot_dot, 0, $plot_dot, $plot_val, $col_graph );
                    }
                }
            }

            if ( exists $layer->{ merge } && $layer->{ merge } )
            {
            }
            else
            {
                my $trans = $layer->{ opacity } || 20;
                $frame->copyMerge( $frame_over, 0, 0, 0, 0, $self->{ size }->[0] + $self->{ border }->[0] + $self->{ border }->[1], $self->{ size }->[1] + $self->{ border }->[2] + $self->{ border }->[3], $trans );
            }

        }
    }
### end plot overlay

### plot data
    if ( exists $self->{ data } )
    {
        my $last_pie;
        foreach my $layer ( @{ $self->{ data } } )
        {
            next unless ( ref $layer eq 'HASH' );
            my $max       = max( @{ $layer->{ set } } );
            my $min       = min( @{ $layer->{ set } } );
            my $scale     = 1;
            my $pre_scale = 1;
            my $bar_size  = $layer->{ bar_size } || 1;
            if ( exists $layer->{ scale } )
            {

                if ( $layer->{ scale } =~ /^(\d*\.*\d*)%$/ )
                {
                    $pre_scale = $1 / 100;
                }
                if ( $layer->{ scale } =~ /^(\d*\.*\d*)$/ )
                {
                    $pre_scale = $1;
                }
                elsif ( $layer->{ scale } eq 'auto' )
                {
                    $pre_scale = 1.1;
                }
            }
            if ( exists $layer->{ max } )
            {
                $max = $layer->{ max };
            }
            $scale = $self->{ size }->[1] / ( $pre_scale * $max );
            if ( exists $layer->{ type } && $layer->{ type } =~ /(up|down)/ )
            {
                $scale /= 2;
            }

            my $thickness = $layer->{ thickness } || 1;
            $frame->setThickness( $thickness );
            my $col_graph = _color_allocate( $layer->{ color }, '00000000', $frame );

            if ( !exists $layer->{ type } || $layer->{ type } =~ /line|dot|bar/ )
            {
                my $poly = new GD::Polygon;
                my $dot  = -1;
                foreach my $raw_val ( @{ $layer->{ set } } )
                {
                    $dot++;
                    next if ( !defined $raw_val );
                    last if ( $dot >= $self->{ size }->[0] );
                    my $offset = $layer->{ offset } || 0;
                    my $val = ( $scale * $raw_val ) + $offset;

                    if ( exists $layer->{ scale } && $layer->{ scale } eq 'log' )
                    {
                        $raw_val = $raw_val <= 0 ? $min : $raw_val;
                        next if ( $raw_val <= 0 );
                        $val = log10( $raw_val ) + $offset;
                    }
                    elsif ( exists $layer->{ scale } && $layer->{ scale } eq 'ln' )
                    {
                        $raw_val = $raw_val <= 0 ? $min : $raw_val;
                        next if ( $raw_val <= 0 );
                        $val = log( $raw_val ) + $offset;
                    }

                    $val = $val > $self->{ size }->[1] ? $self->{ size }->[1] : $val;
                    $val = $val < 0 ? 0 : $val;
                    my $plot_dot = $self->{ border }->[0] + $dot;

                    my $plot_val = $self->{ border }->[2] + $self->{ size }->[1] - $val;

                    my $y_size = $self->{ size }->[1];
                    if ( $layer->{ type } =~ /up/ )
                    {
                        $y_size /= 2;
                        $val = $val > $y_size ? $y_size : $val;
                        $plot_val = $self->{ border }->[2] + $y_size - $val;
                    }
                    elsif ( $layer->{ type } =~ /down/ )
                    {
                        $y_size /= 2;
                        $val = $val > $y_size ? $y_size : $val;
                        $plot_val = $self->{ border }->[2] + $y_size + $val;
                    }
                    if ( $layer->{ type } =~ /line/ )
                    {
                        $poly->addPt( $plot_dot, $plot_val );
                    }
                    elsif ( $layer->{ type } =~ /dot/ )
                    {
                        $frame->filledEllipse( $plot_dot, $plot_val, $thickness, $thickness, $col_graph );
                    }
                    elsif ( $layer->{ type } =~ /bar/ )
                    {
                        $frame->filledRectangle( $plot_dot - $bar_size, $self->{ border }->[2] + $y_size - $layer->{ offset }, $plot_dot + $bar_size, $plot_val, $col_graph );
                    }
                }
                $frame->unclosedPolygon( $poly, $col_graph ) if ( $layer->{ type } =~ /line/ );
            }
            elsif ( $layer->{ type } eq 'pie' )
            {
                my $img_width    = $self->{ size }->[0];
                my $img_height   = $self->{ size }->[1];
                my $graph_offset = 0;
                my $alarm_border = 0;
                my $target_value_graph;
                my $scale = 1;

                my $bar_size = $layer->{ bar_size } || 1;
                if ( exists $layer->{ scale } )
                {
                    if ( $layer->{ scale } =~ /^\d*\.*\d*$/ )
                    {
                        $scale = $layer->{ scale };
                    }
                }
                $frame->filledArc( $img_width / 2 + $self->{ border }->[0], ( $img_height / 2 ) + $self->{ border }->[2], ( $img_height ) * $scale, ( $img_height ) * $scale, $last_pie, $layer->{ set }[-1] + $last_pie, $col_graph, gdEdged );
                $last_pie = $layer->{ set }[-1],;
            }
            elsif ( $layer->{ type } eq 'target' )
            {
                my $img_width    = $self->{ size }->[0];
                my $img_height   = $self->{ size }->[1];
                my $graph_offset = 0;
                my $alarm_border = 0;
                my $target_value_graph;
                my $scale = 1;

                my $bar_size = $layer->{ bar_size } || 1;
                if ( exists $layer->{ scale } )
                {
                    if ( $layer->{ scale } =~ /^\d*\.*\d*$/ )
                    {
                        $scale = $layer->{ scale };
                    }
                }
                $frame->filledArc( $img_width / 2 + $self->{ border }->[0], ( $img_height / 2 ) + $self->{ border }->[2], ( $img_height ) * $scale, ( $img_height ) * $scale, 0, $layer->{ set }[-1], $col_graph, gdEdged );
            }
            elsif ( $layer->{ type } eq 'radial' )
            {
                my $img_width    = $self->{ size }->[0];
                my $img_height   = $self->{ size }->[1];
                my $graph_offset = 0;
                my $alarm_border = 0;
                my $target_value_graph;
                my $tot = $self->{ size }->[1];
                my $max;
                my $scale     = 1;
                my $pre_scale = 1;
                my $bar_size  = $layer->{ bar_size } || 1;

                if ( exists $layer->{ scale } || $layer->{ scale } eq 'auto' )
                {
                    if ( $layer->{ scale } =~ /^\d*\.*\d*$/ )
                    {
                        $pre_scale = $layer->{ scale };
                    }
                    $max = max( @{ $layer->{ set } } );
                    $scale = $self->{ size }->[1] / ( $pre_scale * $max );
                }
                my $dot = -1;
                foreach my $raw_val ( @{ $layer->{ set } } )
                {
                    my $plot_val = $raw_val * $scale;
                    $dot++;
                    $frame->filledArc( $img_width / 2 + $self->{ border }->[0], ( $img_height / 2 ) + $self->{ border }->[2], ( $plot_val ), ( $plot_val ), $dot, $dot + 1, $col_graph, gdEdged );
                }
            }
        }
    }
### end plot

### plot grid + label
    if ( exists $self->{ grid } )
    {
        if ( exists $self->{ grid }{ y } )
        {
            $frame->setThickness( $self->{ grid }{ y }{ thickness } );
            my $grid_color = _color_allocate( $self->{ grid }{ y }{ color }, 'ffffffff', $frame );
            for my $nbr ( 0 .. ( $self->{ grid }{ y }{ number } - 1 ) )
            {
                my $val = ( ( $nbr ) * ( ( ( ( $self->{ size }->[0] ) / ( $self->{ grid }{ y }{ number } - 1 ) ) ) ) );
                $frame->line( $self->{ border }->[0] + $val, $self->{ border }->[2] - $self->{ grid }{ debord }->[2], $self->{ border }->[0] + $val, $self->{ size }->[1] + $self->{ border }->[2] + $self->{ grid }{ debord }->[3], $grid_color );
                if ( defined $self->{ grid }{ y }{ label }{ text }->[$nbr] )
                {
                    my $text_color = $grid_color;
                    if ( exists $self->{ grid }{ y }{ label }{ color } )
                    {
                        $text_color = _color_allocate( $self->{ grid }{ y }{ label }{ color }, 'ffffffff', $frame );
                    }
                    my $radian  = ( $self->{ grid }{ y }{ label }{ rotation } / 180 ) * PI || 0;
                    my $kerning = $self->{ grid }{ y }{ label }{ kerning_correction }      || 0.91;
                    my $cos     = cos( $radian );
                    my $sin     = sin( $radian );
                    my $Xoff;
                    my $Yoff;
                    my $len = length( $self->{ grid }{ y }{ label }{ text }->[$nbr] );

                    if ( $self->{ grid }{ y }{ label }{ rotation } )
                    {
                        $Xoff = ( $cos * ( $self->{ grid }{ y }{ label }{ size } ) ) - ( $cos * ( ( $len**$kerning ) * $self->{ grid }{ y }{ label }{ size } ) );
                        $Yoff = ( $sin * ( ( $len**$kerning ) * $self->{ grid }{ y }{ label }{ size } ) ) + ( $sin * $self->{ grid }{ y }{ label }{ size } );
                    }
                    else
                    {
                        $Xoff = -( ( $len**$kerning ) * $self->{ grid }{ y }{ label }{ size } / 2 );
                        $Yoff = $self->{ grid }{ y }{ label }{ size };
                    }
                    if ( $self->{ grid }{ y }{ label }{ rotation } == 90 )
                    {
                        $Xoff = $self->{ grid }{ y }{ label }{ size } / 2;
                        $Yoff = ( ( $len**$kerning ) * $self->{ grid }{ y }{ label }{ size } );
                    }
                    my @b = $frame->stringFT(
                        $text_color,
                        $self->{ grid }{ y }{ label }{ font },
                        $self->{ grid }{ y }{ label }{ size },
                        $radian,
                        $self->{ border }->[0] + $val + $Xoff,
                        $self->{ size }->[1] +
                          $self->{ border }->[2] +
                          $self->{ grid }{ debord }->[3] +
                          ( $self->{ grid }{ y }{ label }{ space } || 0 ) +
                          $Yoff,
                        $self->{ grid }{ y }{ label }{ text }->[$nbr],
#                         { resolution => "95,95" }
                    );
                    if ( exists $self->{ grid }{ y }{ label }{ surround } )
                    {
                        my $surround_color = $grid_color;
                        if ( exists $self->{ grid }{ y }{ label }{ surround }{ color } )
                        {
                            $surround_color = _color_allocate( $self->{ grid }{ y }{ label }{ surround }{ color }, $self->{ grid }{ y }{ label }{ color }, $frame );
                        }
                        $frame->setThickness( $self->{ grid }{ y }{ label }{ surround }{ thickness } )
                          if ( exists $self->{ grid }{ y }{ label }{ surround }{ thickness } );
                        my $polyT = new GD::Polygon;
                        $polyT->addPt( $b[0], $b[1] );
                        $polyT->addPt( $b[2], $b[3] );
                        $polyT->addPt( $b[4], $b[5] );
                        $polyT->addPt( $b[6], $b[7] );
                        $frame->openPolygon( $polyT, $surround_color );
                    }
                }

                if ( exists $self->{ grid }{ y }{ label }{ text } && defined $self->{ grid }{ y }{ label2 }{ text }->[$nbr] )
                {
                    my $text_color = $grid_color;
                    if ( exists $self->{ grid }{ y }{ label2 }{ color } )
                    {
                        $text_color = _color_allocate( $self->{ grid }{ y }{ label2 }{ color }, 'ffffffff', $frame );
                    }
                    my $radian  = ( $self->{ grid }{ y }{ label2 }{ rotation } / 180 ) * PI || 0;
                    my $kerning = $self->{ grid }{ y }{ label2 }{ kerning_correction }      || 0.91;
                    my $cos     = cos( $radian );
                    my $sin     = sin( $radian );
                    my $Xoff    = 0;
                    my $Yoff    = 0;
                    my $len     = length( $self->{ grid }{ y }{ label2 }{ text }->[$nbr] );

                    unless ( $self->{ grid }{ y }{ label2 }{ rotation } )
                    {
                        $Xoff = -( ( $len**$kerning ) * $self->{ grid }{ y }{ label2 }{ size } / 2 );
                    }
                    if ( $self->{ grid }{ y }{ label2 }{ rotation } == 90 )
                    {
                        $Xoff = $self->{ grid }{ y }{ label2 }{ size } / 2;
                    }

                    my @b = $frame->stringFT(
                        $text_color,
                        $self->{ grid }{ y }{ label2 }{ font },
                        $self->{ grid }{ y }{ label2 }{ size },
                        $radian,
                        $self->{ border }->[0] + $val + $Xoff,
                        $self->{ border }->[2] - $self->{ grid }{ debord }->[2] - ( $self->{ grid }{ y }{ label2 }{ space } || 0 ) - $Yoff,
                        $self->{ grid }{ y }{ label2 }{ text }->[$nbr],
#                         { resolution => "95,95" }
                    );
                    if ( exists $self->{ grid }{ y }{ label2 }{ surround } )
                    {
                        my $surround_color = $grid_color;
                        if ( exists $self->{ grid }{ y }{ label2 }{ surround }{ color } )
                        {
                            $surround_color = _color_allocater( $self->{ grid }{ y }{ label2 }{ surround }{ color }, $self->{ grid }{ y }{ label2 }{ color }, $frame );
                        }
                        $frame->setThickness( $self->{ grid }{ y }{ label2 }{ surround }{ thickness } )
                          if ( exists $self->{ grid }{ y }{ label2 }{ surround }{ thickness } );
                        my $polyT = new GD::Polygon;
                        $polyT->addPt( $b[0], $b[1] );
                        $polyT->addPt( $b[2], $b[3] );
                        $polyT->addPt( $b[4], $b[5] );
                        $polyT->addPt( $b[6], $b[7] );
                        $frame->openPolygon( $polyT, $surround_color );
                    }
                    $frame->setThickness( 1 );
                }
            }
        }
        if ( exists $self->{ grid }{ x } )
        {
            if ( exists $self->{ grid }{ x }{ thickness } )
            {
                $frame->setThickness( $self->{ grid }{ x }{ thickness } );
            }
            my $grid_color = _color_allocate( $self->{ grid }{ x }{ color }, 'ffffffff', $frame );
            for ( my $nbr = $self->{ grid }{ x }{ number } - 1 ; $nbr >= 0 ; $nbr-- )
            {
                my $val = ( ( $nbr ) * ( ( ( ( $self->{ size }->[1] ) / ( $self->{ grid }{ x }{ number } - 1 ) ) ) ) );
                my $text_indx = $self->{ grid }{ x }{ number } - $nbr - 1;

                if ( exists $self->{ grid }{ x }{ type } && $self->{ grid }{ x }{ type } eq 'log' )
                {
                    $text_indx = $nbr;
                    my $s = $self->{ size }->[1] / log( $self->{ grid }{ x }{ number } );
                    $val = $self->{ size }->[1] - ( log( $nbr + 1 ) * $s );
                }
                $frame->line( $self->{ border }->[0] - $self->{ grid }{ debord }->[0], $self->{ border }->[2] + $val, $self->{ border }->[0] + $self->{ size }->[0] + $self->{ grid }{ debord }->[1], $self->{ border }->[2] + $val, $grid_color );
                if ( defined $self->{ grid }{ x }{ label }{ text }->[$text_indx] )
                {
                    my $text_color = $grid_color;
                    if ( exists $self->{ grid }{ x }{ label }{ color } )
                    {
                        $text_color = _color_allocate( $self->{ grid }{ x }{ label }{ color }, 'ffffffff', $frame );
                    }

                    my $radian  = ( $self->{ grid }{ x }{ label }{ rotation } / 180 ) * PI || 0;
                    my $kerning = $self->{ grid }{ x }{ label }{ kerning_correction }      || 0.91;
                    my $cos     = cos( $radian );
                    my $sin     = sin( $radian );
                    my $len = length( $self->{ grid }{ x }{ label }{ text }->[$text_indx] );
                    my $Xoff;
                    my $Yoff;

                    if ( $self->{ grid }{ x }{ label }{ align } eq 'right' )
                    {
                        $Xoff = -( ( $len**$kerning ) * $self->{ grid }{ x }{ label }{ size } );
                    }
                    if ( $self->{ grid }{ x }{ label }{ rotation } )
                    {
                        $Xoff = ( $cos * ( $self->{ grid }{ x }{ label }{ size } ) ) - ( $cos * ( ( $len**$kerning ) * $self->{ grid }{ x }{ label }{ size } ) );

                        $Yoff = ( $sin * ( ( $len**$kerning ) * $self->{ grid }{ x }{ label }{ size } ) ) - ( $sin * $self->{ grid }{ x }{ label }{ size } );
                    }
                    $frame->stringFT( $text_color, $self->{ grid }{ x }{ label }{ font }, $self->{ grid }{ x }{ label }{ size }, $radian, $self->{ border }->[0] - $self->{ grid }{ debord }->[0] + $Xoff - ( $self->{ grid }{ x }{ label }{ space } || 0 ), $self->{ border }->[2] + ( $self->{ grid }{ x }{ label }{ size } / 2 ) + $val + $Yoff, $self->{ grid }{ x }{ label }{ text }->[$text_indx] );
                }

                if ( defined $self->{ grid }{ x }{ label2 }{ text }->[$text_indx] )
                {
                    my $text_color = $grid_color;
                    if ( exists $self->{ grid }{ x }{ label2 }{ color } )
                    {
                        $text_color = _color_allocate( $self->{ grid }{ x }{ label2 }{ color }, 'ffffffff', $frame );
                    }
                    my $radian  = ( $self->{ grid }{ x }{ label2 }{ rotation } / 180 ) * PI || 0;
                    my $kerning = $self->{ grid }{ x }{ label2 }{ kerning_correction }      || 0.91;
                    my $cos     = cos( $radian );
                    my $sin     = sin( $radian );
                    my $len  = length( $self->{ grid }{ x }{ label2 }{ text }->[$text_indx] );
                    my $Xoff = 0;
                    my $Yoff = 0;

                    if ( $self->{ grid }{ x }{ label2 }{ align } eq 'right' )
                    {
                        $Xoff = -( ( $len**$kerning ) * $self->{ grid }{ x }{ label2 }{ size } );
                    }
                    $frame->stringFT(
                        $text_color,
                        $self->{ grid }{ x }{ label2 }{ font },
                        $self->{ grid }{ x }{ label2 }{ size },
                        $radian,
                        $self->{ border }->[0] + $self->{ grid }{ debord }->[1] + $Xoff + $self->{ grid }{ x }{ label2 }{ space } + $self->{ size }->[0],
                        $self->{ border }->[2] + ( $self->{ grid }{ x }{ label2 }{ size } / 2 ) + $val + $Yoff,
                        $self->{ grid }{ x }{ label2 }{ text }->[$text_indx]
                    );
                }
            }
        }
        if ( exists $self->{ grid }{ x_up } )
        {
            $frame->setThickness( $self->{ grid }{ x_up }{ thickness } );
            my $grid_color = _color_allocate( $self->{ grid }{ x_up }{ color }, 'ffffffff', $frame );

            for ( my $nbr = $self->{ grid }{ x_up }{ number } ; $nbr >= 1 ; $nbr-- )
            {
                my $val = ( $nbr - 1 ) * ( int( ( $self->{ size }->[1] ) / ( $self->{ grid }{ x_up }{ number } - 1 ) ) );
                my $text_indx = $self->{ grid }{ x_up }{ number } - $nbr;
                if ( exists $self->{ grid }{ x_up }{ type } && $self->{ grid }{ x_up }{ type } eq 'log' )
                {
                    $text_indx = $nbr - 1;
                    my $s = $self->{ size }->[1] / log( $self->{ grid }{ x_up }{ number } ) / 2;
                    $val = ( $self->{ size }->[1] / 2 ) - ( log( $nbr ) * $s );
                }
                else
                {
                    $val /= 2;
                }

                $frame->line( $self->{ border }->[0] - $self->{ grid }{ debord }->[0], $self->{ border }->[2] + 1 + $val, $self->{ border }->[0] + $self->{ size }->[0] + $self->{ grid }{ debord }->[1], $self->{ border }->[2] + 1 + $val, $grid_color );
                if ( defined $self->{ grid }{ x_up }{ label }{ text }->[$text_indx] )
                {
                    my $text_color = $grid_color;
                    if ( exists $self->{ grid }{ x_up }{ label }{ color } )
                    {
                        $text_color = _color_allocate( $self->{ grid }{ x_up }{ label }{ color }, 'ffffffff', $frame );
                    }

                    my $radian  = ( $self->{ grid }{ x_up }{ label }{ rotation } / 180 ) * PI || 0;
                    my $kerning = $self->{ grid }{ x_up }{ label }{ kerning_correction }      || 0.91;
                    my $cos     = cos( $radian );
                    my $sin     = sin( $radian );
                    my $len = length( $self->{ grid }{ x_up }{ label }{ text }->[$text_indx] );
                    my $Xoff;
                    my $Yoff;

                    if ( $self->{ grid }{ x_up }{ label }{ align } eq 'right' )
                    {
                        $Xoff = -( ( $len**$kerning ) * $self->{ grid }{ x_up }{ label }{ size } );
                    }
                    if ( $self->{ grid }{ x_up }{ label }{ rotation } )
                    {
                        $Xoff = ( $cos * ( $self->{ grid }{ x_up }{ label }{ size } ) ) - ( $cos * ( ( $len**$kerning ) * $self->{ grid }{ x_up }{ label }{ size } ) );

                        $Yoff = ( $sin * ( ( $len**$kerning ) * $self->{ grid }{ x_up }{ label }{ size } ) ) - ( $sin * $self->{ grid }{ x_up }{ label }{ size } );
                    }
                    $frame->stringFT( $text_color, $self->{ grid }{ x_up }{ label }{ font }, $self->{ grid }{ x_up }{ label }{ size }, $radian, $self->{ border }->[0] - $self->{ grid }{ debord }->[0] + $Xoff - $self->{ grid }{ x_up }{ label }{ space }, $self->{ border }->[2] + ( $self->{ grid }{ x_up }{ label }{ size } / 2 ) + $val + $Yoff, $self->{ grid }{ x_up }{ label }{ text }->[$text_indx] );
                }

                if ( defined $self->{ grid }{ x_up }{ label2 }{ text }->[$text_indx] )
                {
                    my $text_color = $grid_color;
                    if ( exists $self->{ grid }{ x_up }{ label2 }{ color } )
                    {
                        $text_color = _color_allocate( $self->{ grid }{ x_up }{ label2 }{ color }, 'ffffffff', $frame );
                    }
                    my $radian  = ( $self->{ grid }{ x_up }{ label2 }{ rotation } / 180 ) * PI || 0;
                    my $kerning = $self->{ grid }{ x_up }{ label2 }{ kerning_correction }      || 0.91;
                    my $cos     = cos( $radian );
                    my $sin     = sin( $radian );
                    my $len = length( $self->{ grid }{ x_up }{ label2 }{ text }->[$text_indx] );
                    my $Xoff;
                    my $Yoff;

                    if ( $self->{ grid }{ x_up }{ label2 }{ align } eq 'right' )
                    {
                        $Xoff = -( ( $len**$kerning ) * $self->{ grid }{ x_up }{ label2 }{ size } );
                    }
                    $frame->stringFT(
                        $text_color,
                        $self->{ grid }{ x_up }{ label2 }{ font },
                        $self->{ grid }{ x_up }{ label2 }{ size },
                        $radian,
                        $self->{ border }->[0] + $self->{ grid }{ debord }->[1] + $Xoff + $self->{ grid }{ x_up }{ label2 }{ space } + $self->{ size }->[0],
                        $self->{ border }->[2] + ( $self->{ grid }{ x_up }{ label2 }{ size } / 2 ) + $val + $Yoff,
                        $self->{ grid }{ x_up }{ label2 }{ text }->[$text_indx]
                    );
                }
            }
        }
        if ( exists $self->{ grid }{ x_down } )
        {
            $frame->setThickness( $self->{ grid }{ x_down }{ thickness } );
            my $grid_color = _color_allocate( $self->{ grid }{ x_down }{ color }, 'ffffffff', $frame );
            for ( my $nbr = $self->{ grid }{ x_down }{ number } ; $nbr >= 1 ; $nbr-- )
            {
                my $val       = ( $nbr - 1 ) * ( int( ( $self->{ size }->[1] ) / ( $self->{ grid }{ x_down }{ number } - 1 ) ) );
                my $text_indx = $self->{ grid }{ x_down }{ number } - $nbr;
                my $x_offset  = 0;
                if ( exists $self->{ grid }{ x_down }{ type } && $self->{ grid }{ x_down }{ type } eq 'log' )
                {
                    $text_indx = $nbr - 1;
                    my $s = $self->{ size }->[1] / log( $self->{ grid }{ x_down }{ number } ) / 2;
                    $val = ( $self->{ size }->[1] / 2 ) + ( log( $nbr ) * $s );
                }
                else
                {
                    $x_offset = $self->{ size }->[1] / 2;
                    $val /= 2;
                }
                $frame->line( $self->{ border }->[0] - $self->{ grid }{ debord }->[0], $self->{ border }->[2] + 1 + $val + $x_offset, $self->{ border }->[0] + $self->{ size }->[0] + $self->{ grid }{ debord }->[1], $self->{ border }->[2] + 1 + $val + $x_offset, $grid_color );
                if ( defined $self->{ grid }{ x_down }{ label }{ text }->[$text_indx] )
                {
                    my $text_color = $grid_color;
                    if ( exists $self->{ grid }{ x_down }{ label }{ color } )
                    {
                        $text_color = _color_allocate( $self->{ grid }{ x_down }{ label }{ color }, 'ffffffff', $frame );
                    }

                    my $radian  = ( $self->{ grid }{ x_down }{ label }{ rotation } / 180 ) * PI || 0;
                    my $kerning = $self->{ grid }{ x_down }{ label }{ kerning_correction }      || 0.91;
                    my $cos     = cos( $radian );
                    my $sin     = sin( $radian );
                    my $len = length( $self->{ grid }{ x_down }{ label }{ text }->[$text_indx] );
                    my $Xoff;
                    my $Yoff;

                    if ( $self->{ grid }{ x_down }{ label }{ align } eq 'right' )
                    {
                        $Xoff = -( ( $len**$kerning ) * $self->{ grid }{ x_down }{ label }{ size } );
                    }
                    if ( $self->{ grid }{ x_down }{ label }{ rotation } )
                    {
                        $Xoff = ( $cos * ( $self->{ grid }{ x_down }{ label }{ size } ) ) - ( $cos * ( ( $len**$kerning ) * $self->{ grid }{ x_down }{ label }{ size } ) );

                        $Yoff = ( $sin * ( ( $len**$kerning ) * $self->{ grid }{ x_down }{ label }{ size } ) ) - ( $sin * $self->{ grid }{ x_down }{ label }{ size } );
                    }
                    if ( exists $self->{ grid }{ x_down }{ type } && $self->{ grid }{ x_down }{ type } eq 'log' )
                    {
                        $x_offset = 0;
                        $val *= -1;
                    }
                    else
                    {
                        $x_offset = $self->{ size }->[1];
                    }
                    $frame->stringFT(
                        $text_color,
                        $self->{ grid }{ x_down }{ label }{ font },
                        $self->{ grid }{ x_down }{ label }{ size },
                        $radian,
                        $self->{ border }->[0] - $self->{ grid }{ debord }->[0] + $Xoff - $self->{ grid }{ x_down }{ label }{ space },
                        $self->{ border }->[2] + ( $self->{ grid }{ x_down }{ label }{ size } / 2 ) - $val + $Yoff + $x_offset,
                        $self->{ grid }{ x_down }{ label }{ text }->[$text_indx]
                    );
                }

                if ( defined $self->{ grid }{ x_down }{ label2 }{ text }->[$text_indx] )
                {
                    my $text_color = $grid_color;
                    if ( exists $self->{ grid }{ x_down }{ label2 }{ color } )
                    {
                        $text_color = _color_allocate( $self->{ grid }{ x_down }{ label2 }{ color }, 'ffffffff', $frame );
                    }
                    my $radian  = ( $self->{ grid }{ x_down }{ label2 }{ rotation } / 180 ) * PI || 0;
                    my $kerning = $self->{ grid }{ x_down }{ label2 }{ kerning_correction }      || 0.91;
                    my $cos     = cos( $radian );
                    my $sin     = sin( $radian );
                    my $len = length( $self->{ grid }{ x_down }{ label2 }{ text }->[$text_indx] );
                    my $Xoff;
                    my $Yoff;

                    if ( $self->{ grid }{ x_down }{ label2 }{ align } eq 'right' )
                    {
                        $Xoff = -( ( $len**$kerning ) * $self->{ grid }{ x_down }{ label2 }{ size } );
                    }
                    if ( exists $self->{ grid }{ x_down }{ type } && $self->{ grid }{ x_down }{ type } eq 'log' )
                    {
                        $x_offset = 0;
                        $val *= -1;
                    }
                    else
                    {
                        $x_offset = $self->{ size }->[1];
                    }
                    $frame->stringFT(
                        $text_color,
                        $self->{ grid }{ x_down }{ label2 }{ font },
                        $self->{ grid }{ x_down }{ label2 }{ size },
                        $radian,
                        $self->{ border }->[0] + $self->{ grid }{ debord }->[1] + $Xoff + $self->{ grid }{ x_down }{ label2 }{ space } + $self->{ size }->[0],
                        $self->{ border }->[2] + ( $self->{ grid }{ x_down }{ label2 }{ size } / 2 ) - $val + $Yoff + $x_offset,
                        $self->{ grid }{ x_down }{ label2 }{ text }->[$text_indx]
                    );
                }
            }
        }
    }
### end plot grid +label
    $frame->setThickness( 1 );

###  plot reticle +label
    if ( exists $self->{ reticle } )
    {
        $frame->setThickness( $self->{ reticle }{ thickness } ) || 1;
        my $grid_color = _color_allocate( $self->{ reticle }{ color }, '00000000', $frame );
        my $angle_inc = ( PI ) / ( $self->{ reticle }{ number } / 2 );

        for my $nbr ( 1 .. ( $self->{ reticle }{ number } ) )
        {
            my $polyline   = new GD::Polyline;
            my $text_angle = 0;
            my $angle      = ( $angle_inc * ( -$nbr ) ) + ( PI / 2 );
            $polyline->addPt( ( $self->{ size }[0] / 2 ) + $self->{ border }[0], $self->{ border }[2] + ( $self->{ size }[1] / 2 ) );
            $polyline->addPt( ( $self->{ size }[0] / 2 ) + $self->{ border }[0], $self->{ border }[2] + $self->{ size }[1] + $self->{ reticle }{ debord } );
            $polyline->rotate( $angle, ( $self->{ size }[0] / 2 ) + $self->{ border }[0], $self->{ border }[2] + ( $self->{ size }[1] / 2 ) );
            $frame->polydraw( $polyline, $grid_color );
            my $val = ( $nbr - 1 ) * ( int( ( $self->{ size }->[1] ) / ( $self->{ reticle }{ number } - 1 ) ) );

            if ( defined $self->{ reticle }{ label_middle }{ text }->[ $nbr - 1 ] )
            {
                my $text_color = $grid_color;
                if ( exists $self->{ reticle }{ label_middle }{ color } )
                {
                    $text_color = _color_allocate( $self->{ reticle }{ label_middle }{ color }, 'ffffffff', $frame );
                }
                my $kerning = $self->{ reticle }{ label_middle }{ kerning_correction } || 0.91;
                my $len = length( $self->{ reticle }{ label_middle }{ text }->[ $nbr - 1 ] );
                my $beta;
                my $c;
                my $pos_angle = ( $angle_inc * ( $nbr ) ) + PI - ( PI / $self->{ reticle }{ number } );
                if ( exists $self->{ reticle }{ label_middle }{ rotate } )
                {

                    if ( $self->{ reticle }{ label_middle }{ rotate } eq 'perpendicular' )
                    {
                        $text_angle = ( PI / 2 ) + ( $angle_inc * ( -$nbr ) ) + ( PI / $self->{ reticle }{ number } );
                        $c = ( ( ( ( $self->{ size }[1] / 2 ) + $self->{ reticle }{ debord } + $self->{ reticle }{ label_middle }{ space } )**2 ) + ( ( ( ( $len**$kerning ) * $self->{ reticle }{ label_middle }{ size } ) / 2 )**2 ) )**.5;
                        $beta = asin( ( ( ( $len**$kerning ) * $self->{ reticle }{ label_middle }{ size } ) / 2 ) / $c );
                    }
                    else
                    {
                        $text_angle = ( $angle_inc * ( -$nbr ) ) + ( PI / $self->{ reticle }{ number } );
                        $c = ( ( ( ( $self->{ size }[1] / 2 ) + $self->{ reticle }{ debord } + $self->{ reticle }{ label_middle }{ space } )**2 ) + ( ( ( $self->{ reticle }{ label }{ size } ) / 2 )**2 ) )**.5;
                        $beta = asin( ( ( $self->{ reticle }{ label }{ size } ) / 2 ) / $c );
                    }
                }
                my $cos  = cos( $pos_angle + $beta );
                my $sin  = sin( $pos_angle + $beta );
                my $Xoff = $cos * ( $self->{ reticle }{ label_middle }{ space } + ( $self->{ size }[1] / 2 ) + $self->{ reticle }{ debord } );
                my $Yoff = $sin * ( $self->{ reticle }{ label_middle }{ space } + ( $self->{ size }[1] / 2 ) + $self->{ reticle }{ debord } );

                if ( exists $self->{ reticle }{ label_middle }{ rotate } )
                {
                    if ( $self->{ reticle }{ label_middle }{ rotate } eq 'perpendicular' )
                    {
                        $Xoff = $cos * ( $self->{ reticle }{ label_middle }{ space } + $c + ( $self->{ reticle }{ label_middle }{ size } ) );
                        $Yoff = $sin * ( $self->{ reticle }{ label_middle }{ space } + $c + ( $self->{ reticle }{ label_middle }{ size } ) );
                    }
                    else
                    {
                        $Xoff = $cos * ( $self->{ reticle }{ label_middle }{ size } + $self->{ reticle }{ label_middle }{ space } + ( $self->{ size }[1] / 2 ) + $self->{ reticle }{ debord } );
                        $Yoff = $sin * ( $self->{ reticle }{ label_middle }{ size } + $self->{ reticle }{ label_middle }{ space } + ( $self->{ size }[1] / 2 ) + $self->{ reticle }{ debord } );
                    }
                }
                $frame->stringFT( $text_color, $self->{ reticle }{ label_middle }{ font }, $self->{ reticle }{ label_middle }{ size }, $text_angle, ( $self->{ size }[0] / 2 ) + $self->{ border }[0] - $Xoff, $self->{ border }[2] + ( $self->{ size }[1] / 2 ) - $Yoff, $self->{ reticle }{ label_middle }{ text }->[ $nbr - 1 ] );
            }

            if ( defined $self->{ reticle }{ label }{ text }->[ $nbr - 1 ] )
            {
                my $text_color = $grid_color;
                if ( exists $self->{ reticle }{ label }{ color } )
                {
                    $text_color = _color_allocate( $self->{ reticle }{ label }{ color }, 'ffffffff', $frame );
                }
                my $kerning = $self->{ reticle }{ label }{ kerning_correction } || 0.91;
                my $len = length( $self->{ reticle }{ label }{ text }->[ $nbr - 1 ] );
                my $beta;
                my $c;
                my $pos_angle = ( $angle_inc * ( $nbr ) ) + PI - ( 2 * PI / $self->{ reticle }{ number } );

                if ( exists $self->{ reticle }{ label }{ rotate } )
                {
                    if ( $self->{ reticle }{ label }{ rotate } eq 'perpendicular' )
                    {
                        $text_angle = ( PI / 2 ) + ( $angle_inc * ( -$nbr ) ) + ( 2 * PI / $self->{ reticle }{ number } );
                        $c = ( ( ( ( $self->{ size }[1] / 2 ) + $self->{ reticle }{ debord } + $self->{ reticle }{ label_middle }{ space } )**2 ) + ( ( ( ( $len**$kerning ) * $self->{ reticle }{ label }{ size } ) / 2 )**2 ) )**.5;
                        $beta = asin( ( ( ( $len**$kerning ) * $self->{ reticle }{ label }{ size } ) / 2 ) / $c );
                    }
                    else
                    {
                        $text_angle = ( $angle_inc * ( -$nbr ) ) + ( 2 * PI / $self->{ reticle }{ number } );
                        $c = ( ( ( ( $self->{ size }[1] / 2 ) + $self->{ reticle }{ debord } + $self->{ reticle }{ label_middle }{ space } )**2 ) + ( ( ( $self->{ reticle }{ label }{ size } ) / 2 )**2 ) )**.5;
                        $beta = asin( ( ( $self->{ reticle }{ label }{ size } ) / 2 ) / $c );
                    }
                }
                my $cos  = cos( $pos_angle + $beta );
                my $sin  = sin( $pos_angle + $beta );
                my $Xoff = $cos * ( $self->{ reticle }{ label }{ space } + ( $self->{ size }[1] / 2 ) + $self->{ reticle }{ debord } );
                my $Yoff = $sin * ( $self->{ reticle }{ label }{ space } + ( $self->{ size }[1] / 2 ) + $self->{ reticle }{ debord } );

                if ( exists $self->{ reticle }{ label }{ rotate } )
                {
                    if ( $self->{ reticle }{ label }{ rotate } eq 'perpendicular' )
                    {
                        $Xoff = $cos * ( $self->{ reticle }{ label }{ space } + $c + ( $self->{ reticle }{ label }{ size } ) );
                        $Yoff = $sin * ( $self->{ reticle }{ label }{ space } + $c + ( $self->{ reticle }{ label }{ size } ) );
                    }
                    else
                    {
                        $Xoff = $cos * ( $self->{ reticle }{ label }{ size } + $self->{ reticle }{ label }{ space } + ( $self->{ size }[1] / 2 ) + $self->{ reticle }{ debord } );
                        $Yoff = $sin * ( $self->{ reticle }{ label }{ size } + $self->{ reticle }{ label }{ space } + ( $self->{ size }[1] / 2 ) + $self->{ reticle }{ debord } );
                    }
                }
                $frame->stringFT( $text_color, $self->{ reticle }{ label }{ font }, $self->{ reticle }{ label }{ size }, $text_angle, ( $self->{ size }[0] / 2 ) + $self->{ border }[0] - $Xoff, $self->{ border }[2] + ( $self->{ size }[1] / 2 ) - $Yoff, $self->{ reticle }{ label }{ text }->[ $nbr - 1 ] );
            }
        }
    }
### end plot reticle +label

### plot frame around main chart
    if ( exists $self->{ frame } )
    {
        my $frame_color = _color_allocate( $self->{ frame }{ color }, '00000000', $frame );

        my $polyF = new GD::Polygon;
        $frame->setThickness( $self->{ frame }{ thickness } );
        $polyF->addPt( $self->{ border }->[0],                        $self->{ border }->[2] );
        $polyF->addPt( $self->{ border }->[0],                        $self->{ border }->[2] + $self->{ size }->[1] );
        $polyF->addPt( $self->{ border }->[0] + $self->{ size }->[0], $self->{ border }->[2] + $self->{ size }->[1] );
        $polyF->addPt( $self->{ border }->[0] + $self->{ size }->[0], $self->{ border }->[2] );
        $frame->openPolygon( $polyF, $frame_color );
    }
### end plot frame

### plot glyph on the main chart
    if ( exists $self->{ glyph } )
    {
        foreach my $item ( @{ $self->{ glyph } } )
        {
            my $X = 1;
            my $Y = 1;

            $X += $item->{ x };
            $Y += $item->{ y };

            my $glyph_color = _color_allocate( $item->{ color }, '00000000', $frame );
            if ( exists $item->{ type } && $item->{ type } eq 'filled' )
            {
                my $polyG = new GD::Polygon;
                foreach my $point ( @{ $item->{ data } } )
                {
                    next unless ( ref $point eq 'ARRAY' );
                    $polyG->addPt( $X + $point->[0], $self->{ border }->[3] + $self->{ border }->[2] + $self->{ size }->[1] - $Y - $point->[1] );
                }

                $frame->filledPolygon( $polyG, $glyph_color );
            }
            elsif ( exists $item->{ type } && $item->{ type } eq 'text' )
            {
                foreach my $point ( @{ $item->{ data } } )
                {
                    my $text_angle = 0;
                    if ( exists $point->[3] )
                    {
                        $text_angle = ( $point->[3] / 180 ) * PI;
                    }
                    $frame->stringFT( $glyph_color, $item->{ font }, $item->{ size }, $text_angle, $X + $point->[1], $self->{ border }->[3] + $self->{ border }->[2] + $self->{ size }->[1] - $Y - $point->[2], $point->[0] );
                }
            }
            else
            {
                my $polyG = new GD::Polygon;
                foreach my $point ( @{ $item->{ data } } )
                {
                    next unless ( ref $point eq 'ARRAY' );
                    $polyG->addPt( $X + $point->[0], $self->{ border }->[3] + $self->{ border }->[2] + $self->{ size }->[1] - $Y - $point->[1] );
                }
                $frame->openPolygon( $polyG, $glyph_color );
            }
        }
    }
### end plot glyph

    $self->{ img } = $frame->png;
    if ( $object )
    {
        $self->png_zEXt( $object );
    }
    return $self->{ img };
}

# sub log10
# {
#     my $n = shift;
#     return log( $n ) / log( 10 );
# }

1;

__END__

=head1 COLOR format

  the color could be in the form of html hexa value '0xff00ff' of simple the hexa value 'ff00ff' all must be read as a string 0xff0000 = 16711680
  it is also possible to use an array with multiple color to create a 'gdDtyled' color ( see GP.pm doc )
  example:
  color => [
	'0xff0000',
	'0xff0000',
	'0xff0000',
	'0xff0000',
	'0x00ff00',
	'0x00ff00',
	'0x00ff00',
	'gdTransparent',
	'gdTransparent'
	],
	
=over

=back

=head1 TODO

=over


=item *

A good test.pl for the install

=back

=head1 AUTHOR

Fabrice Dulaunoy <fabrice@dulaunoy.com>

june 2010

=head1 LICENSE

Under the GNU GPL2

    
    This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public 
    License as published by the Free Software Foundation; either version 2 of the License, 
    or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
    See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program; 
    if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    Proc::Forking    Copyright (C) 2010 DULAUNOY Fabrice  Proc::Forking comes with ABSOLUTELY NO WARRANTY; 
    for details See: L<http://www.gnu.org/licenses/gpl.html> 
    This is free software, and you are welcome to redistribute it under certain conditions;
   


