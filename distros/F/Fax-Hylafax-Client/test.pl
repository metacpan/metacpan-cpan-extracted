use Test::Simple tests => 1;
use Fax::Hylafax::Client;

print q(
To test this module you will need access to a properly configured
HylaFAX server. Do you want to continue? [Y/N]: (Y) );

my $ok = <STDIN>;
chomp $ok;
$ok ||= 'Y';
if ($ok =~ /^Y/i){
	print "\nPlease enter the hostname of the server: (localhost) ";
	my $hostname = <STDIN>;
	chomp $hostname;
	$hostname ||= 'localhost';

	print "Please enter the username to connect as: (anonymous) ";
	my $user = <STDIN>;
	chomp $user;
	$user ||= 'anonymous';

	print "Please enter the password: (anonymous) ";
	my $password = <STDIN>;
	chomp $password;
	$password ||= 'anonymous';

	print "Please enter your e-mail address (the server will send notifications here): ";
	my $notifyaddr = <STDIN>;
	chomp $notifyaddr;

	print "Please enter the fax number to dial: ";
	my $dialstring = <STDIN>;
	chomp $dialstring;

	my $local_dir = `pwd`;
	chomp $local_dir;

	my $docfile = "${local_dir}/test.ps";

	print "We're now ready to connect to the server. Press ENTER to continue.";
	<STDIN>;
	print "\n";

	my $fax = Fax::Hylafax::Client->sendfax(
		host		=> $hostname || '',
		user		=> $user || '',
		password	=> $password || '',
		dialstring	=> $dialstring || '',
		docfile		=> $docfile || '',
		notifyaddr	=> $notifyaddr || '',
		notify		=> 'done',
	);

	ok( $fax->success ? 1 : 0, "Session transcript follows:\n" . $fax->trace);

} else {
	ok( 0, 'Test aborted by user');
}

