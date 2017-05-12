#!/bin/perl

# Version: $Id: last_token.t 3 2007-10-05 15:49:42Z sergey.chernyshev $

use strict;

#
# The problem was reported by Charlie Katz that last token gets stripped
# and moved to next run of the filter method (even if on different string)
# if string didn't have \n at the end
#
# test case is adopted from Charlie's
#

#######################################################################
package NullFilter;
use base "HTML::LinkChanger::URLFilter";
sub url_filter {
 my $self = shift;
 my %args = @_;
 return $args{url};
}
#######################################################################
package main;
use Test;
BEGIN { plan tests => 5}

print "Testing if HTML::LinkChanger is available ... \n";
use HTML::LinkChanger;
ok(1);

print "Testing if HTML::LinkChanger::URLFilter is available ... \n";
use HTML::LinkChanger::URLFilter;
ok(1);

print "Testing if we can create HTML::LinkChanger with NullFilter ... \n";
my $changer = HTML::LinkChanger->new(url_filters => [ NullFilter->new ]);
ok($changer);

print "Testing if string without \\n at the end gets parsed correctly ... \n";
my $unterminated = "This text does not have a newline.";
ok($changer->filter($unterminated) eq $unterminated);

print "Testing if string with \\n at the end gets parsed correctly ... \n";
my $terminated = "This text has a newline at the end.\n";
ok($changer->filter($terminated) eq $terminated);

#######################################################################
