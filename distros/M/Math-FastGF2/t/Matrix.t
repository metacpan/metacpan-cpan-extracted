# -*- Perl -*-

use Test::More tests => 195;
BEGIN { use_ok('Math::FastGF2::Matrix', ':all') };

my $failed;
my $class="Math::FastGF2::Matrix";

# Create a 1x1 matrix?
my $onesquare;
for my $w (1,2,4) {
  $onesquare=Math::FastGF2::Matrix->new(rows=>1, cols =>1, width=>$w);
  ok((defined($onesquare) and ref($onesquare) eq $class),
     "Create 1x1 matrix, width $w?");
}

# Create a 2x2 matrix and do some tests on it
my $m=Math::FastGF2::Matrix->new(rows=>2, cols =>2, width=>1);

ok(ref($m) eq $class,    "new returns correct class?");
ok($m->ROWS == 2,        "ROWS returns correct value?");
ok($m->COLS == 2,        "COLS returns correct value?");
ok($m->WIDTH == 1,       "WIDTH returns correct value?");
ok($m->ORG eq "rowwise", "ORG returns correct value?");

$failed=0;
map { ++$failed if $m->getval($_/2, $_ & 1) } 0..3;
ok (!$failed,  "All values initialised to zero?");

$failed=0;
map { ++$failed if $_*7 + 1 != $m->setval($_/2, $_ & 1, $_*7 + 1) } 0..3;
ok (!$failed,  "setval returns set value?");

$failed=0;
map { ++$failed if $_ * 7 + 1 != $m->getval($_/2, $_ & 1) } 0..3;
ok (!$failed,  "setval/getval returns same value?");

# Now on to a bigger matrix, and do multiply/inverse/
# equality/getvals/setvals tests
my @mat8x8 = (
	      ["35","36","82","7A","D2","7D","75","31"],
	      ["0E","76","C3","B0","97","A8","47","14"],
	      ["F4","42","A2","7E","1C","4A","C6","99"],
	      ["3D","C6","1A","05","30","B6","42","0F"],
	      ["81","6E","F2","72","4E","BC","38","8D"],
	      ["5C","E5","5F","A5","E4","32","F8","44"],
	      ["89","28","94","3C","4F","EC","AA","D6"],
	      ["54","4B","29","B8","D5","A4","0B","2C"],
	     );
my @inv8x8 = (
	      ["3E","02","23","87","8C","C0","4C","79"],
	      ["5D","2B","2A","5B","7E","FE","25","36"],
	      ["F2","A9","B5","57","A2","F6","A2","7D"],
	      ["11","5E","E4","61","59","F4","B9","42"],
	      ["D5","16","B8","5B","30","85","1E","72"],
	      ["3B","F7","1B","5B","4C","55","35","04"],
	      ["58","95","73","33","8A","77","1C","F4"],
	      ["59","C0","7B","13","9F","8B","BE","E3"],
	     );
my @identity8x8 = (
		   [1,0,0,0,0,0,0,0],
		   [0,1,0,0,0,0,0,0],
		   [0,0,1,0,0,0,0,0],
		   [0,0,0,1,0,0,0,0],
		   [0,0,0,0,1,0,0,0],
		   [0,0,0,0,0,1,0,0],
		   [0,0,0,0,0,0,1,0],
		   [0,0,0,0,0,0,0,1],
		  );

# in-place conversion of hex strings to decimal values
map { map { $_ = hex } @$_ } @mat8x8;
map { map { $_ = hex } @$_ } @inv8x8;

my ($r,$c,$m8x8,$i8x8,$r8x8,$id8x8);
$m8x8 = Math::FastGF2::Matrix->new(rows=>8, cols =>8, width=>1);
$i8x8 = Math::FastGF2::Matrix->new(rows=>8, cols =>8, width=>1);
$id8x8= Math::FastGF2::Matrix->new(rows=>8, cols =>8, width=>1);

ok(ref($m8x8)  eq "Math::FastGF2::Matrix", "Create 8x8 matrix?");
ok(ref($i8x8)  eq "Math::FastGF2::Matrix", "Create 8x8 inverse matrix?");
ok(ref($id8x8) eq "Math::FastGF2::Matrix", "Create 8x8 result matrix?");

# Before we write any values to the matrices below, we can check to
# make sure that they were created with all values initially set to
# zero.
$failed=0;
for $r (0..7) {
  for $c (0..7) {
    ++$failed if $m8x8->getval($r,$c) or $i8x8->getval($r,$c) 
      or $id8x8->getval($r,$c);
    $m8x8 ->setval($r,$c,$mat8x8[$r][$c]);
    $i8x8 ->setval($r,$c,$inv8x8[$r][$c]);
    $id8x8->setval($r,$c,$identity8x8[$r][$c]);
  }
}

ok ($failed == 0, "8x8 matrix values all initialised to zero on init?");

# multiply without supplying a result matrix
$r8x8=$m8x8->multiply($i8x8);
ok(defined($r8x8),   "multiply method returns some value?");
ok(ref($r8x8) eq "Math::FastGF2::Matrix", "multiply returns correct class?");

# multiply with a supplied result matrix
my $r2=$m8x8->multiply($i8x8,$r8x8);
ok(defined($r2),  "multiply returns value with supplied result matrix?");
ok($r2 eq $r8x8,  "multiply returns supplied result matrix?");

# Checking equality #1
ok($r8x8->eq($r2),   "Equality test on same matrix?");
ok($r8x8->ne($m),    "Inequality test on differently-sized matrices?");
ok($r8x8->ne($m8x8), "Inequality test on differently-valued matrices?");

# is matrix x inverse = identity?
ok($r8x8->eq($id8x8), "Matrix x Inverse == Identity?");

# Also check new_identity method to see if it's equal to id8x8
my $test_id_8x8=Math::FastGF2::Matrix->new_identity(size => 8, width=> 1);
ok ($test_id_8x8->eq($id8x8), "new_identity eq hand-crafted matrix?");

# Test getvals in scalar context
my $row="3536827AD27D7531";	  # first row of m8x8
my $got= $m8x8->getvals(0,0,8); # get first 8 values
my $packed_row=pack "H16", $row;
ok (length $got == 8, "Scalar return from getvals of correct length?");
ok ($got eq $packed_row,  "Correct scalar return from getvals?");

# Test getvals in list context
my @row=$m8x8->getvals(0,0,8); # get first 8 values
ok (scalar(@row) == 8,  "number of returned items in getvals list?");
$failed=0;
map { ++$failed if $row[$_] != $m8x8->getval(0, $_) } 0..7;
ok (!$failed,  "Correct list return from getvals?");

# Test setvals... using ROWWISE
$m=Math::FastGF2::Matrix->new(rows => 2, cols => 2, width => 1,
			      org=> "rowwise"); # be explicit
my @vals=(65, 66, 67, 68);
my $str=$m->setvals(0,0,\@vals);
ok (length $str == 4,
    "setvals returns string of correct length, given list?");

my $str2=$m->getvals(0,0,4);

ok ($str eq $str2, "getvals ($str2) == setvals ($str)?");

ok ($m->getval(0,0) == $vals[0],
    "setvals (rowwise) sets (0,0) correctly?");
ok ($m->getval(0,1) == $vals[1],
    "setvals (rowwise) sets (0,1) correctly?");
ok ($m->getval(1,0) == $vals[2],
    "setvals (rowwise) sets (1,0) correctly?");
ok ($m->getval(1,1) == $vals[3],
    "setvals (rowwise) sets (1,1) correctly?");

# Test setvals... using COLWISE
$m=Math::FastGF2::Matrix->new(rows => 2, cols => 2, width => 1,
			      org=> "colwise"); # be explicit
ok (ref($m) eq $class,  "Created colwise matrix OK?");
$str=$m->setvals(0,0,\@vals);
ok (length $str == 4,
    "setvals returns string of correct length, given list?");

$str2=$m->getvals(0,0,4);

ok ($str eq $str2, "getvals ($str2) == setvals ($str)?");

ok ($m->getval(0,0) == $vals[0],
    "setvals ([], colwise) sets (0,0) correctly?");
ok ($m->getval(1,0) == $vals[1],
    "setvals ([], colwise) sets (1,0) correctly?");
ok ($m->getval(0,1) == $vals[2],
    "setvals ([], colwise) sets (0,1) correctly?");
ok ($m->getval(1,1) == $vals[3],
    "setvals ([], colwise) sets (1,1) correctly?");

# setvals with a string..
$m=Math::FastGF2::Matrix->new(rows => 2, cols => 2, width => 1,
			      org=> "colwise");
$str=$m->setvals(0,0,$str);
ok ($m->getval(0,0) == $vals[0],
    "setvals (\$\$, colwise) sets (0,0) correctly?");
ok ($m->getval(1,0) == $vals[1],
    "setvals (\$\$, colwise) sets (1,0) correctly?");
ok ($m->getval(0,1) == $vals[2],
    "setvals (\$\$, colwise) sets (0,1) correctly?");
ok ($m->getval(1,1) == $vals[3],
    "setvals (\$\$, colwise) sets (1,1) correctly?");

# Checking equality #2... rowwise vs colwise matrix
my @by_row=(65,66,67,68);
my @by_col=(65,67,66,68);
my $m_by_row=Math::FastGF2::Matrix->new(rows => 2, cols => 2, width => 1,
					 org=> "rowwise");
my $m_by_col=Math::FastGF2::Matrix->new(rows => 2, cols => 2, width => 1,
					 org=> "colwise");
$m_by_row->setvals(0,0,\@by_row);
$m_by_col->setvals(0,0,\@by_col);

ok ($m_by_row->eq($m_by_col),        "rowwise-to-colwise compare eq?");
$m_by_col->setval(1,1,69);
ok ($m_by_row->ne($m_by_col),        "rowwise-to-colwise compare ne?");

# Check rowcol_to_offset and offset_to_rowcol
my ($offset);

ok (((($r,$c)=$m_by_col->offset_to_rowcol(0)),
    $r==0 and $c==0),      "Offset 0 -> (0,0) (colwise)?");
ok (((($r,$c)=$m_by_col->offset_to_rowcol(1)),
     $r==1 and $c==0),      "Offset 1 -> (1,0) (colwise)?");
ok (((($r,$c)=$m_by_col->offset_to_rowcol(2)),
    $r==0 and $c==1),      "Offset 2 -> (0,1) (colwise)?");
ok (((($r,$c)=$m_by_col->offset_to_rowcol(3)),
     $r==1 and $c==1),      "Offset 3 -> (1,1) (colwise)?");

ok (((($r,$c)=$m_by_row->offset_to_rowcol(0)),
     $r==0 and $c==0),      "Offset 0 -> (0,0) (rowwise)?");
ok (((($r,$c)=$m_by_row->offset_to_rowcol(1)),
     $r==0 and $c==1),      "Offset 1 -> (0,1) (rowwise)?");
ok (((($r,$c)=$m_by_row->offset_to_rowcol(2)),
     $r==1 and $c==0),      "Offset 2 -> (1,0) (rowwise)?");
ok (((($r,$c)=$m_by_row->offset_to_rowcol(3)),
     $r==1 and $c==1),      "Offset 3 -> (1,1) (rowwise)?");

ok ($m_by_row->rowcol_to_offset(0,0) == 0,
                              "(0,0) -> Offset 0  (rowwise)?");
ok ($m_by_row->rowcol_to_offset(0,1) == 1,
                              "(0,1) -> Offset 1  (rowwise)?");
ok ($m_by_row->rowcol_to_offset(1,0) == 2,
                              "(1,0) -> Offset 2  (rowwise)?");
ok ($m_by_row->rowcol_to_offset(1,1) == 3,
                              "(1,1) -> Offset 3  (rowwise)?");

ok ($m_by_col->rowcol_to_offset(0,0) == 0,
                              "(0,0) -> Offset 0  (colwise)?");
ok ($m_by_col->rowcol_to_offset(0,1) == 2,
                              "(0,1) -> Offset 2  (colwise)?");
ok ($m_by_col->rowcol_to_offset(1,0) == 1,
                              "(1,0) -> Offset 1  (colwise)?");
ok ($m_by_col->rowcol_to_offset(1,1) == 3,
                              "(1,1) -> Offset 3  (colwise)?");

# Some tests using non-square matrices (similar to previous tests)
$m=Math::FastGF2::Matrix->new(rows => 3, cols => 7, width => 1,
			      org=> "colwise");
ok ($m->rowcol_to_offset(0,0) == 0,
                              "(0,0) -> Offset 0  (colwise)?");
ok ($m->rowcol_to_offset(0,6) == 18,
                              "(0,6) -> Offset 18  (colwise)?");
ok ($m->rowcol_to_offset(2,0) == 2,
                              "(2,0) -> Offset 2  (colwise)?");
ok ($m->rowcol_to_offset(2,6) == 20,
                              "(2,6) -> Offset 20  (colwise)?");

ok (((($r,$c)=$m->offset_to_rowcol(0)),
    $r==0 and $c==0),      "Offset 0 -> (0,0) (colwise)?");
ok (((($r,$c)=$m->offset_to_rowcol(2)),
     $r==2 and $c==0),     "Offset 2 -> (2,0) (colwise)?");
ok (((($r,$c)=$m->offset_to_rowcol(18)),
    $r==0 and $c==6),      "Offset 18 -> (0,6) (colwise)?");
ok (((($r,$c)=$m->offset_to_rowcol(20)),
     $r==2 and $c==6),     "Offset 20 -> (2,6) (colwise)?");

# Some more checks on (set|get)val(s?) for multi-byte words
my @wide_values=(0x4142,0x41424344);
# pack/unpack formats for unsigned short (16-bit) or unsigned long
# (32-bit)
my @native_pack=(undef,undef,"S*",undef,"L*");

for my $test_width (2,4) {

  my $wide_mat=Math::FastGF2::Matrix->new(rows => 2, cols => 2,
					  org => "rowwise",
					  width => $test_width);

  # need extra parentheses below because ',' binds tighter than 'and'
  ok ((defined ($wide_mat) and ref ($wide_mat) eq $class),
      "Create 2x2 rowwise matrix with width $test_width?");

  my $wide_value=shift @wide_values;

  #warn "wide value is ". (sprintf "%0*x", $test_width,
  #			  $wide_value) ."\n";

  # First, check that basic getval/setval work as advertised with
  # multi-byte words
  $wide_mat->setval(0,0,$wide_value);
  ok ($wide_mat->getval(0,0) == $wide_value,
      "getval/setval works with $test_width-byte words?");
  ok ($wide_mat->getval(0,1) == 0,
      "setval with $test_width-byte words overruns!");

  # zero matrix again in case error above causes spurious message for
  # next tests.
  $wide_mat->setval(0,0,0);
  $wide_mat->setval(0,1,0);
  $wide_mat->setval(1,0,0);
  $wide_mat->setval(1,1,0);

  # test that setvals doesn't write more or less than it should
  # list write method first
  $wide_mat->setvals(0,0,[$wide_value]);
  ok ($wide_mat->getval(0,0) == $wide_value,
      "Writing $test_width-byte word as string?");
  #warn "---> got back value " . (sprintf "%0*x", $test_width,
  #			$wide_mat->getval(0,0)) . "\n";
  ok ($wide_mat->getval(0,1) == 0,
      "Writing $test_width-byte word as string overruns!");

  # zero matrix again in case error above causes spurious message for
  # next tests.
  $wide_mat->setval(0,0,0);
  $wide_mat->setval(0,1,0);
  $wide_mat->setval(1,0,0);
  $wide_mat->setval(1,1,0);

  # setvals with string method. Use native byte order (other byte
  # order tests are handled later)
  $wide_mat->setvals(0,0,
		     pack $native_pack[$test_width], $wide_value);
  ok ($wide_mat->getval(0,0) == $wide_value,
      "Writing $test_width-byte word as list?");
  #warn "---> got back value " . (sprintf "%0*x", $test_width,
  #			$wide_mat->getval(0,0)) . "\n";
  ok ($wide_mat->getval(0,1) == 0,
      "Writing $test_width-byte word as list overruns!");
}

# Test byte order flags for getvals, setvals
#
# The module doesn't export any functions or data which can be used to
# detect the byte order on this machine. This is a design decision--
# the user shouldn't have to worry about such things and they
# shouldn't be made to query/save/check the byte order. The ability to
# set an explicit byte order for given data is all that's needed.
# However, for testing, it'll help if we can divine this machine's
# actual byte order so that we only have to write one set of tests
# (otherwise we'd have to keep two sets of tests, and be sure that
# they're always consistent with each other).

# The values of these variables don't matter, only that they're the
# reverse of each other. Array is indexed by width in bytes.
my @native_vals=(undef,undef,0x0201,undef,0x04030201);
my @alien_vals=(undef,undef,0x0102,undef,0x01020304);

# similar array to @native_pack. See manpage for pack
my @big_pack=(undef,undef,"n*",undef,"N*");
my @little_pack=(undef,undef,"v*",undef,"V*");

# Use the same numbering for storing our endian-ness as the module
# does: 1=little endian, 2=big endian
my $endian;			# our endian
my $oendian;			# the "other"/"alien" endian

for my $test_width (2,4) {


  # first create a a 1x1 test matrix
  my $emat=Math::FastGF2::Matrix->new(rows => 1, cols => 1,
				      org  => "rowwise",
				      width => $test_width);
  ok ((defined ($emat) and ref($emat) eq $class),
      "Create 1x1 matrix with width $test_width?");

  # The getval and setval routines both always deal only with
  # native-endian values ...
  $emat->setval(0,0,$native_vals[$test_width]);

  # ... but we need to test getvals, setvals. First make sure that
  # when we don't set a byte order that the value matches what was put
  # in. Need to check for return in both list and string context.
  my (@got_back,$got_back_string,$got_back_value);

  @got_back=$emat->getvals(0,0,1);
  ok ($got_back[0] == $native_vals[$test_width],
      "no byteorder flag, got back same list as put in?");

  $got_back_string=$emat->getvals(0,0,1);
  $got_back_value=unpack $native_pack[$test_width], $got_back_string;
  ok ($got_back_value == $native_vals[$test_width],
      "no byteorder flag, got back same string as put in?");

  # Since we haven't explictly tested setting byteorder to zero yet,
  # do it here
  @got_back=$emat->getvals(0,0,1,0);
  ok ($got_back[0] == $native_vals[$test_width],
      "byteorder 0, got back same list as put in?");

  $got_back_string=$emat->getvals(0,0,1,0);
  $got_back_value=unpack $native_pack[$test_width], $got_back_string;
  ok ($got_back_value == $native_vals[$test_width],
      "byteorder 0, got back same string as put in?");

  # Now we can check byte order settings...
  my ($string1,$string2,$val1,$val2);

  # evaluate getvals in list context
  ($val1)=$emat->getvals(0,0,1,1);
  ($val2)=$emat->getvals(0,0,1,2);

  ok ($val1 ne $val2,
      "different order for w=$test_width returns the same list!");

  $failed=0;
  if ($val1 eq $native_vals[$test_width]) {
    $endian=1;
    ++$failed unless $val2 eq $alien_vals[$test_width];
  } elsif ($val1 eq $alien_vals[$test_width]) {
    $endian=2;
    ++$failed unless $val2 eq $native_vals[$test_width];
  } else {
    ++$failed;
  }
  ok ($failed==0,
      "$test_width-byte order doesn't return either val or reverse!");

  $oendian= 3 - $endian;	# 3 - 1 = 2, 3 - 2 = 1

  # we can now check calling getvals in string string context since
  # now that we know our endian value, we can figure out how to
  # pack/unpack the strings.

  # Firstly, using S (native unsigned 16 bit) or L (native unsigned 32
  # bit) as our pack template should always work if we set the byte
  # order to our native endian value (as opposed to 0, which we've
  # already checked).
  $string1=pack $native_pack[$test_width], $native_vals[$test_width];
  ok ($emat->getvals(0,0,1,$endian) eq $string1,
      "$test_width-byte string doesn't unpack to same as native unpack!");
  # and the reverse ...
  $string2=pack $native_pack[$test_width], $alien_vals[$test_width];
  ok ($emat->getvals(0,0,1,$oendian) eq $string2,
      "$test_width-byte string doesn't unpack to reverse of alien unpack!");

  # The next check might be redundant, but we can test that explicitly
  # setting the order parameter to our endian-ness gives similar
  # results to calling pack/unpack with the same explicit template.
  $string1=pack $endian == 1 ? 
    $little_pack[$test_width] : $big_pack[$test_width],
      $native_vals[$test_width];
  ok ($emat->getvals(0,0,1,$endian) eq $string1,
      "$test_width-byte word doesn't unpack to same with our endian");

  # Finally, we've been doing all these checks for getvals. Rather
  # than rewriting all the tests to check setvals in a similar way, we
  # can rely on previous multi-byte tests that showed that values for
  # getvals/setvals matched and only check for correspondence or
  # reverse correspondence when we pass an explicit byte order flag.
  $emat->setvals(0,0,[$native_vals[$test_width]],$endian);
  ok ($emat->getval(0,0) == $native_vals[$test_width],
      "setvals on native $test_width-byte list equals getval?");
  $emat->setvals(0,0,[$native_vals[$test_width]],$oendian);
  ok ($emat->getval(0,0) == $alien_vals[$test_width],
      "setvals on alien $test_width-byte list reverses getval?");

  $emat->setvals(0,0,$string1,$endian);
  ok ($emat->getval(0,0) == $native_vals[$test_width],
      "setvals on native $test_width-byte string equals getval?");
  $emat->setvals(0,0,$string1,$oendian);
  ok ($emat->getval(0,0) == $alien_vals[$test_width],
      "setvals on alien $test_width-byte string reverses getval?");

}

# All previous getvals/setvals have only checked reading and writing a
# single value. Need to check reading/writing multiple values. I'll do
# that after testing basic 16 and 32-bit matrices...

# Some tests on 16-bit and 32-bit matrices

# After some basic tests creating, comparing and multiplying identity
# matrices I'll move on directly to more high-level testing involving
# matrices defining a threshold scheme. Some k from n rows of the
# matrix should be invertible, so I'll make the submatrix, invert it
# and then multiply it by the original matrix and test whether the
# result is an identity matrix.

# Create identity matrices using two methods and compare the
# values. We already have an @identity8x8 ist of values, so we can
# generate a matrix from those, or we can use new_identity

$id8x8_16= Math::FastGF2::Matrix->new(rows=>8, cols =>8, width=>2);
$id8x8_32= Math::FastGF2::Matrix->new(rows=>8, cols =>8, width=>4);

ok((defined($id8x8_16) and ref($id8x8_16) eq $class),
   "Create 8x8 16-bit matrix?");
ok((defined($id8x8_32) and ref($id8x8_32) eq $class),
   "Create 8x8 32-bit matrix?");

# Before we write any values to the matrices below, we can check to
# make sure that they were created with all values initially set to
# zero.
$failed=0;
for $r (0..7) {
  for $c (0..7) {
    ++$failed if $id8x8_16->getval($r,$c) or $id8x8_32->getval($r,$c);
    $id8x8_16->setval($r,$c,$identity8x8[$r][$c]);
    $id8x8_32->setval($r,$c,$identity8x8[$r][$c]);
  }
}

# Now create matrices using new_identity and compare them with our
# manually-populated matrices
my $ni8x8_16=Math::FastGF2::Matrix->new_identity(size => 8, width=> 2);
my $ni8x8_32=Math::FastGF2::Matrix->new_identity(size => 8, width=> 4);

ok((defined($ni8x8_16) and ref($ni8x8_16) eq $class),
   "new_identity size=>8, width=>2?");
ok((defined($ni8x8_32) and ref($ni8x8_32) eq $class),
   "new_identity size=>8, width=>4?");

ok($ni8x8_16->eq($id8x8_16),
   "16-bit new_identity eq hand-crafted matrix?");
ok($ni8x8_32->eq($id8x8_32),
   "32-bit new_identity eq hand-crafted matrix?");

# Before moving on to inverting parts of our threshold scheme
# matrices, just make sure that an identity matrix squared equals
# itself. This will give us minimal confidence that multiplication
# works.
ok($ni8x8_16->eq($ni8x8_16->multiply($ni8x8_16)),
   "16-bit identity squared eq itself?");
ok($ni8x8_32->eq($ni8x8_32->multiply($ni8x8_32)),
   "32-bit identity squared eq itself?");

# Do the same for inverses
ok($ni8x8_16->eq($ni8x8_16->invert),
   "16-bit inverse identity eq itself?");
ok($ni8x8_32->eq($ni8x8_32->invert),
   "32-bit inverse identity eq itself?");

# 16-bit threshold matrix test

# The following matrix defines a threshold scheme where any 4 rows of
# the matrix are linearly independent (ie, a (4,5) scheme).
my @tr_4_from_5_u16=
  (
   [ "0340", "701f", "2b03", "d145" ],
   [ "d918", "4a93", "3d03", "bcb5" ],
   [ "c0ae", "95fe", "57b2", "fdc9" ],
   [ "dd0d", "0684", "a066", "7c38" ],
   [ "7a06", "0d0f", "0d57", "1045" ],
  );

# in-place conversion of hex strings to decimal values
map { map { $_ = hex } @$_ } @tr_4_from_5_u16;

my @skipped_rows=(4,0,1,3,2);	# useful for error message
my $id_4x4=Math::FastGF2::Matrix->new_identity(size=>4, width=> 2);
my ($new_4x4,$inv_4x4);
for my $rows_16 ( [0,1,2,3], [4,2,1,3], [4,3,2,0],
		  [2,0,1,4], [3,0,4,1]) {
  my $skipped=shift @skipped_rows;

  # we can probably assume these work, given previous similar tests
  $new_4x4=Math::FastGF2::Matrix->new(rows => 4, cols => 4, width => 2);

  # copy values from @tr_4_from_5_u16 array
  my $dest_row=0;
  foreach my $from_row (@$rows_16) {
    foreach $c (0..3) {
      $new_4x4->setval($dest_row,$c,$tr_4_from_5_u16[$from_row][$c]);
    }
    ++$dest_row;
  }

  $inv_4x4=$new_4x4->invert;
  ok((defined($inv_4x4) and ref($inv_4x4) eq $class),
     "Failed to invert 16-bit threshold skipping row $skipped!");

  # Next step will fail as well if we couldn't invert ...
  my $product=$new_4x4->multiply($inv_4x4);
  ok ($id_4x4->eq($product),
      "matrix x inverse for 16-bit threshold skipping row $skipped?");

  # Might as well also check that inverse of inverse is original matrix
  ok ($new_4x4->eq($inv_4x4->invert),
      "inverse of inverse eq self for 16-bit, skipping row $skipped?");
}

# 32-bit threshold matrix test

# The following matrix defines a threshold scheme where any 4 rows of
# the matrix are linearly independent (ie, a (4,5) scheme).
my @tr_4_from_5_u32=
  (
   [ "7dd91d81", "a9b559a6", "fd2f668c", "eab462da" ],
   [ "f77ad141", "d778e64f", "6f0cb2c1", "23b49e0a" ],
   [ "64a7d945", "9947d2ad", "3a55ea06", "6d85f6b9" ],
   [ "66b8caf2", "b9bbaa88", "1836f5fd", "211a93d3" ],
   [ "7cbd8de1", "c838c711", "c3b13916", "ce0c5cc9" ],
  );

# in-place conversion of hex strings to decimal values
map { map { $_ = hex } @$_ } @tr_4_from_5_u32;

@skipped_rows=(4,0,1,3,2);	# useful for error message
$id_4x4=Math::FastGF2::Matrix->new_identity(size=>4, width=> 4);
for my $rows_32 ( [0,1,2,3], [4,2,1,3], [4,3,2,0],
		  [2,0,1,4], [3,0,4,1]) {
  my $skipped=shift @skipped_rows;

  # we can probably assume these work, given previous similar tests
  $new_4x4=Math::FastGF2::Matrix->new(rows => 4, cols => 4, width => 4);

  # copy values from @tr_4_from_5_u32 array
  my $dest_row=0;
  foreach my $from_row (@$rows_32) {
    foreach $c (0..3) {
      $new_4x4->setval($dest_row,$c,$tr_4_from_5_u32[$from_row][$c]);
    }
    ++$dest_row;
  }

  $inv_4x4=$new_4x4->invert;
  ok((defined($inv_4x4) and ref($inv_4x4) eq $class),
     "Failed to invert 32-bit threshold skipping row $skipped!");

  # Next step will fail as well if we couldn't invert ...
  my $product=$new_4x4->multiply($inv_4x4);
  ok ($id_4x4->eq($product),
      "matrix x inverse for 32-bit threshold skipping row $skipped?");

  # Might as well also check that inverse of inverse is original matrix
  ok ($new_4x4->eq($inv_4x4->invert),
      "inverse of inverse eq self for 32-bit, skipping row $skipped?");
}

# Back to testing different byte order flags for getvals, setvals
my $wide_16=Math::FastGF2::Matrix->new(rows => 1, cols => 3, width=>2);
my $wide_32=Math::FastGF2::Matrix->new(rows => 1, cols => 3, width=>4);

my $string_16="ABCDEF";		# 6 letters from 0x41 up
my $string_32="ABCDEFGHIJKL";	# 12 letters

$wide_16->setvals(0,0,$string_16,1); # little-endian
ok( $wide_16->getval(0,0) == 0x4241,
     "16-bit setval as little endian... value 1?");
ok( $wide_16->getval(0,1) == 0x4443,
     "16-bit setval as little endian... value 2?");
ok( $wide_16->getval(0,2) == 0x4645,
     "16-bit setval as little endian... value 3?");

# quicker than zeroing right now!
$wide_16=Math::FastGF2::Matrix->new(rows => 1, cols => 3, width=>2);

$wide_16->setvals(0,0,$string_16,2); # big-endian
ok( $wide_16->getval(0,0) == 0x4142,
     "16-bit setval as big endian... value 1?");
ok( $wide_16->getval(0,1) == 0x4344,
     "16-bit setval as big endian... value 2?");
ok( $wide_16->getval(0,2) == 0x4546,
     "16-bit setval as big endian... value 3?");

# Actually, I couldn't be bothered checking 32-bit values... the same
# code is used for both 16 and 32-bit values and there is really no
# way for one to fail and not the other. This holds for strings
# anyway.

# put in some values as a list in little- and big-endian
# format. Compare output string.
$wide_16->setvals(0,0,[0x4241,0x4443,0x4645],1);
ok ($wide_16->getvals(0,0,3) eq "ABCDEF",
    "16-bit setval putting little-endian list, getting native string?");
$wide_16->setvals(0,0,[0x4241,0x4443,0x4645],2);
ok ($wide_16->getvals(0,0,3) eq "BADCFE",
    "16-bit setval putting big-endian list, getting native string?");

# Check that getvals works with big and little endian
$wide_16->setvals(0,0,[0x4241,0x4443,0x4645],0);
ok ($wide_16->getvals(0,0,3,1) eq "ABCDEF",
    "16-bit setval putting native list, getting little-endian string?");
ok ($wide_16->getvals(0,0,3,2) eq "BADCFE",
    "16-bit setval putting native list, getting big-endian string?");

# Test copy modes
my $copy;

# no arguments == copy entire matrix
$copy=$m8x8->copy;
ok ($copy->eq($m8x8), "full matrix copy?");

# submatrix copy with complete matrix
$copy=undef; $copy=$m8x8->copy(submatrix=> [0,0,7,7]);
ok ($copy->eq($m8x8), "full submatrix matrix copy?");

# copy rows with all rows
$copy=undef; $copy=$m8x8->copy(rows=> [0..7]);
ok ($copy->eq($m8x8), "copy matrix with all rows?");

# copy columns with all cols
$copy=undef; $copy=$m8x8->copy(cols=> [0..7]);
ok ($copy->eq($m8x8), "copy matrix with all columns?");

# copy rows,columns with all rows,cols
$copy=undef; $copy=$m8x8->copy(rows=> [0..7],cols=> [0..7]);
ok ($copy->eq($m8x8), "copy matrix with all rows, columns?");

# Test wrapper functions for doing the above

# submatrix on complete matrix
$copy=undef; $copy=$m8x8->submatrix(0,0,7,7);
ok ($copy->eq($m8x8), "submatrix method copy?");

# copy_rows with all rows
$copy=undef; $copy=$m8x8->copy_rows(0..7);
ok ($copy->eq($m8x8), "copy_rows with all rows?");

# copy_cols with all columns
$copy=undef; $copy=$m8x8->copy_cols(0..7);
ok ($copy->eq($m8x8), "copy_cols with all columns?");

# check some other cases on smaller parts of the matrices. Will use
# one of the 4x4 matrices to cut down on typing. Note that creating
# new matrices with a bunch of values is a bit long-winded at the
# moment. Also, note that I'm using a 16-bit matrix this time, which
# helps cover some more possible failures. If something does fail
# here, though, it might be because of a problem in the copy routine
# or something to do with the width of the fields. Beware...

# create a 5x4 matrix from @tr_4_from_5_u16 ("map" flattens the list)
my $mat_5x4=Math::FastGF2::Matrix->new(rows=> 5, cols => 4, width=> 2);
$mat_5x4->setvals(0,0, [map { @{ $tr_4_from_5_u16[$_] } } (0..4)] );

# full copy
$copy=undef; $copy=$mat_5x4->copy();
ok ($copy->eq($mat_5x4),
    "full copy from 5x4 matrix?");

# submatrix copy
$copy=undef; $copy=$mat_5x4->copy(submatrix=> [1,1,3,2]);
my $submatrix=Math::FastGF2::Matrix->new(rows=> 3, cols => 2, width=> 2);
$submatrix->setvals(0,0,[0x4a93, 0x3d03,
			 0x95fe, 0x57b2,
			 0x0684, 0xa066]);
ok ($copy->eq($submatrix),
    "copy submatrix [1,1,3,2] from 5x4 matrix?");

# copy rows (reuse same $submatrix variable name)
$copy=undef; $submatrix=undef;
$copy=$mat_5x4->copy(rows => [4,2,0]);
$submatrix=Math::FastGF2::Matrix->new(rows=> 3, cols => 4, width=> 2);
$submatrix->setvals(0,0,[0x7a06, 0x0d0f, 0x0d57, 0x1045,
			 0xc0ae, 0x95fe, 0x57b2, 0xfdc9,
			 0x0340, 0x701f, 0x2b03, 0xd145, ]);
ok ($copy->eq($submatrix),
    "copy rows [4,2,0] from 5x4 matrix?");

# copy cols
$copy=undef; $submatrix=undef;
$copy=$mat_5x4->copy(cols => [3,1]);
$submatrix=Math::FastGF2::Matrix->new(rows=> 5, cols => 2, width=> 2);
$submatrix->setvals(0,0,[ 0xd145, 0x701f,
			  0xbcb5, 0x4a93,
			  0xfdc9, 0x95fe,
			  0x7c38, 0x0684,
			  0x1045, 0x0d0f, ]);
ok ($copy->eq($submatrix),
    "copy rows [3,1] from 5x4 matrix?");

# copy rows and cols
$copy=undef; $submatrix=undef;
$copy=$mat_5x4->copy(rows => [0,2,4], cols => [3,1]);
$submatrix=Math::FastGF2::Matrix->new(rows=> 3, cols => 2, width=> 2);
$submatrix->setvals(0,0,[ 0xd145, 0x701f,
			  0xfdc9, 0x95fe,
			  0x1045, 0x0d0f, ]);
ok ($copy->eq($submatrix),
    "copy rows [3,1], cols [0,2,4] from 5x4 matrix?");

# Test new zero method. It works in-place on the matrix, so I'll make a
# copy of an existing matrix before zeroing it.
$copy=$m8x8->copy;
$copy->zero;
ok ($copy->eq(Math::FastGF2::Matrix->new(rows=>8,cols=>8,width=>1)),
   "zero works as expected?");

# Test flip/transpose/reorganise matrix functions
#
# Working on same 5x4 matrix as above. First manually create a 4x5
# transposed version of it.
my $tr_5x4=Math::FastGF2::Matrix->new(rows=> 4, cols => 5, width=> 2);
for $r (0..4) {
  for $c (0..3) {
    $tr_5x4->setval($c,$r,$mat_5x4->getval($r,$c));
  }
}

# Test the wrapper functions first. Using eq here just examines
# values, dimensions and width, as it doesn't care about the
# underlying matrix organisation.
$copy=$mat_5x4->transpose;
ok ($copy->eq($tr_5x4), "transpose of 5x4 matrix?");
ok ($copy ne $mat_5x4,  "transpose returns a new matrix?");

$copy=$mat_5x4->reorganise;
ok ($copy->eq($mat_5x4),
    "reorganised matrix eq previous organisation?");
ok ($copy ne $mat_5x4, "reorganise returns a new matrix?");
ok ($mat_5x4->ORG ne $copy->ORG,
    "reorganise actually changes \$matrix->ORG?");

# The four ways of calling flip combine transpose values (0,1) x
# organisation values ("rowwise", "colwise"). Report organisation
# values as "same", "different" in error messages.

$copy=$mat_5x4->flip(transpose=>0, org => "rowwise");
ok ($copy ne $mat_5x4,
    "transpose: no, org: same returns new matrix?");
ok ($copy->eq($mat_5x4),
    "transpose: no, org: same equals original matrix?");
ok ($copy->ORG eq $mat_5x4->ORG, 
    "transpose: no, org: same returns same ORG?");

$copy=$mat_5x4->flip(transpose=>1, org => "rowwise");
ok ($copy ne $mat_5x4,
    "transpose: yes, org: same returns new matrix?");
ok ($copy->eq($tr_5x4),
    "transpose: yes, org: same equals transpose matrix?");
ok ($copy->ORG eq $mat_5x4->ORG,
    "transpose: yes, org: same returns same ORG?");

$copy=$mat_5x4->flip(transpose=>0, org => "colwise");
ok ($copy ne $mat_5x4,
    "transpose: no, org: different returns new matrix?");
ok ($copy->eq($mat_5x4),
    "transpose: no, org: different equals original matrix?");
ok ($copy->ORG ne $mat_5x4->ORG, 
    "transpose: no, org: different returns different ORG?");

$copy=$mat_5x4->flip(transpose=>1, org => "colwise");
ok ($copy ne $mat_5x4,
    "transpose: yes, org: different returns new matrix?");
ok ($copy->eq($tr_5x4),
    "transpose: yes, org: different equals transpose matrix?");
ok ($copy->ORG ne $mat_5x4->ORG,
    "transpose: yes, org: different returns different ORG?");

