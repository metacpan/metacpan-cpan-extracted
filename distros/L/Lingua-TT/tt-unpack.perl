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
		 fast => 0, ##-- -fast helps a lot for unpack()
		);

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'buffer|buf|fast!' => \$packopts{fast},
	   'slow|paranoid' => sub { $packopts{fast}=!$_[1]; },
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$encoding,
	   'enum-ids|ids|ei!' => \$enum_ids,

	   'packfmt|pack|p=s' => \$packopts{packfmt},
	   'badsym|bad|b=s' => \$packopts{badsym},
	   'delimiter|delim|d:s' => \$packopts{delim},
	   'delim-lines|lines|dl' => sub {$packopts{delim}="\n";},
	   'delim-nul|delim-zero|nul|zero|dz' => sub {$packopts{delim}="\0";},
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

##-- open enum
our $enum = Lingua::TT::Enum->new();
our %enum_io_opts = (encoding=>$encoding, noids=>(!$enum_ids));
$enum = $enum->loadNativeFile($enumfile,%enum_io_opts)
    or die("$prog: coult not load enum file '$enumfile': $!");

##-- guts
our $pk = Lingua::TT::Packed->new(%packopts,enum=>$enum)
  or die("$prog: could not create Packed object: $!");

our $ttout = Lingua::TT::IO->toFile($outfile,encoding=>$encoding)
  or die("$prog: open failed for output file '$outfile': $!");

push(@ARGV,'-') if (!@ARGV);
foreach $infile (@ARGV) {
  $pk->clearData();
  $pk->loadFile($infile)
    or die("$prog: could not load packed file '$infile': $!");
  $pk->unpackIO($ttout)
    or die("$prog: unpackIO() failed for packed file '$infile': $!");
}

$ttout->close();


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-unpack.perl - decode packed tt files using pre-compiled enum

=head1 SYNOPSIS

 tt-unpack.perl [OPTIONS] ENUM [PACKED_FILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -fast                ##-- run in fast buffer mode with no error checks
   -paranoid            ##-- run in slow "paranoid" mode (default)
   -badsym SYM          ##-- symbol to use for missing ids (default='')
   -ids  , -noids       ##-- do/don't expect ids in ENUM (default=don't)
   -pack TEMPLATE       ##-- pack template for output ids (default='N')
   -delim DELIMITER     ##-- pack record delimiter (default='' (none))
   -encoding ENC        ##-- output encoding (default=raw)
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
