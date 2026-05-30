use warnings;
use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

# Non-regression test for #3612
#
# Two applications named "intranet" live in two different categories.
# Each one carries its own "display" rule based on the user's groups.
# Before the cache-key fix, the first rule compiled for "intranet" was
# reused for the second application, hiding the wrong one (and the
# behaviour depended on Perl hash ordering, so it appeared to be random).

my $applicationList = {
    "0001-team-a" => {
        catname => "Team A",
        type    => "category",
        intranet => {
            type    => "application",
            options => {
                logo    => "demo.png",
                uri     => "http://team-a.example.com/",
                name    => "Team A Intranet",
                display => '$groups =~ /\btimelords\b/',
            },
        },
    },
    "0002-team-b" => {
        catname => "Team B",
        type    => "category",
        intranet => {
            type    => "application",
            options => {
                logo    => "demo.png",
                uri     => "http://team-b.example.com/",
                name    => "Team B Intranet",
                display => '$groups =~ /\bearthlings\b/',
            },
        },
    },
};

sub portal {
    return LLNG::Manager::Test->new( {
            ini => {
                portal          => 'http://auth.example.com/',
                authentication  => 'Demo',
                userDB          => 'Same',
                applicationList => $applicationList,
            }
        }
    );
}

sub menuFor {
    my ( $client, $user ) = @_;
    my $s   = "user=$user&password=$user";
    my $res = $client->_post(
        '/', IO::String->new($s),
        length => length($s),
        accept => 'text/html',
    );
    my $id = expectCookie($res);
    ok( $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        "Get menu for $user"
    );
    return $res;
}

# Run the lookup twice with a fresh portal each time: Perl hash ordering
# is randomised, so without the fix the result was non-deterministic and
# a one-shot test could occasionally pass even on the broken code path.
for my $iter ( 1 .. 5 ) {
    subtest "Iteration $iter" => sub {
        my $client = portal();

        # dwho is a timelord: only the Team A intranet must show up
        my $dwhoMenu = menuFor( $client, 'dwho' );
        my @dwhoHrefs =
          map { $_->getAttribute('href') }
          getHtmlElement( $dwhoMenu,
            '//div[contains(@class,"application")]//a' );
        is_deeply(
            [ sort @dwhoHrefs ],
            ['http://team-a.example.com/'],
            'dwho sees Team A intranet only',
        ) or diag explain \@dwhoHrefs;

        # rtyler is an earthling: only the Team B intranet must show up
        my $rtylerMenu = menuFor( $client, 'rtyler' );
        my @rtylerHrefs =
          map { $_->getAttribute('href') }
          getHtmlElement( $rtylerMenu,
            '//div[contains(@class,"application")]//a' );
        is_deeply(
            [ sort @rtylerHrefs ],
            ['http://team-b.example.com/'],
            'rtyler sees Team B intranet only',
        ) or diag explain \@rtylerHrefs;
    };
}

clean_sessions();
done_testing();
