# $Id: 0.t 490 2014-01-26 18:44:36Z whynot $
# Copyright 2009, 2010, 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.50; our $VERSION = qv q|0.1.1|;

use t::TestSuite;
use File::AptFetch;
use Test::More;

File::AptFetch::ConfigData->set_config( timeout => 10 );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan
  !defined $Apt_Lib     ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib             ? ( skip_all =>       q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/copy| ? ( skip_all =>     q|missing method [copy:]| ) :
                          ( tests    =>                             5 );

my $rv = File::AptFetch->init( q|copy| );
isa_ok $rv, q|File::AptFetch|, q|[copy:] method initializes|;
is $rv->{Status}, 100, q|[copy:] method is ready|;
ok !@{$rv->{log}}, q|{@log} is processed|;
ok !!@{$rv->{diag}}, q|{@diag} is filled|;
ok !!keys %{$rv->{capabilities}}, q|{%capabilities} is filled|;
t::TestSuite::FAFTS_show_message %{$rv->{capabilities}};

# vim: syntax=perl
