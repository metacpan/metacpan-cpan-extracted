require InfoSys::FreeDB;

# Create a HTTP connection
my $fact = InfoSys::FreeDB->new();
my $conn = $fact->create_connection( {
    client_name => 'testing-InfoSys::FreeDB',
    client_version => $InfoSys::FreeDB::VERSION,
} );

# Get whom from FreeDB
my $res = $conn->whom();

# Write a bit of whom to STDERR
use IO::Handle;
my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
$fh->print( "\n", $res->get_code(), "\n" );
1;
