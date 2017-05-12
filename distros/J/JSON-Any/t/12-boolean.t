use strict;
use warnings;

use Test::More;
use Test::Fatal;
use JSON::Any;

# JSON::Syck doesn't support bools
my @backends = qw(CPANEL XS JSON DWIW);

# make sure we test the JSON::PP backend instead of XS, twice
$ENV{PERL_JSON_BACKEND} = 0;

# we are intentionally counting our tests here, to be safe
plan tests => @backends * 2 * 4;

test ($_) for @backends;

{
    package Boolean;
    sub true { 1 }
    sub false { '' }
}

sub test {
    my ($backend) = @_;

    SKIP: {
        my $j = eval {
            JSON::Any->import($backend);
            JSON::Any->new;
        };

        note("$backend: " . $@), skip("Backend $backend failed to load", 8) if $@;

        $j and $j->handler or next;

        note "handler is " . ( ref( $j->handler ) || $j->handlerType );

        for my $bool ( qw/true false/ ) {
            my $data;
            is(
                exception { $data = JSON::Any->jsonToObj($bool) },
                undef,
                "inflated '$bool'",
            );

            ok( ($data xor !Boolean->$bool), "$bool evaluates to $bool" );

            is(
                exception { $data = JSON::Any->$bool },
                undef,
                "JSON::Any->$bool returned a value",
            );

            ok( ($data xor !Boolean->$bool), "JSON::Any->$bool evaluates to $bool" );
        }
    };
}
