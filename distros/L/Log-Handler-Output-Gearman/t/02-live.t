use strict;
use warnings;
use Test::More;
use FindBin qw( $Bin );
use File::Temp qw( tempfile );
use lib ( "$Bin/lib", "$Bin/../lib" );
use TestLib;
use Log::Handler;
use Log::Handler::Output::Gearman;

plan tests => 3;

my %lhog_params = (
    servers => ['127.0.0.1:4731'],
    worker  => 'logger',
    method  => 'do',
);

my %lh_params = (
    %lhog_params,
    prepare_message => sub {
        my ($data) = @_;
        $data->{message} =~ s/FOO/BAR/;
    },
    message_layout => '[%L] %m',
);

my $lhog = Log::Handler::Output::Gearman->new(%lhog_params);
my $lh = Log::Handler->new( gearman => \%lh_params );

my $client = $lhog->gearman_client();
isa_ok( $client, 'Gearman::XS::Client' );

$lhog->reload();    # this fails
is( $lhog->gearman_client(), $client, 'New Gearman::XS::Client the same instance after ->reload() without params' );

SKIP: {
    skip( 'Set $ENV{LHO_GEARMAN_LIVE_TEST} to run this test', 1 )
      if !$ENV{LHO_GEARMAN_LIVE_TEST};

    my ( $fh, $filename ) = tempfile( UNLINK => 1 );

    my $testlib = TestLib->new();
    $testlib->run_gearmand();
    $testlib->run_log_worker($filename);

    $lhog->log("This is a log message\n");
    $lh->critical('This is a Log::Handler message, replace this: FOO');

    $lhog_params{servers} = ['localhost:4731'];

    $lh->reload(%lhog_params);

    $lh->error('Log message after reload, replace this: FOO');

    my $log;
    { local $/ = undef; local *FILE; open FILE, "<$filename" or die $!; $log = <FILE>; close FILE }

    is( $log, <<LOG, 'Logfile got expected content' );
This is a log message
[CRITICAL] This is a Log::Handler message, replace this: BAR
[ERROR] Log message after reload, replace this: BAR
LOG
}

