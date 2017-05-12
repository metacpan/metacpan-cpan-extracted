package List::Object;
use 5.008003;
use strict;
use warnings;

# $Id$
# $Name$

use Carp;
#use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use List::Object ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

my %types = (
    ''  => '',
    '$' => 'SCALAR',
    '@' => 'ARRAY',
    '%' => 'HASH',
);

my %rev_types = map { ($types{$_}, $_) } (keys %types);

#print "HELLO!!!!\n";

###################################################################
sub new
{   #
    my $class = CORE::shift;
    my @args  = @_;
    my $this  = {};

    bless $this, $class;
    $this->_init(@args);
    return $this;
}

###################################################################
sub _init
{   #
    my $this = CORE::shift;
    my %args = @_;
    $this->{_type} = defined $args{type} ? $args{type} : '%';
    $this->{_allow_undef} = defined $args{allow_undef} ? $args{allow_undef} : '0';

    if (defined $args{list})
    {   #
       $this->_valid_type(@{$args{list}});  
       $this->{_array} = $args{list};
    }
    else
    {
        $this->{_array} = [];
    }
    $this->rewind();
}

###################################################################
sub _valid_type
{   #
    return 1 if defined  $List::Object::Loose  && $List::Object::Loose == 1;
    # done a second time to suppress the
    # 'used only once: possible typo' perl warning

    my $this = shift; 
    my @check_list = @_;

    my $valid = 1;
    my $undef = 0; 
    for my $c (@check_list)
    {
        if (! $this->{_allow_undef} && ! defined $c)
        {   #
           $undef = 1; 
           last; 
        }
  
        my $ref_type = ref $c;
       
        if (defined $c)
        {
            # are we and object (not a HASH, ARRAY, or SCALAR reftype?);
            if (exists $rev_types{$ref_type})
            {
                unless (ref $c eq $types{$this->{_type}})
                {
                    $valid = 0;
                    last;
                }

            }
            else
            {   #
                unless ($c->isa($this->{_type}))
                {   #
                    $valid = 0; 
                    last;
                }
            }
        }
        
    }
   
    croak(__PACKAGE__ . " undef items not allows in list. ") if $undef && ! $this->{_allow_undef};
    croak(__PACKAGE__ . " item is not valid ref type of '@{[$this->{_type}]}'") unless $valid;
    return 1;
}

# decrement the iterator location by one
# if the iterator is non-zero, and the
# list has been shortened below where
# the index is at;
###################################################################
sub _fix_index
{   #
    croak "method not implemented";
    my $this = shift;
    my $changed_index =  shift;
}

###################################################################
sub has_next
{   #
    return $_[0]->{_index} < @{$_[0]->{_array}} - 1;
}

###################################################################
sub next
{   #
    my $this = shift;
    croak "index out of range" if $this->{_index} >= @{$this->{_array}} - 1;
    $this->_valid_type($this->{_array}->[$this->{_index}]);
    return $this->{_array}->[++$this->{_index}];
}

###################################################################
sub rewind
{   #
    $_[0]->{_index} = 0;
    return 1; 
}

###################################################################
sub shift
{   #
    $_[0]->_valid_type($_[0]->{_array}->[$_[0]->{_index}]);
    $_[0]->rewind();
    
    shift @{$_[0]->{_array}};
}

###################################################################
sub push
{   #
    my $this = CORE::shift;
    my @pushed = @_;
    $this->_valid_type(@pushed);
    $this->rewind();
    CORE::push @{$this->{_array}}, @pushed;
}

###################################################################
sub pop
{   #
    my $this = CORE::shift;
    $this->rewind();
    $this->_valid_type($this->{_array}->[$this->{_index}]);
    CORE::pop @{$this->{_array}};
}


###################################################################
sub unshift
{   #
    my $this = CORE::shift;
    my @unshifted = @_;
    $this->rewind();
    $this->_valid_type(@unshifted);
    CORE::unshift @{$this->{_array}}, @unshifted;
}

###################################################################
sub splice
{   #
    my $this = CORE::shift;

    $this->rewind();
    my $offset = 0;
    my $length = 0;
    my @list = ();

    $offset = CORE::shift if @_;
    $length = CORE::shift if @_;
    @list = @_ if @_;
    $this->_valid_type(@list);    
    splice @{$this->{_array}}, $offset, $length, @list;
}

###################################################################
sub join
{   #
    my $this = CORE::shift;
    my $join = '';
    
    if ($this->{_type} eq '')
    {   #
        $join = CORE::shift if @_;
        return CORE::join $join, @{$this->{_array}}; 
    }
    elsif($this->{_type} eq '$')
    {   #
        $join = CORE::shift if @_;
        return CORE::join $join, map { $$_} @{$this->{_array}}; 
    }
    else
    {   #
        carp("Can't join non-scalar ref types, returning empty string.");
        return '';
         
    }
}

###################################################################
sub count
{   #
    my $this = CORE::shift;
    return scalar @{$this->{_array}};
}

###################################################################
sub clear
{   #
     
    $_[0]->{_array} = [];
    return 1; 
}

###################################################################
sub get
{   #
    my $this    = CORE::shift;
    my $index   = CORE::shift;
    croak "index out of range" if $index >= $this->count();
    $this->_valid_type($this->{_array}->[$index]);
    return $this->{_array}->[$index];
}

###################################################################
sub set
{   #
    my $this    = CORE::shift;
    my $index   = CORE::shift;
    my $item    = CORE::shift;
    croak "index out of range" if $index >= $this->count();
    $this->_valid_type($item);
    $this->{_array}->[$index] = $item;
}

###################################################################
sub add
{   #
    my $this = CORE::shift;
    $this->_valid_type(@_);
    return $this->push(@_);
}


###################################################################
sub remove
{   #
    my $this = CORE::shift;
    my $index = CORE::shift;
    my $rm_item = $this->splice($index, 1);
    $this->_valid_type($rm_item);
    $this->rewind();
    return $rm_item;
}


###################################################################
sub first
{   #
    my $this = CORE::shift;
    $this->_valid_type($this->{_array}->[0]);
    return $this->{_array}->[0];
}

###################################################################
sub last
{   #
    my $this = CORE::shift;
    $this->_valid_type($this->{_array}->[$this->count() - 1]);
    return $this->{_array}->[$this->count() - 1];
}

###################################################################
sub peek
{   #
    my $this = CORE::shift;

    $this->_valid_type($this->{_array}->[$this->{_index}]);
    return $this->{_array}->[$this->{_index}];
}

###################################################################
sub type
{   #
    return $_[0]->{_type};
}

###################################################################
sub allow_undef
{   #
    return $_[0]->{_allow_undef};
    
}

###################################################################
sub array
{   #
    my $this = CORE::shift;
    return @{$this->{_array}};
}

###################################################################
sub reverse
{   #
    my $this = CORE::shift;
    $this->rewind();
    $this->{_array} =  [reverse @{$this->{_array}}] ; 
}

###################################################################
sub sort
{   #
    my $this = CORE::shift;
    if ($this->{_type} eq '')
    {   #
        $this->rewind();
        $this->{_array} = [sort @{$this->{_array}}];
    }
    elsif($this->{_type} eq '$')
    {   #
       # look how nested this is!!! 
       $this->{_array} = [map {\$_} (sort (map {$$_} @{$this->{_array}})) ]  
    }
    else
    {
        carp "Can't sort non-scalar ref types. Nothing done.";
    }
}

###################################################################
sub sort_by
{   #
    my $this         = CORE::shift;
    my $sort_by      = CORE::shift;

    $this->rewind();
    
    my $type = $this->{_type};

    my $sort_sub = sub {    #
        my $av = CORE::shift;
        my $bv = CORE::shift;

        if ($av =~ /^[\d\.]+$/ && $bv =~ /^[\d\.]+$/)
        {
            return $av <=> $bv;
        }
        else
        {   #
            return $av cmp $bv; 
        }
    };

    if (! defined $types{$type})
    {
        # sort list of objects method
        $this->_error() unless $type->can($sort_by);
        $this->{_array} = [ sort { &$sort_sub($a->$sort_by(), $b->$sort_by()) } @{$this->{_array}}];
    }
    elsif ($type eq '%')
    {   
        $this->{_array} = [ sort { &$sort_sub($a->{$sort_by}, $b->{$sort_by}) } @{$this->{_array}}];
    }
    elsif ($type eq '@')
    {   
        $this->{_array} = [ sort { &$sort_sub($a->[$sort_by], $b->[$sort_by]) } @{$this->{_array}}];
    }
    else
    {   #
        # for lists of scalars and scalar refs, fall back to sort;
        carp "Can't sory_by() on scalars and scalar refs, Falling back to sort()";
        $this->sort();
    }
}

###################################################################
sub unique_by
{   #
    croak "method not implemented";
    my $this = CORE::shift;
    my $type = $this->{_type};
    my $method = CORE::shift;
    
}

###################################################################
sub filter_by
{   #
    croak "method not implemented";
    my $this = CORE::shift; 
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

List::Object - Ordered list of objects with array methods and iterator methods, enforces types of list members.

=head1 SYNOPSIS

List::Object was inspired by several other modules: L<Array::|Array::> for having an object-oriented interface
to perl's array functions. L<Class::MethodMaker|Class::MethodMaker> for its auto-generated methods that do that same thing with its C<object_list> functionality (hence the name of this package), as well as the fact that it enforces the declared datatype on its members. And I like the generic Iterator interface for woking with lists.

In a nutshell, List::Object has three main features:

* Object-oriented interface to perl's array methods

* Implements the Iterator interface for the list

* Enforces datatypes of list members.


  use List::Object;
  
  $lo = List::Object->new();

  [...]

  $lo = List::Object->new(type          => 'Package::Name',
                          list          => \@array,
                          allow_undef   => 0);

  [...]

  # Iterator methods
  $lo->next()
  $lo->has_next()
  $lo->peek()
  $lo->rewind()
  $lo->get()
  $lo->set()
  $lo->add()
  $lo->remove()
  $lo->first()
  $lo->last()

  # Perl array functions
  $lo->shift()
  $lo->push()
  $lo->pop()
  $lo->unshift()
  $lo->join()
  $lo->array()
  $lo->reverse()
  $lo->sort()
  $lo->splice()

  # Other
  $lo->sort_by()
  $lo->allow_undef()
  $lo->type()
  $lo->count()
  $lo->clear()

=head1 DESCRIPTION

=over 4

=item new( [type => '',] [list => \@array,] [allow_undef => 0])

type: The type of data that will be in thist list. Takes class names like 'Package::Name', 'Foo::Bar', ete. Also takes '$', '@', and '%'. So you can use this class to maintain lists of scalarrefs, arrayrefs, and hashrefs, respectively. An omitted type or a type of of '' (empty sting) means you are creating list of plain scalars. This is the default. You should explicity declare your list type. At any time, attempting the put and item in the list that does not match the defined type will call the object to croak.

list: Optional list of elements to initially populate the List::Object list.

allow_undef: Flag to let List::Object know if list items can be undefined. By default this is off, and all items must be defined _and_ of the correct type. By turning it on, List::Object overlooks undefined items when enforcing it type requirement.

Returns a new List::Object object;

=item next()

Return the next item in the list as you are iterating through the list. Will croak if there is no next item. Use has_next() to find out ahead of time. Calling next() repeatedly will return a different item each time.

=item has_next()

Return true or false, based whether or not there are more items in a list being iterated over.

=item peek()

Returns the next item on a list, but doesn't move you through the list. Will croak if there is no next time.  Use has_next() to find out ahead of time.  Calling peek() repeatedly will return the same item.

=item rewind()

Resets the iterator back to the beginning of the list.

=item get($index)

Returns an item from the list at the specified (zero-based) index.

=item set($index, $item)

Replaces slot at $index with $item, based on a zero-based index.  Does _not_ add to list or expand the list count. $index must
be with the range of existing members. If not, it will croak.

=item add($item)

Adds $item as a new member at the end of the list. 

=item remove($index)

Removes item at $index from the list. This automatically rewinds the iterator.

=item first()

Returns the first item on the list. 

=item last()

Returns the last item on the list;

=item NOTE -- All 'array' type functions also rewind the index. Later versions will be smarter.

=item shift()

Like perl's shift function, removes the first item from the list and returns it.

=item push(@list)

Like perl's push function, add the list of items to the end of the list; 

=item pop()

Like perl's pop function, removes the last item from the list and returns it.

=item unshift(@list)

Like perl's C<unshift> function, add the list of items to the beginning of the list; 

=item join($join)

List perl's join function, joins the array into a string and returns it. 
However, this only works on lists of scalars or scalar refs. For other 
ref types carps and returns an empty string.

=item array()

Returns an (de-referenced) array of the members of the list.

=item sort()

Like perl's sort function, sorts the list in the same generic way the perl's 
sort method does. This method when working with lists of scalars or scalarrefs.
For other ref types, it carps and does nothing.

=item splice($offset, $length, @list)

Like perls's splice function, 

=item sort_by($key)

Sorts the list. If the list type is '@', the $key must be a index to each arrayref members array.
If the list type is '%', the $key must be a valid key to each hashref. If the list type if a Package::Name, the $key must be a method of the class. For list of scalars or scalarrefs, it will ignore the passed in the $key and fall back to a regular sort() method call.

Examples:

    $lo = List::Object->new(type => '@' , list => \@list)
    $lo->sort_by(2);
    # list of array refs have been sorted by the second element
    # in their list;

    [...]

    $lo = List::Object->(type => '%', list => \@list);
    $lo->sory_by('last_name)
    # list has been sorted by the value of the
    # $person->{last_name} key of each hashref in the list;

    [...]
    
    $lo = List::Object->(type => 'Person', list \@list);
    $lo->sort_by('last_name');
    # list has been sorted by the return value of the
    # last_name() method of each Person object in the list;


=item allow_undef()

Return true or false, base on whether or note the List::Object will permitted
undefined items to be members of the list, as defined by the 'type' parameter
when the List::Object was instantiated. See new().
    
=item type()

Return the type of data permitted in the list, as defined by the 'type' parameter
when the List::Object was instantiated. See new().

=item count()

Returns the current number of members in the list.

=item clear()

Empties list list.

=item loose(boolean)

It is possible to turn off the strict checking of list member's datatype. You can do this
by setting looose to 1.  This works on a per-object basis. You can turn it off across
all instances of the List::Object class by setting $List::Object::Loose to true; 
Don't fiddle with this. Either turn it on or off. I haven't done benchmarking, but I 
imagine you will a small performnace benefit by turning if off.  It may be useful 
to have it _off_ while in development, but turn it _on_ when in production.

=back

=head2 EXPORT

None by default.


=head2 TODO

=over 4

=item Rewinding more context aware

For now, calling any of the array-type methods (as opposed to the iterator-type) will automatically 'rewind' the iterator

=back

=head2 BUGS

No known bugs on initial release. Please send reports to author. 


=head1 SEE ALSO


=head1 AUTHOR

Steven Hilton, E<lt>mshiltonj@mshiltonj.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Steven Hilton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
