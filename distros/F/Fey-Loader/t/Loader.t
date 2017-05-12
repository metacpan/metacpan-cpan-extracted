use strict;
use warnings;

use Fey::Test;
use Test::More;

use Fey::Loader;

{
    my $warnings = '';
    local $SIG{__WARN__} = sub { $warnings .= $_ for @_ };

    my $loader = Fey::Loader->new( dbh => Fey::Test->mock_dbh() );
    like(
        $warnings, qr/no driver-specific Fey::Loader subclass/,
        'warning was emitted when we could not find a driver-specific load subclass'
    );

    isa_ok( $loader, 'Fey::Loader::DBI' );
}

SKIP:
{
    skip 'These tests require DBD::SQLite 1.14+', 2
        unless eval 'use DBD::SQLite 1.14; 1;';

    my $dbh = Fey::Test->mock_dbh();
    $dbh->{Driver}{Name} = 'SQLite';

    my $loader = Fey::Loader->new( dbh => $dbh );
    isa_ok( $loader, 'Fey::Loader::SQLite' );

    # Make sure Fey::Loader finds the right subclass after that subclass
    # has been loaded.
    $loader = Fey::Loader->new( dbh => $dbh );
    isa_ok( $loader, 'Fey::Loader::SQLite' );
}

done_testing();
