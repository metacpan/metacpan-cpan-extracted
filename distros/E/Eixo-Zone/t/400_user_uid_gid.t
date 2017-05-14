use strict;
use Crypt::Passwd;
use Test::More;

use_ok("Eixo::Zone::User::Starter");
use_ok("Eixo::Zone::User::Ctl");

my ($USER, $PASSWORD, $GRP, $UID, $GID);

my %m = Eixo::Zone::User::Ctl->uid_map_get($$);

&create_user;

print "Creado usuario $USER en grupo $GRP con $UID y $GID\n";

my $pid = fork;

unless($pid){

	eval{
		use POSIX;

		setgid($GID);

		setuid($UID);

		die "Cannot set euid and egid" 
			unless(geteuid != 0 && getegid != 0);

		use Eixo::Zone::Artifact::PSInit;
		use Eixo::Zone::Resume;
		use Eixo::Zone::Driver;

		my $z = Eixo::Zone::Artifact::PSInit->new(

			sub {

				print `id`;

				exit 0;
			},

			Eixo::Zone::Resume->new,

			"Eixo::Zone::Driver",

		);

		$z->start(USER=>1);

		waitpid($z->{pid}, 0);

		die "ERROR IN CHILD" unless($? == 0);

	};
	if($@){
		print $@;
		exit 1;
	}

	exit 0;
}

waitpid($pid, 0);

ok($? == 0, "Child process is ok");


done_testing();

if($USER){

	system("userdel $USER");
	system("groupdel $GRP");
}

sub create_user{

	$USER = "test_eixo_" . int(rand(9999));

	$PASSWORD = "blablabla";

	$GRP = "test_eixogr_" . int(rand(9999));

	my $cpass = unix_std_crypt($PASSWORD, "salt");

	system("groupadd $GRP");

	system("useradd -g $GRP -p $cpass $USER");

	$UID = `id $USER -u`;
	chomp($UID);

	$GID = `id $USER -g`;
	chomp($GID);

}
