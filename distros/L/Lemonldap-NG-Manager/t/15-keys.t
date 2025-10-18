# Verify that bas changes are detected

use warnings;
use Test::More;
use strict;
use JSON;
require 't/test-lib.pm';

my $struct = 't/jsonfiles/01-base-tree.json';

sub conf_with_key_nodes {
    my ($keynodes) = @_;
    return get_conf_body_from_fixture(
        't/jsonfiles/01-base-tree.json',
        sub {
            my $data = shift;
            splice( @$data, -1, 0, $keynodes );
        }
    );
}

subtest "Add key to base conf" => sub {
    my ( $len, $body ) = conf_with_key_nodes( {
            "help"  => "keys.html",
            "id"    => "keyNodes",
            "nodes" => [ {
                    "id"    => "keyNodes/abc",
                    "nodes" => [ {
                            "data" => [ {
                                    "data"  => "pv",
                                    "get"   => "keyNodes/abc/keyPrivate",
                                    "id"    => "keyNodes/abc/keyPrivate",
                                    "title" => "keyPrivate"
                                },
                                {
                                    "data"  => "pass",
                                    "get"   => "keyNodes/abc/keyPrivatePwd",
                                    "id"    => "keyNodes/abc/keyPrivatePwd",
                                    "title" => "keyPrivatePwd"
                                },
                                {
                                    "data"  => "pub",
                                    "get"   => "keyNodes/abc/keyPublic",
                                    "id"    => "keyNodes/abc/keyPublic",
                                    "title" => "keyPublic"
                                }
                            ],
                            "get" => [
                                "keyNodes/abc/keyPrivate",
                                "keyNodes/abc/keyPrivatePwd",
                                "keyNodes/abc/keyPublic"
                            ],
                            "id"    => "keyNodes/abc/KeyMaterial",
                            "title" => "KeyMaterial",
                            "type"  => "RSACertKey"
                        },
                        {
                            "help"  => "keys.html#options",
                            "id"    => "keyOptions",
                            "nodes" => [ {
                                    "data"  => "aaazz",
                                    "get"   => "keyNodes/abc/keyId",
                                    "id"    => "keyNodes/abc/keyId",
                                    "title" => "keyId"
                                },
                                {
                                    "data"  => "mycomment",
                                    "get"   => "keyNodes/abc/keyComment",
                                    "id"    => "keyNodes/abc/keyComment",
                                    "title" => "keyComment",
                                }
                            ],
                            "title" => "keyOptions",
                            "type"  => "simpleInputContainer"
                        }
                    ],
                    "template" => "keyNode",
                    "title"    => "abc",
                    "type"     => "keyNode"
                }
            ],
            "template" => "key",
            "title"    => "keyNodes",
            "type"     => "keyNodeContainer"
        }
    );

    my ( $res, $resBody );
    ok(
        $res = &client->_post(
            '/confs/', 'cfgNum=1', $body, 'application/json', $len
        ),
        "Request succeed"
    );
    ok( $res->[0] == 200, "Result code is 200" );
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "Result body contains JSON text"
    );
    ok( $resBody->{result} == 1, "JSON response contains \"result:1\"" )
      or print STDERR Dumper($res);

    ok( $res = &client->_get( '/confs/latest', 'full=1' ), 'Get saved conf' );
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "Result body contains JSON text"
    );
    is( $resBody->{cfgNum}, 2, "New config was saved" );

    is_deeply(
        $resBody->{keys},
        {
            'abc' => {
                'keyPrivate'    => 'pv',
                'keyPrivatePwd' => 'pass',
                'keyPublic'     => 'pub',
                'keyId'         => 'aaazz',
                'keyComment'    => 'mycomment',
            }
        }
    );
};

subtest "Posting the same config does not trigger a save" => sub {
    my ( $len, $body ) = conf_with_key_nodes( {
            "help"  => "keys.html",
            "id"    => "keyNodes",
            "nodes" => [ {
                    "id"    => "keyNodes/abc",
                    "nodes" => [ {
                            "data" => [ {
                                    "data"  => "pv",
                                    "get"   => "keyNodes/abc/keyPrivate",
                                    "id"    => "keyNodes/abc/keyPrivate",
                                    "title" => "keyPrivate"
                                },
                                {
                                    "data"  => "pass",
                                    "get"   => "keyNodes/abc/keyPrivatePwd",
                                    "id"    => "keyNodes/abc/keyPrivatePwd",
                                    "title" => "keyPrivatePwd"
                                },
                                {
                                    "data"  => "pub",
                                    "get"   => "keyNodes/abc/keyPublic",
                                    "id"    => "keyNodes/abc/keyPublic",
                                    "title" => "keyPublic"
                                }
                            ],
                            "get" => [
                                "keyNodes/abc/keyPrivate",
                                "keyNodes/abc/keyPrivatePwd",
                                "keyNodes/abc/keyPublic"
                            ],
                            "id"    => "keyNodes/abc/KeyMaterial",
                            "title" => "KeyMaterial",
                            "type"  => "RSACertKey"
                        },
                        {
                            "help"  => "keys.html#options",
                            "id"    => "keyOptions",
                            "nodes" => [ {
                                    "data"  => "aaazz",
                                    "get"   => "keyNodes/abc/keyId",
                                    "id"    => "keyNodes/abc/keyId",
                                    "title" => "keyId"
                                },
                                {
                                    "data"  => 'mycomment',
                                    "get"   => "keyNodes/abc/keyComment",
                                    "id"    => "keyNodes/abc/keyComment",
                                    "title" => "keyComment",
                                }
                            ],
                            "title" => "keyOptions",
                            "type"  => "simpleInputContainer"
                        }
                    ],
                    "template" => "keyNode",
                    "title"    => "abc",
                    "type"     => "keyNode"
                }
            ],
            "template" => "key",
            "title"    => "keyNodes",
            "type"     => "keyNodeContainer"
        }
    );

    my ( $res, $resBody );
    ok(
        $res = &client->_post(
            '/confs/', 'cfgNum=2', $body, 'application/json', $len
        ),
        "Request succeed"
    );
    ok( $res->[0] == 200, "Result code is 200" );
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "Result body contains JSON text"
    );
    is( $resBody->{result},  0,                    "No save was done" );
    is( $resBody->{message}, '__confNotChanged__', "Correct message" );

    ok( $res = &client->_get( '/confs/latest', 'full=1' ), 'Get saved conf' );
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "Result body contains JSON text"
    );
    is( $resBody->{cfgNum}, 2, "New config was not saved" );

    is_deeply(
        $resBody->{keys},
        {
            'abc' => {
                'keyPrivate'    => 'pv',
                'keyPrivatePwd' => 'pass',
                'keyPublic'     => 'pub',
                'keyId'         => 'aaazz',
                'keyComment'    => 'mycomment',
            }
        }
    );
};

subtest "Add one more key" => sub {
    my ( $len, $body ) = conf_with_key_nodes( {
            "help"  => "keys.html",
            "id"    => "keyNodes",
            "nodes" => [ {
                    "_nodes" => [ {
                            "get" => [
                                "keyNodes/abc/keyPrivate",
                                "keyNodes/abc/keyPrivatePwd",
                                "keyNodes/abc/keyPublic"
                            ],
                            "id"    => "keyNodes/abc/KeyMaterial",
                            "title" => "KeyMaterial",
                            "type"  => "RSACertKey"
                        },
                        {
                            "_nodes" => [ {
                                    "get"   => "keyNodes/abc/keyId",
                                    "id"    => "keyNodes/abc/keyId",
                                    "title" => "keyId"
                                },
                                {
                                    "get"   => "keyNodes/abc/keyComment",
                                    "id"    => "keyNodes/abc/keyComment",
                                    "title" => "keyComment",
                                }
                            ],
                            "help"  => "keys.html#options",
                            "id"    => "keyOptions",
                            "title" => "keyOptions",
                            "type"  => "simpleInputContainer"
                        }
                    ],
                    "id"       => "keyNodes/abc",
                    "template" => "keyNode",
                    "title"    => "abc",
                    "type"     => "keyNode"
                },
                {
                    "id"    => "keyNodes/new__key3",
                    "nodes" => [ {
                            "data" => [ {
                                    "data"  => "pv2",
                                    "get"   => "keyNodes/new__key3/keyPrivate",
                                    "id"    => "keyNodes/new__key3/keyPrivate",
                                    "title" => "keyPrivate"
                                },
                                {
                                    "get" => "keyNodes/new__key3/keyPrivatePwd",
                                    "id"  => "keyNodes/new__key3/keyPrivatePwd",
                                    "title" => "keyPrivatePwd"
                                },
                                {
                                    "data"  => "pub2",
                                    "get"   => "keyNodes/new__key3/keyPublic",
                                    "id"    => "keyNodes/new__key3/keyPublic",
                                    "title" => "keyPublic"
                                }
                            ],
                            "get" => [
                                "keyNodes/new__key3/keyPrivate",
                                "keyNodes/new__key3/keyPrivatePwd",
                                "keyNodes/new__key3/keyPublic"
                            ],
                            "id"    => "keyNodes/new__key3/KeyMaterial",
                            "title" => "KeyMaterial",
                            "type"  => "RSACertKey"
                        },
                        {
                            "help"  => "keys.html#options",
                            "id"    => "keyOptions",
                            "nodes" => [ {
                                    "data"  => "k3",
                                    "get"   => "keyNodes/new__key3/keyId",
                                    "id"    => "keyNodes/new__key3/keyId",
                                    "title" => "keyId"
                                },
                                {
                                    "get"   => "keyNodes/new__key3/keyComment",
                                    "id"    => "keyNodes/new__key3/keyComment",
                                    "title" => "keyComment",
                                }
                            ],
                            "title" => "keyOptions",
                            "type"  => "simpleInputContainer"
                        }
                    ],
                    "title" => "key3",
                    "type"  => "keyNode"
                }
            ],
            "template" => "key",
            "title"    => "keyNodes",
            "type"     => "keyNodeContainer"
        },
    );

    my ( $res, $resBody );
    ok(
        $res = &client->_post(
            '/confs/', 'cfgNum=2', $body, 'application/json', $len
        ),
        "Request succeed"
    );
    ok( $res->[0] == 200, "Result code is 200" );
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "Result body contains JSON text"
    );
    ok( $resBody->{result} == 1, "JSON response contains \"result:1\"" )
      or print STDERR Dumper($res);

    ok( $res = &client->_get( '/confs/latest', 'full=1' ), 'Get saved conf' );
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "Result body contains JSON text"
    );
    is( $resBody->{cfgNum}, 3, "New config was saved" );

    is_deeply(
        $resBody->{keys},
        {
            'abc' => {
                'keyPrivate'    => 'pv',
                'keyPrivatePwd' => 'pass',
                'keyPublic'     => 'pub',
                'keyId'         => 'aaazz',
                'keyComment'    => 'mycomment',
            },
            'key3' => {
                'keyId'      => 'k3',
                'keyPrivate' => 'pv2',
                'keyPublic'  => 'pub2'
            }
        }
    );
};

subtest "Test REST server" => sub {
    my ( $res, $resBody );
    ok( $res = &client->_get('/confs/latest/keyNodes/abc/keyPrivatePwd'),
        "Request succeed" );
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "Result body contains JSON text"
    );
    is( $resBody->{value}, "pass" );

    ok( $res = &client->_get('/confs/latest/keyNodes/key3/keyId'),
        "Request succeed" );
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "Result body contains JSON text"
    );
    is( $resBody->{value}, "k3" );
};

subtest "Delete one key" => sub {
    my ( $len, $body ) = conf_with_key_nodes( {
            "help"  => "keys.html",
            "id"    => "keyNodes",
            "nodes" => [ {
                    "_nodes" => [ {
                            "get" => [
                                "keyNodes/abc/keyPrivate",
                                "keyNodes/abc/keyPrivatePwd",
                                "keyNodes/abc/keyPublic"
                            ],
                            "id"    => "keyNodes/abc/KeyMaterial",
                            "title" => "KeyMaterial",
                            "type"  => "RSACertKey"
                        },
                        {
                            "_nodes" => [ {
                                    "get"   => "keyNodes/abc/keyId",
                                    "id"    => "keyNodes/abc/keyId",
                                    "title" => "keyId"
                                },
                                {
                                    "get"   => "keyNodes/abc/keyComment",
                                    "id"    => "keyNodes/abc/keyComment",
                                    "title" => "keyComment",
                                }
                            ],
                            "help"  => "keys.html#options",
                            "id"    => "keyOptions",
                            "title" => "keyOptions",
                            "type"  => "simpleInputContainer"
                        }
                    ],
                    "id"       => "keyNodes/abc",
                    "template" => "keyNode",
                    "title"    => "abc",
                    "type"     => "keyNode"
                },
            ],
            "template" => "key",
            "title"    => "keyNodes",
            "type"     => "keyNodeContainer"
        },
    );

    my ( $res, $resBody );
    ok(
        $res = &client->_post(
            '/confs/', 'cfgNum=3', $body, 'application/json', $len
        ),
        "Request succeed"
    );
    ok( $res->[0] == 200, "Result code is 200" );
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "Result body contains JSON text"
    );
    ok( $resBody->{result} == 1, "JSON response contains \"result:1\"" )
      or print STDERR Dumper($res);

    ok( $res = &client->_get( '/confs/latest', 'full=1' ), 'Get saved conf' );
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "Result body contains JSON text"
    );
    is( $resBody->{cfgNum}, 4, "New config was saved" );

    is_deeply(
        $resBody->{keys},
        {
            'abc' => {
                'keyPrivate'    => 'pv',
                'keyPrivatePwd' => 'pass',
                'keyPublic'     => 'pub',
                'keyId'         => 'aaazz',
                'keyComment'    => 'mycomment',
            },
        }
    );
};

subtest "Empty keyNodes deletes all keys" => sub {
    my ( $len, $body ) = conf_with_key_nodes( {
            "help"     => "keys.html",
            "id"       => "keyNodes",
            "nodes"    => [],
            "template" => "key",
            "title"    => "keyNodes",
            "type"     => "keyNodeContainer"
        }
    );

    my ( $res, $resBody );
    ok(
        $res = &client->_post(
            '/confs/', 'cfgNum=4', $body, 'application/json', $len
        ),
        "Request succeed"
    );
    ok( $res->[0] == 200, "Result code is 200" );
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "Result body contains JSON text"
    );
    ok( $resBody->{result} == 1, "JSON response contains \"result:1\"" )
      or print STDERR Dumper($res);

    ok( $res = &client->_get( '/confs/latest', 'full=1' ), 'Get saved conf' );
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "Result body contains JSON text"
    );
    is( $resBody->{cfgNum}, 5, "New config was saved" );

    is_deeply( $resBody->{keys}, {} );
};

done_testing();
