require InfoSys::FreeDB;

# Create a HTTP connection
my $fact = InfoSys::FreeDB->new();
my $conn = $fact->create_connection( {
    client_name => 'testing-InfoSys::FreeDB',
    client_version => $InfoSys::FreeDB::VERSION,
} );

# Get stat from FreeDB
my $res = $conn->stat();

# Write a bit of stat to STDERR
use IO::Handle;
my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
$fh->print( "\n", $res->get_proto_cur(), "\n" );
1;
