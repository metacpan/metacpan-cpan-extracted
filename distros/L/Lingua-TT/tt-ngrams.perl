#!/usr/bin/perl -w

use IO::File;
use Getopt::Long ':config'=>'no_ignore_case';
use Pod::Usage;
use File::Basename qw(basename dirname);

use lib '.';
use Lingua::TT;
use Lingua::TT::Unigrams;

BEGIN { select STDERR; $|=1; select STDOUT; $|=0; }

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.11";

##-- program vars
our $prog         = basename($0);
our $outfile      = '-';
our $verbose      = 0;

our $eos	  = '__$';
our $n  	  = 2;

our $listargs = 0;
our $globargs = 0;
our $fieldsep = "\x{0b}"; ##-- field separator (internal); 0x0b=VT (vertical tab)
our $wordsep  = "\t";     ##-- word separator (external)
our $count = 1;           ##-- count-mode (true) or print-mode (false)
our $sort = 'freq';	  ##-- sort order for count-mode

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	  'help|h' => \$help,
	  'version|V' => \$version,
	  'verbose|v=i' => \$verbose,

	   ##-- Behavior
	   'eos|e=s' => \$eos,
	   'n|k=i' => \$n,
	   'field-separator|fs|f=s' => \$fieldsep,
	   'record-separator|rs|r|word-separator|ws|w=s' => \$wordsep,
	   'count|c!' => \$count,
	   'print|p|raw!' => sub { $count=!$_[1]; },

	   ##-- I/O
	   'glob|g!' => \$globargs,
	   'list|l!' => \$listargs,
	   'nosort' => sub { $count=1; $sort='none'; },
	   'freqsort|fsort|freq' => sub {$count=1; $sort='freq'; },
	   'lexsort|lsort|lex' => sub { $count=1; $sort='lex'; },
	   'output|out|o=s' => \$outfile,
	  );

#pod2usage({-msg=>'Not enough arguments specified!', -exitval=>1, -verbose=>0}) if (@ARGV < 1);
pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>1}) if ($man);

if ($version || $verbose >= 1) {
  print STDERR "$prog version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##----------------------------------------------------------------------
## Subs: messages
##----------------------------------------------------------------------

# undef = vmsg($level,@msg)
#  + print @msg to STDERR if $verbose >= $level
sub vmsg {
  my $level = shift;
  print STDERR (@_) if ($verbose >= $level);
}


##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

push(@ARGV,'-') if (!@ARGV);
my @infiles = $globargs ? (map {glob($_)} @ARGV) : @ARGV;
my $ttfiles = \@infiles;
if ($listargs) {
  $ttfiles = [];
  foreach my $listfile (@infiles) {
    open(my $listfh,"<$listfile") or die("$prog: open failed for list-file $listfile: $!");
    while (defined($_=<$listfh>)) {
      chomp;
      next if (/^\s*$/ || /^%%/);
      push(@$ttfiles,$_);
    }
    close($listfh);
  }
}

our (%wf,$ug,$outfh);
my $countsub = undef;
if ($count) {
  %wf = qw(); ##-- ($ngram => $freq, ...)
  $ug = Lingua::TT::Unigrams->new(wf=>\%wf);
  $countsub = sub { ++$wf{$_[0]}; };
} else {
  open($outfh,">$outfile")
    or die("$prog: open failed for output-file '$outfile': $!");
  $countsub = sub { print $outfh $_[0], "\n"; };
}

foreach my $ttfile (@$ttfiles) {
  vmsg(1,"$prog: processing $ttfile...\n");

  our $ttin = Lingua::TT::IO->fromFile($ttfile,encoding=>undef)
    or die("$prog: open failed for '$ttfile': $!");
  our $infh = $ttin->{fh};

  my $last_was_eos = 1;
  my @ng = map {$eos} (1..$n);
  $countsub->(join($wordsep,@ng));

  while (defined($_=<$infh>)) {
    next if (/^\%\%/); ##-- comment or blank line
    chomp;

    if (/^$/) {
      ##-- eos: flush n-gram window
      next if ($last_was_eos);
      foreach (1..$n) {
	shift(@ng);
	push(@ng,$eos);
	$countsub->(join($wordsep,@ng));
      }
      $last_was_eos = 1;
    } else {
      s{\t}{$fieldsep}g if ($fieldsep ne "\t");
      shift(@ng);
      push(@ng,$_);
      $countsub->(join($wordsep,@ng));
      $last_was_eos = 0;
    }
  }

  $ttin->close();

  next if ($last_was_eos);
  foreach (1..$n) {
    shift(@ng);
    push(@ng,$eos);
    $countsub->(join($wordsep,@ng));
  }
}

if ($count) {
  $ug->saveNativeFile($outfile,sort=>$sort,encoding=>undef)
    or die("$prog: save failed to '$outfile': $!");
} else {
  close($outfh)
    or die("$prog: failed to close output file $outfile: $!");
}

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-ngrams.perl - compute n-grams from tt-file(s)

=head1 SYNOPSIS

 tt-ngrams.perl [OPTIONS] TT_FILE(s)...

 General Options:
   -help                     ##-- this help message
   -version                  ##-- print version and exit
   -verbose LEVEL            ##-- set verbosity (0..?)

 N-gram Options:
   -n N                      ##-- set n-gram length (default=2)
   -fs FIELDSEP              ##-- set word-internal field separator (default=VTAB)
   -ws WORDSEP               ##-- set word separator (default=TAB)
   -eos EOS	             ##-- set EOS string (default=__$)

 I/O Options:
   -[no]glob                 ##-- do/don't glob TT_FILE argument(s) (default=don't)
   -[no]list		     ##-- do/don't treat TT_FILE(s) as filename-lists (default=don't)
   -[no]count                ##-- do/don't compute n-gram counts (default=do)
   -raw                      ##-- alias for -nocount
   -nosort                   ##-- don't sort output, implies -count
   -lexsort                  ##-- sort output lexicographically; implies -count
   -freqsort                 ##-- sort output by frequency; implies -count
   -output OUTFILE           ##-- set output file (default=STDOUT)

=cut

###############################################################
## OPTIONS AND ARGUMENTS
###############################################################
=pod

=head1 OPTIONS AND ARGUMENTS

Not yet written.

=cut


###############################################################
# Footer
###############################################################
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 SEE ALSO

perl(1).

=cut

