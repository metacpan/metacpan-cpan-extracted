use strict;
use warnings;
use Test::More;

use Git::Version;

# the core tests are in Git-Version-Compare
my @cmp = (
    [ 'git version 1.6.5',      'le', 'v2.7.0' ],
    [ 'v1.5.3.7-1198-g467f42c', 'gt', 'v1.5.3.7-976-gcd39076' ],
    [ '1.7.0.2.msysgit.0',      'gt', '1.6.6' ],
    [ '1.0.0a',                 'lt', '1.0.3' ],
    [ '1.7.1.rc1',              'gt', 'v1.7.1-rc0' ],
    [ '1.3.2',                  'gt', '0.99' ],
    [ '1.0.0a',                 'le', '1.0.1' ],
    [ '1.3.GIT',                'gt', '1.3.0' ],
);

# operator reversal: $a op $b <=> $b rop $a
my %reverse = (
    eq => 'eq',
    ne => 'ne',
    ge => 'le',
    gt => 'lt',
    le => 'ge',
    lt => 'gt',
);

my $git = `git --version`;
chomp $git;
unshift @cmp, [ $git, 'eq', ( $git =~ /git version (.*)/ )[0] ] if $git;

plan tests => 3 * @cmp;
diag $git || 'git not found';

for my $t (@cmp) {
    my ( $v1, $cmp, $v2 ) = @$t;
    $v1 = Git::Version->new($v1);
    isa_ok( $v1, 'Git::Version' );
    cmp_ok( $v1, $cmp,           $v2, "$v1 $cmp $v2" );
    cmp_ok( $v2, $reverse{$cmp}, $v1, "$v2 $reverse{$cmp} $v1" );
}

