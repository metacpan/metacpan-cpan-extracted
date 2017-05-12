#!perl -w

use strict;
use Test::More;

use File::Spec;
BEGIN{
    package FS; # The original class
    our @ISA = @File::Spec::ISA;
}

use File::Spec::Memoized;
use FindBin qw($Bin);

# constants
foreach my $c(qw(curdir updir rootdir devnull)){
    is(File::Spec->$c(), FS->$c(), $c);
    is(File::Spec->$c(), FS->$c(), $c);
}
is(
    File::Spec->rel2abs( FS->curdir ),
    FS->rel2abs( FS->curdir ),
    'rel2abs',
);
is(
    File::Spec->rel2abs( FS->curdir ),
    FS->rel2abs( FS->curdir ),
    'rel2abs',
);

my @args = ($Bin, 'test', 'dir', 'foo.txt');

is(
    File::Spec->catfile(@args),
    FS->catfile(@args),
    'catfile'
);
is(
    File::Spec->catfile(@args),
    FS->catfile(@args),
    'catfile'
);

splice @args, 1, 0, File::Spec->curdir;
is(
    File::Spec->catfile(@args),
    FS->catfile(@args),
    'catfile'
);
is(
    File::Spec->catfile(@args),
    FS->catfile(@args),
    'catfile'
);

is(
    join(' ', File::Spec->path),
    join(' ', FS->path),
    'path'
);
is(
    join(' ', File::Spec->path),
    join(' ', FS->path),
    'path'
);

ok open(my $in, '<', File::Spec->catfile(@args)), 'open';
is scalar(<$in>), 'foo';

done_testing;
