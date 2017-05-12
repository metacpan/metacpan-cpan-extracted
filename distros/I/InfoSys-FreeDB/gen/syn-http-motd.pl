require InfoSys::FreeDB;

# Create a HTTP connection
my $fact = InfoSys::FreeDB->new();
my $conn = $fact->create_connection( {
    client_name => 'testing-InfoSys::FreeDB',
    client_version => $InfoSys::FreeDB::VERSION,
} );

# Get motd from FreeDB
my $res = $conn->motd();

# Write the motd to STDERR
use IO::Handle;
my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
$fh->print( $res->get_message_text(), "\n" );
1;
