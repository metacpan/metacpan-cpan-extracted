package Math::MatrixLUP;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

use overload
  '""'  => \&stringify,
  'neg' => \&neg,
  'abs' => \&abs,
  '@{}' => sub { $_[0]->{matrix} },

  '==' => \&eq,
  '!=' => \&ne,

  '<'  => \&lt,
  '>'  => \&gt,
  '<=' => \&le,
  '>=' => \&ge,

  '<=>' => sub { $_[2] ? -(&cmp($_[0], $_[1]) // return undef) : &cmp($_[0], $_[1]) },

  'eq' => sub { "$_[0]" eq "$_[1]" },
  'ne' => sub { "$_[0]" ne "$_[1]" },

  'cmp' => sub { $_[2] ? ("$_[1]" cmp $_[0]->stringify) : ($_[0]->stringify cmp "$_[1]") },

  '&' => \&and,
  '|' => \&or,
  '^' => \&xor,
  '~' => \&transpose,

  '>>' => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &rsft },
  '<<' => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &lsft },

  '+' => \&add,
  '*' => \&mul,

  '/' => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &div },
  '-' => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &sub },

  '**' => sub { @_ = $_[2] ? @_[1, 0] : @_[0, 1]; goto &pow },
  '%'  => sub { @_ = $_[2] ? @_[1, 0] : @_[0, 1]; goto &mod },
  ;

sub _croak {
    my ($msg) = @_;
    require Carp;
    Carp::croak($msg);
}

sub new {
    my ($class, $matrix) = @_;

    my ($rows, $cols);

    if (ref($matrix) eq 'ARRAY' and !@$matrix) {
        $rows = -1;
        $cols = -1;
    }
    else {
        (ref($matrix) eq 'ARRAY' and ref($matrix->[0]) eq 'ARRAY')
          or _croak("Math::MatrixLUP->new(): invalid argument (expected a 2D array)");
    }

    $rows //= $#{$matrix};
    $cols //= $#{$matrix->[0]};

    bless {
           matrix    => $matrix,
           rows      => $rows,
           cols      => $cols,
           is_square => ($rows == $cols),
          }, $class;
}

sub build {
    my (undef, $rows, $cols, $callback) = @_;

    if (!defined($callback)) {
        $callback = $cols;
        $cols     = $rows;
    }

    $rows -= 1;
    $cols -= 1;

    __PACKAGE__->new(
        [
         map {
             my $i = $_;
             [map { $callback->($i, $_) } 0 .. $cols];
           } 0 .. $rows
        ]
    );
}

sub identity {
    my $n = $_[-1];

    if ($n <= 0) {
        return __PACKAGE__->new([]);
    }

    __PACKAGE__->new([map { [(0) x ($_ - 1), 1, (0) x ($n - $_)] } 1 .. $n]);
}

*I = \&identity;

sub zero {
    my (undef, $row_count, $col_count) = @_;

    $col_count //= $row_count;

    if ($row_count <= 0) {
        return __PACKAGE__->new([]);
    }

    __PACKAGE__->new([map { [(0) x $col_count] } 1 .. $row_count]);
}

sub _column_vector {
    my (undef, $vector) = @_;

    ref($vector) eq 'ARRAY'
      or _croak("column(): the vector must be an ARRAY ref");

    __PACKAGE__->new([map { [$_] } @$vector]);
}

sub column {
    my ($self, $n) = @_;

    ref($self) || goto &_column_vector;

    [map { $_->[$n] } @$self];
}

sub _row_vector {
    my (undef, $vector) = @_;

    ref($vector) eq 'ARRAY'
      or _croak("row(): the vector must be an ARRAY ref");

    __PACKAGE__->new([$vector]);
}

sub row {
    my ($self, $n) = @_;

    ref($self) || goto &_row_vector;

    [@{$self->[$n]}];
}

sub scalar {
    my (undef, $n, $value) = @_;
    __PACKAGE__->new([map { [(0) x ($_ - 1), $value, (0) x ($n - $_)] } 1 .. $n]);
}

sub _new_diagonal {
    my (undef, $vector) = @_;

    ref($vector) eq 'ARRAY'
      or _croak("diagonal(): the vector must be an ARRAY ref");

    my @diag = @$vector;
    my $n    = scalar(@diag);

    __PACKAGE__->new([map { [(0) x ($_ - 1), shift(@diag), (0) x ($n - $_)] } 1 .. $n]);
}

sub _new_anti_diagonal {
    my (undef, $vector) = @_;

    ref($vector) eq 'ARRAY'
      or _croak("anti_diagonal(): the vector must be an ARRAY ref");

    my @diag = @$vector;
    my $n    = scalar(@diag);

    __PACKAGE__->new([map { [(0) x ($n - $_), shift(@diag), (0) x ($_ - 1)] } 1 .. $n]);
}

sub from_rows {
    my (undef, @rows) = @_;
    __PACKAGE__->new(\@rows);
}

sub from_columns {
    my (undef, @columns) = @_;
    __PACKAGE__->new(\@columns)->transpose;
}

sub diagonal {
    my ($self) = @_;

    ref($self) || goto &_new_diagonal;

    $self->{is_square} or _croak('diagonal(): not a square matrix');

    my $A = $self->{matrix};
    [map { $A->[$_][$_] } 0 .. $self->{rows}];
}

sub anti_diagonal {
    my ($self) = @_;

    ref($self) || goto &_new_anti_diagonal;

    $self->{is_square} or _croak('anti_diagonal(): not a square matrix');

    my $A    = $self->{matrix};
    my $cols = $self->{cols};

    [map { $A->[$_][$cols - $_] } 0 .. $self->{rows}];
}

sub set_column {
    my ($self, $i, $vector) = @_;

    ref($vector) eq 'ARRAY'
      or _croak("set_column(): the vector must be an ARRAY ref");

    $#{$vector} == $self->{rows}
      or _croak("set_column(): length(vector) != length(matrix)");

    my $clone = $self->clone;
    my $A     = $clone->{matrix};

    foreach my $j (0 .. $#{$vector}) {
        $A->[$j][$i] = $vector->[$j];
    }

    $clone;
}

sub set_row {
    my ($self, $i, $vector) = @_;

    ref($vector) eq 'ARRAY'
      or _croak("set_row(): the vector must be an ARRAY ref");

    $#{$vector} == $self->{cols}
      or _croak("set_row(): length(vector) != length(matrix)");

    my $clone = $self->clone;
    $clone->{matrix}[$i] = [@{$vector}];
    $clone;
}

sub as_array {
    my ($self) = @_;
    $self->{matrix};
}

sub size {
    my ($self) = @_;
    ($self->{rows} + 1, $self->{cols} + 1);
}

sub rows {
    my ($self) = @_;
    @{$self->{matrix}};
}

sub columns {
    my ($self) = @_;
    $self->transpose->rows;
}

sub eq {
    my ($m1, $m2) = @_;

    ref($m1) eq ref($m2) or return 0;

    $m1->{rows} == $m2->{rows} or return 0;
    $m1->{cols} == $m2->{cols} or return 0;

    my $A = $m1->{matrix};
    my $B = $m2->{matrix};

    my $rows = $m1->{rows};
    my $cols = $m2->{cols};

    foreach my $i (0 .. $rows) {

        my $Ai = $A->[$i];
        my $Bi = $B->[$i];

        foreach my $j (0 .. $cols) {
            $Ai->[$j] == $Bi->[$j] or return 0;
        }
    }

    return 1;
}

sub cmp {
    my ($m1, $m2) = @_;

    ref($m1) eq ref($m2)
      or _croak("cmp(): can't compare different objects");

    my $a1 = $m1->{matrix};
    my $a2 = $m2->{matrix};

    my $r1 = $m1->{rows};
    my $r2 = $m2->{rows};

    my $c1 = $m1->{cols};
    my $c2 = $m2->{cols};

    my $min_rows = $r1 < $r2 ? $r1 : $r2;
    my $min_cols = $c1 < $c2 ? $c1 : $c2;

    foreach my $i (0 .. $min_rows) {

        my $Ai = $a1->[$i];
        my $Bi = $a2->[$i];

        foreach my $j (0 .. $min_cols) {
            my $cmp = ($Ai->[$j] <=> $Bi->[$j]);
            $cmp and return $cmp;
        }

        if ($c1 != $c2) {
            return ($c1 <=> $c2);
        }
    }

    $r1 <=> $r2;
}

sub lt {
    my ($m1, $m2) = @_;
    $m1->cmp($m2) < 0;
}

sub gt {
    my ($m1, $m2) = @_;
    $m1->cmp($m2) > 0;
}

sub le {
    my ($m1, $m2) = @_;
    $m1->cmp($m2) <= 0;
}

sub ge {
    my ($m1, $m2) = @_;
    $m1->cmp($m2) >= 0;
}

sub ne {
    my ($m1, $m2) = @_;
    !($m1->eq($m2));
}

sub _LUP_decomposition {
    my ($self) = @_;

    my @A = map { [@$_] } @{$self->{matrix}};
    my $N = $self->{rows};
    my @P = (0 .. $N + 1);

    foreach my $i (0 .. $N) {

        my $maxA = 0;
        my $imax = $i;

        foreach my $k ($i .. $N) {
            my $absA = CORE::abs($A[$k][$i] // return [$N, \@A, \@P]);

            if ($absA > $maxA) {
                $maxA = $absA;
                $imax = $k;
            }
        }

        if ($imax != $i) {

            @P[$i, $imax] = @P[$imax, $i];
            @A[$i, $imax] = @A[$imax, $i];

            ++$P[$N + 1];
        }

        foreach my $j ($i + 1 .. $N) {

            if ($A[$i][$i] == 0) {
                return [$N, \@A, \@P];
            }

            $A[$j][$i] /= $A[$i][$i];

            foreach my $k ($i + 1 .. $N) {
                $A[$j][$k] -= $A[$j][$i] * $A[$i][$k];
            }
        }
    }

    [$N, \@A, \@P];
}

sub decompose {
    my ($self) = @_;
    @{$self->{_decomposition} //= $self->_LUP_decomposition};
}

# Reduced row echelon form

sub rref {
    my ($self) = @_;
    $self->{_rref} //= do {

        my @m = map { [@$_] } @{$self->{matrix}};

        @m || return __PACKAGE__->new([]);

        my ($j, $rows, $cols) = (0, $self->{rows} + 1, $self->{cols} + 1);

      OUTER: foreach my $r (0 .. $rows - 1) {

            $j < $cols or last;

            my $i = $r;

            while ($m[$i][$j] == 0) {
                ++$i == $rows or next;
                $i = $r;
                ++$j == $cols and last OUTER;
            }

            @m[$i, $r] = @m[$r, $i];

            my $mr  = $m[$r];
            my $mrj = $mr->[$j];

            foreach my $k (0 .. $cols - 1) {
                $mr->[$k] /= $mrj;
            }

            foreach my $i (0 .. $rows - 1) {

                $i == $r and next;

                my $mr  = $m[$r];
                my $mi  = $m[$i];
                my $mij = $m[$i][$j];

                foreach my $k (0 .. $cols - 1) {
                    $mi->[$k] -= $mij * $mr->[$k];
                }
            }

            ++$j;
        }

        __PACKAGE__->new(\@m);
    };
}

sub clone {
    my ($self) = @_;
    __PACKAGE__->new([map { [@$_] } @{$self->{matrix}}]);
}

sub transpose {
    my ($self) = @_;

    my $A = $self->{matrix};

    my $rows = $self->{rows};
    my $cols = $self->{cols};

    __PACKAGE__->new(
        [
         map {
             my $i = $_;
             [map { $A->[$_][$i] } 0 .. $rows]
           } 0 .. $cols
        ]
    );
}

sub concat {
    my ($m1, $m2) = @_;

    ref($m1) eq ref($m2)
      or _croak("concat(): expected a Matrix::LUP argument");

    $m1->{rows} == $m2->{rows}
      or _croak("concat(): matrices do not have the same row count");

    my $A = $m1->{matrix};
    my $B = $m2->{matrix};

    my @C;

    foreach my $i (0 .. $m1->{rows}) {
        push @C, [@{$A->[$i]}, @{$B->[$i]}];
    }

    __PACKAGE__->new(\@C);
}

sub horizontal_flip {
    my ($self) = @_;
    __PACKAGE__->new([map { [reverse(@$_)] } @{$self->{matrix}}]);
}

*hflip = \&horizontal_flip;

sub vertical_flip {
    my ($self) = @_;
    __PACKAGE__->new([reverse @{$self->{matrix}}]);
}

*vflip = \&vertical_flip;

sub flip {
    my ($self) = @_;
    __PACKAGE__->new([reverse map { [reverse(@$_)] } @{$self->{matrix}}]);
}

sub _scalar_mul {
    my ($matrix, $scalar) = @_;

    my @B;
    foreach my $row (@{$matrix->{matrix}}) {
        push @B, [map { $_ * $scalar } @$row];
    }

    __PACKAGE__->new(\@B);
}

sub _scalar_add {
    my ($matrix, $scalar) = @_;

    my @B;
    foreach my $row (@{$matrix->{matrix}}) {
        push @B, [map { $_ + $scalar } @$row];
    }

    __PACKAGE__->new(\@B);
}

sub _scalar_sub {
    my ($matrix, $scalar) = @_;

    my @B;
    foreach my $row (@{$matrix->{matrix}}) {
        push @B, [map { $_ - $scalar } @$row];
    }

    __PACKAGE__->new(\@B);
}

sub _scalar_div {
    my ($matrix, $scalar) = @_;

    my @B;
    foreach my $row (@{$matrix->{matrix}}) {
        push @B, [map { $_ / $scalar } @$row];
    }

    __PACKAGE__->new(\@B);
}

sub _scalar_mod {
    my ($matrix, $scalar) = @_;

    my @B;
    foreach my $row (@{$matrix->{matrix}}) {
        push @B, [map { $_ % $scalar } @$row];
    }

    __PACKAGE__->new(\@B);
}

sub _scalar_and {
    my ($matrix, $scalar) = @_;

    my @B;
    foreach my $row (@{$matrix->{matrix}}) {
        push @B, [map { $_ & $scalar } @$row];
    }

    __PACKAGE__->new(\@B);
}

sub _scalar_or {
    my ($matrix, $scalar) = @_;

    my @B;
    foreach my $row (@{$matrix->{matrix}}) {
        push @B, [map { $_ | $scalar } @$row];
    }

    __PACKAGE__->new(\@B);
}

sub _scalar_xor {
    my ($matrix, $scalar) = @_;

    my @B;
    foreach my $row (@{$matrix->{matrix}}) {
        push @B, [map { $_ ^ $scalar } @$row];
    }

    __PACKAGE__->new(\@B);
}

sub _scalar_lsft {
    my ($matrix, $scalar) = @_;

    my @B;
    foreach my $row (@{$matrix->{matrix}}) {
        push @B, [map { $_ << $scalar } @$row];
    }

    __PACKAGE__->new(\@B);
}

sub _scalar_rsft {
    my ($matrix, $scalar) = @_;

    my @B;
    foreach my $row (@{$matrix->{matrix}}) {
        push @B, [map { $_ >> $scalar } @$row];
    }

    __PACKAGE__->new(\@B);
}

sub neg {
    my ($matrix) = @_;

    my @B;
    foreach my $row (@{$matrix->{matrix}}) {
        push @B, [map { -$_ } @$row];
    }

    __PACKAGE__->new(\@B);
}

sub abs {
    my ($matrix) = @_;

    my @B;
    foreach my $row (@{$matrix->{matrix}}) {
        push @B, [map { CORE::abs($_) } @$row];
    }

    __PACKAGE__->new(\@B);
}

sub map {
    my ($matrix, $callback) = @_;

    my $A    = $matrix->{matrix};
    my $rows = $matrix->{rows};
    my $cols = $matrix->{cols};

    my @B;
    foreach my $i (0 .. $rows) {
        my @map;
        my $Ai = $A->[$i];
        foreach my $j (0 .. $cols) {
            local $_ = $Ai->[$j];
            push @map, $callback->($i, $j);
        }
        push @B, \@map;
    }

    __PACKAGE__->new(\@B);
}

sub add {
    my ($m1, $m2) = @_;

    if (ref($m2) ne ref($m1)) {
        return $m1->_scalar_add($m2);
    }

    my $A = $m1->{matrix};
    my $B = $m2->{matrix};

    my $rows = $m1->{rows};
    my $cols = $m1->{cols};

    ($rows == $m2->{rows} and $cols == $m2->{cols})
      or _croak("add(): matrices of different sizes");

    my @C;
    foreach my $i (0 .. $rows) {
        my $Ai = $A->[$i];
        my $Bi = $B->[$i];
        push @C, [map { $Ai->[$_] + $Bi->[$_] } 0 .. $cols];
    }

    __PACKAGE__->new(\@C);
}

sub sub {
    my ($m1, $m2) = @_;

    my $r1 = ref($m1);
    my $r2 = ref($m2);

    if ($r1 ne $r2) {
        if ($r1 eq __PACKAGE__) {
            return $m1->_scalar_sub($m2);
        }

        # a - b = -b + a
        if ($r2 eq __PACKAGE__) {
            return $m2->neg->_scalar_add($m1);
        }
    }

    my $A = $m1->{matrix};
    my $B = $m2->{matrix};

    my $rows = $m1->{rows};
    my $cols = $m2->{cols};

    ($rows == $m2->{rows} and $cols == $m2->{cols})
      or _croak("sub(): matrices of different sizes");

    my @C;
    foreach my $i (0 .. $rows) {
        my $Ai = $A->[$i];
        my $Bi = $B->[$i];
        push @C, [map { $Ai->[$_] - $Bi->[$_] } 0 .. $cols];
    }

    __PACKAGE__->new(\@C);
}

sub and {
    my ($m1, $m2) = @_;

    if (ref($m2) ne ref($m1)) {
        return $m1->_scalar_and($m2);
    }

    my $A = $m1->{matrix};
    my $B = $m2->{matrix};

    my $rows = $m1->{rows};
    my $cols = $m2->{cols};

    ($rows == $m2->{rows} and $cols == $m2->{cols})
      or _croak("and(): matrices of different sizes");

    my @C;
    foreach my $i (0 .. $rows) {
        my $Ai = $A->[$i];
        my $Bi = $B->[$i];
        push @C, [map { $Ai->[$_] & $Bi->[$_] } 0 .. $cols];
    }

    __PACKAGE__->new(\@C);
}

sub or {
    my ($m1, $m2) = @_;

    if (ref($m2) ne ref($m1)) {
        return $m1->_scalar_or($m2);
    }

    my $A = $m1->{matrix};
    my $B = $m2->{matrix};

    my $rows = $m1->{rows};
    my $cols = $m1->{cols};

    ($rows == $m2->{rows} and $cols == $m2->{cols})
      or _croak("or(): matrices of different sizes");

    my @C;
    foreach my $i (0 .. $rows) {
        my $Ai = $A->[$i];
        my $Bi = $B->[$i];
        push @C, [map { $Ai->[$_] | $Bi->[$_] } 0 .. $cols];
    }

    __PACKAGE__->new(\@C);
}

sub xor {
    my ($m1, $m2) = @_;

    if (ref($m2) ne ref($m1)) {
        return $m1->_scalar_xor($m2);
    }

    my $A = $m1->{matrix};
    my $B = $m2->{matrix};

    my $rows = $m1->{rows};
    my $cols = $m1->{cols};

    ($rows == $m2->{rows} and $cols == $m2->{cols})
      or _croak("xor(): matrices of different sizes");

    my @C;
    foreach my $i (0 .. $rows) {
        my $Ai = $A->[$i];
        my $Bi = $B->[$i];
        push @C, [map { $Ai->[$_] ^ $Bi->[$_] } 0 .. $cols];
    }

    __PACKAGE__->new(\@C);
}

sub lsft {
    my ($m1, $m2) = @_;

    my $r1 = ref($m1);
    my $r2 = ref($m2);

    if ($r1 ne $r2) {

        if ($r1 eq __PACKAGE__) {
            return $m1->_scalar_lsft($m2);
        }

        _croak("lsft(): invalid argument");
    }

    my $A = $m1->{matrix};
    my $B = $m2->{matrix};

    my $rows = $m1->{rows};
    my $cols = $m2->{cols};

    ($rows == $m2->{rows} and $cols == $m2->{cols})
      or _croak("lsft(): matrices of different sizes");

    my @C;
    foreach my $i (0 .. $rows) {
        my $Ai = $A->[$i];
        my $Bi = $B->[$i];
        push @C, [map { $Ai->[$_] << $Bi->[$_] } 0 .. $cols];
    }

    __PACKAGE__->new(\@C);
}

sub rsft {
    my ($m1, $m2) = @_;

    my $r1 = ref($m1);
    my $r2 = ref($m2);

    if ($r1 ne $r2) {

        if ($r1 eq __PACKAGE__) {
            return $m1->_scalar_rsft($m2);
        }

        _croak("rsft(): invalid argument");
    }

    my $A = $m1->{matrix};
    my $B = $m2->{matrix};

    my $rows = $m1->{rows};
    my $cols = $m1->{cols};

    ($rows == $m2->{rows} and $cols == $m2->{cols})
      or _croak("rsft(): matrices of different sizes");

    my @C;
    foreach my $i (0 .. $rows) {
        my $Ai = $A->[$i];
        my $Bi = $B->[$i];
        push @C, [map { $Ai->[$_] >> $Bi->[$_] } 0 .. $cols];
    }

    __PACKAGE__->new(\@C);
}

sub mul {
    my ($m1, $m2) = @_;

    if (ref($m2) ne ref($m1)) {
        return $m1->_scalar_mul($m2);
    }

    my $A = $m1->{matrix};
    my $B = $m2->{matrix};

    my @c;

    my $a_rows = $m1->{rows};
    my $b_rows = $m2->{rows};
    my $b_cols = $m2->{cols};

    $m1->{cols} == $m2->{rows}
      or _croak("mul(): number of columns in A != number of rows in B");

    foreach my $i (0 .. $a_rows) {
        foreach my $j (0 .. $b_cols) {
            foreach my $k (0 .. $b_rows) {

                my $t = $A->[$i][$k] * $B->[$k][$j];

                if (!defined($c[$i][$j])) {
                    $c[$i][$j] = $t;
                }
                else {
                    $c[$i][$j] += $t;
                }
            }
        }
    }

    __PACKAGE__->new(\@c);
}

sub div {
    my ($m1, $m2) = @_;

    my $r1 = ref($m1);
    my $r2 = ref($m2);

    if ($r1 ne $r2) {

        if ($r1 eq __PACKAGE__) {
            return $m1->_scalar_div($m2);
        }

        # A/B = A * B^(-1)
        if ($r2 eq __PACKAGE__) {
            return $m2->inv->_scalar_mul($m1);
        }
    }

    $m1->mul($m2->inv);
}

sub floor {
    my ($self) = @_;

    __PACKAGE__->new(
        [
         map {
             [
              map {
                  my $t = CORE::int($_);
                  $t -= 1 if ($_ != $t and $_ < 0);
                  $t;
                } @$_
             ]
         } @{$self->{matrix}}
        ]
    );
}

sub ceil {
    my ($self) = @_;

    __PACKAGE__->new(
        [
         map {
             [
              map {
                  my $t = CORE::int($_);
                  $t += 1 if ($_ != $t and $_ > 0);
                  $t;
                } @$_
             ]
         } @{$self->{matrix}}
        ]
    );
}

sub mod {
    my ($A, $B) = @_;

    my $r1 = ref($A);
    my $r2 = ref($B);

    if ($r1 ne $r2) {

        if ($r1 eq __PACKAGE__) {
            return $A->_scalar_mod($B);
        }

        # A - B*floor(A/B) = A - B*floor(A * B^(-1))
        if ($r2 eq __PACKAGE__) {
            return Math::MatrixLUP::sub($A, $B->mul($B->inv->_scalar_mul($A)->floor));
        }
    }

    # A - B*floor(A/B)
    $A->sub($B->mul($A->div($B)->floor));
}

sub pow {
    my ($A, $pow) = @_;

    $pow = CORE::int($pow);
    my $neg = ($pow < 0);
    $pow = CORE::int(CORE::abs($pow));

    return $A->inv if ($neg and $pow == 1);

    my $B = Math::MatrixLUP::identity($A->{rows} + 1);

    return $B if ($pow == 0);

    while (1) {
        $B = $B->mul($A) if ($pow & 1);
        ($pow >>= 1) or last;
        $A = $A->mul($A);
    }

    $neg ? $B->inv : $B;
}

sub powmod {
    my ($A, $pow, $mod) = @_;

    $pow = CORE::int($pow);

    if ($pow < 0) {
        $A   = $A->invmod($mod);
        $pow = CORE::abs($pow);
    }

    my $B = Math::MatrixLUP::identity($A->{rows} + 1);

    return $B->mod($mod) if ($pow == 0);

    while (1) {
        $B = $B->mul($A)->mod($mod) if ($pow & 1);
        ($pow >>= 1) or last;
        $A = $A->mul($A)->mod($mod);
    }

    $B->mod($mod);
}

sub solve {
    my ($self, $vector) = @_;

    $self->{is_square}           or _croak('solve(): not a square matrix');
    ref($vector) eq 'ARRAY'      or _croak('solve(): the vector must be an ARRAY ref');
    $#{$vector} == $self->{rows} or _croak('solve(): length(vector) != length(matrix)');

    my ($N, $A, $P) = $self->decompose;

    my @x = map { $vector->[$P->[$_]] } 0 .. $N;

    foreach my $i (1 .. $N) {
        foreach my $k (0 .. $i - 1) {
            $x[$i] -= $A->[$i][$k] * $x[$k];
        }
    }

    for (my $i = $N ; $i >= 0 ; --$i) {
        foreach my $k ($i + 1 .. $N) {
            $x[$i] -= $A->[$i][$k] * $x[$k];
        }
        $x[$i] /= $A->[$i][$i];
    }

    \@x;
}

sub invert {
    my ($self) = @_;

    $self->{is_square} or _croak('invert(): not a square matrix');

    $self->{_inverse} //= do {
        my ($N, $A, $P) = $self->decompose;

        my @I;

        foreach my $j (0 .. $N) {
            foreach my $i (0 .. $N) {

                $I[$i][$j] = ($P->[$i] == $j) ? 1 : 0;

                foreach my $k (0 .. $i - 1) {
                    $I[$i][$j] -= $A->[$i][$k] * $I[$k][$j];
                }
            }

            for (my $i = $N ; $i >= 0 ; --$i) {

                foreach my $k ($i + 1 .. $N) {
                    $I[$i][$j] -= $A->[$i][$k] * $I[$k][$j];
                }

                $I[$i][$j] /= $A->[$i][$i] // return __PACKAGE__->new([]);
            }
        }

        __PACKAGE__->new(\@I);
    };
}

*inv = \&invert;

sub invmod {
    my ($self, $mod) = @_;

    my $A = $self->invert->clone;

    foreach my $row (@$A) {
        foreach my $i (0 .. $#{$row}) {
            $row->[$i] %= $mod;
        }
    }

    return $A;
}

sub determinant {
    my ($self) = @_;

    $self->{is_square} or _croak('determinant(): not a square matrix');

    $self->{_determinant} //= do {
        my ($N, $A, $P) = $self->decompose;

        my $det = $A->[0][0] // return 1;

        foreach my $i (1 .. $N) {
            $det *= $A->[$i][$i];
        }

        if (($P->[$N + 1] - $N) % 2 == 0) {
            $det *= -1;
        }

        $det;
    };
}

*det = \&determinant;

sub stringify {
    my ($self) = @_;
    $self->{_stringification} //=
      "[\n  " . join(",\n  ", map { "[" . join(", ", @$_) . "]" } @{$self->{matrix}}) . "\n]";
}

1;    # End of Math::MatrixLUP
