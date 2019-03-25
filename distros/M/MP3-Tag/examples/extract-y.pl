#!/usr/bin/perl -w
use strict;

my $opus = qr/Op|WoO/i;
my $rx_date = qr/[^()]*\b\d{4}\b[^()]*/;
my $rx_op = qr/\b(?:$opus)\b\.?\s*\d+[a-d]?(?:-\d[.\d]*)?(?:(?:[.,:;]\s*)No\.?\s*\d[.\d]*)?/i;
my $rx_isodate = qr/\b\d{4}(?:-\d{1,2}\b){0,2}/;
my $rx_isorange = qr,$rx_isodate(?:(?:[-/]|--)$rx_isodate)?,;

sub short_opus ($) {
  my $op = shift;
  my ($opt, $opn, $n) =
    ($op =~ /\b((?:$opus)\b\.?)\s*(\d+[a-d]?(?:-\d[.\d]*)?)(?:(?:[.,:;]\s*)No\.?\s*(\d[.\d]*))?/io);
  $opt =~ s/^Op\b\.?\s*/Op. /i;	# add dot if needed
  $opt =~ s/(?<=\S)$/ /;	# add space if needed
  my $short = $op = "$opt$opn";
  if (defined $n and length $n) {
    $op .= "-$n";
  }
  ($short, $op, $n)
}

sub process_opus_year ($$$$) {
  my ($op, $y, $seen, $no) = @_;
  my ($short, $long, $n) = short_opus $op;
  push @{$$no{$short}}, $n if defined $n and length $n;
  push @{$$seen{$long}}, $y;
}

sub extract_years_all ($) {	# Format as in:
  # Piano Trio No. 1 in E flat major; Op. 1, No. 1 (1795)
  my $fh = shift;
  my (%seen, %no);
  while (<$fh>) {		# Some Op numbers are repeated (Beeth Op. 72)
    warn($_), next unless /[.,;:]\s*($rx_op)(?:\s*\(($rx_date)\))?\s*$/o;
    my ($op, $y) = ($1, $2);
    next unless $y;
    process_opus_year $op, $y, \%seen, \%no;
  }
  (\%seen, \%no)
}

sub extract_years_all_slashes ($$) {	# Format as in
  # ### CHAMBER MUSIC //
  # Op. 1 // 1792--1794 // Pf. trios: Op.1, Nos. 1-3, in Eb, G major, and C minor
  # open my $codm, '<', 'Beethoven.codm' or die;
  my ($no_name, $fh) = (shift, shift);
  my (%seen, %no);
  #my $unknown = 0;
  while (<$fh>) {
    next if /###/;
    #s,^(?= // ), "?" . ++$unknown ,e;
    chomp;
    my ($op, $d, $n) = split m( // ), $_, 3;
    $n or $no_name or die "unexpected: <$_>";
    process_opus_year $op, $d, \%seen, \%no;
  }
  # close $codm or die;
  (\%seen, \%no)
}

sub find_no ($) {
  my $seen = shift;
  my %no;
  for my $op (keys %$seen) {
    push @{$no{$1}}, $2 if $op =~ /^(.*)-(\d+[.\d]*)$/s;
  }
  \%no;
}

sub remove_deducible ($$) {	# Will act only if one date is present
  my ($seen, $no) = (shift, shift);
  for my $op (keys %$no) {
    next unless exists $$seen{$op};
    my $y = $$seen{$op};
    next unless @$y == 1;
    $y = $y->[0];
    my @dups;
    for my $n (@{$$no{$op}}) {
      my $y1 = $$seen{"$op-$n"};
      next unless @$y1 == 1;
      $y1 = $y1->[0];
      push @dups, $n if $y eq $y1;
    }
    delete $$seen{"$op-$_"} for @dups;
  }
}

sub norm_nums {(my $s = shift) =~ s/(\d+)/sprintf '%05d', $1/e; $s }
sub by_with_nums { norm_nums($a) cmp norm_nums($b)}
sub sort_with_nums {sort by_with_nums @_}

sub extract_years ($$) {
  my ($how, $fh) = (shift, shift);
  my ($seen, $no);
  if ($how eq 'wiki') {
    ($seen, $no) = extract_years_all \*ARGV;
  } elsif ($how eq 'merge') {
    ($seen, $no) = extract_years_all_slashes 'no_name', \*ARGV;
  } else {
    ($seen, $no) = extract_years_all_slashes 0, \*ARGV;
  }
  remove_deducible $seen, $no;
  $seen
}

sub years_of_range ($) {
  my $r = shift;
  if ($r =~ /^$rx_isodate$/) {
    $r =~ /(\d{4})/ or die "<$r>";
    return $1;
  }
  my @y = ($r =~ /(\d{4})/g);
  @y == 2 or die "<$r>";
  $y[0] .. $y[1]
}

sub cmp_sets ($$) {		# undef on unclear; returns -1 if $a <<< $b
  my ($a, $b) = (shift, shift);
  my (%a, %b, %only_a, %only_b);
  @a{@$a} = (1) x @$a;
  @b{@$b} = (1) x @$b;
  %only_a = %a, %only_b = %b;
  delete $only_a{$_} for keys %b;
  delete $only_b{$_} for keys %a;
  return undef if %only_a and %only_b;
  return 0 unless %only_a or %only_b;
  return (%only_a ? 1 : -1);
}

sub cmp_dates ($$) { # cmp dates' "informativeness"; undef on unclear
  my ($a, $b) = (shift, shift);	# Should be strings; returns -1 if $a <<< $b
  unless (defined $a) {
    return undef unless defined $b;
    return -1;
  }
  return 1 unless defined $b;
  # Both defined now
  return 0 if $a eq $b;
  my ($a_words, $b_words) = (0,0);
  $a_words = 1 if $a =~ /[^-\d\s]/; # Check non-ranges
  $b_words = 1 if $b =~ /[^-\d\s]/;
  return undef if $a_words and $b_words;
  # Now at most one of them has non-ranges
  my $diff_w = $a_words <=> $b_words;
  my @aranges = ($a =~ /$rx_isorange/g);
  my @branges = ($b =~ /$rx_isorange/g);
  my @ayears = map years_of_range($_), @aranges;
  my @byears = map years_of_range($_), @branges;
  my $diff_r = cmp_sets \@ayears, \@byears;
  return undef unless defined $diff_r;
  return undef if $diff_r and $diff_w and $diff_r ne $diff_w;
  # Now the differences are in the same direction, if any
  my $diff_rw = $diff_w;
  @ayears = ($a =~ /$rx_isodate/g);
  @byears = ($b =~ /$rx_isodate/g);
  my $diff_y = cmp_sets \@ayears, \@byears;
  return undef unless defined $diff_y;
  return undef if $diff_rw and $diff_y and $diff_rw ne $diff_y;
  # Now all the differences are in the same direction, if any
  $diff_rw or $diff_y;
}

sub fix_year ($$) {		# Format as in:
  # Piano Trio No. 1 in E flat major; Op. 1, No. 1 (1795)
  my ($fh, $ys) = (shift, shift);
  my (%seen, %no);
  while (<$fh>) {		# Some Op numbers are repeated (Beeth Op. 72)
    warn($_), next unless /[.,;:]\s*($rx_op)(?:\s*\(($rx_date)\))?\s*$/o;
    my ($op, $y) = ($1, $2);
    my ($short, $long, undef) = short_opus $op;
    my $yy = $ys->{$long} || $ys->{$short};
    if ($yy) {
      s/([.,;:]\s*($rx_op))(?:\s*\(($rx_date)\))?\s*$/$1 ($yy)\n/o
	or warn "<$_>";
    }
    print
  }
}


die "usage:\n\t$0: (wiki|codm|merge ids|fix datefile) file(s)\n"
  unless @ARGV and $ARGV[0] =~ /^(wiki|codm|merge|fix)$/i;

my $how = shift;
my $seen;
if ($how eq 'fix') {
  my $fn = shift;
  open my $f, '<', $fn or die "error opening $fn for read";
  my %ys;
  while (<$f>) {
    next if /^##/;
    my @fields = split m( // ), $_, 4;
    @fields == 4 or warn "<$_>";
    $ys{$fields[0]} = $fields[2];
  }
  close $f or die "error closing $fn for read";
  fix_year \*ARGV, \%ys;
  exit 0;
} elsif ($how eq 'merge') {
  my (@seen, %seen_a, %seen);
  my @ids = split m(/), shift;
  my @f = @ARGV;
  my $c = 0;
  for my $f (@f) {
    @ARGV = $f;
    my $sub_seen = extract_years $how, \*ARGV;
    @{$sub_seen->{$_}} == 1 or die "$_: <@{$sub_seen->{$_}}>"
      for keys %$sub_seen;
    $sub_seen->{$_} = $sub_seen->{$_}[0] for keys %$sub_seen;
    push @seen, $sub_seen;
    $seen_a{$_}[$c] = $sub_seen->{$_} for keys %$sub_seen; # Transposed
    $#{$seen_a{$_}} = $#f for keys %$sub_seen;	# put enough undef's
    $c++;
  }
  $seen{$_} = [join ' // ', map $_ || '', @{$seen_a{$_}}]
    for keys %seen_a;
  # Assumes values of $seen are arrays of date strings
  remove_deducible \%seen, find_no \%seen;
  delete $seen_a{$_} for grep !exists $seen{$_}, keys %seen_a;
  for my $op (keys %seen_a) {
    my $ys = $seen_a{$op};
    my @best;
    for my $ff (0..$#$ys) {
      next unless defined $ys->[$ff];
      my $bad;
      for my $fff (0..$#$ys) {
	next if $fff == $ff or not defined $ys->[$fff];
	my $res = cmp_dates $ys->[$ff], $ys->[$fff];
	$bad++, last if not defined $res or $res < 0;
	$bad++, last if not $res and $fff < $ff; # Reject a later one of the same
      }
      push @best, $ff unless $bad;
    }
    warn "panic: $op: <@$ys>" if @best > 1;
    my ($id, $y) = '';
    unless (@best) {
      push @best, 0;
      $best[0]++ until defined $ys->[$best[0]];
      $id = 'guess-';
    }
    $y = $ys->[$best[0]];
    $id .= $ids[$best[0]];
    $seen->{$op} = [join ' // ', $id, $y, map $_ || '', @$ys];
    #push @$ys, $seen->{$op} = [(@best ? $ys->[$best[0]] : '')];
  }
  my $ids = join ' // ', @ids;
  print <<EOP;
### format: Opus number // source // guessed value // $ids
EOP
} else {
  $seen = extract_years $how, \*ARGV;
}

for my $n (sort_with_nums keys %$seen) {
  my (%s, @y);
  my $y = join ' / ', grep !$s{$_}++, @{$$seen{$n}};
  $n ||= '?';
  print "$n // $y\n"
}
