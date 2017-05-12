# t/03_placefile.t
use strict;
use warnings;

use File::Spec::Functions qw|
    catdir
|;
use Test::More tests => 15;

use_ok('File::Save::Home', qw|
    get_home_directory
    get_subhome_directory_status
    make_subhome_directory
    restore_subhome_directory_status
    conceal_target_file
    reveal_target_file
| );
use_ok('String::PerlIdentifier');

my ($homedir, @subdirs, $desired_dir_ref, $desired_dir, $target_ref, $target );
ok($homedir = get_home_directory(), 'home directory is defined');

# Test a multilevel directory
my $topdir = make_varname();
my $nextdir = make_varname();

$desired_dir_ref =
    get_subhome_directory_status(catdir($topdir, $nextdir));
ok(! defined $desired_dir_ref->{flag},
    "random directory name $desired_dir_ref->{abs} is undefined");

$desired_dir = make_subhome_directory($desired_dir_ref);
ok(-d $desired_dir,
    "randomly named directory $desired_dir_ref->{abs} has been created");

$target = 'file_to_be_checked';
my $ftarget = catdir($desired_dir, $target);
open my $FH, '>', $ftarget
    or die "Unable to open filehandle: $!";
print $FH "\n";
close $FH or die "Unable to close filehandle: $!";

ok(-f $ftarget, "target file created for testing");

$target_ref = conceal_target_file( {
    dir     => $desired_dir,
    file    => $target,
    test    => 1,
} );

reveal_target_file($target_ref);

ok(-f "$desired_dir/$target", "target file restored after testing");

ok(restore_subhome_directory_status($desired_dir_ref),
    "directory status restored");

ok(! -d $desired_dir,
    "randomly named directory $desired_dir_ref->{abs} has been deleted");
ok(! -d $topdir,
    "top directory $topdir has been deleted");




