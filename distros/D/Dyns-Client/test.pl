use Test::More tests => 4;
use ExtUtils::MakeMaker 'prompt';

my ($Username, $Password, $Host, $Domain);
{
	$Username = prompt "Give username";
	last unless $Username;
	$Password = prompt "Give password";
	$Host = prompt "Give host";
	$Domain = prompt "Give domain", "dyns.cx";
}

BEGIN {
	use_ok( "Dyns::Client" );
}

my $dc = Dyns::Client->new();
ok($dc);

my $ip = $dc->get_ip('eth0');
ok($ip);

SKIP: {
	skip "No credentials provided", 1 unless $Username;
	ok(	$dc->update(
			-username 	=> $Username,
			-password 	=> $Password,
			-hostname 	=> $Host,
			-domain	 	=> $Domain,
			-ip		 	=> $ip 
			)
  	);
}
