package TestMod::Foo;

use base 'Exporter';
our @EXPORT = ('inhibit');
sub inhibit{
    return "I'm inhibited";
}

1;