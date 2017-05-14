use strict;
use Test::More;


use_ok("Eixo::Zone");

my $z = Eixo::Zone->create(

	init=>sub {

		sleep(1);

	},

	volumes=>{

		"/proc" => {

			type=>"procfs"

		}

	}

);

ok(Eixo::Zone->same_namespace($$, $z->{pid}, "net"), "Both processes are in the same net namespace");

ok(!Eixo::Zone->same_namespace($$, $z->{pid}, "pid"), "Both processes are not in the same pid namespace");

ok(Eixo::Zone->same_namespace($$, $z->{pid}, "user"), "Both processes are in the same user namespace");

ok(Eixo::Zone->same_namespace($$, $z->{pid}, "uts"), "Both processes are in the same uts namespace");

ok(!Eixo::Zone->same_namespace($$, $z->{pid}, "mnt"), "Both processes are not in the same mnt namespace");

waitpid($z->{pid}, 0);

done_testing();
