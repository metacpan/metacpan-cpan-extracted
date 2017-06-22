#!/usr/bin/env perl

use strict;
use warnings;
use JSON -convert_blessed_universally;
use Test::Most;
use Test::MockModule;
use Data::Faker;
use Data::Printer
    output        => 'stderr',
    colored       => 1,
    deparse       => 1,
    caller_info   => 1,
    show_readonly => 1,
    show_lvalue   => 1,
    max_depth     => 5,
    caller_info   => 1,
    class         => { inherited => 'all', expand => 5 };

my $log;

subtest "Init Logger plain" => sub {
    lives_ok {
        use Log::Log4perl;
        Log::Log4perl->reset();
        use Log::Log4perl::Appender::Graylog;
        use Log::Log4perl::Layout::NoopLayout;
        my $config = <<'END';
log4perl.logger = DEBUG, SERVER
log4perl.appender.SERVER          = Log::Log4perl::Appender::Graylog
log4perl.appender.SERVER.layout = NoopLayout
log4perl.appender.SERVER.PeerAddr = 127.0.0.1
log4perl.appender.SERVER.PeerPort = 12209
log4perl.appender.SERVER.Proto    = udp
log4perl.appender.SERVER.Gzip     = 0
log4perl.appender.SERVER.Chunked = 0
END

        
        Log::Log4perl->init_once( \$config );
        $log = Log::Log4perl->get_logger("log1");
    }
    "lives through setting up logger";
};

subtest "sends though udp plain" => sub {
    my $log_data = Data::Faker->new()->domain_name();
    my $mock     = Test::MockModule->new('IO::Socket::INET');
    $mock->mock(
        'new',
        sub {
            my $proto  = shift;
            my $class  = ref $proto || $proto;
            my %params = @_;
            
            cmp_ok( $params{PeerAddr}, 'eq', "127.0.0.1",
                "PeerAddr is set to localhost" );
            cmp_ok( $params{PeerPort}, '==', 12209,
                "PeerPort is set to 12209  and is a number" );
            cmp_ok( $params{Proto}, 'eq', "udp", "Proto is set to udp" );
            

            return bless \%params, $class;
        }
    );

    $mock->mock(
        'send',
        sub {
            my $self = shift;
            my ($data) = @_;
            my $json =
                JSON->new->utf8->space_after->allow_nonref->convert_blessed;
            my $result;
            lives_ok {
                $result = $json->decode($data);
            }
            "GELF message is json and can be reparsed";

            cmp_ok( $result->{full_message},
                "eq", $log_data, "full_message is $log_data" );
        }
    );
    my $closed = 0;
    $mock->mock(
        'close',
        sub {
            $closed = 1;
        }
    );

    $log->debug($log_data);
    ok( $closed, "Connection verified closed" );
};
done_testing;
