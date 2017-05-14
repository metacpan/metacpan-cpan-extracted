use strict;
use warnings;
use Test::More;

my $git;
if (
    -d '.git'
    and
    eval { $git = `git ls-tree --name-status -r HEAD | egrep -v '^\.(git|be)'` }
  )
{
    plan( tests => 1 );
}
else {
    my $msg = 'Need the git repository to compare the MANIFEST.';
    plan( skip_all => $msg );
}

my $manifest = `cat MANIFEST`;

ok( $git eq $manifest, 'MANIFEST up to date' );
