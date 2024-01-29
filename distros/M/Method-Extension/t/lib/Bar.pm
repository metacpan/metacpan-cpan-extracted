package Bar;
use Method::Extension;

sub new {
    bless {}, $_[0];
}

sub baz : ExtensionMethod(Foo) {
    "Baz from extension method";
}

1;
