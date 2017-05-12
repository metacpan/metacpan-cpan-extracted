use Test::More tests => 8;

use Mac::PropertyList::XS;

my $string = do { local $/; open my($fh), 'plists/test1.plist'; <$fh> };
my $parsed = Mac::PropertyList::XS::parse_plist_string($string);
# These first two aren't overload checks, but they ensure that overloads are
# being called on objects (rather than just checking scalars against other
# scalars)
# TODO XS
isa_ok($parsed->{a},"Mac::PropertyList::SAX::string","string type check");
isa_ok($parsed->{a},"Mac::PropertyList::string","ancestor string type check");
is("$parsed->{a}","b","string object stringification overload");
is("$parsed->{c}->[-1]","5","integer object stringification overload");
is("$parsed->{f}->{i}","true","boolean true stringification overload");
is(!!$parsed->{f}->{i},1,"boolean true boolification overload");
is("$parsed->{f}->{j}","false","boolean false stringification overload");
is(!!$parsed->{f}->{j},"","boolean false boolification overload");


