package LPDS::Util;

use strict;
use feature qw/say/;
use Gtk2;

use Exporter;
our @ISA = qw/Exporter/;

our @EXPORT = qw/uint_to_gdk_color gdk_color_to_uint search_list_store/;

sub gdk_color_to_uint {
    my $color_obj = shift;

    my $color = 0x000000ff;
    my $red   = int( 255 * $color_obj->red / 65535 ) << 24;
    my $green = int( 255 * $color_obj->green / 65535 ) << 16;
    my $blue  = int( 255 * $color_obj->blue / 65535 ) << 8;
    $color += $red;
    $color += $green;
    $color += $blue;

    return $color;
}

sub uint_to_gdk_color {
    my $color = shift;
    my $red   = ( $color & 0xff000000 ) >> 24;
    my $green = ( $color & 0x00ff0000 ) >> 16;
    my $blue  = ( $color & 0x0000ff00 ) >> 8;

    foreach ( $red, $green, $blue ) {
        $_ = int( 65535 * $_ / 255 );
    }

    return Gtk2::Gdk::Color->new( $red, $green, $blue );
}

sub search_list_store {
    my ( $store, $column, $value ) = @_;
    my $iter;
    for (
        $iter = $store->get_iter_first ;
        defined $iter ;
        $iter = $store->iter_next($iter)
      )
    {
        my $curr = $store->get($iter,$column);
        last if $curr eq $value;
    }
    
    return $iter;
}

1;
