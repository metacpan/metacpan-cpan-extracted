package File::Stat::MooseFunctionTest;

use strict;
use warnings;

use Test::Unit::Lite;
use parent 'Test::Unit::TestCase';

use Test::Assert ':all';

use File::Stat::Moose ':all';

use Exception::Base;

use File::Spec;
use File::Temp;

{
    package File::Stat::MooseFunctionTest::Test1;

    use File::Stat::Moose 'lstat';
};

{
    package File::Stat::MooseFunctionTest::Test2;

    use File::Stat::Moose;
};

our ($file, $symlink, $notexistant);

sub set_up {
    $file = __FILE__;
    $symlink = File::Temp::tmpnam();
    $notexistant = '/MooseTestNotExistant';

    eval {
        symlink File::Spec->rel2abs($file), $symlink;
    };
    $symlink = undef if $@;
};

sub tear_down {
    unlink $symlink if $symlink;
};

sub test_import {
    assert_not_null(prototype 'File::Stat::MooseFunctionTest::stat');
    assert_not_null(prototype 'File::Stat::MooseFunctionTest::lstat');

    assert_null(prototype 'File::Stat::MooseFunctionTest::Test1::stat');
    assert_not_null(prototype 'File::Stat::MooseFunctionTest::Test1::lstat');

    assert_null(prototype 'File::Stat::MooseFunctionTest::Test2::stat');
    assert_null(prototype 'File::Stat::MooseFunctionTest::Test2::lstat');
};

sub test_stat {
    my $scalar = stat($file);
    assert_isa('File::Stat::Moose', $scalar);
    assert_not_equals(0, $scalar->size);

    my @array1 = stat($file);
    assert_not_null(@array1);
    assert_equals(13, scalar @array1);

    my @array2 = stat(\*_);
    assert_not_null(@array2);
    assert_equals(13, scalar @array2);
    assert_deep_equals(\@array1, \@array2);

    local $_ = $file;
    my @array3 = stat();
    assert_not_null(@array3);
    assert_equals(13, scalar @array3);
    assert_deep_equals(\@array1, \@array3);

    assert_raises( ['Exception::IO'], sub {
        stat($notexistant);
    } );
};

sub test_lstat {
    my $scalar = lstat($file);
    assert_isa('File::Stat::Moose', $scalar);

    my @array1 = lstat($file);
    assert_not_null(@array1);
    assert_equals(13, scalar @array1);

    my @array2 = lstat(\*_);
    assert_not_null(@array2);
    assert_equals(13, scalar @array2);
    assert_deep_equals(\@array1, \@array2);

    local $_ = $file;
    my @array3 = lstat();
    assert_not_null(@array3);
    assert_equals(13, scalar @array3);
    assert_deep_equals(\@array1, \@array3);

    assert_raises( ['Exception::IO'], sub {
        lstat($notexistant);
    } );
};

sub test_lstat_symlink {
    return unless $symlink;

    my $scalar = lstat($symlink);
    assert_isa('File::Stat::Moose', $scalar);

    my @array1 = lstat($symlink);
    assert_not_null(@array1);
    assert_equals(13, scalar @array1);

    my @array2 = lstat(\*_);
    assert_not_null(@array2);
    assert_equals(13, scalar @array2);
    assert_deep_equals(\@array1, \@array2);

    local $_ = $symlink;
    my @array3 = lstat();
    assert_not_null(@array3);
    assert_equals(13, scalar @array3);
    assert_deep_equals(\@array1, \@array3);

    my @array4 = stat($symlink);
    assert_not_null(@array4);
    assert_equals(13, scalar @array4);
    assert_not_equals($array1[1], $array4[1]);
};

1;
