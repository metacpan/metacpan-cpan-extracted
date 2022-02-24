package Lemonldap::NG::Handler::Test;
use File::Temp;
use HTTP::Request::Common;
use Lemonldap::NG::Handler::Server;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use Plack::Test;
our ( $in, $out, $rin, $rout, $server );
*in   = *main::in;
*out  = *main::out;
*rin  = *main::rin;
*rout = *main::rout;

sub init {
    my $tdir = File::Temp::tempdir( CLEANUP => 1 );

    my $h = Lemonldap::NG::Handler::Server->new( {} );
    $h->init( {
            configStorage => {
                type    => 'File',
                dirName => 't',
            },
            cookieName    => 'lemonldap',
            securedCookie => 0,
            https         => 0,
            logger        => 'Lemonldap::NG::Common::Logger::Std',
            domain        => 'idp.com',
            logLevel      => $main::debug,
            portal        => 'http://auth.idp.com',
            configStorage => {
                type    => 'File',
                dirName => 't',
            },
            globalStorageOptions => {
                Directory      => $LLNG::TMPDIR,
                LockDirectory  => "$LLNG::TMPDIR/lock",
                generateModule =>
                  'Lemonldap::NG::Common::Apache::Session::Generate::SHA256',
            },
            localSessionStorage        => 'Cache::FileCache',
            localSessionStorageOptions => {
                namespace   => 'lemonldap-ng-session',
                cache_root  => $tdir,
                cache_depth => 0,
            },
        }
    );
    $server = Plack::Test->create( $h->run );
}

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my ($env)   = @_;
        my $req     = Plack::Request->new($env);
        my $method  = $req->method;
        my $url     = $req->request_uri;
        my $content = $req->content;
        print $rin JSON::to_json( [ $method => $url, [], $content ] ) . "\n";
        my $res;
        $res = <$rout>, 'Get portal response';
        return JSON::from_json($res);
    }
);

sub run {
    while (<$in>) {
        chomp;
        if (/^END/) {
            return;
        }
        next unless $_;
        my ( $req, $res );
        $req = HTTP::Request->new( @{ JSON::from_json($_) } );
        $res = $server->request($req);
        my @flatten = &flatten($res);
        print $out JSON::to_json(
            [ $res->code, [@flatten], [ $res->content ] ] )
          . "\n";
    }
}

# Copy from HTTP::Headers code
sub flatten {
    my ($self) = @_;
    (
        map {
            my $k = $_;
            map { ( $k => $_ ) } $self->header($_);
        } $self->header_field_names
    );
}

1;

