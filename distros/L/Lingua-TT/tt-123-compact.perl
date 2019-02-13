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

our $VERSION = "0.12";

##-- program vars
our $prog         = basename($0);
our $outfile      = '-';
our $verbose      = 0;
our $sort         = 0; ##-- sort input file(s)?
our $merge        = 1; ##-- merge multiple sorted input file(s)?

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

  our @prf = qw(); ##-- $prefixI => $prefixKey
  while (defined($_=<IN>)) {
    if (/^%%/ || /^$/) {
      ##-- pass through comments and blank lines
      print $_;
      next;
    }
    chomp;

    ##-- split to key & freq
    @key0 = split(/\t/,$_);
    $f    = pop(@key0);
    @key  = @key0;

    ##-- copy shared prefixes
    foreach $pi (0..$#key) {
      last if (!defined($prf[$pi]) || $key[$pi] ne $prf[$pi]);
      $key[$pi] = ''
    }

    ##-- dump
    print join("\t", @key, $f), "\n";

    ##-- update
    @prf = @key0;
  }

  close(IN);
}

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-123-compact.perl - compact verbose (k<=n)-grams in moot .123 files by prefix-encoding [BROKEN!]

=head1 SYNOPSIS

 tt-123-uncompact.perl [OPTIONS] 123_FILE(s)...

 !!! BROKEN !!!

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -sort  , -nosort   ##-- do/don't sort all inputs (default=don't)
   -merge , -nomerge  ##-- do/don't merge multiple sorted inputs (default=do)
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

