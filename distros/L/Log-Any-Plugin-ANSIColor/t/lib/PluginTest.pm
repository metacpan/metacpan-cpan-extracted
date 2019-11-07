package PluginTest;

use strict;
use warnings;

use Log::Any                qw( $log );
use Log::Any::Adapter::Util qw( logging_methods log_level_aliases );
use Term::ANSIColor         qw( colored );
use Test::More;

use parent 'Exporter';

our @EXPORT_OK = qw( check_log_colors );

sub check_log_colors {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my %method_for = log_level_aliases();
    for (logging_methods()) {
        $method_for{$_} = $_;
    }

    my %color = @_;
    for my $method (sort keys %method_for) {
        # Log using the original method name, which may be an alias
        $log->$method($method);

        my $base_method = $method_for{$method};

        my $got = $log->msgs->[0]->{message};
        if ($color{$base_method} && ($color{$base_method} ne 'none')) {
            is($got, colored([$color{$base_method}], $method),
                "$method messages are $color{$base_method}");
        }
        else {
            is($got, $method, "$method messages are plain");
        }
        $log->clear;
    }
}

1;
