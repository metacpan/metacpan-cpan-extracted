use Test::More;

my @exported = qw(a d ei rx ri ni ci si yd jd xd sd md id pd fd dd ld ud gd bd vd ms ss be bu ce cu xe xu ue uu he hu pe pu se su qe qu);
plan tests => ( scalar(@exported) * 4 ) + 2;

# do these no()'s to ensure they are off before testing Devel::Kit’s behavior regarding them
no strict;      ## no critic
no warnings;    ## no critic
use Devel::Kit qw(no __);

diag("Testing Devel::Kit $Devel::Kit::VERSION");

eval 'print $x;';
ok( !$@, 'strict not enabled under “no”' );

{
    my $warn = '';
    local $SIG{__WARN__} = sub {
        $warn = join( '', @_ );
    };
    eval 'print @X[0]';
    is( $warn, '', 'warnings not enabled under “no”' );
}

for my $f (@exported) {
    ok( defined &{"__$f"}, "Alternate double __$f imported" );
}

for my $f (@exported) {
    ok( !defined &{"_$f"}, "Alternate single _$f not imported originally" );
}
Devel::Kit->import('_');
for my $f (@exported) {
    ok( defined &{"_$f"}, "Alternate single _$f imported properly" );
}

Devel::Kit->import('___');
for my $f (@exported) {
    ok( defined &{"___$f"}, "Alternate triple ___$f imported" );
}
