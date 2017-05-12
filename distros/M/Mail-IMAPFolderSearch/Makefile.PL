use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Mail::IMAPFolderSearch',
    'VERSION_FROM' => 'IMAPFolderSearch.pm', # finds $VERSION
);

maketest();

sub maketest {
	my ($prompt,$server,$ssl,$port,$user,$password);
	print "\n";
	$prompt = "Do you intend to run make test? [yes] ";
	unless (yesno($prompt)) { 
		return 0; 
	}
	print "Enter the IMAP server to test against: ";
	chomp ($server = <STDIN>);
	$prompt = "Enable SSL for test? [yes] ";
	if (yesno($prompt)) { 
		$ssl = 1; 
	} else {
		$ssl = 0;
	}
	print "Port to connect to ";
	if ($ssl == 1) {
		print "[993] ";
	} elsif ($ssl == 0) {
		print "[143] "	
	} 
	chomp ($port = <STDIN>);
	if (($port eq "") && ($ssl == 1)) {
		$port = 993;
	} elsif (($port eq "") && ($ssl == 0)) {
		$port = 143;
	}
	print "Enter user to connect as: ";
	chomp ($user = <STDIN>);
	use Term::ReadKey;
	use MIME::Base64;
	print "Enter the password for this account: ";
	ReadMode 4;
	chomp ($password = <STDIN>);
	ReadMode 0;
	my $encoded = encode_base64("$server,$ssl,$port,$user,$password");
	open(OUT,'>./imap.credentials') || die "unable to open imap.credentials";
	chmod 0600, './imap.credentials';
	print OUT $encoded;
	close(OUT);
	print "\n\nCredentials for $user are stored in ./imap.creditials.\n";
	print "You may wish to delete this file after running make test. ;)\n";
}

sub yesno {
	my $prompt = shift;
	my $mt = 0;
	my $response;
	while ($mt == 0) {
		print $prompt;
		chomp ($response = <STDIN>);
		if ($response eq "") {
			$mt++;
		} elsif ($response =~ /^y/i) { 
			$mt++;
		} elsif ($response =~ /^n/i) {
			return 0;
		} else {
			next;
		}
	}
	return 1;
}
	
