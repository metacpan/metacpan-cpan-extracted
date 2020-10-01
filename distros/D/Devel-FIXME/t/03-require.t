#!/usr/bin/perl -T
# taint mode is to override idiomatic PERL5OPT=-MFIXME, and other attrocities

use strict;
use warnings;
no warnings qw/once/;

use Test::More tests => 3;
use Test::NoWarnings;

use lib 't/lib';

sub Devel::FIXME::rules { sub { Devel::FIXME::DROP() } }

use_ok('Devel::FIXME');

my $value = eval { require Devel::FIXME::Test::Scalar };

is_deeply($value, $Devel::FIXME::Test::Scalar::RETURN_VALUE, "return value is valid even if proxied");
