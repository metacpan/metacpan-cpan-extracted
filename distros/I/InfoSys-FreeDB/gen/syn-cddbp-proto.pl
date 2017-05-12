require InfoSys::FreeDB;

# Create a CDDBP connection
my $fact = InfoSys::FreeDB->new();
my $conn = $fact->create_connection( {
    client_name => 'testing-InfoSys::FreeDB',
    client_version => $InfoSys::FreeDB::VERSION,
    protocol => 'CDDBP',
} );

# What's the current protocol level on FreeDB server?
my $res = $conn->proto();

# Write the current protocol level to STDERR
use IO::Handle;
my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
$fh->print( "\n", $res->get_cur_level(), "\n" );

# Set the protocol level to 3 on FreeDB server?
$res = $conn->proto(3);
1;
