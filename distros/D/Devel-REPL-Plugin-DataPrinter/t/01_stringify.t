#!/usr/bin/env perl

use FindBin qw($Bin);
use lib "$Bin/../t/lib";

use Test::More tests => 10;

use_ok('Devel::REPL');
use_ok('Mock::Stringify');
use_ok('Mock::NonStringify');
use_ok('Term::ReadLine::Mock');

my $data = {
    'Mock::Stringify' => {
        default => { regex => qr/^stringified$/,
            message => "stringified by default",
            config => {}
        },
        stringify_on => { regex => qr/^stringified$/,
            message => "stringified by setting 'stringify' to true",
            config => {
                stringify => {
                    'Mock::Stringify' => 1,
                },
            }
        },
        stringify_off => { regex => qr/internal data/s,
            message => "not stringified by setting 'stringify' to false - internal data",
            config => {
                stringify => {
                    'Mock::Stringify' => 0,
                },
            }
        },
    },
    'Mock::NonStringify' => {
        default => { regex => qr/internal data/s,
            message => "not stringified by default - internal data",
            config => {}
        },
        stringify_on => { regex => qr/SCALAR/,
            message => "stringified by setting 'stringify' to true - SCALAR",
            config => {
                stringify => {
                    'Mock::NonStringify' => 1,
                },
            }
        },
        stringify_off => { regex => qr/internal data/s,
            message => "not stringified by setting 'stringify' to false",
            config => {
                stringify => {
                    'Mock::NonStringify' => 0,
                },
            }
        },
    },
};

for my $class (keys %{$data}) {
    for my $type (keys %{$data->{$class}}) {
        my $repl = get_repl($class."->new");
        $repl->dataprinter_config($data->{$class}{$type}{config});
        $repl->run_once();
        like(${$repl->term->string}, $data->{$class}{$type}{regex}, "$class -> $type -> $data->{$class}{$type}{message}" );
    }
}

sub get_repl {
    my ($cmd) = @_;
    my $repl = Devel::REPL->new;
    $repl->load_plugin('DataPrinter');
    $repl->term(Term::ReadLine::Mock->new({ cmd => $cmd }));
    $repl;
}

1;
