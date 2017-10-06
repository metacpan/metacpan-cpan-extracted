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
my $mock_spam = new Test::MockModule( 'HTTP::Tiny' );
$mock_spam->mock( new     => sub{
    my ( $class ) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
});
$mock_spam->mock( post => sub{
    return {
        'success' => 1,
        'content' => '{"default":{"is_spam":true,"is_skipped":true,"score":15.0,"required_score":15.0,"action":"reject","GTUBE":{"name":"GTUBE","score":0.0}},"message-id":"GTUBE1.1010101@example.net"}',
    };
});

if ( ! -e 't/02-rspamd.t' ) {
    die 'Could not find required files, are we in the correct directory?';
}

chdir 't';

plan tests => 6;

{
    #system 'rm -rf tmp';
    mkdir 'tmp';
    mkdir 'tmp/result';

    AuthMilterTest::run_milter_processing_rspamd();
    AuthMilterTest::run_smtp_processing_rspamd();

};


