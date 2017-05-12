use Email::Address;
$value = q{first@foo.org,} . q{ } x 26 . q{second@foo.org};
use Data::Dumper;
print Dumper(Email::Address->parse($value));
