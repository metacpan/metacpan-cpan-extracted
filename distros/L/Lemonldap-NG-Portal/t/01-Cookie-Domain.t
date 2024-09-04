use warnings;
use Test::More;
use strict;
use Lemonldap::NG::Portal::Main::Request;

require 't/test-lib.pm';

my $res;

sub assertCookieValue {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $client, $opts, $expected ) = @_;
    my $result = $client->p->cookie(%$opts);
    my $str    = join( ',', map { "$_=$opts->{$_}" } sort keys %$opts );
    is( $result, $expected, "Correct cookie result for $str" );
}

sub assertGenCookieValue {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $client, $req, $opts, $expected ) = @_;
    my $result = $client->p->genDomainCookie( $req, %$opts );
    my $str    = join( ',', map { "$_=$opts->{$_}" } sort keys %$opts );
    is( $result, $expected, "Correct cookie result for $str" );
}

sub assertStandardBehavior {
    my ( $client, $req ) = @_;

    # cookie() without domain
    assertCookieValue(
        $client,
        { name => "coucou", value => 0 },
        "coucou=0; path=/; HttpOnly=1; SameSite=Lax"
    );

    # cookie() with explicit domain
    assertCookieValue(
        $client,
        { name => "coucou", domain => "example.com", value => 0 },
        "coucou=0; domain=example.com; path=/; HttpOnly=1; SameSite=Lax"
    );

    # Domain can be overwritten
    assertGenCookieValue(
        $client, $req,
        { name => "coucou", value => 0, domain => "other.com" },
        "coucou=0; domain=other.com; path=/; HttpOnly=1; SameSite=Lax"
    );
}

subtest "Behavior with domain = example.com" => sub {
    my $client = LLNG::Manager::Test->new( {
            ini => {
                portal => 'https://auth.example.com/',
            }
        }
    );

    # Stub Request object
    my $req = Lemonldap::NG::Portal::Main::Request->new(
        { PATH_INFO => "", REQUEST_URI => "/" } );

    assertStandardBehavior( $client, $req );

    # Domain is automatically set from portal config
    assertGenCookieValue(
        $client, $req,
        { name => "coucou", value => 0 },
        "coucou=0; domain=.example.com; path=/; HttpOnly=1; SameSite=Lax"
    );
};

subtest "Behavior with unset domain" => sub {
    my $client = LLNG::Manager::Test->new( {
            ini => {
                portal => 'https://auth.example.com/',
                domain => "",
            }
        }
    );

    # Stub Request object
    my $req = Lemonldap::NG::Portal::Main::Request->new(
        { PATH_INFO => "", REQUEST_URI => "/" } );

    assertStandardBehavior( $client, $req );

    # Domain is not automatically set
    assertGenCookieValue(
        $client, $req,
        { name => "coucou", value => 0 },
        "coucou=0; path=/; HttpOnly=1; SameSite=Lax"
    );
};

subtest "Behavior with special #PORTAL# value" => sub {
    my $client = LLNG::Manager::Test->new( {
            ini => {
                portal => 'https://auth.example.com/',
                domain => "#PORTAL#",
            }
        }
    );

    # Stub Request object
    my $req = Lemonldap::NG::Portal::Main::Request->new(
        { PATH_INFO => "", REQUEST_URI => "/" } );
    $req->portal("http://auth.dynamic.com/");

    assertStandardBehavior( $client, $req );

    # Domain is not automatically set
    assertGenCookieValue( $client, $req, { name => "coucou", value => 0 },
        "coucou=0; domain=.auth.dynamic.com; path=/; HttpOnly=1; SameSite=Lax"
    );
};

subtest "Behavior with special #PORTALDOMAIN# value" => sub {
    my $client = LLNG::Manager::Test->new( {
            ini => {
                portal => 'https://auth.example.com/',
                domain => "#PORTALDOMAIN#",
            }
        }
    );

    # Stub Request object
    my $req = Lemonldap::NG::Portal::Main::Request->new(
        { PATH_INFO => "", REQUEST_URI => "/" } );
    $req->portal("http://auth.dynamic.com/");

    assertStandardBehavior( $client, $req );

    # Domain is not automatically set
    assertGenCookieValue(
        $client, $req,
        { name => "coucou", value => 0 },
        "coucou=0; domain=.dynamic.com; path=/; HttpOnly=1; SameSite=Lax"
    );
};

done_testing();
