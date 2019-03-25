#!/usr/bin/perl -w
use strict;

@ARGV == 2 or @ARGV == 1 or die "Usage: $0 Composer_Name [Oxford_CDict_URL]\n";
$ARGV[0] eq 'Beethoven' or die "Only Beethoven supported now...\n";
my $comp = shift;

my $url_get_txt = 'lynx -display_charset=ISO-8859-1 -width=400 -number_links- -nolist -dump';

sub get_url_txt ($) {
  my ($url, $f) = shift;
  local %ENV = %ENV;
  delete $ENV{LYNX_CFG};
  delete $ENV{LYNX_LSS};
  local $ENV{HOME} = '/';
  open $f, "$url_get_txt $url |" or die "open lynx pipe for read: $|";
  $f
}

my $f = get_url_txt 'http://en.wikipedia.org/wiki/List_of_works_by_Beethoven';
#open my $f, '/dev/null';
# XXXX Actually, we "want" writing years, not publication year; need to
#      pull it from some other place
my ($work, $op, $no, $opyears, %opus, %opnums, %op_publ_year);
while (<$f>) {
  $work++ if /^\s*Works having assigned Opus/;
  next unless $work;
  s/\.?\s*$//;
  if (s/^\s*\*\s*(\w+\s.*?):\s*//) {
    $op = $1;
    $op =~ s/\bOpus\b/Op./;
    $no = 0;
    $op_publ_year{$op} = ( s/\s*\(([-\d]+)\)\s*$// ? $1 : '' );
    my $opy = $op_publ_year{$op};
    $opy = " ($opy)" if length $opy;
    $opus{$op} = "$_; $op$opy\n";
  } elsif (s/^\s*\+\s*//) {
    $no++;
    $opus{$op} =~ s/^#*\s*/### /;
    my $opy = $op_publ_year{$op};
    $opy = " ($opy)" if length $opy;
    push @{$opnums{$op}}, "$_; $op, No. $no$opy\n";
  }
}
close $f or die "error closing lynx pipe: $!";

# Get years
my $oxford_url = shift
  || 'http://www.classicalarchives.com/bios/codm/beethoven.html';
$f = get_url_txt $oxford_url;
$work = 0;
my %bywork;

while (<$f>) {
  $work = $1, $bywork{$work} ||= '' if s/^\s*(OPERA|SYMPHONIES|CONCERTOS|ORCHESTRAL|PIANO SONATAS|OTHER PIANO WORKS|CHAMBER MUSIC|CHORAL|SOLO VOICE)\s*(\([^()]+\)\s*)?:\s*//i;
  next unless $work;
  last if /\[Home\]/i;
  $bywork{$work} .= $_;
}
1 while <$f>;
close $f or die "error closing lynx pipe: $!";

my $months_short = q(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec);
my $months_long = q(January|February|March|April|May|June|July|August|September|October|November|December);
my $months_s_rex = qr($months_short)i;
my $months_l_rex = qr($months_long)i;
my $months_days_rex = qr(\b(?:\d{1,2}\s+)?(?:$months_s_rex\b\.?|$months_l_rex\b))i;

my $years_rx1 = qr/(?:$months_days_rex\s+)?\d\d\d\d(?:-\d{1,4})?/;
my $years_rx2 = qr/$years_rx1(?:(?:,|\sand)\s$years_rx1)*/;
# Abbrev: 2consonants, or ob.
my $year_spec_rx = qr/pubd?\.|rev\.|comp\.|arr\.\s(?:by|for|of)(?:\s\w+|\sob\.|\s[b-df-hj-np-tv-z]{1,2}\.)*/;
my $years_rx = qr/(?:$year_spec_rx\s)?$years_rx2(?:,\s(?:$year_spec_rx\s)?$years_rx2)*/;
my $years_fp_rx = qr/$years_rx(?:(?:[,;]|\sand)\s(?:$years_rx|f\.\s*(?:pub\.\s*)?p\.\s[^;]*(?=;|$)))*/;

my $o = 1;
my %iso_month;
$iso_month{lc $_} = $o++ for split /\|/, $months_short;

sub date_to_ISO {		# "Our version" of ISO; use -- instead of /
  my $d = shift;		# Suppose it is matched by $years_rx1
  $d =~ /(?:(?:(\d+)\s+)?($months_short)\w*\.?\s+)?(\d{4})(?:-(\d{1,4}))?/i
    or die "Unrecognized format of date: `$d'";
  my $y = $3;
  $y .= sprintf '-%02d', $iso_month{lc $2} if $2;
  $y .= sprintf '-%02d', $1 if defined $1;
  $y .= ('--' . substr($3, 0, 4 - length $4) . $4) if $4;
  $y
}

open ERR, "> $comp.err" or die "open $comp.err for write: $!";

my %per_opnum;
for my $w (keys %bywork) {
  my $txt = $bywork{$w};
  $txt =~ s/\.?\s*$//;
  $txt =~ s/\s+/ /g;
  my $dot = 1;
  # 1st try: break into sentences ending in date (see Beethoven's Symphonies)
  my @parts = split /(?:(?<=\b\d\d\d\d)|(?<=\b\d\d\d\d-\d)|(?<=\b\d\d\d\d-\d\d)|(?<=\b\d\d\d\d-\d\d\d)|(?<=\b\d\d\d\d-\d\d\d\d))\.\s+/, $txt;
  my $match = qr/^(\?|c\.\s*)?$years_fp_rx$/;
  unless (@parts > 1) {
    # 2nd try: as above, but allow parens before dot; then break via semicolons
    # preceeded by date (see Beethoven's non Symphonies)
    my @p = split /(?<=(?:(?<=\b\d\d\d\d)|(?<=\b\d\d\d\d-\d)|(?<=\b\d\d\d\d-\d\d)|(?<=\b\d\d\d\d-\d\d\d)|(?<=\b\d\d\d\d-\d\d\d\d))\))\.\s+/, $txt;
    @parts = ();
    push @parts, split /(?<=[)\d]);\s+/ for @p;
    $dot = 0;
    $match = qr/^(\?|c\.\s*)?$years_rx$/;
  }
  my($pref, $npref) = '';	# Look for subheader
  # Is beneficial only as in "Op.47, in A major (Kreutzer)", except:
  # Pf. trios: Variations on `Ich bin der Schneider Kakadu', Op.121a (Kakadu)
  # Overtures: Die Weihe des Hauses (Consecration of the House), Op.124
  # Vc. sonatas: Op.102, Nos. 1-2, in C major and D major
  for my $p (@parts) {
    # Is beneficial only as in "Op.47, in A major (Kreutzer)", except:
    # Pf. trios: Variations on `Ich bin der Schneider Kakadu', Op.121a (Kakadu)
    # Overtures: Die Weihe des Hauses (Consecration of the House), Op.124
    # Vc. sonatas: Op.102, Nos. 1-2, in C major and D major
    # String trios (notes):, Vc. Sonatas:, Miscelaneous, str. qts:
    if ($p =~ /^((?:\w+|\w\w\w?\.)(?:\s\w+|\sob\.|\s[b-df-hj-np-tv-z]{1,3}\.)*(?:\s\([^()]+\))?):\s+/i) {
      $npref = $1; $pref = '';
    } else {
      # $p =~ s/^/$pref/ if $pref;
    }
    my $y;
    $p =~ s/,*\s*(?=$years_fp_rx\s*$)/ (/ and $p .= ')' if $dot;
    my $txt = $p;
    $txt =~ s/\s\(([^()]+)\)\s*$// and $y = $1;
    # Explanation: == can't find year; ##  Duplicate Op; plain: !unique Op+year
    print(ERR "==### $w // $pref\n$p\n"), next unless $y and $y =~ /\b\d\d\d\d\b/;
    my @opn = ($txt =~ /\b(?:Op\.\s*|(?=WoO\b))((?:WoO\.?\s*)?\d+[a-d]?)(?:[,\s]|$)/);
    print(ERR "###$w // $pref\n$p\n"), next
      unless $y =~ /$match/ and @opn == 1 and $txt !~ /\b\d\d\d\d\b/;
    if ($per_opnum{$opn[0]}) {
      print(ERR "#####$per_opnum{$opn[0]}[3] // $per_opnum{$opn[0]}[4]\n$per_opnum{$opn[0]}[2]\n")
	if @{$per_opnum{$opn[0]}};
      $per_opnum{$opn[0]} = [];
      print(ERR "#####$w // $pref\n$p\n"), next
    }
    $y =~ s/($years_rx1)/date_to_ISO $1/ge;
    $per_opnum{$opn[0]} = [$y, $txt, $p, $w, $pref];
    ($pref, $npref) = ($npref, '') if $npref;
    #print "@opn // $y // $txt\n";
  }
}
close ERR or die "close $comp.err for write: $!";

sub alignnums ($) {
  my $s = shift;
  $s =~ s/(\d+)/ sprintf '%029d', $1/ge;
  $s
}

open COMP, "> $comp.wiki" or die "open $comp.wiki for write: $!";
for (sort {alignnums($a) cmp alignnums $b} keys %opus) {
  print COMP $opus{$_};
  print COMP for @{$opnums{$_}};
}
close COMP or die "close $comp.wiki for write: $!";

open COMP, "> $comp.codm" or die "open $comp.codm for write: $!";
for (sort {alignnums($a) cmp alignnums $b} keys %per_opnum) {
  next unless @{$per_opnum{$_}};
  print COMP <<EOP
### $per_opnum{$_}[3] // $per_opnum{$_}[4]
Op. $_ // $per_opnum{$_}[0] // $per_opnum{$_}[1]
EOP
}
close COMP or die "close $comp.codm for write: $!";

open DIFF, "> $comp.diffs" or die "open $comp.diffs for write: $!";
for (sort {alignnums($a) cmp alignnums $b} keys %per_opnum) {
  (my $op = $_) =~ s/^(\d+)/Op. $1/;
  next unless @{$per_opnum{$_}}
    and (defined $op_publ_year{$op}
	 and $per_opnum{$_}[0] ne $op_publ_year{$op}
	 and -1 == index $per_opnum{$_}[0], $op_publ_year{$op});
  print DIFF "##$opus{$op}";
  print DIFF "##### $_" for @{$opnums{$op}};

  print DIFF <<EOP
### $per_opnum{$_}[3] // $per_opnum{$_}[4]
Op. $_ // $op_publ_year{$op} // $per_opnum{$_}[0] // $per_opnum{$_}[1]
EOP
}
close DIFF or die "close $comp.diffs for write: $!";
