#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::Unigrams;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);


##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.11";

##-- program vars
our $prog     = basename($0);
our $verbose      = 1;

our $outfile      = '-';
our $encoding     = undef;
our $enum_infile  = undef;
our $enum_ids     = 0;

our $globargs = 1; ##-- glob @ARGV?
our $listargs = 0; ##-- args are file-lists?
our $want_cmts = 0;
our $eos       = '';
our $sort      = 'freq'; ##-- one of qw(freq lex none)
our $union     = 0;      ##-- union mode?
our $ugfile0   = undef;  ##-- initial unigram file

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'glob|g!' => \$globargs,
	   'list|l!' => \$listargs,
	   'initial-unigrams|init|i=s' => \$ugfile0,
	   'merge|sum|union|u' => \$union,
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$encoding,
	   'comments|cmts|c!' => \$want_cmts,
	   'eos|s:s' => \$eos,
	   'no-eos|noeos|S' => sub { undef $eos; },
	   #'sort=s' => \$sort,
	   'nosort' => sub { $sort='none'; },
	   'freqsort|fsort|fs' => sub {$sort='freq'; },
	   'lexsort|lsort|ls' => sub {$sort='lex'; },
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);

if ($version || $verbose >= 2) {
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
  my $ttin = Lingua::TT::IO->fromFile($ttfile,encoding=>$encoding)
    or die("$0: open failed for input file '$ttfile': $!");
  my $infh = $ttin->{fh};

  while (defined($_=<$infh>)) {
    chomp;
    next if ((/^\s*%%/ && !$want_cmts));
    $_ = $eos if ($_ eq '');
    next if (!defined($_));
    ++$wf{$_};
  }
  $infh->close();
}

sub process1gFile {
  my $file = shift;
  $ug->loadFile($file,encoding=>$encoding)
    or die("$0: could not load 1-gram file from '$file': $!");
  return $ug;
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

if (defined($ugfile0)) {
  vmsg(2,"$prog: 1g: $ttfile\n");
  processUgFile($ugfile0);
}

push(@ARGV,'-') if (!@ARGV);
our @infiles = $globargs ? (map {glob($_)} @ARGV) : @ARGV;
if ($listargs) {
  ##-- @infiles are file-lists: expand
  @listfiles = @infiles;
  @infiles = qw();
  foreach $listfile (@listfiles) {
    vmsg(1,"$prog: list: $listfile\n");
    open(LIST,"<$listfile")
      or die("$prog: open failed for list file '$listfile': $!");
    push(@infiles,map {chomp; $_} <LIST>);
    close(LIST);
  }
}

##-- guts
foreach $ttfile (@infiles) {
  if (!$union) {
    vmsg(2,"$prog: tt: $ttfile\n");
    processTTFile($ttfile);
  } else {
    vmsg(2,"$prog: 1g: $ttfile\n");
    process1gFile($ttfile);
  }
}

##-- save
$ug->saveNativeFile($outfile,sort=>$sort,encoding=>$encoding)
  or die("$prog: save failed to '$outfile': $!");

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-1grams.perl - get unigrams from TT file(s)

=head1 SYNOPSIS

 tt-1grams.perl [OPTIONS] [TTFILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -union, -nounion     ##-- TTFILE argument(s) are/aren't really unigram files (default=no)
   -list , -nolist      ##-- TTFILE argument(s) are/aren't file-lists (default=no)
   -glob , -noglob      ##-- do/don't glob TTFILE argument(s) (default=do)
   -cmts , -nocmts      ##-- do/don't count comments (default=don't)
   -init 1GFILE         ##-- initialize unigrams from 1GFILE (default=none)
   -eos EOS             ##-- count eos as string EOS (default='')
   -noeos               ##-- do/don't count EOS at all
   -freqsort            ##-- sort output by frequency (default)
   -lexsort             ##-- sort output lexically
   -nosort              ##-- don't sort output at all
   -encoding ENC        ##-- input encoding (default=raw)
   -output FILE         ##-- output file (default=STDOUT)

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
