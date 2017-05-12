require InfoSys::FreeDB;
require InfoSys::FreeDB::Entry;

# Read entry from the default CD device
my $entry = InfoSys::FreeDB::Entry->new_from_cdparanoia();

# Create a CDDBP connection
my $fact = InfoSys::FreeDB->new();
my $conn = $fact->create_connection( {
    client_name => 'testing-InfoSys::FreeDB',
    client_version => $InfoSys::FreeDB::VERSION,
    protocol => 'CDDBP',
} );

# Query FreeDB
my $res_q = $conn->query( $entry );
scalar( $res_q->get_match() ) ||
    die 'no matches found for the disck in the default CD-Rom drive';

# Read the first match
my $res_r = $conn->read( ( $res_q->get_match() )[0] );

# Write the entry to STDERR
use IO::Handle;
my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
$res_r->get_entry()->write_fh( $fh );
1;
