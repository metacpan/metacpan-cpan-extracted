#!perl -w

use strict;
use warnings;

use Test::More tests => 2;
my @warns;
BEGIN {
    $SIG{__WARN__} = sub { push @warns, @_ };
}

use Encode::Locale;

BEGIN {
    use Encode;
    my $a = encode("UTF-8", "foo\xFF");
    ok $a, "foo\xC3\xBF";
}

is "@warns", "", 'no warnings';
