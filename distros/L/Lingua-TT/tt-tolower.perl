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
our $outfile      = '-';
our $verbose      = 1;

our $encoding = "UTF-8";
our $xlate_all = 1;

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
	   'all|a' => \$xlate_all,
	   'initial|i' => sub { $xlate_all=!$_[1]; },
	  );

pod2usage({
	   -exitval=>0,
	   -verbose=>0
	  }) if ($help);
pod2usage({
	   -exitval=>0,
	   -verbose=>1
	  }) if ($man);

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
push(@ARGV, '-') if (!@ARGV);

our $ttout = Lingua::TT::IO->toFile($outfile,encoding=>$encoding)
  or die("$0: open failed for output file '$outfile': $!");

my ($infile,$ttin,$tok);
foreach $infile (@ARGV) {
  $ttin = Lingua::TT::IO->fromFile($infile,encoding=>$encoding)
    or die("$0: open failed for input file '$infile': $!");

  while (defined($tok=$ttin->getToken)) {
    next if (!$tok->isVanilla);
    $tok->[0] = '' if (!defined($tok->[0]));
    if ($xlate_all) {
      $tok->[0] = lc($tok->[0]);
    } else {
      substr($tok->[0],0,1, lc(substr($tok->[0],0,1)));
    }
  }
  continue {
    $ttout->putToken($tok);
  }
}
$ttout->close();


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-tolower.perl - convert text to lower case in TT files

=head1 SYNOPSIS

 tt-tolower.perl OPTIONS [TTFILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 I/O Options:
   -all , -initial      ##-- which chars of text token? (default: all)
   -output FILE         ##-- default: STDOUT
   -encoding ENCODING   ##-- default: UTF-8

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
