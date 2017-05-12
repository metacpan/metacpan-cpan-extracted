
# want to bind the typeof function
#
use Inline SLang;

my $a0 = getfoo(0);
my $a1 = getfoo(1);
my $a2 = getfoo(2);

print "\nIn Perl:\n";
printf "typeof(foo[0]) = %s\n", $a0->typeof;
printf "typeof(foo[1]) = %s\n", $a1->typeof;
printf "typeof(foo[2]) = %s\n",
  defined($a2) ? $a2->typeof : "undef";

__END__
__SLang__

variable foo = Any_Type [3];
foo[0] = "a string";
foo[1] = 23;

define getfoo(x) { return foo[x]; }

message( "In S-Lang:" );
vmessage( "typeof(foo[0]) = %s", string(typeof(foo[0])) );
vmessage( "typeof(foo[1]) = %s", string(typeof(foo[1])) );
vmessage( "typeof(foo[2]) = %s", string(typeof(foo[2])) );

