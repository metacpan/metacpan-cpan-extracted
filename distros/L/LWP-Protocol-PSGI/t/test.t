use strict;
use Test::More;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use File::Temp ();

my $psgi_app = sub {
    my $env = shift;
    return [
        200,
        [
            "Content-Type", "text/plain",
            "X-Foo" => "bar",
        ],
        [ "query=$env->{QUERY_STRING}" ],
    ];
};

{
    my $guard = LWP::Protocol::PSGI->register($psgi_app);

    my $ua  = LWP::UserAgent->new;
    my $res = $ua->get("http://www.google.com/search?q=bar");
    is $res->content, "query=q=bar";
    is $res->header('X-Foo'), "bar";

    use LWP::Simple;
    my $body = get "http://www.google.com/?q=x";
    is $body, "query=q=x";
}

{
    my $g = LWP::Protocol::PSGI->register($psgi_app, host => 'www.google.com');
    my $ua  = LWP::UserAgent->new;
    my $res = $ua->get("http://www.google.com/search?q=bar");
    is $res->content, "query=q=bar";
}

{
    my $guard1 = LWP::Protocol::PSGI->register($psgi_app);
    my $ua  = LWP::UserAgent->new;
    my $res = $ua->get("http://www.google.com/search?q=bar");
    is $res->content, "query=q=bar";

    {
        my $guard2 = LWP::Protocol::PSGI->register(sub { [ 403, [ "Content-Type" => "text/plain" ], [ "Not here" ] ] }, host => "www.yahoo.com");
        $res = $ua->get("http://www.google.com/search?q=bar");
        is $res->content, "query=q=bar";
        $res = $ua->get("http://www.yahoo.com/search?q=bar");
        is $res->content, "Not here";
    }

    # guard2 expired
    $res = $ua->get("http://www.google.com/search?q=bar");
    is $res->content, "query=q=bar";
    $res = $ua->get("http://www.yahoo.com/search?q=bar");
    is $res->content, "query=q=bar";
}

{
    my $g = LWP::Protocol::PSGI->register($psgi_app, host => 'www.google.com');
    my $ua  = LWP::UserAgent->new;
    my (undef, $tempfile) = File::Temp::tempfile( 'lwp-psgi-mirror-XXXXX', TMPDIR => 1, OPEN => 0, UNLINK => 1 );
    my $res = eval { $ua->mirror("http://www.google.com/search?q=bar", $tempfile) };
    open my $fh, '<:raw', $tempfile
      or do { fail "mirror call works"; last; };
    my $content = do { local $/; <$fh> };
    close $fh;
    is $content, "query=q=bar";
}


sub test_match {
    my($uri, %options) = @_;
    my $p = LWP::Protocol::PSGI->register(sub { }, %options);
    my $ok = LWP::Protocol::PSGI->handles(HTTP::Request->new(GET => $uri));
    undef $p;
    return $ok;
}

ok( test_match 'http://www.google.com/', host => 'www.google.com' );
ok( test_match 'https://www.google.com/', host => 'www.google.com' );
ok( test_match 'https://www.google.com/', host => qr/\.google.com/ );
ok( test_match 'https://www.google.com/', host => sub { $_[0] eq 'www.google.com' } );

ok( !test_match 'http://www.google.com/', host => 'google.com' );
ok( !test_match 'https://www.apple.com/', host => qr/\.google.com/ );
ok( !test_match 'https://google.com/', host => sub { $_[0] eq 'www.google.com' } );

ok( test_match 'http://www.google.com/', uri => 'http://www.google.com/' );
ok( test_match 'https://www.google.com/search?q=bar', uri => 'https://www.google.com/search?q=bar' );
ok( test_match 'https://www.google.com/search', uri => qr/\.google.com/ );
ok( test_match 'https://www.google.com/', uri => sub { $_[0] =~ /www.google.com/ } );

done_testing;

