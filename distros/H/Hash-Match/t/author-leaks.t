use v5.14;

use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };

use Test::More HAS_LEAKTRACE ? (tests => 17) : (skip_all => 'require Test::LeakTrace');

unless ( $ENV{AUTHOR_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

use Test::LeakTrace;

use Hash::Match;

no_leaks_ok {
    my $m = Hash::Match->new( rules => { k => '1' } );

    $m->( {} );
    $m->( { k => 1 } );
    $m->( { k => 2 } );
    $m->( { j => 1 } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => { -not => { k => '1' } } );

    $m->( { k => 1 } );
    $m->( { k => 2 } );
    $m->( { j => 1 } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => { -not => { k => '1', j => 1 } } );

    $m->( { k => 1 } );
    $m->( { k => 2 } );
    $m->( { j => 1 } );
    $m->( { j => 2 } );
    $m->( { k => 1, j => 1 } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => { -not => [ k => '1', j => 1 ] } );

    $m->( { k => 1 } );
    $m->( { k => 2 } );
    $m->( { j => 1 } );
    $m->( { j => 2 } );
    $m->( { k => 1, j => 1 } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => { k => '1', j => qr/\d/, } );

    $m->( { k => 1 } );
    $m->( { k => 2 } );
    $m->( { j => 1 } );
    $m->( { k => 1, j => 3 } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => [ k => '1', j => qr/\d/, ] );

    $m->( { k => 1 } );
    $m->( { k => 2 } );
    $m->( { j => 1 } );
    $m->( { k => 1, j => 3 } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => { -or => { k => '1', j => qr/\d/, } } );

    $m->( { k => 1 } );
    $m->( { k => 2 } );
    $m->( { j => 1 } );
    $m->( { k => 1, j => 3 } );
} 'no memory leaks';


no_leaks_ok {
    my $m = Hash::Match->new( rules => {
        k => '1', -or => [ j => qr/\d/, i => qr/x/, ], } );

    $m->( { k => 1 } );
    $m->( { k => 2 } );
    $m->( { j => 1 } );
    $m->( { k => 1, j => 3 } );
    $m->( { k => 1, i => 'wxyz' } );
    $m->( { k => 1, i => 'abc' } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => [
                                  k => '1', -and => { j => qr/\d/, } ] );

    $m->( { k => 1 } );
    $m->( { k => 2 } );
    $m->( { j => 1 } );
    $m->( { k => 1, j => 3 } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => [
                                  k => '1', -and => [ j => qr/\d/, ] ] );

    $m->( { k => 1 } );
    $m->( { k => 2 } );
    $m->( { j => 1 } );
    $m->( { k => 1, j => 3 } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => [
                                  k => '1', -and => { j => qr/\d/, i => qr/x/ } ] );

    $m->( { k => 1 } );
    $m->( { k => 2 } );
    $m->( { j => 1 } );
    $m->( { k => 1, j => 3 } );
    $m->( { k => 2, i => 'xyz' } );
    $m->( { k => 2, j => 6, i => 'xyz' } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => { k => sub {1} } );

    $m->( { k => 1 } );
    $m->( { k => 2 } );
    $m->( { j => 1 } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => { k => sub { $_[0] <= 2 } } );

    $m->( { k => 1 } );
    $m->( { k => 2 } );
    $m->( { k => 3 } );
    $m->( { j => 1 } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => { k => '1', j => undef } );

    $m->( { k => 1, j => undef } );
    $m->( { k => 1 } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => [ qr/^k/ => 1, ] );

    $m->( { k_a => 1, k_b => 2 } );
    $m->( { k_a => 3, k_b => 2 } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => { -or => [ qr/^k/ => 1, ] } );

    $m->( { k_a => 1, k_b => 2 } );
    $m->( { k_a => 3, k_b => 2 } );
} 'no memory leaks';

no_leaks_ok {
    my $m = Hash::Match->new( rules => { -and => [ qr/^k/ => 1, ] } );

    $m->( { k_a => 1, k_b => 1 } );
    $m->( { k_a => 1, k_b => 2 } );
    $m->( { k_a => 3, k_b => 2 } );
} 'no memory leaks';


done_testing;
