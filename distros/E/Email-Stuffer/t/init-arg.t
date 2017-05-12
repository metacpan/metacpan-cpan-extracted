#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use Email::Stuffer;

my $to = 'me@email.com';
my $stuffer = Email::Stuffer->new({ to => $to });
is( $stuffer->email->header('To'), $to, 'init-arg "to" sets To header' );
