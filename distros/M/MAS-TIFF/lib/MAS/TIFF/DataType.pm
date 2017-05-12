use strict;
use warnings;

package MAS::TIFF::DataType;

use MAS::TIFF::Rational;

my %types = ( );

my $make_type = sub {
  my ($id, $name, $size, $unpack_i, $unpack_m, $post) = @_;
  
  $types{$id} = bless {
    ID => $id,
    NAME => $name,
    SIZE => $size,
    UNPACK_I => $unpack_i,
    UNPACK_M => $unpack_m,
    POST => $post,
  }, 'MAS::TIFF::DataType';
};

# http://www.fileformat.info/format/tiff/egff.htm
&$make_type(1, 'BYTE',       1, 'C%d', 'C%d');
&$make_type(2, 'ASCII',      1, 'Z%d', 'Z%d');
&$make_type(3, 'SHORT',      2, 'S<%d', 'S>%d');
&$make_type(4, 'LONG',       4, 'L<%d', 'L>%d');
&$make_type(5, 'RATIONAL',   8, '(L<2)%d', '(L>2)%d', sub {
  my $in = shift;
  my @longs = @{$in};
  
  my @out = ( );
  while (@longs >= 2) {
    my $n = shift @longs;
    my $d = shift @longs;
    push @out, MAS::TIFF::Rational->new($n, $d);
  }
  return [ @out ];
} );

# TIFF 6.0
&$make_type(6, 'SBYTE',      1, 'c%d', 'c%d');
&$make_type(7, 'UNDEFINE',   1, 'C%d', 'C%d'); # ???
&$make_type(8, 'SSHORT',     2, 's<%d', 's>%d');
&$make_type(9, 'SLONG',      4, 'l<%d', 'l>%d');
&$make_type(10, 'SRATIONAL', 8, '(l<2)%d', '(l>2)%d');
#&$make_type(11, 'FLOAT',     8, ...);
#&$make_type(12, 'DOUBLE',    8, ...);

use constant {
  BYTE => $types{1},
  ASCII => $types{2},
  SHORT => $types{3},
  LONG => $types{4},
  RATIONAL => $types{5},
};

sub read_from_io {
  my $class = shift;
  my $io = shift;
  
  my $id = $io->read_word;
  
  my $type = $types{$id};
  die "Unrecognized data type: $id" unless defined $type;
  
  return $type;
}

sub id { return shift->{ID} }
sub name { return shift->{NAME} }
sub size { return shift->{SIZE} }

sub post_process { 
  my $self = shift;
  my $values = shift;
  
  return $values unless defined $self->{POST};
  
  return &{$self->{POST}}($values);
}

sub template {
  my $self = shift;
  my ($size, $byte_order) = @_;

  my $template = $byte_order eq 'I' ? $self->{UNPACK_I} : $self->{UNPACK_M};
  
  return sprintf($template, $size);
}


1;
