use strict;
use warnings;
use Test::More;

# keyword args to new
use JSON::YY ();

my $coder = JSON::YY->new(utf8 => 1, pretty => 1);
my $json = $coder->encode({a => 1});
like $json, qr/\n/, 'new(pretty => 1) works';

my $coder2 = JSON::YY->new(utf8 => 1, allow_nonref => 1);
is $coder2->encode(42), '42', 'new(allow_nonref => 1) works';
is_deeply $coder2->decode('{"x":1}'), {x => 1}, 'new(utf8 => 1) decode works';

# chaining still works
my $coder3 = JSON::YY->new->utf8->pretty;
like $coder3->encode({b => 2}), qr/\n/, 'chaining still works';

# mix keyword and chaining
my $coder4 = JSON::YY->new(utf8 => 1)->pretty;
like $coder4->encode({c => 3}), qr/\n/, 'keyword + chaining works';

done_testing;
