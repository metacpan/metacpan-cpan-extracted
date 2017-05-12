package Image::ButtonMaker::TemplateCanvas;

use strict;
use utf8;
use Image::Magick;

my @default_publ = (

                    template   => undef,

                    ### Cut parameters
                    cut_left   => 4,
                    cut_right  => 4,
                    cut_top    => 3,
                    cut_bottom => 3,

                    ### Matte color
                    matte_color => '#000000',
                    );


my @default_priv = (
                    slices => undef,
                    );


our $error;
our $errorstr;


#### Public('ish) Methods #############################

sub new {
    my $nobody = shift;
    my @param  = @_;

    my $data = {@default_publ, @param, @default_priv};

    die "No template given" unless($data->{template});

    my $slices = slice_it_up($data->{template},
                             $data->{cut_left},
                             $data->{cut_right},
                             $data->{cut_top},
                             $data->{cut_bottom},
                             $data->{matte_color},
                             );

    return undef unless($slices);

    $data->{slices} = $slices;
    bless $data;
}


sub render($$) {
    my $self = shift;
    my($tot_w, $tot_h) = @_;
    my $slc = $self->{slices};
    my $cur;

    my ($left, $right, $top, $bottom) = ($self->{cut_left}, $self->{cut_right},
                                         $self->{cut_top},  $self->{cut_bottom});

    ## Calculate width & height for center tile
    my $c_width  = $tot_w - $left - $right;
    my $c_height = $tot_h - $top  - $bottom;

    ## Create the button image
    my $matte_color = $self->{matte_color};
    my $res = Image::Magick->new(size => $tot_w.'x'.$tot_h, matte => 1, mattecolor => $matte_color);
    $res->Read("xc:$matte_color");

    ## Top left corner
    $cur = $slc->[0]->Clone;
    $cur->Resize(width=> $left, height => $top);
    $res->Composite(image => $cur, compose => 'Over', geometry=>fromtop(0,0));

    ## Top middle
    $cur = $slc->[1]->Clone;
    $cur->Resize(width=> $c_width, height => $top);
    $res->Composite(image => $cur, compose => 'Over', geometry=>fromtop($left,0));

    ## Top right corner
    $cur = $slc->[2]->Clone;
    $cur->Resize(width=> $right, height => $top);
    $res->Composite(image => $cur, compose => 'Over', geometry=>fromtop($left+$c_width, 0));


    ## Middle left part
    $cur = $slc->[3]->Clone;
    $cur->Resize(width=> $left, height => $c_height, , blur => 0);
    $res->Composite(image => $cur, compose => 'Over', geometry=>fromtop(0, $top));

    ## Middle middle part (Canvas)
    $cur = $slc->[4]->Clone;
    $cur->Set(matte => 'True', mattecolor=> $matte_color);
    $cur->Resize(width=> $c_width, height => $c_height, blur => 1, filter => 'Point');
    $res->Composite(image => $cur, compose => 'Over', geometry=>fromtop($left, $top));

    ## Middle right part
    $cur = $slc->[5]->Clone;
    $cur->Resize(width=> $right, height => $c_height, , blur => 0);
    $res->Composite(image => $cur, compose => 'Over', geometry=>fromtop($left+$c_width, $top));


    ## Bottom left part
    $cur = $slc->[6]->Clone;
    $cur->Resize(width=> $left, height => $bottom);
    $res->Composite(image => $cur, compose => 'Over', geometry=>fromtop(0, $top+$c_height));

    ## Bottom middle part (Canvas)
    $cur = $slc->[7]->Clone;
    $cur->Resize(width=> $c_width, height => $bottom);
    $res->Composite(image => $cur, compose => 'Over', geometry=>fromtop($left, $top+$c_height));

    ## Bottom right part
    $cur = $slc->[8]->Clone;
    $cur->Resize(width=> $right, height => $bottom);
    $res->Composite(image => $cur, compose => 'Over', geometry=>fromtop($left+$c_width, $top+$c_height));

    return $res;
}


#### Privatish methods ################################
##


#### Class Method: slice_it_up($image, $left, $right, $top, $bottom)
##   return value: Image::Magick object containing nine slices
sub slice_it_up($$$$$$) {
    my $image = shift;

    my ($left, $right, $top, $bottom, $mattecolor) = @_;

    my($img_h, $img_w) = $image->Get('rows', 'columns');

    my $middle_h = $img_h - $top - $bottom;
    my $middle_w = $img_w - $left - $right;

    return 
        set_error(1000, "Canvas Cut leaves no space for artwork") 
        if($middle_h < 1 || $middle_w < 1);

    my $result = Image::Magick->new(mattecolor => $mattecolor, matte => 'True');
    my $cur;

    #### Top left slice
    $cur = $image->Clone;
    $cur->Crop(width => $left, height => $top, x => 0, y => 0);
    $result->[0] = $cur;

    #### Top middle
    $cur = $image->Clone;
    $cur->Crop(width => $middle_w, height => $top, x => $left, y => 0);
    $result->[1] = $cur;

    #### Top right
    $cur = $image->Clone;
    $cur->Crop(width => $right, height => $top, x => $left+$middle_w, y => 0);
    $result->[2] = $cur;

    ### Middle left
    $cur = $image->Clone;
    $cur->Crop(width => $left, height => $middle_h, x => 0, y => $top);
    $result->[3] = $cur;

    ### Middle middle
    $cur = $image->Clone;
    $cur->Crop(width => $middle_w, height => $middle_h, x => $left, y => $top);
    #$cur->Crop(geometry => "${middle_w}x${middle_h}+${left}+${top}");
    $result->[4] = $cur;

    ### Middle right
    $cur = $image->Clone;
    $cur->Crop(width => $right, height => $middle_h, x => $left+$middle_w, y => $top);
    $result->[5] = $cur;

    ### Bottom left
    $cur = $image->Clone;
    $cur->Crop(width => $left, height => $bottom, x => 0, y => $top+$middle_h);
    $result->[6] = $cur;

    ### Bottom middle
    $cur = $image->Clone;
    $cur->Crop(width => $middle_w, height => $bottom, x => $left, y => $top+$middle_h);
    $result->[7] = $cur;

    ### Bottom right
    $cur = $image->Clone;
    $cur->Crop(width => $right, height => $bottom, x => $left+$middle_w, y => $top+$middle_h);
    $result->[8] = $cur;

    return $result;

}

#### Format a geometry string ####
sub fromtop($$) {
    my $x = shift;
    my $y = shift;
    return '+'.$x.'+'.$y;
}

#### Error Handling
sub reset_error {
    $error = 0;
    $errorstr = '';
}

sub set_error {
    $error    = shift;
    $errorstr = shift;
    return @_;
}

1;
