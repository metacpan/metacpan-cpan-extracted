#! perl

use strict;
use warnings;

use Test::More 0.89;

use Config;
use Cwd qw/getcwd/;
use File::Temp qw/tempdir/;
use ExtUtils::Builder::Util 'get_perl';
use ExtUtils::Manifest 'mkmanifest';

my $tempdir = tempdir(CLEANUP => 1, TEMPLATE => 'ExtUtilsBuilderXXXX');

my $pwd = getcwd;
chdir $tempdir;

open my $mfpl, '>', 'Makefile.PL';

my @touch_prefix = $^O eq 'MSWin32' || $^O eq 'VMS' ? (get_perl(), '-MExtUtils::Command', '-e') : ();
my $touch = join ', ', map { qq{'$_'} } @touch_prefix, 'touch';

printf $mfpl <<'END', $touch;
use ExtUtils::MakeMaker;
use ExtUtils::Builder::MakeMaker;
use ExtUtils::Builder::Util qw/command code/;


WriteMakefile(
	NAME => 'FOO',
	VERSION => 0.001,
	NO_MYMETA => 1,
	NO_META => 1,
);

sub MY::make_plans {
	my ($self, $planner, $config) = @_;
	my $action1 = command(%s, 'very_unlikely_name');
	my $action2 = code(code => 'open my $fh, "\\x{3e}", "other_unlikely_name"');
	$planner->create_node(target => 'foo', actions => [ $action1, $action2 ]);
	$planner->create_node(target => 'pure_all', dependencies => [ 'foo' ], phony => 1);
}

END

close $mfpl;

{
	local $ExtUtils::Manifest::Verbose = 0;
	mkmanifest;
}

system get_perl(), 'Makefile.PL';

ok(-e 'Makefile', 'Makefile exists');

open my $mf, '<', 'Makefile' or die "Couldn't open Makefile: $!";
my $content = do { local $/; <$mf> };

like($content, qr/^\t .* touch .* very_unlikely_name/xm, 'Makefile contains very_unlikely_name');

my $make = $ENV{MAKE} // $Config{make};
system $make;
ok(-e 'very_unlikely_name', "Unlikely file has been touched");
ok(-e 'other_unlikely_name', "Unlikely file has been touched");

chdir $pwd;

done_testing;
