package Graphics::ColorNames::Test;

use v5.6;

use strict;
use warnings;

sub NamesRgbTable() {
    use integer;
    return {
        'black'       => 0x000000,
        'blue'        => 0x0000ff,
        'cyan'        => 0x00ffff,
        'green'       => 0x00ff00,
        'magenta'     => 0xff00ff,
        'red'         => 0xff0000,
        'yellow'      => 0xffff00,
        'white'       => 0xffffff,
        'darkblue'    => 0x000080,
        'darkcyan'    => 0x008080,
        'darkgreen'   => 0x008000,
        'darkmagenta' => 0x800080,
        'darkred'     => 0x800000,
        'darkyellow'  => 0x808000,
        'darkgray'    => 0x808080,
        'lightgray'   => 0xc0c0c0,
    };
}

1;

__END__
