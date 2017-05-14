use strict;
use Test::More;

use_ok("Eixo::Zone::Driver");
use_ok("Eixo::Zone::Resume");
use_ok("Eixo::Zone::Artifact::PSInit");
use_ok("Eixo::Zone::Artifact::FSVolumeTmp");
use_ok("Eixo::Zone::FS::Ctl");

my $TMP_FILE = 't_file_' . int(rand(9999));

my $r = Eixo::Zone::Resume->new;

my $i = Eixo::Zone::Artifact::PSInit->new(

	sub {

		&test_tmp;

		exit 0;	
	},

	$r,

	"Eixo::Zone::Driver"


);

$i->start(MOUNTS=>1);

wait();

ok($? == 0, "Child has terminated properly");

ok(!-f "/tmp/$TMP_FILE", "Tmp file is not in the parent's /tmp");

done_testing;

sub test_tmp{

	my $tmp = Eixo::Zone::Artifact::FSVolumeTmp->new(

		ctl=>"Eixo::Zone::FS::Ctl"

	);
	
	$tmp->mount;

	# let's see what is in our /tmp
	opendir(TMP, "/tmp");

	my @elements = grep { $_ !~ /^\.+$/} readdir(TMP);

	closedir(TMP);

	die "NOT MY OWN TMP" if(@elements);
	
	open (F, '>', "/tmp/$TMP_FILE") || die($!);
	print F "FROM the child\n";
	close F;
}
