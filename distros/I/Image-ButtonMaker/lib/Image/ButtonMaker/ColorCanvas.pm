package Image::ButtonMaker::ColorCanvas;

use strict;
use utf8;
use Image::Magick;

my @default_publ = (


                    background_color => '#000000',
                    border_color     => '#000000',

                    border_width     => 0,
                    );


our $error;
our $errorstr;


#### Public('ish) Methods #############################

sub new {
    my $nobody = shift;
    my @param  = @_;

    my $data = {@default_publ, @param};

    bless $data;
}


sub render($$) {
    my $self = shift;
    my($tot_w, $tot_h) = @_;

    my $bgcolor  = $self->{background_color};
    my $fgcolor  = $self->{border_color};
    my $stroke_w = $self->{border_width};

    my $res = Image::Magick->new(size       => $tot_w.'x'.$tot_h,
                                 matte      => 1,
                                 mattecolor => $bgcolor
                                );
    $res->Read("xc:$bgcolor");

    if($stroke_w) {
        $res->Draw(fill        => $bgcolor,
                   stroke      => $fgcolor,
                   primitive   => 'rectangle',
                   points      => '0,0 '.($tot_w-1).','.($tot_h-1),
                   antialias   => 0,
                   strokewidth => $stroke_w,
                  );
    }

    return $res;
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
