use Test::More tests => 3;
use Test::Exception;
use lib qw(lib);

BEGIN {
use_ok( 'Luka' );
use_ok( 'Net::FTP' );
}

diag( "Testing die alone, with Net::FTP" );

throws_ok { new_ftp_classic() } qr/^Net::FTP: Bad hostname/, 'error string only';


sub new_ftp_classic {
    my $ftp = Net::FTP->new("ftp.false", (Debug => 0,Passive  => 1)) || die($@);
}
