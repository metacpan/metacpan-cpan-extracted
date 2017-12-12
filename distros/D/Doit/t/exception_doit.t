#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More 'no_plan';

use Doit;

my $d = Doit->init;

{
    eval { $d->system($^X, '-e', 'exit 1') }; my $exception_line = __LINE__;
    like $@->stringify, qr{Command exited with exit code 1 at .*exception_doit\.t line $exception_line}, 'exception message with caller\'s line';
    is   $@->{__line}, $exception_line,                                                                  'check only exception line';
    like $@->{__filename}, qr{exception_doit\.t},                                                        'check only exception filename';
    is   $@->{__package}, 'main',                                                                        'check only exception package';
}

{
    my $exception_line;
    sub exception_within_function {
	eval { $d->system($^X, '-e', 'exit 1') }; $exception_line = __LINE__;
    }
    exception_within_function();
    like $@->stringify, qr{Command exited with exit code 1 at .*exception_doit\.t line $exception_line}, 'exception in function';
    is   $@->{__line}, $exception_line;
    like $@->{__filename}, qr{exception_doit\.t};
    is   $@->{__package}, 'main';
}

{
    {
	package TestPackage;
	sub exception_within_function {
	    eval { $d->system($^X, '-e', 'exit 1') }; my $exception_line = __LINE__;
	    return $exception_line;
	}
    }
    my $exception_line = TestPackage::exception_within_function();
    like $@->stringify, qr{Command exited with exit code 1 at .*exception_doit\.t line $exception_line}, 'exception in other package';
    is   $@->{__line}, $exception_line;
    like $@->{__filename}, qr{exception_doit\.t};
    is   $@->{__package}, 'TestPackage';
}

__END__
