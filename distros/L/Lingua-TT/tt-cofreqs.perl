#!/usr/bin/perl -w

use IO::File;
use Getopt::Long ':config'=>'no_ignore_case';
use Pod::Usage;
use File::Basename qw(basename dirname);

use lib '.';
use Lingua::TT;
use Lingua::TT::Unigrams;
use strict;

BEGIN { select STDERR; $|=1; select STDOUT; $|=0; }

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.11";

##-- program vars
our $prog         = basename($0);
our $outfile      = '-';
our $verbose      = 0;


our $globargs = 1; ##-- glob @ARGV?
our $listargs = 0; ##-- args are file-lists?
our $bos      = '$__';
our $eos      = '__$';
our $n        = 2;	  ##-- co-occurrence window size

our $fieldsep = "\x{0b}"; ##-- field separator (internal); 0x0b=VT (vertical tab)
our $wordsep  = "\t";     ##-- word separator (external)
our $ordered  = 1;        ##-- use ordered skip-grams?

our $osort    = 'freq';   ##-- output sort-mode; one of qw(freq lex none)

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
our ($help,$version);
GetOptions(##-- general
	  'help|h' => \$help,
	  'version|V' => \$version,
	  'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'glob|g!' => \$globargs,
	   'list|l!' => \$listargs,
	   'nosort' => sub { $osort='none'; },
	   'freqsort|fsort' => sub {$osort='freq'; },
	   'lexsort|lsort'  => sub {$osort='lex'; },
	   'output|out|o=s' => \$outfile,

	   ##-- Behavior
	   'eos|e:s' => \$eos,
	   'bos|b:s' => \$bos,
	   'no-eos|noeos|E' => sub { undef $eos },
	   'no-bos|nobos|B' => sub { undef $bos },
	   'sentence-boundary|s:s' => sub { $bos=$eos=$_[1] },
	   'n|k|window-size|window-length|winsize|winlength|wsize|wlen|wl=i' => \$n,
	   'field-separator|fs|f=s' => \$fieldsep,
	   'record-separator|rs|r|word-separator|ws|w=s' => \$wordsep,
	   'directed|d|ordered|order|O!' => \$ordered,
	   'undirected|unordered|unorder|u!' => sub { $ordered=!$_[1]; },
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
## subs: guts

our %wf = qw(); ##-- $text => $freq, ...
our $ug = Lingua::TT::Unigrams->new(wf=>\%wf);

sub processTTFile {
  my $ttfile = shift;
  my $ttin = Lingua::TT::IO->fromFile($ttfile,encoding=>undef)
    or die("$0: open failed for input file '$ttfile': $!");
  my $infh = $ttin->{fh};

  my $last_was_eos = 1;
  my @ng           = ($bos); 	##-- n-gram window (FIFO:push+shift)

  while (defined($_=<$infh>)) {
    next if (/^\%\%/); ##-- ignore comments
    chomp;

    if (/^$/) {
      ##-- eos
      next if ($last_was_eos);
      if (defined($eos)) {
	foreach (grep {defined($ng[$_])} (1..$#ng)) {
	  ++$wf{join($wordsep, $ordered || $ng[$_] lt $eos ? ($ng[$_],$eos) : ($eos,$ng[$_]))};
	}
      }
      $last_was_eos = 1;
      @ng = ($bos);
    }
    else {
      s{\t}{$fieldsep}g if ($fieldsep ne "\t");
      push(@ng,$_);
      shift(@ng) if (@ng > $n);
      foreach (grep {defined($ng[$_])} (0..($#ng-1))) {
	++$wf{join($wordsep, $ordered || $ng[$_] lt $ng[$#ng] ? ($ng[$_],$ng[$#ng]) : ($ng[$#ng],$ng[$_]))};
      }
      $last_was_eos = 0;
    }
  }
  $infh->close();

  ##-- final eos
  return if ($last_was_eos || !defined($eos));
  foreach (grep {defined($ng[$_])} (1..$#ng)) {
    ++$wf{join($wordsep, $ordered || $ng[$_] lt $eos ? ($ng[$_],$eos) : ($eos,$ng[$_]))};
  }

  return;
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
    open(my $listfh,"<$listfile") or die("$0: open failed for list-file $listfile: $!");
    while (defined($_=<$listfh>)) {
      chomp;
      next if (/^\s*$/ || /^%%/);
      push(@$ttfiles,$_);
    }
    close($listfh);
  }
}

##-- guts
foreach my $ttfile (@$ttfiles) {
  vmsg(2,"$prog: tt: $ttfile...\n");
  processTTFile($ttfile);
}

##-- save
$ug->saveNativeFile($outfile,sort=>$osort,encoding=>undef)
  or die("$prog: save failed to '$outfile': $!");

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-cofreqs.perl - compute raw windowed co-occurrence pair frequencies from a tt-file

=head1 SYNOPSIS

 tt-cofreqs.perl [OPTIONS] TT_FILE(s)...

 General Options:
   -help                     ##-- this help message
   -version                  ##-- print version and exit
   -verbose LEVEL            ##-- set verbosity (0..?)

 I/O Options:
   -[no]list            ##-- do/don't treat command-line arguemnts as file-lists (default=no)
   -[no]glob            ##-- do/don't treat command-line arguments as file-globs (default=do)
   -freqsort            ##-- sort output by frequency (default)
   -lexsort             ##-- sort output lexicographically
   -nosort              ##-- don't sort output at all
   -output OUTFILE      ##-- set output file (default=STDOUT)

 Counting Options:
   -n N                 ##-- set co-occurrence window size (default=2)
   -fs FIELDSEP         ##-- set word-internal field separator (default=VTAB)
   -ws WORDSEP          ##-- set word separator (default=TAB)
   -[un]ordered         ##-- do/don't compute ordered co-occurrence pairs (default=-ordered)
   -bos BOS             ##-- count bos as string EOS (default='$__')
   -eos EOS             ##-- count eos as string EOS (default='__$')
   -nobos               ##-- do/don't count BOS at all
   -noeos               ##-- do/don't count EOS at all

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

