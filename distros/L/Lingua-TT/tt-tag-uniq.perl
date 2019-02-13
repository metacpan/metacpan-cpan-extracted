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
our $from_field   = 1;
our $tags_only	  = 0;
our $tags_prepend = 0;
our $strict       = 0;
our $hfst_tags    = 0;

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
	   'trim|tags-only|t!' => \$tags_only,
	   'prepend|tags-prepend|p!' => \$tags_prepend,
	   'strict|s!' => \$strict,
	   'hfst-tags|hfst|ht!' => \$hfst_tags,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>1}) if ($man);
#pod2usage({-exitval=>0,-verbose=>0,-msg=>'Not enough arguments!'}) if (!@ARGV);

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
my $outfh = $ttout->{fh};

##-- ye olde loope
foreach my $infile (@ARGV) {
  my $ttin = Lingua::TT::IO->fromFile($infile,%ioargs)
    or die("$0: open failed for '$infile': $!");
  my $infh = $ttin->{fh};
  my ($prefix,$analyses,%seen,$tag);

  while (defined($_=<$infh>)) {
    if (/^%%/ || /^\s*$/) {
      print $outfh $_;
      next;
    }
    chomp;
    @f = split(/\t/,$_);
    if ($#f >= $from_field) {
      %seen  = qw();
      print $outfh join("\t",
			 @f[0..($from_field-1)],
			map {$seen{$_->[0]} ? qw() : ($seen{$_->[0]}=$_->[1])}
			grep {!$strict || $_->[0] =~ /^[A-Z\$\.\,\(]+$/}
			map {
			  if ($hfst_tags) {
			    ##-- hfst-style tags
			    $tag = /((?:\[\+[^\]]+\])+)(?:\s+\<[0-9\.eE\+\-]+\>)?$/ ? $1 : undef;
			    if (/((?:\\?\[[^\<\>\[\]\/\\]+\\?\])+)$/) {
			      $tag = join('.', (($tag=$1) =~ /\[\+?([^\<\>\[\]\/\\]+)\\?\]/g));
			    } elsif (/((?:\\?\[\<?[^\<\>\[\]\/\\]+\>?\\?\]))$/) {
			      ($tag = $1) =~ s/[\\\<\>\[\]\+]//g;
			    } else {
			      $tag = $_;
			    }
			  } else {
			    ##-- tagh-style tags
			    $tag = /\[_?([^<>\]\s]+)[\]\s]/ ? $1 : $_;
			  }
			  [$tag, ($tags_only ? "[$tag]" : ($tags_prepend ? "[$tag] $_" : $_))]
			}
			@f[$from_field..$#f]
		       ), "\n";
    } else {
      print $outfh $_, "\n";
    }
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

tt-tag-uniq.perl - reduce TT analyses to unique tags

=head1 SYNOPSIS

 tt-tag-uniq.perl [OPTIONS] [TT_FILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -output FILE         ##-- output file (default: STDOUT)
   -encoding ENCODING   ##-- I/O encoding (default: UTF-8)
   -from=INDEX		##-- minimum index for reducible fields (default=1)
   -[no]trim            ##-- do/don't dump only tags as "[TAG]" (default: -notrim)
   -[no]prepend         ##-- do/don't prepend tags as "[TAG] " (default: -noprepend; only if -notrim)
   -[no]strict          ##-- do/don't apply strict tag heuristics (default=don't)
   -[no]hfst-tags       ##-- do/don't use HFST-style tag extraction (default=don't)

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
