use Inline 'SLang' => Config => BIND_NS => [ "Global", "foo" ];
use Inline 'SLang' => <<'EOS1';
  define fn_in_global(x) { "in global"; }
  implements( "foo" );
  define fn_in_foo(x) { "in foo"; }
EOS1

printf "I am %s\n", foo::fn_in_foo("dummyval");
printf "I am %s\n", fn_in_global("dummyval");
