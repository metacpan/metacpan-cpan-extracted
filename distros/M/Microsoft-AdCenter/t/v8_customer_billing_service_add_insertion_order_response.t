#!perl -T
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use lib 't/lib';

use Microsoft::AdCenter::V8::CustomerBillingService::Test::AddInsertionOrderResponse;

Test::Class->runtests;

