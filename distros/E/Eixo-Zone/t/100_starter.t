use strict;
use Test::More;

use_ok("Eixo::Zone::Starter");

my $TMP_FILE_INNER = 't_file_' . int(rand(9999));
my $TMP_FILE_OUTER = '/tmp/o_t_file_' . int(rand(9999));

open(F, ">", $TMP_FILE_OUTER); close(F);

my $r = Eixo::Zone::Starter->init(

	init=>sub{

		&test_zone();

		exit 0;

	},

	volumes=>{

		'/tmp' => {

			type=>"tmpfs"

		},

		'/proc' => {

			type=>"procfs"

		}
	},

	network=>{

		type=>"simple",

		prefix=>"test", 

		net_ns=>"self",	

		external_addr=>"10.1.44.1/24",

		internal_addr=>"10.1.44.2/24",
	}

);

print $r->{pid} . "\n";

wait();

ok($? == 0, "Zone is correct");

ok(!-f "/tmp/$TMP_FILE_INNER", "Child's files are in its own mount");

done_testing();

unlink($TMP_FILE_OUTER);

sub test_zone{

	
	# let's see what is in our /tmp
	my @elements = &getTmp;

	die "NOT MY OWN TMP" if(@elements);

	# we create a file
	open F, ">/tmp/$TMP_FILE_INNER" || die($!);
	close F;

	@elements = &getTmp;

	die "NOT MY OWN TMP" if(@elements != 1);

	# let's check our own process tree
	my @process = &getProc;

	die "NOT MY OWN /proc" unless(@process == 1);

	# we fork one process and check
	my $pid = fork;
	
	unless($pid){
		sleep(1000);
	}

	@process = &getProc;

	die "NOT MY OWN /proc" unless(@process == 2);
	
	kill("TERM", $pid); wait();

	# we check our own resume
	no strict 'refs';

	my $zone_resume = defined(&{"main::zone_resume"}) && &zone_resume;
	
	unless($zone_resume){
		die "NOT MY ZONE::RESUME\n";
	}

	my @artifacts =map {

		ref($_)
	
	} $zone_resume->artifacts;

	die("DON'T have artifacts") unless((grep { $_ =~ /volume/i} @artifacts) == 2 );
}

sub getTmp{

	opendir(TMP, "/tmp");

	my @elements = grep { $_ !~ /^\.+$/} readdir(TMP);

	closedir(TMP);

	@elements;
}

sub getProc{

	opendir(PROC, '/proc');

	my @process = grep {$_ =~ /^\d+$/} readdir(PROC);

	closedir(PROC);	

	@process;

}

1;
