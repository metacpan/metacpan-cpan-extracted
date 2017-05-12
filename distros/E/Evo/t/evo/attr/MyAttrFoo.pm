package MyAttrFoo;
use Evo '-Attr';

no strict 'refs';    ## no critic

# directly
Evo::Attr::register_attribute(__PACKAGE__,
  'Foo1',
  sub ($dest, $code, $name, @opts) {
    local $, = '; ';
    ${"${dest}::GOT_FOO1"} = [$dest, $code, $name, @opts];
  }
);

# by EvoAttr attribute
sub Foo2 ($dest, $code, $name, @opts) : Attr {
  local $, = '; ';
  ${"${dest}::GOT_FOO2"} = [$dest, $code, $name, @opts];
}

1;
