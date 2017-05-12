package Test::MockBank;

use Test::More;
use warnings;
use strict;

use HTTP::Status;
use HTTP::Response;
use URI::Escape;

my %GLOBALSTATE = (
                   loggedin => 0,
                   config => {},
                   requestcount => 0,
                  );

sub globalstate {
    my $self = shift;
    my ( $key, $value ) = @_;

    if ( defined( $value )) {
        $GLOBALSTATE{$key} = $value;
# what I should be doing, except I'm using this as a set/get function :(
#    } else {
#        delete $GLOBALSTATE{$key};
    }

    $GLOBALSTATE{$key};
}

sub fail_on_iterations {
    my $self = shift;
    my $iterations = [ @_ ];
    $self->globalstate( 'fail', [ $iterations, 0 ] );
}

sub on_page {
    my $self = shift;
    my $uri = shift;
    my $usepage = shift;

    if ( !$uri ) {
        # argh
        delete $GLOBALSTATE{on_page};
    } else {
        $self->globalstate( 'on_page', [ $uri, $usepage ] );
    }
}

sub simple_request {
    my ( $self, $request ) = @_;

    $GLOBALSTATE{requestcount}++;

    my $fail = Test::MockBank->globalstate( 'fail' );
    my ( $failures, $iteration );
    if ( $fail ) {
        ( $failures, $iteration ) = @{$fail};
    }

    diag( sprintf( "Mock Bank request %d for %s, iteration %s, login state %s",
                   $GLOBALSTATE{requestcount},
                   $request->uri,
                   defined( $iteration ) ? $iteration : "(not counting)",
                   ( Test::MockBank->globalstate( 'loggedin' )||0))) if $ENV{DEBUG};

    my $response = new HTTP::Response();
    $response->request( $request );

    if ( $fail ) {
        $iteration++;
        Test::MockBank->globalstate( 'fail', [ $failures, $iteration ]);

        if ( grep {m/^$iteration$/} @{$failures} ) {
            diag( "failing per request on iteration $iteration when " . $request->method . "ing " . $request->uri) if $ENV{DEBUG};
            my @iterations = grep {!m/^$iteration$/} @{$failures};
            if ( !@iterations ) {
                Test::MockBank->globalstate( 'fail', 0 );
            } else {
                Test::MockBank->globalstate( 'fail', [ \@iterations, $iteration ] );
            }
            $response->code( RC_INTERNAL_SERVER_ERROR );
            $response->content( 'FAIL' );
            diag( "returning " . $response->code) if $ENV{DEBUG};
            return $response;
        } else {
        }
    }

    if ( my $substitute = Test::MockBank->globalstate( 'on_page' )) {
        my $uri = $request->uri;
        if ( $uri eq $substitute->[0] ) {
            if ( $substitute->[1] ) {
                $request->uri( $substitute->[1] );
            } else {
                diag("failing per request when " . $request->method . "ing " . $request->uri) if $ENV{DEBUG};
                $response->code( RC_INTERNAL_SERVER_ERROR );
                $response->content( 'FAIL' );
                diag("returning " . $response->code) if $ENV{DEBUG};
                return $response;
            }
        }
    }

    # a little fragile perhaps
    my $context = $0;
    $context =~ s@t/(.*)\.t$@$1@;

    eval '$response = Test::MockBank::' . $context . '->request( $response, $context );';
    die "$context: $@" if $@;

    diag("returning " . $response->code) if $ENV{DEBUG};

    return $response;
}

sub request {
    my ( $self, $response, $context ) = @_;

    my $request = $response->request();

    my $content = Test::Util::getfile( $request->uri, $context );
    if ( defined( $content )) {
        $response->code( RC_OK );
        $response->content( $content );
    } else {
        $response->code( RC_NOT_FOUND );
        $response->message( 'file not found' );
        $response->content( 'no such uri ' . $request->uri );
    }

    $response;
}

sub get_param {
    my ( $self, $param, $args ) = @_;
    my $value;
    map {
        $value = $_->[1] if $_->[0] eq $param or uri_unescape( $_->[0] ) eq $param;
    } @{$args};

    $value = uri_unescape( $value ) if $value;

    $value;
}

1;
