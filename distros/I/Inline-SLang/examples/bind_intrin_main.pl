use Inline 'SLang' => Config => BIND_SLFUNCS => ["typeof"];
use Inline 'SLang' => "define get_typeof(x) { typeof(x); }";

# both print
#  The S-Lang type of 'foo' is String_Type
printf "The S-Lang type of 'foo' is %s\n", get_typeof("foo");
printf "The S-Lang type of 'foo' is %s\n", typeof("foo");
