package Image::Signature::GrayMoment;

use strict;
our $VERSION = '0.01';

use Image::Magick;

use Image::Signature::Grayscale;


sub gray_moment {
    my $self = shift;
    my $img = $self->{img};

    my ($row, $col);
    $row = $self->{row};
    $col = $self->{col};
    my $num_points = $self->{num_points} = $row*$col;

    my $moment = 0;
    my $avg = 0;

    foreach (my $y; $y<$row; $y+=2){
        foreach (my $x; $x<$col; $x+=2){
	     $avg +=
		 to_gray((split /,/, $img->Get("pixel[$x,$y]"))[0..2])
#		 (split /,/, $img->Get("pixel[$x,$y]"))[0]
		     / $num_points;
        }
    }
    foreach (my $y; $y<$row; $y+=2){
        foreach (my $x; $x<$row; $x+=2){
	     $moment += 
		 ((to_gray((split /,/, $img->Get("pixel[$x,$y]"))[0..2])-$avg)**2)
#		 (((split /,/, $img->Get("pixel[$x,$y]"))[0]- $avg)**2)
		     / $num_points;
        }
    }
    $self->{std_moment} = $moment;
    $self->{num_points} = $num_points;
    $self->{gray_avg}   = $avg;
    $moment;
}



1;
__END__
