use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 7;
use File::Basename;
use File::Spec;
use Footprintless::Util qw(
    agent
    factory
);
use HTTP::Daemon;
use HTTP::Status;
use URI;

BEGIN { use_ok('Footprintless::Plugin::Atlassian::Confluence') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout',
        log_level => Log::Any::Adapter::Util::numeric_level($level) );
};

my $logger = Log::Any->get_logger();

my $test_dir = dirname( File::Spec->rel2abs($0) );

sub with_footprintless {
    my ( $httpd_handler, $callback, %options ) = @_;

    my $port = int( rand(10000) ) + 49152;
    my $pid  = fork();
    if ( $pid == 0 ) {
        print STDERR "Starting server...\n";
        my $httpd = HTTP::Daemon->new( LocalPort => $port )
            || die( 'unable to create daemon: ' . $! );
        while ( my $connection = $httpd->accept() ) {
            while ( my $request = $connection->get_request() ) {
                if (   $request->method() eq 'GET'
                    && $request->uri()->path() eq "/running" )
                {
                    $connection->send_status_line();
                }
                else {
                    &$httpd_handler( $connection, $request );
                }
            }
            $connection->close();
            undef($connection);
        }
        exit 0;
    }
    else {
        eval {
            my $url = "http://localhost:$port/";
            my $uri = URI->new($url);

            my $count = 0;
            my $agent = agent( timeout => 1 );
            while ( $count < 5
                && !$agent->get( $url . 'running' )->is_success() )
            {
                $logger->tracef( "not running: ", $count++, "\n" );
                sleep(1);
            }
            die('httpd never started') unless ( $count < 5 );

            my $footprintless = factory(
                {   confluence => {
                        automation => {
                            password => 'bar',
                            username => 'foo',
                        },
                        web => {
                            http     => 0,
                            hostname => $uri->host(),
                            port     => $uri->port(),
                        },
                    },
                    footprintless => {
                        plugins => [ 'Footprintless::Plugin::Atlassian::Confluence', ],
                        'Footprintless::Plugin::Atlassian::Confluence' => {
                            (   $options{request_builder_module}
                                ? ( request_builder_module => $options{request_builder_module} )
                                : ()
                            ),
                            (   $options{response_parser_module}
                                ? ( response_parser_module => $options{response_parser_module} )
                                : ()
                            ),
                        }
                    }
                }
            );

            &$callback($footprintless);
        };
        my $error = $@;
        $logger->debugf( 'failed: %s', $error );

        kill( 'KILL', $pid );

        return !$error;
    }
}

{
    $logger->info('with defaults');
    ok( with_footprintless(
            sub {
                my ( $connection, $request ) = @_;
                if (   $request->method() eq 'GET'
                    && $request->uri()->path() eq "/rest/api/content/123" )
                {
                    $connection->send_status_line();
                }
                else {
                    $connection->send_error(RC_NOT_FOUND);
                }
            },
            sub {
                my ($footprintless) = @_;
                my $client = $footprintless->confluence_client('confluence');
                ok( $client, 'with defaults got client' );
                my $response = $client->request( 'get_content', [ id => 123 ] );
                ok( $response->{success}, 'with defaults get_content by id' );
            }
        ),
        'with defaults completed'
    );
}

{
    $logger->info('with foobar');

    {

        package Foobar::RequestBuilder;

        sub new {
            my ( $class, $url ) = @_;
            return bless( { url => $url }, $class );
        }

        sub get_content {
            my ( $self, %options ) = @_;
            return HTTP::Request->new( 'GET', "$self->{url}/foobar/$options{id}" );
        }

        $INC{'Foobar/RequestBuilder.pm'} = '/dev/null/Foobar/RequestBuilder.pm';
    }

    ok( with_footprintless(
            sub {
                my ( $connection, $request ) = @_;
                $logger->debugf( 'request: %s', $request );
                if (   $request->method() eq 'GET'
                    && $request->uri()->path() eq "/foobar/123" )
                {
                    $connection->send_status_line();
                }
                else {
                    $connection->send_error(RC_NOT_FOUND);
                }
            },
            sub {
                my ($footprintless) = @_;
                my $client = $footprintless->confluence_client('confluence');
                ok( $client, 'with foobar got client' );
                my $response = $client->request( 'get_content', [ id => 123 ] );
                ok( $response->{success}, 'with foobar get_content by id' );
            },
            request_builder_module => 'Foobar::RequestBuilder'
        ),
        'with foobar completed'
    );
}
