#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $module = 'EPublisher::Target::Plugin::OTRSDoc';
use_ok( $module );
use_ok( 'EPublisher::Target::Base' );

my $obj = $module->new();

isa_ok($obj, 'EPublisher::Target::Base');
can_ok($obj, qw'deploy new publisher _config');


done_testing();

