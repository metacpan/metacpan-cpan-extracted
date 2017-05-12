#!/usr/bin/perl

use strict;
use warnings;

use Dir::Split;
use File::Find;
use File::Path;
use File::Spec;
use File::Temp qw(tempdir);
use Test::More tests => 2;

my ($source_dir, $target_dir);

num_mode_tests();
char_mode_tests();

sub num_mode_tests
{
    $source_dir = tempdir();
    $target_dir = tempdir();

    my %num_opts = (
        mode       => 'num',
        source     => $source_dir,
        target     => $target_dir,
        verbose    => 0,
        override   => 0,
        identifier => 'sub',
        file_limit => 2,
        file_sort  => '+',
        separator  => '-',
        continue   => 0,
        length     => 5,
    );

    my @num_files = (
        [ qw(sub-00001)         ],
        [ qw(sub-00001 .hidden) ],
        [ qw(sub-00001 abc)     ],
        [ qw(sub-00002)         ],
        [ qw(sub-00002 def)     ],
        [ qw(sub-00002 ghi)     ],
        [ qw(sub-00003)         ],
        [ qw(sub-00003 jkl)     ],
        [ qw(sub-00003 mno)     ],
        [ qw(sub-00004)         ],
        [ qw(sub-00004 pqr)     ],
    );

    make_directories();
    chdir_srcdir();
    make_files();

    split_dir(%num_opts);
    examine_target(\@num_files, 'numeric');
}

sub char_mode_tests
{
    $source_dir = tempdir();
    $target_dir = tempdir();

    my %char_opts = (
        mode       => 'char',
        source     => $source_dir,
        target     => $target_dir,
        verbose    => 0,
        override   => 0,
        identifier => 'sub',
        separator  => '-',
        case       => 'upper',
        length     => 1,
    );

    my @char_files = (
        [ qw(sub-.)         ],
        [ qw(sub-. .hidden) ],
        [ qw(sub-A)         ],
        [ qw(sub-A abc)     ],
        [ qw(sub-D)         ],
        [ qw(sub-D def)     ],
        [ qw(sub-G)         ],
        [ qw(sub-G ghi)     ],
        [ qw(sub-J)         ],
        [ qw(sub-J jkl)     ],
        [ qw(sub-M)         ],
        [ qw(sub-M mno)     ],
        [ qw(sub-P)         ],
        [ qw(sub-P pqr)     ],
    );

    make_directories();
    chdir_srcdir();
    make_files();

    split_dir(%char_opts);
    examine_target(\@char_files, 'characteristic');
}

sub make_directories
{
    foreach my $dir ($source_dir, $target_dir) {
        eval { mkpath($dir) };
        if ($@) {
            die "Can't create $dir: $@\n";
        }
    }
}

sub chdir_srcdir
{
    chdir($source_dir) or die "Can't chdir to $source_dir: $!\n";
}

sub make_files
{
    my $create_file = sub
    {
        open(my $fh, '>', $_[0]) or die "Can't create $_[0]: $!\n";
        close($fh);
    };
    foreach my $file (qw(.hidden abc def ghi jkl mno pqr)) {
        $create_file->(File::Spec->catfile($source_dir, $file));
    }
}

sub split_dir
{
    my (%opts) = @_;

    my $dir = Dir::Split->new(%opts);
    $dir->split_dir;
}

sub examine_target
{
    my ($files, $mode) = @_;

    my @got;
    my $verify = sub
    {
        return if $_ eq '.';
        push @got, $File::Find::name;
    };
    find({ wanted => $verify }, $target_dir);
    @got = sort @got;

    my @expected;
    foreach (@$files) {
        push @expected, File::Spec->catfile($target_dir, @$_);
    }
    is_deeply(\@got, \@expected, "$mode mode splitting");
}
