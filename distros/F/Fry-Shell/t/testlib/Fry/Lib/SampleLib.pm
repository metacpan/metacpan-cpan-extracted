package Fry::Lib::SampleLib;
our @called_cmds;
sub _default_data1 {return 
	{global=>{food=>'pizza'},
	help=>{feed=>{d=>'virtually feeds user'}},
	alias=>{cmds=>{f=>'feed'}}
	}
}
sub _default_data { 
	return { 
		depend=>[':EmptyLib'],
		vars=>{var1=>'',var2=>''},
		opts=>{	},
		cmds=>{cmd1=>{a=>'c1',arg=>'$testcmd',_sub=>sub { &cmdsCalled('cmd1') }},
		#cmds=>{cmd1=>{a=>'c1',_sub=>sub { &cmdsCalled('cmd1') }},
			cmd2=>{_sub=>sub { &cmdsCalled('cmd2');return 0 } }
		},
		subs=>{blah=>{qw/id blah/}},
		#lib=>{cmds=>[qw/libcmd/],
			#not yet
			#vars=>[qw/libvar/]
			#}
	}
}
our $called_tests;
sub t_testcmd { $called_tests++ ;return 1}
my $obj = {};
sub _initLib { $obj = $_[0] if ($_[0]); return $obj}
sub cmdsCalled { push (@called_cmds,$_[0]) }
#used by fry_sub
our @use;
sub import { @use = @_ };
#*import = \&cmdsCalled;
1;
