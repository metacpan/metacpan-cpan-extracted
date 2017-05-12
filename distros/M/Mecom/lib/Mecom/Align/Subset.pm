package Mecom::Align::Subset;


use 5.006;
use strict;
no strict "refs";
use warnings;
use Carp;
use Bio::SeqIO;
use base("Bio::Root::Root");


###############################################################################
# Class data and methods
###############################################################################
{  
    # A list of all attributes wiht default values and read/write/required properties
    my %_attribute_properties = (
        _file => ["????", "read.required"],
        _format    => ["????", "read.required"],
        _identifiers   => ["????", "read.write"   ],
        _sequences => ["????", "read.write"   ],
        _seq_length=> [0     , "read.write"   ]
    );
    
    # Global variable to keep count of existing objects
    my $_count = 0;
    
    # The list of all attributes
    sub _all_attributes {
        keys %_attribute_properties;
    }
    
    # Check if a given property is set for a given attribute
    sub _permissions{
        my ($self,$attribute, $permissions) = @_;
        $_attribute_properties{$attribute}[1] =~/$permissions/;
    }
    
    # Return the default value for a given attribute
    sub _attribute_default{
        my ($self,$attribute) = @_;
        $_attribute_properties{$attribute}[0];
    }
    
    # Manage the count of existing objects
    sub get_count{
        $_count;
    }
    sub _incr_count{
        ++$_count;
    }
    sub _decr_count{
        --$_count;
    }
    
}
#
# The constructor of the class
#
sub new {
    
    my ($class, %arg) = @_;
    my $self = bless {}, $class;
    
    foreach my $attribute ($self->_all_attributes()){
        
        # E.g. attribute = "_name", argument = "name"
        my ($argument) = ($attribute =~ /^_(.*)/);
        
        # If explicitly given
        if(exists $arg{$argument}){
            $self->{$attribute} = $arg{$argument};
        }
        
        # If not given but required
        elsif($self->_permissions($attribute, 'required')){
            croak("No $argument attribute as required");
        }
        
        # Set to default
        else{
            $self->{$attribute} = $self->_attribute_default($attribute);            
        }
        
    }
    
    # Called $class because it is a gobal method
    $class->_incr_count;
    
    $self->_extract_sequences;
    return $self;
    
}


#
# Obtaining the sequences in a Array
#
sub _extract_sequences{
    
    my $self = $_[0];
        
    my @identifiers;
    my @sequences;
    
    my $seqIO = Bio::SeqIO->new(
                             -file   => $self->get_file,
                             -format => $self->get_format
                            );
    
    while( my $seq = $seqIO->next_seq){
        
        my $sequence_string = $seq->seq;
        $sequence_string =~ s/\s//g;
        
        push(@identifiers, $seq->id);
        $self->_verify_chain($sequence_string);
        push(@sequences, $sequence_string);
        
    }
    
    $self->set_identifiers(\@identifiers);
    $self->set_sequences(\@sequences);
    
}



#
# Build a subset
#
sub build_subset{
    
    my ($self, $subset) = @_;
    
    
    # Initialite array for the new sequences
    my @new_sequences = ();
    
    for(my $i=0;$i<=$#{$self->get_sequences};$i++){
        # Initialite a new string for the new sequence
        my $new_sequence = "";
        for my $index (@{$subset}){
            if(($index-1)*3 > length(${$self->get_sequences}[$i])){ last }
            $new_sequence.= substr(${$self->get_sequences}[$i],($index-1)*3,3);
        }
        push(@new_sequences, $new_sequence);
    }
    
    my @identifiers   = @{$self->get_identifiers};
    # Create the new align object
    my $aln_obj = Bio::SimpleAlign->new();
    
    # Build a new Bio::LocatableSeq obj for each sequence
    for(my $i=0;$i<=$#identifiers;$i++){
        
        my $id = substr($identifiers[$i],0,9);
        
        #my $iden_plus_num = $id;
        # $i is for my self identifier adding, but it is bad for merge alignments
        my $iden_plus_num = $i.$id;
        
        # Create such object
        my $newSeq = Bio::LocatableSeq->new(-seq   => $new_sequences[$i],
                                            -id    => substr($iden_plus_num,0,9),
                                            -start => 0,
                                            -end   => length($new_sequences[$i]));
        
        # Append the new sequence object to the new alignmen object
        $aln_obj->add_seq($newSeq);
        
    }
    
    # Once the loop is finished, return the alignment object
    # with all the sequences appended.
    return $aln_obj;
    
}

###############################################################################
# Auxiliary methods
###############################################################################
{
    #
    # Set the sequence length of the whole alignment
    #
    sub _set_sequence_length{
        my $self = $_[0];
        $self->{_seq_length} = $_[1];
    }
    
    #
    # Check if a the length of a given sequence match with the length of
    # the whole alignment.
    #
    sub _check_sequence_length{
        my $self = $_[0];
        my $tested_sequence_length = $_[1];
        $tested_sequence_length == $self->get_seq_length ? return 1 : return 0;
    }
    
    #
    # Verifies the integrity of a given sequence
    #
    sub _verify_chain{
        
        my ($self,$sequence) = @_;
        my $seq_length = length($sequence);
        
        
        # 1. The chain must be a DNA sequence
        $self->_isdna($sequence) ? 1 : $self->warn("\nThe following sequence does not seems as a dna/rna (ATGCU) sequence:\n\n<< $sequence >>\n");
        
        # 2. Also, all the sequences must be equal. But if $_sequence_length
        # has not been updated, it takes the value of the length of this sequence.
        if($self->get_seq_length == 0){
            # The input file must be wrapped (non untermitated codons)
            $seq_length % 3 == 0 ? 1 : $self->throw("The sequence length is not multiple of 3 ($seq_length)");
            $self->_set_sequence_length($seq_length);
        }else{
            $self->_check_sequence_length($seq_length) ? 1 : croak("A sequence length does not match with the length of the whole alignment");
        }
        return 1;
        
    }
    
    #
    # Verifies if a given string is a DNA sequence
    #
    sub _isdna{
        my ($self,$sequence) = ($_[0],uc($_[1]));
        if($sequence =~ /^[ACGTU]+$/){
             return 1;
        }else{
             return 0;
        }
    }
    
    
}
###############################################################################


###############################################################################
# Accessor Methods
###############################################################################
# This kind of method is called Accesor
# Method. It returns the value of a key
# and avoid the direct acces to the inner
# value of $obj->{_file}.
###############################################################################
sub get_file { $_[0] -> {_file} }
sub get_format    { $_[0] -> {_format}    }
sub get_sequences { $_[0] -> {_sequences} }
sub get_identifiers   { $_[0] -> {_identifiers}   }
sub get_seq_length{ $_[0] -> {_seq_length}}
###############################################################################


###############################################################################
# Mutator Methods
###############################################################################
sub set_file { my ($self, $file) = @_;
                    $self-> {_file} = $file if $file;
                  }
sub set_format    { my ($self, $format) = @_;
                    $self-> {_format} = $format if $format;
                  }
sub set_identifiers   { my ($self, $identifiers) = @_;
                    $self-> {_identifiers} = $identifiers if $identifiers;
                  }
sub set_sequences { my ($self, $sequences) = @_;
                    $self-> {_sequences} = $sequences if $sequences;
                  }
###############################################################################





1;
