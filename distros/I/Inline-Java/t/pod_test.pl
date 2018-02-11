use strict ;

use blib ;
use Getopt::Long ;

require Inline::Java ;

my %opts = () ;
GetOptions (\%opts,
	"d",    	# debug
	"s=i",    	# skip to
	"o=i",    	# only
) ;

my $skip_to = $opts{s} || 0 ;
my $cnt = -1 ;

foreach my $podf ('Java.pod', 'Java/Callback.pod', 'Java/PerlNatives/PerlNatives.pod'){
	open(POD, "<$podf") or 
		die("Can't open $podf file") ;
	my $pod = join("", <POD>) ;
	close(POD) ;

	my $del = "\n=for comment\n" ;

	my @code_blocks = ($pod =~ m/$del(.*?)$del/gs) ;

	foreach my $code (@code_blocks){
		$cnt++ ;

		if ((defined($opts{o}))&&($opts{o} != $cnt)){
			print "skipped\n" ;
			next ;
		}

		if ($cnt < $skip_to){
			print "skipped\n" ;
			next ;
		}

		print "-> Code Block $cnt ($podf)\n" ;

		$code =~ s/(\n)(   )/$1/gs ;  
		$code =~ s/(((END(_OF_JAVA_CODE)?)|STUDY)\')/$1, NAME => "main::main" / ;  
		$code =~ s/(STUDY\')/$1, AUTOSTUDY => 1 / ;  

		if (($code =~ /SHARED_JVM/)&&($opts{o} != $cnt)){
			print "skipped\n" ;
			next ;
		}

		$code =~ s/print\((.*) \. \"\\n\"\) ; # prints (.*)/{
			"print (((($1) eq ('$2')) ? \"ok\" : \"not ok ('$1' ne '$2')\") . \"\\n\") ;" ;
		}/ge ;

		my $Entry = '$Entry' ;
		debug($code) ;

		eval $code ;
		if ($@){
			die $@ ;
		}
	}
}


sub debug {
	my $msg = shift ;
	if ($opts{d}){
		print $msg ;
	}
}

