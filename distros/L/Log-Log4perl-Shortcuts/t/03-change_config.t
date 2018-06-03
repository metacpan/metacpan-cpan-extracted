#/usr/bin/env perl
use Test::More;
use Test::Warn;
use Test::Fatal;
use Test::NoWarnings;
use Test::Exception;
use Log::Log4perl::Shortcuts qw(:all);
use File::Temp 'tempdir';
use File::Copy qw(copy);
diag( "Running change log config tests" );






my $tests = 3; # keep on line 17 for ,i (increment and ,d (decrement)
plan tests => $tests;

warnings_like { change_config_file('nanapoopiepantsxzyabc123yup.cfg') } qr/Configuration file unchanged\./, 'Rejects non existent file';

my $config_dir = tempdir() . '/';
my $file = 'yizkjweiasdkjadwkejfakdEWWW78ss.cfg';
my $config_file = $config_dir . $file;
$Log::Log4perl::Shortcuts::home_dir = '';
$Log::Log4perl::Shortcuts::config_dir = $config_dir;

if (!-f $config_file ) {
  copy ('config/default.cfg', $config_file) or die "copy failed: $!";
}

ok ( change_config_file($file) == 'success', 'config file changed');
unlink $config_file;

