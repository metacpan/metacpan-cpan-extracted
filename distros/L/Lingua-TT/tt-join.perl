#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.13";

##-- program vars
our $progname     = basename($0);
our $outfile      = '-';
our $verbose      = 0;

our $format = '1.*,/,2.*';
our $encoding = 'UTF-8'; ##-- default encoding

our $wantComments1 = 1;
our $wantComments2 = 1;

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	  'help|h' => \$help,
	  'man|m'  => \$man,
	  'version|V' => \$version,
	  'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'format|fmt|f=s' => \$format,
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$encoding,
	   'comments1|cmts1|c1!' => \$wantComments1,
	   'comments2|cmts2|c2!' => \$wantComments2,
	   'comments|c!' => sub { $wantComments1=$wantComments2=$_[1]; },
	  );

pod2usage({-exitval=>1,-verbose=>0,-msg=>'Not enough arguments specified!'}) if (@ARGV < 1);
pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>1}) if ($man);

if ($version || $verbose >= 1) {
  print STDERR "$progname version $VERSION by Bryan Jurish\n";
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
## Subs: errors
##----------------------------------------------------------------------

sub error {
  my @msg = @_;
  die("$progname: ", @msg, "\n",
      (defined($cr1->{fh})
       ? ("  > $file1: line ", $cr1->{fh}->input_line_number, "\n")
       : ("  > $file1: (unknown)\n")),
      (defined($cr2->{fh})
       ? ("  > $file2: line ", $cr2->{fh}->input_line_number, "\n")
       : ("  > $file2: (unknown)\n")),
      "  > ");
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

## + format string:
##    FORMAT     ::= FIELDSPECS
##    FIELDSPECS ::= FIELDSPEC ["," FIELDSPECS]
##    FIELDSPEC  ::= [FILENUM "."] FIELDNUM | <constant-string>
##    FILENUM    ::= "1" | "2"
##    FIELDNUM   ::= "*"
##                   | <literal-number-counting-from-1>
##                   | <startIndex>:<endIndex>
## + data format:
##    @fieldspecs = ($fs1,...,$fsN)
##    $fsi        = $string | $fs
##    $fs         = [ $fileIdx, $startNum, $endNum+1 ] ##-- indices may be negative (count from back)
our @fieldspecs = qw();
foreach (split(/[\s\,]+/,$format)) {
  next if (/^\s+$/);

  if ($_ =~ s/^\+//) {
    ##-- constant literal with "+" prefix
    push(@fieldspecs, $_);
    next;
  }

  ($filenum,$field) = split(/\./, $_, 2);
  $filenum = 1 if ($filenum eq '');
  if (!defined($field) || $field eq '') {
    ##-- (compat): constant literal string without "+" prefix
    push(@fieldspecs, join('.',$filenum,(defined($field) ? $field : qw())));
  }
  elsif ($field eq '*') {
    ##-- all fields
    push(@fieldspecs, [ $filenum-1, 0, -1 ]);
  }
  elsif ($field =~ /^([^\:]*):([^\:]*)$/) {
    my ($start,$end) = ($1,$2);
    $start = 1  if (!defined($start) || $start eq '');
    $end   = -1 if (!defined($end) || $end eq '');
    push(@fieldspecs, [ $filenum-1, $start-1, $end ]);
  }
  else {
    push(@fieldspecs, [$filenum-1, $field-1, $field]);
  }
}

$file1 = shift;
$file2 = shift;
$file2 = $file1 if (!defined($file2));

our %ioargs = (encoding=>$encoding);
$cr1 = Lingua::TT::IO->fromFile($file1, %ioargs)
  or die("$progname: Lingua::TT::IO->fromFile($file1) failed: $!");
$cr2 = Lingua::TT::IO->fromFile($file2, %ioargs)
  or die("$progname: Lingua::TT::IO->fromFile($file2) failed: $!");
$cw  = Lingua::TT::IO->toFile($outfile, %ioargs)
  or die("$progname: Lingua::TT::IO->toFile($outfile) failed: $!");

$sboth = bless([],'Lingua::TT::Sentence');
our $s0 = bless([],'Lingua::TT::Sentence');

my ($fspec,$tokboth);
while (1) {
  $s1 = $cr1->getSentence;
  $s2 = $cr2->getSentence;
  last if (!$s1 && !$s2);
  $s1 ||= $s0;
  $s2 ||= $s0;

  ##-- extract comments (indexed by vanilla index)
  @cmts = qw();
  for ($i=0; $i<=$#$s1; ++$i) {
    if ($i<=$#$s1 && $s1->[$i][0] =~ /^%%/) {
      $cmt = splice(@$s1,$i,1);
      push(@{$cmts[$i]}, $cmt) if ($wantComments1);
      --$i;
    }
  }
  for ($i=0; $i<=$#$s2; ++$i) {
    if ($s2->[$i][0] =~ /^%%/) {
      $cmt = splice(@$s2,$i,1);
      push(@{$cmts[$i]}, $cmt) if ($wantComments2);
      --$i;
    }
  }

  ##-- sanity check: sentence length
  error("sentence-length mismatch (", scalar(@$s1), "/", scalar(@$s2), ")") if (@$s1 != @$s2);

  ##-- construct pseudo-sentence
  @$sboth = qw();
  foreach $i (0..$#$s1) {
    @toks = ($s1->[$i], $s2->[$i]);

    ##-- apply formats
    $tokboth = bless([],'Lingua::TT::Token');
    foreach $fspec (@fieldspecs) {
      if (!ref($fspec)) {
	##-- constant literal string
	push(@$tokboth, $fspec);
      }
      else {
	($fileid,$start,$end) = @$fspec;
	if ($start < 0) { $start += @{$toks[$fileid]} + 1; }
	if ($end   < 0) { $end   += @{$toks[$fileid]} + 1; }
	#$start = @{$toks[$fileid]} if ($start > @{$toks[$fileid]});
	$end   = @{$toks[$fileid]} if ($end > @{$toks[$fileid]});
	push(@$tokboth, @{$toks[$fileid]}[$start..($end-1)]);
      }
    }

    push(@$sboth,$tokboth);
  }

  ##-- splice comments back in
  foreach $i (reverse grep {defined($cmts[$_])} (0..$#cmts)) {
    splice(@$sboth,$i,0,@{$cmts[$i]});
  }

  ##-- output
  $cw->putSentence($sboth);
}

##-- cleanup
$cr1->close();
$cr2->close();
$cw->close();


###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-join.perl - join .tt format corpus files

=head1 SYNOPSIS

 tt-join.perl [OPTIONS] FILE1 [FILE2=FILE1]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -format FORMAT  , -f FORMAT
   -output OUTFILE , -o OUTFILE

 Formats:
   FORMAT     ::= FIELDSPECS
   FIELDSPECS ::= FIELDSPEC ["," FIELDSPECS]
   FIELDSPEC  ::= [FILENUM "."] FIELDNUM | <constant-string>
   FILENUM    ::= "1" | "2"
   FIELDNUM   ::= "*" | INDEX | RANGE
   INDEX      ::= <positive-integer>          ##-- offset from start (>=1)
                  | <negative-integer>        ##-- offset from end (<0)
   RANGE      ::= INDEX ":" INDEX             ##-- inclusive

=cut

###############################################################
## OPTIONS
###############################################################
=pod

=head1 OPTIONS

=cut

###############################################################
# General Options
###############################################################
=pod

=head2 General Options

=over 4

=item -help

Display a brief help message and exit.

=item -version

Display version information and exit.

=item -verbose LEVEL

Set verbosity level to LEVEL.  Default=1.

=back

=cut


###############################################################
# Other Options
###############################################################
=pod

=head2 Other Options

=over 4

=item -someoptions ARG

Example option.

=back

=cut


###############################################################
# Bugs and Limitations
###############################################################
=pod

=head1 BUGS AND LIMITATIONS

Probably many.

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

