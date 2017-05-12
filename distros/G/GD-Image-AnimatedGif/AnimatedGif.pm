package GD::Image::AnimatedGif;

use strict;
use warnings;
use GD; # gdlib v 2.0.33 or later required

our $VERSION = '0.05';

sub GD::Image::animated_gif {
  my ($im,$lp,$ft,$fc,$sp,$x,$y,$ar,$cd) = @_;
  $lp = $lp ? 0 : 1;
  my @addargs = (0,0,0,$sp,1);
  my $prev = $im;

  $cd = sub { shift->string($ft,$x,$y,shift,$fc); } if ref $cd ne 'CODE';
 
  my $gifdata = $im->gifanimbegin(1,$lp);
  for(@{ $ar }) {
    my $frame  = GD::Image->new($im->getBounds);
    $cd->($frame,$_);
    $gifdata .= $frame->gifanimadd(@addargs,$prev);
    $prev = $frame;
  }
  $gifdata   .= $im->gifanimend;
  return $gifdata;
}

sub GD::Image::animated_gif_easy {
  my $img = shift;
  my $lup = shift || 0;
  $img->transparent($img->colorAllocate(255,255,255)) if shift;
  return $img->animated_gif($lup,GD::Font->Small(),$img->colorAllocate(0,0,0),42,4,2,shift,shift);
}

1;
__END__

=head1 NAME

GD::Image::AnimatedGif - Perl extension for creating animated gifs with GD

=head1 SYNOPSIS

    use GD::Image::AnimatedGif;

    # setup the image
    my $image = GD::Image->new(42,21);
    my $white = $image->colorAllocate(255,255,255);
    $image->transparent($white);

    # setup some font goodies
    my $fontcolor = $image->colorAllocate(0,0,0);
    my $font = GD::Font->Small();

    # setup some settings into variables
    my $loop = 0;
    my $speed = 42; # 1/100 of a sec
    my $x_font = 10; # from right (x or y ??)
    my $y_font = 2; # from top (x or $y ??)

    print "Content-type: image/gif\n\n";
    print $image->animated_gif($loop,$font,$fontcolor,$speed,$x_font,$y_font,[qw(text per frame)],\&optional_frame_handler);

or

    print $image->animated_gif_easy(0,0,\@array,\&optional_frame_handler);

So you can have this be your entire script, actual animation creation is on one line:

    #!/usr/bin/perl

    use strict;
    use warnings;
    use GD::Image::AnimatedGif;

    print "Content-type: image/gif\n\n";
    print GD::Image->new(50,20)->animated_gif_easy(0,[qw(10 9 8 7 6 5 4 3 2 1 0 Liftoff!)]);


=head1 DESCRIPTION

Quickly and easily create optimized animated gifs with GD.

=head2 animated_gif()

Returns an entire gif ready to use. The arguments are:

   0 - loop the animation if set to true
   1 - font object
   2 - font color
   3 - speed of frames in 1/100 of a sec
   4 - x position of font
   5 - y position of font
   6 - array ref of strings to have in each frame
   7 - (optional) code ref to handle creating each frame (see below for more info)

=head2 animated_gif_easy()

call animate_gif with some defaults so all you have to specify is:
  
   0 - loop the animation if set to true
   1 - set white transparency if true, (may want it to be false if changing the background color of each frame in a frame handler for instance)
   2 - array ref of strings to have in each frame
   3 - (optional) code ref to handle creating each frame (see below for more info)

The font is GD::Font->Small() in black.
The speed is 42/100 of a second and the font's x is 4 and y is 2

=head2 \&optional_frame_handler

Without this the animation has one element of the array ref in each frame as a string.

It is using by default, essentially:

    sub { 
        my $frm = shift;
        $frm->string($font,$x_font,$y_font,shift,$fontcolor); 
    }

to accomplish this. If you specify a code ref it will be used instead and you will be able to do anything you want with each frame.

The first argument is the GD::Image object for the frame and the second is the array element we are on in the loop.

So you could use the array as a counter or other reference to decide how to manipulate the frame's GD::Image object if you like.

For example, to change the background color and text color in each frame:

    my $frame_array = [
        { bgcolor => [0,0,0], fontcolor => [255,255,255] },
        { bgcolor => [255,255,255], fontcolor => [0,0,0] }
    ];

    my $frame_handler = sub {
        my $frm = shift;
        my $arr = shift;
        $frm->colorAllocate( @{ $arr->{bgcolor} } );
        $frm->string(GD::Font->Small(),4,4,'Perl is great!',$frm->colorAllocate( @{ $arr->{fontcolor} } )); 
    };

    print "Content-type: image/gif\n\n";
    print GD::Image->new(100,20)->animated_gif_easy(1,0,$frame_array,$frame_handler);

Or to create an animation based on a series of still images:

    my $frame_handler = sub {
        my $frm = shift;
        my $imgx = GD::Image->new(shift) or die $!;
        $frm->copy($imgx,0,0,0,0,$frm->getBounds);
    };

    print "Content-type: image/gif\n\n";
    print GD::Image->new(25,25)->animated_gif_easy(1,1,\@image_file_paths,$frame_handler);

=head1 SEE ALSO

See script example info at url in "AUTHOR" section below for "Secret Decoder Ring" script as an neat usage example ;p

    L<GD>

=head1 AUTHOR

Daniel Muey,  L<http://drmuey.com/cpan_contact.pl> 

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
