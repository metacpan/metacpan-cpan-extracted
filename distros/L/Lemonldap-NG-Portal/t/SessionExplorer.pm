package t::SessionExplorer;
use File::Temp 'tempfile', 'tempdir';
use Lemonldap::NG::Common::PSGI::Router;
use Lemonldap::NG::Manager::Sessions;
use Lemonldap::NG::Portal::Main::Request;
use t::TestStdLogger;

sub new {
    my ( $class, $ini ) = @_;
    my $sessionExlorer = Lemonldap::NG::Manager::Sessions->new;
    $sessionExlorer->{p} = Lemonldap::NG::Common::PSGI::Router->new;
    $sessionExlorer->{p}->logger(
        t::TestStdLogger->new( { logLevel => $ENV{LLNGLOGLEVEL} || 'error' } )
    );
    $sessionExlorer->init($ini);
    return bless { se => $sessionExlorer }, $class;
}

sub adminLogout {
    my ( $self, %args ) = @_;
    my $path = '/sessions/glogout';
    return $self->{se}->userLogout(
        Lemonldap::NG::Portal::Main::Request->new( {
                'HTTP_ACCEPT'          => $args{accept} // 'application/json',
                'HTTP_ACCEPT_LANGUAGE' => 'en-US,fr-FR;q=0.7,fr;q=0.3',
                'HTTP_CACHE_CONTROL'   => 'max-age=0',
                ( $args{cookie} ? ( HTTP_COOKIE => $args{cookie} ) : () ),
                'HTTP_HOST' =>
                  ( $args{host} ? $args{host} : 'auth.example.com' ),
                'HTTP_USER_AGENT' =>
                  'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
                'PATH_INFO' => $path,
                ( $args{referer} ? ( REFERER => $args{referer} ) : () ),
                (
                    $args{ip} ? ( 'REMOTE_ADDR' => $args{ip} )
                    : ( 'REMOTE_ADDR' => '127.0.0.1' )
                ),
                (
                    $args{remote_user} ? ( 'REMOTE_USER' => $args{remote_user} )
                    : ()
                ),
                'REQUEST_METHOD' => $args{method} || 'GET',
                'REQUEST_URI'    => $path
                  . ( $args{query} ? "?$args{query}" : '' ),
                ( $args{query} ? ( QUERY_STRING => $args{query} ) : () ),
                'SCRIPT_NAME'     => '',
                'SERVER_NAME'     => 'auth.example.com',
                'SERVER_PORT'     => '80',
                'SERVER_PROTOCOL' => 'HTTP/1.1',
                'psgi.url_scheme' => ( $args{secure} ? 'https' : 'http' ),
                ( $args{custom} ? %{ $args{custom} } : () ),
            }
        )
    );
}

1;
