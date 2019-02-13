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

our $VERSION = "0.12";

##-- program vars
our $progname     = basename($0);
our $verbose      = 1;

our $outfile      = '-';
our %ioargs       = (encoding=>'UTF-8');

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'man|m'  => \$man,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$ioargs{encoding},
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>1}) if ($man);

if ($version || $verbose >= 2) {
  print STDERR "$progname version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
push(@ARGV,'-') if (@ARGV < 2);

##-- process input file(s)
my %atf = qw();  # $analysis_tag => { $tagger_tag => $count, ... }
foreach my $infile (@ARGV) {
  my $ttin = Lingua::TT::IO->fromFile($infile,%ioargs)
    or die("$0: open failed for '$infile': $!");
  my $infh = $ttin->{fh};
  my (@f,$tag,$a,$atag);

  while (defined($_=<$infh>)) {
    next if (/^%%/ || /^\s*$/);
    chomp;
    @f   = split(/\t/,$_);
    $tag = ($f[1] =~ /\[_?([^\s\]]+)[\s\]]/ ? $1 : $f[1]);
    foreach $a (@f[2..$#f]) {
      $atag = ($a =~ /\[_?([^\s\]]+)[\s\]]/ ? $1 : $a);
      ++$atf{$atag}{$tag};
    }
  }
  undef $infh;
  $ttin->close;
}

##-- compute analysis-wise tag-probabilities, entropies
my %ax  = qw(); ##-- $a => "$best_tag_for_a".($verbose ? "\tf=f(t,a)\tN=f(a)\tH=$H_2(T|A=a)")
my ($a,$t2f,$n, %t2p,$tp,$H, $fbest,$tbest);
my $log2 = log(2.0);
sub log2 { return $_[0]==0 ? 'NaN' : log($_[0])/$log2; }
foreach my $a (sort keys %atf) {
  $t2f = $atf{$a};
  $n = 0;
  $n += $_ foreach values (%$t2f);

  ##-- normalize
  $H = 0;
  $fbest = -1;
  $tbest = undef;
  foreach $t (keys %$t2f) {
    $tp = $t2f->{$t} / $n;
    $H -= $tp * log2($tp);

    if ($fbest < $t2f->{$t}) {
      $fbest = $t2f->{$t};
      $tbest = $t;
    }
  }

  ##-- record best translation
  $ax{$a} = $tbest.($verbose ? sprintf("\tf=%d\tN=%d\tH=%.4g",$fbest,$n,$H) : '');
}

##-- dump output
our $ttout = Lingua::TT::IO->toFile($outfile,%ioargs)
  or die("$0: open failed for '$outfile': $!");
my $outfh = $ttout->{fh};

foreach $a (sort keys %ax) {
  print $outfh "$a\t$ax{$a}\n";
}

$ttout->close();

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-tagx-guess.perl - guess tag-translation dictionary from a "well-done" file

=head1 SYNOPSIS

 tt-tag-guess.perl OPTIONS [WD_FILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL	##-- print verbose comments if >1 (default=1)

 Other Options:
   -output FILE         ##-- output file (default: STDOUT)
   -encoding ENCODING   ##-- I/O encoding (default: UTF-8)

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
