use Test::More;
use strict; use warnings FATAL => 'all';

use IRC::Toolkit::TS6;

my $id = ts6_id;
isa_ok( $id, 'IRC::Toolkit::TS6' );

cmp_ok( length $id, '==', 6, 'six character ID' );
cmp_ok( $id, 'eq', $id->as_string, 'stringification' );
my $cur = $id->as_string;
my $nxt = $id->next;
cmp_ok( length $nxt, '==', 6, 'next returned six character ID' );
cmp_ok( $cur, 'ne', $nxt, 'next returned fresh ID' );

my @ids = map {; $id->() } 1 .. 50_000;
cmp_ok( @ids, '==', 50_000, 'CODE overload appears to work' );
my %seen;
@ids = grep {; !$seen{$_}++ } @ids;
cmp_ok( @ids, '==', 50_000, 'created 50k unique IDs' );
my @bad = grep {; length $_ != 6 } @ids;
ok !@bad, 'unique IDs all appear to have correct length';

my $dies = ts6_id( 'Z99999' );
eval {; $dies->next };
like $@, qr/Ran out of IDs/, 'dies when IDs run dry';

done_testing;
