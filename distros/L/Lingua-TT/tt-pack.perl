#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::Enum;
use Lingua::TT::Packed;

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
our $enumfile     = undef,
our $enum_ids     = 0;

our %packopts = (
		 packfmt => 'N',
		 badid => 0,
		 badsym => '',
		 fast => 0, ##-- -fast doesn't help much for pack()
		);

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- Packed
	   'enum-ids|ids|ei!' => \$enum_ids,
	   'buffer|buf|fast!' => \$packopts{fast},
	   'slow|paranoid' => sub { $packopts{fast}=!$_[1]; },
	   'packfmt|pack|p=s' => \$packopts{packfmt},
	   'badid|bad|b=s' => \$packopts{badid},
	   'delimiter|delim|d:s' => \$packopts{delim},
	   #'delim-lines|lines|dl' => sub {$packopts{delim}="\n";},
	   #'delim-nul|delim-zero|nul|zero|dz' => sub {$packopts{delim}="\0";},

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$encoding,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>0,-msg=>'No ENUM specified!'}) if (!@ARGV);
$enumfile = shift;

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
## MAIN
##----------------------------------------------------------------------

##-- load enum
our $enum = Lingua::TT::Enum->new();
our %enum_io_opts = (encoding=>$encoding, noids=>(!$enum_ids));
$enum = $enum->loadNativeFile($enumfile,%enum_io_opts)
    or die("$prog: could not load enum file '$enumfile': $!");
our $sym2id = $enum->{sym2id};

##-- guts
our $pk = Lingua::TT::Packed->new(%packopts,enum=>$enum)
  or die("$prog: could not create Packed object: $!");

push(@ARGV,'-') if (!@ARGV);
foreach $infile (@ARGV) {
  my $ttin = Lingua::TT::IO->fromFile($infile,encoding=>$encoding)
    or die("$prog: open failed for input file '$infile': $!");

  $pk->packIO($ttin)
    or die("$prog: packIO() failed for input file '$infile': $!");

  $ttin->close();
}

##-- save
$pk->saveFile($outfile)
  or die("$prog: could not save to '$outfile': $!");


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-pack.perl - encode tt files using pre-compiled enum

=head1 SYNOPSIS

 tt-pack.perl [OPTIONS] ENUM [TTFILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -fast                ##-- run in fast buffer mode with no error checks
   -paranoid            ##-- run in slow "paranoid" mode (default)
   -ids  , -noids       ##-- do/don't expect ids in ENUM (default=don't)
   -pack TEMPLATE       ##-- pack template for output ids (default='N')
   -delimiter DELIM     ##-- pack record delimiter (default='' (none))
   -encoding ENC        ##-- input encoding (default=raw)
   -output FILE         ##-- output file (default=STDOUT)

 Some useful pack formats:
   -pack=n              ##-- 16-bit big-endian integers (overflow danger!)
   -pack=N              ##-- 32-bit big-endian integers (default)
   -pack=w              ##-- BER compressed integers (smallest)
   -pack=a              ##-- "\n"-delimited ASCII %d dump (like -pack="A*" -delim="\n")
   -pack=z              ##-- NUL-delimited BER ints       (like -pack=w    -delim="\0")
   -pack=at             ##-- "\n"-delimited ASCII %d dump with tt-style newlines
   -pack=zt             ##-- "\n"-delimited BER ints with tt-style newlines
   #-pack=x              ##-- ASCII hex dump           (uses sprintf())

=cut


###############################################################
## OPTIONS
###############################################################
=pod

=head1 OPTIONS

More useful pack formats:

   -pack=S              ##-- 16-bit local integers
   -pack=L              ##-- 32-bit local integers
   -pack=I              ##-- >=32-bit native integers
   -pack=J              ##-- perl UV integers

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
