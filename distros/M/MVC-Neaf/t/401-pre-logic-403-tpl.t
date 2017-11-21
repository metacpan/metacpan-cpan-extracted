#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf qw(:sugar);

neaf pre_logic => sub { die 403 };
neaf 403 => sub { +{ -content => 'Forbidden' }; };

get '/' => sub { die "Must never get here"; };

my ($status, $header, $content) = neaf->run_test('/');

is $status, 403, "Status preserved";
is $content, 'Forbidden', "template worked";

done_testing;
