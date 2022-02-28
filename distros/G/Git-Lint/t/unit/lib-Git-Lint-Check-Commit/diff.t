use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";

use Git::Lint::Test;

my $class = 'Git::Lint::Check::Commit';
use_ok( $class );

my $expected = "fake return\n";

Git::Lint::Test::override(
    package => 'Git::Lint::Check::Commit',
    name    => '_against',
    subref  => sub { return 'HEAD' },
);

Git::Lint::Test::override(
    package => 'Git::Lint::Check::Commit',
    name    => '_diff_index',
    subref  => sub { return [ $expected ] },
);

my $plugin = $class->new();
my $return = $plugin->diff();

ok( ref $return eq 'ARRAY', 'return is an ARRAYREF' );
is( $return->[0], $expected, 'return matches expected' );

done_testing;
