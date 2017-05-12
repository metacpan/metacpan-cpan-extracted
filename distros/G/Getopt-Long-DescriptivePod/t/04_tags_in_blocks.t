#!perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    use_ok 'Getopt::Long::DescriptivePod';
}

throws_ok
    sub {
        replace_pod({
            filename          => \q{},
            tag               => '=head1 USAGE',
            before_code_block => "=t\n",
            code_block        => q{},
        });
    },
    qr{\A \QA Pod tag is not allowed in before_code_block at}xms,
    'before';

throws_ok
    sub {
        replace_pod({
            filename   => \q{},
            tag        => '=head1 USAGE',
            code_block => "=t\n",
        });
    },
    qr{\A \QA Pod tag is not allowed in code_block at}xms,
    'code';

throws_ok
    sub {
        replace_pod({
            filename         => \q{},
            tag              => '=head1 USAGE',
            code_block       => q{},
            after_code_block => "=t\n",
        });
    },
    qr{\A \QA Pod tag is not allowed in after_code_block at}xms,
    'after';
