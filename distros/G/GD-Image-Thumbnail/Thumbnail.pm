package GD::Image::Thumbnail;

use strict;
use warnings;
use POSIX qw(ceil floor);
use GD;

our $VERSION = '0.02';

sub GD::Image::thumbnail {
    my $gdo = shift;
    my %thm;
    my($w,$h) = $gdo->getBounds;
    if(ref $_[0] eq 'HASH') {
       delete $thm{nh};
       delete $thm{nw};
       %thm = %{ shift() };
    } else { $thm{side} = shift }
    my $hori = $w > $h ? 1 : 0;
    $thm{factor} = 0.20 if !$thm{side} && !$thm{factor} && !$thm{w} && !$thm{h};
    if($thm{factor}) {
       $thm{factor} = 0.20 unless $thm{factor} > 0 && $thm{factor} < 1 && $thm{factor} =~ m/^0\.\d\d$/;
       if($thm{small}) { 
           $thm{nh} = floor $h * $thm{factor};
           $thm{nw} = floor $w * $thm{factor};  
       } else {
           $thm{nh} = ceil $h * $thm{factor};
           $thm{nw} = ceil $w * $thm{factor};
       }
    } else {
        if($thm{side}) {
            if($hori) {
                $thm{nw} = $thm{side} if $thm{small};
                $thm{nh} = $thm{side} if !$thm{small};
            } else {
                $thm{nh} = $thm{side} if $thm{small};
                $thm{nw} = $thm{side} if !$thm{small};
            }
        } else {
           if($thm{h} && $thm{w}) {
                if($hori) {
                    $thm{nw} = $thm{w} if $thm{small};
                    $thm{nh} = $thm{h} if !$thm{small};
                } else {
                    $thm{nh} = $thm{h} if $thm{small};
                    $thm{nw} = $thm{w} if !$thm{small};
                }
            } else {
                $thm{nh} = $thm{h} if $thm{h};
                $thm{nw} = $thm{w} if $thm{w};
            }
        }
        $thm{ratio} = $thm{nw} ? $w/$thm{nw} : $h/$thm{nh};
        $thm{nh} = $h/$thm{ratio};
        $thm{nw} = $w/$thm{ratio};
        if($thm{small}) {
            $thm{$_} = floor $thm{$_} for('nh','nw');
        } else {
            $thm{$_} = ceil $thm{$_} for('nh','nw');
        }
    }
    my $tho = new GD::Image($thm{nw},$thm{nh});
    if(shift || $thm{resample}) { 
        $tho->copyResampled($gdo,0,0,0,0,$thm{nw},$thm{nh},$w,$h) 
    } else { 
        $tho->copyResized($gdo,0,0,0,0,$thm{nw},$thm{nh},$w,$h) 
    }   
    return ($tho,$tho->getBounds) if wantarray;
    return $tho;
}

sub GD::Image::thumb { shift()->thumbnail(@_); }

1;

__END__

=head1 NAME

GD::Image::Thumbnail - Perl extension for creating thumbnailed images with GD. 

=head1 SYNOPSIS

    use GD::Image::Thumbnail;
 
    my $img = GD::Image->new(100,20);

    my $thm = $img->thumbnail; # same as { factor => 0.20 }
    my $thm = $img->thumbnail($n); # same as { side => $n }

    my $thm = $img->thumbnail({ factor => 0.25 });
    my $thm = $img->thumbnail({ factor => 0.25, small => 1 });

    my $thm = $img->thumbnail({ side => $n });
    my $thm = $img->thumbnail({ side => $n, small => 1 });

    my $thm = $img->thumbnail({ w => $w });
    my $thm = $img->thumbnail({ h => $h });
    my $thm = $img->thumbnail({ w => $w, h => $h });

    my $thm = $img->thumbnail({ w => $w, small => 1 });
    my $thm = $img->thumbnail({ h => $h, small => 1 });
    my $thm = $img->thumbnail({ w => $w, h => $h, small => 1 });

=head1 thumb()

thumb() is shortcut for thumbnail() - useful for people who like to bite their nails :)

    $img->thumbnail(@thm_args)

and

    $img->thumb(@thm_args);

are doing the same thing

=head1 OPTIONS

=head2 factor => $n

This makes a thumbnail $n (0.20 by default) times the size of the original. Only a two decimal place number between 0 and 1 are allowed.
If a factor is given side, h, and w are all ignored

=head2 side => $n

Makes the side that will result in a larger thumbnail $n pixels (or opposite if small => 1).
If side is given then h and w are ignored.

=head2 w => $x and h => $y

You can specify one or both of these. If only one is given it makes that side that dimention.
If you specify both, the side that will result in a larger thumbnail (based on the image's 
orientation and *not* the values of w and h if different), is used (or opposite if small => 1).

=head2 small => 1

If true make the images the smallest possible. This will round down instead of up when rounding 
is necessary and will help decide which side gets set to the given value. 

   $img->thumbnail(10); # 100 x 25 image becomes 40 x 10
   $img->thumbnail({ side => 10, small => 1}); # 100 x 25 image becomes 10 x 2

=head2 resample => 1

If true use copyResampled() instead of copyResized() See L<GD>'s documentation about the difference.
This can also be turned on by specifying a true value as the second argument:

   $img->thumbnail($n, 1);
   $img->thumbnail({ factor => $n }, 1);

=head2 RETURN VALUES

If called in scalar context it return the new GD::Image object that is the thumbnail (IE the original object is not modified)

    my $thm = $img->thumb;

If called in array context it returns an array which is the new object, the width , and height of the new image in that object.

    my($thm,$thm_w,$thm_h) = $img->thumb;

=head1 TO DO

I'd like to add functionality to modify the original image object if called in void context:

   $img->thumbnail(@thm_args);

=head1 SEE ALSO

L<GD>

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
