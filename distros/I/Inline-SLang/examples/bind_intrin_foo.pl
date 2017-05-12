use Inline 'SLang' => Config =>
  BIND_NS => "Global=foo",
  BIND_SLFUNCS => ["typeof"];
#use Inline 'SLang' => "define pointless() { return NULL; }";
use Inline 'SLang' => " ";

# This also prints
#  The S-Lang type of 'foo' is String_Type
printf "The S-Lang type of 'foo' is %s\n", foo::typeof("foo");
