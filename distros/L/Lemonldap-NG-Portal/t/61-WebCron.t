use warnings;
use Test::More;
use strict;
use IO::String;
use Time::Fake;

BEGIN {
    require 't/test-lib.pm';
}

my $client;
ok( (
        $client = LLNG::Manager::Test->new( {
                ini => {
                    authentication        => 'Demo',
                    userDB                => 'Same',
                    timeout               => 59,
                    webCronSecret         => 'secret',
                    oidcRPMetaDataOptions => {
                        rp => {
                            oidcRPMetaDataOptionsClientID   => 'rpid',
                            oidcRPMetaDataOptionsRtActivity => 3600,
                        },
                    },
                }
            }
        )
    ),
    'Able to load WebCron'
);

ok( $client->login('dwho') );
Time::Fake->offset('+1m');
ok( $client->login('dwho') );
&insertRt;
&insertRt(time);
&insertRt( time - 7200 );

ok( &sessionNumber == 5, '5 sessions in db' ) or explain( &sessionNumber, 4 );
my $res = $client->_post(
    '/webcron/purge',
    IO::String->new('secret=secret'),
    length => 13,
);
expectOK($res);
ok( &sessionNumber == 3, '3 sessions in db' ) or explain( &sessionNumber, 2 );

sub sessionNumber {
    my $r = 0;
    opendir D, $client->p->conf->{globalStorageOptions}->{Directory};
    while ( my $f = readdir D ) {
        next unless $f =~ /^[0-9a-f]{64}$/;
        $r++;
    }
    close D;
    return $r;
}

my $rtid = 0;

sub insertRt {
    my ($lastSeen) = @_;
    my $sid = ( 'a' x 63 ) . $rtid++;
    open F, '>', $client->p->conf->{globalStorageOptions}->{Directory} . "/$sid"
      or die $!;
    print F JSON::to_json( {
            _utime        => time + ( 86400 * 200 ),
            _session_kind => 'OIDCI',
            _type         => 'refresh_token',
            _session_uid  => 'dwho',
            _whatToTrace  => 'dwho',
            client_id     => 'rpid',
            _session_id   => $sid,
            ( defined $lastSeen ? ( _oidcRtUpdate => $lastSeen ) : () ),
        }
    );
    close F;
}

clean_sessions();
done_testing();
