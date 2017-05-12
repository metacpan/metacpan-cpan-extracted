#!perl

use strict;
use warnings;

use Test::More;

use Cwd ();
use File::Basename ();
use File::Spec ();

BEGIN {
    $ENV{PLACK_ENV} = "development"; # fake plackup env
}

use File::ConfigDir 'config_dirs';
use File::ConfigDir::Plack qw/plack_app_dir plack_env_dir/;

my $plack_app_dir = Cwd::abs_path(File::Spec->catdir(File::Basename::dirname($0), File::Spec->updir));
my $plack_env_devel = File::Spec->catdir($plack_app_dir, "environments", "development");
my $plack_env_int = File::Spec->catdir($plack_app_dir, "environments", "integration");
my $plack_env_cons = File::Spec->catdir($plack_app_dir, "environments", "consolidation");
my $plack_env_prod = File::Spec->catdir($plack_app_dir, "environments", "production");

my @supported_functions = (
                            qw(config_dirs plack_app_dir plack_env_dir),
                          );

my @dirs = config_dirs();
note( "config_dirs: " . join( ",", @dirs ) );
ok( scalar @dirs >= 3, "config_dirs" );    # we expect system_cfg_dir + .. + ../environments/development
is( $dirs[-1], (plack_env_dir)[0], 'plack_env_dir (devel)');
is( $dirs[-2], (plack_app_dir)[0], 'plack_app_dir (devel)');

is( (plack_app_dir)[0], $plack_app_dir, "direct plack_app_dir");
is( (plack_env_dir)[0], $plack_env_devel, "direct plack_env_dir");

@dirs = config_dirs(qw(extra));
note( "config_dirs: " . join( ",", @dirs ) );
ok( scalar @dirs >= 1, "config_dirs" );    # we expect at least ..
is( $dirs[-1], (plack_app_dir)[0], 'plack_app_dir but extra');

$ENV{PLACK_ENV} = "integration";
my @nointd = config_dirs();
note( "config_dirs: " . join( ",", @nointd ) );
is( (plack_env_dir)[0], $plack_env_int, "direct plack_env_dir (int)");
is( $nointd[-1], (plack_app_dir)[0], 'plack_app_dir (int)');

$ENV{PLACK_ENV} = "consolidation";
my @nocond = config_dirs();
is( (plack_env_dir)[0], $plack_env_cons, "direct plack_env_dir (cons)");
is( $nocond[-1], (plack_app_dir)[0], 'plack_app_dir (cons)');

is_deeply(\@nocond, \@nointd, "no integration, neither consolidation");

$ENV{PLACK_ENV} = "production";
my @butpro = config_dirs();
is( (plack_env_dir)[0], $plack_env_prod, "direct plack_env_dir (prod)");
is( $butpro[-1], (plack_env_dir)[0], 'plack_env_dir (prod)');
is( $butpro[-2], (plack_app_dir)[0], 'plack_app_dir (prod)');

done_testing();
