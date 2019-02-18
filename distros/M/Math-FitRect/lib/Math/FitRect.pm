package Math::FitRect;

$Math::FitRect::VERSION = '0.05';

=head1 NAME

Math::FitRect - Resize one rect in to another while preserving aspect ratio.

=head1 SYNOPSIS

    use Math::FitRect;
    
    # This will return: {w=>40, h=>20, x=>0, y=>10}
    my $rect = fit_rect( [80,40] => 40 );
    
    # This will return: {w=>80, h=>40, x=>-19, y=>0}
    my $rect = crop_rect( [80,40] => 40 );

=head1 DESCRIPTION

This module is very simple in its content but can save much time, much like
other simplistic modules like L<Data::Pager>.  This module is useful for
calculating what size you should resize images as for such things as
thumbnails.

=cut

use strict;
use warnings;

use Carp qw( croak );

use Exporter qw( import );
our @EXPORT_OK = qw(
    fit_rect
    crop_rect
);

=head1 RECTANGLES

Rectangles may be specified in several different forms to fit your needs.

=over

=item A simple scalar integer containg the pixel width/height of a square.

=item An array ref containing the width and height of a rectangle: [$width,$height]

=item A hash ref containg a w (width) and h (height) key: {w=>$width,h=>$height}

=back

=head1 FUNCTIONS

=head2 fit_rect

    # This will return: {w=>40, h=>20, x=>0, y=>10}
    my $rect = fit_rect( [80,40] => 40 );

Takes two rectangles and fits the first one inside the second one.  The rectangle
that will be returned will be a hash ref with a 'w' and 'h' parameter as well
as 'x' and 'y' parameters which will specify any offset.

=cut

sub fit_rect {
    return _calc_rect('fit',@_);
}

=head2 crop_rect

    # This will return: {w=>80, h=>40, x=>-19, y=>0}
    my $rect = crop_rect( [80,40] => 40 );

Like the fit_rect function, crop_rect takes two rectangles as a parameter and it
makes $rect1 completely fill $rect2.  This can mean that the top and bottom or
the left and right get chopped off (cropped).  This method returns a hash ref just
like fit_rect.

=cut

sub crop_rect {
    return _calc_rect('crop',@_);
}

sub _calc_rect {
    my($type,$from,$to) = @_;
    $from = _normalize($from);
    $to = _normalize($to);
    my($w,$h,$x,$y);
    if($type eq 'crop'){ ($to->{r},$from->{r}) = ($from->{r},$to->{r}); }

    if($from->{r} < $to->{r}){
        $w = $from->{w} * ($to->{h}/$from->{h});
        $h = $to->{h};
        $x = ($to->{w}-$w)/2;
        $y = 0;
    }else{
        $h = $from->{h} * ($to->{w}/$from->{w});
        $w = $to->{w};
        $y = ($to->{h}-$h)/2;
        $x = 0;
    }

    return {w=>int($w+0.5),h=>int($h+0.5),x=>int($x+0.5),y=>int($y+0.5)};
}

sub _normalize {
    my $rect = shift;
    my($w,$h,$r);
    if(!ref($rect)){ # square
        $w = $h = $rect;
    }elsif(ref($rect) eq 'HASH'){ # rect hash ref
        $w = $rect->{w};
        $h = $rect->{h};
    }elsif(@$rect==2){ # width, height
        $w = $rect->[0];
        $h = $rect->[1];
    }elsif(@$rect==4){ # x1, y1, x2, y2
        if($rect->[0]<$rect->[2]){ $w=($rect->[2]-$rect->[0])+1; }
        else{ $w=($rect->[0]-$rect->[2])+1; }
        if($rect->[1]<$rect->[3]){ $h=($rect->[3]-$rect->[1])+1; }
        else{ $h=($rect->[1]-$rect->[3])+1; }
    }else{
        croak('Invalid rectangle parameter');
    }
    $r = $w/$h;
    return {w=>$w,h=>$h,r=>$r};
}

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

