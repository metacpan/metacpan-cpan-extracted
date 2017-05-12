# t/05_pseudohome.t
use strict;
use warnings;

use Test::More 
# tests =>  9;
qw(no_plan);

use_ok('File::Save::Home', qw|
    get_subhome_directory_status
    make_subhome_temp_directory 
| );
use_ok('File::Temp', qw| tempdir |);
use_ok('Cwd');
use_ok('String::PerlIdentifier');

my ($cwd, $pseudohome, $desired_dir_ref );
$cwd = cwd();

ok($pseudohome = tempdir( CLEANUP => 1 ), 
    'pseudo-home directory has been created');

ok(chdir $pseudohome, "able to change to $pseudohome");

$desired_dir_ref = get_subhome_directory_status(
    make_varname(),
    $pseudohome,
);
ok(! defined $desired_dir_ref->{flag}, 
    "random directory name $desired_dir_ref->{abs} is undefined");

ok(chdir $cwd, "able to change to $cwd");

eval {
    $desired_dir_ref = get_subhome_directory_status(
        make_varname(),
        make_varname(),
    );
};
like($@, qr/is\snot\sa\svalid\sdirectory/,
    "optional second argument must be a valid directory");

my ($newpseudohome, $tmpdir);
ok($newpseudohome = tempdir( CLEANUP => 1 ), 
    'another pseudo-home directory has been created');

ok(chdir $newpseudohome, "able to change to $newpseudohome");

$tmpdir = make_subhome_temp_directory($newpseudohome);
ok(  (-d $tmpdir), "$tmpdir exists");

ok(chdir $cwd, "able to change to $cwd");

eval {
    $tmpdir = make_subhome_temp_directory(make_varname());
};
like($@, qr/is\snot\sa\svalid\sdirectory/,
    "optional argument must be a valid directory");
