package Image::ButtonMaker::TextContainer;

use Image::Magick;
use strict;
use utf8;


#### Create a dummy image for QueryFontMetrics calls
my $idummy = Image::Magick->new();
$idummy->Read('xc:black');



#### Prototype for TextContainer objects
my @defaults = (
                layout      => 'horizontal',
                align       => 'baseline',
                cells       => [],
                );


my @align_horiz_types  = ('baseline', 'top', 'bottom');
my @layout_types = ('vertical', 'horizontal'); 


#### Private data for TextContainer objects
my @defaults_priv = (
                     error  => 0,
                     errstr => '',
                     );


#### Error codes
use constant ERR_WRONG_CELL_TYPE  => 100;
use constant ERR_WRONG_CELL_PARAM => 101;
use constant ERR_UNSUPPORTED_FEAT => 1000;


#### Cell prototypes #####################################
my @cell_types = ('text', 'space', 'icon');
my %cell_proto = (
                  text => {
                           type      => 'text',
                           font      => '',
                           size      => 10,
                           text      => 'NO_TEXT',
                           antialias => 1,
                           fill      => 'white',
                           scale     => 1.0,
                           },

                  space => {
                            type  => 'space',
                            width => 3,
                            },

                  icon  => {
                            type => 'icon',
                            image => undef,
                            vertfix => 0,
                           }
                  );



##########################################################
## Public-ish methods 
sub new {
    my $self  = shift;
    my @param = @_; 

    my $data = { @defaults, @param };

    return undef unless(search_array($data->{layout}, \@layout_types));

    if($data->{layout} eq 'horizontal') {
        unless(search_array($data->{align}, \@align_horiz_types)) {
            print STDERR "Alignment ".$data->{align}." not supported for layout horizontal\n";
            return undef;
        }
    }

    if($data->{layout} eq 'vertical') {
        print STDERR "Vertical alignment not supported yet\n";
        return undef;
    }

    $data->{cells} = [];

    bless $data;

    $data->reset_error;

    return $data;
}


#### add cell to array and return undef
sub add_cell {
    my $self = shift;
    my %param = @_;

    ## Find cell type
    my $type = $param{type};
    $type = 'space' unless $type;

    if(!search_array($type, \@cell_types)) {
        return $self->set_error(ERR_WRONG_CELL_TYPE,
                                "Unknown cell type: $type");

    }

    my $proto   = $cell_proto{$type};
    my $newcell =  { %$proto };

    foreach my $k (keys(%param)) {
        ## Return error if prototype doesn't have param
        if(!exists($proto->{$k})) {
            return $self->set_error(ERR_WRONG_CELL_PARAM, 
                                    "Unknown param $k for cell type $type");
        }
        $newcell->{$k} = $param{$k};
    }

    my $cells = $self->{cells};
    push @$cells, $newcell;

    return undef;
}


#### compute width and height for all the cells together
#### Return (width, height) or undef (+ set errorerror)
sub compute_size {
    my $self = shift;
    $self->reset_error;

    #### initialize values
    my ($max_asc, $max_height, $min_desc) = (0,0,0);
    my $acc_width = 0;

    my $cells = $self->{cells};

    foreach my $cell (@$cells) {
        my $type = $cell->{type};

        if($type eq 'text') {
            my %text_param =(font      => $cell->{font},
                             pointsize => $cell->{size},
                             scale     => $cell->{scale},
                             text      => $cell->{text},
                             );


            my ($x_ppem, $y_ppem, $ascender, $descender, $width, $height, $max_advance) =
                $idummy->QueryFontMetrics(%text_param);


            #Height is kinda strange. Recompute:
            $height = $ascender - $descender;

            $acc_width += $width;
            $max_height = $height    if($height    > $max_height);
            $max_asc    = $ascender  if($ascender  > $max_asc);
            $min_desc   = $descender if($descender < $min_desc);
        }

        elsif($type eq 'space') {
            $acc_width += $cell->{width};
        }
        elsif($type eq 'icon') {
            my($width, $height) = $cell->{image}->Get('columns', 'rows');

            $max_height = $height if($height > $max_height);
            $max_asc    = $height if($height > $max_asc);
            $acc_width += $width;
        }
    }

    if($self->{align} eq 'baseline') {
        return ($acc_width, $max_asc-$min_desc, $max_asc, $min_desc);
    }
    return ($acc_width, $max_height, $max_asc, $min_desc);
}


#### render cells into a target image
sub render {
    my $self = shift;
    my ($image, $x_offset, $y_offset) = @_;
    $x_offset = 0 unless($x_offset);
    $y_offset = 0 unless($y_offset);

    $self->reset_error;

    my $layout = $self->{layout};
    if($layout ne 'horizontal') {
        $self->set_error(ERR_UNSUPPORTED_FEAT,
                         "Unsupported layout: $layout");
        return undef;
    }

    my $align = $self->{align};
    my $cells = $self->{cells};

    my ($img_width, $img_height, $max_asc, $min_desc) = $self->compute_size;

    #### If no target image is passed, then generate a target
    if(!$image) {
        $image = Image::Magick->new(size  => $img_width .'x'.$img_height,
                                       matte => 1,
                                       );
        $image->Read('xc:rgba(0,0,0,0)');
    }

    my $leftpoint = $x_offset;
    my $toppoint;

    foreach my $cell (@$cells) {
        my $type = $cell->{type};

        if($type eq 'text') {

            my %text_param =(font      => $cell->{font},
                             pointsize => $cell->{size},
                             text      => $cell->{text},
                             );

            my( $x_ppem, $y_ppem, $ascender, $descender, 
                $width,  $height, $max_advance ) =
                $idummy->QueryFontMetrics(%text_param);

            $height = $ascender - $descender;

            $text_param{antialias} = $cell->{antialias};
            $text_param{fill}      = $cell->{fill};
            $text_param{stroke}    = 'rgba(0,0,0,255)';
            $text_param{scale}     = $cell->{scale};

            if($align eq 'top') {
                $toppoint = $ascender + $y_offset;
            }
            elsif($align eq 'bottom') {
                $toppoint = $img_height + $descender + $y_offset;;
            }
            elsif($align eq 'baseline') {
                $toppoint = $max_asc + $y_offset;;
            }

            $text_param{x} = $leftpoint;
            $text_param{y} = $toppoint;

            my $rr = $image->Annotate(%text_param);

            $leftpoint += $width;
        }
        elsif($type eq 'icon') {

            my $icon = $cell->{image};
            my($i_width, $i_height) = $icon->Get('columns', 'rows');


            if($align eq 'top') {
                $toppoint = $y_offset;;
            }
            elsif($align eq 'bottom') {
                $toppoint = $img_height - $i_height + $y_offset;;
            }
            elsif($align eq 'baseline') {
                $toppoint = $max_asc - $i_height + $y_offset;;
            }

            my $vvv = $cell->{vertfix};

            if($cell->{vertfix}) {
                $toppoint += $cell->{vertfix};
            }

            $toppoint = 0 if($toppoint < 0);

            $image->Composite(image   => $icon,
                              compose => 'Over',
                              geometry=> fromtop($leftpoint, $toppoint)
                              );
            $leftpoint += $i_width;
        }
        elsif($type eq 'space') {
            $leftpoint += $cell->{width};
        }
    }

    return $image;
}


#### set alignment
sub set_align {
    my $self  = shift;
    my $align = shift; 
    return 0;
}


##########################################################
## Private-ish methods

sub reset_error {
    my $self = shift;

    $self->{error} = 0;
    $self->{errstr} = '';
    return;
}


sub set_error {
    my $self = shift;

    $self->{error}  = shift;
    $self->{errstr} = shift;

    print $self->{errstr}, "\n";
    return $self->{errstr};
}


sub is_error {
    my $self = shift;
    return ($self->{error} != 0);
}

sub get_errstr {
    my $self = shift;
    return $self->{errstr};
}

##### search_array(value, array_reference)
##    retval: 0 or 1
sub search_array {
    my($val, $arr) = @_;

    foreach my $v (@$arr) {
        return 1 if($v eq $val);
    }

    return 0;
}

###### Create geometry string counting from left top corner
##     retval: geometry string
sub fromtop {
    my $x = shift;
    my $y = shift;
    return '+'.$x.'+'.$y;
}


1;
