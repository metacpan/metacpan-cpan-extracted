#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;

run_test(
    30,
    sub {
        $DB::single=1; 12;
        13;
        14;
        15;
        16;
        # 17
    },
    \&check_is_breakable,
    \&set_breakpoints,
    'continue',
    loc(line => 13),
    'continue',
    loc(line => 16),
    'done'
);

sub check_is_breakable {
    my($db, $loc) = @_;

    Test::More::ok(! $db->is_breakable(__FILE__, 11), 'Line 11 is not breakable');
    Test::More::ok($db->is_breakable(__FILE__, 12), 'Line 12 is breakable');
    Test::More::ok(! $db->is_breakable(__FILE__, 17), 'Line 17 is not breakable');
}

my @breakpoints;
BEGIN {
  @breakpoints = (
    { line => 13, comment => 'Set unconditional breakpoint' },
    { line => 14, code => 0, comment => 'Set breakpoint that will never fire' },
    { line => 15, code => 1, inactive => 1, comment => 'Set unconditional, inactive breakpoint' },
    { line => 16, code => 0, comment => 'Set breakpoint that will never fire' },
    { line => 16, comment => 'Set second unconditional breakpoint' },
  );
}

sub set_breakpoints {
    my($db, $loc) = @_;

    foreach my $break ( @breakpoints ) {
        my $line = $break->{line};
        my $comment = delete($break->{comment}) . " on line $line";

        Test::More::ok(Devel::Chitin::Breakpoint->new(
            file => $loc->filename,
            %$break
        ), $comment);
    }

    {
        my @bp = Devel::Chitin::Breakpoint->get(file => $loc->filename);
        Test::More::is(scalar(@bp), scalar(@breakpoints), 'get() by file returns correct number of breakpoints');
    }

    my %breakpoints_by_line;
    foreach my $break ( @breakpoints ) {
        my $line = $break->{line};
        $breakpoints_by_line{$line} ||= [];
        push @{ $breakpoints_by_line{$line} }, $break;
    }

    foreach my $line ( keys %breakpoints_by_line ) {
        my @bp = Devel::Chitin::Breakpoint->get(file => $loc->filename, line => $line);
        Test::More::is(scalar(@bp), scalar(@{ $breakpoints_by_line{$line} }), "expected breakpoints for line $line");
    }

    foreach my $break ( @breakpoints ) {
        my $line = $break->{line};
        my $code = exists($break->{code}) ? $break->{code} : 1;  # 1 for unconditional

        my($bp) = Devel::Chitin::Breakpoint->get(file => $loc->filename, line => $line, code => $code);
        Test::More::ok($bp, "Got breakpoint for line $line code $code");
        Test::More::is($bp->line, $line, 'Breakpoint line');
        Test::More::is($bp->code, $code, 'Breakpoint code');
    }
}

