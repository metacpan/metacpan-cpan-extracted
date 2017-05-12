package MyWarn;
use base 'Exporter';
our @EXPORT = 'warn_count';
our $DEBUG = 0;

my %list = (
	'list'=>{
		new=>[[1,'no id',3],[1,'id already exists',3]],
		objExists=>[[1,'no object',2]],
		get=>[[1,'nonexistant attribute',1]],
		attrExists=>[[0,'no warning']],
		set=>[[1,'not enough arguments',3]],
		getMany=>[[2,'undef passed',2]],
		setMany=>[[2,'didn\'t set attribute',1]],
		findIds=>[[1,'not enough arguments',3]],
		findAlias=>[[1,'no alias found',2]],
		pushArray=>[[1,'invalid attribute',2]],
	},
	'fry_cmd'=>{
		runTest=>[[1,'invalid argument type',3]],
		checkArgs=>[[1,'test sub not found',2]],
		runCmd=>[[3,'no _sub attribute'],[3,'caller not in path',1],
			[3,"method caller can't call method",1]],
	},
	fry_sub=>{
		_require=>[[1,'warns via option']],
	},
	fry_opt=>{
		setOptions=>[[2,'invalid option',1]],
		Opt=>[[2,'invalid option skipped',1]],
		preParseCmd=>[[2,'invalid option skipped',1]],
	},
	fry_shell=>{
		unloadGeneral=>[[1,'invalid core class',3]],
		loadFile=>[[1,'invalid file',3]],
		loadPlugins=>[[1,'invalid module',3]],
	}
);
my $warning = 0;
$SIG{__WARN__} =  sub { $warning++; #print "@_" 
}; 
my %methodcount;
sub warn_count { 
       	$warning = 0; 
	my ($pkg,$file) = (caller(0))[0,1]; 
	#$file =~ s#\./t/(\w+)\.t#\1#;
	$file =~ s#[/\w.]+/(\w+)\.t#\1#;
	my ($sub,$method,$methodnum,$opt) = @_;
	$methodnum = $methodcount{$method} || 0;
	$methodcount{$method}++;
	$sub->();
	my ($count,$msg) = @{$list{$file}{$method}[$methodnum]};
	#print "c: @_; $warning,$count,$file,$msg\n" if ($DEBUG);
       	&{"$caller\::ok"}($warning == $count,$opt->{msg} || make_message($method,$msg));
}
sub make_message { return "&$_[0] warning: $_[1]" }

#sub get_warnings { return %{$list{$_[1]} } }
#sub warn_count (&$) { &warning_like($_[0],qr//, $_[1]) }
#warn_count {$cls->new(qw/not complete/)} '&new warning: no id';
1;
