#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 3;
use Test::Differences;
use Test::NoWarnings;

use Locale::Utils::Autotranslator;

my $auto_translator = Locale::Utils::Autotranslator->new(language => 'de');

eq_or_diff
    $auto_translator->with_lines(
        " \t foo \nb ä \t r\n \n baz \t ",
        sub {
            return "-$_-";
        },
    ),
    " \t -foo- \n-b ä r-\n \n -baz- \t ",
    'with_lines';
eq_or_diff
    $auto_translator->with_lines(
        "foo\r\nbär\r\nbaz",
        sub {
            return "-$_-";
        },
    ),
    "-foo-\r\n-bär-\r\n-baz-",
    'with_lines (network line endings)';
