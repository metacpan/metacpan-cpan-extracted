use Test::More tests => 1;
# test for RT#94713

my $INC = join ' ', map { "-I$_" } @INC;

SKIP: {
    skip "test fails on windows", 1 if $^O eq 'MSWin32';
    is(`MALLOC_OPTIONS=Z $^X $INC -MHTML::Strip -e 'print HTML::Strip->new->parse(q[<li>abc < 0.5 km</li><li>xyz</li>])'`, q[abc xyz]);
}

