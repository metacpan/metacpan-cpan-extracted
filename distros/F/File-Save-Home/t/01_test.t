# t/01_test.t - check module loading
use strict;
use warnings;

use Test::More tests => 13;

use_ok('File::Save::Home', qw|
    get_home_directory
    get_subhome_directory_status
    make_subhome_directory
    restore_subhome_directory_status 
| );
use_ok('String::PerlIdentifier');
use_ok('Cwd');

my ($cwd, $homedir, @subdirs, $desired_dir_ref, $desired_dir );
ok($homedir = get_home_directory(), 'home directory is defined');

$cwd = cwd();

ok(chdir $homedir, "able to change to $homedir");
{
    local *DH;
    ok((opendir DH, $homedir), "able to open directory handle to $homedir");
    @subdirs = grep {-d $_ and !($_ eq '.' or $_ eq '..') } readdir DH;
    ok(closedir DH, "able to close directory handle to $homedir");
}

ok(chdir $cwd, "able to change back to $cwd");

if (@subdirs) {
    my $testdir = $subdirs[int(rand(@subdirs))];
    $desired_dir_ref = get_subhome_directory_status($testdir);
    ok($desired_dir_ref->{flag}, 
        "confirm existence of $testdir under $homedir");
} else {
    $desired_dir_ref = get_subhome_directory_status(make_varname());
    ok(! defined $desired_dir_ref->{flag}, 
        "random directory name under $homedir is undefined");
}

$desired_dir_ref = get_subhome_directory_status(make_varname());
ok(! defined $desired_dir_ref->{flag}, 
    "random directory name $desired_dir_ref->{abs} is undefined");

$desired_dir = make_subhome_directory($desired_dir_ref);
ok(-d $desired_dir,
    "randomly named directory $desired_dir_ref->{abs} has been created");

ok(restore_subhome_directory_status($desired_dir_ref),
    "directory status restored");

ok(! -d $desired_dir, 
    "randomly named directory $desired_dir_ref->{abs} has been deleted");

