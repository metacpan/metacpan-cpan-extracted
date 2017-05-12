#!/usr/bin/perl -w

use Gfsm;
use Getopt::Long qw(:config no_ignore_case);

our ($help);
our $fromlab = $Gfsm::noLabel;
our $tolab   = $Gfsm::epsilon;
our $side    = 'both';
our $outfile = '-';
GetOptions(
	   ##-- general
	   'help|h'=>\$help,
	   ##
	   ##-- which?
	   'side|which|s|w=s' => \$side,
	   'from|f=i' => \$fromlab,
	   'to|t=i'   => \$tolab,
	   'out|o|F=s' => \$outfile,
	  );


our %side2which =
  (
   lo=>$Gfsm::LSLower,
   hi=>$Gfsm::LSUpper,
   all=>$Gfsm::LSBoth,
   lower=>$Gfsm::LSLower,
   upper=>$Gfsm::LSUpper,
   both =>$Gfsm::LSBoth,
  );
our $which   = $side2which{$side};

if ($help || !defined($which)) {
  print STDERR
    ("Usage: $0 [OPTIONS] [FSTFILE]\n",
     " OPTIONS:\n",
     "  -help\n",
     "  -side WHICH    ##-- 'lower', 'upper', or 'both'\n",
     "  -from LABEL\n",
     "  -to   LABEL\n",
     "  -out  OUTFILE\n"
    );
  exit 0;
}

our $fstfile = @ARGV ? shift : '-';


##======================================================================
## Subs: messages
sub vmsg   { print STDERR @_; }
sub vmsg1  { print STDERR "$0: ", @_, "\n"; }
sub vmsg1t { print STDERR  "\t", @_, "\n"; }

##======================================================================
## Main: load fst

vmsg("$0: loading FST... ");

our $fst = Gfsm::Automaton->new();
$fst->load($fstfile)
  or die("$0: load failed for gfsm file '$fstfile'");

vmsg("loaded.\n");

##======================================================================
## Main: process fst

vmsg("$0: processing... ");

our $ai = Gfsm::ArcIter->new();
my ($qid,$lo,$hi);

my $do_lower = ($which==$Gfsm::LSLower || $which==$Gfsm::LSBoth);
my $do_upper = ($which==$Gfsm::LSUpper || $which==$Gfsm::LSBoth);
foreach $qid (0..($fst->n_states-1)) {
  next if (!$fst->has_state($qid));
  for ($ai->open($fst,$qid); $ai->ok; $ai->next) {
    $ai->lower($tolab) if ($do_lower && $ai->lower==$fromlab);
    $ai->upper($tolab) if ($do_upper && $ai->upper==$fromlab);
  }
}

vmsg("done.\n");

##======================================================================
## Main: save

vmsg("$0: saving output FST... ");
$fst->save($outfile)
  or die("$0: save() failed for FST to file '$outfile': $!");
vmsg("saved.\n");

