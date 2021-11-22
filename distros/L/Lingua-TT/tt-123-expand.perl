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
our $sort         = 0; ##-- sort input file(s)?
our $merge        = 1; ##-- merge multiple sorted input file(s)?
our $moot_eos_hack = 0; ##-- moot-compatible eos hack? --------------- BROKEN ------------------

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	  'help|h' => \$help,
	  #'man|m'  => \$man,
	  'version|V' => \$version,
	  'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'sort|s!' => \$sort,
	   'merge|m!' => \$merge,
	   'moot-eos-hack|eos-hack|eh!' => \$moot_eos_hack,
	   'keeptmp|keep|k!' => \$FS_KEEP,
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
## MAIN
##----------------------------------------------------------------------

push(@ARGV,'-') if (@ARGV < 1);

##-- force strict lexical ordering
$ENV{LC_ALL} = 'C';
$FS_VERBOSE = $verbose;

##-- sort input file(s)
our @in0 = @ARGV;
our (@in1);
if ($sort) {
  @in1 = fs_filesort(@in0);
} elsif (@ARGV > 1 && $merge) {
  @in1 = fs_filemerge(@in0);
} else {
  @in1 = @in0;
}

##-- open output file
open(OUT,">$outfile")
  or die("$prog: open failed for output file '$outfile': $!");
select OUT;

foreach $infile (@in1) {
  open(IN,"<$infile")
    or die("$prog: open failed for (sorted) input file '$infile': $!");

  our @prf = qw(); ##-- $prefixI => [$prefixKey,$prefixF]
  while (defined($_=<IN>)) {
    if (/^%%/ || /^$/) {
      ##-- pass through comments and blank lines
      print $_;
      next;
    }
    chomp;

    ##-- check for prefixes
    @key = split(/\t/,$_);
    $f   = pop(@key);
    foreach $pi (0..$#key) {
      if (!$prf[$pi] || $prf[$pi][0] ne $key[$pi]) {
	##-- prefix mismatch: dump remaining buffered prefix data
	foreach $pj (reverse $pi..$#prf) {
	  #$prf[0][1]=$prf[0][1]*2+1 if ($moot_eos_hack && $pi==0 && $pj==0 && $prf[0][0] eq '__$');
	  #$prf[0][1]=$prf[0][1] if ($moot_eos_hack && $pi==0 && $pj==0 && $prf[0][0] eq '__$');
	  print join("\t", (map {$_->[0]} @prf[0..$pj]), $prf[$pj][1]), "\n";
	}
	splice(@prf,$pi,@prf-$pi,map {[$_,$f]} @key[$pi..$#key]);
	last;
      }
      else {
	##-- prefix match: add current freq
	$prf[$pi][1] += $f;
      }
    }
  }
  ##-- end of file: dump any remaining prefixes
  foreach $pj (reverse 0..$#prf) {
    #$prf[0][1]=$prf[0][1]*2+1 if ($moot_eos_hack && $pj==0 && $prf[0][0] eq '__$');
    #$prf[0][1]=$prf[0][1] if ($moot_eos_hack && $pj==0 && $prf[0][0] eq '__$');
    print join("\t", (map {$_->[0]} @prf[0..$pj]), $prf[$pj][1]), "\n";
  }

  close(IN);
}

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-123-expand.perl - expand all (k<=n)-grams in verbose n-gram files

=head1 SYNOPSIS

 tt-123-expand.perl [OPTIONS] VERBOSE_123_FILE(s)...

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -sort  , -nosort   ##-- do/don't sort all inputs (default=don't)
   -merge , -nomerge  ##-- do/don't merge sorted inputs (default=do)
   -keep  , -nokeep   ##-- do/don't keep temporary files (default=don't)
   -moot-eos-hack     ##-- for moot, set f(__$) := 2*sum(f(* __$))+1 [default=no] : BROKEN
   -no-eos-hack       ##-- disable moot eos hack : BROKEN
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

