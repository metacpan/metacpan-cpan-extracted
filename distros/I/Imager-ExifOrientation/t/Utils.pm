package t::Utils;
use strict;
use warnings;

use File::Spec;
use Imager;
use Imager::Color;
use Test::More;

sub import {
    my($class, %args) = @_;
    my $caller = caller(0);

    if (delete $args{want_jpeg}) {
        unless (grep { $_ eq 'jpeg' } Imager->read_types) {
            plan skip_all => 'this test required jpeg support at Imager';
        }
    }

    strict->import;
    warnings->import;

    for my $name (qw/ is_rotated path_to slurp /) {
        no strict 'refs';
        *{"$caller\::$name"} = \&{$name};
    }
}

my $pattern_maps = {
    1 => { x => 5,  y => 5  },
    2 => { x => 25, y => 5  },
    3 => { x => 25, y => 35 },
    4 => { x => 5,  y => 35 },
    5 => { x => 5,  y => 15 },
    6 => { x => 35, y => 5  },
    7 => { x => 35, y => 25 },
    8 => { x => 5,  y => 20 },
};

sub is_rotated {
    my($orientation, $image) = @_;

    my $map = $pattern_maps->{$orientation};

    for my $x (($map->{x}-1)..($map->{x}+1)) {
        for my $y (($map->{y}-1)..($map->{y}+1)) {
            my @color = $image->getpixel( x => $x, y => $y )->rgba;
            ::ok($color[0] > $color[1]+100, "$orientation: $x, $y is R($color[0]) > G($color[1]+100)");
            ::ok($color[0] > $color[2]+200, "$orientation: $x, $y is R($color[0]) > B($color[2]+200)");
        }
    }
}

sub path_to {
    my $file = shift;
    File::Spec->catfile( 't', 'images', 'original', $file );
}

sub slurp {
    my $path = shift;
    open my $fh, '<', $path or die "$!: $path";
    local $/;
    <$fh>;
}

1;
