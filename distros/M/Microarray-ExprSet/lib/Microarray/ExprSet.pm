package Microarray::ExprSet;

# Simple description of microarray data
# contains three elements
# data matrix
# feature (gene) names array
# sample names array

use List::Vectorize;
use Carp;
use strict;

our $VERSION = "0.11";

1;


sub new {

    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = { feature => undef,
                 phenotype => undef,
                 matrix => undef, 
                 error => undef,};
    bless($self, $class);
    return $self;
   
}


# probe name
sub feature {

    my $self = shift;
    
    return $self->{feature};

}

sub set_feature {
   
    my $self = shift;
    
    List::Vectorize::check_prototype(@_, '\@');
    
    my $feature = shift;
    
    $self->{feature} = $feature;
    
    return $self;

}

# sample name
sub phenotype {
     
    my $self = shift;
    
    return $self->{phenotype};

}

sub set_phenotype {
    
    my $self = shift;
    
    List::Vectorize::check_prototype(@_, '\@');
    
    my $phenotype = shift;
    
    $self->{phenotype} = $phenotype;
    
    return $self;
    
}

sub set_matrix {

    my $self = shift;
    
    List::Vectorize::check_prototype(@_, '\@');
    
    my $matrix = shift;
    
    # check whether it is a valid matrix
    my ($nr, $nc) = dim($matrix);
    if(!defined($nr) or !defined($nc)) {
        croak "ERROR: Not a valid matrix";
    }
    
    $self->{matrix} = $matrix;
    
    return $self;
    
}

sub matrix {
    
    my $self = shift;
    
    return $self->{matrix};

}

sub is_valid {
 
    my $self = shift;
    $self->{error} = undef;
    
    if(defined($self->matrix)) {
    
        my ($nr, $nc) = dim($self->matrix);
        
        if(!defined($nr) or !defined($nc)) {
            $self->{error} = "Not a matrix";
            return 0;
        }
        
        if(defined($self->feature)) {
            if(len($self->feature) != $nr) {
                $self->{error} = "Length of feature names is not identical to the number of matrix rows";
                return 0;
            }
        }
        
        if(defined($self->phenotype)) {
            if(len($self->phenotype) != $nc) {
                $self->{error} = "Length of phenotype names is not identical to the number of matrix columns";
                return 0;
            }
        }
    }
    else {
        $self->{error} = "Expression matrix is not defined";
        return 0;
    }
    
    return 1;
}


sub remove_empty_features {

    my $self = shift;
    
    my $old_feature = $self->feature;
    my $old_matrix = $self->matrix;
    
    if(is_empty($old_feature)) {
        carp "WARN: Feature names are empty. ";
    }
    elsif(! $self->is_valid) {
        croak $self->{error};
    }
    
    my $new_feature;
    my $new_matrix;
    
    for(my $i = 0; $i < len($old_feature); $i ++) {
    
        if($old_feature->[$i] !~ /^\s*$/) {
            push(@$new_feature, $old_feature->[$i]);
            push(@$new_matrix, $old_matrix->[$i]);
        }
    }
    
    $self->set_feature($new_feature);
    $self->set_matrix($new_matrix);
    undef($old_feature);
    undef($old_matrix);

    return $self;
}

sub n_feature {
    
    my $self = shift;
    
    return len($self->feature);

}

sub n_phenotype {
    
    my $self = shift;
    
    return len($self->phenotype);

}

# using mean or median
sub unique_features {
    
    my $self = shift;
    my $method = shift || "mean";
    
    my $fun;
    if($method eq "mean") {
        $fun = \&mean;
    }
    elsif($method eq "median") {
        $fun = \&median;
    }
    else {
        $fun = \&mean;
    }
    
    my $fh;
    my $feature = $self->feature;
    
    if(is_empty($feature)) {
        carp "WARN: Feature names are empty. ";
    }
    elsif(! $self->is_valid) {
        croak $self->{error};
    }
    
    for(my $i = 0; $i < len($feature); $i ++) {
        if($fh->{$feature->[$i]}) {
            push(@{$fh->{$feature->[$i]}}, $i);
        }
        else {
            $fh->{$feature->[$i]}->[0] = $i;
        }
    }

    my $new_feature;
    my $new_matrix;
    my $matrix = $self->matrix;
    foreach my $f (keys %$fh) {
    
        my $index = $fh->{$f};
        push(@$new_feature, $f);
        
        if(len($index) == 1) {
            push(@$new_matrix, $matrix->[$index->[0]]);
        }
        else {
            my $new_array;
            for(my $i = 0; $i < len($matrix->[0]); $i ++) {
                my $tmp_array;
                for(my $j = 0; $j < len($index); $j ++) {
                    
                    push(@$tmp_array, $matrix->[$index->[$j]]->[$i]);
                
                }
                push(@$new_array, &$fun($tmp_array));
            }
            push(@$new_matrix, $new_array);
        }
    }
    
    $self->set_feature($new_feature);
    $self->set_matrix($new_matrix);
    undef($feature);
    undef($matrix);

    return $self;
}

sub save {
    
    my $self = shift;
    
    List::Vectorize::check_prototype(@_, '$');
    
    my $file = shift;
    
    if(is_empty($self->feature)) {
        croak "ERROR: Feature names are required. ";
    } elsif(is_empty($self->phenotype)) {
        croak "ERROR: Phenotype names are required. ";
    } elsif(! $self->is_valid) {
        croak "ERROR: not a valid ".__PACKAGE__." object";
    }
    
    write_table($self->matrix, "file" => $file, "row.names" => $self->feature, "col.names" => $self->phenotype);
    
    return 1;
}


__END__

=pod

=head1 NAME

Microarray::ExprSet - Simple description of microarray data

=head1 SYNOPSIS

  use Microarray::ExprSet;
  
  my $mat = [[1, 2, 3, 4, 5, 6],
             [7, 8, 9, 10, 11, 12],
             [13, 14, 15, 16, 17, 18],
             [19, 20, 21, 22, 23, 24],
             [25, 26, 27, 28, 29, 30],
             [31, 32, 33, 34, 35, 36]];
  my $probe = ["gene1", "gene2", "gene2", "gene3", "", "gene4"];
  my $sample = ["treatment", "treatment", "treatment", "control", "control", "control"];
  
  my $expr = Microarray::ExprSet->new();
  $expr->set_matrix($mat);
  $expr->set_feature($probe);
  $expr->set_phenotype($sample);
  # or simplified as
  $expr->set_matrix($mat)->set_feature($probe)->set_phenotype($sample);
  
  # whether the data valid
  $expr->is_valid;  # 1 or 0
  
  # do some preprocess
  $expr->remove_empty_features();
  # combine duplicated features, order of features is shuffled
  $expr->unique_features("mean");  # you can use "median" too
  
  # now you can get content of the object
  my $new_mat = $expr->matrix;
  my $new_probe = $expr->feature;
  my $new_sample = $expr->phenotype;
  my $n_probe = $expr->n_feature;
  my $n_sample = $expr->n_phenotype;
  
  # save into file
  $expr->save("some-file");

=head1 DESCRIPTION

The C<Microarray::ExprSet> class object describes the data structure of microarray
data. It contains three elements: 1) data matrix
that stores the expression value; 2) array of features that are the probe names
or gene IDs; 3) array of phenotypes that are the settings of samples (e.g. control vs
treatment). Other information about the microarray experiment such as the protocal
or sample preparation is not included in this object. This module aims to provide the 
minimum information that a microarray data needs.

Usually the C<Microarray::ExprSet> object is created by other modules such as
L<Microarray::GEO::SOFT>.

=head2 Subroutines

=over 4

=item C<new>

Initial or reset a C<Microarray::ExprSet> class object.

=item C<$expr-E<gt>set_matrix(MATRIX)>

Argument is the expression value matrix which is stored in an array reference of array
references.

=item C<$expr-E<gt>set_feature(ARRAY_REF)>

Set the feature names. The length of features should be equal to the number of 
rows of the expression value matrix. You can think each feature is a probe or a gene.

=item C<$expr-E<gt>set_phenotype(ARRAY_REF)>

Set the phenotype names. The length of phenotypes should be equal to the number
of columns of the expression value matrix. You can think the phenotypes are the experimental sample names.

=item C<$expr-E<gt>matrix>

Get expression value matrix

=item C<$expr-E<gt>feature>

Get feature names, array reference.

=item C<$expr-E<gt>phenotype>

Get phenotype names, array reference.

=item C<$expr-E<gt>n_feature>

Get the number of features

=item C<$expr-E<gt>n_phenotype>

Get the number of phenotypes

=item C<$expr-E<gt>is_valid>

whether your object is valid. If, for some reason, the expression matrix is not
a standard format of matrix, it would return 0. If feature names are defined but
the length of the feature names is not identical to the number of matrix rows,
it would return 0. If phenotype names are defined but the length of the phenotype
names is not identical to the number of matrix columns, it would return 0.

=item C<$expr-E<gt>remove_empty_features>

Some features may not have names, so it is necessary to eliminate these features
without any names.

=item C<$expr-E<gt>unique_features('mean' | 'median')>

It is usually that features are measured repeatly, especially when you map probe id
to gene ID. Some analysis procedures need unified features. The argument can be 
set to choose the method for multiple feature merging. Note the order of arrays
would be shuffled.

=item C<$expr-E<gt>save(filename)>

Save to file as tables. 

=back

=head1 AUTHOR

Zuguang Gu E<lt>jokergoo@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Zuguang Gu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Microarray::GEO::SOFT>

=cut
