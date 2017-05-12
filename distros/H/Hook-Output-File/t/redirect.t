#!/usr/bin/perl

use strict;
use warnings;
use constant stdout => 0;
use constant stderr => 1;

use File::Temp ':POSIX';
use Hook::Output::File;
use IO::Capture::Stderr;
use IO::Capture::Stdout;
use Test::More tests => 24;

my $get_file_content = sub
{
    open(my $fh, '<', $_[0]) or die "Cannot open $_[0]: $!\n";
    return do { local $/; local $_ = <$fh>; s/\n+$//; $_ };
};

my %handlers = (
    stdout => { explicit => sub { print STDOUT $_[0] },
                implicit => sub { print $_[0]        }},
    stderr => { explicit => sub { print STDERR $_[0] },
                implicit => sub { warn $_[0], "\n"   }},
);

sub test_redirect_both
{
    my ($code, $output_messages, $test_messages) = @_;

    my $stdout_tmpfile = tmpnam();
    my $stderr_tmpfile = tmpnam();

    my $hook = Hook::Output::File->redirect(
        stdout => $stdout_tmpfile,
        stderr => $stderr_tmpfile,
    );

    $code->[stdout]->($output_messages->[stdout]);
    $code->[stderr]->($output_messages->[stderr]);

    undef $hook;

    is($get_file_content->($stdout_tmpfile), $output_messages->[stdout], "$test_messages->[stdout] [both]");
    is($get_file_content->($stderr_tmpfile), $output_messages->[stderr], "$test_messages->[stderr] [both]");

    unlink $stdout_tmpfile;
    unlink $stderr_tmpfile;
}

test_redirect_both(
    [ $handlers{stdout}{explicit},    $handlers{stderr}{explicit}    ],
    [ 'explicit stdout (redirected)', 'explicit stderr (redirected)' ],
    [ 'explicit stdout redirected',   'explicit stderr redirected'   ],
);
test_redirect_both(
    [ $handlers{stdout}{implicit},    $handlers{stderr}{implicit}    ],
    [ 'implicit stdout (redirected)', 'implicit stderr (redirected)' ],
    [ 'implicit stdout redirected',   'implicit stderr redirected'   ],
);

sub test_redirect_single
{
    my ($stream, $code, $output_message, $test_message) = @_;

    my $tmpfile = tmpnam();

    my $hook = Hook::Output::File->redirect(
        $stream => $tmpfile,
    );

    $code->($output_message);

    undef $hook;

    is($get_file_content->($tmpfile), $output_message, "$test_message [single]");

    unlink $tmpfile;
}

test_redirect_single(
    'stdout',
    $handlers{stdout}{explicit},
    'explicit stdout (redirected)',
    'explicit stdout redirected',
);
test_redirect_single(
    'stderr',
    $handlers{stderr}{explicit},
    'explicit stderr (redirected)',
    'explicit stderr redirected',
);
test_redirect_single(
    'stdout',
    $handlers{stdout}{implicit},
    'implicit stdout (redirected)',
    'implicit stdout redirected',
);
test_redirect_single(
    'stderr',
    $handlers{stderr}{implicit},
    'implicit stderr (redirected)',
    'implicit stderr redirected',
);

sub test_capture
{
    my ($code, $output_messages, $test_messages) = @_;

    my $stdout_tmpfile = tmpnam();
    my $stderr_tmpfile = tmpnam();

    my @descriptors = (1, 2);

    is(fileno STDOUT, $descriptors[stdout], 'stdout descriptor before');
    is(fileno STDERR, $descriptors[stderr], 'stderr descriptor before');

    my $hook = Hook::Output::File->redirect(
        stdout => $stdout_tmpfile,
        stderr => $stderr_tmpfile,
    );

    is(fileno STDOUT, $descriptors[stdout], 'stdout descriptor while');
    is(fileno STDERR, $descriptors[stderr], 'stderr descriptor while');

    undef $hook;

    is(fileno STDOUT, $descriptors[stdout], 'stdout descriptor after');
    is(fileno STDERR, $descriptors[stderr], 'stderr descriptor after');

    unlink $stdout_tmpfile;
    unlink $stderr_tmpfile;

    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    $code->[stdout]->($output_messages->[stdout]);
    $capture->stop;
    my @stdout_lines = $capture->read;

    $capture = IO::Capture::Stderr->new;
    $capture->start;
    $code->[stderr]->($output_messages->[stderr]);
    $capture->stop;
    my @stderr_lines = $capture->read;

    chomp @stderr_lines;

    is_deeply(\@stdout_lines, [ $output_messages->[stdout] ], $test_messages->[stdout]);
    is_deeply(\@stderr_lines, [ $output_messages->[stderr] ], $test_messages->[stderr]);
}

test_capture(
    [ $handlers{stdout}{explicit},  $handlers{stderr}{explicit}  ],
    [ 'explicit stdout (captured)', 'explicit stderr (captured)' ],
    [ 'explicit stdout captured',   'explicit stderr captured'   ],
);
test_capture(
    [ $handlers{stdout}{implicit},  $handlers{stderr}{implicit}  ],
    [ 'implicit stdout (captured)', 'implicit stderr (captured)' ],
    [ 'implicit stdout captured',   'implicit stderr captured'   ],
);
