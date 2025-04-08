use strict;
use Test::More;
use IO::String;
use Time::Fake;
require 't/test-lib.pm';

my $client = LLNG::Manager::Test->new( { ini => {} } );

my $pub = Lemonldap::NG::Common::MessageBroker::NoBroker->new(
    {
        checkTime       => 5,
        eventQueueName  => 'llng_events',
        statusQueueName => 'llng_status',
    }
);

my $id = $client->login('dwho');

$pub->publish( 'llng_events', { action => 'logout', id => $id } );
Time::Fake->offset('+6s');
my $res = $client->_get('/',cookie => "lemonldap=$id");
ok( $res->[0] >= 400, 'Logout done' ) or explain($res, '400 or 401');

clean_sessions();
done_testing();
