#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::File::Contents;
use AuthMilterTest;

use Mail::SpamAssassin::Client;
use Test::MockModule;
my $mock_spam = new Test::MockModule( 'Mail::SpamAssassin::Client' );
$mock_spam->mock( new     => sub{
    my ( $class ) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
});
$mock_spam->mock( ping    => sub{
    return 1;
});
$mock_spam->mock( _filter => sub{
    return {
        'isspam'    => 'True',
        'score'     => '1000.0',
        'threshold' => '5.0',
        'message'   => 'GTUBE,NO_RECEIVED,NO_RELAYS,FAKE_SPAMD',
    };
});

if ( ! -e 't/01-spam.t' ) {
    die 'Could not find required files, are we in the correct directory?';
}

chdir 't';

plan tests => 6;

{
    #system 'rm -rf tmp';
    mkdir 'tmp';
    mkdir 'tmp/result';

    AuthMilterTest::run_milter_processing_spam();
    AuthMilterTest::run_smtp_processing_spam();

};


