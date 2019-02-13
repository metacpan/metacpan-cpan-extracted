#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::TextAlignment;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

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
our $VERSION	  = 0.12;

our $outfile      = '-';
our $outfmt       = 'DEFAULT';
our %ioargs       = (encoding=>'UTF-8');

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$ioargs{encoding},
	   'compact|C!' => \$ioargs{compact},
	   'prolix|P|expanded|x!'  => sub {$ioargs{compact}=!$_[1]},
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>0,-msg=>'Not enough arguments specified!'}) if (@ARGV < 2);

if ($version || $verbose >= $vl_trace) {
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
our ($txtfile,$ttfile) = @ARGV;
our $ta = Lingua::TT::TextAlignment->new();

##-- get raw text buffer
vmsg1($vl_trace, "loading text data from $txtfile ...");
$ta->loadTextFile($txtfile,%ioargs)
  or die("$prog: failed to load text buffer from $txtfile: $!");

##-- get tt data with offsets
vmsg1($vl_trace, "loading TT+offset data from $ttfile ...");
$ta->loadTTFile($ttfile,%ioargs)
  or die("$prog: failed to load TT data from $ttfile: $!");

##-- dump as Rtt
vmsg1($vl_trace, "saving to $outfile ...");
$ta->saveRttFile($outfile,%ioargs)
  or die("$prog: save failed to $outfile: $!");
vmsg1($vl_trace, "done.\n");

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-txt-merge.perl - merge raw-text and tokenizer output-files to RTT format

=head1 SYNOPSIS

 tt-txt-merge.perl [OPTIONS] TEXT_FILE TT_FILE

 General Options:
   -help
   -version
   -verbose LEVEL

 I/O Options:
   -output FILE         # output file, RTT format (default: STDOUT)
   -encoding ENC        # I/O encoding (default: utf8)
   -compact  , -prolix  # output compact RTT (-compact) or expanded (-prolix, default)

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
