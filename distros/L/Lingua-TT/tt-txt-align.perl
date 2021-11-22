#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::Diff;
use Lingua::TT::TextAlignment;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

##----------------------------------------------------------------------
## Globals

##-- verbosity levels
our $vl_silent = 0;
our $vl_error = 1;
our $vl_warn = 2;
our $vl_info = 3;
our $vl_trace = 4;

our $prog         = basename($0);
our $verbose      = $vl_trace;
our $VERSION	  = 0.13;

our $outfile      = '-';
our %ioargs       = (encoding=>'UTF-8', compact=>0);
our %saveargs     = (shared=>1, context=>undef, syntax=>1);
our %diffargs     = (auxEOS=>0, auxComments=>1, diffopts=>'');

our $dump_ttdiff = 0; ##-- dump/debug ttdiff?
our $raw_ttdiff  = 0; ##-- dump raw ttdiff data?

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- diff
	   'keep|K!'  => \$diffargs{keeptmp},
	   'diff-options|D' => \$diffargs{diffopts},
	   'minimal|d' => sub { $diffargs{diffopts} .= ' -d'; },

	   ##-- I/O
	   'ttdiff' => \$dump_ttdiff,
	   'raw-ttdiff' => sub {$dump_ttdiff=$raw_ttdiff=$_[1]},
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$ioargs{encoding},
	   'compact|C!' => \$ioargs{compact},
	   'prolix|P|expanded|x!'  => sub {$ioargs{compact}=!$_[1]},
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>0,-msg=>'Not enough arguments specified!'}) if (@ARGV < 2);

if ($version || $verbose >= $vl_trace) {
  print STDERR "$prog version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##-- sanity check(s) & overrides
if ($diffargs{keeptmp}) {
  $diffargs{tmpfile1} //= 'tmp_txt.t0';
  $diffargs{tmpfile2} //= 'tmp_tt.t0';
}

##----------------------------------------------------------------------
## messages
sub vmsg {
  my $level = shift;
  print STDERR @_ if ($verbose >= $level);
}
sub vmsg1 {
  my $level = shift;
  vmsg($level, "$prog: ", @_, "\n");
}

##----------------------------------------------------------------------
## Output

##----------------------------------------------------------------------
## utils: (un)-escaping
BEGIN {
  *escape_rtt = \&Lingua::TT::TextAlignment::escape_rtt;
  *unescape_rtt = \&Lingua::TT::TextAlignment::unescape_rtt;
}

##--------------------------------------------------------------
## utils: compute $char_i => $tt_i map

## \$c2t = get_c2t_vec($diff);
## \$c2t = get_c2t_vec($diff,\$c2t);
##  + get vec()-style vec s.t. ($ti == vec($c2t, $ci, 32)) iff char $::ttchars[$ci] aligns to token $::ttlines->[$ti-1]
sub get_c2t_vec {
  my ($diff,$vecr) = @_;
  do { my $vec = ''; $vecr = \$vec; } if (!$vecr);

  my ($i1,$i2) = (0,0);
  my ($fmin1,$fmax1,$fmin2,$fmax2); ##-- finite-context vars
  my ($seq1,$seq2,$hunks) = @$diff{qw(seq1 seq2 hunks)};
  my ($hunk, $op,$min1,$max1,$min2,$max2,$fix,$cmt, $addr);

  my ($j);
  my $nil  = [];
  foreach $hunk (@{$diff->{hunks}}) {
    ($op,$min1,$max1,$min2,$max2,$fix,$cmt) = @$hunk;

    ##-- full context: preceding context
    foreach $j (0..($min1-$i1-1)) {
      vec($$vecr, $i1+$j, 32) = $1 if (($seq2->[$i2+$j]//'') =~ /\t([0-9]+)$/);
    }

    ##-- non-identity hunk: ignore

    ##-- update current position counters
    ($i1,$i2) = ($max1+1,$max2+1);
  }

  ##-- trailing context
  foreach $j (0..($#$seq1-$i1)) {
    vec($$vecr, $i1+$j, 32) = $1 if (($seq2->[$i2+$j]//'') =~ /\t([0-9]+)$/);
  }

  return $vecr;
}

##--------------------------------------------------------------
## utils: compute $tt_i => ($min_ci,$max_ci) maps

## (\$minr,\$maxr) = get_w_minmax(\$c2t);
##  + see get_c2t_vec() for details on arg \$c2t
##  + get vec()-style vecs s.t.
##     $ci==vec($minr, $ti, 32) iff $ci==  min i with vec($c2t,i,32)==$ti
##     $ci==vec($maxr, $ti, 32) iff $ci==1+max i with vec($c2t,i,32)==$ti
sub get_w_minmax {
  my ($c2tr,$minr,$maxr) = @_;
  do { my $min = ''; $minr = \$min; } if (!$minr);
  do { my $max = ''; $maxr = \$max; } if (!$maxr);
  my $got = '';

  use bytes;
  my ($ti,$ci);
  foreach $ci (0..$#::txtchars) {
    $ti = vec($$c2tr,$ci,32);
    if (!vec($got,$ti,1)) {
      vec($$minr,$ti,32) = $ci;
      vec($got,$ti,1) = 1;
    }
    vec($$maxr,$ti,32) = $ci+1;
  }

  return ($minr,$maxr);
}

##--------------------------------------------------------------
## utils: compute character-index => (offset,length) maps

## \$coff = get_c_offsets(\@txtchars)
sub get_c_offsets {
  my $coff = '';
  my ($i,$off,$len) = (1,0,0);
  vec($coff,0,32) = 0;
  foreach (@{$_[0]}) {
    $off += bytes::length( unescape_rtt($_) );
    vec($coff,$i,32) = $off;
    ++$i;
  }
  return \$coff;
}


##--------------------------------------------------------------
## output: tt-diff
sub save_ttdiff {
  my ($diff,$filename) = @_;
  if (!$raw_ttdiff) {
    my $used = '';
    my ($tti);
    foreach (@{$diff->{seq2}}) {
      next if (/^\%\%/ || /^$/);
      if (/\t([0-9]+)$/ && !vec($used,$1,1)) {
	$tti = $1;
	$_ .= "\t".$::ttlines->[$tti-1];
	vec($used,$tti,1) = 1;
      }
    }
  }
  $diff->saveTextFile($outfile, %saveargs)
    or die("$prog: failed to save ttdiff dump to '$outfile': $!");
}

##--------------------------------------------------------------
##-- output: tt +text-comments
sub save_rtt {
  my ($diff,$filename) = @_;
  my $ta = Lingua::TT::TextAlignment->new();
  $ta->{lines} = $::ttlines;
  $ta->{buf}   = $::txtbuf;
  my $offr     = \$ta->{off};
  my $lenr     = \$ta->{len};

  ##-- get ci-to-ti, min-, and max-character maps
  my $c2tr = get_c2t_vec($diff);
  my ($wminr,$wmaxr) = get_w_minmax($c2tr);
  my $coffr = get_c_offsets(\@txtchars);
  my ($coff,$clen) = (0,0);
  my ($ti);

  foreach $ti (0..$#$::ttlines) {
    ##-- get token limits
    $ci_min = vec($$wminr,$ti+1,32);
    $ci_max = vec($$wmaxr,$ti+1,32);

    if ($ci_min>=$ci_max) {
      ##-- no character data for this tt-line (comment or EOS): just dump the tt-line
      $clen = 0;
    } else {
      ##-- character data present: claim it greedily
      $coff = vec($$coffr,$ci_min, 32);
      $clen = vec($$coffr,$ci_max, 32) - $coff;
    }

    ##-- update TextAlignment object
    vec($$offr, $ti, 32) = $coff;
    vec($$lenr, $ti, 32) = $clen;
    $coff += $clen;
  }


  ##-- dump TextAlignment object as RTT
  $ta->saveRttFile($outfile,%ioargs)
    or die("$prog: failed to save RTT dump to '$outfile': $!");
}


##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
our ($txtfile,$ttfile) = @ARGV;

##-- get raw text buffer
vmsg1($vl_trace, "buffering text data from $txtfile ...");
our ($txtbuf);
{
  local $/=undef;
  open(TXT,"<:encoding($ioargs{encoding})",$txtfile)
    or die("$prog: open failed for $txtfile: $!");
  $txtbuf=<TXT>;
  close(TXT);
}

##-- get raw tt data
vmsg1($vl_trace, "buffering TT data from $ttfile ...");
my $ttio  = Lingua::TT::IO->fromFile($ttfile,%ioargs)
  or die("$0: could not open Lingua::TT::IO from $ttfile: $!");
our $ttlines = $ttio->getLines();

##-- split to characters
vmsg1($vl_trace, "extracting text characters ...");
our @txtchars = map {escape_rtt($_)} split(//,$txtbuf);

vmsg1($vl_trace, "extracting token characters ...");
my ($l,$w,$w0,@c);
our @ttchars  = (
		 map {
		   $w = $ttlines->[$l=$_];
		   chomp($w);
		   ($w0 = $w) =~ s/\t.*$//;
		   if ($w =~ /^\%\%/) { @c = ($w); }
		   elsif ($w =~ /^$/) { @c = ("%%\$EOS"); }
		   else { @c = map {escape_rtt($_)."\t".($l+1)} split(//,$w0); }
		   @c
		 } (0..$#$ttlines)
		);


##-- run tt-diff comparison
vmsg1($vl_trace, "comparing ...");
our $diff = Lingua::TT::Diff->new(%diffargs);
$diff->compare(\@txtchars,\@ttchars)
  or die("$0: diff->compare() failed: $!");
@$diff{qw(file1 file2)} = ("$txtfile (text)", "$ttfile (tokens)");

##-- dump ttdiff?
if ($dump_ttdiff) {
  vmsg1($vl_trace, "dumping ".($raw_ttdiff ? 'raw ' : '')."ttdiff data to $outfile...");
  save_ttdiff($diff,$outfile);
}
else {
  ##-- convert to Lingua::TT::TextAlignment and dump RTT
  vmsg1($vl_trace, "dumping RTT data to $outfile...");
  save_rtt($diff,$outfile);
}

vmsg1($vl_trace, "done.\n");

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-txt-align.perl - align raw-text and TT-format files to RTT format

=head1 SYNOPSIS

 tt-txt-align.perl [OPTIONS] TEXT_FILE TT_FILE

 General Options:
   -help
   -version
   -verbose LEVEL

 Diff Options:
   -keep   , -nokeep    # do/don't keep temp files (default=don't)
   -minimal             # alias for -D='-d'
   -D DIFF_OPTIONS      # pass DIFF_OPTIONS to GNU diff

 I/O Options:
   -output FILE         # output file in RTT format (default: STDOUT)
   -encoding ENC        # input encoding (default: utf8) [output is always utf8]
   -compact  , -prolix  # output compact rtt (-compact) or expanded (-prolix, default)
   -ttdiff		# dump ttdiff data (for debugging)
   -raw-ttdiff		# dump ttdiff data (for low-level debugging)

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
