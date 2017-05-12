package Image::Signature::ColorHistogram;

use strict;
our $VERSION = '0.01';

use Image::Magick;

use Image::Signature::Vars;

sub color_histogram {
    my $self = shift;
    # sampling pixel distance
    my $spdist = shift() || 2;
    my $img = $self->{img};
    my $histogram;

    my ($row, $col) = $img->Get(qw/rows columns/);

    foreach (my $y; $y<$row; $y+=$spdist){
	foreach (my $x; $x<$row; $x+=$spdist){
	    my @fields = split /,/, $img->Get("pixel[$x,$y]");
	    foreach my $idx (0..3){
		$histogram->{$colorname[$idx]}->{$fields[$idx]} ++;
	    }
	}
    }
    $self->{color_histogram} = $histogram;
}



1;
__END__
