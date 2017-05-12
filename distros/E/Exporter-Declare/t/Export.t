#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Lite;

our $CLASS = "Exporter::Declare::Export";
require_ok $CLASS;

tests create => sub {
    throws_ok { $CLASS->new([]) }
        qr/You must specify exported_by when calling $CLASS\->new()/,
        "Required specs";
    my $export = $CLASS->new([], exported_by => __PACKAGE__ );
    isa_ok( $export, $CLASS );
    is( $export->exported_by, __PACKAGE__, "Stored property" );
    is_deeply( $export, [], "Is just an array" );
};

tests inject_vars => sub {
    my $var = "AAAA";
    $CLASS->new( \$var, exported_by => __PACKAGE__ );
    (\$var)->inject( __PACKAGE__, 'foo' );
    no strict 'vars';
    is( \$foo, \$var, "injected var" );
    is( $foo, 'AAAA', "Sanity var" );
};

tests inject_subs => sub {
    my $sub = sub { "AAAA" };
    $CLASS->new( $sub, exported_by => __PACKAGE__ );
    $sub->inject( __PACKAGE__, 'bar' );
    is( \&bar, $sub, "injected sub" );
    is( bar(), 'AAAA', "Sanity sub" );
};

run_tests();
done_testing;
