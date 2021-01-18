use Test::More;
use strict;
use IO::String;
use MIME::Base64;
use JSON qw/to_json/;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                        => 'error',
            useSafeJail                     => 1,
            issuerDBOpenIDConnectActivation => 1,
            multiValuesSeparator            => ";"
        }
    }
);

my $oidc =
  $client->p->loadedModules->{'Lemonldap::NG::Portal::Issuer::OpenIDConnect'};

my $tests = [

    # Auto array
    [ [ undef,     "string", "auto" ], '{"key":null}' ],
    [ [ "",        "string", "auto" ], '{"key":null}' ],
    [ [ "foo",     "string", "auto" ], '{"key":"foo"}' ],
    [ [ "foo;bar", "string", "auto" ], '{"key":["foo","bar"]}' ],
    [ [ undef,     "int",    "auto" ], '{"key":null}' ],
    [ [ "",        "int",    "auto" ], '{"key":null}' ],
    [ [ "0",       "int",    "auto" ], '{"key":0}' ],
    [ [ "0;1;2;3", "int",    "auto" ], '{"key":[0,1,2,3]}' ],
    [ [ undef,     "bool",   "auto" ], '{"key":null}' ],
    [ [ "",        "bool",   "auto" ], '{"key":null}' ],
    [ [ "0",       "bool",   "auto" ], '{"key":false}' ],
    [ [ "1",       "bool",   "auto" ], '{"key":true}' ],
    [ [ "0;1;;3",  "bool",   "auto" ], '{"key":[false,true,false,true]}' ],

    # Always array
    [ [ undef,     "string", "always" ], '{"key":null}' ],
    [ [ "",        "string", "always" ], '{"key":null}' ],
    [ [ "foo",     "string", "always" ], '{"key":["foo"]}' ],
    [ [ "foo;bar", "string", "always" ], '{"key":["foo","bar"]}' ],
    [ [ undef,     "int",    "always" ], '{"key":null}' ],
    [ [ "",        "int",    "always" ], '{"key":null}' ],
    [ [ "0",       "int",    "always" ], '{"key":[0]}' ],
    [ [ "0;1;2;3", "int",    "always" ], '{"key":[0,1,2,3]}' ],
    [ [ undef,     "bool",   "always" ], '{"key":null}' ],
    [ [ "",        "bool",   "always" ], '{"key":null}' ],
    [ [ "0",       "bool",   "always" ], '{"key":[false]}' ],
    [ [ "1",       "bool",   "always" ], '{"key":[true]}' ],
    [ [ "0;1;;3",  "bool",   "always" ], '{"key":[false,true,false,true]}' ],

    # Never array
    [ [ undef,     "string", "never" ], '{"key":null}' ],
    [ [ "",        "string", "never" ], '{"key":null}' ],
    [ [ "foo",     "string", "never" ], '{"key":"foo"}' ],
    [ [ "foo;bar", "string", "never" ], '{"key":"foo;bar"}' ],
    [ [ undef,     "int",    "never" ], '{"key":null}' ],
    [ [ "",        "int",    "never" ], '{"key":null}' ],
    [ [ "0",       "int",    "never" ], '{"key":0}' ],
    [ [ "0;1;2;3", "int",    "never" ], '{"key":"0;1;2;3"}' ],
    [ [ undef,     "bool",   "never" ], '{"key":null}' ],
    [ [ "",        "bool",   "never" ], '{"key":null}' ],
    [ [ "0",       "bool",   "never" ], '{"key":false}' ],
    [ [ "1",       "bool",   "never" ], '{"key":true}' ],
    [ [ "0;1;;3",  "bool",   "never" ], '{"key":"0;1;;3"}' ],
];

for my $test ( @{$tests} ) {
    my @args   = @{ $test->[0] };
    my $expect = $test->[1];
    is( to_json( { key => $oidc->_formatValue( @args, "key", "foo" ) } ),
        $expect, "_formatvalue(" . join( ', ', map { "'$_'" } @args ) . ")" );
}

done_testing();
