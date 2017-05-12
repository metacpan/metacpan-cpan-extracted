use strict;
use warnings;

use Test::More;
use Dist::Zilla::App::Tester;
use Path::Tiny qw( path );
use Test::TempDir::Tiny qw( tempdir );
use Dist::Zilla::Plugin::GatherDir;
use Test::DZil qw( simple_ini );

my $ini = simple_ini( ['GatherDir'] );
my $critic_rc = <<'EOF';

EOF
my $example_pm = <<'EOF';
use strict;
use warnings;

package Example;

1;
EOF

my $wd = tempdir('Scratch');

path( $wd, 'dist.ini' )->spew_raw($ini);
path( $wd, 'perlcritic.rc' )->spew_raw($critic_rc);
path( $wd, 'lib' )->mkpath;
path( $wd, 'lib/Example.pm' )->spew_raw($example_pm);

my $result = test_dzil( $wd, ['critic'] );
ok( ref $result, 'self-test executed' );
is( $result->error,     undef, 'no errors' );
is( $result->exit_code, 0,     'exit == 0' );
note( $result->stdout );

done_testing;

