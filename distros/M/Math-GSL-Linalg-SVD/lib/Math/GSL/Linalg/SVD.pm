package Math::GSL::Linalg::SVD;

use 5.010000;
use strict;
use warnings;
use Carp;

#=fs Config

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

#=fe

our $VERSION = '0.0.2';

#=fs Config

require XSLoader;
XSLoader::load('Math::GSL::Linalg::SVD', $VERSION);

#=fe


#////////////////////////////////////////////// Convinience Methods ///////////////////////////////////////////////////


=head1 NAME

Math::GSL::Linalg::SVD - Perl extension with convenience methods for performing SVD and eigenvector decomp with the gsl C libraries.

=cut 

=head1 SYNOPSIS

    use Math::GSL::Linalg::SVD;

    # Create object.
    my $svd = Math::GSL::Linalg::SVD->new( { verbose => 1 } );

    my $data = [ 
                    [qw/  9.515970281313E-01  1.230695618728E-01 -1.652767938310E-01 /],
                    [qw/ -1.788010086499E-01  3.654739881179E-01  8.526964090247E-02 /],
                    [qw/  4.156708817272E-02  5.298288357316E-02  7.130047145031E-01 /],
               ];

    # Load data.
    $svd->load_data( { data => $data } );

    # Perform singular value decomposition using the Golub-Reinsch algorithm (this is the default - see METHODS).
    # To perform eigen decomposition pass 'eign' as algorithm argument - see METHODS.
    $svd->decompose( { algorithm => q{gd} } );

    # Pass results - see METHODS for more details.
    my ($S_vec_ref, $U_mat_ref, $V_mat_ref, $original_data_ref) = $svd->results;

    # Print elements of vector S.
    print qq{\nPrint diagonal elements in vector S\n};  
    for my $s (@{$S_vec_ref}) { print qq{$s, }; }

    # Print elements of matrix U.
    print qq{\nPrint matrix U\n};  
    for my $r (0..$#{$U_mat_ref}) {
        for my $c (0..$#{$U_mat_ref->[$r]}) { print qq{$U_mat_ref->[$r][$c], } }; print qq{\n}; }

    # Print elements of matrix V.
    print qq{\nPrint matrix V\n};  
    for my $r (0..$#{$V_mat_ref}) {
        for my $c (0..$#{$V_mat_ref->[$r]}) { print qq{$V_mat_ref->[$r][$c], } }; print qq{\n}; }
    
=cut

=head1 DESCRIPTION

The singular value decomposition (SVD) is an important factorization of a rectangular real matrix - see
http://en.wikipedia.org/wiki/Singular_value_decomposition. Eigendecomposition is the factorization of a 
matrix into a canonical form, whereby the matrix is represented in terms of its eigenvalues and
eigenvectors - see http://en.wikipedia.org/wiki/Eigendecomposition_of_a_matrix. This module implements the 
SVD and Eigen decomposition routines of the The C GNU Scientific Library (GSL). It provides simple convinience methods in the
upper-level Math::GSL::Linalg::SVD namespace to perform these operations. Alternatively, it also provides direct access
to the C routines in the Math::GSL::Linalg::SVD::Matrix, Math::GSL::Linalg::SVD::Vector and
Math::GSL::Linalg::SVD::Eigen namespaces - see METHODS. 

=cut

=head1 METHODS

This is a C-Wrapper for the gsl SVD and Eigen decomp routines. Its provides two means of accessing them. First, a basic
OO-interface of convenience methods to allow simple use of the various sdv and eigen routines within the Math::GSL::Linalg::SVD namespaces. Second,
it allows you to use the various routines directly using an object interface for the various C structure types. These
exist within specific lower-level namespaces for convenience - see below.

=head2 Math::GSL::Linalg::SVD

=head3 new

Create a new Math:GSL::Linalg::SVD object.

    my $svd = Math::GSL::Linalg::SVD->new();
    # Pass verbose to turn on minimal messages.
    my $svd = Math::GSL::Linalg::SVD->new( { verbose => 1 } );

=head3 load_data
   
Used for loading data into object. Data is fed as a reference to a LoL within an anonymous hash using the named argument
'data'. 

    $svd->load_data( { data => [ 
                                    [qw/  9.515970281313E-01 1.230695618728E-01 /], 
                                    [qw/ -1.788010086499E-01 3.654739881179E-01 /], 
                                    [qw/  4.156708817272E-02  5.298288357316E-02 /], 
                               ] } );

=head3 decompose

Performs one of several different singular value decomposition algorithms on the loaded matrix (or computes eigenvalues
and eigenvectors) depending on argument passed with with 'algorithm' argument. To use the Golub-Reinsch algorithm 
implemented by C<gsl_linalg_SV_decomp> pass 'gd'. To use the modified Golub-Reinsch algorithm implemented by 
C<gsl_linalg_SV_decomp_mod> pass 'mod'. To use the one-sided Jacobi orthogonalization algorithm
implemented by C<gsl_linalg_SV_decomp_jacobi> pass 'jacobi'. To perform the eigenvalue and eigenvector calculations
implemented by C<gsl_eigen_symmv> pass 'eigen'. See
http://www.gnu.org/software/gsl/manual/html_node/Singular-Value-Decomposition.html for further details.

    # Perform svd using the Golub-Reinsch algorithm pass 'gd' or nothing.
    $svd->decompose();
    $svd->decompose( { algorithm => q{mod} } );
    $svd->decompose( { algorithm => q{jacobi} } );
    $eigen->decompose( { algorithm => q{eigen} } );


=head3 results

Used to access the results of the analysis. Called in LIST context. For svd an ordered LIST of the LoLs is returned
(corresponding to Vector S, Matrix U, Matrix V and Matrix A (see
http://www.gnu.org/software/gsl/manual/html_node/Singular-Value-Decomposition.html). See SYNOPSIS.

    my ($S_vec_ref, $U_mat_ref, $V_mat_ref, $original_data_ref) = $svd->results;

For eigen computation an ordered list of LoLs is returned corresponding to unordered eigenvalues, the eigenvectors (in
the same order as the eigenvalues) and the original data matrix. See
http://www.gnu.org/software/gsl/manual/html_node/Real-Symmetric-Matrices.html.
    
    my ($e_val_ref, $e_vec_ref, $original_data_ref) = $eigen->results;

    # Print eigenvalues along with corresponding eigenvectors.
    for my $i (0..$#{$e_val_ref}) {
        print qq{\nEigenvalue: $e_val_ref->[$i], };  
        print qq{\nEigenvector: }; 
        for my $vec_component (@{$e_vec_ref->[$i]}) { print qq{$vec_component, }; }; print qq{\n}; }

=head2 Math::GSL::Linalg::SVD::Matrix

This namespace functions as an interface to the C<gsl_matrix> C-structure typedef. 

=head3 new

    Name:           new
    Implements:     gsl_matrix_alloc
    Usage:          $gsl_matrix_pointer_as_perl_object = Math::GSL::Linalg::SVD::Matrix->new;
    Returns:        pointer to a gsl_matrix type as Perl object

=head3 set_matrix

    Name:           set_matrix
    Implements:     gsl_matrix_set
    Usage:          $gsl_matrix_pointer_as_perl_object->set_matrix($row, $col, $double_number);
    Returns:  

=head3 get_matrix

    Name:           matrix_get
    Implements:     gsl_matrix_get
    Usage:          $gsl_matrix_pointer_as_perl_object->set_matrix($row, $col);
    Returns:        scalar value

=head3 SV_decomp

    Name:           SV_decomp
    Implements:     gsl_linalg_SV_decomp
    Usage:          $gsl_matrix_pointer_as_perl_object->SV_decomp (...);
    Returns:  

=head3 SV_decomp_mod

    Name:           SV_decomp_mod
    Implements:     gsl_linalg_SV_decomp_mod
    Usage:          $gsl_matrix_pointer_as_perl_object->SV_decomp_mod (...);
    Returns:  

=head3 SV_decomp_jacobi
    
    Name:           SV_decomp_jacobi
    Implements:     gsl_linalg_SV_decomp_jacobi
    Usage:          $gsl_matrix_pointer_as_perl_object->SV_decomp_mod (...);
    Returns:  

=head3 Eigen_decomp

    Name:           Eigen_decomp
    Implements:     gsl_eigen_symmv
    Usage:          $gsl_matrix_pointer_as_perl_object->Eigen_decomp (...);
    Returns:  

=head2 Math::GSL::Linalg::SVD::Vector

This namespace functions as an interface to the C<gsl_vector> C-structure typedef. 

=head3 new

    Name:           new
    Implements:     gsl_vector_alloc
    Usage:          $gsl_vector_pointer_as_perl_object = Math::GSL::Linalg::SVD::Vector->new;
    Returns:        pointer to gsl_vector as perl object


=head3 set_vector

    Name:           vector_set
    Implements:     gsl_vector_set
    Usage:          $gsl_vector_pointer_as_perl_object->set_vector($row, $col, $double_number);
    Returns:  

=head3 get_vector

    Name:           vector_get
    Implements:     gsl_vector_get
    Usage:          $gsl_vector_pointer_as_perl_object->set_vector($row, $col)
    Returns:        scalar value

=head2 Math::GSL::Linalg::SVD::Eigen

This namespace functions as an interface to the C<gsl_eigen_symmv_workspace> C-structure typedef used as workspace for
the eigen decomposition routines of the gsl library. 

=head3 new

    Name:           new
    Implements:     gsl_eigen_symmv_alloc
    Usage:          $gsl_vector_pointer_as_perl_object = Math::GSL::Linalg::SVD::vector->new;
    Returns:        pointer to gsl_eigen_symmv type as perl object

=cut

sub new {
    my ( $class, $h_ref ) = @_;
    croak qq{\nArguments must be passed as HASH reference.} if ( ( $h_ref ) && ( ref $h_ref ne q{HASH} ) );
    my $verbose = 1 if ( ( exists $h_ref->{verbose} ) && ( $h_ref->{verbose} == 1 ) );
    my $self = {};
    $self->{flags}{verbose} = $verbose;
    bless $self, $class;
    return $self;
}

sub load_data {
    my ( $self, $h_ref ) = @_;
    croak qq{\nArguments must be passed as HASH reference.} if ( ( $h_ref ) && ( ref $h_ref ne q{HASH} ) );
    my $data_dirty = $h_ref->{data};
    &_data_checks($data_dirty);
    my $data = _deep_copy_references($data_dirty);

    my $A_m = scalar ( @{$data} );
    my $A_n = scalar ( @{$data->[0]} );

    print qq{\nData entry matrix is: m = $A_m * n = $A_n. Feeding data to object.} if $self->{flags}{verbose};
    
    $self->{data} = $data;
    $self->{A_m} = $A_m;
    $self->{A_n} = $A_n;

    #y set flag
    $self->{flags}{load} = 1;
    
    return;
}

sub _deep_copy_references { 
    my $ref = shift;
    if (!ref $ref) { $ref; } 
    elsif (ref $ref eq q{ARRAY} ) { [ map { _deep_copy_references($_) } @{$ref} ]; } 
    elsif (ref $ref eq q{HASH} )  { + {   map { $_ => _deep_copy_references($ref->{$_}) } (keys %{$ref}) }; } 
    else { die "what type is $_?" }
}
# don´t return on this one - kills its before recursion - over-kill. its only operating on a LoL

#/ just a sub not a method
sub _data_checks {
    my $data_a_ref = shift;
    my $rows = scalar ( @{$data_a_ref} );
    croak qq{\nI need some data - there are too few rows in your data.\n} if ( !$rows || $rows == 1 );
    my $cols = scalar ( @{$data_a_ref->[0]} );
    croak qq{\nI need some data - there are too few columns in your data.\n} if ( !$cols || $cols == 1 );
    for my $row (@{$data_a_ref}) {
        croak qq{\n\nData set must be passed as ARRAY references.\n} if ( ref $row ne q{ARRAY} );
        croak qq{\n\nAll rows must have the same number of columns.\n} if ( scalar( @{$row} ) != $cols );
    }
    return;
}

#/////////////////////////////////////////////////////// ANALYSIS /////////////////////////////////////////////////////

sub decompose {
    my ( $self, $h_ref ) = @_;
    croak qq{\nYou need to load some data first.} if ( !exists $self->{flags}{load});
    croak qq{\nArguments must be passed as HASH reference.} if ( ( $h_ref ) && ( ref $h_ref ne q{HASH} ) );
    # Golub-Reinsch / modified Golub-Reinsch / one-sided Jacobi orthogonalization
    exists $h_ref->{algorithm} || print qq{\nUsing default Golub-Reinsch algorithm for SVD.};
    my $sdv = exists $h_ref->{algorithm} ? $h_ref->{algorithm} : q{gd};
    if ( $sdv eq q{eigen} ) { $self->_eigen }
    else { $self->_svd($sdv) };
    return;
}

sub _svd {
    my ( $self, $sdv ) = @_;
    #y sdv specific check
    $self->_sdv_check();
    
    #croak qq{\nI don\x27t recognise that value for the \x27algorithm\x27 option - requires \x27gd\x27, \x27mod\x27 }
    #      . qq{or \x27jacobi\x27 (defaults#to \x27gs\x27 without option).} if ( $sdv !~ /\A(gd|mod|jacobi)\z/xms );

    my $data = $self->{data};
    my $A_m = $self->{A_m};
    my $A_n = $self->{A_n};

    my $A_mat = Math::GSL::Linalg::SVD::Matrix->new($A_m,$A_n);

    #y only if we have mod algorithm
    #my $workspace_mat = Math::GSL::Linalg::SVD::Matrix->new($A_n,$A_n) if ( $sdv eq q{mod} );
    
    my $V_mat = Math::GSL::Linalg::SVD::Matrix->new($A_n,$A_n);
    my $S_vec = Math::GSL::Linalg::SVD::Vector->new($A_n);

    #y only needed if either gd or mod - thus either put if postfix here or put in twice in the anonysubs below
    my $workspace_vec = Math::GSL::Linalg::SVD::Vector->new($A_n) if ( ( $sdv eq q{gd} ) || ( $sdv eq q{mod} ) );

    #$self->{C_objects} = {  A   =>  $A_mat, V   =>  $V_mat, S   =>  $S_vec, workspace_vector    => $workspace_vec, };

    #/ load matrix - as private sub not method
    &_load_matrix($A_mat, $data, $A_m, $A_n);

    my %algo = ( gd     =>  sub {   my $int = $A_mat->SV_decomp( $V_mat, $S_vec, $workspace_vec );                      },
                 mod    =>  sub {   my $workspace_mat = Math::GSL::Linalg::SVD::Matrix->new($A_n,$A_n) if ( $sdv eq q{mod} );
                                    my $int = $A_mat->SV_decomp_mod( $workspace_mat, $V_mat, $S_vec, $workspace_vec );  },
                 jacobi =>  sub {   my $int = $A_mat->SV_decomp_jacobi($V_mat, $S_vec );                                },
               );
            
    my $type = $algo{$sdv};
    croak qq{\nI don\x27t recognise that value for the \x27algorithm\x27 option - requires \x27gd\x27, \x27mod\x27 }
          . qq{or \x27jacobi\x27 (defaults#to \x27gs\x27 without option).} if ( !defined $type );
          #if ( $sdv !~ /\A(gd|mod|jacobi)\z/xms );

    $type->();

    my $d = [];
    $d = &_get_d ($S_vec, $A_n);
    
    #/ no method call on thingy so need to put the data directly into the object here
    $self->{d} = $d;

    #/ get U that is actually same matrix as A but with U data now - so its just as well we pre-stored the data as the original is gone
    my $U = [];
    $U = &_get_u ($A_mat, $A_m, $A_n);
    $self->{U} = $U;

    #/ get the V matrix
    my $V = [];
    $V = &_get_u ($V_mat, $A_n, $A_n);
    $self->{V} = $V;

    #y set flag for results
    $self->{flags}{svd} = 1;

    return;
}

sub _eigen {
    my $self = shift;
    $self->_eigen_check;
    my $data = $self->{data};
    my $A_m = $self->{A_m}; # checked: m == n 

    my $Eigen_mat = Math::GSL::Linalg::SVD::Matrix->new($A_m,$A_m);
    my $EV_mat = Math::GSL::Linalg::SVD::Matrix->new($A_m,$A_m);
    my $EV_vec = Math::GSL::Linalg::SVD::Vector->new($A_m);
    my $workpace_eigen = Math::GSL::Linalg::SVD::Eigen->new(4*$A_m);

    &_load_matrix($Eigen_mat, $data, $A_m, $A_m);

    my $int = $Eigen_mat->Eigen_decomp($EV_vec, $EV_mat, $workpace_eigen );

    my $e_vals = &_get_d ($EV_vec, $A_m);
    $self->{eigen_values} = $e_vals;
   
    #my $e_vecs = &_get_v ($EV_mat, $A_m);
    my $e_vecs = &_get_u ($EV_mat, $A_m, $A_m);
    $e_vecs = _transpose($e_vecs);
    $self->{eigen_vectors} = $e_vecs;
    
    #y set flag for results
    $self->{flags}{eigen} = 1;

    return;
}

# sub routine not method
sub _transpose {
    #y basic sub
    my $a_ref = shift;
    my $done = [];
    for my $col ( 0..$#{$a_ref->[0]} ) {
    push @{$done}, [ map { $_->[$col] } @{$a_ref} ];
    }
    return $done;
}

sub _eigen_check {
    my $self = shift;
    my $data = $self->{data};
    my $A_m = $self->{A_m}; 
    my $A_n = $self->{A_n};
    # twat:
    # croak qq{\nEigen decomposition requires a square matrix.} if ( $A_m == $A_n );
    croak qq{\nEigen decomposition requires a square matrix.} if ( $A_m != $A_n );
    return;
}

sub _sdv_check {
    my $self = shift;
    my $data = $self->{data};
    my $A_m = $self->{A_m}; 
    my $A_n = $self->{A_n};
    croak qq{\nSVD for matrix MxN with M<N not implemented in gsl.} if ($A_n > $A_m); # duh... A_m >= A_n
    return;
}

sub _load_matrix {
    my ( $A_mat, $data, $A_m, $A_n) = @_;

    for my $row ( (0..$A_m-1) ) {
        for my $col ( (0..$A_n-1) ) {
            $A_mat->matrix_set($row,$col,$data->[$row][$col]);
        }
    }
    # return $A_mat;
    return;
}

sub _get_d {
    my ($S_vec, $A_n) = @_;
    my $d = [];
    for my $row ( (0..$A_n-1) ) { 
        my $val = $S_vec->vector_get($row); 
        #y nao faz diferenenca aqui...
        #$d->[$row] = $val;
        push @{$d}, $val;
    }
    #/ as sub we´ll need to return the list and not put it into the object
    #$self->{d} = $d;
    # return;
    return $d;
}

sub _get_u {
    #/ no need for method just private sub
    #my ($self, $S_vec, $A_n) = @_;
    #/ get U that is actually same matrix as A but with U data now - so its just as well we pre-stored the data as the original is gone
    my ($A_mat, $A_m, $A_n) = @_;
    
    my $U = [];
    for my $row ( (0..$A_m-1) ) { 
        for my $col ( (0..$A_n-1) ) { 
            my $val = $A_mat->matrix_get($row,$col); 
           
            #/ can´t push - need to use each index individually!
            #push @{$U}, $val;
            $U->[$row][$col] = $val;
        } 
    }
    
    #/ as sub we´ll need to return the list and not put it into the object
    #$self->{d} = $d;
    # return;
    return $U;
}

sub results {
    my $self = shift;
    croak qq{\nThis method is called in LIST context.} if !wantarray;
    if ( ( $self->{flags}{svd} ) && ( $self->{flags}{eigen} ) ) { 
        croak qq{\nYou performed both SVD and Eigen decomp. Which did you want to do?};
    }
    elsif ( $self->{flags}{svd} ) { 
        print qq{\nPassing SVD results data.} if $self->{flags}{verbose};
        return $self->{d}, $self->{U}, $self->{V}, $self->{data};
    }
    # silly, but...
    elsif ( $self->{flags}{eigen} ) { 
        print qq{\nPassing Eigen results data.} if $self->{flags}{verbose};
        return $self->{eigen_values}, $self->{eigen_vectors}, $self->{data};
    }
    # perlcritic plesure...
    return;
}


1;

__END__

=head1 AUTHOR

Daniel S. T. Hughes <dsth@cpan.org>

=cut

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Daniel S. T. Hughes <dsth@cantab.net>. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See perlartistic.

=cut

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty for the software, to the extent permitted by
applicable law. Except when otherwise stated in writing the copyright holders and/or other parties provide the
software "as is" without warranty of any kind, either expressed or implied, including, but not limited to, the
implied warranties of merchantability and fitness for a particular purpose. The entire risk as to the quality and
performance of the software is with you. Should the software prove defective, you assume the cost of all necessary
servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing will any copyright holder, or any other
party who may modify and/or redistribute the software as permitted by the above licence, be liable to you for
damages, including any general, special, incidental, or consequential damages arising out of the use or inability
to use the software (including but not limited to loss of data or data being rendered inaccurate or losses
sustained by you or third parties or a failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of such damages.
Dr Daniel S. T. Hughes, E<lt>dsth@E<gt>

=cut
