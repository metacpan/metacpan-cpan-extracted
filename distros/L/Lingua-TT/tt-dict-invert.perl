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

our $weights = 0; ##-- keep weights in value part of dict?
our $nmax    = -1; ##-- maximum number of target values (-1:no max)?

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   #'man|m'  => \$man,
	   #'version|V' => \$version,
	   #'verbose|v=i' => \$verbose,

	   ##-- misc
	   'weights|weight|w!' => \$weights, ##-- if true, weights will be parsed and appended to dict values
	   'max-values|nmax|n=i' => \$nmax,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$encoding,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>0,-msg=>'No dictionary file specified!'}) if (!@ARGV);

##----------------------------------------------------------------------
## Subs

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- i/o
push(@ARGV,'-') if (!@ARGV);

##-- output dict
my $dict = Lingua::TT::Dict->new();
my $dh   = $dict->{dict};

##-- process token files
foreach $infile (@ARGV ? @ARGV : '-') {
  $ttin = Lingua::TT::IO->fromFile($infile,encoding=>$encoding)
    or die("$0: open failed for '$infile': $!");
  $infh = $ttin->{fh};

  while (defined($_=<$infh>)) {
    next if (/^%%/ || /^$/);
    chomp;
    ($text,@a_in) = split(/\t/,$_);

    foreach (@a_in) {
      $w = $weights && s/(\s*\<[\+\-\d\.eE]+\>\s*)$// ? $1 : undef;
      $dh->{$_} .= "\t".$text.(defined($w) ? $w : '');
    }
  }
  $ttin->close;
}

##-- trim leading TABs
$_=~s/^\t// foreach (values %$dh);

##-- trim to $nmax values
if ($nmax > 0) {
  my (@vals);
  foreach (values %$dh) {
    @vals = split(/\t/,$_);
    if (@vals > $nmax) {
      splice(@vals, $nmax, @vals-$nmax);
      $_ = join("\t",@vals);
    }
  }
}


##-- dump
$dict->saveFile($outfile,encoding=>$encoding);


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-dict-invert.perl - invert TT dict files

=head1 SYNOPSIS

 tt-dict-invert.perl [OPTIONS] [DICT_FILE(s)]

 General Options:
   -help
   #-version
   #-verbose LEVEL

 I/O Options:
   -[no]weight          ##-- do/don't keep FST-style weight suffixes in value part (default=don't)
   -nmax NMAX           ##-- maximum number of target values per key (default=-1: no max)
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
