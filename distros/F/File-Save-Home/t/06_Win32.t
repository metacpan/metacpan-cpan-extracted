# t/06_Win32.t
use strict;
use warnings;
use Test::More;
if( $^O !~ /Win32/ ) {
    plan skip_all => 'Test irrelevant except on Win32';
} else {
    plan qw(no_plan);
}

like($^O, qr/Win32/, "You're on Windows -- the greatest operating system to come out of Redmond, Washington!");

SKIP: {
    eval { require File::HomeDir };
    skip "File::HomeDir not found", 
        14 if $@;
    use_ok('File::Save::Home', qw|
        get_subhome_directory_status
        make_subhome_temp_directory 
    | );
    use_ok('File::Temp', qw| tempdir |);
    use_ok('Cwd');
    use_ok('String::PerlIdentifier');
    
    my ($cwd, $pseudohome, $desired_dir_ref );
    $cwd = cwd();
    
    ok($pseudohome = File::HomeDir->my_home(), 
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
    ok($newpseudohome = File::HomeDir->my_home(), 
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
}

