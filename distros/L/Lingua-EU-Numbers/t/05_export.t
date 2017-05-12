#!/usr/bin/perl 
use Lingua::EU::Numbers qw(&cardinal2alpha %num2alpha);
use strict;
use Test::More tests => 1;

$SIG{__WARN__} = sub { }; # Discard warnings, we expect them.

$num2alpha{1} = 'foo';
is(cardinal2alpha(1), 'foo', "\%num2alpha export") ;

