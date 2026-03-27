#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 16;

use_ok('Medusa::XS');

# Disable colour for dump format tests
{ no warnings 'once'; $Medusa::XS::LOG{OPTIONS}{colour} = 0; }

# Test pure C SV serializer (replaces Data::Dumper in the hot path)

# 1. Simple string (Loo uses double quotes with useqq=1)
my $result = Medusa::XS::dump_sv("hello");
like($result, qr/"hello"/, "string serialization");

# 2. Number (integer)
$result = Medusa::XS::dump_sv(42);
like($result, qr/42/, "integer serialization");

# 3. Float
$result = Medusa::XS::dump_sv(3.14);
like($result, qr/3\.14/, "float serialization");

# 4. Undef
$result = Medusa::XS::dump_sv(undef);
is($result, 'undef', "undef serialization");

# 5. Array reference (Loo includes spaces after commas)
$result = Medusa::XS::dump_sv([1, 2, 3]);
like($result, qr/\[1,?\s*2,?\s*3\]/, "arrayref serialization");

# 6. Hash reference (Loo uses unquoted keys with quotekeys=0)
$result = Medusa::XS::dump_sv({a => 1});
like($result, qr/a => 1/, "hashref serialization");

# 7. Nested structure
$result = Medusa::XS::dump_sv({list => [1, "two"]});
like($result, qr/list => \[1,?\s*"two"\]/, "nested structure");

# 8. String with escapes
$result = Medusa::XS::dump_sv("line1\nline2");
like($result, qr/\\n/, "string escape handling");

# 9. Blessed reference
my $obj = bless {id => 1}, 'My::Class';
$result = Medusa::XS::dump_sv($obj);
like($result, qr/bless/, "blessed object serialization");
like($result, qr/My::Class/, "blessed class name");

# 10. Code reference
$result = Medusa::XS::dump_sv(sub { 1 });
like($result, qr/sub/, "coderef serialization");

# 11. Scalar reference
$result = Medusa::XS::dump_sv(\42);
like($result, qr/\\42/, "scalarref serialization");

# 12. Empty array
$result = Medusa::XS::dump_sv([]);
is($result, '[]', "empty arrayref");

# 13. Empty hash
$result = Medusa::XS::dump_sv({});
is($result, '{}', "empty hashref");

# 14. String with quotes (Loo uses double quotes, apostrophe needs no escaping)
$result = Medusa::XS::dump_sv("it's");
like($result, qr/it's/, "escaped quotes in string");

done_testing();
