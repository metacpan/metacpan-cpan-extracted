# Test sessions explorer API

use Test::More;
use JSON;
use strict;
use Lemonldap::NG::Common::Session;

eval { mkdir 't/sessions' };
`rm -rf t/sessions/*`;
require 't/test-lib.pm';

sub newSession {
    my ( $uid, $ip ) = splice @_;
    my $tmp;
    ok(
        $tmp = Lemonldap::NG::Common::Session->new( {
                storageModule        => 'Apache::Session::File',
                storageModuleOptions => {
                    Directory      => 't/sessions',
                    LockDirectory  => 't/sessions',
                    generateModule =>
'Lemonldap::NG::Common::Apache::Session::Generate::SHA256',
                },
            }
        ),
        'Sessions module'
    );
    count(1);
    $tmp->update( {
            ipAddr        => $ip,
            _whatToTrace  => $uid,
            uid           => $uid,
            _utime        => time,
            _session_kind => 'SSO'
        }
    );
    return $tmp->{id};
}

# Single session access
my @ids;
$ids[0] = newSession( 'dwho',  '127.10.0.1' );
$ids[1] = newSession( 'dwho2', '127.2.0.2' );
my $res = &client->jsonResponse("/sessions/global/$ids[0]");
ok( ( $res->{uid}    and $res->{uid} eq 'dwho' ),          'Uid found' );
ok( ( $res->{ipAddr} and $res->{ipAddr} eq '127.10.0.1' ), 'IP found' );
count(2);

# "All" query
$res = &client->jsonResponse("/sessions/global/");
ok( $res->{result} == 1,      'Result code = 1' );
ok( $res->{count} == 2,       'Found 2 sessions' );
ok( @{ $res->{values} } == 2, 'List 2 sessions' );
ok( $res->{values}->[$_]->{session} =~ /^(?:$ids[0]|$ids[1])$/,
    'Good session id' )
  foreach ( 0 .. 1 );
count(5);

# GroupBy query
$res = &client->jsonResponse( '/sessions/global', 'groupBy=substr(uid,1)' );
ok( $res->{result} == 1, 'Result code = 1' );
ok( $res->{count} == 1,  'Found 1 entry' );
ok( $res->{values}->[0]->{value} && $res->{values}->[0]->{value} eq 'd',
    'Result match "uid=d"' )
  or print STDERR Dumper($res);
ok( $res->{values}->[0]->{count} == 2, 'Found 2 sessions starting with "d"' );
count(4);

$ids[2] = newSession( 'foo', '127.3.0.3' );
$res = &client->jsonResponse( '/sessions/global', 'groupBy=substr(uid,1)' );
ok( $res->{count} == 2, 'Found 2 entries' );
count(1);

# Filtered queries
$res = &client->jsonResponse( '/sessions/global', 'uid=d*' );
ok( $res->{count} == 2, 'Found 2 sessions' );
ok( $res->{values}->[$_]->{session} =~ /^(?:$ids[0]|$ids[1])$/,
    'Good session id' )
  foreach ( 0 .. 1 );
count(3);
$res = &client->jsonResponse( '/sessions/global', 'uid=f*' );
ok( $res->{count} == 1,                        'Found 1 sessions' );
ok( $res->{values}->[0]->{session} eq $ids[2], 'Good session id' );
count(2);

# DoubleIp
$ids[3] = newSession( 'foo', '127.3.0.4' );
$res = &client->jsonResponse( '/sessions/global', 'doubleIp' );
ok( $res->{count} == 1,                    'Found 1 user' );
ok( $res->{values}->[0]->{value} eq 'foo', 'User is foo' );
ok(
    $res->{values}->[0]->{sessions}->[$_]->{session} =~ /^(?:$ids[2]|$ids[3])$/,
    'Good session id'
) foreach ( 0 .. 1 );
count(4);

# New GroupBy query test with 4 sessions
$res = &client->jsonResponse( '/sessions/global', 'groupBy=uid' );
ok( (
              $res->{values}->[0]->{value} eq 'dwho'
          and $res->{values}->[0]->{count} == 1
    ),
    '1st user is dwho'
) or print STDERR Dumper($res);
ok( (
              $res->{values}->[1]->{value} eq 'dwho2'
          and $res->{values}->[1]->{count} == 1
    ),
    '2nd user is dwho2'
) or print STDERR Dumper($res);
ok( (
              $res->{values}->[2]->{value} eq 'foo'
          and $res->{values}->[2]->{count} == 2
    ),
    '3rd user is foo with 2 sessions'
) or print STDERR Dumper($res);
count(3);

# Ordered queries
$res = &client->jsonResponse( '/sessions/global', 'orderBy=uid' );
ok( $res->{values}->[0]->{uid} eq 'dwho',  '1st user is dwho' );
ok( $res->{values}->[1]->{uid} eq 'dwho2', '2nd user is dwho2' );
ok( $res->{values}->[2]->{uid} eq 'foo',   '3rd user is foo' );
ok( $res->{values}->[3]->{uid} eq 'foo',   '4th user is foo' );
count(4);

# IPv4 networks
$res = &client->jsonResponse( '/sessions/global', 'groupBy=net4(ipAddr,1)' );
ok( $res->{count} == 1,                'One A subnet' );
ok( $res->{values}->[0]->{count} == 4, 'All sessions found' );
$res = &client->jsonResponse( '/sessions/global', 'groupBy=net4(ipAddr,2)' );
ok( $res->{count} == 3,                'Three B subnet' );
ok( $res->{values}->[1]->{count} == 2, 'All sessions found' )
  or print STDERR Dumper($res);
count(4);

$res = &client->jsonResponse( '/sessions/global', 'orderBy=net4(ipAddr)' );
ok( $res->{count} == 4,                        '4 sessions ordered' );
ok( $res->{values}->[0]->{session} eq $ids[1], '1st is id[1]' );
ok( $res->{values}->[1]->{session} eq $ids[2], '2nd is id[2]' );
ok( $res->{values}->[2]->{session} eq $ids[3], '3rd is id[3]' );
ok( $res->{values}->[3]->{session} eq $ids[0], '4th is id[0]' );
count(5);

#print STDERR Dumper($res);

# Delete sessions
foreach (@ids) {
    my $res;
    ok( $res = &client->_del("/sessions/global/$_"), "Delete $_" );
    ok( $res->[0] == 200,                            'Result code is 200' );
    ok( from_json( $res->[2]->[0] )->{result} == 1,
        'Body is JSON and result==1' );
    count(3);
}

opendir D, 't/sessions' or die 'Unknown dir';
my @files = grep { not /(?:^\.|.lock$)/ } readdir D;
ok( @files == 0, "Session directory is empty" );
count(1);

done_testing( count() );

# Remove sessions directory
`rm -rf t/sessions`;
