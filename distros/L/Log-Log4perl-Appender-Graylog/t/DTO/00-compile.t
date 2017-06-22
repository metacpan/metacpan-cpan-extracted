#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;
use Data::DTO::GELF;

use Readonly;
Readonly my $CLASS => 'Data::DTO::GELF';

subtest "$CLASS Is valid object." => sub {
    meta_ok($CLASS);
};

subtest "$CLASS has correct attributes" => sub {
    has_attribute_ok( $CLASS, 'version' );
    has_attribute_ok( $CLASS, 'host' );
    has_attribute_ok( $CLASS, 'short_message' );
    has_attribute_ok( $CLASS, 'full_message' );
    has_attribute_ok( $CLASS, 'timestamp' );
    has_attribute_ok( $CLASS, 'level' );

};

subtest "$CLASS has correct predicates, clearers, writers, and builders" =>
    sub {
    has_method_ok( $CLASS, '_build_version' );
    has_method_ok( $CLASS, '_build_timestamp' );
    };

done_testing();
