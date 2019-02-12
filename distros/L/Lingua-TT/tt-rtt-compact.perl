#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::TextAlignment qw(:escape);

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

use strict;

##----------------------------------------------------------------------
## Globals

##-- verbosity levels
our $vl_silent = 0;
our $vl_error = 1;
our $vl_warn = 2;
our $vl_info = 3;
our $vl_trace = 4;

our $prog         = basename($0);
our $verbose      = $vl_info;
our $VERSION	  = 0.11;

our $outfile      = '-';
our %ioargs       = (encoding=>'UTF-8');
our $compact      = $prog =~ /(?:compact|compress|convert)/ ? 1 : 0;

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
my ($help,$version);
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'output|o=s'   => \$outfile,
	   'encoding|e=s' => \$ioargs{encoding},
	   'compact|compress|C|z!' => \$compact,
	   'uncompact|uncompress|u|expand|x|prolix|P!' => sub {$compact=!$_[1]},
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>0,-msg=>'Not enough arguments specified!'}) if (@ARGV < 2);

if ($version) {
  print STDERR "$prog version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##----------------------------------------------------------------------
## messages
sub vmsg {
  my $level = shift;
  print STDERR @_ if ($verbose >= $level);
}
sub vmsg1 {
  my $level = shift;
  vmsg($level, "$prog: ", @_, "\n");
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
my $infile = shift // '-';
my $ta = Lingua::TT::TextAlignment->loadRttFile($infile,%ioargs,compact=>!$compact)
  or die("$prog: failed to load $infile: $!");

$ta->saveRttFile($outfile,%ioargs, compact=>$compact)
  or die("$prog: failed to save $outfile: $!");

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-rtt-convert.perl - convert between compact and prolix RTT dialects

=head1 SYNOPSIS

 tt-rtt-convert.perl [OPTIONS] [RTT_FILE=-]

 General Options:
   -help
   -version
   -verbose LEVEL

 I/O Options:
   -output FILE         # output file in RTT format (default: STDOUT)
   -encoding ENC        # input encoding (default: utf8) [output is always utf8]
   -compact  , -expand  # compact or prolix-mode output?

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
