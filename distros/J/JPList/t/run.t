#!/usr/bin/perl -w

#
# t/run.pl
#
# Developed by Skanda shastry<skanda@exceleron.com>
# Copyright (c) 2015 Exceleron Inc
# All rights reserved.
#
#

use FindBin;
use lib 't';
use lib "$FindBin::Bin/../lib";

# Load all the testcases
use Test::Class::Load qw(t);

# For any specific cases
#use Test::PAMS::Alerts::Contact;
#use Test::PAMS::Alerts::Subscription;
#use Test::PAMS::Alerts::AlertDefinition;

Test::Class->runtests;

