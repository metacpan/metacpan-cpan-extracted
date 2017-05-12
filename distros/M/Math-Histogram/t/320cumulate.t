use strict;
use warnings;
use Math::Histogram qw(make_histogram);
use Test::More;
use File::Spec;
use Data::Dumper;

BEGIN { push @INC, -d "t" ? File::Spec->catdir(qw(t lib)) : "lib"; }
use Math::Histogram::Test;

my @axis_specs3 = ([3, 0., 1.], [3, 0., 1.], [3, 0., 1.]);
my @axis_specs2 = ([3, 0., 1.], [3, 0., 1.]);
my @axis_specs1 = ([3, 0., 1.]);

my $d3 = [
  [ [ 1 .. 3 ], [ 4 .. 6 ], [ 7 .. 9  ] ],
  [ [ 2 .. 4 ], [ 5 .. 7 ], [ 8 .. 10 ] ],
  [ [ 3 .. 5 ], [ 6 .. 8 ], [ 9 .. 11 ] ],
];

my $d2 = [
  [ 1, 2, 3 ],
  [ 4, 5, 6 ],
  [ 7, 8, 9 ],
];
my $d2_out = [
  [ 1, 3, 6 ],
  [ 5, 12, 21 ],
  [ 12, 27, 45 ],
];

my $d1 = [ 1 .. 3 ];

pass();

SCOPE: {
  my $h = make_histogram(@axis_specs1);
  fill_hist_from_arrays($h, $d1);

  my $clone = $h->clone;
  $h->cumulate($_) for 0..$h->ndim-1;
  # Nuke overflow...
  $h->set_bin_content([$h->get_axis(0)->nbins+1], 0);

  my $expected_out = dim(3);
  cumulate( $d1, $expected_out, [2] );
  my $h1 = make_histogram(@axis_specs1);
  fill_hist_from_arrays($h1, $expected_out);
  ok($h->data_equal_to($h1), "1d cumulated data equal");
  my $ary = arrays_from_hist($h);
} # end SCOPE

SCOPE: {
  my $h = make_histogram(@axis_specs2);
  fill_hist_from_arrays($h, $d2);

  my $clone = $h->clone;
  $h->cumulate($_) for 0..$h->ndim-1;
  # Nuke overflow...
  $h->set_bin_content([$_, $h->get_axis(1)->nbins+1], 0) for 0..$h->get_axis(0)->nbins+1;
  $h->set_bin_content([$h->get_axis(0)->nbins+1, $_], 0) for 0..$h->get_axis(1)->nbins+1;
  #$h->_debug_dump_data;
  #print "\n";

  #my $expected_out = dim(3,3);
  #cumulate( $d2, $expected_out, [2,2] );
  my $h2 = make_histogram(@axis_specs2);
  fill_hist_from_arrays($h2, $d2_out);
  ok($h->data_equal_to($h2));
  #my $ary = arrays_from_hist($h);
  #use Data::Dumper;
  #warn Dumper $ary;
  #warn Dumper $expected_out;
  #table($ary);
  
} # end SCOPE

done_testing();

sub fill_hist_from_arrays {
  my $h = shift;
  my $data = shift;

  my $nbins = [map $h->get_axis($_)->nbins, 0..$h->ndim-1];
  my $bin_vec = [(0) x $h->ndim];

  my $c = [(1) x $h->ndim];

  # inefficient as hell, but fine for now.
  OUTER: while (1) {
    #print "@$c\n";
    my $elem = $data;
    $elem = $elem->[$_-1] foreach @$c;
    $h->fill_bin_w($c, $elem);
    foreach my $dim (0..$h->ndim-1) {
      $c->[$dim]++;
      if ($c->[$dim] > $nbins->[$dim]) {
        last OUTER if $dim == $h->ndim-1;
        $c->[$dim] = 1;
      }
      else { last }
    }
  }
}

sub arrays_from_hist {
  my $h = shift;

  my $nbins = [map $h->get_axis(0)->nbins, 0..$h->ndim-1];

  my $c = [(1) x $h->ndim];
  my $data = [];

  # inefficient as hell, but fine for now.
  OUTER: while (1) {
    my $content = $h->get_bin_content($c);
    #print $content, "\n";
    my $elem = $data;
    $elem = ($elem->[$_-1]||=[]) foreach @{$c}[0..$#$c-1];
    $elem->[$c->[-1]-1] = $content;
    foreach my $dim (0..$h->ndim-1) {
      $c->[$dim]++;
      if ($c->[$dim] > $nbins->[$dim]) {
        last OUTER if $dim == $h->ndim-1;
        $c->[$dim] = 1;
      }
      else { last }
    }
  }

  return $data;
}


############################################
# Alternative cumulation implementation by David Golden
# Note: Appears to yield different (wrong?) results for ndim=2 already?

# given AoA-style multi-dimensional structure, index an
# arbitrary element by successive dereferencing
sub lookup {
  my ($ref, $coord) = @_;
  $ref = $ref->[$_] for @$coord;
  return $ref;
}

# assign to AoA-style multi-dimensional structure
sub assign {
  my ($value, $ref, $coord) = @_;
  my $orig = $ref;
  my $last = pop @$coord;
  for my $i ( @$coord ) {
    $ref->[$i] ||= [];
    $ref = $ref->[$i];
  }
  $ref->[$last] = $value;
  return;
}

# crude matrix dumper
sub table {
  my ($data) = @_;
  if ( ref($data->[0]) ) {
    table($_) for @$data;
    print "\n";
  }
  else {
    print "@$data\n";
  }
}

# initialize AoA matrix
sub dim {
  my ($size, @rest) = @_;
  return [ (undef) x $size ] unless @rest;
  my $data;
  for my $i (0 .. $size-1) {
    $data->[$i] = dim(@rest);
  }
  return $data;
}

# recursively calculate cumulations from maximum element
# (destructive on provided output data matrix)
sub cumulate {
  my ($in, $out, $coord) = @_;

  # start with bucket count
  my $sum = lookup($in, $coord);

  # add recursive cumulation from each cardinal direction
  for my $i ( 0 .. $#$coord ) {
    my $adjacent = [ @$coord ];
    next if --$adjacent->[$i] < 0;
    my $l = lookup($out, $adjacent);
    $sum += defined($l) ? $l : cumulate($in, $out, $adjacent);
  }
  # update the output cumulation matrix
  assign($sum, $out, $coord);
  # return the sum for use in recursion
  return $sum;
}

