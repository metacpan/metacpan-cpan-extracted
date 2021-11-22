#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::Dict;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION  = "0.13";
our $encoding = undef;
our $outfile  = '-';

our %apply_opts = (allow_empty=>0);
our $dclass = 'Lingua::TT::Dict';

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$encoding,
	   'json|tj|j!' => sub { $dclass='Lingua::TT::Dict'.($_[1] ? '::JSON' : ''); $encoding='utf8' if ($_[1]); },
	   'include-empty-analyses|allow-empty|empty!' => \$apply_opts{allow_empty},
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>0,-msg=>'No dictionary file specified!'}) if (!@ARGV);

##----------------------------------------------------------------------
## Subs

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- i/o
our $ttout = Lingua::TT::IO->toFile($outfile,encoding=>$encoding)
  or die("$0: open failed for '$outfile': $!");

##-- read dict
my $dictfile = shift(@ARGV);
if ($dclass =~ /JSON/) {
  require Lingua::TT::Dict::JSON;
}
my $dict = $dclass->loadFile($dictfile,encoding=>$encoding)
  or die("$0: ${dclass}::loadFile() failed for dict file '$dictfile': $!");

##-- process token files
foreach $infile (@ARGV ? @ARGV : '-') {
  $ttin = Lingua::TT::IO->fromFile($infile,encoding=>$encoding)
    or die("$0: open failed for '$infile': $!");
  $dict->apply($ttin,$ttout,%apply_opts)
    or die("$0: ${dclass}::apply() failed for file '$infile': $!");
  $ttin->close;
}
$ttout->close();

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-dictapply.perl - apply text-keyed dictionary analyses to TT file(s)

=head1 SYNOPSIS

 tt-dictapply.perl [OPTIONS] DICT_FILE [TT_FILE(s)]

 General Options:
   -help

 I/O Options:
  -output FILE         ##-- default: STDOUT
  -encoding ENCODING   ##-- default: raw
  -json  , -nojson     ##-- do/don't use JSON-encoded dict values
  -empty , -noempty    ##-- do/don't output empty analyses (default=don't)

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
