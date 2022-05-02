#!/usr/bin/env perl

use warnings;
use strict;

BEGIN { delete $ENV{DEBUG} }

use lib 't/lib';
use TestCommon;

use File::KDBX::Error;
use File::KDBX;
use Test::More;

subtest 'Errors' => sub {
    my $error = exception {
        local $! = 1;
        $@ = 'last exception';
        throw 'uh oh', foo => 'bar';
    };
    like $error, qr/uh oh/, 'Errors can be thrown using the "throw" function';

    $error = exception { $error->throw };
    like $error, qr/uh oh/, 'Errors can be rethrown';

    is $error->details->{foo}, 'bar', 'Errors can have details';
    is $error->errno+0, 1, 'Errors record copy of errno when thrown';
    is $error->previous, 'last exception', 'Warnings record copy of the last exception';

    my $trace = $error->trace;
    ok 0 < @$trace, 'Errors record a stacktrace';
    like $trace->[0], qr!^uh oh at \H+error\.t line \d+$!, 'Stacktrace is correct';

    $error = exception { File::KDBX::Error->throw('uh oh') };
    like $error, qr/uh oh/, 'Errors can be thrown using the "throw" constructor';
    like $error->trace->[0], qr!^uh oh at \H+error\.t line \d+$!, 'Stacktrace is correct';

    $error = File::KDBX::Error->new('uh oh');
    $error = exception { $error->throw };
    like $error, qr/uh oh/, 'Errors can be thrown using the "throw" method';
    like $error->trace->[0], qr!^uh oh at \H+error\.t line \d+$!, 'Stacktrace is correct';
};

subtest 'Warnings' => sub {
    my $warning = warning {
        local $! = 1;
        $@ = 'last exception';
        alert 'uh oh', foo => 'bar';
    };
    like $warning, qr/uh oh/, 'Warnings are enabled by default' or diag 'Warnings: ', explain $warning;

    SKIP: {
        skip 'Warning object requires Perl 5.14 or later' if $] < 5.014;
        is $warning->details->{foo}, 'bar', 'Warnings can have details';
        is $warning->errno+0, 1, 'Warnings record copy of errno when logged';
        is $warning->previous, 'last exception', 'Warnings record copy of the last exception';
        like $warning->trace->[0], qr!^uh oh at \H+error\.t line \d+$!, 'Stacktrace is correct';
    };

    $warning = warning { File::KDBX::Error->warn('uh oh') };
    like $warning, qr/uh oh/, 'Warnings can be logged using the "alert" constructor';
    SKIP: {
        skip 'Warning object requires Perl 5.14 or later' if $] < 5.014;
        like $warning->trace->[0], qr!^uh oh at \H+error\.t line \d+$!, 'Stacktrace is correct';
    };

    my $error = File::KDBX::Error->new('uh oh');
    $warning = warning { $error->alert };
    like $warning, qr/uh oh/, 'Warnings can be logged using the "alert" method';
    SKIP: {
        skip 'Warning object requires Perl 5.14 or later' if $] < 5.014;
        like $warning->trace->[0], qr!^uh oh at \H+error\.t line \d+$!, 'Stacktrace is correct';
    };

    {
        local $File::KDBX::WARNINGS = 0;
        my @warnings = warnings { alert 'uh oh' };
        is @warnings, 0, 'Warnings can be disabled locally'
            or diag 'Warnings: ', explain(\@warnings);
    }

    SKIP: {
        skip 'warnings::warnif_at_level is required', 1 if !warnings->can('warnif_at_level');
        no warnings 'File::KDBX';
        my @warnings = warnings { alert 'uh oh' };
        is @warnings, 0, 'Warnings can be disabled lexically'
            or diag 'Warnings: ', explain(\@warnings);
    }

    SKIP: {
        skip 'warnings::fatal_enabled_at_level is required', 1 if !warnings->can('fatal_enabled_at_level');
        use warnings FATAL => 'File::KDBX';
        my $exception = exception { alert 'uh oh' };
        like $exception, qr/uh oh/, 'Warnings can be fatal';
    }

    {
        my $warning;
        local $SIG{__WARN__} = sub { $warning = shift };
        alert 'uh oh';
        like $warning, qr/uh oh/, 'Warnings can be caught';
    }
};

done_testing;
