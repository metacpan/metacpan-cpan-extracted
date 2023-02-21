use warnings;
use strict;

use Test::More;
BEGIN {
    plan skip_all => 'Need DateTime installed to run these tests'
        unless(eval 'use DateTime; 1')
}
use Test::Exception;
use Test::Time;
use Devel::Deprecations::Environmental ();

use lib 't/lib';
use lib 't/inc';

our $now = time();
our $warn_time_object        = DateTime->from_epoch(epoch => $now + 1);
our $unsupported_time_object = DateTime->from_epoch(epoch => $now + 3);
our $fatal_time_object       = DateTime->from_epoch(epoch => $now + 5);

require 'time-tests.pl';
