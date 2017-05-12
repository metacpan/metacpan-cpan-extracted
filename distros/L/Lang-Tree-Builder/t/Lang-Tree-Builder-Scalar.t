use Test::More tests => 6;
BEGIN { use_ok('Lang::Tree::Builder::Scalar') }
my $scalar = new Lang::Tree::Builder::Scalar();
ok($scalar, 'new');
is($scalar->is_scalar, 1, 'is_scalar');
is($scalar->is_substantial, 0, 'is_substantial');
is($scalar->name, 'scalar', 'name');
is($scalar->lastpart, 'scalar', 'lastpart');
