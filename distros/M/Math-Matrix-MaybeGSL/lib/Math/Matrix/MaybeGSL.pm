# ABSTRACT: Uniform use of Math::MatrixReal and Math::GSL::Matrix.

use strict;
use warnings;

package Math::Matrix::MaybeGSL;
$Math::Matrix::MaybeGSL::VERSION = '0.008';
use parent 'Exporter';
our @EXPORT = qw{Matrix};

use overload
       '*=' => '_assign_multiply',
        '*' => '_multiply',
       '+=' => '_assign_add',
        '+' => '_add',
 'fallback' =>   undef;

sub _choose_matrix_module {
    return 'Math::GSL::Matrix' if $INC{'Math/GSL/Matrix.pm'};
    return 'Math::MatrixReal'  if $INC{'Math/MatrixReal.pm'};

    my @err;

    return 'Math::GSL::Matrix' if eval {
        require Math::GSL;
        require Math::GSL::Matrix;
        1;
    };
    push @err, "Error loading Math::GSL::Matrix: $@";

    return 'Math::MatrixReal' if eval { require Math::MatrixReal; 1; };
    push @err, "Error loading Math::MatrixReal: $@";

    die join( "\n", "Couldn't load a Matrix module:", @err );
}

sub Matrix { __PACKAGE__ }

sub _call {
    my ($method, $obj, @args) = @_;
    $obj->{matrix}->$method(@args);
}

sub isGSL {
    our $matrix_module;
    return $matrix_module eq "Math::GSL::Matrix";
}

BEGIN {
    our $matrix_module = _choose_matrix_module();
    my %functions
      = (
         'any' => {
                   new => sub {
                       my (undef, $rows, $cols) = @_;
                       return _new( $matrix_module->new($rows, $cols) );
                   },
                   dim     => sub { _call(dim => @_) },
                   each    => sub { _new(_call(each => @_)) },
                   as_list => sub { _call(as_list => @_) },
                   det     => sub { _call(det => @_)} ,
                  },
         'Math::GSL::Matrix' => {
            assign        => sub { _call(set_elem => ($_[0], $_[1]-1, $_[2]-1, $_[3])); },
            element       => sub { _call(get_elem => ($_[0], $_[1]-1, $_[2]-1, $_[3])); },
            new_from_cols => sub { _new(_gsl_new_from_cols($_[1])) },
            new_from_rows => sub { _new(_gsl_new_from_rows($_[1])) },
            vconcat       => sub { _new(_call(vconcat => $_[0], $_[1]{matrix})) },
            hconcat       => sub { _new(_call(hconcat => $_[0], $_[1]{matrix})) },
            write         => sub { _gsl_write(@_) },
            read          => sub { _gsl_read($_[1]) },
            max           => sub {
                if (wantarray) {
                    my ($v, @pos) = _call(max => @_);
                    return ($v, map { $_ + 1 } @pos);
                } else {
                    return scalar(_call(max => @_));
                };
            },
            min           => sub {
                if (wantarray) {
                    my ($v, @pos) = _call(min => @_);
                    return ($v, map { $_ + 1 } @pos);
                } else {
                    return scalar(_call(min => @_));
                };
            },
            row           => sub { _new(_call(row => $_[0], $_[1]-1)) },
            find_zeros    => sub { _gsl_find_zeros(@_) },
            transpose     => sub { _gsl_transpose(@_) },
           },
         'Math::MatrixReal' => {
            assign        => sub { _call(assign        => @_); },
            element       => sub { _call(element       => @_); },
            new_from_cols => sub { _new( $matrix_module->new_from_cols($_[1])) },
            new_from_rows => sub { _new( $matrix_module->new_from_rows($_[1])) },
            vconcat       => sub { _new( ~((~$_[0]{matrix}) . (~$_[1]{matrix})) ) },
            hconcat       => sub { _new(     $_[0]{matrix}  .   $_[1]{matrix}   ) },
            write         => sub { _mreal_write(@_) },
            read          => sub { _mreal_read($_[1]) },
            max           => sub { _mreal_max($_[0]{matrix}) },
            min           => sub { _mreal_min($_[0]{matrix}) },
            row           => sub { _new( $_[0]{matrix}->row($_[1]) ) },
            find_zeros    => sub { _mreal_find_zeros(@_) },
            transpose     => sub { _new( ~$_[0]{matrix} ) },
                               },
	);

    no strict 'refs';

    for my $func (keys %{$functions{$matrix_module}}) {
        # Use Sub::Install later?
        $_ = __PACKAGE__ . "::$func";
        *$_ = $functions{$matrix_module}{$func};
    }
    for my $func (keys %{$functions{any}}) {
        # Use Sub::Install later?
        $_ = __PACKAGE__ . "::$func";
        *$_ = $functions{any}{$func};
    }

}

sub _mreal_max {
    my $matrix = shift;
    my ($rs, $cs) = $matrix->dim();
    return $matrix->max() if ($rs == 1 || $cs == 1);

    my ($m, $r, $c, $v) = ($matrix->[0], 1, 1, undef);

    for my $i (1..$rs) {
        for my $j (1..$cs) {
            if (!$v || $v < $m->[$i-1][$j-1]) {
                $r = $i;
                $c = $j;
                $v = $m->[$i-1][$j-1];
            }
        }
    }

    return wantarray ? ($v, $r, $c) : $v;
}

sub _mreal_min {
    my $matrix = shift;
    my ($rs, $cs) = $matrix->dim();
    return $matrix->min() if ($rs == 1 || $cs == 1);

    my ($m, $r, $c, $v) = ($matrix->[0], 1, 1, undef);

    for my $i (1..$rs) {
        for my $j (1..$cs) {
            if (!$v || $v > $m->[$i-1][$j-1]) {
                $r = $i;
                $c = $j;
                $v = $m->[$i-1][$j-1];
            }
        }
    }

    return wantarray ? ($v, $r, $c) : $v;
}

sub _gsl_new_from_cols {
    my $cols = shift;

    my $nr_columns = scalar(@$cols);
    my $nr_rows = 0;
    for my $row (@$cols) {
        $nr_rows = scalar(@$row) if @$row > $nr_rows;
    }
    my $m = Math::GSL::Matrix->new($nr_rows, $nr_columns);
    for my $r (0..$nr_rows - 1) {
        for my $c (0..$nr_columns - 1) {
            $m->set_elem($r, $c, $cols->[$c][$r] || 0);
        }
    }
    return $m;
}

sub _gsl_new_from_rows {
    my $rows = shift;

    my $nr_rows = scalar(@$rows);
    my $nr_columns = 0;
    for my $col (@$rows) {
        $nr_columns = scalar(@$col) if @$col > $nr_columns;
    }
    my $m = Math::GSL::Matrix->new($nr_rows, $nr_columns);
    for my $c (0..$nr_columns - 1) {
        for my $r (0..$nr_rows - 1) {
            $m->set_elem($r, $c, $rows->[$r][$c] || 0);
        }
    }
    return $m;
}

sub _new {
    my $mat = shift;
    return bless { matrix => $mat }, __PACKAGE__;
}

sub _assign_multiply {
    my($object,$argument) = @_;

    return( &_multiply($object,$argument,undef) );
}

sub _multiply {
    my ($object, $argument, $flag) = @_;

    $argument = $argument->{matrix} if ref $argument eq __PACKAGE__;
    $object   = $object->{matrix}   if ref $object   eq __PACKAGE__;

    if ((defined $flag) && $flag) {
    	return _new($argument * $object);
    } else {
    	return _new($object * $argument);
    }
}

sub _assign_add {
    my($object,$argument) = @_;

    return( &_add($object,$argument) );
}

sub _add {
    my ($object, $argument) = @_;

    $object   = $object->{matrix}   if ref $object   eq __PACKAGE__;
    $argument = $argument->{matrix} if ref $argument eq __PACKAGE__;

    return _new($object + $argument);
}

sub _mreal_write {
    my ($m, $filename) = @_;

    my $matrix = $m->{matrix};

    open my $fh, ">", $filename or
      die "Could not create file '$filename': $!";

    # probably faster than creating a full string in memory
    my ($rows, $cols) = $matrix->dim();

    for my $r (0..$rows-1) {
        for my $c (0..$cols-1) {
            print $fh $matrix->[0][$r][$c];
            print $fh "\t" unless $c == $cols-1;
        }
        print $fh "\n";
    }
    close $fh;
}

sub _mreal_read {
    my $filename = shift;

    my $m = [];

    open my $fh, "<", $filename or
      die "could not open file '$filename': $!";

    while (<$fh>) {
        chomp;
        push @$m, [split /\s+/];
    }

    return _new( Math::MatrixReal->new_from_rows($m) );
}

sub _mreal_find_zeros {
    my ($matrix) = @_;
    my ($rs, $cs) = $matrix->dim();

    my @matches;
    my $pos = 0;
    for ($matrix->as_list()) {
        push @matches, [int($pos/$cs)+1, ($pos % $cs)+1] unless $_;
        $pos++;
    }

    return @matches;
}

sub _gsl_read {
    my $filename = shift;

    die "$filename does not exist" unless -f $filename;

    my $fh = Math::GSL::gsl_fopen($filename, "r");
    die "error opening file $filename for reading" unless $fh;

    my $dim = Math::GSL::Matrix::gsl_matrix_alloc(1, 2);
    my $err = Math::GSL::Matrix::gsl_matrix_fread($fh, $dim);
    die "error reading matrix" if $err;

    my $m = Math::GSL::Matrix::gsl_matrix_alloc(
               Math::GSL::Matrix::gsl_matrix_get($dim, 0, 0),
               Math::GSL::Matrix::gsl_matrix_get($dim, 0, 1));
    $err = Math::GSL::Matrix::gsl_matrix_fread($fh, $m);
    die "error reading matrix" if $err;

    Math::GSL::Matrix::gsl_matrix_free($dim);

    Math::GSL::gsl_fclose($fh);
    _new( Math::GSL::Matrix->new($m) );
}

sub _gsl_write {
    my ($self, $filename) = @_;

    my $fh = Math::GSL::gsl_fopen($filename, "w");
    die "error opening file: $filename" unless $fh;

    # create a temporary matrix with the main matrix dimensions
    my $dim = Math::GSL::Matrix::gsl_matrix_alloc(1, 2);
    my ($rows, $cols) = $self->dim;
    Math::GSL::Matrix::gsl_matrix_set($dim, 0, 0, $rows);
    Math::GSL::Matrix::gsl_matrix_set($dim, 0, 1, $cols);

    my $err = Math::GSL::Matrix::gsl_matrix_fwrite($fh, $dim);
    die "error gsl-writting matrix" if $err;

    Math::GSL::Matrix::gsl_matrix_free($dim);

    $err = Math::GSL::Matrix::gsl_matrix_fwrite($fh, $self->{matrix}->raw);
    die "error gsl-writting matrix" if $err;

    Math::GSL::gsl_fclose($fh);

}

sub _gsl_find_zeros {
    my ($matrix) = @_;
    my ($rs, $cs) = $matrix->dim();

    my $raw_matrix = $matrix->{matrix}->raw;
    my @matches;
    for my $i (0..$rs-1) {
        for my $j (0..$cs-1) {
            next if Math::GSL::Matrix::gsl_matrix_get($raw_matrix, $i, $j);
            push @matches, [$i+1, $j+1];
        }
    }
    return @matches;
}

sub _gsl_transpose {
    my ($matrix) = @_;
    my ($rs, $cs) = $matrix->dim();

    my $result = Math::GSL::Matrix::gsl_matrix_alloc($cs, $rs);
    Math::GSL::Matrix::gsl_matrix_transpose_memcpy($result, $matrix->{matrix}->raw());

    return _new(Math::GSL::Matrix->new($result));
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::Matrix::MaybeGSL - Uniform use of Math::MatrixReal and Math::GSL::Matrix.

=head1 VERSION

version 0.008

=head1 SYNOPSIS

   use Math::Matrix::MaybeGSL;

   my $matrix = Matrix->new(3, 4);

   # puts first position of matrix with value 10
   $matrix->assign(1, 1, 10);

   # gets last position of matrix (should hold 0)
   my $l = $matrix->element(3, 4);

=head1 DESCRIPTION

This module interfaces with C<Math::GSL::Matrix> or, if that is not
available, C<Math::MatrixReal>.  The idea behind this module is to
allow the development of tools that use matrices that will work in
pure Perl (using C<Math::MatrixReal>) or with extra efficiency using
C<Math::GSL::Matrix>.

Given the two modules API is quite distinct, this module defines its
own API, stealing method names from both these modules.

=head1 METHODS

=head2 C<Matrix>

This is a simple function that returns this package name: C<Math::Matrix::MaybeGSL>.
It allows a simple interface as shown below for the constructors.

=head2 C<isGSL>

Returns a true value is running over L<Math::GSL> backend.

    if (Matrix->isGSL) { ... }

=head2 C<new>

Construct a new matrix object. Receives as arguments the number of rows and columns of the
matrix being created.

   my $matrix = Matrix->new(20, 30);

Yes, although the module name is C<Math::Matrix::MaybeGSL>, the C<Matrix> subroutine will 
make it easier to use (shorter name).

=head2 C<new_from_cols>

Receives a nested list with the matrix elements, one column at a time:

   my $matrix = Matrix->new_from_cols( [[1, 2], [3, 4]]);

   returns  [ 1 3 ]
            [ 2 4 ]

=head2 C<new_from_rows>

Receives a nested list with the matrix elements, one row at a time:

   my $matrix = Matrix->new_from_rows( [[1, 2], [3, 4]]);

   returns  [ 1 2 ]
            [ 3 4 ]

=head2 C<dim>

Returns a list (a pair) with the number of lines and columns of the matrix.

   my ($rows, $columns) = $matrix->dim();

=head2 C<assign>

Sets a value in a specific position. Note that B<indexes start at 1> unlike Perl and some 
other programming languages.

    # sets the first element of the matrix to 10.
    $matrix->assign(1, 1, 10);

=head2 C<element>

Retrieves a value from a specific position of the matrix. Note that B<indexes start at 1> unlike
Perl and some other programming languages.

    # retrieves the second element of the first row
    my $val = $matrix->element(1, 2);

=head2 C<each>

Apply a specific function to every element of the matrix, returning a new one.

    # square all elements
    $squared_matrix = $matrix->each( { shift ** 2 } );

=head2 C<hconcat>

Concatenates two matrices horizontally. Note they must have the same number of rows.

   $C = $a->hconcat($b);

   if A = [ 1 2 ]  and B = [ 5 6 ]  then C = [ 1 2 5 6 ]
          [ 3 4 ]          [ 7 8 ]           [ 3 4 7 8 ]

=head2 C<vconcat>

Concatenates two matrices horizontally. Note they must have the same number of rows.

   $C = $a->vconcat($b);

   if A = [ 1 2 ]  and B = [ 5 6 ]  then C = [ 1 2 ]
          [ 3 4 ]          [ 7 8 ]           [ 3 4 ]
                                             [ 5 6 ]
                                             [ 7 8 ]

=head2 C<max>

Returns the maximum value of the matrix. In scalar context the position is also
returned. For vectors (matrices whose number of rows or columns is 1) only a position value
is returned.

      $max = $matrix->max();
      ($max, $row, $col) = $matrix->max();

=head2 C<min>

Returns the minimum value of the matrix. In scalar context the position is also
returned. For vectors (matrices whose number of rows or columns is 1) only a position value
is returned.

      $min = $matrix->min();
      ($min, $row, $col) = $matrix->min();

=head2 C<det>

Returns the determinant of the matrix, without going through the rigamarole of computing
a LR decomposition.

=head2 C<as_list>

Get the contents of a matrix instance as a Perl list.

=head2 C<write>

Given a matrix and a filename, writes that matrix to the file. Note that if the file
exists it will be overwritten. Also, B<files written by Math::GSL will not be compatible
with files written by Math::MatrixReal> nor vice-versa.

     $matrix->write("my_matrix.dat");

=head2 C<read>

Reads a matrix written by the C<write> method. Note that it will only read matrices
written by the same back-end that is being used for reading.

     my $matrix = Matrix->load("my_matrix.dat");

=head2 C<row>

Returns the selected row in a matrix as a new matrix object. Note that B<indexes start at 1>
unlike Perl and some other programming languages.

    my $row = $matrix->row(1);

=head2 C<find_zeros>

Given a matrix, returns a nested list of indices corresponding to zero values in the
given matrix. Note that B<indexes start at 1> unlike Perl and some other programming languages.

    my @indices = $matrix->find_zeros();

=head2 C<transpose>

Returns transposed matrix.

=head1 OVERLOAD

For now only matrix multiplication and addition are overloaded, in the usual operators, C<*> and C<+>, correspondingly.
Take attention that these operations only work if the matrix dimensions are compatible.

    $m = $a * $b;
    $n = $a + $b;

=head1 BUGS

At this initial stage of this module, only the methods that I am really needing for my depending applications are 
implemented. Therefore, it might not include the method that you were looking for. Nevertheless, 
send me an e-mail (or open an issue on GitHub) and I'll be happy to include it (given the two
modules support it).

=head1 SEE ALSO

Check C<Math::MatrixReal> and C<Math::GSL::Matrix> documentation.

=head1 CONTRIBUTORS

=over 4

=item * Andrius Merkys <merkys@cpan.org>

=item * Ivan Baidakou

=item * Gabor Szabo

=back

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
