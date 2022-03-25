#!/usr/bin/env perl

# Gibbs.pm v1.1
# Author: MH Seabolt
# Last updated: 2022-03-22

# SYNOPSIS:
# A Perl object to instantiate a Gibbs motif sampler tailored for biological sequence data.
# Constructs an object (the Gibbs sampler) with some data passed to the constructor,
# which can then be randomly sampled in order to identify potentially interesting "most mutually similar"
# sequence motifs.

# Note: some of the methods in this class print output directly to the terminal via STDERR.
# This can be redirected or captured as desired.

##################################################################################
# The MIT License
#
# Copyright (c) 2022 Matthew H. Seabolt
# TO DO:
# Include a class method to determine the probability of finding a "significant"
# motif of length *k* by random chance, given the length of the sequences that 
# are given to the Gibbs object. This is different from an e-value (e.g. Blast) 
# since that probability is based on the database size.
#
# Permission is hereby granted, free of charge, 
# to any person obtaining a copy of this software and 
# associated documentation files (the "Software"), to 
# deal in the Software without restriction, including 
# without limitation the rights to use, copy, modify, 
# merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom 
# the Software is furnished to do so, 
# subject to the following conditions:
#
# The above copyright notice and this permission notice 
# shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
# ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
##################################################################################

package Gibbs;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();			 #Import from other packages

use strict;
use warnings;
use List::Util qw(sum min max first);
use Scalar::Util;
use Storable qw(dclone);
use Carp;
our $AUTOLOAD;
use version; our $VERSION = version->declare("v1.1");


################################################################################## 

# Class data and methods 
# Attributes 
{
	# _states and _adj are inherited from Markov parent class
	my %_attribute_properties = (
		_k						=> 3,					# the number of iterations for which nothing changing will be considered convergence, Default 3
		_seqs					=> [ ],					# an anon array containing all the DNA sequences we are searching/sampling from
		_motif_len				=> 7,					# the length of the motif we are searching for, Default 7
		_alphabet				=> '',					# the set of possible symbols available
		_samples				=> [ ],					# a list of the samples we pull, will be updated each iteration
		_profiles				=> [ ],					# a list of the last k profiles, so that we can tell when we've reached convergence
		_t						=> '',					# the number of DNA sequences
		_n 						=> '',					# the length of the DNA sequences
	);
	
	# Global variable counter
	my $_count = 0;
	
	# Return a list of all attributes
	sub _all_attributes	{
		keys %_attribute_properties;
	}
	
	# Return the default value for a given attribute
    sub _attribute_default 	{
     	my( $self, $attribute ) = @_;
        	$_attribute_properties{$attribute};
    	}
    
	# Manage the count of existing objects
	sub get_count	{
		$_count;
	}
	sub _incr_count	{
		++$_count;
	}
	sub _decr_count	{
		--$_count;
	}	
}

############################################################
#                       CONSTRUCTORS                       #
############################################################

# The contructor method
# Construct a new graph (my $node = Markov->new() );
# Returns a scalar reference to a
sub new				{
	my ( $class, %arg ) = @_;
	
	# Create the new object
	my $self = bless {}, $class;

	foreach my $attribute ( $self->_all_attributes() ) {
        	# E.g. attribute = "_name",  argument = "name"
        	my ($argument) = ( $attribute =~ /^_(.*)/ );
        	# If explicitly given
        	if (exists $arg{$argument}) 	{
            	$self->{$attribute} = $arg{$argument};
        	}
        	else	{
            	$self->{$attribute} = $self->_attribute_default($attribute);
        	}
   	}
	
	# Confirm that the DNA attribute exists, then check all sequences are the same length
	if ( not $self->{_seqs} )	{
		warn "Gibbs->new() WARNING: DNA attribute does not exist!\n";
		return;
	}
	
	my $all_same_flag = $self->_all_the_same_length( $self->{_seqs} );
	if ( $all_same_flag == 0 )	{
		warn "Gibbs->new() WARNING: DNA sequences are not all the same length!\n";
		return;
	}
	
	# Set the alphabet set of characters
	my %Uniques;
	foreach my $sequence ( @{ $self->{_seqs} } )	{
		my @seq = split('', $sequence);
		$Uniques{$_} = 1 foreach ( @seq );
	}
	my @alphabet = keys %Uniques;
	$self->{_alphabet} = \@alphabet;
	
	# Set t and n
	$self->{_t} = scalar @{$self->{_seqs}};
	$self->{_n} = length $self->{_seqs}->[0];
	
	# All other attributes should have default values set which will at least allow us to run
	
   	# Return the new object
    $class->_incr_count();
	return $self;
}

# The clone method
# All attributes are copied from the calling object, unless specifically overriden
# Called from an existing object ( Syntax: $cloned_obj = $obj->clone(); )
sub clone	{
	my ( $caller, %arg ) = @_;
	# Extract the class name from the calling object
	my $class =ref($caller);
		
	# Create a new object
	my $self = bless {}, $class;
		
	foreach my $attribute ( $self->_all_attributes() )	{
		my ($argument) = ( $attribute =~ /^_(.*)/ );
			
		# If explicitly given
		if ( exists $arg{$argument} )	{
			$self->{$attribute} = $arg{$argument};
		}
			
		# Otherwise, copy attribute of new object from the calling object
		else	{
			$self->{$attribute} = $caller->{$attribute};
		}
	}
	$self->_incr_count();
	return $self;
}

#######################################
# Autoload getters and setters
sub AUTOLOAD {
    	my ( $self, $newvalue ) = @_;
    	my ( $operation, $attribute ) = ( $AUTOLOAD =~ /(get|set)(_\w+)$/ );
    
    	# Is this a legal method name?
    	unless( $operation && $attribute ) {
        	croak "Method name $AUTOLOAD is not in the recognized form (get|set)_attribute\n";
    	}
    	unless( exists $self->{$attribute} ) {
        	croak "No such attribute $attribute exists in the class ", ref($self);
    	}

    	# Turn off strict references to enable "magic" AUTOLOAD speedup
    	no strict 'refs';

    	# AUTOLOAD accessors
    	if( $operation eq 'get' ) 	{
        	# Install this accessor definition in the symbol table
        	*{$AUTOLOAD} = sub {
            	my ($self) = @_;
          	$self->{$attribute};
     	};
    }
    # AUTOLOAD mutators
    elsif( $operation eq 'set' ) 	{
		# Set the attribute value
        	$self->{$attribute} = $newvalue;

        	# Install this mutator definition in the symbol table
        	*{$AUTOLOAD} = sub {
        		my ($self, $newvalue) = @_;
            	$self->{$attribute} = $newvalue;
        	};
    }

    # Turn strict references back on
    use strict 'refs';

    # Return the attribute value
    return $self->{$attribute};
}

# When an object is no longer being used, garbage collect it and adjust count of existing objects
sub DESTROY	{
	my ( $self ) = @_;
	$self->_decr_count();
}

############################################################
#                   PUBLIC SUBROUTINES                     #
############################################################

# Start a sample counter -- all print statements within this package automatically go to STDERR
my $random_gibbs_sample_count = 0;

# Samples a random set and prints a score
sub sample	{
	my ( $self, $nsamples ) = @_;
	my @motifs;
	foreach my $i ( 1 .. $nsamples )	{
		my $sample = $self->_gibbs_sample();
		push @motifs, $sample;
	}
	my $best_motif =  $self->_max_score( \@motifs );
	return $best_motif;
}

# These functions are just aliases of sample() above
sub gibbs			{	my ( $self, $nsamples ) = @_;  return $self->sample($nsamples); 	}
sub gibbs_sample	{	my ( $self, $nsamples ) = @_;  return $self->sample($nsamples); 	}
sub search 			{	my ( $self, $nsamples ) = @_;  return $self->sample($nsamples); 	}
sub gibbs_search	{	my ( $self, $nsamples ) = @_;  return $self->sample($nsamples); 	}
sub sample_motif	{	my ( $self, $nsamples ) = @_;  return $self->sample($nsamples); 	}
sub find_motif		{	my ( $self, $nsamples ) = @_;  return $self->sample($nsamples); 	}

		
# Simply prints an array with each element on a new line		
sub print_matrix	{
	my ( $self, $list ) = @_;
	print STDERR join("\n", @{$list});
}

# Show where the motif is in each sequence, but nicely :)
sub show_motif	{
	my ( $self, $starting_positions ) = @_;
	for ( my $i=0; $i < $self->{_t}; $i++ )	{
		my $sequence = $self->{_seqs}->[$i];
		my $starting_position = $starting_positions->[$i];
		my $a = lc ( substr($sequence, 0, $starting_position) );
		my $b = uc ( substr($sequence, $starting_position, $self->{_motif_len} ) );
		my $c = lc ( substr($sequence, ($starting_position + $self->{_motif_len})) );
		print STDERR "$a$b$c\n";
	}
}

# Print a given profile to an output file
sub print_profile	{
	my ( $self, $filename, $mode ) = @_;
	my %Profile = %{ $self->{_profiles}->[-1] };
	
	# Sanity check
	$mode = ( $mode && $mode eq ">>" )? ">>" : ">";
	$filename = ( $filename )? $filename : "--";
	
	# Set the output filehandle
	my $succout = open( OUT, "$mode", "$filename" ) if ( $filename ne "--" );
	my $fhout;
	if ( $succout )		{	$fhout = *OUT;		}
	else				{	$fhout = *STDOUT;	}
	
	# Print to filehandle
	print $fhout "$_\t", join("\t", @{$Profile{$_}}, "\n") foreach ( sort keys %Profile );
	close $fhout if ( $succout );
}

############################################################
#         SANITY-CHECKING PROBABILITY SUBROUTINES          #
############################################################

# Additional public utility functions to determine the probability that a random, unrelated kmer of size k
# is present in M of the N sequences of equal length L (and an alphabet of size s), potentially leading us to misleading results.
#
# Here, we are making the simplifying assumptions that the frequency distribution of kmers is Poisson,
# and the distribution of symbols in the alphabet are independent and identical (IID).

# Returns the minimum (suggested) sequence length such that the probability of a kmer of size k occuring in M sequences is less than or equal to a given probability p.
# This is useful to help determine if the sequences being searched for motifs are reasonably likely to contain random, confounding motifs that are likely to just be "noise". 
sub minimum_suggested_sequence_length		{
	my ( $self, $prob, $m, $k, $s ) = @_;
	
	# Sanity check incoming parameters
	$k = ( $k && $k > 0 )? $k : $self->{_motif_len};		# Set $k to the kmer size in the Gibbs object if this parameter is not given
	$m = ( $m && $m > 0 )? $m : $self->{_t};				# Set $m to the total number of sequences if this parameter is not given
	$s = ( $s && $s > 0 )? $s : scalar @{$self->{_alphabet}};
	$prob = ( $prob && $prob > 0.0 && $prob <= 1.0 )? $prob : 0.01;				# Set $prob to a default value of 0.01
	my $pK = (1 / $s)**$k;				# Probability of any random k-sized kmer using the given alphabet
	
	# Compute minimum suggested length at the given probability threshold
	my $length = ($k-1) - $s**$k * log(1 - $prob**(1/$m));
	return int $length;
}

# Returns the Poisson probability of identifying a random, non-target kmer of length k from M sequences
sub nontarget_motif_probability		{
	my ( $self, $m, $k, $L, $s ) = @_;
	
	# Sanity check incoming parameters
	$k = ( $k && $k > 0 && $k <= $self->{_n} )? $k : $self->{_motif_len};		# Set $k to the kmer size in the Gibbs object if this parameter is not given
	$m = ( $m && $m > 0 && $m <= $self->{_t} )? $m : $self->{_t};				# Set $m to the total number of sequences if this parameter is not given
	$s = ( $s && $s > 0 )? $s : scalar @{$self->{_alphabet}};
	$L = ( $L && $L > 0 )? $L : $self->{_n};
	
	# Define some additional parameters for Poisson probability
	my $pK = (1 / $s)**$k;				# Probability of any random k-sized kmer using the given alphabet
	my $lambda = ($L - ($k-1))*$pK;		# Poisson parameter lambda
	
	# Compute Poisson probability of encountering a random motif under the given parameters
	my $prob = (1 - exp(-$lambda))**$m;		
	return sprintf("%3.4f", $prob);
}

############################################################
#                   PRIVATE SUBROUTINES                    #
############################################################

# Returns TRUE (1) if everything in a list has the same length as everything else
sub _all_the_same_length	{
	my ( $self, $list ) = @_;
	for ( my $i=0; $i < scalar @{$list}; $i++ )	{
		if ( length $list->[$i] != length $list->[0] )	{
			return 0;
		}
	}
	# If we make it this far, then everything is the same
	return 1;
}		

# Returns TRUE (1) if everything in a list has the same value as everything else
sub _all_the_same_value	{
	my ( $self, $list ) = @_;
	foreach my $item ( @{$list} )	{
		if ( $item != $list->[0] || $item ne $list->[0] )	{
			return 0;
		}
	}
	# If we make it this far, then everything is the same
	return 1;
}	

# Returns TRUE (1) if everything in a list has the same value as everything else
# This is more of a quick-and-dirty comparison, but it should get the job done well enough.
sub _all_the_same_hashes	{
	my ( $self, $list ) = @_;
	my @ref_keys = sort keys %{ $list->[0] };
	
	# Compare the remaining hashes in the list to the reference hash
	for ( my $h=0; $h < scalar @{$list}; $h++ )		{	
		my @keys = sort keys %{$list->[$h]};

		# Check the number of keys and number of values
		return 0 if ( scalar @ref_keys != scalar @keys ); 

		# Compare the values of the hashes
		foreach my $key ( @ref_keys )	{
			return 0 if ( not exists $list->[$h]->{$key} );
			my @values = @{ $list->[$h]->{$key} };
			my @ref_values = @{ $list->[0]->{$key} };
			for ( my $v=0; $v < scalar @ref_values; $v++ )	{
				return 0 if ( $ref_values[$v] != $values[$v] );
			}
		}
	}
	# If we make it this far, then everything is the same
	return 1;
}

# Checks if the most recent *k* profiles have converged
sub _check_convergence	{
	my ( $self ) = @_;
	my $k = $self->get_k;
	my @last_k_profiles = @{$self->{_profiles}};
	if ( scalar @last_k_profiles < $k )	{
		return 0;
	}
	else	{
		return $self->_all_the_same_hashes( \@last_k_profiles );
	}
}

# Samples a random set and prints a score
sub sample_random_starting_positions	{
	my ( $self, $nsamples ) = @_;
	my @motifs;
	foreach my $i ( 1 .. $nsamples )	{
		my $sample = $self->gibbs_sample();
		push @motifs, $sample;
	}
	my $best_motif =  $self->max_score( \@motifs );
	return $best_motif;
}
		
# Randomly selects starting positions in each string, disallowing any starting positions
# that would cause the motif substring to overflow the length of the sequence.
sub _get_starting_positions		{
	my ( $self ) = @_;
	my @start_pos;
	
	foreach my $i ( 1 .. $self->{_t} )	{
		push @start_pos, int(rand($self->{_n} - $self->{_motif_len}));
	}
	return \@start_pos;
}

# Generates a normalized profile from the sampled motif matrix
sub _create_profile 		{
	my ( $self, $matrix ) = @_;
	my %Profile = ();
	my $alphabet = $self->{_alphabet};
	
	# Initialize a hash where keys are each possible symbol in our alphabet,
	# and values are an anon array, where each index represents a position in the sampled motif
	foreach my $nucleotide ( @{$alphabet} )	{
		for ( my $i=0; $i < $self->{_motif_len}; $i++ )	{
			push @{$Profile{$nucleotide}}, 0;
		}
	}
	
	# Count the occurences of each symbol
	for ( my $i=0; $i < $self->{_t}; $i++ )	{
		for ( my $j=0; $j < $self->{_motif_len}; $j++ )	{
			$Profile{ $matrix->[$i]->[$j] }->[$j] += 1;
		}
	}
	
	# Normalize the counts
	foreach my $nucleotide ( @{$alphabet} )	{
		for ( my $j=0; $j < $self->{_motif_len}; $j++ )	{
			$Profile{$nucleotide}->[$j] /= $self->{_t};
			$Profile{$nucleotide}->[$j] = sprintf "%3.3f", $Profile{$nucleotide}->[$j];
		}
	}
	
	return \%Profile;	
}		

# Normalizes a list of numerical values		
sub _normalize	{
	my ( $self, $dist ) = @_;
	my $probabilities;
	my $total = sum @{$dist};	
	foreach my $probability ( @{$dist} )	{
		push @{$probabilities}, ($probability/$total);
	}
	return $probabilities;
}

# Compute the joint probability of sampling a particular profile
sub _get_generation_probability		{
	my ( $self, $lmer, $profile ) = @_;
	my $prob = 1;		# Initialize to 1 for easy multiplication
	
	# The probability of the whole string is the product of the probability of each letter being generated in its position over all letters.
	my @profile_probs;
	for ( my $i=0; $i < $self->{_motif_len}; $i++ )	{
		push @profile_probs, $profile->{ $lmer->[$i] }->[$i];
	}
	
	# It's possible that everything is 0. Return 0 if that's the case
	return 0 if ( sum @profile_probs == 0 );
	
	# Otherwise, find the smallest probability greater than 0
	my @filter = grep { $_ != 0 } @profile_probs;
	my $min_prob = min @filter;

	# Compute the joint probability
	foreach my $profile_prob ( @profile_probs )	{
		if ( $profile_prob == 0 )	{
			$prob *= ( $min_prob * (10**-10) );		# We are using a very tiny number to approximate 0 here, since we may encounter zeros that we dont want to actually multiply by.
		}
		else	{
			$prob *= $profile_prob;
		}
	}
	return $prob;
}

# Reads a profile and returns the consensus motif
sub _get_motif 	{
	my ( $self, $profile ) = @_;
	my $alphabet = $self->{_alphabet};
	my @motif;
	
	# Get the most probable letter at each position in the profile
	for ( my $i=0; $i < $self->{_motif_len}; $i++ )	{
		my @candidates;
		foreach my $letter ( @{$alphabet} )		{
			my @tmp = ( $letter, $profile->{$letter}->[$i] );
			push @candidates, \@tmp;
		}
		push @motif, $self->_max_score( \@candidates )->[0];
	}
	# Join the motif array into a string and return
	return join("", @motif);
}

# Calculate the score of a given profile
sub _get_profile_score		{
	my ( $self, $profile ) = @_;
	my @list;
	
	# The score of the profile is the sum of the most frequent letter in every position in the profile's indices
	# For each position in the motif, get the column from the profile.
	# Then take the maximum value of the column and sum it with all the other colMaxes.
	for (my $i=0; $i < $self->{_motif_len}; $i++ )	{
		my @col;
		foreach my $freq ( values %{$profile} )	{
			push @col, $freq->[$i];
		}
		push @list, max @col;
	}
	return sum @list;
}

# Returns the maximum valued tuple from a list of tuples, where the value to maximize is the second element in the tuple.		
sub _max_score	{
	my ( $self, $tuples ) = @_;
	my $max = -10**10;			# Approximate a very low number as the initial max
	my $tup;
	
	for ( my $i=0; $i < scalar @{$tuples}; $i++ )	{
		if ( $tuples->[$i]->[1] >= $max )	{
			$max = $tuples->[$i]->[1];
			$tup = $tuples->[$i];
		}
		else	{
			next;
		}
	}
	return $tup;
}		

# This package's way of sampling a normalized distribution		
sub _choose_from_distribution	{
	my ( $self, $dist ) = @_;
	my $rand = rand();			# Gets a random value between 0 and 1
	
	# Return the index of a randomly sampled element in the distribution
	for ( my $p=0; $p < scalar @{$dist}; $p++ )	{
		$rand -= $dist->[$p];
		if ( $rand <= 0 )	{
			return $p;
		}
		# Otherwise, keep going
	}
	# If we got here, then there are problems :)
	warn "Gibbs::choose_from_distribution WARNING: Choosing from a distribution is hard. Did you make sure the distribution was normalised?\n";
	return;
}		

# Randomly select an element from a list and return both the element and the randomly chosen index
sub _random_choice	{
	my ( $self, $list ) = @_;
	my $idx = int(rand(scalar @{$list}));
	return ( $list->[$idx], $idx );
}


####################################
# The actual Gibbs sampling function
sub _gibbs_sample 		{
	my ( $self, $motif_k ) = @_;
	$random_gibbs_sample_count++;
	
	# Extra quality-of-life addition:
	# If $motif_k is passed as an argument, update this parameter in the object.
	if ( $motif_k && int($motif_k) == $motif_k && $motif_k > 0 && $motif_k < $self->{_n} )	{
		$self->{_motif_len} = $motif_k;
	}
	
	
	# Get starting positions and reset our lists of samples and profiles
	my $starting_positions = $self->_get_starting_positions;
	$self->{_samples} = [ ];
	$self->{_profiles} = [ ];

	my $c = 0;

	while ( $self->_check_convergence != 1 )		{
		# Generate new lmers that come from starting positions
		my $tuples;
		my $DNA = $self->{_seqs};		
		for ( my $i=0; $i < $self->{_t}; $i++ )	{
			my $sub = substr( $self->{_seqs}->[$i], $starting_positions->[$i], $self->{_motif_len} );
			my @submotif = split('', $sub);
			push @{$tuples}, \@submotif;
		}
		
		# Choose a sequence from the DNA sequences randomly,
		# then remove it

		my ( $sequence, $index ) = $self->_random_choice( $self->{_seqs} );
		splice( @{$self->{_seqs}}, $index, 1);		# Careful here, make sure that we are assigning the spliced list correctly to $self->DNA
		
		# Make a new profile from the starting positions and save it for convergence checking
		my %Profile = %{ $self->_create_profile( $tuples ) };
		push @{$self->{_profiles}}, \%Profile;
	
		# If saving this profile overflows the profile buffer, then get rid of the odlest profile in it
		if ( scalar @{$self->{_profiles}} > $self->{_k} )	{
			my $trash = shift @{$self->{_profiles}};
		}
		
		# This is just to check how many loops is going and prints the profile itself
		$c++;
		print STDERR "\n----------------------------------------- \n";
		print STDERR "Sample: $random_gibbs_sample_count          Conv.Iter: $c \n";
		print STDERR "----------------------------------------- \n";
		print STDERR "$_\t", join("\t", @{$Profile{$_}}, "\n") foreach ( sort keys %Profile );
		
		
		
		# For each position i in the chosen DNA sequence, find the probability
		# that the lmer starting in this position is generated by the profile
		my $probs_ref;
		for ( my $i=0; $i < ($self->{_n}-$self->{_motif_len}); $i++ )					{
			my $lmer = substr($sequence, $i, $self->{_motif_len});
			my @lmer = split('', $lmer);
			my $prob = $self->_get_generation_probability( \@lmer, \%Profile );
			push @{$probs_ref}, $prob;
		}
		my $probs = $self->_normalize( $probs_ref );
		
		# Get a new starting index, then put the sequence we spliced out earlier back where it belongs
		my $new_starting_index = $self->_choose_from_distribution( $probs );
		$starting_positions->[$index] = $new_starting_index;
		splice( @{$self->{_seqs}}, $index, 0, $sequence );
		
		# Get the consensus motif and profile score
		my $motif = $self->_get_motif( \%Profile );
		my $score = $self->_get_profile_score( \%Profile );
		
		# Add the motif and score to $self->{_samples}
		my @tmp = ( $motif, $score );
		push @{$self->{_samples}}, \@tmp;
		
		# At this point, the loop will automatically check for convergence before the next iteration.
	}
	
    # Of all the samples we took, choose the best one. 	# Hopefully it's the one we converged to, but may not be...
	my $best_motif = $self->_max_score( $self->{_samples} );
	return $best_motif;		# $best_motif is actually a tuple array of ( STR motif and FLOAT score ), we only want to return the STR motif.
}

# Last line in the class must always be 1!
# We're done!
1;