use Inline 'SLang' => <<'EOS';
typedef struct { x, foo } My_Struct;
define is_okay(x) {
  if ( typeof(x) != My_Struct ) {
    vmessage("You sent me a %S", typeof(x));
    return;
  }
  vmessage( "My_Struct field x   = %S", x.x );
  vmessage( "My_Struct field foo = %S", x.foo );
}
EOS

my $s = My_Struct->new();
$$s{x}   = 1;
$$s{foo} = "foo foo";
is_okay( $s );
