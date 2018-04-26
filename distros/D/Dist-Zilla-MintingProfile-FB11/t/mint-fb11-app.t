use strictures 2;
use autodie;
use File::Temp qw/tempdir/;
use Test::Most;
use Cwd;


my $dir = tempdir( CLEANUP => 1 );
my $olddir = getcwd();
chdir($dir);

system(qw/dzil new -P FB11 My::App/);

havedir('My-App');
chdir('My-App');
havedir('lib/My/App');
havepath('lib/My/App.pm');
havepath('lib/My/App/Builder.pm');
havepath('.gitignore');

#ok(system("prove", "-l", 't') == 0);

chdir($olddir);

done_testing();

sub havedir { my $path = shift; ok((-d $path), "directory: $path") }
sub havepath { my $path = shift; ok((-e $path), "should exist: $path") }


