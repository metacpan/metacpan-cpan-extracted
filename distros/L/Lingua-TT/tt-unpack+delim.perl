#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::Enum;

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

our $packfmt = 'N';
our $delim = undef;
our $membuf = 1;

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'buffer|buf|fast!' => \$membuf,
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$encoding,
	   'enum-ids|ids|ei!' => \$enum_ids,

	   'packfmt|pack|p=s' => \$packfmt,
	   'delim|d:s' => \$delim,
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
my $id2sym = $enum->{id2sym};

##-- guts
our $ttout = Lingua::TT::IO->toFile($outfile,encoding=>$encoding)
  or die("$prog: open failed for output file '$outfile': $!");
our $outfh = $ttout->{fh};

##-- delimiter
if (!defined($delim)) {
  if ($packfmt eq 'w') { $delim = chr(0); }
  else {
    my $reclen = length(pack($packfmt,0));
    $delim = \$reclen;
  }
}
our $lobits = chr(127); ##-- == ~chr(128)


push(@ARGV,'-') if (!@ARGV);
foreach $infile (@ARGV) {
  my $infh = IO::File->new("<$infile")
    or die("$prog: open failed for input file '$infile': $!");

  if ($membuf) {
    ##-- buffer-mode
    local $/=undef;
    $buf = <$infh>;
    if ($packfmt eq 'w') {
      ##-- must clear high bit on final byte for 'w' format
      @ids = map {unpack('w',substr($_,length($_)-1).(substr($_,length($_)-1) & $lobits))} split(/\0/,$buf);
    } else {
      @ids = unpack("${packfmt}*",$buf);
    }
    @txt = @$id2sym[@ids];
    $outfh->print(map {$_."\n"} @txt);
  }
  else {
    ##-- no-buffer mode
    local $/=$delim;
    while (defined($_=<$infh>)) {
      chomp;
      substr($_,length($_)-1) &= $lobits if ($packfmt eq 'w'); ##-- clear hight bit for 'w' format
      $id = unpack($packfmt,$_);
      $txt = $id2sym->[$id];
      if (!defined($txt)) {
	warn("$prog: no enum symbol for id=$id; using empty string");
	$txt = '';
      }
      $outfh->print($txt,"\n");
    }
  }
  $infh->close();
}
$outfh->close();


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
   -buf  , -nobuf       ##-- do/don't buffer whole input files (default=do)
   -ids  , -noids       ##-- do/don't expect ids in ENUM (default=don't)
   -pack TEMPLATE       ##-- pack template for output ids (default='N')
   -delim DELIM         ##-- output token delimiter (default='')
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
