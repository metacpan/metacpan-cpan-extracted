#!perl -T
use warnings; use strict;
use Test::More tests => 5;
use Test::Fatal;
use version;

use lib '.';
use t::Elive;

use Elive;

SKIP: {

    my %result = t::Elive->test_connection(only => 'real');
    my $auth = $result{auth};

    skip ($result{reason} || 'skipping live tests',
	5)
	unless $auth && @$auth;

    my $connection_class = $result{class};

    my $connection = $connection_class->connect(@$auth);
    isa_ok($connection, 'Elive::Connection','connection')
	or exit(1);

    Elive->connection($connection);

    my $good_som;
    {
	is( exception {$good_som = $connection->call('getServerDetails')} => undef, 'legitimate soap call - lives...');
    }

    is( exception {$connection->_check_for_errors($good_som)} => undef, '...and lives when checked');

   my $bad_som;
    {
	local($connection->known_commands->{'unknownCommandXXX'}) = 'r';
	is( exception {$bad_som = $connection->call('unknownCommandXXX')} => undef, 'call to unknown command - intially lives...');
    }

    isnt( exception {$connection->_check_for_errors($bad_som)} => undef, '...but dies when checked');

}

Elive->disconnect;

