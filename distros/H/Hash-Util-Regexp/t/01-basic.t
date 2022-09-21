#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Hash::Util::Regexp qw(
                             has_key_matching
                             first_key_matching
                             keys_matching

                             has_key_not_matching
                             first_key_not_matching
                             keys_not_matching
                     );

ok( has_key_matching({a=>1, b=>2, c=>3}, qr/[ab]/));
ok(!has_key_matching({a=>1, b=>2, c=>3}, qr/[de]/));

is_deeply(first_key_matching({a=>1, b=>2, c=>3}, qr/[ab]/, 1), 'a');
is_deeply([first_key_matching({a=>1, b=>2, c=>3}, qr/[de]/, 1)], []);

is_deeply([keys_matching({a=>1, b=>2, c=>3}, qr/[ab]/, 1)], ['a', 'b']);
is_deeply([keys_matching({a=>1, b=>2, c=>3}, qr/[de]/, 1)], []);

ok( has_key_not_matching({a=>1, b=>2, c=>3}, qr/[ab]/));
ok(!has_key_not_matching({a=>1, b=>2, c=>3}, qr/[abc]/));

is_deeply(first_key_not_matching({a=>1, b=>2, c=>3}, qr/[ab]/, 1), 'c');
is_deeply([first_key_not_matching({a=>1, b=>2, c=>3}, qr/[abc]/, 1)], []);

is_deeply([keys_not_matching({a=>1, b=>2, c=>3}, qr/[b]/, 1)], ['a', 'c']);
is_deeply([keys_not_matching({a=>1, b=>2, c=>3}, qr/[abc]/, 1)], []);

done_testing;
