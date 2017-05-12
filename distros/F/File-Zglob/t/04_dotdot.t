use strict;
use warnings;
use utf8;
use Test::More;
use File::Zglob qw(zglob);
use Fatal qw(chdir);
use File::Basename qw(dirname basename);

local $File::Zglob::NOCASE = 0; # case sensitive to pass tests.


{
    chdir 't/';
    my @abs = map { basename($_) } zglob("../lib/**/*.pm");
    is_deeply \@abs, [qw(Zglob.pm)];
    chdir '..';
}

{
    my @abs = map { basename($_) } zglob("lib/../lib/**/*.pm");
    is_deeply \@abs, [qw(Zglob.pm)];
}

done_testing;

