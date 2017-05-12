#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Warn;
use Test::Exception;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

use Path::Tiny;
use Log::Deep;

my $deep;
eval { $deep = Log::Deep->new; };

SKIP:
{
    if ($EVAL_ERROR) {
        skip("Could not wright log file: $EVAL_ERROR", 26) if $EVAL_ERROR;
    }

    isa_ok( $deep, 'Log::Deep', 'Can create a log object');

    ok( -f $deep->file, 'Check that the file is created/exists' );

    # truncate the file and reset the writing at the start
    truncate $deep->{handle}, 0;
    seek $deep->{handle}, 0, 0;

    my $expected_length = 0;
    my $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Check that we realy do have a zero length file');

    $deep->session(0);
    $deep->flush;
    $expected_length = $found_length + 1;
    $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Checking that session writes one log line');

    dies_ok { $deep->fatal('test') } "Fatal dies";
    $deep->flush;
    $expected_length = $found_length + 1;
    $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Checking that fatal writes one log line');

    $deep->error('test');
    $deep->flush;
    $expected_length = $found_length + 1;
    $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Checking that error writes one log line');

    $deep->warn('test');
    $deep->flush;
    $expected_length = $found_length + 1;
    $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Checking that warn writes one log line');

    $deep->debug('test');
    $deep->flush;
    $expected_length = $found_length + 0;
    $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Checking that debug writes zero log lines');

    $deep->enable('debug');
    $deep->debug('test');
    $deep->flush;
    $expected_length = $found_length + 1;
    $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Checking that debug writes one log line');

    $deep->message('test');
    $deep->flush;
    $expected_length = $found_length + 0;
    $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Checking that message writes zero log lines');

    $deep->enable('message');
    $deep->message('test');
    $deep->flush;
    $expected_length = $found_length + 1;
    $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Checking that message writes one log line');

    $deep->info('test');
    $deep->flush;
    $expected_length = $found_length + 0;
    $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Checking that info writes zero log lines');

    $deep->enable('info');
    $deep->info('test');
    $deep->flush;
    $expected_length = $found_length + 1;
    $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Checking that info writes one log line');

    $deep->security('test');
    $deep->flush;
    $expected_length = $found_length + 1;
    $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Checking that security writes one log line');

    # turn on catching warnings
    ok( $deep->catch_warnings(1), 'Catching warnings now' );
    warn "This should be cought";
    $deep->flush;
    $expected_length = $found_length + 1;
    $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Checking that warn() writes one log line');

    # turn back off warning capture
    ok( !$deep->catch_warnings(0), 'No longer catching warnings' );

    warning_is {warn "Not cought"} 'Not cought', 'Warnings are no longer cought';
    $expected_length = $found_length;
    $found_length    = log_length($deep);

    is( $found_length, $expected_length, 'Checking that warn() does not write one log line');
}
done_testing();

sub log_length {
    my ($deep) = @_;

    my $file   = $deep->file;
    my @lines  = split /\n/xms, path($file)->slurp;

    return scalar @lines;
}
