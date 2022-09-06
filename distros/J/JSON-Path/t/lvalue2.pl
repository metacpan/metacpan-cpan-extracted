use Test2::V0;

use JSON::Path -all;

my $hash = { "a" => "b" };
my $path = JSON::Path->new('$.l1.l2');
$path->value($hash) = 'l2_value';
print Dumper $hash;
is $hash->{l1}, { l2 => 'l2_value' }, q{lvalue sets deep keys};
done_testing;

