#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    use_ok 'Getopt::Long::DescriptivePod' ;
}

lives_ok
    sub {
        replace_pod({
            filename   => \q{},
            tag        => '=head1 USAGE',
            code_block => q{},
            on_verbose => sub {
                my $message = shift;
                $message =~ tr{\n}{ };
                note $message;
                ok 1, $message;
            },
        });
    },
    'empty code block';
