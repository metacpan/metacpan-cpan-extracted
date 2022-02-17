#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';

use Test::More;

unless ($ENV {AUTHOR_TESTING}) {
    plan skip_all => "AUTHOR tests";
    exit;
}

eval "use Test::Pod::Coverage 1.00; 1" or
      plan skip_all => "Test::Pod::Coverage required for testing POD coverage";

all_pod_coverage_ok ({private => [qr /^/]});


__END__
