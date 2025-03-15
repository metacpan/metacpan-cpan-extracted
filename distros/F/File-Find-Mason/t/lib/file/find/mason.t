#!/usr/bin/perl

use strict;
use warnings;
use Cwd;
use File::Find;
use File::Find::Mason;
use File::Temp qw/tempdir/;

use Test::More tests=>6;

my %token=(
	shebang   =>'#!/usr/bin/perl',
	args      =>'<%args>',
	once      =>'<%once>',
	perl      =>'<%perl>',
	call      =>'<& /other.mas &>',
	modeline  =>'%# vim:set syntax=mason:',
);
my @tokenOrder=qw/shebang args once perl call modeline/;

my %testfiles=(
	'a.mas'   =>[qw/args/],
	'o.mas'   =>[qw/once/],
	'p.mas'   =>[qw/perl/],
	'c.mas'   =>[qw/call/],
	'm.mas'   =>[qw/modeline/],
	's.mas'   =>[qw/shebang/],
	'sa.mas'  =>[qw/shebang args/],
);

sub create {
	my ($fn,@content)=@_;
	my %type=map {$_=>1} @content;
	open(my $fh,'>',$fn) or die "open failed:  $!";
	foreach my $k (grep {$type{$_}} @tokenOrder) { print $fh "$token{$k}\n" }
	close($fh);
}

my $root=cwd();
my $tmpdir=tempdir('FFM_find_t_XXXXXX',CLEANUP=>1);
ok($root,  'Starting directory found');
ok($tmpdir,'Temporary directory created');

if(-d $tmpdir) {
	chdir($tmpdir) or die "Failed to chdir to $tmpdir";
	foreach my $fn (keys %testfiles) { create($fn,@{$testfiles{$fn}}) }
}

subtest 'List usage:  Find'=>sub {
	plan tests=>10;
	my $find=sub { my ($options)=@_; return map {$_=>1} File::Find::Mason::find($options,'.') };
	my %opt=map {$_=>0} qw/args once perl call modeline/;
	foreach my $shebang (0,1) {
		$opt{shebang}=$shebang;
		is_deeply({&$find({%opt,args=>1})},    {map {$_=>1} map {"./$_"} qw/a.mas/},"Find:  only args (shebang $shebang)");
		is_deeply({&$find({%opt,once=>1})},    {map {$_=>1} map {"./$_"} qw/o.mas/},"Find:  only once (shebang $shebang)");
		is_deeply({&$find({%opt,perl=>1})},    {map {$_=>1} map {"./$_"} qw/p.mas/},"Find:  only perl (shebang $shebang)");
		is_deeply({&$find({%opt,call=>1})},    {map {$_=>1} map {"./$_"} qw/c.mas/},"Find:  only call (shebang $shebang)");
		is_deeply({&$find({%opt,modeline=>1})},{map {$_=>1} map {"./$_"} qw/m.mas/},"Find:  only modeline (shebang $shebang)");
	}
};

subtest 'List usage:  Wanted'=>sub {
	plan tests=>14;
	my $wanted=sub { my ($options,$basefn)=@_; return File::Find::Mason::wanted($options,$basefn) };
	#
	ok( &$wanted({},'a.mas'), 'Wanted:  args');
	ok( &$wanted({},'o.mas'), 'Wanted:  once');
	ok( &$wanted({},'p.mas'), 'Wanted:  perl');
	ok( &$wanted({},'c.mas'), 'Wanted:  call');
	ok( &$wanted({},'m.mas'), 'Wanted:  modeline');
	ok(!&$wanted({},'s.mas'), 'Wanted:  shebang');
	ok(!&$wanted({},'sa.mas'),'Wanted:  shebang args');
	#
	ok(!&$wanted({args=>0},'a.mas'),    'Wanted:  !args');
	ok(!&$wanted({once=>0},'o.mas'),    'Wanted:  !once');
	ok(!&$wanted({perl=>0},'p.mas'),    'Wanted:  !perl');
	ok(!&$wanted({call=>0},'c.mas'),    'Wanted:  !call');
	ok(!&$wanted({modeline=>0},'m.mas'),'Wanted:  !modeline');
	ok(!&$wanted({shebang=>0},'s.mas'), 'Wanted:  !shebang');
	ok(!&$wanted({shebang=>0,args=>0},'sa.mas'),'Wanted:  !shebang !args');
};

subtest 'Wanted usage:  Find'=>sub {
	plan tests=>10;
	my %found;
	my $find=sub { my ($options)=@_; %found=(); return map {$_=>1} File::Find::Mason::find($options,'.') };
	my $cb=sub { my ($fn)=@_; $found{$File::Find::name}=1 };
	my %opt=(wanted=>$cb,map {$_=>0} qw/args once perl call modeline/);
	foreach my $shebang (0,1) {
		$opt{shebang}=$shebang;
		&$find({%opt,args=>1}); is_deeply(\%found, {map {$_=>1} map {"./$_"} qw/a.mas/},"Find:  only args (shebang $shebang)");
		&$find({%opt,once=>1}); is_deeply(\%found, {map {$_=>1} map {"./$_"} qw/o.mas/},"Find:  only once (shebang $shebang)");
		&$find({%opt,perl=>1}); is_deeply(\%found, {map {$_=>1} map {"./$_"} qw/p.mas/},"Find:  only perl (shebang $shebang)");
		&$find({%opt,call=>1}); is_deeply(\%found, {map {$_=>1} map {"./$_"} qw/c.mas/},"Find:  only call (shebang $shebang)");
		&$find({%opt,modeline=>1}); is_deeply(\%found,{map {$_=>1} map {"./$_"} qw/m.mas/},"Find:  only modeline (shebang $shebang)");
	}
};

subtest 'Wanted usage:  Wanted'=>sub {
	plan tests=>14;
	my %found;
	my $wanted=sub { my ($options,$basefn)=@_; %found=(); return File::Find::Mason::wanted($options,$basefn) };
	my $cb=sub { my ($fn)=@_; $found{$fn}=1 };
	my %opt=(wanted=>$cb);
	#
	&$wanted(\%opt,'a.mas'); is_deeply(\%found,{map {$_=>1} qw/a.mas/}, 'Wanted:  args');
	&$wanted(\%opt,'o.mas'); is_deeply(\%found,{map {$_=>1} qw/o.mas/}, 'Wanted:  once');
	&$wanted(\%opt,'p.mas'); is_deeply(\%found,{map {$_=>1} qw/p.mas/}, 'Wanted:  perl');
	&$wanted(\%opt,'c.mas'); is_deeply(\%found,{map {$_=>1} qw/c.mas/}, 'Wanted:  call');
	&$wanted(\%opt,'m.mas'); is_deeply(\%found,{map {$_=>1} qw/m.mas/}, 'Wanted:  modeline');
	&$wanted(\%opt,'s.mas');  is_deeply(\%found,{},                     'Wanted:  shebang');
	&$wanted(\%opt,'sa.mas'); is_deeply(\%found,{},                     'Wanted:  shebang args');
	#
	&$wanted({%opt,args=>0},'a.mas'); is_deeply(\%found,{}, 'Wanted:  !args');
	&$wanted({%opt,once=>0},'o.mas'); is_deeply(\%found,{}, 'Wanted:  !once');
	&$wanted({%opt,perl=>0},'p.mas'); is_deeply(\%found,{}, 'Wanted:  !perl');
	&$wanted({%opt,call=>0},'c.mas'); is_deeply(\%found,{}, 'Wanted:  !call');
	&$wanted({%opt,modeline=>0},'m.mas'); is_deeply(\%found,{}, 'Wanted:  !modeline');
	&$wanted({%opt,shebang=>0},'s.mas');  is_deeply(\%found,{}, 'Wanted:  !shebang');
	&$wanted({%opt,shebang=>0,args=>0},'sa.mas'); is_deeply(\%found,{}, 'Wanted:  !shebang !args');
};

sub cleanup {
	chdir($tmpdir) or return;
	foreach my $fn (grep {-e $_} keys %testfiles) { unlink($fn) }
	if((-d $tmpdir)&&!rmdir($tmpdir)) { print STDERR "Unable to remove $tmpdir" }
	chdir($root) or die "Failed to chdir to $root";
}

END { cleanup() };
