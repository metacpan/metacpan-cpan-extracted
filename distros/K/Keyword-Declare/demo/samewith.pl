#! /usr/bin/env perl

use 5.024; use warnings; use autodie;
use lib qw< dlib ../dlib >;
use experimentals;

use Perl6::SameWith;
use Time::HiRes 'sleep';

# Show the difference in behaviour
local $SIG{__WARN__} = sub { die @_ };

sub marquee_samewith ($banner, $count = 300) {
    # Are we done yet???
    return if $count <= 0;

    # Print the banner...
    say "\n" x 30;
    say " " x 20, $banner, '   ', sprintf("%3d",$count);
    say "\n" x 15;
    sleep 0.02;

    # Make the marquee rotate...
    my $rotated_banner = substr($banner,1).substr($banner,0,1);

    samewith $rotated_banner, $count-1;
}

sub marquee_recursive ($banner, $count = 300) {
    # Are we done yet???
    return if $count <= 0;

    # Print the banner...
    say "\n" x 30;
    say " " x 20, $banner, '   ', sprintf("%3d",$count);
    say "\n" x 15;
    sleep 0.02;

    # Make the marquee rotate...
    my $rotated_banner = substr($banner,1).substr($banner,0,1);

    marquee_recursive( $rotated_banner, $count-1 );
}



marquee_samewith("Eat at Joes! ");
marquee_recursive("Eat at Shmoes! ");

