#!/usr/bin/env perl
# Test the additional modifiers.
use warnings;
use strict;

use Test::More;
use Log::Report mode => 'DEBUG';
use File::Basename qw(dirname);

use_ok 'Log::Report::Template';

# The modifiers are loaded automagically
my $templater = Log::Report::Template->new;
isa_ok $templater, 'Log::Report::Template';

### oops, there are none to be tested yet ;-)

done_testing;
