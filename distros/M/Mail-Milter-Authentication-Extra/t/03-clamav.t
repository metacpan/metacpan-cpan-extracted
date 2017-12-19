#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::File::Contents;
use AuthMilterTest;

use HTTP::Tiny;
use Test::MockModule;
my $mock_clam = new Test::MockModule( 'ClamAV::Client' );
$mock_clam->mock( new => sub{
    my ( $class ) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
});
$mock_clam->mock( ping => sub{
    return 1;
});
$mock_clam->mock( scan_scalar => sub{
    my ( $self, $message_ref ) = @_;
    my $message = $$message_ref;
    return 'Mock ClamAV ' if $message =~ /DAoBAnB2FwIeTgwEL9rMEAAAAAAAAAAAAAAAAAAAwBAAAIAQAAAAAAAAAAAAAAAAAADaEAAA9BAA/;
    return 0;
});

if ( ! -e 't/03-clamav.t' ) {
    die 'Could not find required files, are we in the correct directory?';
}

chdir 't';

plan tests => 6;

{
    #system 'rm -rf tmp';
    mkdir 'tmp';
    mkdir 'tmp/result';

    AuthMilterTest::run_milter_processing_clamav();
    AuthMilterTest::run_smtp_processing_clamav();

};


