use strict;
use warnings;
use Test::More;

use Git::Version;

# non-git version
my @fail = ( 'this is a test', '1.0203', '1.2_3' );

plan tests => 2 * @fail;

for my $v (@fail) {
    ok( !eval { Git::Version->new($v) }, "$v is not a valid git version" );
    like(
        $@,
        qr/^$v does not look like a Git version /,
        '... expected error message'
    );
}
