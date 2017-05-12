use Inline 'SLang' => Config => BIND_NS => ["foo"];
use Inline 'SLang' => <<'EOS1';
  define fn_in_global(x) { "in global"; }
  implements( "foo" );
  define fn_in_foo(x) { "in foo"; }
EOS1

printf "I am %s\n", foo::fn_in_foo("dummyval");

# the following will not work since fn_in_global() is in the
# Global namespace which was not listed in the BIND_NS option
#
printf "I am %s\n", fn_in_global("dummyval");
