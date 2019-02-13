#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);


##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.12";

##-- program vars
our $progname     = basename($0);
our $verbose      = 1;

our $outfile      = '-';
our $encoding     = undef;
our $base         = 0; ##-- counting base

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'man|m'  => \$man,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$encoding,
	   '0|zero-based' => sub { $base=0; },
	   '1|one-based' => sub { $base=1; },
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>1}) if ($man);
pod2usage({-exitval=>0,-verbose=>1,-msg=>'No index specified!'}) if (!@ARGV);

if ($version || $verbose >= 2) {
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
## MAIN
##----------------------------------------------------------------------
our $which = shift(@ARGV);
our ($imin,$imax) = split(/[\:\,\.\s]+/, $which);
$imin ||= 0;
$imax   = $imin if (!defined($imax) || $imax eq '');

push(@ARGV, '-') if (!@ARGV);
our $ttout = Lingua::TT::IO->toFile($outfile,encoding=>$encoding)
  or die("$0: open failed for output file '$outfile': $!");
our $outfh = $ttout->{fh};

my ($infh,$line,@buf);
my $senti = $base;
foreach $infile (@ARGV) {
  $ttin = Lingua::TT::IO->fromFile($infile,encoding=>$encoding)
    or die("$0: open failed for input file '$infile': $!");
  $infh = $ttin->{fh};

  ##-- scan for beginning of requested range
  if ($imin > $senti) {
    while (defined($line=<$infh>)) {
      next if ($line !~ /^$/);
      ++$senti;
      last if ($senti >= $imin);
    }
  }

  ##-- scan for end of requested range
  while (defined($line=<$infh>)) {
    $outfh->print($line);
    next if ($line !~ /^$/);
    ++$senti;
    last if ($senti > $imax);
  }
  last if ($senti > $imax);
}


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-get-sentence.perl - get sentence by index

=head1 SYNOPSIS

 tt-get-sentence.perl [OPTIONS] WHICH [TTFILE(s)]

 Arguments:
   WHICH                ##-- index, or range "MIN:MAX"

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -output FILE         ##-- default: STDOUT
   -encoding ENC        ##-- default: (none)
   -0                   ##-- counting starts at zero (default)
   -1                   ##-- counting starts at one

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
