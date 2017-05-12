# -*- mode: Perl; -*-
package UriTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::Exception;
use Test::More;

use Eve::Uri;

sub test_to_string : Test(3) {
    my $uri_string_hash = {
        'http://domain.com/path/script?foo=%2FBar' =>
            'http://domain.com/path/script?foo=%2FBar',
        'HTTP://AnotherDomain.com:80/AnotherScript?baz=%7fBam' =>
            'http://anotherdomain.com/AnotherScript?baz=%7FBam',
        'http://domain.com/:place/:holder' =>
            'http://domain.com/:place/:holder'};

    for my $key_uri (keys %{$uri_string_hash}) {
        my $uri  = Eve::Uri->new(string => $key_uri);
        is($uri->string, $uri_string_hash->{$key_uri});
    }
}

sub test_query : Test(4) {
    my $uri_string_hash = {
        'http://domain.com/with?query=string' =>
            'query=string',
        'http://domain.com/with?another=query&string=1' =>
            'another=query&string=1'};

    my $uri = Eve::Uri->new(string => 'http://domain.com/with');
    for my $uri_string (keys %{$uri_string_hash}) {
        $uri->query = $uri_string_hash->{$uri_string};
        is($uri->string, $uri_string);
    }

    for my $uri_string (keys %{$uri_string_hash}) {
        $uri = Eve::Uri->new(string => $uri_string);
        is($uri->query, $uri_string_hash->{$uri_string});
    }
}

sub test_host : Test(4) {
    my $uri_string_hash = {
        'http://some_domain.com/with/path' => 'some_domain.com',
        'http://other_domain.com/with/path' => 'other_domain.com'};

    my $uri = Eve::Uri->new(string => 'http://domain.com/with/path');
    for my $uri_string (keys %{$uri_string_hash}) {
        $uri->host = $uri_string_hash->{$uri_string};
        is($uri->string, $uri_string);
    }

    for my $uri_string (keys %{$uri_string_hash}) {
        $uri = Eve::Uri->new(string => $uri_string);
        is($uri->host, $uri_string_hash->{$uri_string});
    }
}

sub test_set_query_parameter : Test(3) {
    my $uri_string = 'http://domain.com/with?initial=value';
    my $uri_string_hash = {
        'http://domain.com/with?query=string&with=parameters' => {
            'initial' => undef,
            'query' => 'string',
            'with' => 'parameters'},
        'http://domain.com/with?initial=value&another=query&string=1' => {
            'another' => 'query',
            'string' => '1'},
        'http://domain.com/with?initial=value&list=1&list=2&list=3' => {
            'list' => [1, 2, 3]}};

    for my $result_uri_string (keys %{$uri_string_hash}) {
        my $uri = Eve::Uri->new(string => $uri_string);

        for my $parameter_name (
            keys %{$uri_string_hash->{$result_uri_string}}) {
            $uri->set_query_parameter(
                name => $parameter_name,
                value => $uri_string_hash->{$result_uri_string}
                    ->{$parameter_name});

        }
        is($uri->string, $result_uri_string);
    }
}

sub test_get_query_parameter_list : Test(2) {
    my $uri_string_hash = {
        'http://domain.com/with?list=1&list=2&list=3' => {
            'list' => ['1', '2', '3']},
        'http://domain.com/with?list2=a&list2=b&list2=c&other=doh' => {
            'list2' => ['a', 'b', 'c']}};

    for my $uri_string (keys %{$uri_string_hash}) {
        my $uri = Eve::Uri->new(string => $uri_string);

        for my $parameter_name (keys %{$uri_string_hash->{$uri_string}}) {
            my $value = $uri_string_hash->{$uri_string}->{$parameter_name};

            is_deeply(
                [$uri->get_query_parameter(name => $parameter_name)],
                $value);
        }
    }
}

sub test_get_query_parameter : Test(4) {
    my $uri_string_hash = {
        'http://domain.com/with?query=string&with=parameters' => {
            'query' => 'string',
            'with' => 'parameters'},
        'http://domain.com/with?another=query&string=1' => {
            'another' => 'query',
            'string' => '1'}};

    for my $uri_string (keys %{$uri_string_hash}) {
        my $uri = Eve::Uri->new(string => $uri_string);

        for my $parameter_name (keys %{$uri_string_hash->{$uri_string}}) {
            my $value = $uri_string_hash->{$uri_string}->{$parameter_name};

            is_deeply(
                $uri->get_query_parameter(name => $parameter_name),
                $value);
        }
    }
}

sub test_set_query_hash : Test(3) {
    my $uri_string = 'http://domain.com/with';
    my $uri_string_hash = {
        'http://domain.com/with?query=string;with=parameters' => {
            'hash' => {
                'query' => 'string',
                'with' => 'parameters'},
            'delimiter' => ';'},
        'http://domain.com/with?another=query&string=1' => {
            'hash' => {
                'another' => 'query',
                'string' => '1'}},
        'http://domain.com/with?list=1+list=2+list=3' => {
            'hash' => {
                'list' => [1, 2, 3]},
            'delimiter' => '+'}};

    for my $result_uri_string (keys %{$uri_string_hash}) {
        my $uri = Eve::Uri->new(string => $uri_string);

        $uri->set_query_hash(%{$uri_string_hash->{$result_uri_string}});

        is($uri->string, $result_uri_string);
    }
}

sub test_get_query_hash : Test(2) {
    my $uri_string_hash = {
        'http://domain.com/with?var=1&foo=2&bar=3' => {
            'var' => '1', 'foo' => '2', 'bar' => '3'},
        'http://domain.com/with?some=a&other=b&var=c' => {
            'some' => 'a', 'other' => 'b', 'var' => 'c'}};

    for my $uri_string (keys %{$uri_string_hash}) {
        my $uri = Eve::Uri->new(string => $uri_string);

        is_deeply($uri->get_query_hash(), $uri_string_hash->{$uri_string});
    }
}

sub test_fragment : Test(4) {
    my $uri_string_hash = {
        'http://domain.com/with#fragment' =>
            'fragment',
        'http://domain.com/with#another_fragment' =>
            'another_fragment'
    };

    my $uri = Eve::Uri->new(string => 'http://domain.com/with');
    for my $uri_string (keys %{$uri_string_hash}) {
        $uri->fragment = $uri_string_hash->{$uri_string};
        is($uri->string, $uri_string);
    }

    for my $uri_string (keys %{$uri_string_hash}) {
        $uri = Eve::Uri->new(string => $uri_string);
        is($uri->fragment, $uri_string_hash->{$uri_string});
    }
}

sub test_path : Test(4) {
    my $uri_string_hash = {
        'http://domain.com/with/path' =>
            '/with/path',
        'http://domain.com/with/another/path' =>
            '/with/another/path'
    };

    my $uri = Eve::Uri->new(string => 'http://domain.com');
    for my $uri_string (keys %{$uri_string_hash}) {
        $uri->path = $uri_string_hash->{$uri_string};
        is($uri->string, $uri_string);
    }

    for my $uri_string (keys %{$uri_string_hash}) {
        $uri = Eve::Uri->new(string => $uri_string);
        is($uri->path, $uri_string_hash->{$uri_string});
    }
}

sub test_string : Test(2) {
    my $uri_string_list = [
        'http://another.domain.com/with#fragment',
        'http://yet.another.domain.com/with?query=string'];

    my $uri = Eve::Uri->new(string => 'http://domain.com/with');
    for my $uri_string (@{$uri_string_list}) {
        $uri->string = $uri_string;
        is($uri->string, $uri_string);
    }
}

sub test_match : Test(8) {
    my $uri_hash = {
        'http://domain.com/:place/:holder' => {
            'http://domain.com/substi/tution' => {
                'place' => 'substi', 'holder' => 'tution'},
            'http://domain.com/some/thing' => {
                'place' => 'some', 'holder' => 'thing'},
            'http://domain.com/not/matching/one' => undef,
        },
        'http://domain.com/without/placeholder' => {
            'http://domain.com/without/placeholder' => {},
            'http://domain.com/not/matching/again' => undef,
            'http://domain.com/without/placeholder?with=query&string=1' => {},
        },
        'http://domain.com/with?query=string' => {
            'http://domain.com/with' => {},
            'http://domain.com/with?another=query&string=1' => {},
        },
    };

    for my $uri_pattern_string (keys %{$uri_hash}) {
        my $uri_pattern  = Eve::Uri->new(string => $uri_pattern_string);

        for my $uri_string (keys %{$uri_hash->{$uri_pattern_string}}) {
            my $uri = Eve::Uri->new(string => $uri_string);
            is_deeply(
                $uri_pattern->match(uri => $uri),
                $uri_hash->{$uri_pattern_string}->{$uri_string});
        }
    }
}

sub test_clone : Test(2) {
    my $uri = Eve::Uri->new(string => 'http://www.domain.com/path');
    my $uri_clone = $uri->clone();

    isnt($uri, $uri_clone);
    is($uri_clone->string, 'http://www.domain.com/path');
}

sub test_path_concat : Test(2) {
    my $uri_string_hash = {
        '/another/path' => 'http://www.domain.com/path/another/path',
        '/yet/another/path' => 'http://www.domain.com/path/yet/another/path'
    };

    for my $path_string (keys %{$uri_string_hash}) {
        my $uri = Eve::Uri->new(string => 'http://www.domain.com/path');
        $uri->path_concat(string => $path_string);
        is($uri->string, $uri_string_hash->{$path_string});
    }
}

sub test_substitute : Test(6) {
    my $data_hash = {
        'http://domain.com/nothing' => {
            'hash' => {},
            'result' => 'http://domain.com/nothing'
        },
        'http://domain.com/:some' => {
            'hash' => { 'some' => 'thing' },
            'result' => 'http://domain.com/thing'
        },
        'http://domain.com/:place/:holder' => {
            'hash' => { 'place' => 'ta', 'holder' => 'dam' },
            'result' => 'http://domain.com/ta/dam'
        }
    };

    for my $string (keys %{$data_hash}) {
        my $uri = Eve::Uri->new(string => $string);
        my $resulting_uri = $uri->substitute(
            hash => $data_hash->{$string}->{'hash'});
        is($resulting_uri->string, $data_hash->{$string}->{'result'});
        isnt($uri, $resulting_uri);
    }
}

sub test_substitute_not_enough : Test(2) {
    my $uri = Eve::Uri->new(string => 'http://doman.com/:not/:only/:one');

    throws_ok(
        sub {
            $uri->substitute(hash => { 'only' => 'this' });
        },
        'Eve::Error::Value');
    ok(Eve::Error::Value->caught()->message =~
       qr/Not enough substitutions are specified/);
}

sub test_substitute_redundant : Test(2) {
    my $uri = Eve::Uri->new(string => 'http://doman.com/:along');

    throws_ok(
        sub {
            $uri->substitute(hash => { 'iam' => 'not', 'along' => 'here' });
        },
        'Eve::Error::Value');
    ok(Eve::Error::Value->caught()->message =~
       qr/Redundant substitutions are specified/);
}

sub test_is_relative : Test(5) {
    my $data_hash = {
        'http://domain.com/some/path' => 0,
        'http://another_domain.com/some/path' => 0,
        '/some/relative/path' => 1,
        '/another/relative/path' => 1};

    for my $uri_string (keys %{$data_hash}) {
        my $uri = Eve::Uri->new(string => $uri_string);

        is($uri->is_relative(), $data_hash->{$uri_string}, $uri_string);
    }
}

1;
