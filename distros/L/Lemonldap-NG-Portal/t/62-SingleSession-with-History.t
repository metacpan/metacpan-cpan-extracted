use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

my $level = 'error';
my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel            => $level,
            authentication      => 'Demo',
            userDB              => 'Same',
            loginHistoryEnabled => 1,
            singleSession       => 1,
        }
    }
);

sub loginUser {
    my ( $client, $user, $ip, $history ) = @_;
    my $query = (
        $history
        ? "user=$user&password=$user&checkLogins=1"
        : "user=$user&password=$user"
    );
    ok(
        my $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            ip     => $ip,
        ),
        'Auth query'
    );
    count(1);
    return $res;
}

####################
# Test singleSession

# Test logins
$res = loginUser( $client, "dwho", "127.0.0.1" );
my $id = expectCookie($res);
$res = loginUser( $client, "dwho", "127.0.0.1" );
expectCookie($res);
$res = loginUser( $client, "dwho", "127.0.0.1", 1 );
expectCookie($res);
ok( $res->[2]->[0] =~ m%<h3 trspan="sessionsDeleted"></h3>%,
    'sessionsDeleted found' )
  or explain( $res->[2]->[0], 'sessionsDeleted found' );
count(1);

# Test history
ok( $res->[2]->[0] =~ m%<h3 trspan="lastLogins"></h3%, 'History found' );
my @c = ( $res->[2]->[0] =~ m%<td class="localeDate" val="\d{10}"></td>%gs );
ok( @c == 4, ' -> Four entries found' )
  or explain( $res->[2]->[0], 'History entries found' );
count(2);

clean_sessions();

done_testing( count() );
