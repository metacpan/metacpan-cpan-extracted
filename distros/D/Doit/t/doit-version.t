#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;

use Scalar::Util 'looks_like_number';
use Test::More 'no_plan';

use Doit;

ok looks_like_number($Doit::VERSION);
unlike $Doit::VERSION, qr{_}, 'underscore in VERSION may cause warnings elsewhere';

__END__
