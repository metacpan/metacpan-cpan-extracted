use strictures 2;
use autodie;
use File::Temp qw/tempdir/;
use Test::Most;
use Cwd;


my $dir = tempdir( CLEANUP => 1 );
my $olddir = getcwd();
chdir($dir);

system(qw/dzil new -P FB11 -p FB11X My::FB11X::Component/);

havedir('My-FB11X-Component');
chdir('My-FB11X-Component');
havedir('lib/My/FB11X/Component');
havepath('lib/My/FB11X/Component.pm');
havedir('t/lib');
havepath('t/lib/TestApp.pm');
havedir('t/lib/TestApp');
havepath('t/lib/TestApp/Builder.pm');

#ok(system("prove", "-l", 't') == 0);

chdir($olddir);

done_testing();

sub havedir { my $path = shift; ok((-d $path), "directory: $path") }
sub havepath { my $path = shift; ok((-e $path), "should exist: $path") }


