# $Id: 0.t 498 2014-04-02 19:19:15Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
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
File::AptFetch::ConfigData->set_config( tick    =>  1 );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan
  !defined $Apt_Lib ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib           ?     ( skip_all => q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/ftp|  ?  ( skip_all => q|missing method [ftp:]| ) :
                                                     ( tests => 5 );

my $rv = File::AptFetch->init( q|ftp| );
isa_ok $rv, q|File::AptFetch|, q|[ftp:] method initializes|;
is $rv->{Status}, 100, q|[ftp:] method is ready|;
ok !@{$rv->{log}}, q|{@log} is processed|;
ok !!@{$rv->{diag}}, q|{@diag} is filled|;
ok !!keys %{$rv->{capabilities}}, q|{%capabilities} is filled|;
t::TestSuite::FAFTS_show_message %{$rv->{capabilities}};

# vim: syntax=perl
