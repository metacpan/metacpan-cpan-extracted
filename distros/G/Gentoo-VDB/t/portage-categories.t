use strict;
use warnings;

BEGIN {
    local @INC = @INC;
    unshift @INC, 't/lib';
    require KENTNL::IsVDB;
    KENTNL::IsVDB::check_isvdb('/var/db/pkg');
}

use Test::More;

use Gentoo::VDB;
my $vdb = Gentoo::VDB->new();

for my $cat ( $vdb->categories ) {
  my $ok = like( $cat, qr{\A[^/]+\z}, "Category $cat has no slashes" );
  # Note, this will probably fail somewhere, and if it does, its likely this test that needs
  # to be changed. However, category naming rules dont' appear anywhere I can find.
  undef $ok unless like( $cat, qr{\A[a-z0-9-]+\z}, "Category $cat matches restricted set");
  diag "Failed category $cat" unless $ok;
}

done_testing;
