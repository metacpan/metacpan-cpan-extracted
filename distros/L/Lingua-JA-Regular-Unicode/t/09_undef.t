use strict;
use warnings;
use utf8;
use Test::More;
use Lingua::JA::Regular::Unicode;

for (@Lingua::JA::Regular::Unicode::EXPORT) {
    subtest $_ => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, shift };
        is(Lingua::JA::Regular::Unicode->can($_)->(undef), undef);
        is(0+@warnings, 0, 'No warnings');
    };
}

done_testing;

