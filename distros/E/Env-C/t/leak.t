#!/usr/bin/env perl
#
# Test fix for RT #49872
#

use strict;
use Test::More;
use Env::C;

if (Env::C::using_safe_putenv()) {
    plan skip_all => "perl leaks with PERL_USE_SAFE_PUTENV";
}

unless (-f '/proc/self/statm') {
    plan skip_all => 'this test requires /proc/self/statm';
}

plan tests => 1;

Env::C::setenv(TZ => 'GMT');

my $start_size = memusage();

for (1..300000) {
    $ENV{TZ} = 'GMT';
    $ENV{TZ} = '';
}

my $end_size = memusage();

cmp_ok $end_size, '==', $start_size, 'setenv does not leak';

sub is_memusage_supported {
    return 1 if -f "/proc/self/statm";
}

sub memusage {
    my $pid = $$;

    my ($size) = split /\s+/, slurp('/proc/self/statm');

    return $size;
}

sub slurp {
    my $file = shift;

    local $/ = undef;

    open my $fh, '<', $file or die "failed to open $file: $!";

    my $content = <$fh>;

    return $content;
}
