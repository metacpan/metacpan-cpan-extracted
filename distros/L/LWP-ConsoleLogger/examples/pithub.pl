#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use LWP::ConsoleLogger::Easy qw( debug_ua );
use LWP::UserAgent;
use Pithub;

my $mech  = LWP::UserAgent->new;
my $debug = debug_ua($mech);

my $token = shift @ARGV;

die 'usage: perl pithub.pl my-access-token' unless $token;

my $c = Pithub::Repos::Collaborators->new(
    ua    => $mech, user => 'tokuhirom',
    token => $token
);
my $result = $c->list( repo => 'OrePAN2' );

=pod

Please see
https://help.github.com/articles/creating-an-access-token-for-command-line-use
for instructions on how to get your own Github access token.

=cut
