#!perl

use strict;
use warnings;
use Test::More;
use Log::Log4perl;
use AnyEvent;

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

my ( $o, $cv );

Lim->Config->{zonalizer} = { lang => 'en_US', collector => { exec => 't/collectors/do_nothing' } };

isa_ok( $o = Lim::Plugin::Zonalizer::Server->new, 'Lim::Plugin::Zonalizer::Server' );

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
}

$cv = AnyEvent->condvar;
undef $@;
eval { $o->ReadPolicy( $o ); };
ok( !$@ );
isa_ok( ( $_ = $cv->recv ), 'Lim::Error' );
is( $_->toString, 'Module: Lim::Plugin::Zonalizer::Server Code: 400 Message: invalid_api_version' );

done_testing;

sub create_timeout {
    $timeout = AnyEvent->timer(
        after => 300,
        cb    => sub {
            BAIL_OUT 'Timed out';
        }
    );
}
