#!/usr/bin/perl
use strict;
use warnings;

use Logging::Simple;
use Test::More;

my $mod = 'Logging::Simple';

{
    my $log = $mod->new;

    my %lvls = $log->levels;

    is ( keys %lvls, 8, "levels() returns correct count with 'names' param" );

    my %levels = (
        0 => 'lvl 0',
        1 => 'lvl 1',
        2 => 'lvl 2',
        3 => 'lvl 3',
        4 => 'lvl 4',
        5 => 'lvl 5',
        6 => 'lvl 6',
        7 => 'lvl 7',
    );

    for (0..7){
        is (
            $lvls{$_},
            $levels{$_},
            "levels() with 'names' param maps $_ to $levels{$_} ok");
    }

    my %tags = $log->levels;

    is (ref \%tags, 'HASH', "levels() returns a hash");

    for (0..7){
        is ($tags{$_}, $levels{$_}, "return from levels() is sane");
    }

    is (keys %tags, 8, "levels() return has proper key count");
}
{ # level invalid warning
    my $warn;
    local $SIG{__WARN__} = sub { $warn = shift; };

    my $log = $mod->new;

    my $lvl = $log->level('xxx');

    like ($warn, qr/invalid level/, "an invalid level spits a warning");
    is ($lvl, 4, "...and the default level is set");
}

done_testing();

