package GH::Sim4;

require 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw(sim4
		    print_exons
		    );
our @EXPORT = qw();
our $VERSION = '0.01';

my $sim4_error = undef;

my %_default_args = ("W" => 12,	# word size
		     "X" => 12,	# value for terminating word extensions
		     "K" => 16,	# MSP score threshold for first pass
		     "C" => 12,	# MSP score threshold for second pass
		     "R" => 0,	# search dir. (0=forward, 1=reverse, 2=both)
		     "D" => 10,	# bound for the range of diag's w/in 
				# consecutive msp's in an exon
		     "H" => 100, # weight factor for MSP scores in relinking
				# DEFAULT_WEIGHT, but not from sim4 usage comment... 
		     "E" => 3,	# 
		     "A" => 0,	# whether or not to include alignment text in hash
		     "P" => 0,	# if not 0, remove poly-A tails XXXX
		     "N" => 0,	# sequence accuracy (non-zero => very accruate)
		     "B" => 1,	# if 0, disallow amBiguity codes.
		     "S" => undef, # coding region specification
		     "PrintError" => 0,
		     "RaiseError" => 0,		     
		   );

 

bootstrap GH::Sim4 $VERSION;

# Preloaded methods go here.

sub sim4 {
  my ($g, $c, $optional_args) = @_;
  my ($retval);
  my (%args);
  my ($key);

  # merge the default and optional arguement hashes.
  %args = %_default_args;
  if (defined($optional_args)) {
    foreach $key (keys %$optional_args) {
      $args{$key} = $optional_args->{$key};
    }
  }

  #
  # By calling my xs routine inside an eval, I can catch croak()s
  # and do The Right Thing.
  #
  eval {
    $retval = _sim4($g, $c, \%args);
  };
  if ($@) {
    $sim4_error = $@;
    if ($args{"PrintError"}) {
      warn($@);
    }
    if ($args{"RaiseError"}) {
      die($@);
    }
    return(undef);
  }
  else {
    $sim4_error = undef;
    $retval = post_process_result($retval);
    return($retval);
  }
}

sub post_process_result {
  my($result) = @_;
  
  # do any perl level postprocessing of the result hash.
  
  return($result);
}

sub err {
  return($sim4_error);
}

sub print_exons {
  my($result) = @_;
  my($exons, $e);
  my($i) = 0;

  $exons = $result->{exons};
  while($e = $$exons[$i]) {
    printf("%d-%d  (%d-%d)   %d%%",
	   $e->{from1}, $e->{to1}, $e->{from2}, $e->{to2}, $e->{match});    
    # orientation only defined if there is a next exon.
    if ($i < scalar @$exons - 1) {
      print $e->{ori};
    }
    else {
      print "\n";
    }
    $i++;
  }
}



1;
__END__

=head1 NAME

GH::Sim4 - a perl XS encapsulation of the Sim4 alignment tool:

=head1 SYNOPSIS

 # 
 use GH::Sim4 qw/ sim4 /;

 $genomic = "acgtacgtacgtacgtacgtacgtacgtacgtacgtacgtacgtacgtacgtac";
 $cDNA = "acgtacgtacgt";
 $result = sim4($genomic, $cDNA);

 $result = sim4($genomic, $cDNA,
		{"W" => 15, "R" => 1, "RaiseError" => 1});

=head1 DESCRIPTION

GH::Sim4 is a module that provides direct access to the sim4
cDNA-genomic sequence alignment tool.  Sim4 is described in
more detail at: 

=over 4

=item

B<Florea L, Hartzell G, Zhang Z, Rubin GM, Miller W.
A computer program for aligning a cDNA sequence with a
genomic DNA sequence. Genome Res. 1998 Sep;8(9):967-74.>

=item

and

=item

B<http://bio.cse.psu.edu/>

=back

This module has two basic goals: provide the ability to run sim4 from
Perl programs without the overhead of starting a separate process and
provide access to sim4's results without having to catch and parse its
textual output.  It also has the added benefit of providing more
pleasant (for a Perl-ite at least) error handling than is easily
achievable by firing off the command line version.

=head1 EXPORT

Nothing is EXPORTed by default.

=head1 EXPORT_OK

sim4

=head1 ARGUMENTS

C<sim4()> has two required arguments and a third optional argument.
The first argument is a scalar variable containing the genomic
sequence.  The second argument is a scalar variable containing the
cDNA sequence.  The third (optional) argument is a hash containing
option settings.

=head2 Option settings

Sim4 options are set by including their name and value in the optional
(third) argument to the function call.  See the SYNOPSIS above for an
example.  Most of the options have the same names, meanings and
constraints as they have in the stand-alone version of sim4.

Here is their description, cribbed from sim4's usage message.  Default
values are in parentheses:

=over 4

=item

W - word size. (W=12)

=item

X - value for terminating word extensions. (X=12)

=item

K - MSP score threshold for the first pass. (e.g., K=16)

=item

C  -  MSP score threshold for the second pass. (e.g., C=12)

=item

R - Search the direct sequence or reverse complement of the cDNA: 0 -
search the '+' (direct) strand only; 1 - search the '-' strand only; 2
- search both strands and report the best match.  

The coordinates of the matches that sim4 reports are in the cDNA
sequence that gave the better alignment.  In other words, for a
forward match, position 10 is the 10th base in the cDNA sequence as it
was handed to sim4().  For a reverse match, position 10 is the 10th
base in the reverse complement of the cDNA sequence, which corresponds
to position "length of the cDNA minus 10 minus 1" in the original
sequence. (R=2)

=item

D - bound for the range of diagonals within consecutive msps in an
exon. (D=10)

=item

H - weight factor for MSP scores in relinking. (H=500)

=item

P - if not 0, remove poly-A tails; report coordinates in the '+'
(direct) strand for complement matches; use lav alignment headers in
all display options. (P=0) [XXXX BUG?  Check out how coord's are
returned!]  Poly-A tails are recognized *before* the alignment occurs
and ignored during the alignment process.

=item

N - accuracy of sequences (non-zero for highly accurate). (N=0)

=item

B - if 0, dis-allow ambiguity codes (other than N and X) in the
sequence data. (B=1)

=item

A - must be 0 or 1.  If A=1, sim4()) will include a textual
representation (like that generated by sim4 with its A=1 setting) in
the hash of results under the key "alignment_string".


=back

The B<S> option is not supported.  Setting it will result in the call
to sim4() failing (returning NULL, generating an exception, and/or
printing a warning, depending on the how error handling is
configured).

Two additional options control how errors are handled (modeled on the
Perl DBI interface):

=over 4

=item

B<PrintError> Setting "PrintError" to a true value will cause the module to
make a warn() call if an error occurs.  By default this will cause the
error message to be printed to the standard error stream, but it can
be caught using the $SIG{__WARN__} handler.

=item

B<RaiseError> Setting "RaiseError" to a true value will cause the module to
make a die() call fi an error occurs.  By default this will cause the
application to exit, but it may be caught inside an eval or via the 
$SIG{__DIE} handler.

=back

=head1 RETURN VALUE

B<ICK>.  Given that sim4 succeeds, it's currently returning a big ole'
hash, with just about everything that the sim4 algorithm discovers
tucked in there somewhere.  Not all of the values are guaranteed to be
meaningful (or even valid, I'm not always sure what sim4's thinking),
but the fundamental information is easy to recognize.  When in doubt,
see if it agrees with something that the command line sim4 says.  The
perl Data::Dumper module can be very useful here.  B<Sorry...>.
Suggestions for particularly useful interfaces would be appreciated.

That said, here are some of the interesting bits:

=head2 Exons

The exons element in the hash contains a reference to a list of
hashes, one per each exon that sim4 identifies:

 'exons' => [
                       {
                         'nmatches' => 120,
                         'flag' => 0,
                         'length' => 120,
                         'min_diag' => 0,
                         'to1' => 170,
                         'ori' => ' <-',
                         'to2' => 120,
                         'max_diag' => 0,
                         'ematches' => 0,
                         'alen' => 120,
                         'from1' => 51,
                         'edist' => 0,
                         'from2' => 1,
                         'match' => 100
                       },
                       ...
                       {
                         'nmatches' => 156,
                         'flag' => 0,
                         'length' => 156,
                         'min_diag' => 0,
                         'to1' => 1546,
                         'ori' => undef,
                         'to2' => 684,
                         'max_diag' => 0,
                         'ematches' => 0,
                         'alen' => 156,
                         'from1' => 1391,
                         'edist' => 0,
                         'from2' => 529,
                         'match' => 100
                       }
                     ],


=head3 Exon orientation (ori).

There are four possible values for the "ori" field in the hash of
information about each exon.

=over 4

=item C< -> >  a.k.a. forward.

Sim4 reports this orientation when it recognizes the splice sites
"GT---AG" in the genomic sequence a the edges of the intron.

=item C< <- >  a.k.a. reverse

Sim4 reports this orientation when it recognizes the splice sites
"CT---AC" in the genomic sequence a the edges of the intron.

=item C< -- >  a.k.a. indeterminate

Sim4 reports this orientation when the splice sites seem equally
likely to be either forward or reverse (e.g. the forward score is
equal to the reverse score).

=item C< == >  a.k.a. problematic

Sim4 reports this orientation when this exon and the next one are not
contiguous in the cDNA (e.g., if e1 and 2 are neighboring exons,
[e2->from2 - e1->to2 - 1 != 0]).

=back

=head2 match_orientation

C<match_orientation> is set to either 'forward' or 'reverse',
specifying the orientation in which the best match was found (using
sim4's standard semantics.

 'match_orientation' => 'forward'

=head2 exon_count

C<exon_count> contains the number of exons that sim4 discovered.

 'exon_count' => 7

=head2 number_matches

C<number_matches> specifies the number of bases that sim4 matched
between the cDNA and the genomic sequence.

 'number_matches' => 682,

=head2 coverage_int

C<coverage_int> specifies the number of bases in the genomic sequence
(I think...) that were covered by the alignment.

 'coverage_int' => 684,

=head2 coverage_float

C<coverage_float> specifies the ratio of the number of bases covered
to the number of bases in the genomic sequence.

 'coverage_float' => '1',

=head2 edit_distance

C<edit_distance> counts the number of edit operations in the alignment.

 'edit_distance' => 2,

=head2 alignment_string

  'alignment_string' =>

      0     .    :    .    :    .    :    .    :    .    :
     51 ATGGTGGGTGTGTCGCCGAAGATCGCTCCGTCGATGTTGTCATCGGACTT
        ||||||||||||||||||||||||||||||||||||||||||||||||||
      1 ATGGTGGGTGTGTCGCCGAAGATCGCTCCGTCGATGTTGTCATCGGACTT
    ... 

  Only included in the output when the options include "A" => 1.

  Contains the textual representation of the alignment that the stand-alone
  sim4 application prints out when its A option is set to 1.

=head2 exon_alignment_strings

  An reference to an array of the textual representations of each exon's
  alignment. 

  Only included in the output when the options include "A" => 1.

=head2 Opaque/Problematic fields.

Several of the field in the hash are useful, but require that one
understand what sim4's doing internally.  The alignment operations are
a good example.  Judicious use of Data::Dumper and perusing the sim4
code (particularly sim4.init.c) should give you a handle on them.

=head1 MODULE INTERNALS

The stand alone version of sim4 starts with a C<main()> routine that
lives in the file sim4.init.c.  It is responsible for loading
sequences, processing arguments, and providing results.  All of the
real work is done by a routine called C<SIM4()>, which lives in the
file named sim4b1.c.  When it runs into trouble, it calls various
flavors of C<fatal> routines that throw up their hands, print errors,
and quits.

The perl xs module started life as a minimal wrapper around the
C<SIM4()> call and has sprouted many of the features implemented in
sim4.init.c (frequently by virtual cut-and-paste).  Where something's
broken, it's almost certainly B<my fault>.

There are three levels to my implementation.  The Perl-ish parts live
in Sim4.pm.  There's a minimal Perl XS layer, in Sim4.xs, it's kept
thin because I find miss the support that the I<one true editor> gives
me when I'm working in real Perl or real C.  The bottom layer lives in
sim4_helpers.c and handles calling into the original SIM4 code and
packaging up the results.

=head2 Debugging

Tracking down problems in the code can be a bit difficult, since it's
dynamically loaded into the perl executable at run time.  Here's a
methodology that gives you Perl's debugger to poke around the Perl
code and gdb for poking at the C code.

=over 4

=item

Before you begin, make sure that everythings compiled with debugging
support.  C<Makefile.PL> needs to have something like this:

 'OPTIMIZE' => '-g',

=item

Now, set up a simple test case using the standard perl test harness,
eg:

   use Test;
   use Data::Dumper;
   
   my $result;
   my $cDNA;
   my $genomic;
   
   BEGIN { plan tests => 3 };  # or how ever many you expect
   use GH::Sim4 qw/ sim4 /;
   print "# check that the library loads correctly.\n";
   ok(1); # If we made it this far, we're ok.

    #########################
    #
    # first pass test, just see if it works
    #
    
    print "#################\n# Basic functionality test.\n#\n";
    
    $cDNA = slurp("t/cDNA-1.fasta");
    $genomic = slurp("t/genomic-1.fasta");
    
    undef $result;
    $result = sim4($genomic, $cDNA, {"R" => 0});

    print "# check if sim4 returned a defined value.\n";
    ok(defined($result));
   
    print "# check that it returned the right number of exons.\n";
    ok(scalar @{$result->{exons}}, 7);
    
    print "# check that the alignment is on the forward strand.\n";
    ok($result->{match_orientation}, 'forward');
   
=item

Next, create a gdb init file (C<.gdbinit>) (this will save you a lot
of typing).  This example defines two aliases, C<r> and C<r2> that run
different scripts (as described above).  The particular C<-I> include
flags here are correct for my particular system at the moment, but
might not be for you.  Just crib them from the one Perl uses when you
run a C<make test> on the module.  Be careful that the run line is
either all on a single line or that there's a \ at the end of the line
to continue it onto the next.

  #
  define r
   run -Iblib/arch -Iblib/lib -I/usr/lib/perl5/5.6.0/i386-linux \
       -I/usr/lib/perl5/5.6.0 -d t/sim4.t
  end 
  define r2
   run -Iblib/arch -Iblib/lib -I/usr/lib/perl5/5.6.0/i386-linux \
       -I/usr/lib/perl5/5.6.0 -d /tmp/moose.t
  end 

=item

Next, start up perl inside the debugger.  Assuming that everythings
covered by your path variable, you can just say:

 gdb perl 

=item

Now, start your script.  Since the C<-d> flag is included in the
aliases that you've defined in your C<.gdbinit> file, you'll find
yourself sitting at the perl debugger prompt.

For example, just use the gdb alias that you defined above:

 r

=item

Step through the test script (e.g. using C<n>) until you've passed the
C<use GH::Sim4> line.  Everything is now loaded into memory.  At this
point, you can use a control-C to interupt the perl interpreter and
drop into gdb.  From there you can set breakpoints, examine variables,
continue execution, etc....  The routine C<sim4_helper> is a good
entry point into the C interface code, and C<SIM4> is where all of the
B<real> sim4 magic begins.

=item

At this point, you can move back and forth between the Perl debugger
and gdb, stepping and examining to your hearts content.

=back


=head1 BUGS

Almost certainly.

For example:

=over 4

=item B<Inefficiency> The command line version of sim4 does some fancy
footwork so that various internal data structures are built using the
shorter of the two sequences.  This can really improve performance.
This module doesn't (for the moment) implement that optimization.  It
will be I<Real Soon Now>.

=item B<Memory leaks>.  The stand alone implementation version of
I<sim4> handles fatal exceptions by throwing up its hands and
quitting, without necessarily cleaning up any resources that it may
have allocated.  Since the program just exits, these resources are
magically freed and life goes on happily.  The GH::Sim4 module handles
these programmatic hissy-fits by converting them into perl die()
and/or warn() calls, but it doesn't do any better at cleaning up the
things that sim4's allocated.  Once control returns to the module's
caller, the references to this information are lost and they are
inaccessible.  A long-running program that encounters many exceptional
situations may suffer from this leakage.  This isn't likely to be
fixed.

=item B<Lower case sequence characters>.  The sim4 internals expect
the seqeunces to be upper case.  There is a routine [seq_toupper()]
which will uppercase the sequences for you, but it only checks B<the
first 100 bases> of the sequence to decide whether or not to waste the
time converting it.  This "feature" will remain so that the Perl XS
routines are consistent with the command line application.

=back


=head1 AUTHOR

George Hartzell, hartzell@fruitfly.org

=cut
  

