# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'


######################### We start with some black magic to print on failure.


# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mail::IMAPFolderSearch;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $connect = connectInfo();
print "ok 2\n" if ( checkModules() ) ;
testIMAP($connect);


sub connectInfo {
	use MIME::Base64;
	open(IN,'./imap.credentials') || die 'Credentials not supplied!';
	my $credentials = [ <IN> ];
	close(IN);
	my $decoded = decode_base64($credentials->[0]);
	my ($server, $ssl, $port, $user, $password) = split(/,/,$decoded);
	my $connection = { SSL => $ssl,
			   Port => $port,
			   Server => $server,
			   User => $user,
			   Password => $password,
			 };
	return $connection;
}

sub checkModules {
	use IO::Socket::SSL;
	use IO::Socket;
	return 1;
}


sub testIMAP {
	my $connect  = shift;
	print "ok 3\n" if (
			my $imap = Mail::IMAPFolderSearch->new(SSL => $connect->{SSL},
							  Port => $connect->{Port},
							  Server => $connect->{Server},
				          		  )
			);	

	print "ok 4\n" if (
			$imap->login(User => $connect->{User},
		     	Password => $connect->{Password})
		     	);

	$imap->{Folders} = [ qw( INBOX )];

	my $keywords = { 	Keyword1 => { 	Word => 'the', 
						What => 'TEXT' },
				Keyword2 => { 	Word => 'and',
						What => 'NOT BODY' },
			};
	print "ok 5\n" if (
			$imap->searchFolders(Boolean => 'OR', 
					     Keywords => $keywords)
			);
			
		
	my $outfolder = $imap->_getOutFolder();
	$imap->_deleteFolder($outfolder);
	print "ok 6\n" if ( $imap->logout() );
}
