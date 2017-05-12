require InfoSys::FreeDB;
require InfoSys::FreeDB::Entry;

# Read entry from the default CD device
my $entry = InfoSys::FreeDB::Entry->new_from_cdparanoia();

# Create a HTTP connection
my $fact = InfoSys::FreeDB->new();
my $conn = $fact->create_connection( {
    client_name => 'testing-InfoSys::FreeDB',
    client_version => $InfoSys::FreeDB::VERSION,
} );

# Get discid from FreeDB
my $res = $conn->discid( $entry );

# Write the discid to STDERR
use IO::Handle;
my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
$fh->print( $res->get_discid(), "\n" );
1;
