package Tree::Numbered;

use strict;

our $VERSION = '1.00';

our @counters = (); # For getting new serial numbers.

sub getNewSerial {
    my $lucky_number = shift;
    $counters[$lucky_number] = 1 unless (exists $counters[$lucky_number]);
    return ($counters[$lucky_number]++);
}

sub getNewLucky {
    $#counters++;
    return $#counters;
}

# predeclare subs used in <new>.
sub addField; 

# <new> constructs a new tree or node.
# Arguments: $value - the default value to be stored in the node.
#            %extra - extra fields as name => value.
# Returns: The tree object.

sub new {
    my ($parent, $value, $second, %extra) = @_;
    my $class;
    
    my $properties = { 
	Items => [],
	Cursor => -1,
	};

    
    if ($class = ref($parent)) {
	# Give it the same number as its parent.
	$properties->{_LuckyNumber} = $parent->{_LuckyNumber};
	$properties->{_ParentRef} = $parent;
	bless $properties, $class;

	# Inherit fields from parent (unless assigned in argument list).
	$properties->addField($_, $parent->{$_}) 
	    foreach ($parent->getFieldNames);
    } else {
	$class = $parent;
	$properties->{_LuckyNumber} = getNewLucky;
	bless $properties, $class
    }
    $properties->{_Serial} = getNewSerial($properties->{_LuckyNumber});

    # Detect parameter passing style for backward compatibility.
    if (scalar @_ > 2) {
	$extra{$value} = $second;
    } elsif (scalar @_ == 2) {
	$extra{Value} = $value if defined $value;
    }

    # Add requested fields, default to 'Value'.
    foreach (keys %extra) {
	# Calls are separated to override inherited settings.
	$properties->addField($_);
	$properties->setField($_, $extra{$_});
    }
    return $properties;
}

# <nextNode> moves the cursor forward by one.
# Arguments: None.
# Returns: Whatever is pointed by the cursor, undef on overflow, first item
#          on subsequent overflow.

sub nextNode {
    my $self = shift;

    my $cursor = $self->{Cursor};
    my $length = $self->childCount;
    $cursor++;

    # return undef when end of iterations. On next call - reset counter.
    if ($cursor > $length) {
	$cursor = ($length) ? 0 : -1;
    }
    $self->{Cursor} = $cursor;

    if (exists $self->{Items}->[$cursor]) {
	return $self->{Items}->[$cursor];
    }
    return undef;
}

# <reset> returns the counter to the beginning of the list.
# Arguments: None.
# Returns: Nothing.

sub reset {
    my $self = shift;
    $self->{Cursor} = -1;
}

# <delete> deletes the item pointed to by the cursor.
# The curser is not changed, which means it effectively moves to the next item.
# However it does change to be just after the end if it is already there,
# so you won't get an overflow.
# Arguments: None.
# Returns: The deleted item or undef if none was deleted.

sub delete {
    my $self = shift;
    my $cursor = $self->{Cursor};
    
    if (exists $self->{Items}->[$cursor]) {
	my $deleted =  splice(@{$self->{Items}}, $cursor, 1);

	# Make sure the cursor doesn't overflow:
	if ($cursor > $self->childCount) {
	    $self->{Cursor} = $self->childCount;
	}
	return $deleted;
    }

    return undef;
}

# <append> adds a node at the end of the list.
# Arguments: parameters for new.
# Returns: The added node or undef on error.

sub append {
    my $self = shift;
    my $newNode = $self->new(@_);
    return undef unless $newNode;

    push @{$self->{Items}}, $newNode;
    return $newNode;
}

# <savePlace> saves the place of the cursor.
# Arguments: None.
# Returns: Nothing.

sub savePlace {
    my $self = shift;
    $self->{Saved} = $self->{Cursor};
}

# <restorePlace> returns the cursor to its saved place if any. The place is 
# still saved untill the save is changed.
# Arguments: None.
# Returns: 1 if restored, undef otherwise.

sub restorePlace {
    my $self = shift;
    if (exists($self->{Saved}) && ($self->{Saved} <= $self->childCount)) {
	$self->{Cursor} = $self->{Saved};
	return 1;
    }
    return undef;
}

# <clone> returns a new tree that is the same as the cloned one except for 
#   its lucky number.
# Arguments: None.
# Returns: None.

sub clone {
    my $self = shift;
    my ($lucky_number, $parent) = @_;

    unless (defined $lucky_number) {
	$lucky_number = getNewLucky;
	$counters[$lucky_number] = $counters[$self->{_LuckyNumber}];
    }

    my $cloned = {};
    $cloned->{$_} = $self->{$_} foreach (keys %$self);
    $cloned->{_ParentRef} = $parent;
    $cloned->{_LuckyNumber} = $lucky_number;
    $cloned->{Items} = [map {$_->clone($lucky_number, $cloned)} 
			@{ $self->{Items} }];
    
    return bless $cloned, ref($self);
}

# <deepProcess> runs a given subroutine on all descendants of a node.
# Arguments: $subref - the sub to be run.
#       all remaining arguments will be passed to the subroutine,
#       prepended by a ref to the node being processed.
# Returns: Nothing.

sub deepProcess {
    my $self = shift;
    my ($subref, @args) = @_;

    # I do not use the savePlace + reset metods, because the subroutine 
    # passed by the user may mess it up.
    foreach my $child (@{ $self->{Items} }) {
	$subref->($child, @args);
	$child->deepProcess($subref, @args);
    }
}

# <allProcess> does the same as deepProcess except that it also processes the 
#   root element.
# Arguments: see <deepProcess>.
# Returns: Nothing.

sub allProcess {
    my $self = shift;
    my ($subref, @args) = @_;
    
    $subref->($self, @args);
    $self->deepProcess($subref, @args);
}

#*******************************************************************
#   Accessors:

sub childCount {
    my $self = shift;
    return scalar @{$self->{Items}};
}

# There is no setNumber because numbers are handled only by the object.
sub getNumber {
    my $self = shift;
    return $self->{_Serial};
}

# same for LuckyNumber.
sub getLuckyNumber {
    my $self = shift;
    return $self->{_LuckyNumber};
}

sub getParentRef {
    my $self = shift;
    return $self->{_ParentRef};
}

# <getFieldNames> returns a list of fields for an object, not including Value.
# Arguments: None.
# Returns: The list in list context, a ref to it in scalar context.

sub getFieldNames {
    my $self = shift;
    return undef unless ($self->{Fields});
    
    if (wantarray) {
	return @{ $self->{Fields} };
    } else {
	return $self->{Fields};
    }
}

# <hasField> is a boolean function to determine if a field exists.
# Arguments: $name - field name.
# Returns: True if the field exists, undef if not.

sub hasField {
    my $self = shift;
    my $name = shift;

    for ($self->getFieldNames) {
	return 1 if ($_ eq $name);
    }
    return undef;
}

# <get/setField> accesses a field by name.
# Arguments: $name - field name.
#            $value - field value.
# Returns: Field value on success, undef otherwise.

sub getField {
    my $self = shift;
    my $name = shift;

    return $self->{$name} if $self->hasField($name);
    return undef;
}

sub setField {
    my $self = shift;
    my ($name, $value) = @_;

    return $self->{$name} = $value if $self->hasField($name);
    return undef;
}

# <getFields> returns a hash ref of field => value for each extra field.
# Arguments: None.
# Returns: See above.

sub getFields {
    my $self = shift;
    return undef unless ($self->{Fields});

    my %fields = map { $_ => $self->getField($_) } $self->getFieldNames;
    return \%fields;
}

sub setFields {
    my $self = shift;
    return undef unless ($self->{Fields});

    my (%fields) = @_;
    $self->setField($_, $fields{$_}) foreach (keys %fields);
}

# <addField> adds an extra field to the object.
# Arguments: $name - field name.
#            $value - field value.
# Returns: True on success, undef on failure (field exists).

sub addField {
    my $self = shift;
    my ($name, $value) = @_;
    
    # Fail if field exists or is a predefined field.
    return undef if (exists $self->{$name});
    
    push @{ $self->{Fields} }, $name;
    $self->{$name} = $value;
    return 1;
}

# <removeField> removes an extra field from the object.
# Arguments: $name - field name.
# Returns: True on success, undef on failure (field doesn't exist).

sub removeField {
    my $self = shift;
    my $name = shift;

    my @fields = $self->getFieldNames;
    for my $i (0..$#fields) {
	if ($fields[$i] eq $name) {
	    delete $self->{$name};
	    splice @fields, $i, 1;
	    $self->{Fields} = \@fields;
	    return 1;
	}
    }
    return undef;
}

#***********************************************************************
# scary: AUTOLOAD captures access requests for fields.

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/(.*):://;
    my $pkg = $1;

    if ($AUTOLOAD =~ /get(.*)$/) {
	return $self->getField($1) if $self->hasField($1);
	die ("No such field ($1) in tree");
    } elsif ($AUTOLOAD =~ /set(.*)$/) {
	return $self->setField($1, shift) if $self->hasField($1);
	die ("No such field ($1) in tree");
    }

    die "Can't call method $AUTOLOAD via package $pkg";
}

sub DESTROY {}
#***************************************************************************
#   Service methods.

# <getSubTree> returns the sub tree whose  root element's serial number
# is requested.
# Arguments: $serial - the requested serial number.
# Returns - the matching object if it's there, undef otherwise.

sub getSubTree {
    my ($self, $serial) = @_;
    return $self if ($serial == $self->getNumber);
    
    $self->savePlace;
    $self->reset;

    while (my $branch = $self->nextNode) {
	if ($branch->getNumber == $serial) {
	    $self->restorePlace;
	    return $branch;
	} elsif (my $subtree = getSubTree($branch, $serial)) {
	    $self->restorePlace;
	    return $subtree;
	}
    }
    $self->restorePlace;
    return undef;
}

# <listChildNumbers> returns a list of serial numbers of all items under
# an item whose serial number is given as an argument.
# Arguments: $serial - denoting the item requested.

sub listChildNumbers {
    my $self = shift;
    my $serial = shift;

    my @subSerials = ();
    my $subtree = ($serial) ? getSubTree($self, $serial) : $self;

    $subtree->savePlace;
    $subtree->reset;
    
    while (my $branch = $subtree->nextNode) {
	push @subSerials, $branch->{_Serial};
	
	if ($branch->childCount > 0) {
	    push @subSerials, $branch->listChildNumbers;
	}
    }

    $subtree->restorePlace;
    return @subSerials;
}

# <follow> Will find an item in a tree by its serial number 
#  and return a list of all values for a requested field up to and including 
#  the requested one. 
# Arguments: $serial - number of target node.
#            $field - field name (defauld - Value)

sub follow {
    my $self = shift;
    my ($serial, $field) = @_;
    $field ||= 'Value';   # backward compatibility.

    $self->savePlace;
    $self->reset;
        
    while (my $branch = $self->nextNode) {
	my @patharray = ();
	if ($branch->{_Serial} == $serial) {
	    $self->restorePlace;
	    return ($branch->getField($field));
	} elsif ($branch->childCount) {
	    @patharray = $branch->follow($serial, $field);
	}
	
	if ($#patharray >= 0) {
	    # Parent nodes go first:
	    unshift @patharray, $branch->getField($field);
	    $self->restorePlace;
	    return @patharray;
	}
    }

    $self->restorePlace;
    return ();
}

1;

=head1 NAME

Tree::Numbered - a thin N-ary tree structure with a unique number for each item.

=head1 SYNOPSYS

 use Tree::Numbered;
 my $tree = Tree::Numbered->new('John Doe');
 $tree->append('John Doe Jr.');
 $tree->append('Marry-Jane Doe');

 while (my $branch = $tree->nextNode) {
    $branch->delete if ($branch->getValue eq 'Stuff I dont want');
 }
 
 my $itemId = what_the_DB_says;
 print join ' --- ', $tree->follow($itemId); # a list of items up to itemId.
 
 $tree->allProcess( sub {
     my $self = shift;
     $self->getValue =~ /^(\S*)/;
     $self->addField('FirstName', $1);
 } );

 etc. 

=head1 DESCRIPTION

Tree::Numbered is a special N-ary tree with a number for each node. This is useful on many occasions. The first use I  found for that (and wrote this for) was to store information about the selected item as a number instead of storing the whole value which is space-expensive.

Every tree also has a lucky number of his own that distinguishes it from other trees created by the same module. This module is thin on purpose and is meant to be a base class for stuff that can make use of this behaveiour. For example, I wrote Tree::Numbered::DB which ties a tree to a table in a database, and Javascript::Menu which uses this tree to build menus for websites.

One more feature that the module implements for the ease of subclassing it is an API for adding and removing fields from trees and nodes.

=head1 BUILDING AND DESTROYING A TREE

=over 4

=item Tree::Numbered->new

There is only one correct way to start an independent tree with its own lucky number from scratch: calling the class function I<new>. Using new as a method is wrong because it will create a node for the same tree but the tree won't know of its existence. See below.

There are two forms of calling I<new>. The first is calling it with one argument only - the value for the node. If you do that, the tree / node  will be created with one field, called 'Value', and this field will receive the value you supplied as an argument.

The second form is calling I<new> with a hash of <field name> => <field value> pairs. For each pair, a field by the name <field name> be created, and it's value will be <field value>. The Value field will not be created unless you specifically request it. 

Note: Calling I<new> with no arguments is the same as calling it in the second form.

=item $tree->clone

Another way to obtain a new tree object is to clone an existing one. The clone method does that. The original object remains untouched.

=item $tree->append

This is the correct way to add an item to a tree or a branch thereof. Internally uses $tree->new but does other stuff. The arguments for I<append> are the same as for I<new>.

=item $tree->delete

Deletes the child pointed to by the cursor (see below) and returns the deleted item. Note that it becomes risky to use this item since its parent tree knows nothing about it from the moment it is deleted and you can cause collisions so use with caution.

=back

=head1 WORKING WITH FIELDS

As this module is designed for subclassing, I added a mechanism to easily create fields in a tree. Fields are different from normal object attributes in that they are specifically registered as fields within their object, and can be added, removed, and querried for existence. For every field a set of accessors is auto created (actually, autoloaded). In the section 'Subclassing Issues' there's more on using fields vs. regular attributes.

One more important thing to know about fields is that every node inherits all fields that his parent had at the moment of creation. The value of the field is also inherited unless the field was requested in the argument list for I<append>, in which case it takes the value provided as an argument.

Naming your fields: If you want to make use of the automatic accessors, you might want to name your fields with a capital first letter. This is because the accessors created for a field are nothing more then the name of the field prefixed with either 'get' or 'set'. Alternatively, use underscore-lower letter if that's your style.

=head2 But what if I only need one field for storing some value?

No problem - The module knows of a default field called 'Value' which is created if you only give one argument - the value - to I<new> or I<append>. When you build a tree like that, you'll have the methods getValue and setValue. Furthermore, the method I<follow> guesses that you want this field if you do not specify any other. So working with one field only is just a short-code version of working with many.

=head2 Methods for working with fields:

=over 4

=item getFieldNames

Returns a list of all registered fields within a node.

=item addField(name, [value])

Adds a field I<only> to the node on which the method was invoked. if value is not specified, the field's value will default to undef. If the field does not exist, will do nothing - won't even set its value.

If you need to add a field to all existing descendants of a node (future ones inherit the field automatically) use either I<deepProcess> or I<allProcess> as described above in 'Synopsys'.

Returns: True on success, undef on failure.

=item removeField(name)

Removes the field by that name, and deletes its value.

Returns: True on success, undef on failure.

=item getField(name)

Returns the value of the field given in the name argument. if the field does not exist returns undef. If you want to check if the field exists, use I<hasField> or try to call the automatic getter for that field, an attempt that will cause a painfull death if there's no such field.

=item setField(name, [value])

Sets the value of the requested field. If value is not specified, undef is assumed. Returns the new value on success, undef on failure (field does not exist).

=item getFields

Returns a reference to a hash of Field => Value pairs, for each field the node owns.

=item setFields([Field => Value, Field => Value, ...])

Sets the requested fields to the requested values. Keeps quiet if a field does not exist, so watch out.

=back

=head1 ITERATING OVER CHILD ITEMS

=head2 The cursor

Every node in the tree has its own cursor that points to the current item. When you start iterating, the cursor is placed just B<before> the first child. When you are at the last item, trying to move beyond the last item will put the 
cursor B<after> the last item (which will result in an undef value, signalling the end) but the next attempt will cause the cursor to B<start over> from the first child.

=head2 Methods for iteration

=over 4

=item nextNode

Moves the cursor one child forward and returns the pointed child.

=item reset

Resets the cursor to point before the first child.

=item savePlace

Allows you to save the cursor's place, do stuff, then go back. There is only one save, though, so don't try to nest saves.

=item restorePlace

Tries to set the cursor to the item at the same place as it was when its place was saved and returns true on success. If the saved place doesn't exist anymore returns undef. Note: If you deleted items from the tree you might not get to the right place.

=head1 ACCESSORS

The following accessors are always available and deal with the node's properties, not with fields:

=over 4

=item getNumber

Gets the number of the node within its tree. There is no setter since this number is special.

=item getLuckyNumber

Gets the number of the main tree that the node is a member of. Again, there is no setter since this is special.

=item getParentRef

Returns a reference to the parent of the node (of course the root will return undef).

=item childCount

Gets the number of childs for this node.

=back

Also, as described above, for each field you create, a getter and a setter automatically show up when needed. For each field *, you'll have the methods get* and set*.

=head1 THINGS YOU CAN DO WITH NODE NUMBERS

Well, I didn't include the node numbers just for fun, this is actually very needed sometimes. There are three basic service methods that use this (subclasses may add to this):

=over 4

=item getSubTree([number])

If a node who's number is given is a member of the subtree that the method was invoked on, that node will be  returned, undef otherwise. To be consistent with set theory, any tree is considered to be its own child, so giving the number of the root node will return that node.

=item listChildNumbers([number])

returns a list of all numbers of nodes that are decendants (any level) of the subtree whose number is given. Number is optional, the node's own number is used if no number is specifically requested.

=item follow(number, [field])

returns a list of all field values starting from the decendant node with the requested number, through every parent of the node and up to the node the method was invoked on. If no such node exists, returns an empty list. If no field is specified, defaults to the Value field.

=back

=head1 OTHER METHODS

There are two methods that apply a certain subroutine to whole trees:

=over 4

=item deepProcess (SUBREF, ARG, ARG, ...)

For each child of the node, runs the subroutine referenced by SUBREF with an argument list that starts with a reference to the child being processed and continues with the rest of the arguments passed to deepProcess. In short, your subroutine is called as a method of the child items, so you can shift $self out of the arguments list and use it.

=item allProcess (SUBREF, ARG, ARG, ...)

does the same as deepProcess but runs on the root node first.

=back

=head1 SUBCLASSING ISSUES

=over 4

=item Fields vs. normal attributes

The usual implementation of a data field is as a hash key, either in one hash per object, or one hash per property (an inside-out object). The fields mechanism allows you to maintain a list of fields, but assumes that the fields are regular data fields. My subclasses of this modules use Fields for regular data, but do not register as fields anything with 'magical' or 'internal use only' data. The reason is that not using fields gives more control over the behaveiour of these fields. 

For example, if you implement a property using the fields mechanism, and you don't want the user to access it, you'll have to manually override the automatic accessors to die or do something unpleasant when they're used.

Secondly, if you register a property as a field - it is easy to remove it by accident even if you count on it to always exist. That's bad, isn't it?

And lastly, if you count on a value to be frequently used, you might not want the overhead of autoloading the accessors or you don't need it in the list of fields.

The benefits of using fields, are in the easiness of managing a set of fields acording to changing demands and the simplicity of extending the behaveiour of a class. For example, check out my Javascript::Menu which creates the URL field if the user is just trying to build a navigational menu, but doesn't bother if the user uses the more complex, action based menus that I designed the module for.

=item Setting attributes that have no setters

You'll notice that none of the constant properties of this class (the number, lucky number and parent ref) have a setter. This is on purpose. These properties are determined automatically and are not supposed to be messed with.

If you do want to change the behaveiour, I assume that you know what you're doing and that you have read some source. Then you'll have no problem with implementing your desired behaveiour.

=item Extending field behaveiour

The fields mechanism, however, is more object-oriented. Everything that has to do with fields tries to use field methods even internally. Even I<new> calls addField to add fields. The main implication of this (that I found) is that if you want things to happen when a field is created, you must make sure that the data for this happening (if any is required) is already available at the time of adding the field. For an example of that, see how my Tree::Numbered::DB makes sure that a field mapping will always be available, before calling SUPER::new in its own constructor. 

=back

=head1 BUGS AND PROBLEMS

Works pretty well for me. If you found anything, please send a bug report:
E<lt>http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tree-NumberedE<gt>
or send mail to E<lt>bug-Tree-Numbered#rt.cpan.orgE<gt> 

=head1 SEE ALSO

Tree::Numbered::DB, Javascript::Menu

=head1 AUTHOR

Yosef Meller, E<lt> mellerf@netvision.net.il E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Yosef Meller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
