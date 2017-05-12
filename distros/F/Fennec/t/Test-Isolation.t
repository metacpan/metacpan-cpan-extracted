#!/usr/bin/perl

use Fennec parallel => 0, test_sort => 'random';
use Cwd qw(abs_path);

my $Original_Cwd;
my %Original_ENV;
before_all name => sub {
    $Original_Cwd = abs_path;
    %Original_ENV = %ENV;
    note "Before All $$ $Original_Cwd";
};

tests "ENV change 1" => sub {
    is_deeply \%Original_ENV, \%ENV;
    $ENV{FOO} = 23;
};

tests "ENV change 2" => sub {
    is_deeply \%Original_ENV, \%ENV;
    $ENV{FOO} = 42;
};

tests "chdir 1" => sub {
    note "$$ $Original_Cwd";
    is $Original_Cwd, abs_path;
    chdir "..";
};

tests "chdir 2" => sub {
    note "$$ $Original_Cwd";
    is $Original_Cwd, abs_path;
    chdir "t";
};

done_testing;
