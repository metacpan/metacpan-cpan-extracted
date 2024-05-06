#! perl

use strict;
use warnings;

use Test::More 0.89;

use Config;
use File::Temp qw/tempdir/;
use ExtUtils::Builder::Util 'get_perl';

system $^X, '-e0' and plan(skip_all => 'Can\'t find perl');

my $tempdir = tempdir();

chdir $tempdir;

open my $mfpl, '>', 'Makefile.PL';

my @touch_prefix = $^O eq 'MSWin32' || $^O eq 'VMS' ? (get_perl(), '-MExtUtils::Command', '-e') : ();
my $touch = join ', ', map { qq{'$_'} } @touch_prefix, 'touch';

printf $mfpl <<'END', $touch;
use ExtUtils::MakeMaker;
use ExtUtils::Builder::MakeMaker;
use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::Action::Code;


WriteMakefile(
	NAME => 'FOO',
	VERSION => 0.001,
	NO_MYMETA => 1,
	NO_META => 1,
);

sub MY::make_plans {
	my ($self, $planner, $config) = @_;
	my $action1 = ExtUtils::Builder::Action::Command->new(command => [%s, 'very_unlikely_name']);
	my $action2 = ExtUtils::Builder::Action::Code->new(code => 'open my $fh, "\\x{3e}", "other_unlikely_name"');
	$planner->create_node(target => 'foo', actions => [ $action1, $action2 ]);
	$planner->create_node(target => 'pure_all', dependencies => [ 'foo' ], phony => 1);
}

END

close $mfpl;

system $^X, 'Makefile.PL';

ok(-e 'Makefile', 'Makefile exists');

open my $mf, '<', 'Makefile' or die "Couldn't open Makefile: $!";
my $content = do { local $/; <$mf> };

like($content, qr/^\t .* touch .* very_unlikely_name/xm, 'Makefile contains very_unlikely_name');

my $make = $ENV{MAKE} || $Config{make};
system $make;
ok(-e 'very_unlikely_name', "Unlikely file has been touched");
ok(-e 'other_unlikely_name', "Unlikely file has been touched");

done_testing;
