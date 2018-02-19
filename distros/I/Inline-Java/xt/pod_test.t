use strict ;
use warnings ;
use Test::More;
use Getopt::Long ;
require Inline::Java ;
use Cwd;

my $start_dir = getcwd;
my %opts = () ;
GetOptions (\%opts,
	"d",    	# debug
	"s=i",    	# skip to
	"o=i",    	# only
) ;

my $skip_to = $opts{s} || 0 ;
my $cnt = -1 ;
my @PODS = qw(
  lib/Inline/Java.pod
  lib/Inline/Java/Callback.pod
);
#push @PODS, 'Java/PerlNatives/PerlNatives.pod' if 

foreach my $podf (@PODS) {
	open(POD, "<$podf") or 
		die("Can't open $podf file") ;
	my $pod = join("", <POD>) ;
	close(POD) ;

	my $del = "\n=for comment\n" ;

	my @code_blocks = ($pod =~ m/$del(.*?)$del/gs) ;

	foreach my $code (@code_blocks) {
		$cnt++ ;

		if ((defined($opts{o}))&&($opts{o} != $cnt)){
			note "skipped $cnt";
			next ;
		}
		if ($cnt < $skip_to){
			note "skipped $cnt";
			next ;
		}
		if (
		  ($code =~ /shared_jvm/) &&
		  !(defined($opts{o}) && ($opts{o} == $cnt))
		) {
			note "skipped $cnt, shared_jvm";
			next ;
		}

		note "-> Code Block $cnt ($podf)";

		$code =~ s/(\n)(   )/$1/gs ;
		$code =~ s/print\((.*) \. \"\\n\"\) ; # prints (.*)/{
			"is(($1), ('$2'));" ;
		}/ge ;

		debug($code) ;

		eval $code ;
		is $@, '' or diag "Failed: $code";
		chdir $start_dir; # I::J does chdir which is bad if blows up
	}
}

done_testing;

sub debug {
	my $msg = shift ;
	if ($opts{d}){
		diag $msg ;
	}
}
