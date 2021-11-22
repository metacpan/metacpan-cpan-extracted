#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::Packed;
use PDL;
use PDL::Ngrams;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);


##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.13";

##-- program vars
our $prog     = basename($0);
our $verbose      = 1;

our $outfile      = '-';
our $encoding     = undef;
our $enum_file    = undef;
our $enum_ids     = 0;
our $N = 2;

our $eos_str = undef; ##-- default: ''
our $eos_id  = undef; ##-- default: id($eos_str) or 0

#our $globargs  = 1; ##-- glob @ARGV?
#our $listargs  = 0; ##-- args are file-lists?
our $eos       = '';     ##-- eos string

our %packopts = (
		 packfmt => 'N',
		 badid => 0,
		 badsym => '',
		 fast => 1,
		);

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- Enum
	   'enum-ids|ids|ei!' => \$enum_ids,
	   'enum-file|efile|ef=s' => \$enum_file,

	   ##-- Packed
	   'buffer|buf|fast!' => \$packopts{fast},
	   'slow|paranoid' => sub { $packopts{fast}=!$_[1]; },
	   'packfmt|pack|p=s' => \$packopts{packfmt},
	   'badid|bad|b=s' => \$packopts{badid},
	   'delimiter|delim|d:s' => \$packopts{delim},
	   'delim-lines|lines|dl' => sub {$packopts{delim}="\n";},
	   'delim-nul|delim-zero|nul|zero|dz' => sub {$packopts{delim}="\0";},

	   ##-- n-grams
	   'eos-string|eos|s=s' => \$eos_str,
	   'eos-id|eosid|S=i' => \$eos_id,
	   'n|N=i' => \$N,

	   ##-- I/O
	   #'glob|g!' => \$globargs,
	   #'list|l!' => \$listargs,
	   'output|o=s' => \$outfile,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>0,-msg=>'No ENUM specified!'}) if (!@ARGV);
#$enum_infile = shift(@ARGV);

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
sub processFile {
  my $pkfile = shift;
  my $pk = Lingua::TT::Packed->new(%packopts);
  $pk->loadFile($pkfile)
    or die("$prog: load failed for packed file '$pkfile': $!");
  my $toks = pdl(long,$pk->ids);

  ##-- count n-grams using PDL::Ngrams
  #my $seq     = $toks->sequence;
  my $offsets = pdl(long,[0])->append(which($toks==$eos_id));
  my $delims  = pdl(long,[$eos_id])->slice("*$N,");
  my ($ngfreqs,$ngelts) = $toks->slice("*$N,")->ng_cofreq(boffsets=>$offsets, delims=>$delims);

  ##-- dump: HOW?!
  my $packfmt_id = "$pk->{packfmt}$N";
  my $packfmt_f  = 'w';
  my ($i);
  foreach $i (0..($ngfreqs->nelem-1)) {
    $outfh->print(pack($packfmt_id.$packfmt_f, $ngelts->slice(",($i)")->list, $ngfreqs->at($i)));
    #$outfh->print(join("\t", $ngelts->slice(",($i)")->list, $ngfreqs->at($i)),"\n");
  }
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- enum
if (!defined($eos_id)) {
  if (defined($enum_file)) {
    $enum = Lingua::TT::Enum->loadFile($enumfile,encoding=>$encoding, noids=>(!$enum_ids))
      or die("$prog: could not load enum file '$enumfile': $!");
  }
  $eos_str = '' if (!defined($eos_str));
  $eos_id = $enum->{sym2id}{$eos_str} if ($enum);
  if (!defined($eos_id)) {
    warn("$prog: could not get id for EOS symbol '$eos_str' -- using 0") if ($enum);
    $eos_id = 0;
  }
  undef($enum);
}

##-- output file
our $outfh = IO::File->new(">$outfile")
  or die("$prog: open failed for output file '$outfile': $!");
binmode($outfh);

##-- guts
push(@ARGV,'-') if (!@ARGV);
foreach $pfile (@ARGV) {
  vmsg(1,"$prog: packed: $pfile\n");
  processFile($pfile);
}

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-pdl-ngrams.perl - get n-grams from packed TT file(s)

=head1 SYNOPSIS

 tt-pdl-ngrams.perl [OPTIONS] [PACKED_FILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Enum Options:
   -enum ENUM           ##-- load enum from file (for -eos=STR)
   -ids  , -noids       ##-- do/don't expect ids in ENUM (default=don't)

 Packing Options:
   -fast                ##-- run in fast buffer mode with no error checks
   -paranoid            ##-- run in slow "paranoid" mode (default)
   -pack TEMPLATE       ##-- pack template for output ids (default='N')
   -delimiter DELIM     ##-- pack record delimiter (default='' (none))

 N-gram Options:
   -eos-str STR         ##-- use id(STR) as EOS marker (default=''); requires -enum
   -eos-id  ID          ##-- use ID as EOS marker (default=0)
   -n N                 ##-- co-occurence window length (default=2)

 I/O Options:
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
