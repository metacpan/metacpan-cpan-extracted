
package Math::FastGF2::Matrix;

use 5.006000;
use strict;
use warnings;
no warnings qw(redefine);

use Carp;

use Math::FastGF2 ":ops";

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;

@ISA = qw(Exporter Math::FastGF2);
%EXPORT_TAGS = ( 'all' => [ qw( ) ],
	       );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = (  );
$VERSION = '0.06';

require XSLoader;
XSLoader::load('Math::FastGF2', $VERSION);

use constant {
    ROWWISE => 1,
    COLWISE => 2,
};

our @orgs=("undefined", "rowwise", "colwise");

sub new {
  my $proto  = shift;
  my $class  = ref($proto) || $proto;
  my $parent = ref($proto) && $proto;
  my %o=
    (
     rows => undef,
     cols => undef,
     width => undef,
     org => "rowwise",
     @_,
    );
  my $org;			# numeric value 1==ROWWISE, 2==COLWISE
  my $errors=0;

  foreach (qw(rows cols width)) {
    unless (defined($o{$_})) {
      carp "required parameter '$_' not supplied";
      ++$errors;
    }
  }

  if (defined($o{"org"})) {
    if ($o{"org"} eq "rowwise") {
      #carp "setting org to 1 as requested";
      $org=1;
    } elsif ($o{"org"} eq "colwise") {
      #carp "setting org to 2 as requested";
      $org=2;
    } else {
      carp "value of 'org' parameter should be 'rowwise' or 'colwise'";
      ++$errors;
    }
  } else {
    #carp "defaulting org to 1";
    $org=1;			# default to ROWWISE
  }

  if ($o{width} != 1 and $o{width} != 2 and $o{width} != 4) {
    carp "Invalid width $o{width} (must be 1, 2 or 4)";
    ++$errors;
  }

  return undef if $errors;

  return alloc_c($class,$o{rows},$o{cols},$o{width},$org);
}


sub new_identity {
  my $proto  = shift;
  my $class  = ref($proto) || $proto;
  my $parent = ref($proto) && $proto;
  my %o = (
	   size  => undef,
	   org   => "rowwise",	# default to rowwise
	   width => undef,
	   @_
	  );
  unless (defined($o{size}) and $o{size} > 0) {
    carp "new_identity needs a size argument";
    return undef;
  }
  unless (defined($o{width}) and ($o{width}==1 or $o{width}==2 or
				  $o{width}==4)) {
    carp "new_identity needs width parameter of 1, 2 or 4";
    return undef;
  }
  unless (defined($o{org}) and ($o{org} eq "rowwise"
				or $o{org}== "colwise")) {
    carp "new_identity org parameter must be 'rowwise' or 'colwise'";
    return undef;
  }
  my $org = ($o{org} eq "rowwise" ? 1 : 2);

  my $id=alloc_c($class,$o{size},$o{size},$o{width},$org);
  return undef unless $id;
  for my $i (0 .. $o{size} - 1 ) {
    $id->setval($i,$i,1);
  }
  return $id;
}

sub ORG {
  my $self=shift;
  #carp "Numeric organisation value is " . $self->ORGNUM;
  return $orgs[$self->ORGNUM];
}

sub multiply {
  my $self   = shift;
  my $class  = ref($self);
  my $other  = shift;
  my $result = shift;

  unless (defined($other) and ref($other) eq $class) {
    carp "need another matrix to multiply by";
    return undef;
  }
  unless ($self->COLS == $other->ROWS) {
    carp "this matrix's COLS must equal other's ROWS";
    return undef;
  }
  unless ($self->WIDTH == $other->WIDTH) {
    carp "can only multiply two matrices with the same WIDTH";
    return undef;
  }

  if (defined($result)) {
    unless (ref($result) eq $class) {
      carp "result object is not a matrix";
      return undef;
    }
    unless ($self->ROWS == $result->ROWS) {
      carp "this matrix's ROWS must equal result's ROWS";
      return undef;
    }
    unless ($self->WIDTH == $result->WIDTH) {
      carp "result matrix's WIDTH does not match this ones.";
      return undef;
    }
  } else {
    $result=new($class, rows=>$self->ROWS, cols =>$other->COLS,
			width=> $self->WIDTH, org=>$self->ORG);
    unless (defined ($result) and ref($result) eq $class) {
      carp "Problem allocating new RESULT matrix";
      return undef;
    }
  }

  multiply_submatrix_c($self, $other, $result,
		       0,0,$self->ROWS,
		       0,0,$other->COLS);
  return $result;
}

sub eq {
  my $self   = shift;
  my $class  = ref($self);
  my $other  = shift;

  unless (defined($other) and ref($other) eq $class) {
    carp "eq needs another matrix to compare against";
    return undef;
  }
  unless ($self->COLS == $other->COLS) {
    return 0;
  }
  unless ($self->COLS == $other->COLS) {
    return 0;
  }
  unless ($self->WIDTH == $other->WIDTH) {
    return 0;
  }
  return values_eq_c($self,$other);
}


sub ne {
  my $self   = shift;
  my $class  = ref($self);
  my $other  = shift;

  unless (defined($other) and ref($other) eq $class) {
    carp "eq needs another matrix to compare against";
    return undef;
  }
  if ($self->COLS != $other->COLS) {
    return 1;
  }
  if ($self->COLS != $other->COLS) {
    return 1;
  }
  if ($self->WIDTH != $other->WIDTH) {
    return 1;
  }
  return !values_eq_c($self,$other);
}

sub offset_to_rowcol {
  my $self=shift;
  my $offset=shift;

  # XS calls are expensive, so do them only once
  my ($WIDTH, $ROWS, $COLS) = 
      map { $self->$_ } qw{WIDTH ROWS COLS};

  $offset /= $WIDTH;
  if (int($offset) != $offset) {
    carp "offset must be a multiple of WIDTH in offset_to_rowcol";
    return undef;
  }
  if ($offset < 0 or $offset >= $ROWS * $COLS) {
    carp "Offset out of range in offset_to_rowcol";
    return undef;
  }
  if (ROWWISE == $self->ORGNUM) {
      my $row = int ($offset / $COLS);
      return ( ($row), 
	       ($offset - $row * $COLS) ); # = $offset % $cols
  } else {
    return (($offset % $ROWS),
	    (int ($offset / $ROWS)));
  }
}

sub rowcol_to_offset {
  my $self=shift;
  my $row=shift;
  my $col=shift;

  if ($row < 0 or $row >= $self->ROWS) {
    carp "ROW out of range in rowcol_to_offset";
    return undef;
  }
  if ($col < 0 or $col >= $self->COLS) {
    carp "COL out of range in rowcol_to_offset";
    return undef;
  }
  if ($self->ORG eq "rowwise") {
    return ($row * $self->COLS + $col) * $self->WIDTH;# / $self->WIDTH;
  } else {
    return ($col * $self->ROWS + $row) * $self->WIDTH; # / $self->WIDTH
  }
}

sub getvals {
  my $self  = shift;
  my $class = ref($self);
  my $row   = shift;
  my $col   = shift;
  my $words = shift;
  my $order = shift || 0;
  my $want_list = wantarray;

  # XS calls are expensive, so do them only once
  my ($WIDTH, $ROWS, $COLS) = 
      map { $self->$_ } qw{WIDTH ROWS COLS};

  unless ($class) {
    carp "getvals only operates on an object instance";
    return undef;
  }
  #if ($bytes % $self->WIDTH) {
  #  carp "bytes to get must be a multiple of WIDTH";
  #  return undef;
  #}
  unless (defined($row) and defined($col) and defined($words)) {
    carp "getvals requires row, col, words parameters";
    return undef;
  }
  if ($order < 0 or $order > 2) {
    carp "order ($order) != 0 (native), 1 (little-endian) or 2 (big-endian)";
    return undef;
  }
  my $width=$WIDTH;
  my $msize=$ROWS * $COLS;
  if ($row < 0 or $row >= $ROWS) {
    carp "starting row out of range";
    return undef;
  }
  if ($col < 0 or $row >= $ROWS) {
    carp "starting row out of range";
    return undef;
  }

  my $s=get_raw_values_c($self, $row, $col, $words, $order);

  return $s unless $want_list;

  # Since the get_raw_values_c call swaps byte order, we don't do it here
  if ($WIDTH == 1) {
    return unpack "C*", $s;
  } elsif ($WIDTH == 2) {
    return unpack "S*", $s
  } else {
    return unpack "L*", $s;
  }

  # return unpack ($self->WIDTH == 2 ? "v*" : "V*"), $s;
  # return unpack ($self->WIDTH == 2 ? "n*" : "N*"), $s;
}

sub setvals {
  my $self    = shift;
  my $class   = ref($self);
  my ($row, $col, $vals, $order) = @_;
  my ($str,$words);
  $order=0 unless defined($order);

  # XS calls are expensive, so do them only once
  my ($WIDTH, $ROWS, $COLS) = 
      map { $self->$_ } qw{WIDTH ROWS COLS};

  unless ($class) {
    carp "setvals only operates on an object instance";
    return undef;
  }
  unless (defined($row) and defined($col)) {
    carp "setvals requires row, col, order parameters";
    return undef;
  }
  if ($order < 0 or $order > 2) {
    carp "order != 0 (native), 1 (little-endian) or 2 (big-endian)";
    return undef;
  }
  if ($row < 0 or $row >= $ROWS) {
    carp "starting row out of range";
    return undef;
  }
  if ($col < 0 or $row >= $ROWS) {
    carp "starting row out of range";
    return undef;
  }

  if(ref($vals)) {
    # treat $vals as a list(ref) of numbers
    unless ($words=scalar(@$vals)) {
      carp "setvals: values must be either a string or reference to a list";
      return undef;
    }
    if ($WIDTH == 1) {
      $str=pack "C*", @$vals;
    } elsif ($WIDTH == 2) {
      $str=pack "S*", @$vals;
    } else {
      $str=pack "L*", @$vals;
    }
  } else {
    # treat vals as a string
    $str="$vals";
    $words=(length $str) / $WIDTH;
  }

  my $msize=$ROWS * $COLS;
  if ( ((ROWWISE == $self->ORGNUM) and
	($words + $COLS * $row + $col > $msize)) or
       ($words + $ROWS * $col + $row > $msize)) {
    carp "string length exceeds matrix size";
    return undef;
  }

  #carp "Writing $words word(s) to ($row,$col) (string '$str')";
  set_raw_values_c($self, $row, $col, $words, $order, $str);
  return $str;
}

# return new matrix with self on left, other on right
sub concat {
  my $self  = shift;
  my $class = ref($self);
  my $other = shift;

  unless (defined($other) and ref($other) eq $class) {
    carp "concat needs a second matrix to operate on";
    return undef;
  }
  unless ($self->WIDTH == $other->WIDTH) {
    carp "concat: incompatible matrix widths";
    return undef;
  }
  unless ($self->ROWS == $other->ROWS) {
    carp "can't concat: the matrices have different number of rows";
    return undef;
  }

  my $cat=alloc_c($class, $self->ROWS, $self->COLS + $other->COLS,
		  $self->WIDTH, $self->ORGNUM);
  return undef unless defined $cat;
  if ($self->ORG eq "rowwise") {
    my $s;
    for my $row (0.. $other->ROWS - 1) {
      $s=get_raw_values_c($self, $row, 0, $self->COLS, 0);
      set_raw_values_c   ($cat,  $row, 0, $self->COLS, 0, $s);
      for my $col (0.. $other->COLS - 1) {
	$cat->setval($row, $self->COLS + $col,
		     $other->getval($row,$col));
      }
    }
  } else {
    my $s;
    $s=get_raw_values_c($self, 0, 0, $self->COLS * $self->ROWS, 0);
    set_raw_values_c   ($cat,  0, 0, $self->COLS * $self->ROWS, 0, $s);
    for my $row (0.. $other->ROWS - 1) {
      for my $col (0.. $other->COLS - 1) {
	$cat->setval($row, $self->COLS + $col,
		     $other->getval($row,$col));
      }
    }
  }

  return $cat;
}

# Swapping rows and columns in a matrix is done in-place
sub swap_rows {
  my ($self, $row1, $row2, $start_col) = @_;
  return if $row1==$row2;
  $start_col=0 unless defined $start_col;

  my $cols=$self->COLS;
  my ($s,$t);

  if ($self->ORG eq "rowwise") {
    $s=get_raw_values_c($self, $row1, $start_col,
			$cols - $start_col, 0);
    $t=get_raw_values_c($self, $row2, $start_col,
			$cols - $start_col, 0);
    set_raw_values_c   ($self, $row1, $start_col,
			$cols - $start_col, 0, $t);
    set_raw_values_c   ($self, $row2, $start_col,
			$cols - $start_col, 0, $s);
  } else {
    for my $col ($start_col .. $cols -1) {
      $s=$self->getval($row1,$col);
      $t=$self->getval($row2,$col);
      $self->setval($row1, $col, $t);
      $self->setval($row2, $col, $s);
    }
  }
}

sub swap_cols {
  my ($self, $col1, $col2, $start_row) = @_;
  return if $col1==$col2;
  $start_row=0 unless defined $start_row;

  my $rows=$self->ROWS;
  my ($s,$t);

  if ($self->ORG eq "colwise") {
    $s=get_raw_values_c($self, $start_row, $col1,
			$rows - $start_row, 0);
    $t=get_raw_values_c($self, $start_row, $col2,
			$rows - $start_row, 0);
    set_raw_values_c   ($self, $start_row, $col1,
			$rows - $start_row, 0, $t);
    set_raw_values_c   ($self, $start_row, $col2,
			$rows - $start_row, 0, $s);
  } else {
    for my $row ($start_row .. $rows -1) {
      $s=$self->getval($row,$col1);
      $t=$self->getval($row,$col2);
      $self->setval($row, $col1, $t);
      $self->setval($row, $col2, $s);
    }
  }
}


# I'll replace this with some C code later
sub solve {

  my $self  = shift;
  my $class = ref($self);

  my $rows=$self->ROWS;
  my $cols=$self->COLS;
  my $bits=$self->WIDTH * 8;

  unless ($cols > $rows) {
    carp "solve only works on matrices with COLS > ROWS";
    return undef;
  }

  # work down the diagonal one row at a time ...
  for my $row (0 .. $rows - 1) {

    # We have to check whether the matrix is non-singular; all k x k
    # sub-matrices generated by the split part of the IDA are
    # guaranteed to be invertible, but user-supplied matrices may not
    # be, so we have to test for this.

    if ($self->getval($row,$row) == 0) {
      print "had to swap zeros\n";
      my $found=undef;
      for my $other_row ($row + 1 .. $rows - 1) {
	next if $row == $other_row;
	if ($self->getval($other_row,$row) != 0) {
	  $found=$other_row;
	  last;
	}
      }
      return undef unless defined $found;
      $self->swap_rows($row,$found,$row);
    }

    # normalise the current row first
    my $diag_inverse = gf2_inv($bits,$self->getval($row,$row));

    $self->setval($row,$row,1);
    for my $col ($row + 1 .. $cols - 1) {
      $self->setval($row,$col,
	gf2_mul($bits, $self->getval($row,$col), $diag_inverse));
    }

    # zero all elements above and below ...
    for my $other_row (0 .. $rows - 1) {
      next if $row == $other_row;

      my $other=$self->getval($other_row,$row);
      next if $other == 0;
      $self->setval($other_row,$row,0);
      for my $col ($row + 1 .. $cols - 1) {
	$self->setval($other_row,$col,
	  gf2_mul($bits, $self->getval($row,$col), $other) ^
	    $self->getval($other_row,$col));
      }
    }
  }

  my $result=alloc_c($class, $rows, $cols - $rows,
		     $self->WIDTH, $self->ORGNUM);
  for my $row (0 .. $rows - 1) {
    for my $col (0 .. $cols - $rows - 1) {
      $result->setval($row,$col,
		      $self->getval($row, $col + $rows));
    }
  }

  return $result;
}

sub invert {

  my $self  = shift;
  my $class = ref($self);

  #carp "Asked to invert matrix!";

  unless ($self->COLS == $self->ROWS) {
    carp "invert only works on square matrices";
    return undef;
  }

  my $cat=
    $self->concat($self->new_identity(size => $self->COLS,
				      width => $self->WIDTH));
  return undef unless defined ($cat);
  return $cat->solve;
}

sub zero {
  my $self  = shift;
  my $class = ref($self);

  $self->setvals(0,0,"\0" x ($self->ROWS * $self->COLS * $self->WIDTH));

}


# Create a new Cauchy matrix
# (was being done in Crypt::IDA before, but it's more relevant here)
sub new_cauchy {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $parent = ref($proto) && $proto;
    my %o = (
	org       => "rowwise",
	width     => undef,
	xvals     => undef,	# was "sharelist"
	yvals     => undef,
	xyvals    => undef,	# was "key"
	rows      => undef,
	cols      => undef,
	@_
    );

    my $w   = $o{width}    || die "width parameter required\n";

    # any of these could be undefined
    my ($rows, $cols, $xvals, $yvals);
    $rows  = $o{rows};
    $cols  = $o{cols};
    $xvals = $o{xvals};
    $yvals = $o{yvals};

    if (defined $o{xyvals}) {
	my $xyvals =  $o{xyvals};
	die "Can't pass both xyvals and xvals\n" if defined $xvals;
	die "Can't pass both xyvals and yvals\n" if defined $yvals;

	if (defined $rows and !defined $cols) {
	    $cols = @$xyvals - $rows;
	    # warn "Rows was $rows. Set 'cols' to $cols\n";
	} elsif (defined $cols and !defined $rows) {
	    $rows = @$xyvals - $cols;
	    # warn "Cols was $cols. Set 'rows' to $rows\n";
	} else {
	    die "Passing xyvals requires rows and/or cols\n";
	}

	# case where both are defined is handled later

	# break up into two lists
	$xvals = [@$xyvals[0.. $rows - 1]];
	$yvals = [@$xyvals[$rows .. $rows + $cols - 1]];
	# warn "Set up xvals with " . (@$xvals+0) . " elements\n";
	# warn "Set up yvals with " . (@$yvals+0) . " elements\n";
    } else {
	# if user sets cols/rows explicitly, don't overwrite
	$rows = scalar(@$xvals) if defined $xvals and !defined $rows;
	$cols = scalar(@$yvals) if defined $yvals and !defined $cols;
    }

    die "Must have either xyvals + rows/cols or xvals + yvals\n"
	unless defined $xvals and defined $yvals;
    die "Rows/xvals are inconsistent\n" unless @$xvals == $rows;
    die "Cols/yvals are inconsistent\n" unless @$yvals == $cols;
    die "Must have rows >= cols\n" unless $rows >= $cols;

    # Note: no check done to ensure that x,y values are unique
    my @x   = @$xvals;
    my @y   = @$yvals;

    my $self = $class->new(rows => $rows, cols => $cols, width => $w,
			   org => $o{org});
    die unless ref $self;

    # ported from IDA::ida_key_to_matrix
    $w <<= 3; 			# bits <- bytes
    for my $row (0..$rows - 1 ) {
	for my $col (0 .. $cols - 1) {
	    my $xi  = $x[$row];
	    my $yj  = $y[$col];
	    $self->setval($row, $col, gf2_inv($w, $xi ^ $yj));
	}
    }
    return $self;
}


#
# New method to calculate inverse Cauchy matrix given list:
#
# xyvals = [ x_1, ... x_n, y_1, ... y_k ]
#
# See Wikipedia page on Cauchy matrices:
#
# https://en.wikipedia.org/wiki/Cauchy_matrix
#
# A better page:
#
# https://proofwiki.org/wiki/Inverse_of_Cauchy_Matrix

sub new_inverse_cauchy {

    # parameter names were based on Crypt::IDA::ida_key_to_matrix
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $parent = ref($proto) && $proto;
    my %o = (
	org       => "rowwise",
	size      => undef,	# was "quorum"
	width     => undef,
	#shares    => undef,	# was "shares"
	xvals     => undef,	# was "sharelist"
	width     => undef,
	xylist    => undef,	# was "key"
	
	@_
    );

    # Our "key" is in x's, y's format. The last "quorum" values are y's
    # To create a square matrix, we only take the x values specified
    # in the xvals listref
    my $k   = $o{size}     || die "size parameter required\n";
    my $w   = $o{width}    || die "width parameter required\n";
    my $key = $o{xylist}   || die "xylist parameter required\n";
    die "xvals parameter required\n" unless defined $o{xvals};

    # Note: no check done below to ensure that xvals are unique
    my @x   = map {$key->[$_]} @{$o{xvals}};
    my @y   = splice @$key, -$k;
    push @$key, @y; 	# splice is destructive; undo damage

    #    warn "xlist: [" . (join ", ", @x) . "]\n";
    #    warn "ylist: [" . (join ", ", @y) . "]\n";
    die if @x - @y;		# is it square?
    die if @$key < 2 * $k;	# is n >= k?
    die if @x != $k;		# did user supply k xvals?

    my $self = $class->new(rows => $k, cols => $k, width => $w,
			   org => $o{org});
    die unless ref $self;

    # Using the proof wiki page as a guide...
    #
    # rename k to n so we can use it as a loop counter (and go -1
    # because we're using zero-based indexes)
    my ($i, $j, $n, $bits) = (0,0, $k-1, $w * 8);

    if ($n < 3) {
	# unoptimised version
	for $i (0 .. $n) {
	    for $j (0 .. $n) {
		
		my $top = 1;	# multiplicative identity
		map {
		    $top = gf2_mul($bits, $top, $x[$j] ^ $y[$_]);
		    $top = gf2_mul($bits, $top, $x[$_] ^ $y[$i]);
		} (0 .. $n);
		
		my $bot = $x[$j] ^ $y[$i];
		
		map { $bot = gf2_mul($bits, $bot, $x[$j] ^ $x[$_]) }
		grep { $_ != $j } (0 .. $n); # $_ is our $k
		
		map { $bot = gf2_mul($bits, $bot, $y[$i] ^ $y[$_]) }
		grep { $_ != $i } (0 .. $n); # $_ is our $k
		
		$top = gf2_mul($bits, $top, gf2_inv($bits, $bot));
		
		$self->setval($i,$j,$top);
	    }
	}
    } else {
	# The above two big product loops are ripe for optimisation
	# Instead of calculating:
	# * product of row except for ... (n-1 multiplications)
	# * product of col except for ... (n-1 multiplications)
	# You can memoise full row/col products 
	# 
	# This should be hugely noticeable for large n, but should
	# probably also even have a positive effect for n>3 assuming
	# a word size of 1 byte and gf2_inv that is as cheap (or cheaper)
	# than a multiplication.

	my @jmemo = ();
	for $j (0..$n) {
	    my ($sum,$xj) = (1, $x[$j]);
	    map { $sum = gf2_mul($bits, $sum, $xj ^ $x[$_]) } 
	    grep { $_ != $j} (0..$n);
	    push @jmemo, $sum;
	}
	my @imemo = ();
	for $i (0..$n) {
	    my ($sum,$yi) = (1, $y[$i]);
	    map { $sum = gf2_mul($bits, $sum, $yi ^ $y[$_]) }
	    grep {$_ != $i} (0..$n);
	    push @imemo, $sum;
	}
	for $i (0 .. $n) {
	    for $j (0 .. $n) {

		# We can save one multiplication by 1 below:
		my $top = gf2_mul($bits, $x[$j] ^ $y[0], $x[0] ^ $y[$i]);
		map {
		    $top = gf2_mul($bits, $top, $x[$j] ^ $y[$_]);
		    $top = gf2_mul($bits, $top, $x[$_] ^ $y[$i]);
		} (1 .. $n);
	
		my $bot = $x[$j] ^ $y[$i];
		$bot = gf2_mul($bits, $bot, $jmemo[$j]);
		$bot = gf2_mul($bits, $bot, $imemo[$i]);
		
		$top = gf2_mul($bits, $top, gf2_inv($bits, $bot));
		
		$self->setval($i,$j,$top);
	    }
	}
    }
    return $self;
}

sub new_vandermonde {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $parent = ref($proto) && $proto;
    my %o = (
	org        => "rowwise",
	cols       => undef,
	width      => undef,
	xvals     => undef,  
	@_
    );

    # pull out variables
    my ($org,$cols,$width,$xvals) = 
	@o{qw(org cols width xvals)}; # hash slice

    die "xvals must be a listref\n" unless ref($xvals) eq "ARRAY";
    die "need cols > 0" unless defined $cols and $cols >0;

    my $rows = @$xvals;

    my $self = $class->new(
	org => $org, width => $width, rows => $rows, cols => $cols);
    die unless ref($self);

    # populate all the rows
    my $w = $width << 3;
    for my $row (0 .. $rows -1) {
	$self->setval($row,0,1);
	my $x = 1;
	for my $col (1 .. $cols -1) {
	    $x = gf2_mul($w,$x,$xvals->[$row]);
	    $self->setval($row,$col,$x);
	}
    }
    
    $self;    
}    

sub print {
    my $self = shift;
    #die ref $self;
    my $rows  = $self->ROWS;
    my $cols  = $self->COLS;
    my $w     = $self->WIDTH;
    $w <<= 1;

    for my $row (0.. $rows -1) {
	print "| ";
	for my $col (0.. $cols -1) {
	    my $f =" {%0${w}x} ";
	    printf $f, $self->getval($row,$col);
	}
	print "|\n";
    }
}


# Generic routine for copying some matrix elements into a new matrix
#
# rows => [ $row1, $row2, ... ]
# cols => [ $col1, $col2, ... ]
# submatrix => [ $first_row, $first_col, $last_row, $last_col ]
#
# In order to keep this routine fairly simple, the newly-created
# matrix will have the same organisation as the original, and we won't
# allow for transposition in the same step.
sub copy {
  my $self  = shift;
  my $class = ref($self);
  my %o=(
	 rows => undef,
	 cols => undef,
	 submatrix => undef,
	 @_,
	);

  my $rows      = $o{rows};
  my $cols      = $o{cols};
  my $submatrix = $o{submatrix};

  if (defined($submatrix)) {
    if (defined($rows) or defined($cols)) {
      carp "Can't specify both submatrix and rows/cols";
      return undef;
    }
    my ($row1,$col1,$row2,$col2)=@$submatrix;
    unless (defined($row1) and defined($col1) and
	    defined($row2) and defined($col2)) {
      carp 'Need submatrx => [$row1,$col1,$row2,$col2]';
      return undef;
    }

    unless ($row1 >=0 and $row1 <= $row2 and $row2 < $self->ROWS and
	    $col1 >=0 and $col1 <= $col2 and $col2 < $self->COLS) {
      carp "submatrix corners out of range";
      return undef;
    }
    my $mat=alloc_c($class, $row2 - $row1 + 1, $col2 - $col1 + 1,
		    $self->WIDTH, $self->ORGNUM);
    my ($s,$dest)=("",0);
    if ($self->ORG eq "rowwise") {
      for my $r ($row1 .. $row2) {
	$s=$self->getvals($r,$col1,$col2 - $col1 + 1);
	$mat->setvals($dest,0,$s);
	++$dest;
      }
    } else {
      for my $c ($col1 .. $col2) {
	$s=$self->getvals($row1,$c,$row2 - $row1 + 1);
	$mat->setvals(0,$dest,$s);
	++$dest;
      }
    }
    return $mat;

  } elsif (defined($rows) or defined($cols)) {

    if (defined($rows) and !ref($rows)) {
      carp "rows must be a reference to a list of rows";
      return undef;
    }
    if (defined($cols) and !ref($cols)) {
      carp "cols must be a reference to a list of columns";
      return undef;
    }

    if (defined($rows) and defined($cols)) {
      my $mat=alloc_c($class, scalar(@$rows), scalar(@$cols),
		      $self->WIDTH, $self->ORGNUM);
      my $dest_row=0;
      my $dest_col;
      for my $r (@$rows) {
	$dest_col=0;
	for my $c (@$cols) {
	  $mat->setval($dest_row,$dest_col++,
		       $self->getval($r,$c));
	}
	++$dest_row;
      }
      return $mat;

    } elsif (defined($rows) and $self->ORG eq "rowwise") {
      my $mat=alloc_c($class, scalar(@$rows), $self->COLS,
		      $self->WIDTH, $self->ORGNUM);
      my ($s,$dest)=("",0);
      for my $r (@$rows) {
	$s=$self->getvals($r,0,$self->COLS);
	$mat->setvals($dest,0,$s);
	++$dest;
      }
      return $mat;

    } elsif (defined($cols) and $self->ORG eq "colwise") {
      my $mat=alloc_c($class, $self->ROWS, scalar(@$cols),
		      $self->WIDTH, $self->ORGNUM);
      my ($s,$dest)=("",0);
      for my $c (@$cols) {
	$s=$self->getvals(0,$c,$self->ROWS);
	$mat->setvals(0,$dest,$s);
	++$dest;
      }
      return $mat;

    } else {
      # we've been told to copy some rows or some columns, but the
      # organisation of the matrix doesn't allow for using quick
      # getvals. Iterate as we would have done if both rows and cols
      # were specified, but set whichever of rows/cols wasn't set to
      # the input matrix's rows/cols.
      $rows=[ 0 .. $self->ROWS - 1] unless defined($rows);
      $cols=[ 0 .. $self->COLS - 1] unless defined($cols);
      my $mat=alloc_c($class, scalar(@$rows), scalar(@$cols),
		      $self->WIDTH, $self->ORGNUM);
      my $dest_row=0;
      my $dest_col;
      for my $r (@$rows) {
	$dest_col=0;
	for my $c (@$cols) {
	  $mat->setval($dest_row,$dest_col++,
		       $self->getval($r,$c));
	}
	++$dest_row;
      }
      return $mat;

    }

  } else {
    # No submatrix/rows/cols option given, so do a full copy. This is
    # made easy by not allowing transpose or re-organistaion options
    my $mat=alloc_c($class, $self->ROWS, $self->COLS,
		    $self->WIDTH, $self->ORGNUM);
    return undef unless defined $mat;
    my $s=$self->getvals(0,0,$self->ROWS * $self->COLS);
    $mat->setvals(0,0,$s);
    return $mat;
  }

  die "Unreachable? ORLY?\n";
}

# provide aliases for all forms of copy except copy rows /and/ cols

sub copy_rows {
  return shift -> copy(rows => [ @_ ]);
}

sub copy_cols {
  return shift -> copy(cols => [ @_ ]);
}

sub submatrix {
  return shift -> copy(submatrix => [ @_ ]);
}

# Roll the transpose and reorganise code into one "flip" routine.
# This can save the user one step in some cases.

sub flip {
  my $self=shift;
  my %o=( transpose => 0, org => $self->ORG, @_ );

  my $transpose=$o{"transpose"};
  my $mat;
  my ($fliporg,$neworg);
  my ($r,$c,$s);

  if (($o{"org"} ne $self->ORG)) {
    $neworg=$o{"org"};
    $fliporg=1;
  } else {
    $neworg=$self->ORG;
    $fliporg=0;
  }

  if ($transpose) {
    $mat=Math::FastGF2::Matrix->
      new(rows => $self->COLS, cols=>$self->ROWS,
	  width => $self->WIDTH, org => $neworg);
    return undef unless defined ($mat);
    if ($fliporg) {
      $s=$self->getvals(0,0,$self->COLS * $self->ROWS);
      $mat->setvals(0,0,$s);
    } else {
      for $r (0..$self->ROWS - 1) {
	for $c (0..$self->COLS - 1) {
	  $mat->setval($c,$r,$self->getval($r,$c));
	}
      }
    }
    return $mat;

  } elsif ($fliporg) {
    $mat=Math::FastGF2::Matrix->
      new(rows => $self->ROWS, cols=> $self->COLS,
	  width => $self->WIDTH, org => $neworg);
    return undef unless defined ($mat);
    for $r (0..$self->ROWS - 1) {
      for $c (0..$self->COLS - 1) {
	$mat->setval($r,$c,$self->getval($r,$c));
      }
    }
    return $mat;

  } else {
    # no change, but return a new copy of self to be in line with all
    # other input cases.
    return $self->copy;
  }
  die "Unreachable? ORLY?\n";
}


sub transpose {
  return shift -> flip(transpose => 1);
}

sub reorganise {
  my $self=shift;

  if ($self->ORG eq "rowwise") {
    return $self->flip(org => "colwise");
  } else {
    return $self->flip(org => "rowwise");
  }
}


1;

__END__

=head1 NAME

Math::FastGF2::Matrix - Matrix operations for fast Galois Field arithmetic

=head1 SYNOPSIS

 use Math::FastGF2::Matrix;
 
 $m=Math::FastGF2::Matrix->
   new(rows => $r, cols => $c, width => $w, org => "rowwise");
 $i=Math::FastGF2::Matrix->
   new_identity(size => $size, width => $w, org => "rowwise");
 $copy=$m->copy( ... );
 $copy=$m->copy_rows($row1, $row2, ... );
 $copy=$m->copy_cols($col1, $col2, ... );
 $copy=$m->submatrix($row1,$col1,$row2,$col2);
 $copy=$m->flip(...);
 $copy=$m->transpose;
 $copy=$m->reorganise;

 $rows = $m->ROWS;   $cols  = $m->COLS;
 $org  = $m->ORG;    $width = $m->WIDTH;
 
 $val=$m->getval($row,$col);
 $m->setval($row,$col,$val);
 $m->zero;
 
 @vals=$m->getvals($row,$col,$words,$order);
 $vals=$m->getvals($row,$col,$words,$order);
 $vals=$m->setvals($row,$col,\@vals,$order);
 $vals=$m->setvals($row,$col,$vals,$order);
 
 $product=$m->multiply($m);
 $inverse=$m->invert;
 $adjoined=$m->concat($m);
 $solution=$m->solve;

=head1 DESCRIPTION

This module provides basic functionality for handling matrices of
Galois Field elements. It is a fairly "close to the metal"
implementation using the C language to store the underlying object and
handle performance-critical tasks such as bulk input/output of values
and matrix multiplication. Less critical tasks are handled by Perl
methods.

All matrix elements are treated as polynomials in GF(2^m), with all
calculations on them being done using the Math::FastGF2 module.

=head1 CONSTRUCTORS

=head2 new

New Math::FastGF2::Matrix objects are created and initialised to with
zero values with the C<new()> constructor method:

 $m=Math::FastGF2::Matrix->
   new(rows => $r, cols => $c, width => $w, org => "rowwise");

The rows and cols parameters specify how many rows and columns the new
matrix should have. The width parameter must be set to 1, 2 or 4 to
indicate Galois Fields of that many bytes in size.

The C<org> parameter is optional and defaults to "rowwise" if
unset. This parameter specifies how the matrix should be organised in
memory, which affects how the bulk data input/output routines
C<setvals> and C<getvals> enter data and retrieve it from the
matrix. With "rowwise" organisation, values are written in
left-to-right order first, moving down to the next row as each row
becomes full. With "colwise" organisation, values are written
top-to-bottom first, moving right to the next column as each column
becomes full.

=head2 new_identity

To create a new identity matrix with C<$size> rows and columns, width
C<$w> and organisation C<$org>:

 $i=Math::FastGF2::Matrix->
          new_identity(size => $size, width => $w, org => $org);

As with the C<new> constructor, the C<org> parameter is optional and
default to "rowwise".

=head2 new_cauchy

Create a Cauchy matrix from a set of x and y values:

 my @xvals = (1..7);        # all values must be distinct across
 my @yvals = (8..10);       # the combined list
 
 # Passing separate x and y lists (rows/cols inferred)
 $i=Math::FastGF2::Matrix->
          new_cauchy(width => 1, org => "rowwise",
                     xvals => \@xvals, yvals => \@yvals
          );

 # Passing combined list and at least one of rows/cols
 $i=Math::FastGF2::Matrix->
          new_cauchy(width => 1, org => "rowwise",
                     xyvals => [@xvals, @yvals],
                     rows => scalar(@xvals),
                     cols => scalar(@yvals),
          );

Cauchy matrices have the useful property that for a matrix of n rows
and k columns, all subsets of k rows are linearly independent with
respect to each other. Thus this submatrix is invertible. This has
applications in constructing error-correcting codes. See the
L<Crypt::IDA> manual page for details.

=head2 new_inverse_cauchy

Creates an inverse Cauchy matrix from a set of y values and an subset
of x values:

 my @xvals = (20..27);        # all values must be distinct across
 my @yvals = (28..30);        # the combined list
 
 $i=Math::FastGF2::Matrix->
      new_inverse_cauchy(width => 1, org => "rowwise",
                         xylist => [ @xvals, @yvals ],
                         size => 3,       # size of y list
                         xvals => [0..3], # indexes into x list
 );

Note that the xvals parameter in this case is a set of indices into
the C<@xvals> array. Effectively, it selects 'size' rows from the
Cauchy matrix described by C<[ @xvals, @yvals ]> and inverts that
matrix.

This uses an algorithm described in volume 1 of Knuth's I<"The Art of
Computer Programming">, which should run faster than the regular
Gaussian elimination method implemented by the C<invert> method.

=head2 new_vandermonde

Create a Vandermonde matrix from a list of x values

 $i=Math::FastGF2::Matrix->
      new_vandermonde(width => 1, org => "rowwise",
                      xvals => [ 0..6 ],  # 7 rows
                      cols   => 3,
 );

For each x_i value, creates a row of the form:

        |     0    1    2          cols-1  |
        |   x    x    x   ...    x         |
        |    i    i    i          i        |

If all the x_i values in the list are distinct, then, like the Cauchy
matrix above, taking any 'cols' subset of rows from the matrix gives
you an invertible matrix. This is the form of matrix generally used
for Reed-Solomon error-correcting codes.

To create the inverse of some cols x cols submatrix, just use the
standard C<invert> method on it.

=head2 copy

The copy method copy of some or all elements of an existing
matrix. The template for a call, showing the default values of all
parameters is as follows:

 $new_matrix = $m->copy(
	 rows => undef,		# [ $row1, $row2, ... ]
	 cols => undef,		# [ $col1, $col2, ... ]
	 submatrix => undef,    # [ $row1, $col1, $row2, $col2 ]
 );

If no parameters are set, then then the entire matrix is copied. The
C<rows> and C<cols> parameters can be set individually or in
combination with each other, to copy only the selected rows or columns
to the new matrix. The C<submatrix> parameter copies a rectangular
region of the original matrix into the new matrix. The C<submatrix>
option cannot be used in combination with the C<rows> or C<cols>
options.

The new matrix will have the same values set for the C<width> and
C<org> parameters as the original matrix.

The C<copy_rows>, C<copy_cols> and C<submatrix> methods are
implemented as small wrapper functions which call the C<copy> method
with the appropriate parameters.

=head2 copy_rows

 $new_matrix = $m->copy_rows ($row1, $row2, ... );

Create a new matrix from the selected rows of the original
matrix.

=head2 copy_cols

 $new_matrix = $m->copy_cols ($col1, $col2, ... );

Create a new matrix from the selected columns of the original
matrix.

=head2 submatrix

 $new_matrix = $m->submatrix ($row1, $col1, $row2, $col2);

Create a new matrix from the selected rectangular region of the
original matrix.

=head2 transpose

Return a new matrix which is the transpose of the original matrix. The
organisation of the original matrix is carried over to the new matrix:

 $new_matrix = $m->transpose;

=head2 reorganise

Return a new matrix which has the opposite organisation to the
original matrix:

 $new_matrix = $m->reorganise;

=head2 flip

Carry out transpose and/or reorganise operations in one step:

 $new_matrix = $m->flip( transpose = > (0 or 1),
                         org => ("rowwise" or "colwise") );

The org parameter is the organisation to use for the new matrix.

=head1 GETTING AND SETTING VALUES

Getting and setting individual values in the matrix is handled by the
C<getval> and C<setval> methods:

 $val=$m->getval($row,$col);
 $m->setval($row,$col,$val);

Multiple values can be got/set at once, using the more efficient
C<getvals>/C<setvals> methods:

 @vals=$m->getvals($row,$col,$words,$order);
 $vals=$m->getvals($row,$col,$words,$order);
 $vals=$m->setvals($row,$col,\@vals,$order);
 $vals=$m->setvals($row,$col,$vals,$order);

These methods copy the values out of/into the C data structure. The
C<$words> parameter to C<getvals> specifies how many values to extract
from the Matrix.

These methods can take an optional C<$order> parameter which can be
used to perform byte-swapping on 2-byte and 4-byte words where it is
needed. The possible values are:

=over

=item 0. input is/output should be in native byte order (no
byte-swapping)

=item 1. input is/output should be in little-endian byte order

=item 2. input is/output should be in big-endian byte order

=back

=cut

If the specified byte order is different from the native byte order on
the machine, then bytes within each word will be swapped. Otherwise,
the values are passed through unchanged.

All these routines have the choice of operating on strings (close to
the internal representation of the matrix in memory) or lists of
values (regular numeric scalars, as used by getval/setval). Byte order
translation (where specified) is performed regardless of whether
strings or lists are used. Operating with strings is slightly more
efficient than using lists of values, since data can be copied with
fewer operations without needing to pack/unpack a list of values.

=head2 Examples

To swap two rows of a "rowwise" matrix using temporary lists

 die "Expected matrix to be ROWWISE\n" unless $m->ORG eq "rowwise"
 @list1 = $m->getvals($row1,0,$m->COLS);
 @list2 = $m->getvals($row2,0,$m->COLS);
 $m->setvals($row1,0,\@list2);
 $m->setvals($row2,0,\@list1);

The same example using slightly more efficient string form:

 die "Expected matrix to be ROWWISE\n" unless $m->ORG eq "rowwise"
 $str1 = $m->getvals($row1,0,$m->COLS);
 $str2 = $m->getvals($row2,0,$m->COLS);
 $m->setvals($row1,0,$str2);
 $m->setvals($row2,0,$str1);

This is an example of how I<not> to implement the above. It fails
because getvals is being called in a list context. I<Beware>:

 ($str1,$str2) = ( $m->getvals($row1,0,$m->COLS),
                   $m->getvals($row2,0,$m->COLS) );
 $m->setvals($row1,0,$str2);
 $m->setvals($row2,0,$str1);

Likewise, this common idiom also implies a list context:

 my ($var) = ...

When in doubt about list/scalar context, always use a simple
assignment to a scalar variable. Alternatively, scalar context can be
enforced by using Perl's C<scalar> keyword, eg:

 my ($str) = (scalar $m->getvals(...));

Read in some little-endian values from a file, and have them converted
to Perl's internal format if necessary:

 # assume ROWWISE, writing values into row $row of matrix
 sysread $fh, $str, $m->COLS * $m->WIDTH;
 $m->setvals($row,0,$str,1);

Take values from a matrix and output them to a file as a list of
little-endian values:

 # assume ROWWISE, reading values from row $row of matrix
 $str=$m->getvals($row,0,$str,1);
 syswrite $fh, $str, $m->COLS * $m->WIDTH;

Zero all elements in a matrix (works regardless of matrix
organisation):

 $m->setvals(0,0,(0) x ($m->ROWS * $m->COLS));

or:

  $m->setvals(0,0,"\0" x ($self->ROWS * $self->COLS * $self->WIDTH));

(which is exactly what the C<zero> method does.)

=head1 MATRIX OPERATIONS

=head2 Multiply

To multiply two matrices $m1 (on left) and $m2 (on right), use:

 $result=$m1->multiply($m2);

This returns a new matrix in C<$result> or undef on error. The number
of columns in C<$m1> must equal the number of rows in C<$m2>. The
resulting matrix will have the same number of rows as $m1 and the same
number of columns as $m2. An alternative form allows storing the
result in an existing matrix (of the appropriate dimensions), thus
avoiding the overhead of allocating a new one:

 $m1->multiply($m2,$result);

The C<$result> matrix is also returned, though it can be safely
ignored.

=head2 Invert

To invert a square matrix (using Gauss-Jordan method):

 $inverse=$m->invert;

A new inverse matrix is returned if the matrix was invertible, or
undef otherwise.

=head2 Concat(enate)

To create a new matrix which has matrix $m1 on the left and $m2 on the
right, use:

$adjoined = $m1->concat($m2);

The number of rows in C<$m1> and C<$m2> must be the same. Returns a
new matrix or undef in the case of an error.

=head2 Solve

Treat matrix as a set of simultaneous equations and attempt to solve
it using Gaussian elimination:

 $solution=$m->solve;

The result is a new matrix, or undef if the equations have no
solution. The input matrix must have at least one more column than
rows, with the first $m->ROWS columns being the coefficients of the
equations to be solved (ie, the left-hand side of equations), and the
remaining column(s) being the value(s) the equations evaluate to (ie,
the right-hand side of equations).

=head2 Equality

To test whether two matrices have the same values:

 if ($m1->eq($m2)) {
   # Matrices are equal
   ...
 }

Testing for inequality:

 if ($m1->ne($m2)) {
   # Matrices are not equal
   ...
 }

=head1 SEE ALSO

See L<Math::FastGF2> for details of the underlying Galois Field
arithmetic.

See L<Math::Matrix> for storing and manipulating matrices of regular
numbers.

=head1 AUTHOR

Declan Malone, E<lt>idablack@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Declan Malone

This package is free software; you can redistribute it and/or modify
it under the terms of the "GNU General Public License" ("GPL").

Please refer to the file "GNU_GPL.txt" in this distribution for
details.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut



