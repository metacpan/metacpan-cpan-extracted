#
# Use this via 'perl -Mblib -MInline=info example/info.pl'
#

use Inline SLang;
# let's not actually do anything

__END__
__SLang__

typedef struct { foo, bar } FooBarStruct_Type;

variable foobar = "a string";
define foo()  { return foobar; }
define bar(x) { foobar = x; }
