#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::TextAlignment ':escape';
use Encode qw(encode decode);

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

use strict;

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.12";

##-- program vars
our $progname     = basename($0);
our $verbose      = 1;

our $outfile      = '-';
our %ioargs       = (encoding=>'UTF-8');
our $txtfile      = undef;

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
my ($help,$version);
GetOptions(##-- general
	   'help|h' => \$help,
	   #'man|m'  => \$man,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$ioargs{encoding},
	   'use-offsets-in|offsets-in|offsets|off|O|text-file|text|txt|t=s' => \$txtfile,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>1}) if ($man);
#pod2usage({-exitval=>0,-verbose=>1,-msg=>'Not enough arguments specified!'}) if (@ARGV < 2);

if ($version || $verbose >= 2) {
  print STDERR "$progname version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##----------------------------------------------------------------------
## Subs

##--------------------------------------------------------------
sub tt_ensure_stxt_txtbuf {
  my ($ttin,$ttout,$txtbuf) = @_;
  my ($s,$stxt_cmt,@sw, $off0,$len0, $off1,$len1, $stxt);
  my $enc = $ioargs{encoding};

  while (defined($s=$ttin->getSentence)) {

    ##-- get actual word-like tokens
    next if ( !(@sw = grep {@$_ > 1 && $_->[0] !~ /^%%/} @$s) );

    ##-- get actual text comment (trim if exists)
    $stxt_cmt = undef;
    foreach (@$s) {
      if ((@$_ && $_->[0] =~ s/^(%%\s*\$stxt=).*/$1/)
	  || ($_->[0] =~ /^%% Sentence /
	      #&& (@$_ == 1 ? ($_->[1] = '= ') : (@$_ > 1 && $_->[1] =~ s/^=.*/= /))
	      && @$_ > 1 && $_->[1] =~ s/^=.*/= /)
	 ) {
	$stxt_cmt = $_;
	last;
      }
    }
    if (!defined($stxt_cmt)) {
      ##-- no sentence-text comment found: splice a new one in after leading comments
      foreach (0..$#$s) {
	if ($s->[$_][0] !~ /^%%/) {
	  splice(@$s,$_,0, $stxt_cmt=['%% $stxt=']);
	  last;
	}
      }
    }

    ##-- get offsets
    ($off0,$len0) = split(' ', $sw[0][1]);
    ($off1,$len1) = split(' ', $sw[$#sw][1]);

    ##-- (re-)populate sentence-text comment
    $stxt = bytes::substr($txtbuf, $off0, ($off1+$len1)-$off0);
    $stxt = decode($enc, $stxt) if ($enc);
    $stxt_cmt->[$#$stxt_cmt] .= escape_rtt( $stxt );
  }
  continue {
    $ttout->putSentence($s);
  }
}


##--------------------------------------------------------------
sub tt_ensure_stxt_guess {
  my ($ttin,$ttout) = @_;
  my ($s,$stxt);

  ##-- use comments or guess
 SENT_GUESS:
  while (defined($s=$ttin->getSentence)) {
    next if (!@$s || grep {@$_ && ($_->[0] =~ /^%%\s*\$stxt=/ || ($_->[0] =~ /^%% Sentence \S+/ && @$_ > 1 && $_->[1] =~ /^=\s?\S/))} @$s);
    $stxt = ["%% \$stxt=".$s->guessRawString()];
    foreach (0..$#$s) {
      if ($s->[$_][0] !~ /^%%/) {
	splice(@$s,$_,0,$stxt);
	next SENT_GUESS;
      }
    }
  } continue {
    $ttout->putSentence($s);
  }
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
push(@ARGV,'-') if (!@ARGV);
our $ttout = Lingua::TT::IO->toFile($outfile,%ioargs)
    or die("$0: open failed for '$outfile': $!");

##-- get text buffer
my ($txtbuf);
if ($txtfile) {
  open(my $txtfh, "<:raw", $txtfile) or die("$0: open failed for '$txtfile': $!");
  local $/ = undef;
  $txtbuf = <$txtfh>;
  close $txtfh;
}

##-- ye olde loope
foreach my $infile (@ARGV) {
  my $ttin = Lingua::TT::IO->fromFile($infile,%ioargs)
    or die("$0: open failed for '$infile': $!");

  if (defined($txtbuf)) {
    tt_ensure_stxt_txtbuf($ttin,$ttout,$txtbuf);
  } else {
    tt_ensure_stxt_guess($ttin,$ttout);
  }

  $ttin->close();
}
$ttout->close();

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-ensure-stxt.perl - ensure that 'stxt' comment appears in tt file

=head1 SYNOPSIS

 tt-ensure-stxt.perl OPTIONS [TT_FILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -txtfile TXTFILE	##-- get raw text via offsets from TXTFILE (default: none)
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
