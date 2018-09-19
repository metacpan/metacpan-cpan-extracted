#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use File::Util::Tempdir qw(get_tempdir get_user_tempdir);

subtest get_tempdir => sub {
    my $dir;
    lives_ok { $dir = get_tempdir() };
    diag "result of get_tempdir(): ", $dir;
};

subtest get_user_tempdir => sub {
    my $dir;
    lives_ok { $dir = get_user_tempdir() };
    diag "result of get_user_tempdir(): ", $dir;
};

done_testing;
