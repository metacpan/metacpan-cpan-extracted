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
    ok( !system( 'bin/zonalizer-couchdb-database', '--create', '--load', File::Spec->catfile( 't', 'api.analysis.couchdb.json' ), $ENV{TEST_COUCHDB_DATABASE} ) );
    $db{CouchDB} = { uri => $ENV{TEST_COUCHDB_DATABASE} };
}

open( RESULTS, File::Spec->catfile( 't', 'api.analysis.results.json' ) ) or die 'open: ' . $!;
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
        open( MEMORY, File::Spec->catfile( 't', 'api.analysis.memory.json' ) ) or die 'open: ' . $!;
        {
            local $/;
            $o->{db}->{space}->{''}->{analysis} = JSON->new->utf8->decode( <MEMORY> );
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
    eval { $o->ReadAnalysis( $o ); };
    ok( !$@, 'ReadAnalysis1' );
    isa_ok( ( $_ = $cv->recv ), 'Lim::Error', 'ReadAnalysis1' );
    is( $_->toString, 'Module: Lim::Plugin::Zonalizer::Server Code: 400 Message: invalid_api_version', 'ReadAnalysis1' );

    $cv = AnyEvent->condvar;
    undef $@;
    eval { $o->ReadAnalysis( $o, { version => 1 } ); };
    ok( !$@, 'ReadAnalysis2' );
    ok( ( $_ = $cv->recv ), 'ReadAnalysis2' );
    is_deeply( $_, $r->{ReadAnalysis2}, 'ReadAnalysis2' );

    $cv = AnyEvent->condvar;
    undef $@;
    eval { $o->ReadAnalysis( $o, { version => 1, limit => 2 } ); };
    ok( !$@, 'ReadAnalysis3' );
    ok( ( $_ = $cv->recv ), 'ReadAnalysis3' );
    is_deeply( $_, $r->{ReadAnalysis3}, 'ReadAnalysis3' );

    $cv = AnyEvent->condvar;
    undef $@;
    eval { $o->ReadAnalysis( $o, { version => 1, limit => 2, after => 'test-id-2' } ); };
    ok( !$@, 'ReadAnalysis4' );
    ok( ( $_ = $cv->recv ), 'ReadAnalysis4' );
    is_deeply( $_, $r->{ReadAnalysis4}, 'ReadAnalysis4' );

    $cv = AnyEvent->condvar;
    undef $@;
    eval { $o->ReadAnalysis( $o, { version => 1, limit => 2, after => 'test-id-4' } ); };
    ok( !$@, 'ReadAnalysis5' );
    ok( ( $_ = $cv->recv ), 'ReadAnalysis5' );
    is_deeply( $_, $r->{ReadAnalysis5}, 'ReadAnalysis5' );

    $cv = AnyEvent->condvar;
    undef $@;
    eval { $o->DeleteAnalysis( $o ); };
    ok( !$@, 'DeleteAnalysis1' );
    isa_ok( ( $_ = $cv->recv ), 'Lim::Error', 'DeleteAnalysis1' );
    is( $_->toString, 'Module: Lim::Plugin::Zonalizer::Server Code: 400 Message: invalid_api_version', 'DeleteAnalysis1' );

    $cv = AnyEvent->condvar;
    undef $@;
    eval { $o->DeleteAnalysis( $o, { version => 1 } ); };
    ok( !$@,        'DeleteAnalysis2' );
    ok( !$cv->recv, 'DeleteAnalysis2' );

    $cv = AnyEvent->condvar;
    undef $@;
    eval { $o->ReadAnalysis( $o, { version => 1 } ); };
    ok( !$@, 'ReadAnalysisEnd' );
    ok( ( $_ = $cv->recv ), 'ReadAnalysisEnd' );
    is_deeply( $_, { analysis => [] }, 'ReadAnalysisEnd' );
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
