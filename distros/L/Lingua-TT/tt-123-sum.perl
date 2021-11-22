#!/usr/bin/perl -w

use IO::File;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);
#use File::Copy;

use lib '.';
use Lingua::TT;
use Lingua::TT::Sort qw(:all);

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.13";

##-- program vars
our $prog         = basename($0);
our $outfile      = '-';
our $verbose      = 0;

our $sort0   = 1; ##-- sort first input file?
our $sort1   = 1; ##-- sort other input file(s)?
#our $keeptmp = 0; ##-- keep temp files?

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	  'help|h' => \$help,
	  #'man|m'  => \$man,
	  'version|V' => \$version,
	  'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'sort0|s0!' => \$sort0,
	   'sort1|s1!' => \$sort1,
	   'sort|s!' => sub { $sort0=$sort1=$_[1]; },
	   'keeptmp|keep|k!' => \$FS_KEEP,
	   'output|o=s' => \$outfile,
	  );

#pod2usage({-msg=>'Not enough arguments specified!',-exitval=>1,-verbose=>0}) if (@ARGV < 1);
pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>1}) if ($man);

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
sub sortsum {
  my ($ifile,$ofile) = @_;

  my $ifh = ref($ifile) ? $ifile : IO::File->new("<$ifile");
  die("$prog: open failed for input file '$ifile': $!") if (!defined($ifh));

  my $ofh = ref($ofile) ? $ofile : IO::File->new(">$ofile");
  die("$prog: open failed for output file '$ofile': $!") if (!defined($ofh));

  select($ofh);
  our ($lastkey,$lastf) = (undef,0);
  our ($key,$f);
  while (defined($_=<$ifh>)) {
    if (/^$/ || /^%%/) {
      print $_;
      next;
    }
    s/\r?\n?$//;
    if (/^(.*)\t([^\t]*)$/) {
      ($key,$f) = ($1,$2);
    } else {
      warn("$prog: could not parse merged line '$_'; skipping");
      next;
    }

    if (!defined($lastkey)) {
      ($lastkey,$lastf) = ($key,$f);
    }
    elsif ($key eq $lastkey) {
      $lastf += $f;
    }
    else {
      print $lastkey, "\t", $lastf, "\n";
      ($lastkey,$lastf) = ($key,$f);
    }
  }
  if (defined($lastkey)) {
    print $lastkey, "\t", $lastf, "\n";
  }

  close($ifh) if (!ref($ifile));
  close($ofh) if (!ref($ofile));
  return 1;
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

push(@ARGV,'-') if (@ARGV < 1);

##-- force strict lexical ordering
$ENV{LC_ALL} = 'C';
$FS_VERBOSE = $verbose;

##-- sort initial input file(s)
our $file0 = shift(@ARGV);
our $file0s = $sort0 ? fs_filesort($file0) : $file0;
our $ofile0 = $sort0 ? undef : $file0s;

if (!@ARGV) {
  ##-- just sum over a single (sorted) file
  sortsum($file0s,$outfile) || exit 1;
  exit 0;
}

my ($ofile);
foreach $i (0..$#ARGV) {
  $file1  = $ARGV[$i];
  $file1s = $sort1 ? fs_filesort($file1) : $file1;
  $mergefh = fs_cmdfh("sort -m \"$file0s\" \"$file1s\" |");

  $ofile = $i==$#ARGV ? $outfile : fs_tmpfile;
  vmsg(2,"$prog: ".($i==$#ARGV ? 'OUT' : 'TMP')." $ofile\n");
  open(OUT, ">$ofile")
    or die("$prog: open failed for ".($i==$#ARGV ? '' : 'intermediate ')."output file '$ofile': $!");

  ##-- sort
  sortsum($mergefh,\*OUT)
    or die("$prog: sort sum failed for '$file1' (sorted='$file1s') to '$ofile': $!");

  ##-- unlink temps
  if (defined($file0s) && $file0s ne $file0) {
    vmsg(2,"$prog: UNLINK $file0s\n");
    unlink($file0s);
    $file0s = undef;
  }
  if ($sort1 && !$FS_KEEP) {
    vmsg(2,"$prog: UNLINK $file1s\n");
    unlink($file1s);
  }

  ##-- update
  $file0s = $ofile;
}

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-123-sum.perl - sum over verbose n-gram input files using system sort & merge

=head1 SYNOPSIS

 tt-123-sum.perl [OPTIONS] [VERBOSE_123_FILE(s)...]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -sort0 , -nosort0  ##-- do/don't sort first input file    (default=do)
   -sort1 , -nosort1  ##-- do/don't sort other input file(s) (default=do)
   -sort  , -nosort   ##-- shortcut fot -[no]sort0 -[no]sort1
   -keep  , -nokeep   ##-- do/don't keep temporary files (default=don't)
   -output OUTFILE    ##-- set output file (default=STDOUT)

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

