#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('LWP::UserAgent::msgraph') };

my $ua=new_ok('LWP::UserAgent::msgraph'=>[appid => 'A', tenant => 'B',grant_type=>'client_credentials']);
