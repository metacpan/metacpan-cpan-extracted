#!perl

use strict;
use warnings;
use IPC::Open3;
use File::Spec;
use Symbol qw( gensym );

BEGIN {
    require 't/common.pl';
}


my @examples = qw(
        get_device.pl
        get_driver.pl
        get_module.pl
);

plan tests => scalar @examples * 3;

for my $example (@examples) {
    my $path = File::Spec->catfile('examples', $example);

    my ($out, $err) = (gensym(), gensym());
    my $pid = open3(undef, $out, $err, $^X, '-MExtUtils::testlib', '-c', $path);

    ok( $? == 0, "$^X exited with 0" );
    ok( do { local $/ = undef; <$out> } eq '', 'nothing on STDOUT' );
    like( do { local $/ = undef; <$err> }, qr/\bsyntax OK\b/, 'syntax OK' );
}
