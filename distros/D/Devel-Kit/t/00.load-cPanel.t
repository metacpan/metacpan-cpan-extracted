use Test::More;
BEGIN { eval "require Cpanel::Logger;"; plan skip_all => "tests irrelevant on non-cPanel environment" if $@; }

my @exported = qw(a d ei rx ri ni ci si yd jd xd sd md id pd fd dd ld ud gd bd vd ms ss be bu ce cu xe xu ue uu he hu pe pu se su qe qu);
plan tests => ( scalar(@exported) * 1 ) + 2;

# do these no()'s to ensure they are off before testing Devel::Kit::cPanel’s behavior regarding them
no strict;      ## no critic
no warnings;    ## no critic
use Devel::Kit::cPanel;

diag("Testing Devel::Kit::cPanel $Devel::Kit::cPanel::VERSION");

eval 'print $x;';
like( $@, qr/Global symbol "\$x" requires explicit package name/, 'strict enabled' );

{
    my $warn = '';
    local $SIG{__WARN__} = sub {
        $warn = join( '', @_ );
    };
    eval 'print @X[0]';
    like( $warn, qr/Scalar value \@x\[0\] better written as \$x\[0\]/i, 'warnings enabled' );
}

for my $f (@exported) {
    ok( defined &{$f}, "$f imported" );
}
