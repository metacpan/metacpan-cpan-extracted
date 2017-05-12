use strict;
use warnings;
use utf8;
use Test::More;
use File::Zglob;

*gpp = *File::Zglob::glob_prepare_pattern;

local $File::Zglob::NOCASE = 0; # case sensitive to pass tests.

subtest 'normal' => sub {
    my @patterns = (
        '**/*'  => [ \0, [ \"**", qr{^(?=[^\.])[^/]*$} ] ],
        ".*"    => [ \0, [qr{^\.[^/]*$}] ],
        '/home' => [ \1, [qr{^(?=[^\.])home$}] ],
    );
    for (my $i=0; $i<@patterns; $i+=2) {
        is_deeply([gpp($patterns[$i])], $patterns[$i+1], $patterns[$i]);
    }
};

done_testing;

