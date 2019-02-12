#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;

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
our %ioargs       = (encoding=>undef);
our $wantComments = 0;
#our @tagseps      = ('/', ':', ',');
our @tagseps      = ('/', '/', '/');
our $wellDone     = 1;

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
	   'comments|cmts|c!' => \$wantComments,
	   'tag-separator|tagsep|ts|t=s' => sub { $_=$_[1] foreach (@tagseps); },
	   'tag-separator1|tagsep1|ts1|t1=s' => \$tagseps[0],
	   'tag-separator2|tagsep2|ts2|t2=s' => \$tagseps[1],
	   'tag-separator3|tagsep3|ts3|t3=s' => \$tagseps[2],
	   'well-done|wd!' => \$wellDone,
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
our $ttout = Lingua::TT::IO->toFile($outfile,%ioargs)
  or die("$0: open failed for '$outfile': $!");
our $outfh = $ttout->{fh};

our ($ttin,$infh, $sbuf, @tok);

foreach $infile (@ARGV) {
  $ttin = Lingua::TT::IO->fromFile($infile,%ioargs)
    or die("$0: open failed for '$infile': $!");
  $infh = $ttin->{fh};
  @sbuf = qw();
  while (<$infh>) {
    if (/^\%\%/) {
      $outfh->print($_) if ($wantComments);
    }
    elsif (/^$/) {
      $outfh->print(join(' ', @sbuf), "\n");
      @sbuf = qw();
    }
    else {
      @tok = split(/[\t\n\r]/,$_);
      $tok = '';
      foreach (0..$#tok) {
	$tok .= $tagseps[$_ > @tagseps ? $#tagseps : ($_-1)] if ($_>0);
	$tok .= $tok[$_];
      }
      push(@sbuf, $tok);
    }
  }
  $outfh->print(join(' ', @sbuf),"\n") if (@sbuf);
  $ttin->close;
}


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-2btt.perl - convert .tt files to Brill format

=head1 SYNOPSIS

 tt-2btt.perl OPTIONS [TTFILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -output FILE         ##-- output file (default: STDOUT)
   -cmts , -nocmts      ##-- do/don't include comments (default: don't)
   -tagsep  SEP123      ##-- global tag separator character (default='/')
   -tagsep1 SEP1        ##-- text/tag separator (default='/')
   -tagsep2 SEP2        ##-- tag/analyses separator (default='/')
   -tagsep3 SEP3        ##-- analysis separator (default='/')

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
