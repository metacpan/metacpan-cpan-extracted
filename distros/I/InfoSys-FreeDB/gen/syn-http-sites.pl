require InfoSys::FreeDB;

# Create a HTTP connection
my $fact = InfoSys::FreeDB->new();
my $conn = $fact->create_connection( {
    client_name => 'testing-InfoSys::FreeDB',
    client_version => $InfoSys::FreeDB::VERSION,
} );

# Get sites from FreeDB
my $res = $conn->sites();

# Write the sites to STDERR
use IO::Handle;
my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
foreach my $site ( $res->get_site() ) {
    $fh->print( join(', ',
        $site->get_address(),
        $site->get_description(),
        $site->get_latitude(),
        $site->get_longitude(),
        $site->get_port(),
        $site->get_protocol(),
        $site->get_site(),
    ), "\n" );
}
1;
