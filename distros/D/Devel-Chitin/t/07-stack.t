#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;

our($serial_1, $serial_2, $serial_3, $serial_4, $serial_5); my $main_serial = $Devel::Chitin::stack_serial[0]->[-1];
run_test(
    79,
    sub {
        $serial_1 = $Devel::Chitin::stack_serial[-1]->[-1];
        foo(1,2,3);                 # line 14: void
        sub foo {
            $serial_2 = $Devel::Chitin::stack_serial[-1]->[-1];
            my @a = Bar::bar();     # line 17: list
        }
        sub Bar::bar {
            $serial_3 = $Devel::Chitin::stack_serial[-1]->[-1];
            &Bar::baz;              # line 21: list
        } 
        package Bar;
        sub baz {
            $serial_4 = $Devel::Chitin::stack_serial[-1]->[-1];
            my $a = eval {          # line 26: scalar
                eval "quux()";      # line 27: scalar
            };
        }
        sub AUTOLOAD {
            $serial_5 = $Devel::Chitin::stack_serial[-1]->[-1];
            $DB::single=1;
            33;                     # scalar
        }
    },
    \&check_stack,
    'done'
);

sub check_stack {
    my($db, $loc) = @_;
    my $stack = $db->stack();

    Test::More::ok($stack, 'Get execution stack');

    my $filename = __FILE__;
    my @expected = (
        {   package     => 'Bar',
            filename    => $filename,
            line        => 33,
            subroutine  => 'Bar::AUTOLOAD',
            hasargs     => 1,
            wantarray   => '',
            evaltext    => undef,
            evalfile    => undef,
            evalline    => undef,
            is_require  => undef,
            autoload    => 'quux',
            subname     => 'AUTOLOAD',
            args        => [],
            serial      => $serial_5,
        },
        {   package     => 'Bar',
            filename    => qr/\(eval \d+\)\[\Q$filename\E:27\]/,
            line        => 1,   # line 1 if the eval text
            subroutine  => '(eval)',
            hasargs     => 0,
            wantarray   => '',
            evaltext    => $^V lt v5.18 ? "quux()\n;" : 'quux()',
            evalfile    => $filename,
            evalline    => 27,
            is_require  => '',  # false but not undef because it is a string eval
            autoload    => undef,
            subname     => '(eval)',
            args        => [],
            serial      => '__DONT_CARE__',  # we'll check eval frame IDs in serials_are_distinct()
        },
        {   package     => 'Bar',
            filename    => $filename,
            line        => 27,
            subroutine  => '(eval)',
            hasargs     => 0,
            wantarray   => '',
            evaltext    => undef,
            evalfile    => undef,
            evalline    => undef,
            is_require  => undef,
            autoload    => undef,
            subname     => '(eval)',
            args        => [],
            serial      => '__DONT_CARE__', # we'll check eval frame IDs in serials_are_distinct()
        },
        {   package     => 'Bar',
            filename    => $filename,
            line        => 26,
            subroutine  => 'Bar::baz',
            hasargs     => '', # because it's called as &Bar::baz;
            wantarray   => 1,
            evaltext    => undef,
            evalfile    => undef,
            evalline    => undef,
            is_require  => undef,
            autoload    => undef,
            subname     => 'baz',
            args        => [],
            serial      => $serial_4,
        },
        {   package     => 'main',
            filename    => $filename,
            line        => 21,
            subroutine  => 'Bar::bar',
            hasargs     => 1,
            wantarray   => 1,
            evaltext    => undef,
            evalfile    => undef,
            evalline    => undef,
            is_require  => undef,
            autoload    => undef,
            subname     => 'bar',
            args        => [],
            serial      => $serial_3,
        },
        {   package     => 'main',
            filename    => $filename,
            line        => 17,
            subroutine  => 'main::foo',
            hasargs     => 1,
            wantarray   => undef,
            evaltext    => undef,
            evalfile    => undef,
            evalline    => undef,
            is_require  => undef,
            autoload    => undef,
            subname     => 'foo',
            args        => [1,2,3],
            serial      => $serial_2,
        },
        # two frames inside run_test
        {   package     => 'main',
            filename    => $filename,
            line        => 14,
            subroutine  => "main::__ANON__[$filename:35]",
            hasargs     => 1,
            wantarray   => undef,
            evaltext    => undef,
            evalfile    => undef,
            evalline    => undef,
            is_require  => undef,
            autoload    => undef,
            subname     => '__ANON__',
            args        => [],
            serial      => $serial_1,
        },
        {   package =>  'Devel::Chitin::TestRunner',
            filename    => qr(t/lib/Devel/Chitin/TestRunner\.pm$),
            line        => '__DONT_CARE__',
            subroutine  => 'Devel::Chitin::TestRunner::run_test',
            hasargs     => 1,
            wantarray   => undef,
            evaltext    => undef,
            evalfile    => undef,
            evalline    => undef,
            is_require  => undef,
            autoload    => undef,
            subname     => 'run_test',
            args        => '__DONT_CARE__',
            serial      => '__DONT_CARE__',
        },
 
        {   package     => 'main',
            filename    => $filename,
            line        => 36,
            subroutine  => 'main::MAIN',
            hasargs     => 1,
            wantarray   => undef,
            evaltext    => undef,
            evalfile    => undef,
            evalline    => undef,
            is_require  => undef,
            autoload    => undef,
            subname     => 'MAIN',
            args        => ['--test'],
            serial      => $main_serial,
            callsite    => undef,
        },
    );

    Test::More::is($stack->depth, scalar(@expected), 'Expected number of stack frames');

    my(@serial, @callsite);
    for(my $framenum = 0; my $frame = $stack->frame($framenum); $framenum++) {
        check_frame($frame, $expected[$framenum]);
        push @serial, [$framenum, $frame->serial];
        push @callsite, [$framenum, $frame->callsite];
    }
    values_are_distinct(\@serial, 'serials are distinct');
    values_are_distinct(\@serial, 'callsites are distinct');

    my $iter = $stack->iterator();
    Test::More::ok($iter, 'Stack iterator');
    my @iter_serial;
    for(my $framenum = 0; my $frame = $iter->(); $framenum++) {
        check_frame($frame, $expected[$framenum], 'iterator');
        push @iter_serial, [$framenum, $frame->serial];

    }
    Test::More::is_deeply(\@iter_serial, \@serial, 'Got the same serial numbers');

    # Get the stack again, serials should be the same
    Devel::Chitin::Stack::invalidate();  # force it to re-create it
    my $stack2 = $db->stack();
    my @serial2;
    for (my $framenum = 0; my $frame = $stack2->frame($framenum); $framenum++) {
        push @serial2, [ $framenum, $frame->serial];
    }
    Test::More::is_deeply(\@serial2, \@serial, 'serial numbers are the same getting another stack object');
}

sub check_frame {
    my($got_orig, $expected_orig, $msg) = @_;
    my %got_copy = %$got_orig;
    my %expected_copy = %$expected_orig;

    { no warnings 'uninitialized';
        $msg = (defined $msg)
                ? sprintf("%s:%s $msg", @expected_copy{'filename','line'})
                : sprintf("%s:%s", @expected_copy{'filename','line'});
    }

    remove_dont_care(\%expected_copy, \%got_copy);

    Test::More::ok(exists($got_copy{hints})
            && exists($got_copy{bitmask})
            && exists($got_copy{level})
            && exists($got_copy{callsite}),
            "Frame has hints, bitmask, callsite and level: $msg");
    my($level) = delete @got_copy{'level','hints','bitmask'};

    my $callsite = delete $got_copy{callsite};
    if (has_callsite) {
        if (exists $expected_copy{callsite}) {
            Test::More::is($callsite, $expected_copy{callsite}, "callsite value for line $expected_copy{line}");
            delete $expected_copy{callsite};
        } else {
            Test::More::ok($callsite, "callsite has a value for line $expected_copy{line}");
        }
    } else {
        delete $expected_copy{callsite};
        Test::More::ok(!defined($callsite), 'unsupported callsite is undef');
    }

    my $got_filename = delete $got_copy{filename};
    my $expected_filename = delete $expected_copy{filename};
    if (ref $expected_filename) {
        Test::More::like(
                $got_filename,
                $expected_filename,
                "Execution stack frame filename matches: $msg");
    } else {
        Test::More::is($got_filename,
                        $expected_filename,
                        "Execution stack frame filename matches: $msg");
    }

    Test::More::is_deeply(\%got_copy, \%expected_copy, "Execution stack frame matches for $msg");
}

sub values_are_distinct {
    my($record_list, $ok_msg) = @_;

    my %value_counts;
    my %value_to_frame;
    foreach my $record ( @$record_list ) {
        my($frameno, $value) = @$record;
        $value_counts{ $value }++;

        $value_to_frame{$value} ||= [];
        push @{$value_to_frame{ $value } }, $frameno;
    }

    my @duplicate_values = grep { $value_counts{$_} > 1 } keys %value_counts;
    Test::More::ok(! @duplicate_values, $ok_msg)
        or Test::More::diag('Frames with duplicates: ', join(' and ', map { join(',', @{$value_to_frame{$_}}) } @duplicate_values));
}

sub remove_dont_care {
    my($expected, $got) = @_;
    foreach my $k ( keys %$expected ) {
        no warnings 'uninitialized';
        if ($expected->{$k} eq '__DONT_CARE__') {
            delete $expected->{$k};
            delete $got->{$k};
        }
    }
}
