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
eval { $o->ReadVersion( $o ); };
ok( !$@ );
isa_ok( ( $_ = $cv->recv ), 'Lim::Error' );
is( $_->toString, 'Module: Lim::Plugin::Zonalizer::Server Code: 400 Message: invalid_api_version' );

$cv = AnyEvent->condvar;
undef $@;
eval { $o->ReadVersion( $o, { version => 1 } ); };
ok( !$@ );
ok( ( $_ = $cv->recv ) );
@{ $_->{zonemaster}->{tests} } = sort { $a->{name} cmp $b->{name} } @{ $_->{zonemaster}->{tests} };
is_deeply(
    $_,
    {
        version    => Lim::Plugin::Zonalizer::Server->VERSION,
        zonemaster => {
            version => Zonemaster->VERSION,
            tests   => [
                {
                    name    => 'Address',
                    version => Zonemaster::Test::Address->VERSION,
                },
                {
                    name    => 'Basic',
                    version => Zonemaster::Test::Basic->VERSION
                },
                {
                    name    => 'Connectivity',
                    version => Zonemaster::Test::Connectivity->VERSION
                },
                {
                    name    => 'Consistency',
                    version => Zonemaster::Test::Consistency->VERSION,
                },
                {
                    name    => 'DNSSEC',
                    version => Zonemaster::Test::DNSSEC->VERSION
                },
                {
                    name    => 'Delegation',
                    version => Zonemaster::Test::Delegation->VERSION,
                },
                {
                    name    => 'Example',
                    version => Zonemaster::Test::Example->VERSION,
                },
                {
                    name    => 'Nameserver',
                    version => Zonemaster::Test::Nameserver->VERSION,
                },
                {
                    name    => 'Syntax',
                    version => Zonemaster::Test::Syntax->VERSION,
                },
                {
                    name    => 'Zone',
                    version => Zonemaster::Test::Zone->VERSION,
                }
            ]
        }
    }
);

done_testing;

sub create_timeout {
    $timeout = AnyEvent->timer(
        after => 300,
        cb    => sub {
            BAIL_OUT 'Timed out';
        }
    );
}
