#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( 'Event::Distributor' );

use_ok( 'Event::Distributor::_Event' );
use_ok( 'Event::Distributor::Signal' );
use_ok( 'Event::Distributor::Action' );
use_ok( 'Event::Distributor::Query' );

done_testing;
