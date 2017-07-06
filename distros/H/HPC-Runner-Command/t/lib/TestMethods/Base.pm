package TestMethods::Base;

use strict;
use warnings;

use Test::Class::Moose;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use IPC::Cmd qw[can_run];
use File::Temp;
use File::Spec;
use File::Slurp;
use Cwd;

sub make_test_dir {

    my $tmpdir = File::Spec->tmpdir();
    my $tmp    = File::Temp->newdir(
        UNLINK   => 0,
        CLEANUP  => 0,
        TEMPLATE => File::Spec->catdir( $tmpdir, 'hpcrunnerXXXXXXX' )
    );
    my $test_dir = $tmp->dirname;

    remove_tree($test_dir);
    make_path($test_dir);
    make_path( File::Spec->catdir( $test_dir, 'script' ) );

    chdir($test_dir);

    if ( can_run('git') && !-d File::Spec->catdir( $test_dir, '.git' ) ) {
        system('git init');
    }

    # return $test_dir;
    return cwd();
}

# Tests were failing if they were running asyncronously.
sub test_shutdown {

    chdir("$Bin");

}

sub print_diff {
    my $got    = shift;
    my $expect = shift;

    use Text::Diff;

    my $diff = diff \$got, \$expect;
    diag("Diff is\n\n$diff\n\n");

    write_file( 'got.diff',    $got )    or die print "Couldn't write $!\n";
    write_file( 'expect.diff', $expect ) or die print "Couldn't write $!\n";
    write_file( 'diff.diff',   $diff )   or die print "Could't write $!\n";

    ok(1);
}

1;
