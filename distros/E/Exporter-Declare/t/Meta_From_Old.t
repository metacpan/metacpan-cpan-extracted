#!/usr/bin/perl
use Fennec::Lite;
use strict;
use warnings;

use aliased 'Exporter::Declare::Meta';

{
    package ExporterA;

    our @EXPORT_OK = qw/a b c/;

    sub a { 'a' }
    sub b { 'b' }
    sub c { 'c' }
}

tests ExporterA => sub {
    # Bug found when Testing 0.102 against Exodist:Util prior to release
    lives_ok { Meta->new_from_exporter( 'ExporterA' ) };
};


run_tests;
done_testing;
