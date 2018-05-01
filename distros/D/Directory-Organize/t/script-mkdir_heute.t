use strict;
use File::Path;
use File::Spec;
use Test::More;
use Symbol 'gensym';
use IPC::Open3;

eval "use Probe::Perl";
if ($@) {
	plan skip_all => 'Probe::Perl required for testing the script';
}
elsif ('MSWin32' eq $^O) { # man perlport
	plan skip_all => qq(Script is not usable on $^O);
}
else {
	plan tests => 8;
}

my $perl = Probe::Perl->find_perl_interpreter;
my $script = File::Spec->catfile(qw/. mkdir_heute/); 
my $basedir = 't/base';
my @scriptopts = ( '-b', $basedir, '-l', '5', '--notermreadkey');

my $in  = gensym;
my $out = gensym;
my $err = gensym;

setup();

eval {
	my $pid;
	local $SIG{ALRM} = sub { die "not completed\n" };
	alarm(30);   

	$pid = open3($in, $out, $err, $perl, '-Ilib', $script, @scriptopts);
	print $in "q\n";
	is(<$out>,'.',"end with (q)uit");
	like(<$err>,qr/^\+\(plus\): new directory /,"what's on stderr");
	waitpid($pid, 0);

	$pid = open3($in, $out, $err, $perl, '-Ilib', $script, @scriptopts);
	close $in;
	is(<$out>,'.',"EOF in Input");
	like(<$err>,qr/^\+\(plus\): new directory /,"what's on stderr");
	waitpid($pid, 0);

	$pid = open3($in, $out, $err, $perl, '-Ilib', $script, @scriptopts);
	print $in "+ something\n";
	my $dir = <$out>;
	waitpid($pid, 0);
	like($dir,qr(^t/base/),"directory below basedir");
	ok(-d $dir,'new directory created');
	like(<$err>,qr/^\+\(plus\): new directory /,"what's on stderr");
};
unlike($@, qr/^not completed$/, "All tests completed in time");

sub setup {
	rmtree($basedir) if -d $basedir;
}
