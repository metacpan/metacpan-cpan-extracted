
use Inline SLang;

my $ref = getfoo();

print "\$ref is a " . ref($ref) . " object\n";
print "And when printed as a string = $ref\n";

printfoo($ref);
changefoo($ref,"no it isn't");
printfoo($ref);

__END__
__SLang__

variable foo = "this is a string";
define getfoo() { return &foo; }
define printfoo(x) { () = printf( "foo = [%s]\n", @x ); }
define changefoo(x,y) { @x = y; }

