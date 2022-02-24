# Test Providers API

use Test::More;
use strict;
use JSON;
use IO::String;
require 't/test-lib.pm';

our $_json = JSON->new->allow_nonref;

sub check201 {
    my ( $test, $res ) = splice @_;

    #diag Dumper($res);
    is( $res->[0], "201", "$test: Result code is 201" )
      or diag explain $res->[2];
    count(1);
    checkJson( $test, $res );
}

sub check204 {
    my ( $test, $res ) = splice @_;

    #diag Dumper($res);
    is( $res->[0], "204", "$test: Result code is 204" )
      or diag explain $res->[2];
    count(1);
    is( $res->[2]->[0], undef, "204 code returns no content" );
}

sub check200 {
    my ( $test, $res ) = splice @_;

    #diag Dumper($res);
    is( $res->[0], "200", "$test: Result code is 200" )
      or diag explain $res->[2];
    count(1);
    checkJson( $test, $res );

}

sub check409 {
    my ( $test, $res ) = splice @_;

    #diag Dumper($res);
    is( $res->[0], "409", "$test: Result code is 409" )
      or diag explain $res->[2];
    count(1);
    checkJson( $test, $res );
}

sub check404 {
    my ( $test, $res ) = splice @_;

    #diag Dumper($res);
    is( $res->[0], "404", "$test: Result code is 404" )
      or diag explain $res->[2];
    count(1);
    checkJson( $test, $res );
}

sub check400 {
    my ( $test, $res ) = splice @_;
    is( $res->[0], "400", "$test: Result code is 400" )
      or diag explain $res->[2];
    count(1);
    count(1);
    checkJson( $test, $res );
}

sub checkJson {
    my ( $test, $res ) = splice @_;
    my $key;

    #diag Dumper($res->[2]->[0]);
    ok( $key = from_json( $res->[2]->[0] ), "$test: Response is JSON" );
    count(1);
}

sub add {
    my ( $test, $type, $obj ) = splice @_;
    my $j = $_json->encode($obj);
    my $res;

    #diag Dumper($j);
    ok(
        $res = &client->_post(
            "/api/v1/menu/$type", '',
            IO::String->new($j),  'application/json',
            length($j)
        ),
        "$test: Request succeed"
    );
    count(1);
    return $res;
}

sub checkAdd {
    my ( $test, $type, $add ) = splice @_;
    check201( $test, add( $test, $type, $add ) );
}

sub checkAddNotFound {
    my ( $test, $type, $add ) = splice @_;
    check404( $test, add( $test, $type, $add ) );
}

sub checkAddFailsIfExists {
    my ( $test, $type, $add ) = splice @_;
    check409( $test, add( $test, $type, $add ) );
}

sub checkAddFailsOnInvalidConfkey {
    my ( $test, $type, $add ) = splice @_;
    check400( $test, add( $test, $type, $add ) );
}

sub get {
    my ( $test, $type, $confKey ) = splice @_;
    my $res;
    ok( $res = &client->_get( "/api/v1/menu/$type/$confKey", '' ),
        "$test: Request succeed" );
    count(1);
    return $res;
}

sub checkGet {
    my ( $test, $type, $confKey, $attrPath, $expectedValue ) = splice @_;
    my $res = get( $test, $type, $confKey );
    check200( $test, $res );
    my @path = split '/', $attrPath;
    my $key  = from_json( $res->[2]->[0] );
    for (@path) {
        if ( ref($key) eq 'ARRAY' ) {
            $key = $key->[$_];
        }
        else {
            $key = $key->{$_};
        }
    }
    ok(
        $key eq $expectedValue,
"$test: check if $attrPath value \"$key\" matches expected value \"$expectedValue\""
    );
    count(1);
}

sub checkGetNotFound {
    my ( $test, $type, $confKey ) = splice @_;
    check404( $test, get( $test, $type, $confKey ) );
}

sub checkGetList {
    my ( $test, $type, $confKey, $expectedHits ) = splice @_;
    my $res = get( $test, $type, $confKey );
    check200( $test, $res );
    my $hits    = from_json( $res->[2]->[0] );
    my $counter = @{$hits};
    ok(
        $counter eq $expectedHits,
"$test: check if nb of hits returned ($counter) matches expectation ($expectedHits)"
    );
    count(1);
}

sub update {
    my ( $test, $type, $confKey, $obj ) = splice @_;
    my $j = $_json->encode($obj);

    #diag Dumper($j);
    my $res;
    ok(
        $res = &client->_patch(
            "/api/v1/menu/$type/$confKey", '',
            IO::String->new($j),           'application/json',
            length($j)
        ),
        "$test: Request succeed"
    );
    count(1);
    return $res;
}

sub checkUpdate {
    my ( $test, $type, $confKey, $update ) = splice @_;
    check204( $test, update( $test, $type, $confKey, $update ) );
}

sub checkUpdateNotFound {
    my ( $test, $type, $confKey, $update ) = splice @_;
    check404( $test, update( $test, $type, $confKey, $update ) );
}

sub checkUpdateFailsIfExists {
    my ( $test, $type, $confKey, $update ) = splice @_;
    check409( $test, update( $test, $type, $confKey, $update ) );
}

sub checkUpdateWithUnknownAttributes {
    my ( $test, $type, $confKey, $update ) = splice @_;
    check400( $test, update( $test, $type, $confKey, $update ) );
}

sub replace {
    my ( $test, $type, $confKey, $obj ) = splice @_;
    my $j = $_json->encode($obj);
    my $res;
    ok(
        $res = &client->_put(
            "/api/v1/menu/$type/$confKey", '',
            IO::String->new($j),           'application/json',
            length($j)
        ),
        "$test: Request succeed"
    );
    count(1);
    return $res;
}

sub checkReplace {
    my ( $test, $type, $confKey, $replace ) = splice @_;
    check204( $test, replace( $test, $type, $confKey, $replace ) );
}

sub checkReplaceAlreadyThere {
    my ( $test, $type, $confKey, $replace ) = splice @_;
    check400( $test, replace( $test, $type, $confKey, $replace ) );
}

sub checkReplaceNotFound {
    my ( $test, $type, $confKey, $update ) = splice @_;
    check404( $test, replace( $test, $type, $confKey, $update ) );
}

sub checkReplaceWithInvalidAttribute {
    my ( $test, $type, $confKey, $replace ) = splice @_;
    check400( $test, replace( $test, $type, $confKey, $replace ) );
}

sub findByConfKey {
    my ( $test, $type, $confKey ) = splice @_;
    my $res;
    ok(
        $res = &client->_get(
            "/api/v1/menu/$type/findByConfKey",
            "pattern=$confKey"
        ),
        "$test: Request succeed"
    );
    count(1);
    return $res;
}

sub checkFindByConfKeyError {
    my ( $test, $type, $pattern ) = splice @_;
    my $res = findByConfKey( $test, $type, $pattern );
    check400( $test, $res );
}

sub checkFindByConfKey {
    my ( $test, $type, $confKey, $expectedHits ) = splice @_;
    my $res = findByConfKey( $test, $type, $confKey );
    check200( $test, $res );
    my $hits    = from_json( $res->[2]->[0] );
    my $counter = @{$hits};
    ok(
        $counter eq $expectedHits,
"$test: check if nb of hits returned ($counter) matches expectation ($expectedHits)"
    );
    count(1);
}

sub deleteMenu {
    my ( $test, $type, $confKey ) = splice @_;
    my $res;
    ok(
        $res = &client->_del(
            "/api/v1/menu/$type/$confKey", '', '', 'application/json', 0
        ),
        "$test: Request succeed"
    );
    count(1);
    return $res;
}

sub checkDelete {
    my ( $test, $type, $confKey ) = splice @_;
    check204( $test, deleteMenu( $test, $type, $confKey ) );
}

sub checkDeleteNotFound {
    my ( $test, $type, $confKey ) = splice @_;
    check404( $test, deleteMenu( $test, $type, $confKey ) );
}

my $test;

my $cat1 = {
    confKey => 'mycat1',
    catname => 'My Cat 1',
    order   => 1
};
my $cat2 = {
    confKey => 'mycat2',
    catname => 'My Cat 2',
    order   => 2
};
my $cat3 = {
    confKey => 'mycat/mycat3',
    catname => 'My Cat 3',
    order   => 2
};
$test = "Cat - Get mycat1 cat should err on not found";
checkGetNotFound( $test, 'cat', 'mycat1' );

$test = "Cat - Add should succeed";
checkAdd( $test, 'cat', $cat1 );
checkGet( $test, 'cat', 'mycat1', 'catname', 'My Cat 1' );
checkGet( $test, 'cat', 'mycat1', 'order',   1 );

$test = "Cat - Add should fail on duplicate confKey";
checkAddFailsIfExists( $test, 'cat', $cat1 );

$test = "Cat - Add should fail on invalid confKey";
checkAddFailsOnInvalidConfkey( $test, 'cat', $cat3 );

checkAddFailsOnInvalidConfkey

  $test = "Cat - Update should succeed and keep existing values";
$cat1->{order} = 3;
delete $cat1->{catname};
checkUpdate( $test, 'cat', 'mycat1', $cat1 );
checkGet( $test, 'cat', 'mycat1', 'catname', 'My Cat 1' );
checkGet( $test, 'cat', 'mycat1', 'order',   3 );

$test = "Cat - Update should fail if confKey not found";
$cat1->{confKey} = 'mycat3';
checkUpdateNotFound( $test, 'cat', 'mycat3', $cat1 );

$test = "Cat - 2nd add should succeed";
checkAdd( $test, 'cat', $cat2 );

$test = "Cat - Replace should succeed";
delete $cat2->{order};
checkReplace( $test, 'cat', 'mycat2', $cat2 );

$test = "Cat - Replace should fail if confKey not found";
$cat2->{confKey} = 'mycat3';
checkReplaceNotFound( $test, 'cat', 'mycat3', $cat2 );

$test = "Cat - FindByConfKey should find 2 hits";
checkFindByConfKey( $test, 'cat', 'mycat', 2 );

$test = "Cat - FindByConfKey should find 1 hits";
checkFindByConfKey( $test, 'cat', 'mycat1', 1 );

$test = "Cat - FindByConfKey should find 1 hits";
checkFindByConfKey( $test, 'cat', 'mycat2', 1 );

$test = "Cat - FindByConfKey should find 0 hits";
checkFindByConfKey( $test, 'cat', 'mycat3', 0 );

$test = "Cat - FindByConfKey should err on invalid patterns";
checkFindByConfKeyError( $test, 'cat', '' );
checkFindByConfKeyError( $test, 'cat', '$' );

my $app1 = {
    confKey => 'myapp1',
    options => {
        name        => 'My App 1',
        description => 'My app 1 description',
        tooltip     => 'My app 1 tooltip',
        uri         => 'http://app1.example.com/'
    },
    order => 1
};
my $app2 = {
    confKey => 'myapp2',
    options => {
        name        => 'My App 2',
        description => 'My app 2 description',
        display     => 'enabled',
        logo        => 'demo.png',
        tooltip     => 'My app 2 tooltip',
        uri         => 'http://app2.example.com/'
    },
    order => 2
};
my $app3 = {
    confKey => 'myapp3',
    options => {
        name        => 'My App 3',
        description => 'My app 3 description',
        display     => "\$uid eq 'dwho'",
        logo        => 'attach.png',
        tooltip     => 'My app 3 tooltip',
        uri         => 'http://app3.example.com/'
    },
    order => 1
};
my $app4 = {
    confKey => 'myapp1/myapp4',
    options => {
        name        => 'My App 4',
        description => 'My app 4 description',
        tooltip     => 'My app 4 tooltip',
        uri         => 'http://app4.example.com/'
    },
    order => 1
};

$test = "App - Get mycat3 apps should err on not found";
checkGetNotFound( $test, 'app', 'mycat3' );

$test = "App - Get app myapp1 from existing mycat2 should err on not found";
checkGetNotFound( $test, 'app/mycat2', 'myapp1' );

$test = "App - Get app myapp1 from mycat3 should err on not found";
checkGetNotFound( $test, 'app/mycat3', 'myapp1' );

$test = "App - Add app myapp1 to mycat3 should err on not found";
checkAddNotFound( $test, 'app/mycat3', $app1 );

$test = "App - Add app1 to cat1 should succeed";
checkAdd( $test, 'app/mycat1', $app1 );
checkGet( $test, 'app/mycat1', 'myapp1', 'order',        '1' );
checkGet( $test, 'app/mycat1', 'myapp1', 'options/name', 'My App 1' );
checkGet( $test, 'app/mycat1', 'myapp1', 'options/description',
    'My app 1 description' );
checkGet( $test, 'app/mycat1', 'myapp1', 'options/tooltip',
    'My app 1 tooltip' );
checkGet( $test, 'app/mycat1', 'myapp1', 'options/uri',
    'http://app1.example.com/' );

$test = "App - Add app2 to cat1 should succeed";
checkAdd( $test, 'app/mycat1', $app2 );
checkGet( $test, 'app/mycat1', 'myapp2', 'order',        '2' );
checkGet( $test, 'app/mycat1', 'myapp2', 'options/name', 'My App 2' );
checkGet( $test, 'app/mycat1', 'myapp2', 'options/logo', 'demo.png' );

$test = "App - Add app3 to cat2 should succeed";
checkAdd( $test, 'app/mycat2', $app3 );
checkGet( $test, 'app/mycat2', 'myapp3', 'order',           '1' );
checkGet( $test, 'app/mycat2', 'myapp3', 'options/display', "\$uid eq 'dwho'" );

$test = "App - Add should fail on duplicate confKey";
checkAddFailsIfExists( $test, 'app/mycat1', $app1 );

$test = "App - Add should fail on invalid confKey";
checkAddFailsOnInvalidConfkey( $test, 'app/mycat1', $app4 );

$test = "App - Check default value were set";
checkGet( $test, 'app/mycat1', 'myapp1', 'options/logo',    'network.png' );
checkGet( $test, 'app/mycat1', 'myapp1', 'options/display', 'auto' );

$test = "App - Category 1 should return 2 apps";
checkGetList( $test, 'app', 'mycat1', 2 );

$test = "App - Category 2 should return 1 app";
checkGetList( $test, 'app', 'mycat2', 1 );

$test = "App - FindByConfKey should find 2 hits";
checkFindByConfKey( $test, 'app/mycat1', '*', 2 );

$test = "App - FindByConfKey should find 1 hit";
checkFindByConfKey( $test, 'app/mycat1', 'app1', 1 );

$test = "App - FindByConfKey should err on invalid patterns";
checkFindByConfKeyError( $test, 'app/mycat1', '' );
checkFindByConfKeyError( $test, 'app/mycat1', '$' );

$test = "App - Update should succeed and keep existing values";
$app1->{options}->{name} = 'My App 1 updated';
delete $app1->{options}->{tooltip};
delete $app1->{order};
checkUpdate( $test, 'app/mycat1', 'myapp1', $app1 );
checkGet( $test, 'app/mycat1', 'myapp1', 'options/name', 'My App 1 updated' );
checkGet( $test, 'app/mycat1', 'myapp1', 'options/tooltip',
    'My app 1 tooltip' );
checkGet( $test, 'app/mycat1', 'myapp1', 'order', 1 );

$test = "App - Update should fail if confKey not found";
checkUpdateNotFound( $test, 'app/mycat4', 'myapp1', $app1 );
$app1->{confKey} = 'myapp4';
checkUpdateNotFound( $test, 'app/mycat1', 'myapp4', $app1 );

$test = "App - Replace should succeed";
$app3->{options}->{name} = 'My App 3 updated';
checkReplace( $test, 'app/mycat2', 'myapp3', $app3 );
checkGet( $test, 'app/mycat2', 'myapp3', 'options/name', 'My App 3 updated' );

$test = "App - Replace should fail if confKey not found";
checkReplaceNotFound( $test, 'app/mycat4', 'myapp3', $app3 );
$app3->{confKey} = 'myapp4';
checkReplaceNotFound( $test, 'app/mycat2', 'myapp4', $app3 );

$test = "App - Delete should succeed";
checkDelete( $test, 'app/mycat1', 'myapp2' );

$test = "App - Entity should not be found after deletion";
checkDeleteNotFound( $test, 'app/mycat1', 'myapp2' );

$test = "App - Category 1 should return 1 app";
checkGetList( $test, 'app', 'mycat1', 1 );

$test = "Cat - Clean up";
checkDelete( $test, 'cat', 'mycat1' );
checkDelete( $test, 'cat', 'mycat2' );
$test = "cat - Entity should not be found after clean up";
checkDeleteNotFound( $test, 'cat', 'mycat1' );

# Clean up generated conf files, except for "lmConf-1.json"
unlink grep { $_ ne "t/conf/lmConf-1.json" } glob "t/conf/lmConf-*.json";

done_testing();
