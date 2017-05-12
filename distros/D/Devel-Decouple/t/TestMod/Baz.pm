package TestMod::Baz;

use TestMod::Foo;
use TestMod::Bar;

sub exhibit{
    inhibit()
}
sub adhibit{
    prohibit();
    exhibit();
}

1;