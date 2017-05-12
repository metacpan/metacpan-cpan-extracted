#!/usr/bin/perl

# This is a port of the Java code in the FirstHop.java example. You can find
# the original Java source at:
#
#   http://jackrabbit.apache.org/doc/firststeps.html#Hop_1:_Logging_in_to_Jackrabbit
#
# -- Sterling, 2006-06-11

use strict;
use warnings;

use Java::JCR;
use Java::JCR::Jackrabbit;

my $repository = Java::JCR::Jackrabbit->new;
my $session = $repository->login;

my $user = $session->get_user_id;
my $name = $repository->get_descriptor($Java::JCR::Repository::REP_NAME_DESC);
print "Logged in as $user to a $name repository.\n";

$session->logout;

