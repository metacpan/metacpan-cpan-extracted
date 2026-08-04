use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }
sub V { JSON::Schema::Fast->compile($_[0]) }

my $len = V({ type => 'string', minLength => 2, maxLength => 4 });
ok( $len->is_valid(J('"ab"')),    'minLength ok');
ok(!$len->is_valid(J('"a"')),     'below minLength');
ok( $len->is_valid(J('"abcd"')),  'maxLength ok');
ok(!$len->is_valid(J('"abcde"')), 'above maxLength');

# length counts codepoints, not bytes
my $u = V({ minLength => 3, maxLength => 3 });
ok( $u->is_valid(J('"ééé"')), 'three accented chars = 3 codepoints');
ok(!$u->is_valid(J('"éé"')),        'two = 2 codepoints');

my $p = V({ pattern => '^a.*z$' });
ok( $p->is_valid(J('"abcz"')), 'pattern matches');
ok(!$p->is_valid(J('"abc"')),  'pattern no match');

my $sub = V({ pattern => 'b' });   # unanchored: a search, not a full match
ok( $sub->is_valid(J('"abc"')), 'unanchored pattern searches');

done_testing;
