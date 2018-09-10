#/usr/bin/env perl
use Test::More;
use Test::Warn;
use Test::Fatal;
use Test::NoWarnings;
use Test::Exception;
use Test::File::ShareDir::Dist { 'Log-Log4perl-Shortcuts' => 'config/' };
use Test::File::ShareDir::Module { 'Log::Log4perl::Shortcuts' => 'config/' };
use Log::Log4perl::Shortcuts qw(:all);
use File::Temp 'tempdir';
use File::Copy qw(copy);
use Path::Tiny;
use File::UserConfig;
diag( "Running change log config tests" );

my $tests = 3; # keep on line 17 for ,i (increment and ,d (decrement)
plan tests => $tests;

my $file = 'yizkjweiasdkjadwkejfakdEWWW78ss.cfg';
warnings_like { set_log_config($file) } qr/Configuration file unchanged/, 'Rejects non existent file';

my $package    = 'Log-Log4perl-Shortcuts';
my $config = File::UserConfig->new(dist => $package);
my $config_dir = $config->configdir;
my $file_abs         = path($config_dir, 'log_config', $file)->canonpath;
my $default       = path($config_dir, 'log_config', 'default.cfg')->canonpath;
copy ($default, $file_abs);

ok ( set_log_config($file) == 'success', 'config file changed');
unlink $file_abs;
