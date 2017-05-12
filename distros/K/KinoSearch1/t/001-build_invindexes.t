#!/usr/bin/perl 
use strict;
use warnings;

use lib 'buildlib';
use Test::More tests => 4;
use File::Spec::Functions qw( catfile );
use KinoSearch1::Test::TestUtils qw(
    working_dir
    create_working_dir
    remove_working_dir
    create_persistent_test_index
    persistent_test_index_loc
);

remove_working_dir();
ok( !-e working_dir(), "Working dir doesn't exist" );
create_working_dir();
ok( -e working_dir(), "Working dir successfully created" );

create_persistent_test_index();

my $path = persistent_test_index_loc();
ok( -d $path, "created invindex directory" );
opendir( my $test_invindex_dh, $path )
    or die "Couldn't opendir '$path': $!";
my @cfs_files = grep {m/\.cfs$/} readdir $test_invindex_dh;
closedir $test_invindex_dh or die "Couldn't closedir '$path': $!";
cmp_ok( scalar @cfs_files, '>', 0, "at least one .cfs file exists" );
