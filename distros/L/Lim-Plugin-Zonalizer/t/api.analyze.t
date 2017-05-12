#!perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use Log::Log4perl;
use AnyEvent;
use JSON;

Log::Log4perl->init(
    \q(
log4perl.logger                   = FATAL, Screen
log4perl.appender.Screen          = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr   = 1
log4perl.appender.Screen.layout   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %F [%L] %p: %m%n
)
);

use_ok( 'Lim::Plugin::Zonalizer::Server' );

my $timeout;
create_timeout();

my ( $o, $cv, %db, $r );

Lim->Config->{zonalizer} = { lang => 'en_US', collector => { exec => 't/collectors/do_nothing' } };

%db = ( Memory => {} );

SKIP: {
    skip '$TEST_COUCHDB_DATABASE not set', 1 unless ( $ENV{TEST_COUCHDB_DATABASE} );
    ok( !system( 'bin/zonalizer-couchdb-database', '--create', '--load', File::Spec->catfile( 't', 'api.analyze.couchdb.json' ), $ENV{TEST_COUCHDB_DATABASE} ) );
    $db{CouchDB} = { uri => $ENV{TEST_COUCHDB_DATABASE} };
}

open( RESULTS, File::Spec->catfile( 't', 'api.analyze.results.json' ) ) or die 'open: ' . $!;
{
    local $/;
    $r = JSON->new->utf8->decode( <RESULTS> );
}
close( RESULTS );

foreach my $db_driver ( keys %db ) {
    Lim->Config->{zonalizer}->{db_driver} = $db_driver;
    Lim->Config->{zonalizer}->{db_conf}   = $db{$db_driver};

    ok( $db_driver, $db_driver );
    isa_ok( $o = Lim::Plugin::Zonalizer::Server->new, 'Lim::Plugin::Zonalizer::Server' );

    if ( $db_driver eq 'Memory' ) {
        open( MEMORY, File::Spec->catfile( 't', 'api.analyze.memory.json' ) ) or die 'open: ' . $!;
        {
            local $/;
            my $analysis = JSON->new->utf8->decode( <MEMORY> );
            foreach ( @$analysis ) {
                push( @{ $o->{db}->{space}->{ $_->{space} }->{analysis} }, $_ );
                $o->{db}->{space}->{ $_->{space} }->{analyze}->{ $_->{id} } = $_;
                push( @{ $o->{db}->{space}->{ $_->{space} }->{analyze_fqdn}->{ $_->{fqdn} } }, $_ );
                push( @{ $o->{db}->{space}->{ $_->{space} }->{analyze_rfqdn}->{ join( '.', reverse( split( /\./o, $_->{fqdn} ) ) ) } }, $_ );
            }
        }
        close( MEMORY );
    }

    {
        no warnings 'redefine';
        no warnings 'once';
        *Lim::Plugin::Zonalizer::Server::Error = sub {
            shift;
            shift;
            $cv->send( scalar @_ ? ( @_ ) : 'error' );
        };
        *Lim::Plugin::Zonalizer::Server::Successful = sub {
            shift;
            shift;
            $cv->send( @_ );
        };
        my ( $header, $request );
        *Lim::Plugin::Zonalizer::Server::set_header = sub {
            $header = $_[1];
        };
        *Lim::Plugin::Zonalizer::Server::header = sub {
            return $header;
        };
        *Lim::Plugin::Zonalizer::Server::set_request = sub {
            $request = $_[1];
        };
        *Lim::Plugin::Zonalizer::Server::request = sub {
            return $request;
        };
    }

    $cv = AnyEvent->condvar;
    undef $@;
    eval { $o->CreateAnalyze( $o ); };
    ok( !$@, 'CreateAnalyze1' );
    isa_ok( ( $_ = $cv->recv ), 'Lim::Error', 'CreateAnalyze1' );
    is( $_->toString, 'Module: Lim::Plugin::Zonalizer::Server Code: 400 Message: invalid_api_version', 'CreateAnalyze1' );

    $cv = AnyEvent->condvar;
    undef $@;
    eval { $o->ReadAnalyze( $o ); };
    ok( !$@, 'ReadAnalyze1' );
    isa_ok( ( $_ = $cv->recv ), 'Lim::Error', 'ReadAnalyze1' );
    is( $_->toString, 'Module: Lim::Plugin::Zonalizer::Server Code: 400 Message: invalid_api_version', 'ReadAnalyze1' );

    $cv = AnyEvent->condvar;
    undef $@;
    eval { $o->ReadAnalyze( $o, { version => 1, id => 'test-id-1' } ); };
    ok( !$@, 'ReadAnalyze2' );
    ok( ( $_ = $cv->recv ), 'ReadAnalyze2' );
    is_deeply( $_, $r->{ReadAnalyze2}, 'ReadAnalysis2' );

    $cv = AnyEvent->condvar;
    undef $@;
    eval { $o->ReadAnalyze( $o, { version => 1, id => 'test-does-not-exists' } ); };
    ok( !$@, 'ReadAnalyze3' );
    isa_ok( ( $_ = $cv->recv ), 'Lim::Error', 'ReadAnalyze3' );
    is( $_->toString, 'Module: Lim::Plugin::Zonalizer::Server Code: 404 Message: id_not_found', 'ReadAnalyze3' );

    $cv = AnyEvent->condvar;
    undef $@;
    eval { $o->ReadAnalyzeStatus( $o ); };
    ok( !$@, 'ReadAnalyzeStatus1' );
    isa_ok( ( $_ = $cv->recv ), 'Lim::Error', 'ReadAnalyzeStatus1' );
    is( $_->toString, 'Module: Lim::Plugin::Zonalizer::Server Code: 400 Message: invalid_api_version', 'ReadAnalyzeStatus1' );

    $cv = AnyEvent->condvar;
    undef $@;
    eval { $o->DeleteAnalyze( $o ); };
    ok( !$@, 'DeleteAnalyze1' );
    isa_ok( ( $_ = $cv->recv ), 'Lim::Error', 'DeleteAnalyze1' );
    is( $_->toString, 'Module: Lim::Plugin::Zonalizer::Server Code: 400 Message: invalid_api_version', 'DeleteAnalyze1' );
}

SKIP: {
    skip '$TEST_COUCHDB_DATABASE not set', 1 unless ( $ENV{TEST_COUCHDB_DATABASE} );
    ok( !system( 'bin/zonalizer-couchdb-database', '--drop', $ENV{TEST_COUCHDB_DATABASE} ) );
}

done_testing;

sub create_timeout {
    $timeout = AnyEvent->timer(
        after => 300,
        cb    => sub {
            BAIL_OUT 'Timed out';
        }
    );
}
