package Tree::Numbered::DB;

use strict;

use Tree::Numbered;

use DBI;

our $VERSION = '1.00';
our @ISA = qw(Tree::Numbered);

my %collumn_names = (_Serial => 'serial', 
		      _Parent => 'parent',
		     Value => 'name');

sub _addMapping; # predeclared method.

# Internal group of subs to determine whether we should write each change
# or do batch operations. 1 = every change.
{
    my $write_mode = 1;
    sub _turnOnWrite {
	$write_mode = 1;
    }
    sub _turnOffWrite {
	$write_mode = 0;
    }
    sub _WriteMode {return $write_mode};
}

# <getFieldsStr> returns a string of fields in the order they are returned
#  from getFieldNames
# Arguments: $cols - a hash of column mappings.
# Returns: See above,,,

sub _getFieldsStr {
    my $self = shift;
    return join ', ', map {$self->getMapping($_) . "=?"} 
    @{$self->getFieldNames} if $self->getFieldNames;
}

# <getStatements> a service method that prepares SQL statements used in the 
# module.
# Arguments: $colnames - names of the columns that make up the table (see
#            %collumn_names above).
# Returns: a hash with the statements.

sub getStatements {
    my $self = shift;
    my $serial = $self->getMapping('_Serial');
    my $parent = $self->getMapping('_Parent');

    my $extra = $self->_getFieldsStr || '';
    my $dbh = $self->{Source};
    my $table = $self->{SourceName};

    my %statements;
    $statements{add} = "insert into $table set " .
	"$parent=$self->{_Parent}, " . $extra;
    $statements{who} = "select max($serial) from $table";
    $statements{delete} = "delete from $table where $serial=?";
    $statements{update} = "update $table set " . $extra .
	" where $serial=?"; # We don't have a number yet...
    $statements{truncate} = "truncate $table";

    $self->{Statements} = {map {$_ => $dbh->prepare($statements{$_}) } 
			   keys %statements};
}

# <new> constructs a new tree or node.
# Arguments: By name: 
#       parent - the node's parent (for internal use).
#       source_name - table name.
#       source - DB handle.
#       *_col - column mapping.
#       * - column value.
#       serial_col - collumn name for serial numbers
#       parent_col - column name for parent numbers.
#       NoWrite - create the node without writing it to the DB (internal use). 
# Returns: The tree object.

sub new {
    my %reserved = map {$_ => 1} ('parent_col', 'serial_col', 
				  'parent', 'serial', 'NoWrite', 
				  'source', 'source_name');

    my $parent = shift;
    my %args = @_;

    my ($parent_serial, $class);
    _turnOffWrite; # turn off writing for a while.

    # Create the bloody thing. addField will search the parent for mappings.
    my $properties = $parent->SUPER::new;

    # Find out which mappings and fields
    my @colnames = grep(/_col$/, keys %args);
    my %colmaps = map {$_ => $args{$_}} @colnames;
    my %fields = %args;
    delete @fields{@colnames, keys %reserved};

    # Auto create fields with undefind value if a mapping exists for them.
    foreach (@colnames) {
	next if (exists $reserved{$_});
	s/_col$//;
	$fields{$_} = undef unless (exists $fields{$_});
    }

    # Create the Value field if no other field was requested:
    unless (scalar keys %fields) {
	#default field and map.
	$properties->_addMapping('Value', $collumn_names{Value});
	$fields{Value} = undef;
    }

    if ($class = ref($parent)) {
	# We're adding to an existing tree.
	$properties->{Source} = $parent->{Source};   
	$properties->{SourceName} = $parent->{SourceName};
	$properties->{_Parent} = $parent->{_Serial};

	# Inherit mappings:
	foreach my $field ($parent->getFieldNames) {
	    # Won't do anything if mapping is already there:
	    $properties->_addMapping($field, $parent->getMapping($field));
	}
	$properties->_addMapping('_Serial', $parent->getMapping('_Serial'));
	$properties->_addMapping('_Parent', $parent->getMapping('_Parent'));
    } else {
	# New tree. Check that args are correct:
	unless ($args{source_name} && $args{source}){
	    warn "No source or name, failed to create a tree.";
	    return undef; 
	}

	$class = $parent;
	$properties->{_Parent} = $args{parent} ||= 0;
	$properties->{Source} = $args{source} ||= '';   
	$properties->{SourceName} = $args{source_name} ||= '';

	# Use default mapping for mandatory fields::
	$properties->_addMapping('_Serial', $collumn_names{_Serial});
	$properties->_addMapping('_Parent', $collumn_names{_Parent});

    }

    # Use arguments for mappings for mandatory serial and parent.
    $properties->setMapping('_Serial', $colmaps{"serial_col"}) 
	if ($colmaps{"serial_col"});
    $properties->setMapping('_Parent', $colmaps{"parent_col"})
	if  ($colmaps{"parent_col"});
    
    # add mappings and fields.
    foreach (keys %fields) {
        # Fail if there's a field with no mapping.
	unless($colmaps{"${_}_col"} or $properties->getMapping($_)) {
	    warn "No mapping for field $_, unable to create a tree.";
	    return undef;
	}
	$properties->_addMapping($_, $colmaps{"${_}_col"});
	$properties->addField($_, $fields{$_}) or 
	    $properties->setField($_, $fields{$_});
    }
	     
    _turnOnWrite; # Ok, let's make it real:
    # Create SQL statements:
    $properties->getStatements;
    $properties->{_Serial} = addNodeDB($properties) unless $args{NoWrite};

    return $properties;
}

# <addNodeDB> adds a record to a table containing a tree.
# Arguments: $self - the node's hash. This is not a class method because the 
#            object we're operating on is not yet blessed.
# Returns: The new Serial number of the Item added.

sub addNodeDB {
    my $self = shift;
    my $parent = $self->{_Parent};
    # Preserve order of fields:
    my @values = map { $self->getField($_) } @{ $self->getFieldNames };

    $self->{Statements}->{add}->execute(@values) or return undef;
    $self->{Statements}->{who}->execute;
    return ($self->{Statements}->{who}->fetchrow_array)[0];
}

# <readDB> constructs a new tree from a pre-existing table.
# Arguments: $table - table name.
#            $dbh - database handle to operate on.
#            $cols - a hash giving alternative collumn names.
# Returns: The tree object.

sub read {
    my ($self, $table, $dbh, $cols) = @_;
    return undef if (ref $self); # Class method only, dude.

    # Some defaults:
    $cols ||= {Value_col => $collumn_names{Value}}; 
    $cols->{serial_col} ||= $collumn_names{_Serial};
    $cols->{parent_col} ||= $collumn_names{_Parent};

    my %fcols = %$cols; # field columns.
    delete @fcols{'serial_col', 'parent_col'};

    # Start construction of root element:
    my $tree = Tree::Numbered::DB->new(source => $dbh,
				       source_name => $table,
				       parent => 0,
				       NoWrite => 1, 
				       %$cols);

    my $extra = join '', map {', '.$tree->getMapping($_)} $tree->getFieldNames;
    $extra ||= '';

    my @parents = @{
	$dbh->selectall_arrayref("select $cols->{parent_col} from $table " . 
				 "group by $cols->{parent_col}")
	};
    # The prntnums hash is used to save calls to the DB. 
    # if a row is not a parent,
    # there's no need to query the database about its childs.
    my %prntnums = map {$_->[0] => 1} @parents;
    delete $prntnums{0}; # or endless recursion...

    # TO DO: make order-by a user choice instead of hard-coded.
    my $sth = $dbh->prepare("select $cols->{serial_col}" . $extra . 
			    " from $table where $cols->{parent_col}=?" .
			    " order by $cols->{serial_col}");
    $sth->execute(0);
    my $root = $sth->fetchrow_hashref;

    $tree->{_Serial} = $root->{$tree->getMapping('_Serial')};
    foreach my $field ($tree->getFieldNames) {
	$tree->setField($field, $root->{$tree->getMapping($field)});
    }
    $tree->recursiveTreeBuild($sth, $cols, %prntnums);

    return $tree;
}

sub recursiveTreeBuild {
    my ($self, $sth, $cols, %prntnums) = @_;
    my $serial = $self->{_Serial};

    $sth->execute(($serial));
    my %rows = %{$sth->fetchall_hashref($self->getMapping('_Serial'))};
    
    foreach my $row (keys %rows) {
	# Note that the mappings for #self are the same as those of $newNode.
	my %values = map { $_, $rows{$row}->{$self->getMapping($_)} } 
	$self->getFieldNames;
	$values{NoWrite} = 1;

	my $newNode = $self->append(%values);
	$newNode->{_Serial} = $row;

	next unless (delete $prntnums{$row});
	$newNode->recursiveTreeBuild($sth, $cols, %prntnums);
    }
}

# <delete> deletes the item pointed to by the cursor.
# The curser is not changed, which means it effectively moves to the next item.
# However it does change to be just after the end if it is already there,
# so you won't get an overflow.
# Arguments: None.
# Returns: The deleted item or undef if none was deleted.
#          Note that the returned item is invalid since it's deleted from its 
#          table.

sub delete {
    my $self = shift;
    my $deleted = $self->SUPER::delete;

    if ($deleted) { 
	$deleted->{Statements}->{delete}->execute($deleted->{_Serial}); 
    }
    return $deleted;
}

# <update> updates the database when something changes.
sub update {
    my $self = shift;
    my @values = (map { $self->getField($_) } 
		  @{ $self->getFieldNames } );
    $self->{Statements}->{update}->execute(@values, $self->getNumber);
}

# <truncate> removes the entire table tied to the tree. Kills the 
#  data structure.
# Arguments: None.
# Returns: Nothing.

sub truncate {
    my $self = shift;
    $self->{Statements}->{truncate}->execute;
    delete $self->{keys %$self}; # Suicide.
}

# <revert> re-blesses the tree into the parent class, losing DB Tie.
# Arguments: None.
# Returns: Nothing.

sub revert {
    my $self = shift;
    my $keep_data = shift;

    # Remove data specific to this class:
    unless ($keep_data) {
	delete $self->{Source};
	delete $self->{SourceName};
	delete $self->{Statements};
	delete $self->{Map};
    }
    $_->revert foreach (@{ $self->{Items} });

    return bless $self, $ISA[0];
}

#*******************************************************************
# Field <-> DB mappings

# <_addMapping> adds a mapping to a field if there isn't one already.
#  You are allowed to add mappings to nonexistent fields.
# Arguments: $field - field name.
#            $map - collumn name to be mapped to the field.
# Returns: map name on success, undef otherwise.

sub _addMapping {
    my $self = shift;
    my ($field, $map) = @_;

    return $self->{Map}->{$field} = $map unless ($self->{Map}->{$field});
    return undef;
}

sub _removeMapping {
    my $self = shift;
    my $field = shift;
    delete $self->{Map}->{$field};
}

sub getMapping {
    my $self = shift;
    my $field = shift;
    return $self->{Map}->{$field} if (exists $self->{Map}->{$field});
    return undef;
}

# <setMapping> changes the collumn mapping for a field.
# Arguments: $field - field name.
#            $value - new column name.
# Returns: the new map value (undef if set failed).

sub setMapping {
    my $self = shift;
    my ($field, $value) = @_;

    return undef unless (exists $self->{Map}->{$field});
    $self->{Map}->{$field} = $value;
    $self->getStatements if _WriteMode;
    return $self->{Map}->{$field};
}

#*******************************************************************
# Overloaded setters:

sub setField {
    my $self = shift;
    $self->SUPER::setField(@_);
    $self->update if (_WriteMode);
}

sub setFields {
    my $self = shift;
    return undef unless ($self->{Fields});

    my (%fields) = @_;
    $self->SUPER::setField($_, $fields{$_}) foreach (keys %fields);
    $self->update if (_WriteMode);
}

# <addField> adds a field and a mapping if necessary. Fails if can't find 
#   mapping.
# Order of search for a mapping:
#   Argument -> Existing -> Parent -> Fail.
# Arguments: $field - field name to add.
#            $arg - field value.
#            $map - a mapping for the field.
# Returns: undef on failure, true on success.

sub addField {
    my $self = shift;
    my ($field, $arg, $map) = @_;

    $map ||= $self->getMapping($field) || 
	$self->getParentRef->getMapping($field);
    return undef unless ((defined $field) && $map);

    $self->_addMapping($field, $map) or $self->setMapping($field, $map);
    my $rv = $self->SUPER::addField($field, $arg);

    if (_WriteMode) {
	$self->getStatements; 
	$self->update;
    }
    return $rv;
}

# <removeField> removes a field and its mapping.
# Arguments: $field - name of field to be removed.
#            $keep_map - wil not delete mapping if true.
# Returns: undef on failure, true on success.

sub removeField {
    my $self = shift;
    my ($field, $keep_map) = @_;

    my $rv = $self->SUPER::removeField($field);
    $self->_removeMapping($field) unless ($keep_map);
    return $rv;
}

1;

=head1 NAME

 Tree::Numbered::DB - a tree that is stored in / tied to a DB table.

=head1 SYNOPSIS

  use NumberedTree::DBTree;
  my $dbh = DBI->connect(...);

  # The easy way:
  my $tree = NumberedTree::DBTree->read($table, $dbh);

  # The hard way:
  my $tree = NumberedTree::DBTree->new(source_name => 'a_table', 
                                       source => $dbh);
  while (I aint sick of it) {
  	$tree->append($newValue);
  }
  
  etc.
  
=head1 DESCRIPTION

Tree::Numbered::DB is a child class of Tree::Numbered that supplies database tying (every change is immediately reflected in the database) and reading using tables that are built to store a tree (the structure is described below). It's basically the same as Tree::Numbered except for some methods. These, and arguments changes for inherited methods, are also described below. For the rest, please refer to the documentation for Tree::Numbered.

Tree::Numbered::DB allows you to change the relations between the table and the tree, by adding and deleting fields on runtime, thus giving you a lot of flexibility in working with big tables. The mechanism for that is described below in short. A lot about dealing with fields can be found in the docs for Tree::Numbered.

To see a working example, see example.pl in the distribution directory.

=head1 CREATING A TABLE FOR THE TREE

A table used by this module must have at least 2 columns: the serial number column (by default 'serial') and the parent column (default - 'parent'). There is also a default field column for the field Value ('name') if you want this field to be created. If the default names don't suit you, don't worry - you can supply different names to the constructors. 

Serial numbers start from any number greater than zero and must be auto increment fields. Parent numbers of course are the serial numbers of the parent for each node - the root node B<always> takes parent number 0.

 Example SQL statement to build the table (tested on MySQL):  
 create table places (serial int auto_increment primary key, 
 				  parent int not null, 
				  name varchar(20));

=head1 MAPPING FIELDS TO DATA ATTRIBUTES

To create a simple menu with one field as value, the defaults will do. However, if you are looking for something more complex, or if  you have an existing table and you can't (or won't) change its collumn names, you'll have to tell the module which fields you want, and which column maps to what field. There are two ways of doing this:

=over 4

=item *

Supplying the field name and field value to the constructor (see below). 

=item *

Using the method I<addField>.

=back

Whenever a field is added in any way, the module tries to resolve its mapping in the following order (low precedence first):

  Existing mapping (e.g. from a deleted field, or default) -->
  Mapping for the same field found in the parent of the node -->
  Mapping suplied as an argument.

If no proper mapping can be found, the method that attempted to create the field will fail.  

When deleting a field, you have the option of keeping its mapping in memory, allowing you to remount that field easily.

=head1 METHODS

This section only describes methods that are not the same as in Tree::Numbered. Mandatory arguments are marked.

=head2 Constructors

There are two of them:

=over 4

=item new (source => I<source>, source_name => I<source_name>, somefield => value, somefield_col => mapping, ...)

creates a new tree object that uses an empty table named E<lt>I<source_name>E<gt> using a DBI database handle supplied via the I<source> argument. for each field you want to create, you must give a mapping key in the arguments hash. The key is the name of the field postfixed with B<_col>. The value is the name of the collumn to map to that field.

For each mapping key specified, a field will be created, even if you don't specify a starting value. 

There are also two special mapping keys you can give to replace module defaults: 'serial_col' will change the mapping for the serial number column from the default to whatever you give it, and 'parent_col' will do the same for the collumn that holds the parent numbers.

Note that you should not add nodes to an existing tree using this method. Instead, use I<append>.

=item read (I<SOURCE_NAME>, I<SOURCE>, MAP)

creates a new tree object from a table named I<SOURCE_NAME> that contains tree data as specified above, using a DB handle given in I<SOURCE>. The optional MAP argument takes a reference to a hash of mappings, as described in new. If you do not supply this, the defaults will be used (including the creation of the Value field). As in I<new>, you can use this argument to replace module default mappings.

=back

=head2 Overriden and new methods in this class.

Two methods are added to this class:

=over 4

=item truncate

Activates the truncate SQL command, effectively deleting all data in a table, but not the table itself. This also disposes of the tree object, so you'll have to build a new one after using this method.

=item revert

Removes information that is specific to this class and re-blesses the entire tree into the parent class. Does not lose fields! Use this method if you just want to read the tree, then do stuff that's not related to the DB.

=item get/setMapping (I<field>, I<map>)

Either sets the mapping of a field to whatever you give it or gets the current value of the mapping for a field (in that case ther's only one argument, the field name).

=back

Overriden methods that changed arguments:

=over 4

=item addField(I<name>, value, mapping)

Adds a field to its node B<only>. New child nodes will inherit it, but old child nodes will not automatically add that field to themselves. The mapping argument is optional if the module can find the mapping using the search order described above, in 'Mapping fields to data attributes.

=back

=head1 METHOD SUMMARY (NEW + INHERITED)

The following is a categorized list of all available meyhods, for quick reference. Methods that do not appear in the source of this module are marked:

=over 4

=item Object lifecycle:

new, read, delete, *append, truncate, revert.

=item Iterating and managing children:

*nextNode, *reset, *savePlace, *restorePlace, *childCount, *getSubTree, *follow

=item Fields and mappings

addField, removeField, setField, setFields, *getField, *getFields, *hasField, addMapping, removeMapping

=back

=head1 BUGS AND OTHER ISSUES

 Please report through CPAN: 
 E<lt>http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tree-Numbered-DBE<gt>
 or send mail to E<lt>bug-Tree-Numbered-DB#rt.cpan.orgE<gt> 
 
 For sugestions, questions and such, email me directly.

=head1 SEE ALSO

Tree::Numbered, Javascript::Menu

=head1 AUTHOR

Yosef Meller, E<lt>mellerf@netvision.net.ilE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Yosef Meller

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
