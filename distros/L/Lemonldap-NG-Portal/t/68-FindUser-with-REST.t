use strict;
use IO::String;
use Test::More;
use lib 'inc';
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use JSON qw(to_json from_json);

BEGIN {
    require 't/test-lib.pm';
}

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#^http://ws/(search)#, 'search REST request' )
          or explain( $req->uri, 'http://ws/search' );
        count(1);
        my $type = $1;
        my $res  = from_json( $req->content );
        ok(
            $res->{excludingAttributes} eq
              '[{"type":"mutant"},{"uid":"rtyler"}]',
            ' [{"type":"mutant"},{"uid":"rtyler"}]'
        ) or explain( $res, 'type:mutant, uid:rtyler' );
        count(1);

        if ( $type eq 'search' ) {
            if ( $res->{searchingAttributes} eq '[{"uid":"dwho"}]' ) {
                ok( $res->{searchingAttributes} eq '[{"uid":"dwho"}]',
                    ' uid: dwho' );
                count(1);
                return [
                    200,
                    [ 'Content-Type' => 'application/json' ],
                    ['{"result":true,"users":["dwho"]}']
                ];
            }
            elsif ( $res->{searchingAttributes} eq
                '[{"guy":"bad"},{"uid":"dwho"}]' )
            {
                ok(
                    $res->{searchingAttributes} eq
                      '[{"guy":"bad"},{"uid":"dwho"}]',
                    ' guy:bad, uid: dwho'
                );
                count(1);
                return [
                    200,
                    [ 'Content-Type' => 'application/json' ],
                    ['{"result":0,"users":[]}']
                ];
            }
            elsif ( $res->{searchingAttributes} eq '[{"guy":"good"}]' ) {
                ok( $res->{searchingAttributes} eq '[{"guy":"good"}]',
                    ' guy:good' );
                count(1);
                return [
                    200,
                    [ 'Content-Type' => 'application/json' ],
                    ['{"result":true,"users":["dwho","rtyler","msmith"]}']
                ];
            }
            else { explain( $res, 'Bad searchingAttributes' ); count(1); }
        }
        else {
            fail('Unknwon URL');
            count(1);
        }
        return [ 500, [], [] ];
    }
);

my $res;
my $json;
my $request;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            authentication => 'Null',
            userDB         => 'REST',
            passwordDB     => 'Null',
            restUserDBUrl  => 'http://ws/search',

            #restFindUserDBUrl => 'http://ws/search',
            findUser                    => 1,
            impersonationRule           => 1,
            useSafeJail                 => 1,
            findUserSearchingAttributes =>
              { 'uid##1' => 'Login', 'guy##1' => 'Kind', 'cn##1' => 'Name' },
            findUserExcludingAttributes =>
              { type => 'mutant', uid => 'rtyler' },
        }
    }
);
use Lemonldap::NG::Portal::Main::Constants 'PE_USERNOTFOUND';

$request = 'uid=dwho';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post good FindUser request'
);
expectOK($res);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{user} eq 'dwho', ' Good user' )
  or explain( $json, "user => 'dwho'" );
ok( $json->{result} == 1, ' result => 1' )
  or explain( $json, 'Result => 1' );
count(4);

$request = 'guy=bad&uid=dwho';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post null response FindUser request'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{result} == 0, ' Good result' )
  or explain( $json, 'result => 0' );
ok( $json->{error} == PE_USERNOTFOUND, ' No user found' )
  or explain( $json, 'error => 4' );
count(4);

$request = 'other=dwho';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post bad parameter FindUser request'
);
expectOK($res);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{user} eq '', ' Empty user' )
  or explain( $json, "user => ''" );
ok( $json->{result} == 1, ' result => 1' )
  or explain( $json, 'Result => 1' );
count(4);

$request = '';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post empty response FindUser request'
);
expectOK($res);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{user} eq '', ' Empty user' )
  or explain( $json, "user => ''" );
ok( $json->{result} == 1, ' result => 1' )
  or explain( $json, 'Result => 1' );
count(4);

$request = 'guy=good';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post multi responses FindUser request'
);
expectOK($res);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{user} =~ /^(dwho|rtyler|msmith)$/, " Good user ($1)" )
  or explain( $json, "user => ?" );
ok( $json->{result} == 1, ' result => 1' )
  or explain( $json, 'Result => 1' );
count(4);

done_testing( count() );

