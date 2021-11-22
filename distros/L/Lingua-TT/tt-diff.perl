#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::Diff;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.13";

##-- program vars
our $prog     = basename($0);
our $verbose  = $Lingua::TT::Diff::vl_warn;

our $outfile      = '-';
our %ioargs       = (encoding=>'UTF-8');
our %saveargs     = (shared=>1, context=>undef, syntax=>1);
our %diffargs     = (auxEOS=>1, auxComments=>1, diffopts=>'');

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'man|m'  => \$man,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- misc
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$ioargs{encoding},
	   'shared|s!' => \$saveargs{shared},
	   'keep|K!'  => \$diffargs{keeptmp},
	   'eos|E!'   => sub { $diffargs{auxEOS}=!$_[1]; },
	   'comments|cmts|cmt|C!'   => sub { $diffargs{auxComments}=!$_[1]; },
	   'context|c|k=i' => \$saveargs{context},
	   'header|syntax|S!' => \$saveargs{syntax},
	   'diff-options|D' => \$diffargs{diffopts},
	   'minimal|d' => sub { $diffargs{diffopts} .= ' -d'; },
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>1}) if ($man);
pod2usage({-exitval=>0,-verbose=>1,-msg=>'Not enough arguments specified!'}) if (@ARGV < 2);

if ($version || $verbose >= $Lingua::TT::Diff::vl_info) {
  print STDERR "$prog version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##-- sanity check(s) & overrides
if ($diffargs{keeptmp}) {
  $diffargs{tmpfile1} //= 'ttdiff_tmp1.t';
  $diffargs{tmpfile2} //= 'ttdiff_tmp2.t';
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
our ($file1,$file2) = @ARGV;
our $diff = Lingua::TT::Diff->new(verbose=>$verbose, %diffargs);
$diff->compare($file1,$file2, %ioargs)
  or die("$prog: diff->compare() failed: $!");
$diff->saveTextFile($outfile, %saveargs)
  or die("$prog: diff->saveTextFile() failed for '$outfile': $!");


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-diff.perl - diff of TT file(s) keyed by token text

=head1 SYNOPSIS

 tt-diff.perl OPTIONS [TTFILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -output FILE         ##-- output file (default: STDOUT)
   -encoding ENC        ##-- input encoding (default: UTF-8) [output is always UTF-8]
   -D DIFF_OPTIONS      ##-- pass DIFF_OPTIONS to GNU diff
   -minimal             ##-- alias for -D='-d'
   -context K           ##-- set output context size (default=-1: all)
   -header , -noheader  ##-- do/don't output header comments (default=do)
   -shared , -noshared  ##-- do/don't output shared data lines (default=do)
   -files  , -nofiles   ##-- do/don't output filenames (default=do)
   -keep   , -nokeep    ##-- do/don't keep temp files (default=don't)
   -eos    , -noeos     ##-- do/don't treat EOS as ordinary tokens (default=don't)
   -cmt    , -nocmt     ##-- do/don't treat comments as ordinary tokens (default=don't)

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
