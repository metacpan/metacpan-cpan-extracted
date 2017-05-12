package Math::MatrixReal::Ext1;

use strict;
use Math::MatrixReal;
use Carp;

use base qw/Math::MatrixReal/;

our $VERSION = '0.07';

sub new_from_cols {
    my $this = shift;
    my $extra_args = ( @_ > 1 && ref($_[-1]) eq 'HASH' ) ? pop : {};
    $extra_args->{_type} = 'column';

    return $this->_new_from_rows_or_cols(@_, $extra_args );
}
sub new_from_columns {
    my $this = shift;
    $this->new_from_cols(@_);
}
sub new_from_rows {
    my $this = shift;
    my $extra_args = ( @_ > 1 && ref($_[-1]) eq 'HASH' ) ? pop : {};
    $extra_args->{_type} = 'row';

    return $this->_new_from_rows_or_cols(@_, $extra_args );
}

sub _new_from_rows_or_cols {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $ref_to_vectors = shift;

    # these additional args are internal at the moment, 
    # but in the future the user could pass e.g. {pad=>1} to
    # request padding
    my $args = pop;
    my $vector_type = $args->{_type};
    die "Internal ".__PACKAGE__." error" unless $vector_type =~ /^(row|column)$/;

    # step back one frame because this private method is 
    # not how the user called it
    my $caller_subname = (caller(1))[3];

    # note--this die() could be inconvenient if someone had something
    # really fancy that knew how to be dereffed as an array 
    # (can you do that with a tied scalar?), but I'm not putting
    # the rest of the world through an eval--they can just
    # deref and pass a reference themselves.  If that ever happens
    # we can add an arg to skip this check
    croak "$caller_subname: need a reference to an array of ${vector_type}s" unless ref($ref_to_vectors) eq 'ARRAY';
    my @vectors = @{$ref_to_vectors};

    my $matrix;

    my $other_type = {row=>'column', column=>'row'}->{$vector_type};

    my %matrix_dim = (
        $vector_type => scalar( @vectors ), 
        $other_type  => 0,  # we will correct this in a bit
    );

    # row and column indices are one based
    my $current_vector_count = 1; 
    foreach my $current_vector (@vectors) {
        # dimension is one-based, so we're
        # starting with one here and incrementing
        # as we go.  The other dimension is fixed (for now, until
        # we add the 'pad' option), and gets set later
        my $ref = ref( $current_vector ) ;

        if ( $ref eq '' ) {
            # we hope this is a properly formatted Math::MatrixReal string,
            # but if not we just let the Math::MatrixReal die() do it's
            # thing
                $current_vector = $class->new_from_string( $current_vector );
            }
            elsif ( $ref eq 'ARRAY' ) {
                my @array = @$current_vector;
                croak "$caller_subname: one $vector_type you gave me was a ref to an array with no elements" unless @array ;
            # we need to create the right kind of string based on whether
            # they said they were sending us rows or columns:
            if ($vector_type eq 'row') {
                $current_vector = $class->new_from_string( '[ '. join( " ", @array) ." ]\n" );
            }
            else {
                $current_vector = $class->new_from_string( '[ '. join( " ]\n[ ", @array) ." ]\n" );
            }
        }
        elsif ( $ref ne 'HASH' and $current_vector->isa('Math::MatrixReal') ) {
            # it's already a Math::MatrixReal something.
            # we don't need to do anything, it will all
            # work out
        }
        else {
            # we have no idea, error time!
            croak "$caller_subname: I only know how to deal with array refs, strings, and things that inherit from Math::MatrixReal\n";
        }

        # starting now we know $current_vector isa Math::MatrixReal thingy
        my @vector_dims = $current_vector->dim;

        #die unless the appropriate dimension is 1
        croak "$caller_subname: I don't accept $other_type vectors"
            unless ($vector_dims[ $vector_type eq 'row' ? 0 : 1 ] == 1) ;

        # the other dimension is the length of our vector
        my $length =  $vector_dims[ $vector_type eq 'row' ? 1 : 0 ];

        # set the "other" dimension to the length of this
        # vector the first time through
        $matrix_dim{$other_type} ||= $length;

        # die unless length of this vector matches the first length
        croak "$caller_subname: one $vector_type has [$length] elements and another one had [$matrix_dim{$other_type}]--all of the ${vector_type}s passed in must have the same dimension"
              unless ($length == $matrix_dim{$other_type}) ;

        # create the matrix the first time through
        $matrix ||= $class->new($matrix_dim{row}, $matrix_dim{column});

        # step along the vector assigning the value of each element
        # to the correct place in the matrix we're building
        foreach my $element_index ( 1..$length ){
            # args for vector assignment:
            # initialize both to one and reset the correct
            # one below
            my ($v_r, $v_c) = (1,1);

            # args for matrix assignment
            my ($row_index, $column_index, $value);

            if ($vector_type eq 'row') {
                $row_index           = $current_vector_count;
                $v_c = $column_index = $element_index;
            }
            else {
                $v_r = $row_index    = $element_index;
                $column_index        = $current_vector_count;
            }
            $value = $current_vector->element($v_r, $v_c);
            $matrix->assign($row_index, $column_index, $value);
        }
        $current_vector_count ++ ;
    }
    return $matrix;
}


1;
__END__
=head1 NAME

Math::MatrixReal::Ext1 - Minor extensions to Math::MatrixReal

=head1 SYNOPSIS

  use Math::MatrixReal::Ext1;

  $ident3x3 = Math::MatrixReal::Ext1->new_from_cols( [ [1,0,0],[0,1,0],[0,0,1] ] );
  $upper_tri = Math::MatrixReal::Ext1->new_from_rows( [ [1,1,1],[0,1,1],[0,0,1] ] );

  $col1 = Math::MatrixReal->new_from_string("[ 1 ]\n[ 3 ]\n[ 5 ]\n");
  $col2 = Math::MatrixReal->new_from_string("[ 2 ]\n[ 4 ]\n[ 6 ]\n");

  $mat = Math::MatrixReal::Ext1->new_from_cols( [ $col1, $col2 ] );

=head1 DOWNLOADING

The latest version might be at

    http://fulcrum.org/personal/msouth/code/

but I would bet on CPAN if I were you.

=head1 DESCRIPTION

Just scratching a couple of itches for functionality in Math::MatrixReal.

[At the time I wrote this (2001) Math::MatrixReal was abandoned, but 
someone has since adopted it.  My recent (2005) updates will also
hopefully go into Math::MatrixReal, but for now I'm putting them
here because I just can't stand having this stuff out there
uncorrected.  Once the most recent changes are in the main 
line, I will deprecate this module and then it will completely
disappear, probably some time in 2006.]

=over 4

=item C<new_from_cols>

C<new_from_cols( [ $column_vector|$array_ref|$string, ... ] )>

Creates a new matrix given a reference to an array of any of the following:

=over 4

=item * column vectors ( n by 1 Math::MatrixReal matrices )

=item * references to arrays

=item * strings properly formatted to create a column with Math::MatrixReal's C<new_from_string> command

=back

You may mix and match these as you wish.  However, all must be of the 
same dimension--no padding happens automatically.  This could possibly
change in a future version.

=item C<new_from_rows>

C<new_from_rows( [ $row_vector|$array_ref|$string, ... ] )>

Creates a new matrix given a reference to an array of any of the following:

=over 4

=item * row vectors ( 1 by n Math::MatrixReal matrices )

=item * references to arrays

=item * strings properly formatted to create a row with Math::MatrixReal's C<new_from_string> command

=back

You may mix and match these as you wish.  However, all must be of the 
same dimension--no padding happens automatically.  This could possibly
change in a future version.

=back

=head1 BUGS

Error handling could be more descriptive in some cases.

It has been suggested that use of Math::MatrixReal (and thus, by extension,
extending it) is pointless in light of the powerful Math::Pari.  From the
documentation for Math::Pari:

=over 4

Package Math::Pari is a Perl interface to famous library PARI for
numerical/scientific/number-theoretic calculations.  It allows use of
most PARI functions (>500) as Perl functions, and (almost) seamless merging
of PARI and Perl data. 

=back 

So, if you're thinking of using this, you may want to look at Math::Pari instead.


=head1 AUTHOR

msouth@fulcrum.org (see http://fulcrum.org )

=head1 SEE ALSO

Math::MatrixReal(3).

=cut
