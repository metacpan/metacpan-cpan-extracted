use warnings;
use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

sub sortgroups {
    my ($value) = @_;
    return join( '; ', sort split( '; ', $value ) );
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel          => 'error',
            authentication    => 'Demo',
            userDB            => 'Same',
            refreshSessions   => 1,
            restSessionServer => 1,
        }
    }
);

my @ids;
foreach ( 1 .. 6 ) {
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
        ),
        "Auth query $_"
    );
    count(1);
    push @ids, expectCookie($res);
}

$Lemonldap::NG::Portal::UserDB::Demo::demoAccounts{dwho}->{uid} = 'Dr Who';

$Lemonldap::NG::Portal::UserDB::Demo::demoGroups{timelords} = [];
$Lemonldap::NG::Portal::UserDB::Demo::demoGroups{daleks} = ["dwho"]; #uh oh

ok(
    $res = $client->_post(
        '/refreshsessions', IO::String->new('{"uid":"dwho"}'),
        length => 14,
        type   => 'application/json',
    ),
    'Call refresh'
);
count(1);
expectOK($res);
my $c = @ids;
ok( $res->[2]->[0] =~ /"updated":$c/, "Count is $c" );
count(1);

foreach (@ids) {
    ok( my $attr = getSessionAttributes( $client, $_ ), 'Get session content' );
    is( $attr->{uid},                  "Dr Who",        ' Content is updated' );
    is( sortgroups( $attr->{groups} ), "daleks; users", ' Correct groups' );
    count(3);
}

clean_sessions();
done_testing( count() );
