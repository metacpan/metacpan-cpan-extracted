package TestMethods::Base;

use strict;
use warnings;

use Test::Class::Moose;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use IPC::Cmd qw[can_run];
use File::Temp;
use File::Spec;

sub make_test_dir{

    my $tmpdir = File::Spec->tmpdir();
    my $tmp = File::Temp->newdir(UNLINK =>0, CLEANUP => 0, TEMPLATE => $tmpdir.'/hpcrunnerXXXXXXX');
    my $test_dir = $tmp->dirname;

    remove_tree($test_dir);
    make_path($test_dir);
    make_path("$test_dir/script");

    chdir($test_dir);

    if(can_run('git') && !-d $test_dir."/.git"){
        system('git init');
    }

    return $test_dir;
}

# Tests were failing if they were running asyncronously.
# We will just use File::Spec to clean up tmpdir
sub test_shutdown {

    chdir("$Bin");
    
}

sub print_diff {
    my $got    = shift;
    my $expect = shift;

    use Text::Diff;

    my $diff = diff \$got, \$expect;
    diag("Diff is\n\n$diff\n\n");

    my $fh;
    open( $fh, ">got.diff" ) or die print "Couldn't open $!\n";
    print $fh $got;
    close($fh);

    open( $fh, ">expect.diff" ) or die print "Couldn't open $!\n";
    print $fh $expect;
    close($fh);

    open( $fh, ">diff.diff" ) or die print "Couldn't open $!\n";
    print $fh $diff;
    close($fh);

    ok(1);
}

1;
