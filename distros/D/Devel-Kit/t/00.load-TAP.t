use Test::More;

my @exported = qw(a d ei rx ri ni ci si yd jd xd sd md id pd fd dd ld ud gd bd vd ms ss s2 s3 s5 be bu ce cu xe xu ue uu he hu pe pu se su qe qu);
plan tests => ( scalar(@exported) * 1 ) + 2;

# do these no()'s to ensure they are off before testing Devel::Kit::TAP’s behavior regarding them
no strict;      ## no critic
no warnings;    ## no critic
use Devel::Kit::TAP;

diag("Testing Devel::Kit::TAP $Devel::Kit::TAP::VERSION");

eval 'print $x;';
like( $@, qr/Global symbol "\$x" requires explicit package name/, 'strict enabled' );

{
    my $warn = '';
    local $SIG{__WARN__} = sub {
        $warn = join( '', @_ );
    };
    eval 'my $n;my $s="$n foo";';
    like( $warn, qr/Use of uninitialized value \$n in concatenation/i, 'warnings enabled' );
}

for my $f (@exported) {
    ok( defined &{$f}, "$f imported" );
}
