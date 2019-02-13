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

our $VERSION = "0.12";

##-- program vars
our $progname     = basename($0);
our $verbose      = 1;

our $outfile      = '-';
our %diffargs     = qw();
our %saveargs     = (shared=>1, context=>undef, syntax=>1);

our $select_code = '';
our $select_other = 0;

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'man|m'  => \$man,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- selection
	   '0' => sub { $select_code .= 'return 1 if (!$fix);' },
	   '1' => sub { $select_code .= 'return 1 if ($fix && $fix eq 1);' },
	   '2' => sub { $select_code .= 'return 1 if ($fix && $fix eq 2);' },
	   'at|array|a' => sub { $select_code .= 'return 1 if (ref($fix) && ref($fix) eq "ARRAY");' },
	   'comment|cmt|c=s' => sub { $select_code .= 'return 1 if (($cmt||"") =~ m/'.$_[1].'/o);'; },
	   'eval-code|E|code|C=s' => sub { $select_code .= $_[1]; },
	   'other|O!' => \$select_other,

	   ##-- I/O
	   'shared|s!' => \$saveargs{shared},
	   'context|k=i' => \$saveargs{context},
	   'header|syntax|S!' => \$saveargs{syntax},
	   'output|o=s' => \$outfile,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>1}) if ($man);
#pod2usage({-exitval=>0,-verbose=>1,-msg=>'Not enough arguments specified!'}) if (@ARGV < 2);

if ($version || $verbose >= 2) {
  print STDERR "$progname version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
push(@ARGV,'-') if (!@ARGV);

##-- compile select sub
our ($op,$min1,$max1,$min2,$max2,$fix,$cmt);
our $select_sub = eval "sub { $select_code; return ".($select_other ? '1' : '0')."; };";
die "$0: could not compile select sub '$select_code': $@" if (!$select_sub);

our $diff = Lingua::TT::Diff->new(%diffargs);
our $dfile = shift(@ARGV);
$diff->loadTextFile($dfile)
  or die("$0: load failed from '$dfile': $!");

##-- select
our ($seq1,$seq2,$aux1,$aux2,$hunks) = @$diff{qw(seq1 seq2 aux1 aux2 hunks)};
foreach $hunk (@$hunks) {
  ($op,$min1,$max1,$min2,$max2,$fix,$cmt) = @$hunk;
  if (!$select_sub->()) {
    ##-- break this hunk
    $fix = 0;
  }
  @$hunk = ($op,$min1,$max1,$min2,$max2,$fix,$cmt);
}

##-- dump
$diff->saveTextFile($outfile, %saveargs)
  or die("$0: diff->saveTextFile() failed for '$outfile': $!");

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-diff-select.perl - select certain hunks of a tt-diff

=head1 SYNOPSIS

 tt-diff-select.perl OPTIONS [TT_DIFF_FILE]

 General Options:
   -help
   -version
   -verbose LEVEL

 Selection Options:
   -fix=WHICH           ##-- select hunks with FIX==WHICH (0,1,2)
   -0                   ##-- ... alias for -fix=0
   -1                   ##-- ... alias for -fix=1
   -2                   ##-- ... alias for -fix=2
   -at                  ##-- select hunks with FIX==@ (explicit resolution with '=')
   -cmt=REGEX           ##-- select hunks with FIX=~REGEX (slash-quoted)
   -code=CODE           ##-- select hunks via perl code (return true to select, false to ignore)
   -other , -noother    ##-- select remaining hunks too (default=-noother)?

 I/O Options:
   -header , -noheader  ##-- do/don't output header comments (default=do)
   -shared , -noshared  ##-- do/don't output shared data lines (default=do)
   -context=K           ##-- set output context size (default=-1: all)
   -output FILE         ##-- output file (default: STDOUT)

 Perl Code variables:
   $diff                                ##-- global diff object
   $seq1,$seq2,$aux1,$aux2,$hunks       ##-- global diff properties
   $hunk                                ##-- current hunk
   $op,$min1,$max,$min2,$max2,$fix,$cmt ##-- current hunk properties

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
