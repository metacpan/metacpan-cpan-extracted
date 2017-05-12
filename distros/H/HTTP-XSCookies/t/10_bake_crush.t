use strict;
use warnings;

use Test::More;
use HTTP::XSCookies qw[crush_cookie bake_cookie];

my @cookie_list = (
    {
        string => 'foo=bar; Path=/',
        name => 'foo',
        fields => {
            'value' => 'bar',
            'Path' => '/',
        },
    },
    {
        string => 'whv=MtW_XszVxqHnN6rHsX0d; Expires=Sun, 10-Jan-2016 18:19:29 GMT; Domain=.wikihow.com; Path=',
        name => 'whv',
        fields => {
            'value' => 'MtW_XszVxqHnN6rHsX0d',
            'Expires' => '1452449969',
            'Domain' => '.wikihow.com',
            'Path' => '',
        },
        expires => 'Sun, 10-Jan-2016 18:19:29 GMT',
    },
    {
        string => 'name=Gandalf; Path=/tmp/foo; Path=/tmp/bar',
        name => 'name',
        fields => {
            'value' => 'Gandalf',
            'Path' => '/tmp/foo',
        },
        result => 'name=Gandalf; Path=/tmp/foo',
    },
    {
        string => 'Bilbo%26Frodo=Foo%20Bar; Path=%2bMERRY%2b;',
        name => 'Bilbo&Frodo',
        fields => {
            'value' => 'Foo Bar',
            'Path'  => '+MERRY+',
        },
        # I would have expected the value of path should be URL encoded
        # however other tests from Cookie::Baker(::XS)? seem to state
        # this is not the case...
        result => 'Bilbo%26Frodo=Foo%20Bar; Path=+MERRY+',
    },
    {
        # Test case reported by Peter Mottram
        string => 'cookie.a=foo=bar; cookie.b=1234abcd; no.value.cookie',
        name => 'cookie.a',
        fields => {
            'value' => 'foo=bar',
            'cookie.b' => '1234abcd',
        },
        result => 'cookie.a=foo%3dbar',
    },
    {
        # SameSite
        string => 'foo=bar; SameSite=strict',
        name => 'foo',
        fields => {
            'value' => 'bar',
            'SameSite' => 'strict',
        },
        result => 'foo=bar; SameSite=strict',
    }
);

exit main();

sub main {
    test_crush_cookie();
    test_bake_cookie();

    done_testing();
    return 0;
}

sub test_crush_cookie {
    for my $cookie (@cookie_list) {
        my $crushed = crush_cookie($cookie->{string});
        for my $key (keys %$crushed) {
            my $k = $key eq $cookie->{name} ? 'value' : $key;
            my $v = $key eq 'Expires' ? $cookie->{expires} : $cookie->{fields}{$k};
            is($crushed->{$key}, $v, 'crush1-' . $key);
        }
        for my $key (keys %{$cookie->{fields}}) {
            my $k = $key eq 'value' ? $cookie->{name} : $key;
            my $v = $key eq 'Expires' ? $cookie->{expires} : $cookie->{fields}{$key};
            is($v, $crushed->{$k}, 'crush2-' . $key);
        }
    }
}

sub test_bake_cookie {
    for my $cookie (@cookie_list) {
        my $c = _sort_cookie(bake_cookie($cookie->{name}, $cookie->{fields}));
        my $result = $cookie->{result} // _sort_cookie($cookie->{string});
        is($c, $result, 'bake ' . $cookie->{name});
    }
}

sub _sort_cookie {
    my ($cookie) = @_;

    my $name;
    my $value;
    my %data;
    my $first = 1;
    my @pairs = split(/;[ \t]*/, $cookie);
    for my $pair (@pairs) {
        my ($k, $v) = split('=', $pair);
        if ($first) {
            $name = $k;
            $value = $v;
            $first = 0;
            next;
        }
        $data{$k} = $v;
    }

    $cookie = sprintf("%s=%s", $name, $value);
    for my $k (sort keys %data) {
        $cookie .= sprintf("; %s=%s", $k, $data{$k});
    }

    return $cookie;
}
