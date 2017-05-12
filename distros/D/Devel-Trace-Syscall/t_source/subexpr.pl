#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

sub filename {
    return '/dev/null';
}

sub baz {
    open my $fh, '>', filename();

    say {$fh} 'hello';

    close $fh;
}

sub bar {
    baz();
}

sub foo {
    bar();
}

foo();

__DATA__
open("/dev/null", 0x241, 0666) = * at subexpr.pl line 12.
    main::baz() called at subexpr.pl line 20
    main::bar() called at subexpr.pl line 24
    main::foo() called at subexpr.pl line 27
