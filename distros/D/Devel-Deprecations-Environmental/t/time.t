use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Time;
use Devel::Deprecations::Environmental ();
use Devel::Deprecations::Environmental::MicroDateTime;

use Devel::Hide qw(DateTime);

use lib 't/lib';
use lib 't/inc';

our $now = time();
our $warn_time_object        = Devel::Deprecations::Environmental::MicroDateTime->from_epoch(epoch => $now + 1);
our $unsupported_time_object = Devel::Deprecations::Environmental::MicroDateTime->from_epoch(epoch => $now + 3);
our $fatal_time_object       = Devel::Deprecations::Environmental::MicroDateTime->from_epoch(epoch => $now + 5);

require 'time-tests.pl';
