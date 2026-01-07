package Google::RestApi::SheetsApi4::Types;

# custom type constrants. see Type::Library.
# NOTE: can't use Google::RestApi::Setup here because that module imports this one.

# this handles the complex coercions of different formats for specifying ranges
# using type::library to handle it. having different formats for ranges is probably
# more comlicated that it's worth, it grew in complexity organically, but it works
# and we have it now.

use strict;
use warnings;

our $VERSION = '1.1.0';

use feature qw( state );

use Type::Params qw( compile );
use Types::Standard qw( Undef Defined Value Str StrMatch Int ArrayRef HashRef Tuple Dict HasMethods );
use Types::Common::Numeric qw( PositiveInt PositiveOrZeroInt );

use Google::RestApi::Types qw( :all );

my @types = qw(
  DimCol DimRow DimColRow DimAll
  RangeCol RangeRow RangeCell RangeAny RangeAll
  RangeNamed RangeIndex
  HasRange
);

use Type::Library -base, -declare => @types;

use Exporter;
our %EXPORT_TAGS = (all => \@types);

my $meta = __PACKAGE__->meta;


my $dim_col = $meta->add_type(
  name    => 'DimCol',
  parent  => StrMatch[qr/^(col)/i],
  message => sub { "Must be spreadsheet dimension 'col'" },
);

my $dim_row = $meta->add_type(
  name    => 'DimRow',
  parent  => StrMatch[qr/^(row)/i],
  message => sub { "Must be spreadsheet dimension 'row'" },
);

my $dim_all = $meta->add_type(
  name    => 'DimAll',
  parent  => StrMatch[qr/^(all)/i],
  message => sub { "Must be spreadsheet dimension 'all'" },
);

$meta->add_type(
  name    => 'DimColRow',
  parent  => $dim_col | $dim_row,
  message => sub { "Must be a spreadsheet dimension (col or row)" },
);

$_->coercion->add_type_coercions(
  Str, sub { lc(substr($_, 0, 3)); },
) for ($dim_col, $dim_row, $dim_all);




my $col_str_int = StrMatch[qr/^([A-Z]+|\d+)$/];

my $col = $meta->add_type(
  name    => 'RangeCol',
  parent  => StrMatch[qr/^([A-Z]+)\d*:\1\d*$/],
  message => sub { "Must be a spreadsheet range column Ax:Ay" },
);
$col->coercion->add_type_coercions(
  StrMatch[qr/^([A-Z]+)$/], sub { "$_:$_"; },  # 'A' => 'A:A', 1 should be a row.
  Dict[col => $col_str_int], sub { $_ = _col_i2a($_->{col}); "$_:$_"; },
  Tuple[Dict[col => $col_str_int]], sub { $_ = _col_i2a($_->[0]->{col}); "$_:$_"; },
  Tuple[$col_str_int], sub { $_ = _col_i2a($_->[0]); "$_:$_"; },
  Tuple[$col_str_int, False], sub { $_ = _col_i2a($_->[0]); "$_:$_"; },
  Tuple[Tuple[$col_str_int]], sub { $_ = _col_i2a($_->[0]->[0]); "$_:$_"; },
  Tuple[Tuple[$col_str_int, False]], sub { $_ = _col_i2a($_->[0]->[0]); "$_:$_"; },
);
sub _col_i2a {
  my $col = shift;
  return '' if !defined $col || $col eq '';
  return $col if $col =~ qr/\D/;
  my $l = int($col / 27);
  my $r = $col - $l * 26;
  return $l > 0 ? (pack 'CC', $l+64, $r+64) : (pack 'C', $r+64);
}


my $row = $meta->add_type(
  name    => 'RangeRow',
  parent  => StrMatch[qr/^[A-Z]*(\d+):[A-Z]*\1$/],
  message => sub { "Must be a spreadsheet range row x1:y1" },
);
$row->coercion->add_type_coercions(
  PositiveInt, sub { "$_:$_"; },   # 1 => 1:1
  Dict[row => PositiveInt], sub { "$_->{row}:$_->{row}"; },
  Tuple[Dict[row => PositiveInt]], sub { "$_->[0]->{row}:$_->[0]->{row}"; },
  Tuple[False, PositiveInt] => sub { "$_->[1]:$_->[1]"; },
  Tuple[Tuple[False, PositiveInt]] => sub { "$_->[0]->[1]:$_->[0]->[1]"; },
);



my $cell_str_int = StrMatch[qr/^[A-Z]+\d+$/];

my $cell = $meta->add_type(
  name    => 'RangeCell',
  parent  => $cell_str_int,
  message => sub { "Must be a spreadsheet range cell A1" },
);
$cell->coercion->add_type_coercions(
  StrMatch[qr/^([A-Z]+\d+):\1$/], sub { (split(':'))[0]; },  # 'A1:A1' should be a cell.
  Dict[col => $col_str_int, row => PositiveInt], sub { _col_i2a($_->{col}) . $_->{row}; },
  Tuple[Dict[col => $col_str_int, row => PositiveInt]], sub { _col_i2a($_->[0]->{col}) . $_->[0]->{row}; },
  Tuple[$col_str_int, PositiveInt], sub { _col_i2a($_->[0]) . $_->[1]; },
  Tuple[Tuple[$col_str_int, PositiveInt]], sub { _col_i2a($_->[0]->[0]) . $_->[0]->[1]; },
);


my $range_any = $meta->add_type(
  name    => 'RangeAny',
  parent  => StrMatch[qr/^[A-Z]*\d*(:[A-Z]*\d*)?$/],
  message => sub { "Must be a spreadsheet range A1:B2" },
);
# drive the coercions on each type by running them through compile/check.
$range_any->coercion->add_type_coercions(
  Tuple[Defined, Defined],
    sub {
      state $check = compile(Tuple[$col | $row | $cell, $col | $row | $cell]);
      my ($range) = $check->($_);

      # these look odd but if 'A' is passed as one of the tuples, it will be
      # translated to 'A:A' for that one tuple by col coercions above,
      # so have to squash it here. same goes for row.
      ($range->[0]) = (split(':', $range->[0]))[0];
      ($range->[1]) = (split(':', $range->[1]))[0];
      
      # if this is 'A1:A1' squash it to 'A1'.
      return $range->[0] if
        $range->[0] =~ qr/^[A-Z]+\d+/ &&
        $range->[1] =~ qr/^[A-Z]+\d+/ &&
        $range->[0] eq $range->[1];

      return "$range->[0]:$range->[1]";
    },
  Tuple[Defined],
    sub {
      state $check = compile(Tuple[$col | $row | $cell]);
      my ($range) = $check->($_);
      return $range;
    },
  Value,
    sub {
      state $check = compile($col | $row | $cell);
      my ($range) = $check->($_);
      return $range;
    },
  );



$meta->add_type(
  name    => 'RangeAll',
  parent  => $col | $row | $cell | $range_any,
  message => sub { "Must be a spreadsheet range, col, row, or cell" },
);



# https://support.google.com/docs/answer/63175?co=GENIE.Platform%3DDesktop&hl=en
$meta->add_type(
  name    => 'RangeNamed',
  parent  => StrMatch[qr/^[A-Za-z_][A-Za-z0-9_]+/],
  message => sub { "Must be a spreadsheet named range" },
);

$meta->add_type(
  name    => 'RangeIndex',
  parent  => PositiveOrZeroInt,
  message => sub { "Must be a spreadsheet range index (0-based)" },
);


$meta->add_type(
  name    => 'HasRange',
  parent  => HasMethods[qw(range)],
  message => sub { "Must be a range object"; }
);

__PACKAGE__->make_immutable;

1;
