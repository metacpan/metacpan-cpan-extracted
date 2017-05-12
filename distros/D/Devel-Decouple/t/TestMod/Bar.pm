package TestMod::Bar;

use base 'Exporter';
our @EXPORT = ('prohibit');
sub prohibit{
    return "I'm prohibited";
}

1;