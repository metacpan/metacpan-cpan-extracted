use strict;
use warnings;
use Test::More tests => 3;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JQ::Lite;

my $jq = JQ::Lite->new;

my $json = '{"k":1, "a b":2}';

my @plain = $jq->run_query($json, '.k');

is_deeply(\@plain, [1], 'Unquoted field access works');

my @quoted = $jq->run_query($json, '."k"');

is_deeply(\@quoted, [1], 'Quoted field access matches unquoted');

my @spaced = $jq->run_query($json, '."a b"');

is_deeply(\@spaced, [2], 'Quoted field access supports spaces');
