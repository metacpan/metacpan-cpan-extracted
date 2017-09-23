package PluginTest;

use strict;
use warnings;

use Log::Any        qw( $log );
use Term::ANSIColor qw( colored );
use Test::More;

use parent 'Exporter';

our @EXPORT_OK = qw( check_log_colors );

sub check_log_colors {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my %color = @_;
    for my $method (Log::Any->logging_methods) {
        $log->$method($method);
        my $got = $log->msgs->[0]->{message};
        if ($color{$method} && ($color{$method} ne 'none')) {
            is($got, colored([$color{$method}], $method),
                "$method messages are $color{$method}");
        }
        else {
            is($got, $method, "$method messages are plain");
        }
        $log->clear;
    }
}

1;
