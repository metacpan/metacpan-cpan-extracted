package testload;

use strict;
use Test::More;
use File::Spec;

use vars qw( @ISA @EXPORT $Dat_Dir
             @LINEAGE_DATA @HEADERS @SKEW_DATA
             @GNARLY_DATA @TRANSLATION_DATA
           );

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( $Dat_Dir @LINEAGE_DATA @HEADERS @SKEW_DATA
i             @TRANSLATION_DATA @GNARLY_DATA
              good_data good_slice_data good_skew_data
              good_gnarly_data good_sticky_data
            );

my $base_dir;
BEGIN {
  my $pkg = __PACKAGE__;
  $pkg =~ s%::%/%g;
  $pkg .= '.pm';
  my @parts = File::Spec->splitpath(File::Spec->canonpath($INC{$pkg}));
  $parts[-1] = '';
  $base_dir = File::Spec->catpath(@parts);
}
$Dat_Dir = $base_dir;

# For dataset 'chain'
@LINEAGE_DATA = (
  [ '0,0,1,0', '1,0,1,0', '2,0,1,0', '3,0' ],
  [ '0,0,1,0', '1,0,1,0', '2,0,2,1', '3,1' ],
  [ '0,0,1,0', '1,0,1,0', '2,0' ],
  [ '0,0,1,0', '1,0,2,1', '2,1,1,1', '3,2' ],
  [ '0,0,1,0', '1,0,2,1', '2,1,2,0', '3,3' ],
  [ '0,0,1,0', '1,0,2,1', '2,1' ],
  [ '0,0,1,0', '1,0' ],
  [ '0,0,2,1', '1,1,1,1', '2,2,1,0', '3,4' ],
  [ '0,0,2,1', '1,1,1,1', '2,2,2,1', '3,5' ],
  [ '0,0,2,1', '1,1,1,1', '2,2' ],
  [ '0,0,2,1', '1,1,2,0', '2,3,1,1', '3,6' ],
  [ '0,0,2,1', '1,1,2,0', '2,3,2,0', '3,7' ],
  [ '0,0,2,1', '1,1,2,0', '2,3' ],
  [ '0,0,2,1', '1,1' ],
  [ '0,0' ]
);

# For data set 'basic'
@HEADERS = (
  'Header Zero',
  'Header One',
  'Header Two',
  'Header Three',
  'Header Four',
  'Header Five',
  'Header Six',
  'Header Seven',
  'Header Eight',
  'Header Nine',
);

# For data set 'skew'
@SKEW_DATA = (
  [ 'head0','head1','head2','head3' ],
  [ 'THIS IS A WHOLE ROW-CELL OF JUNK','','','' ],
  [ 'JUNK','Tasty tidbit (1,1)','JUNK','Tasty tidbit (1,3)' ],
  [ '',"BIG\nJUNK",'','Tasty tidbit (2,3)' ],
  [ 'Tasty tidbit (3,0)','','','Tasty tidbit (3,3)' ],
  [ 'Tasty tidbit (4,0)','','','Tasty tidbit (4,3)' ],
  [ 'JUNK BUTTON','','Tasty tidbit (5,2)','Tasty tidbit (5,3)' ],
);

@TRANSLATION_DATA = (
  [ '0,0', '0,1', '0,2', '0,3' ],
  [ '1,0', '1,0', '1,0', '1,0' ],
  [ '2,0', '2,1', '2,2', '2,3' ],
  [ '2,0', '3,1', '3,1', '3,3' ],
  [ '4,0', '3,1', '3,1', '4,3' ],
  [ '5,0', '3,1', '3,1', '5,3' ],
  [ '6,0', '6,0', '6,2', '6,3' ]
);

@GNARLY_DATA = (
  [ '(0,0) [1,4]',            '',            '',            '', '(0,1) [2,4]',            '',            '',            '' ],
  [ '(1,0) [2,1]', '(1,1) [1,1]', '(1,2) [1,2]',            '',            '',            '',            '',            '' ],
  [            '', '(2,0) [2,4]',            '',            '',            '', '(2,1) [2,2]',            '', '(2,2) [1,1]' ],
  [ '(3,0) [1,1]',            '',            '',            '',            '',            '',            '', '(3,1) [1,1]' ],
  [ '(4,0) [3,2]',            '', '(4,1) [1,1]', '(4,2) [3,1]', '(4,3) [4,4]',            '',            '',            '' ],
  [            '',            '', '(5,0) [1,1]',            '',            '',            '',            '',            '' ],
  [            '',            '', '(6,0) [1,1]',            '',            '',            '',            '',            '' ],
  [ '(7,0) [1,4]',            '',            '',            '',            '',            '',            '',            '' ]
);

sub good_data {
  my($ts, $label, @slice) = @_;
  ref $ts or die "Oops: Table state ref required\n";
  my $t = $ts->{grid};
  my $skew;
  my $txt = ref $t->[0][0] eq 'SCALAR' ?
    ${$t->[0][0]} : $t->[0][0]->as_text;
  $skew = $txt =~ /^Header/ ? 1 : 0;
  my $row = 0 + $skew;

  if (@slice) {
    my @rows = $ts->rows;
    cmp_ok(scalar @slice, '==', scalar @{$rows[0]}, "$label (col cnt)");
  }

  # Must have rows
  ok(scalar @{$t}, "$label (rows)");

  # See if we got the numbers.
  foreach my $r ($row .. $#$t) {
    # Must have columns
    ok(scalar @{$t->[$r]}, "$label (columns)");
    my @indices = @slice ? @slice : 0 .. $#{$t->[$r]};
    foreach my $c (@indices) {
      my $rc = $skew ? $r : $r + 1;
      next if $ts->{headers} && !$ts->{hits}{$c};
      my $txt = ref $t->[$r][$c] eq 'SCALAR' ?
        ${$t->[$r][$c]} : $t->[$r][$c]->as_text;
      like($txt, qr/^ \($rc,$c\)/, "$label ($r,$c)");
    }
  }

  # Header order check
  if ($skew) {
    foreach my $c (0 .. $#{$t->[0]}) {
      my $hs = $HEADERS[$c];
      my $txt = ref $t->[0][$c] eq 'SCALAR' ?
        ${$t->[0][$c]} : $t->[0][$c]->as_text;
      like($txt, qr/^$hs$/, "$label (header order)");
    }
  }
  1;
}

sub good_slice_data {
  my($ts, $label, @slice) = @_;
  my $t = $ts->{grid};
  my @rows = $ts->rows;
  my $txt = ref $t->[0][0] eq 'SCALAR' ?
    ${$t->[0][0]} : $t->[0][0]->as_text;
  my $skew = 1;
  foreach my $r (0 .. $#rows) {
    my $row = $rows[$r];
    my $trow = $t->[$r+$skew];
    ok(@$row == @slice, "$label (slice width)");
    my @s = $ts->column_map;
    foreach my $c (0 .. $#$row) {
      my $sc = $s[$c];
      my $cell = $trow->[$sc];
      my $txt = ref $cell eq 'SCALAR' ?
        $$cell : $cell->as_text;
      ok($row->[$c] eq $txt, "$label ($r,$c)");
    }
  }
}

sub good_skew_data   {
  push(@_, 0) if @_ == 2;
  _good_span_data(@_, \@SKEW_DATA);
}

sub good_gnarly_data {
  push(@_, 0) if @_ == 2;
  _good_span_data(@_, \@GNARLY_DATA);
}

sub _good_span_data {
  my($ts, $label, $reverse, $REF_DATA) = @_;
  ref $ts or die "Oops: Table state ref required\n";
  my $t = $ts->{grid};
  foreach my $r (1 .. $#$t) {
    my $row = $t->[$r];
    my @cols = 0 .. $#$row;
    @cols = reverse @cols if $reverse;
    foreach my $c (@cols) {
      my $txt = ref $row->[$c] eq 'SCALAR' ?  ${$row->[$c]} : $row->[$c]->as_text;
      $txt = '' unless defined $txt;
      cmp_ok($txt, 'eq', $REF_DATA->[$r][$c], $label);
    }
  }
  1;
}

sub good_sticky_data {
  # testing grid aliasing
  my($ts, $label, $reverse) = @_;
  ref $ts or die "Oops: Table state ref required\n";
  my $t = $ts->_gridalias;
  foreach my $r (0 .. $#$t) {
    my $row = $t->[$r];
    my @cols = 0 .. $#$row;
    @cols = reverse @cols if $reverse;
    foreach my $c (@cols) {
      my $txt = ref $row->[$c] eq 'SCALAR' ?
        ${$row->[$c]} : $row->[$c]->as_text;
      my($tr,$tc) = $ts->source_coords($r,$c);
      cmp_ok("$tr,$tc", 'eq', $TRANSLATION_DATA[$r][$c], "$label (coords)");
      my $trow = $t->[$tr];
      my $ttxt = ref $trow->[$tc] eq 'SCALAR' ?
        ${$trow->[$tc]} : $trow->[$tc]->as_text;
      cmp_ok($ttxt, 'eq', $txt, "$label (content)");
      cmp_ok($ttxt, 'eq', $SKEW_DATA[$tr][$tc], "$label (abs)");
    }
  }
  1;
}

1;
