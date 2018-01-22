#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Encode;

use MVC::Neaf::Upload;

# [pri`vet] means "hello" in Russian
my $privet = join "", map { chr $_ } 0x43f, 0x440, 0x438, 0x432, 0x435, 0x442;
my $binary = encode_utf8( "$privet\n$privet" );
my $garbage = join "", chr 0xff, chr 0xff;

{
    note "utf8=1, normal data";
    open my $fd, "<", \$binary
        or die "Failed to open memory: $!";
    my $up = MVC::Neaf::Upload->new( id => "cyrillic", handle => $fd, utf8=>1 );

    is $up->id, "cyrillic", "Id round-trip";
    is $up->content, "$privet\n$privet", "Content round-trip";
    ok $up->content =~ /[\x{440}]/, "Wide character present";
};

{
    note "utf8=0, normal data";
    open my $fd, "<", \$binary
        or die "Failed to open memory: $!";
    my $up = MVC::Neaf::Upload->new( id => "cyrillic", handle => $fd );

    is $up->id, "cyrillic", "Id round-trip";
    is $up->content, encode_utf8("$privet\n$privet"), "Content round-trip";
    like $up->content, qr/^[\0-\xff]*$/s, "No wide chars";
};

{
    note "utf8=0, broken data";
    open my $fd, "<", \$garbage
        or die "Failed to open memory: $!";
    my $up = MVC::Neaf::Upload->new( id => "barbage", handle => $fd );

    my $ct;
    my $live = eval {
        $ct = $up->content;
        1;
    };

    ok $live, "Garbage fine w/o utf8"
        or diag "Exception: $@";

    is $ct, $garbage, "Data round-trip";
};

{
    note "utf8=1, broken data";
    open my $fd, "<", \$garbage
        or die "Failed to open memory: $!";
    my $up = MVC::Neaf::Upload->new( id => "barbage", handle => $fd, utf8 => 1 );

    my $ct;
    my $live = eval {
        $ct = $up->content;
        1;
    };

    ok !$live, "Exception: ". $@
        or diag explain [$ct];
};

done_testing;
