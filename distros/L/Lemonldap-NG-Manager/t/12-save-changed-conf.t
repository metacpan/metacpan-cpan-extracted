#!/usr/bin/env perl -I pl/lib
#
# Verify that a modified configuration can be saved and that all changes are
# detected

use Test::More;
use strict;
use JSON;
use Data::Dumper;
require 't/test-lib.pm';

my $struct = 't/jsonfiles/12-modified.json';
my $confFiles = [ 't/conf/lmConf-1.js', 't/conf/lmConf-2.js' ];

sub body {
    return IO::File->new( $struct, 'r' );
}

# Delete lmConf-2.js if exists
eval { unlink $confFiles->[1]; };
mkdir 't/sessions';

my ( $res, $resBody );
ok( $res = &client->_post( '/confs/', 'cfgNum=1', &body, 'application/json' ),
    "Request succeed" );
ok( $res->[0] == 200, "Result code is 200" );
ok( $resBody = from_json( $res->[2]->[0] ), "Result body contains JSON text" );
ok( $resBody->{result} == 1, "JSON response contains \"result:1\"" )
  or print STDERR Dumper($resBody);
ok( -f $confFiles->[1], 'File is created' );

my @changes = @{&changes};
my @cmsg    = @{ $resBody->{details}->{__changes__} };
my $bug;
ok( @changes == @cmsg, 'Same changes count' ) or $bug = 1;
while ( my $c = shift @{ $resBody->{details}->{__changes__} } ) {
    my $cmp1 = @changes;
    my $cmp2 = @cmsg;

    my @d1 = grep { $_->{key} eq $c->{key} } @changes;
    my @d2 = grep { $_->{key} eq $c->{key} } @cmsg;
    @changes = grep { $_->{key} ne $c->{key} } @changes;
    @cmsg    = grep { $_->{key} ne $c->{key} } @cmsg;
    ok( ( $cmp1 - @changes ) == ( $cmp2 - @cmsg ), "$c->{key} found" )
      or print STDERR 'Expect: '
      . ( $cmp1 - @changes )
      . ', got: '
      . ( $cmp2 - @cmsg )
      . "\nExpect: "
      . Dumper( \@d1 ) . "Got: "
      . Dumper( \@d2 );
    count(1);
}
ok( !@changes, 'All changes detected' ) or $bug = 1;

if ($bug) {
    print STDERR 'Expected not found: '
      . Dumper( \@changes )
      . 'Changes announced and not found: '
      . Dumper( \@cmsg );
}

#print STDERR Dumper(\@changes,\@cmsg);

count(7);

unlink $confFiles->[1];
eval { rmdir 't/sessions'; };
done_testing( count() );

sub changes {
    return [
        {
            'key' => 'portal',
            'new' => 'http://auth2.example.com/',
            'old' => 'http://auth.example.com/'
        },
        {
            'new' => 0,
            'old' => 1,
            'key' => 'portalDisplayLogout'
        },
        {
            'key' =>
              'applicationList, Sample applications, Application Test 1, uri',
            'old' => 'http://test1.example.com/',
            'new' => 'http://testex.example.com/'
        },
        {
            'new' => 'Application Test 3',
            'key' => 'applicationList, Sample applications'
        },
        {
            'key' => 'applicationList',
            'new' => 'New cat(s)/app(s)'
        },
        {
            'key' => 'userDB',
            'new' => 'LDAP',
            'old' => 'Demo'
        },
        {
            'key' => 'passwordDB',
            'new' => 'LDAP',
            'old' => 'Demo'
        },
        {
            'key' => 'openIdSPList',
            'new' => '1;bad.com'
        },
        {
            'key' => 'exportedVars',
            'new' => 'User-Agent'
        },
        {
            'new' => 'Uid',
            'key' => 'exportedVars'
        },
        {
            'key' => 'exportedVars',
            'old' => 'UA'
        },
        {
            'key' =>
              'locationRules, test1.example.com, (?#Logout comment)^/logout',
            'new' => 'logout_sso',
            'old' => undef
        },
        {
            'old' => '^/logout',
            'key' => 'locationRules, test1.example.com'
        },
        {
            'key' => 'locationRules, test3.example.com, ^/logout',
            'new' => 'logout_sso',
            'old' => undef
        },
        {
            'key' => 'locationRules, test3.example.com, default',
            'old' => undef,
            'new' => 'accept'
        },
        {
            'key' => 'locationRules',
            'new' => 'test3.example.com'
        },
        {
            'key' => 'exportedHeaders, test3.example.com, Auth-User',
            'old' => undef,
            'new' => '$uid'
        },
        {
            'new' => 'test3.example.com',
            'key' => 'exportedHeaders'
        },
        {
            'key' => 'locationRules, test.ex.com, default',
            'old' => undef,
            'new' => 'deny'
        },
        {
            'key' => 'locationRules',
            'new' => 'test.ex.com'
        },
        {
            'key' => 'virtualHosts',
            'new' => 'test3.example.com',
            'old' => 'test2.example.com'
        },
        {
            'key' => 'virtualHosts',
            'old' => 'test2.example.com'
        }
    ];
}
