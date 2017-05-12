#!/usr/bin/env perl
# Test Log::Dispatch (only very simple tests)

use warnings;
use strict;
use lib 'lib', '../lib';

use File::Temp   qw/tempfile/;
use Test::More;

use Log::Report undef, syntax => 'SHORT';

BEGIN
{   eval "require Log::Dispatch";
    plan skip_all => 'Log::Dispatch not installed'
        if $@;

    my $sv = Log::Dispatch->VERSION;
    eval { Log::Dispatch->VERSION(2.00) };
    plan skip_all => "Log::Dispatch too old (is $sv, requires 2.00)"
        if $@;

    plan tests => 5;
    use_ok('Log::Report::Dispatcher::LogDispatch');
}

use_ok('Log::Dispatch::File');

my ($out, $outfn) = tempfile;
dispatcher 'Log::Dispatch::File' => 'logger'
   , filename => $outfn
   , to_level => ['ALERT-' => 'err'];

dispatcher close => 'default';

cmp_ok(-s $outfn, '==', 0);
notice "this is a test";
my $s1 = -s $outfn;
cmp_ok($s1, '>', 0);

warning "some more";
my $s2 = -s $outfn;
cmp_ok($s2, '>', $s1);

unlink $outfn;

