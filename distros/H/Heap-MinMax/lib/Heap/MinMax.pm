#
# MinMax.pm
#
# An implementation of a Min-Max Binary Heap, based on 1986 article
# "Min-Max Heaps and Generalized Priority Queues" by Atkinson, Sack, 
# Santoro, and Strothotte, published in Communications of the ACM.
#
# In a Min-Max heap, objects are stored in partial order such that both the
# minimum element and maximum element are available in constant time.  This 
# is accomplished through a modification of the standard heap algorithm that
# introduces the notion of 'min' (even) levels and 'max' (odd) levels in the
# binary tree structure of the heap.  
# 
# With a Min-Max heap you get all this, plus insertion into a Min-Max heap is 
# actually *faster* than with a normal heap (by a constant factor of 0.5).
#
#
package Heap::MinMax;

use Carp;
use strict;
use warnings;


our $VERSION = '1.04';



##################################################
#  the MinMax Heap constructor 
##################################################
sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
        _arr      => [],   # Array containing heap
	fcompare  => \&default_cmp_func,
	feval     => \&default_eval,
        @_,    # Override previous attributes
    };
    $self = bless $self, $class;
    return $self;
}

##############################################
# accessor methods        
##############################################

sub array
{
    my $self = shift;
    if (@_) { $self->{_arr} = shift }
    return $self->{_arr};	
}




#=========================================================================
#
# main heap functions
#
#=========================================================================


##########################################################################
#
# build_heap
# 
# $mm_heap->build_heap();
#
# builds a heap from MinMax object's array
#
##########################################################################
sub build_heap
{
    my ($self) = @_;     
    my $array = $self->{_arr};    
    my $arr_length = @$array;
    my $val;

    for(my $i = $arr_length/2; $i >= 0; $i--){
	$val = $self->trickledown($i);	
    }    
    return $val;
}

##########################################################################
#
# insert
#
# $mm_heap->insert($value);
# $mm_heap->insert(@values);
#
# Insertion works by placing the new node in the first available 
# leaf position and then calling bubble_up to re-establish min-max 
# ordering of the heap.
#
##########################################################################
sub insert
{
    my ($self,
	@values) = @_;
    
    while(defined(my $val = shift(@values))){	
	my $array = $self->{_arr};	
	push(@$array, $val); # put the new element in the next available leaf slot	
	my $arr_length = @$array;
	my $index = $arr_length - 1;
	
	# call bubble_up        
	$self->bubble_up($index);	
    }
}

#########################################################################
#
# remove
# 
# $mm_heap->remove($object);
#
# Not the same as pop_<min,max>.  really expensive arbitrary remove 
# operation that iterates over the array and finds the object it needs, 
# removes it, then calls trickledown from the index where the object 
# was found to re-establish min-max ordering of the heap.
#
#########################################################################
sub remove
{
    my ($self,
	$obj) = @_;
    

    my ($pkg, $filename, $line) = caller();

    my $array = $self->{_arr};
    my $arr_length = @$array;
    my $evalfunc = $self->{feval};
    my $value = $evalfunc->($obj);
    
    my $index;

    my $i = 0;
    foreach my $elt (@$array){

	if($self->{fcompare}->($obj, $elt) == 0){
	    $index = $i;
	    last;
	}	
	$i++;
    }

    if(defined $index){
	my $obj = $array->[$index];

	$array->[$index] = $array->[$arr_length-1];    
	pop(@$array);

	$self->trickledown($index);

	return $obj;
    }
    return;
}

############################################################
#
# min
#
# my $min_obj = $mm_heap->min(); 
#
# return the minimum object in heap
#
############################################################
sub min
{
    my ($self) = @_;
    my $array = $self->{_arr};
    my $arr_length = @$array;

    #array is empty
    if(!$arr_length){
	return;
    }

    my $top = $array->[0];    	
    return $top;
}

############################################################
#
# pop_min
#
# my $min_obj = $mm_heap->pop_min(); 
# 
# pop the minimum object from the heap and return it
#
############################################################
sub pop_min
{
    my ($self) = @_;
    my $array = $self->{_arr};
    my $arr_length = @$array;

    #array is empty
    if(!$arr_length){
	return;
    }

    my $top = $array->[0];
 
    $array->[0] = $array->[$arr_length-1];    
    pop(@$array);
    
    $self->trickledown(0);	
    return $top;
}


############################################################
#
# min_non_zero
#
# my $min_obj = $mm_heap->min_no_zero(); 
# 
# get minimum, non-zero valued object from the heap 
# and return it.   This only makes sense if you have an 
# evaluation function that can return 0.
#
############################################################
sub min_non_zero # the smallest non-zero element
{
    my ($self) = @_;
    my $array = $self->{_arr};
    my $arr_length = @$array;
    my $evalfunc = $self->{feval};    
    my $index = 0;

    #array is empty
    if(!$arr_length){
	return;
    }

    my $top = $array->[$index];
    
    if($evalfunc->($top) == 0){ # find min of grandchildren
	my $n = 0;	
	my $smallest;
	for my $i (3,4,5,6) {
	    if($n == 0){
		$smallest = $i;
		$n++;
	    }
	    else{
		if($array->[$i] && $self->{fcompare}->($array->[$i], $array->[$smallest]) == -1){
		    $smallest = $i;
		}
	    }
	}
	$index = $smallest;
    }
    
    $top = $array->[$index];

    return $top;
}


############################################################
#
# pop_min_non_zero
# 
# my $min_obj = $mm_heap->pop_min_no_zero(); 
#
# pop the minimum, non-zero valued object from the heap 
# and return it.   This only makes sense if you have an 
# evaluation function that can return 0.
#
############################################################
sub pop_min_non_zero # pop the smallest non-zero element
{
    my ($self) = @_;
    my $array = $self->{_arr};
    my $arr_length = @$array;
    my $evalfunc = $self->{feval};    
    my $index = 0;

    #array is empty
    if(!$arr_length){
	return;
    }

    my $top = $array->[$index];
    
    if($evalfunc->($top) == 0){ # find min of grandchildren
	my $n = 0;	
	my $smallest;
	for my $i (3,4,5,6) {
	    if($n == 0){
		$smallest = $i;
		$n++;
	    }
	    else{
		if($array->[$i] && $self->{fcompare}->($array->[$i], $array->[$smallest]) == -1){
		    $smallest = $i;
		}
	    }
	}
	$index = $smallest;
    }
    
    $top = $array->[$index];
    $array->[$index] = $array->[$arr_length-1];    
    pop(@$array);    
    $self->trickledown($index);
	
    return $top;
}

############################################################
#
# max
#
# my $max_obj = $mm_heap->max();
# 
# get maximum object in the heap and return it
#
############################################################
sub max
{
    my ($self) = @_;
    my $array = $self->{_arr};
    my $arr_length = @$array;
    my $evalfunc = $self->{feval};  

    #array is empty
    if(!$arr_length){
	return;
    }
    
    # array has only one element
    if($arr_length == 1){ 
	return $array->[0];
    }

    # array has only two elements
    if($arr_length == 2){
	return $array->[1];
    }

    my $result = $self->{fcompare}->($array->[1], $array->[2]);    
    my $max_index = ($result >= 0) ? 1 : 2;
    my $top = $array->[$max_index];  

    return $top;
}



############################################################
#
# pop_max
#
# my $max_obj = $mm_heap->pop_max();
# 
# pop the maximum object from the heap and return it
#
############################################################
sub pop_max
{
    my ($self) = @_;
    my $array = $self->{_arr};
    my $arr_length = @$array;
    my $evalfunc = $self->{feval};  

    my $top;
    my $max_index;

    #array is empty
    if(!$arr_length){
	return;
    }

     # array has only one element
    if($arr_length == 1){ 
	$max_index =  0;
    }
    # array has only two elements
    elsif($arr_length == 2){
	$max_index = 1;
    }
    else{
	my $result = $self->{fcompare}->($array->[1], $array->[2]);    
        $max_index = ($result >= 0) ? 1 : 2;
    }
    
    $top = $array->[$max_index];
       
    $array->[$max_index] = $array->[$arr_length-1];
    pop(@$array);    

    $self->trickledown($max_index);
    
    return $top;
}





############################################################
#
# trickledown() is called during heap construction.   it
# determines whether current level is a min-level or max-level, 
# and calls the appropriate trickledown{min,max}() function.
#
############################################################
sub trickledown
{
    my ($self, $i) = @_;
    my $array = $self->{_arr};

    if($i >= @$array){
	return;
    }
    my $level = $self->get_level($i);

    if($level == 0){
	$self->trickledown_min($i);
    }
    elsif(($level % 2) == 0){
	$self->trickledown_min($i);
    }
    else{
	$self->trickledown_max($i);	
    }
    return;
}

############################################################
#
# trickledown_min is called during heap construction when examining 
# a subtree rooted at an even level.  Compares the values of the root 
# node with the smallest of its children and grand-children.
# if the root node is larger, the values are swapped and the
# function recurses.
#
#
# Note: this function is very similar to trickle_down_max, but 
# they are kept separate for purposes of readability.
#
############################################################
sub trickledown_min
{
       my ($self, $index) = @_;
       my $array = $self->{_arr};
       my $m = $self->get_smallest_descendant_index($index);
       
       my $level = $self->get_level($index);

       if(!$m){ 
	   return; 
       }

       if($self->is_grandchild($index, $m)){
	   if($self->{fcompare}->($array->[$m], $array->[$index]) == -1){
	       $self->swap($index, $m);
	       
	       if($self->{fcompare}->($array->[$m], $self->parent($m)) == 1){
		   my $parent_index = $self->parent_node_index($m);
		   $self->swap($m, $parent_index);
	       }
	       
	       $self->trickledown_min($m);
	   }
       }
       elsif($self->{fcompare}->($array->[$m], $array->[$index]) == -1){
      	   $self->swap($index, $m);
       }    
}

############################################################
#
# trickledown_max is called during heap construction when examining 
# a subtree rooted at an odd level.  Compares the values of the root 
# node with the largest of its children and grand-children.
# if the root node is smaller, the values are swapped and the
# function recurses.
#
#
# Note: this function is very similar to trickle_down_min, but 
# they are kept separate for purposes of readability.
#
############################################################
sub trickledown_max
{
       my ($self, $index) = @_;
       my $array = $self->{_arr};
       my $m = $self->get_largest_descendant_index($index);
       
       my $level = $self->get_level($index);

       if(!$m){ return; }

       if($self->is_grandchild($index, $m)){
	   if($self->{fcompare}->($array->[$m], $array->[$index]) == 1){
	       $self->swap($m, $index);
	       
	       if($self->{fcompare}->($array->[$m], $self->parent($m)) == -1){	       
		   my $parent_index = $self->parent_node_index($m);
		   $self->swap($m, $parent_index);
	       }
	       
	       $self->trickledown_max($m);
	   }
       }
       elsif($self->{fcompare}->($array->[$m], $array->[$index]) == 1){
	   $self->swap($index, $m);
       }    
}

############################################################
#
# bubble_up() is  called during insertion.  determines whether the
# current level is an even (min) or odd (max) level, and 
# then either calls bubble_up_min or bubble_up_max.
#
#
############################################################
sub bubble_up
{
    my ($self, $i) = @_;    
    my $array = $self->{_arr};    
    
    my $level = $self->get_level($i);

    if(($level % 2) == 0){       
	if($self->has_parent($i) != -1){
	    my $parent_index = $self->parent_node_index($i);
	    
	    if($self->{fcompare}->($array->[$i], $array->[$parent_index]) == 1){
		$self->swap($i, $parent_index);		
		$self->bubble_up_max($parent_index);
	    }
	    else{
		$self->bubble_up_min($i);
	    }
	}
    }
    else{		
	if($self->has_parent($i) != -1){
	    my $parent_index = $self->parent_node_index($i);

	    if($self->{fcompare}->($array->[$i], $array->[$parent_index]) == -1){
		$self->swap($i, $parent_index);		
		$self->bubble_up_min($parent_index);
	    }
	    else{
		$self->bubble_up_max($i);
	    }
	}
    }
}

############################################################
#
# bubble_up_min is called during insertion. after inserting
# a new leaf on the heap, the object is then "bubbled-up" to 
# maintain heap-ness. 
#
# Note: this function is *very* similar to bubble_up_max, but 
# they are kept separate for purposes of readability.
#
############################################################
sub bubble_up_min
{
    my ($self, $i) = @_;
    my $array = $self->{_arr};
    
    if($self->has_grandparent($i)){
	my $gp_index = $self->grandparent_node_index($i);

	if($self->{fcompare}->($array->[$i], $array->[$gp_index]) == -1){
	    $self->swap($i, $gp_index);
	    $self->bubble_up_min($gp_index);
	}	
    }     
}

############################################################
#
# bubble_up_max is called during insertion.   after inserting
# a new leaf on the heap, the object is then "bubbled-up" to 
# maintain heap-ness.
#
# Note: this function is *very* similar to bubble_up_min, but 
# they are kept separate for purposes of readability.
#
############################################################
sub bubble_up_max
{
    my ($self, $i) = @_;
    my $array = $self->{_arr};
        
    if($self->has_grandparent($i)){
	my $gp_index = $self->grandparent_node_index($i);

	if($self->{fcompare}->($array->[$i], $array->[$gp_index]) == 1){
	    $self->swap($i, $gp_index);
	    $self->bubble_up_max($gp_index);
	}	
    }       
}



############################################################
#
# swap two elements in the array
#
############################################################
sub swap
{
    my ($self, $m, $index) = @_;
    my $array = $self->{_arr};
    
    if($m <  @$array && $index <  @$array){
	 my $tmp = $array->[$index];
	 $array->[$index] =  $array->[$m];
	 $array->[$m] =  $tmp;
    }

    $self->{_arr} = $array;
}



############################################################
#
# get_smallest_descendant_index() returns the index of the
# smallest descendant of this node.
#
############################################################
sub get_smallest_descendant_index
{
    my ($self, $index) = @_;    
    my $array = $self->{_arr};

    if($self->has_children($index)){ # if has children
	my %descendants;

	# right node and right node descendants
	my $rightnode = $self->right_node($index);
	my $r_index = $self->right_node_index($index);	

	if($rightnode){
	    $descendants{$r_index} = $rightnode;
	}

	my $right_leftnode = $self->left_node($r_index);
	my $right_leftnode_index = $self->left_node_index($r_index);

	if($right_leftnode){
	    $descendants{$right_leftnode_index} = $right_leftnode;
	}

	my $right_rightnode = $self->right_node($r_index);
	my $right_rightnode_index = $self->right_node_index($r_index);

	if($right_rightnode){
	    $descendants{$right_rightnode_index} = $right_rightnode;
	}

	# left node and left node descendants
	my $leftnode = $self->left_node($index);
	my $l_index = $self->left_node_index($index);

	if($leftnode){
	    $descendants{$l_index} = $leftnode;
	}
	
	my $left_leftnode = $self->left_node($l_index);
	my $left_leftnode_index = $self->left_node_index($l_index);

	if($left_leftnode){
	    $descendants{$left_leftnode_index} = $left_leftnode;
	}

	my $left_rightnode = $self->right_node($l_index);
	my $left_rightnode_index = $self->right_node_index($l_index);
	if($left_rightnode){
	    $descendants{$left_rightnode_index} = $left_rightnode;
	}
	
	my $index;
	
	# extract minimum
	my $min_descendant;
	my $i = 0;
	foreach my $key (keys %descendants){
	    if($i == 0){
		$min_descendant = $descendants{$key};

		$index = $key;
		$i++;
	    }	
	    elsif($self->{fcompare}->($descendants{$key}, $min_descendant) == -1){ 
		$min_descendant = $descendants{$key};
		$index = $key;
	    }	    
	}      
	return $index;	
    }
 
    return;
}


############################################################
#
# get_largest_descendant_index() returns the index of the
# largest descendant of this node.
#
############################################################
sub get_largest_descendant_index
{
    my ($self, $index) = @_;    
    my $array = $self->{_arr};
    
    if($self->has_children($index)){ # if has children
	my %descendants;

	# right node and right node descendants
	my $rightnode = $self->right_node($index);
	my $r_index = $self->right_node_index($index);	

	if($rightnode){
	    $descendants{$r_index} = $rightnode;
	}

	my $right_leftnode = $self->left_node($r_index);
	my $right_leftnode_index = $self->left_node_index($r_index);

	if($right_leftnode){
	    $descendants{$right_leftnode_index} = $right_leftnode;
	}

	my $right_rightnode = $self->right_node($r_index);
	my $right_rightnode_index = $self->right_node_index($r_index);

	if($right_rightnode){
	    $descendants{$right_rightnode_index} = $right_rightnode;
	}

	# left node and left node descendants
	my $leftnode = $self->left_node($index);
	my $l_index = $self->left_node_index($index);

	if($leftnode){
	    $descendants{$l_index} = $leftnode;
	}
	
	my $left_leftnode = $self->left_node($l_index);
	my $left_leftnode_index = $self->left_node_index($l_index);

	if($left_leftnode){
	    $descendants{$left_leftnode_index} = $left_leftnode;
	}

	my $left_rightnode = $self->right_node($l_index);
	my $left_rightnode_index = $self->right_node_index($l_index);
	if($left_rightnode){
	    $descendants{$left_rightnode_index} = $left_rightnode;
	}
	
	my $index;
	
	# extract maximum
	my $max_descendant;
	my $i = 0;

	foreach my $key (keys %descendants){
	    if($i == 0){
		$max_descendant = $descendants{$key};

		$index = $key;
		$i++;
	    }	
	    elsif($self->{fcompare}->($descendants{$key}, $max_descendant) == 1){ 
		$max_descendant = $descendants{$key};
		$index = $key;
	    }	    
	}
		
	return $index;	
    }

    return;
}





################################################
#
# utilities for the heap algorithms
#
################################################
sub default_cmp_func
{
    my ($obj1, $obj2) = @_;
   
    if(fp_equal($obj1, $obj2, 10)){
	return 0;
    }
    if($obj1 < $obj2){	
	return -1;
    }
    return 1;
}

sub default_eval
{
    my ($elt) = @_;
    return $elt;
}


sub parent_node_index
{
    my ($self,
	$index) = @_;
    
    if($index == 0){
	return -1;
    }

    return int(($index-1)/2);
}


sub grandparent_node_index
{
    my ($self,
	$index) = @_;
    
    if($index == 0){
	return;
    }
    my $parent_index = $self->parent_node_index($index);
    if($parent_index){
	return $self->parent_node_index($parent_index);
    }
    return;
}

sub right_node
{
    my ($self, $index) = @_;

    my $r_index = $self->right_node_index($index);
    my $array = $self->{_arr};

    if($r_index < @$array){ 
	return $array->[$r_index];	
    }
    return;
}

sub right_node_index
{
    my ($self,
	$index) = @_;
    return $index*2 + 2;
}


sub left_node
{
    my ($self, $index) = @_;
    my $l_index = $self->left_node_index($index);
    my $array = $self->{_arr};
    
    if($l_index < @$array){ 
	return $array->[$l_index];
    }
    return;
}


sub left_node_index
{
    my ($self,
	$index) = @_;
    return $index*2 + 1;
}


sub parent
{    
    my ($self,
	$index) = @_; 
    my $array = $self->{_arr};

    if($index == 0){
	return;
    }        
    my $parent_index = $self->parent_node_index($index);
    
    if($parent_index){
	return $self->{_arr}->[$parent_index];
    }
    return;
}


sub get_size
{
    my $self = shift;
    my $array = $self->{_arr};
    return @$array;	
}

sub is_empty
{
    my ($self) = @_; 
    my $array = $self->{_arr};
    if(@$array == 0){
	return 1;
    }
    return 0;    
}


sub has_grandparent
{
    my ($self, $i) = @_;

    my $parent_node_index = $self->parent_node_index($i);
    
    if($parent_node_index){
	if($self->parent_node_index($parent_node_index) != -1){
	    return 1;

	}
    }
    return 0;
}

sub has_parent
{
    my ($self, $i) = @_;
    
    if($self->parent_node_index($i) != -1){
	return 1;
    }
    return -1;    
}

sub has_children
{
    my ($self, $i) = @_;

    if($self->left_node($i) || $self->right_node($i)){ # if has children
	return 1;
    }
    return 0;
}

sub is_grandchild
{
    my ($self, $index, $gindex) = @_;
    
    my $l_index = $self->left_node_index($index);
    my $r_index = $self->right_node_index($index);
    
    my $l_l_index = $self->left_node_index($l_index);
    if($gindex == $l_l_index){
	return 1;
    }
    my $l_r_index = $self->right_node_index($l_index);
    if($gindex == $l_r_index){
	return 1;
    }
    my $r_l_index = $self->left_node_index($r_index);
    if($gindex == $r_l_index){
	return 1;
    }
    my $r_r_index = $self->right_node_index($r_index);
    if($gindex == $r_r_index){
	return 1;
    }

    return 0;
}



sub get_level
{
    my ($self, $i) = @_;
    my $log;
    my ($pkg, $filename, $line) = caller();

    if($i == 0){
	return 0;
    }
    $log = log($i + 1) / log(2);    
    return int($log);
}



############################################################
#
# print
#
# $mm_heap->print();
# 
# Dump the contents of the heap to STDOUT
#
############################################################
sub print{
    $_[0]->print_heap();    
}

sub print_heap{
    my ($self) = @_;
    my $array = $self->{_arr};
    my $eval_func = $self->{feval};

    my $i = 0;
    foreach my $elt (@$array){
	my $val = $eval_func->($elt);
	if(!defined($val)){
	    croak "Error:  evaluation function provided to Heap::MinMax object returned null\n";
	}
	print $eval_func->($elt) . "\n";
	$i++;
    }
}



sub fp_equal {
    my ($A, $B, $dp) = @_;

    return sprintf("%.${dp}g", $A) eq sprintf("%.${dp}g", $B);
}





1;
__END__


=head1 NAME

Heap::MinMax - Min-Max Heap for Priority Queues etc.

=head1 SYNOPSIS

 use Heap::MinMax;

=head2 EXAMPLE 1

  # shows basic (default constructor) behavior of heap.
  # the default comparison function is floating-point numeric.

  my $mm_heap = Heap::MinMax->new();
  my @vals = (2, 1, 3, 7, 9, 5, 8);
  foreach my $val (@vals){    
    $mm_heap->insert($val);
  }
  $mm_heap->print_heap();
  my $min = $mm_heap->pop_min();
  print "min was: $min\n";
  my $max = $mm_heap->pop_max();
  print "max was: $max\n";
  $mm_heap->print_heap();


  my $mm_heap2 = Heap::MinMax->new();
  my @vals2 = (19.111111, 19.111112, 15, 17);
  $mm_heap2->insert(@vals2);
  $mm_heap2->insert(19.11110);
  $mm_heap2->print_heap();
  print $mm_heap2->max() . "\n"; # output 19.111112
  print $mm_heap2->min() . "\n"; # output 15

  exit


=head2 EXAMPLE 2

  # shows how you can store any set of comparable objects in heap.  
  #
  #  Note: in this example, anonymous subroutines are
  #  passed in to the constructor, but you can just as well supply
  #  your own object's comparison methods by name-   i.e.,
  #
  #  $avltree = Heap::MinMax->new(
  #          fcompare => \&MyObj::compare,
  #           
  #          . . . 
  #           
  #          etc...
  


  use Heap::MinMax;

  my $elt1 = { _name => "Bob",
  	     _phone => "444-4444",};
  my $elt2 = { _name => "Amy",
	     _phone => "555-5555",};
  my $elt3 = { _name => "Sara",
	     _phone => "666-6666",}; 

  my $mm_heap3 = Heap::MinMax->new(

      fcompare => sub{ my ($o1, $o2) = @_;
  		     if($o1->{_name} gt $o2->{_name}){ return 1}
  		     elsif($o1->{_name} lt $o2->{_name}){ return -1}
  		     return 0;},

      feval     => sub{ my($obj) = @_;
  		       return $obj->{_name} . ", " . $obj->{_phone};},   

      );


  $mm_heap3->insert($elt1);
  $mm_heap3->insert($elt2);
  $mm_heap3->insert($elt3);
  # ...  etc.

  $mm_heap3->print();



  exit;




=head1 DESCRIPTION

An implementation of a Min-Max Heap as described in "Min-Max Heaps
and Generalized Priority Queues", Atkinson, Sack, Santoro, Strothotte, 1986.

Min-Max heaps allow objects to be stored in a 'dual' partially-sorted manner, such 
that finding both the minimum and the maximum element in the set takes constant 
time. This is accomplished through a modification of R.W. Floyd's original
heap algorithm that introduces the notion of 'min' (even) levels and 'max' 
(odd) levels in the binary structure of the heap.  

A comparison of the time complexities of Min-Max Heaps vs. regular Min Heaps is 
as follows:

                       Min Heap                     Min-Max Heap
 -----------------------------------------------------------------------------
 Create                2*n                            (7/3)*n
 Insert                log(n+1)                       0.5*log(n+1)
 DeleteMin             2*log(n)                       2.5*log(n)
 DeleteMax             0.5*n+log(n)                   2.5*log(n)
 -----------------------------------------------------------------------------



=head1 METHODS

=head2 new()

 my $mm_heap = Heap::MinMax->new();

MinMax Heap constructor.   Without any arguments, returns a heap that works with
floating-point values.   You can also supply a comparision function and an
evaluation function (useful for printing).




=head2  array()

 my $heaps_array = $mm_heap->array();

Access the array that is used by the heap.




=head2 build_heap()

 $mm_heap->build_heap();

Builds a heap from heap object's array.





=head2  insert()
 
 $mm_heap->insert($thing);

or

 $mm_heap->insert(@things);

Add a value/object to the heap.




=head2  remove()

 my $found_thing = $mm_heap->remove($thing);

Really expensive arbitrary remove function.   Looks through the array for value/object 
specified and removes it, then trickles heap-property down from that location.  If you
are using this function, you are not taking advantage of the power of Heaps.  However, 
sometimes you gotta do what you gotta do.





=head2  min()

 my $min_thing = $mm_heap->min();

Returns the minimum value/object stored in the heap.


=head2 min_non_zero()

 my $min_non_zero_thing = $mm_heap->min_non_zero();

Returns the minimum non-zero value/object stored in the heap.



=head2  max()

 my $max_thing = $mm_heap->max();

Returns the maximum value/object stored in the heap.





=head2  pop_min()

 my $min_thing = $mm_heap->pop_min();

Removes and returns the minimum value/object stored in the heap.


=head2 pop_min_non_zero()

 my $min_non_zero_thing = $mm_heap->pop_min_non_zero();

Removes and returns the minimum non-zero value/object stored in the heap.



=head2  pop_max()

 my $min_thing = $mm_heap->pop_max();

Removes and returns the maximum value/object stored in the heap.





=head2  get_size()

 my $size = $mm_heap->get_size();

Returns the number of elements currently in the heap.





=head2  print()

 $mm_heap->print();

Dumps the contents of the heap to STDOUT.


=head1 DEPENDENCIES

Test::More (for installation and testing).



=head1 EXPORT

None.


=head1 SEE ALSO

"Min-Max Heaps and Generalized Priority Queues", Atkinson, Sack, Santoro, Strothotte, 1986.


=head1 AUTHOR

Matthias Beebe, E<lt>matthiasbeebe@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Matthias Beebe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
