#!/usr/bin/perl -w

use IO::File;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);
#use File::Copy;


use lib '.';
use Lingua::TT;
#use Lingua::TT::Sort qw(:all);

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.13";

##-- program vars
our $prog         = basename($0);
our $outfile      = '-';
our $verbose      = 0;
#our $sort         = 0; ##-- sort input file(s)?
#our $merge        = 1; ##-- merge multiple sorted input file(s)?

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
#$ENV{LC_ALL} = 'C';
#$FS_VERBOSE = $verbose;

##-- open output file
open(OUT,">$outfile")
  or die("$prog: open failed for output file '$outfile': $!");
select OUT;

foreach $infile (@ARGV) {
  open(IN,"<$infile")
    or die("$prog: open failed for input file '$infile': $!");

  our @prf = qw(); ##-- $prefixI => $prefixKey
  while (defined($_=<IN>)) {
    if (/^%%/ || /^$/) {
      ##-- pass through comments and blank lines
      print $_;
      next;
    }
    chomp;

    ##-- split to key & freq
    @key = split(/\t/,$_);
    $f   = pop(@key);

    ##-- copy shared prefixes
    foreach $pi (0..$#key) {
      last if ($key[$pi] ne '');
      $key[$pi] = $prf[$pi];
    }

    ##-- dump
    print join("\t", @key, $f), "\n";

    ##-- update
    @prf = @key;
  }

  close(IN);
}

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-123-uncompact.perl - un-compact prefix-encoded (k<=n)-grams in moot .123 files

=head1 SYNOPSIS

 tt-123-uncompact.perl [OPTIONS] 123_FILE(s)...

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
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

