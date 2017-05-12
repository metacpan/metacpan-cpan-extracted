#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Lite;

our $CLASS = "Exporter::Declare::Export::Sub";
require_ok $CLASS;

tests inject_subs => sub {
    my $sub = sub { "AAAA" };
    $CLASS->new( $sub, exported_by => __PACKAGE__ );
    $sub->inject( __PACKAGE__, 'bar' );
    is( \&bar, $sub, "injected sub" );
    is( bar(), 'AAAA', "Sanity sub" );
};

run_tests();
done_testing;
