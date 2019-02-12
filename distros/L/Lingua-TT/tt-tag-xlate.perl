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

our $VERSION = "0.11";

##-- program vars
our $progname     = basename($0);
our $verbose      = 1;

our $outfile      = '-';
our %ioargs       = (encoding=>'UTF-8');
our $from_field   = 1;

our $replace	  = 0;       ##-- replace tags in-place?
our $prepend	  = '$X=';   ##-- prepend literal string to translated tags?
our $trim	  = '^\$.='; ##-- regex to trim from translated tags

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
	   'from-field|ff|from|f=i' => \$from_field,
	   'replace|repl|r|in-place|inplace|i!' => \$replace,
	   'prepend|p=s' => \$prepend,
	   'trim|t=s' => \$trim,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>1}) if ($man);
pod2usage({-exitval=>0,-verbose=>0,-msg=>'No tag-translation dictionary specified!'}) if (!@ARGV);

if ($version || $verbose >= 2) {
  print STDERR "$progname version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
push(@ARGV,'-') if (@ARGV < 2);
our $ttout = Lingua::TT::IO->toFile($outfile,%ioargs)
    or die("$0: open failed for '$outfile': $!");
my $outfh = $ttout->{fh};

##-- read dict
my $dictfile = shift(@ARGV);
my $dclass = 'Lingua::TT::Dict';
my $dict = $dclass->loadFile($dictfile,%ioargs)
  or die("$0: ${dclass}::loadFile() failed for dict file '$dictfile': $!");
my $tagx = $dict->{dict};


##-- ye olde loope
foreach my $infile (@ARGV) {
  my $ttin = Lingua::TT::IO->fromFile($infile,%ioargs)
    or die("$0: open failed for '$infile': $!");
  my $infh = $ttin->{fh};
  my (@f,@x,$xtag);

  while (defined($_=<$infh>)) {
    if (/^%%/ || /^\s*$/) {
      print $outfh $_;
      next;
    }
    chomp;
    @f = split(/\t/,$_);
    foreach (@f[${from_field}..$#f]) {
      if (/\[_?([^\s\]]+)[\s\]]/ && defined($xtag=$tagx->{$1})) {
	substr($_, $-[1], $+[1] - $-[1]) = ($replace ? $xtag : "$xtag ~$1");
	s/$trim//o if (defined($trim));
	$_ = $prepend . $_;
      }
      elsif (defined($xtag=$tagx->{$_})) {
	s/$trim//o if (defined($trim));
	$_ = $prepend . ($replace ? $xtag : "$xtag %%~$_");
      }
    }
    print $outfh join("\t",@f), "\n";
  }
  undef $infh;
  $ttin->close;
}
$ttout->close();

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-tag-xlate.perl - apply tag-translation dictionary to a TT-file

=head1 SYNOPSIS

 tt-tag-xlate.perl OPTIONS TAG_DICT [TT_FILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -output FILE         ##-- output file (default: STDOUT)
   -encoding ENCODING   ##-- I/O encoding (default: UTF-8)
   -from=INDEX		##-- minimum index for translated fields (default=1)
   -replace , -norepl   ##-- do/don't replace tags in-place (default: don't)
   -prepend=PREFIX	##-- prepend PREFIX to translated tags (default: '$X=')
   -trim=REGEX		##-- trim REGEX from translated tags (default: '^\$.=')

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
