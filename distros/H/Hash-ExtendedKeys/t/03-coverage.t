use Test::More;
use Hash::ExtendedKeys;

my $ha = Hash::ExtendedKeys->new;

my $ref = [qw/one two/];
$ha->{$ref} = 'three';
is($ha->{$ref}, 'three');
$ha->{$ref} = 'four';
is($ha->{$ref}, 'four');
is($ha->{[qw/not exists/]}, undef);
is(exists $ha->{$ref}, 1);
is(exists $ha->{[qw/not exists/]}, '');
ok(delete $ha->{$ref});
ok(! delete $ha->{[qw/not exists/]});
is(scalar %{$ha}, 0);
ok(1);
done_testing;
