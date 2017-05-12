package TestOrdinal;

use strict;
use warnings;
use Test::More;
use Exporter 'import';
use Try::Tiny;
use Lingua::EN::Number::IsOrdinal ();

our @EXPORT_OK = qw/is_ordinal is_not_ordinal/;

sub is_ordinal {
    my $num = shift;

    try {
        my $test = Lingua::EN::Number::IsOrdinal::is_ordinal($num);

        local $Test::Builder::Level = $Test::Builder::Level + 3;

        ok($test, "'$num' is an ordinal number");
    }
    catch {
        local $Test::Builder::Level = $Test::Builder::Level + 3;

        fail "'$num' is not a number";
    };
}

sub is_not_ordinal {
    my $num = shift;

    try {
        my $test = !Lingua::EN::Number::IsOrdinal::is_ordinal($num);

        local $Test::Builder::Level = $Test::Builder::Level + 3;

        ok($test, "'$num' is NOT an ordinal number");
    }
    catch {
        local $Test::Builder::Level = $Test::Builder::Level + 3;

        fail "'$num' is not a number";
    };
}

1;
