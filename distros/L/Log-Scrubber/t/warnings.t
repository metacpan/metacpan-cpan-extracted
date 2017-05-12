#!/usr/bin/perl

# Test the warning:: overrides

use Test::More tests => 6;
use warnings;
use warnings::register;
use Log::Scrubber;

scrubber_init( {
    '\x1b' => '[esc]',
    '4007000000027' => 'X' x 13,
    '1234' => 'X' x 4,
} );

END { unlink "test.out"; }

sub _read
{
    open FILE, "test.out";
    my $ret = join('', <FILE>);
    close FILE;
    return $ret;
}

sub _setup
{
    open STDERR, ">test.out";
    select((select(STDERR), $|++)[0]);
}

my $tests = {
    "escape --> \x1b" => "escape --> [esc]",
    "escape --> 4007000000027" => "escape --> XXXXXXXXXXXXX",
    "escape --> 1234" => "escape --> XXXX",
};

foreach my $key ( keys %$tests ) {
    eval { 
        _setup;
        warnings::warn($key."\n");
    };

    my $result = _read;
    $result =~ s/\n.*$//s;
    is ($result, $tests->{$key}, "warnings::warn");

    eval { 
        _setup;
        warnings::warnif("void", $key."\n");
    };

    $result = _read;
    $result =~ s/\n.*$//s;
    is ($result, $tests->{$key}, "warnings::warnif");
}
