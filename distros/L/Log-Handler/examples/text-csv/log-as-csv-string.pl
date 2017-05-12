#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;
use Text::CSV;

my $log = Log::Handler->new();
my $csv = Text::CSV->new();

$log->add(
    screen => {
        maxlevel        => 'info',
        newline         => 1,
        message_layout  => '%m',
        message_pattern => '%T %L %P %t',
        prepare_message => sub {
            my $m = shift;
            $csv->combine(@{$m}{qw/time level pid mtime message/});
            $m->{message} = $csv->string;
        },
    }
);

$log->info('foo');
$log->info('bar');
$log->info('baz');

