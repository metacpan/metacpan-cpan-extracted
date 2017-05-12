#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

sub baz {
    open my $fh, '>', '/dev/null';

    say {$fh} 'hello';

    close $fh;
}

sub bar {
    baz();
}

sub foo {
    bar();
}

say 'before';
foo();
say 'after';
foo();
say 'end';

__DATA__
open("/dev/null", 0x241, 0666) = * at basic.pl line 8.
    main::baz() called at basic.pl line 16
    main::bar() called at basic.pl line 20
    main::foo() called at basic.pl line 24

open("/dev/null", 0x241, 0666) = * at basic.pl line 8.
    main::baz() called at basic.pl line 16
    main::bar() called at basic.pl line 20
    main::foo() called at basic.pl line 26
