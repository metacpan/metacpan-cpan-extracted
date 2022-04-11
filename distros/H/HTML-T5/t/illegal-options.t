#!perl -T

BEGIN
{
    $ENV{LC_ALL} = 'C';

    # See: https://github.com/shlomif/html-tidy5/issues/6
    $ENV{LANG} = 'en_US.UTF-8';
};


use 5.010001;
use strict;
use warnings;

use Test::Exception;
use Test::More;

use HTML::T5;

my @unsupported_options = qw(
    force-output
    gnu-emacs-file
    gnu-emacs
    keep-time
    quiet
    slide-style
    write-back
);

foreach my $option ( @unsupported_options ) {
    throws_ok {
        HTML::T5->new(
            {
                config_file => 't/cfg-for-parse.cfg',
                $option     => 1,
            },
        );
    } qr/\QUnsupported option: $option\E/,
    "option $option is not supported";
}

done_testing();
