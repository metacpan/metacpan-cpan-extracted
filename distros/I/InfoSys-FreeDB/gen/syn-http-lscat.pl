require InfoSys::FreeDB;

# Create a HTTP connection
my $fact = InfoSys::FreeDB->new();
my $conn = $fact->create_connection( {
    client_name => 'testing-InfoSys::FreeDB',
    client_version => $InfoSys::FreeDB::VERSION,
} );

# Get lscat from FreeDB
my $res = $conn->lscat();

# Write the categories to STDERR
use IO::Handle;
my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
foreach my $cat ( $res->get_category() ) {
    $fh->print( "$cat\n" );
}
1;
