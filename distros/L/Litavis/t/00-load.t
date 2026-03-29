use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('Litavis') }

my $litavis = Litavis->new;
isa_ok($litavis, 'Litavis');

can_ok($litavis, qw(parse parse_file compile compile_file reset pretty dedupe));

ok(defined Litavis->include_dir, 'include_dir returns a value');
