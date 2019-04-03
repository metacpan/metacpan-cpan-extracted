#!perl
use 5.006;
use lib::relative '.';
use MY::Kit;
use Test::Fatal;
use Data::Dumper;

my $obj = Data::Dumper->new([]);    # A blessed reference
isa_ok($obj, 'Data::Dumper', 'A random blessed reference');

# Skipper - invalid parameters
my $S = "$DUT\::Skipper";
ok(exception { $S->new('hello') }, q(Skipper rejects strings that don't look like numbers));
ok(exception { $S->new([]) }, 'Skipper rejects arrayrefs');
ok(exception { $S->new($obj) }, 'Skipper rejects blessed references');
ok(exception { $S->new(1, 2) }, 'Skipper rejects multiple parameters');
ok(exception { $S->new() }, 'Skipper rejects missing parameters');

# Now test the same things, but in the context of a load() call
ok(exception { $DUT->new->load(LSKIP 'hello') }, 'load rejects strings');
ok(exception { $DUT->new->load(LSKIP []) }, 'load rejects arrayrefs');
ok(exception { $DUT->new->load(LSKIP $obj) }, 'load rejects blessed reference');
ok(exception { $DUT->new->load(&LSKIP(1, 2)) }, 'Skipper rejects multiple parameters');
ok(exception { $DUT->new->load(&LSKIP()) }, 'Skipper rejects missing parameters');

done_testing;
