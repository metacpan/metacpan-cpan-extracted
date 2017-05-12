#!/usr/bin/perl
use lib "lib";
eval q[
	use Getopt::WonderBra;
	sub version {
		print "version: x\n";
	};
	sub help {
		print map { s/{PROGNAME}/$0/e; $_ } <DATA>;
	};
	@ARGV = getopt("f:abc-",@ARGV);
	help "no args" unless @ARGV > 1;
	while (($_=shift)ne'--'){
		die "no leading -" unless s/^-//;
		if     (  s/^-// )  {
			die "bad long opt: --$_" unless defined ($_=$shoft{$_});
			$opts{$_}++;
		}
		elsif  (  /^a$/  )  {  $opt{a}++;          }
		elsif  (  /^b$/  )  {  $opt{b}++;          }
		elsif  (  /^c$/  )  {  $opt{c}++;          }
		elsif  (  /^f$/  )  {  push(@ARGV,shift);  }
	};
	push(@{$opt{_}}, splice @ARGV);

	use Data::Dumper;
	print Dumper \%opt;
];
die "$@" if "$@";
__DATA__
usage: {PROGNAME}
	-a frobnicate a
	-b fnord the river b
	-c cannard the canary
	-f<file> file the fnords in file <file>.
