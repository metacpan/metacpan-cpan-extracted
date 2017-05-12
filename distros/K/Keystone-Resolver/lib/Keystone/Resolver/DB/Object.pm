# $Id: Object.pm,v 1.34 2008-04-29 17:05:38 mike Exp $

package Keystone::Resolver::DB::Object;

use strict;
use warnings;
use Carp;


sub new {
    my $class = shift();
    my($db) = shift();

    my @fields = $class->physical_fields();
    my %hash = (_db => $db);
    foreach my $i (1 .. @fields) {
	my $key = $fields[$i-1];
	my $value = $_[$i-1];
	$hash{$key} = $value;
    }

    return bless \%hash, $class;
}


sub class {
    my $this = shift();
    my $class = ref $this;
    $class =~ s/^Keystone::Resolver::DB:://;
    return $class;
}


# Accessors and delegations
sub db { shift()->{_db} }
sub log { shift()->{_db}->log(@_) }
sub quote { shift()->{_db}->quote(@_) }

# Default implementations of subclass-specific virtual functions
# fields() must be explicitly provided for searchable classes
# virtual_fields() must be explicitly provided for searchable classes
sub mandatory_fields { qw() }
# search_fields() must be explicitly provided for searchable classes
# display_fields() must be explicitly provided for searchable classes
sub fulldisplay_fields { shift()->display_fields(@_) }
sub field_map { {} }


# Returns an empty array if it's OK to delete this object, or
# otherwise an array of one or more strings, each specifying a reason
# why not.  Can be overridden by subclasses, but by default insists on
# no non-dependent links.
#
sub undeletable {
    my $this = shift();

    my @reasons;
    my %fields = $this->fields();
    foreach my $key (sort keys %fields) {
	my $ref = $fields{$key};
	if (ref $ref && defined $ref->[3]) {
	    my($linkfield, $linkclass, $linkto) = @$ref;
	    ### This is wasteful: it would be better to use a method
	    #   that only counts hits instead of fetching all the data
	    #   and constructing all the objects, but there is as yet
	    #   no such method,
	    my @hits = $this->db()->find($linkclass, undef, $linkto,
					 $this->field($linkfield));
	    my $n = @hits;
	    if ($n == 1) {
		push @reasons, "a $linkclass depends on it";
	    } elsif ($n != 0) {
		push @reasons, "$n $linkclass objects depend on it";
	    }
	}
    }

    return @reasons;
}


# Returns a list of all the field specified by fields(), with types
# drawn from fulldisplay_fields() where available and using "t" when
# not.
#
# Fields which are used as the link-field in a virtual-field recipe
# of the "dependent-link" type are omitted (e.g. service_type_id
# from the Service class, because it is the link-field in the
# service_type recipe).
#
# Virtual fields that are of not of the "dependent-link" type have a
# exclude-at-creation-time attribute prepended to their type, if they
# don't already have it.
#
sub editable_fields {
    my $class = shift();

    my @allfields = $class->fields();
    my %hash = @allfields;
    my(%omitFields, %virtualFields);
    foreach my $key (keys %hash) {
	my $value = $hash{$key};
	if (defined $value && ref $value) {
	    ### The correct test here might not be for @$value==3 but
	    #   something like defined $value[3].  See all the virtual
	    #   fields in Service.pm and think harder.
	    if (@$value == 3) {
		$omitFields{$value->[0]} = 1;
	    } else {
		$virtualFields{$key} = 1;
	    }
	}
    }

    foreach my $skip ($class->uneditable_fields()) {
	$omitFields{$skip} = 1;
    }

    my %fdfields = $class->fulldisplay_fields();
    my @res;

    while (@allfields) {
	my $name = shift @allfields;
	my $recipe = shift @allfields;
	if (defined $omitFields{$name}) {
	    warn "omitting '$name' from editable_field($class)\n";
	    next;
	}

	my $display = $fdfields{$name} || "t";
	if (defined $virtualFields{$name}) {
	    $display = "X$display" if $display !~ /X/;
	    warn "made '$name' readonly '$display' in editable_field($class)\n";
	}

	push @res, ($name, $display);
    }

    return @res;
}


# List of fields to omit from the return of editable fields (unless
# that method has been overridden, of course).  This list is empty in
# general, but can be used to knock out link-fields and suchlike as
# required.
#
sub uneditable_fields {
    return ();
}


sub physical_fields {
    my $class = shift();

    my @allfields = $class->fields();
    my @pfields;
    while (@allfields) {
	my $name = shift @allfields;
	my $recipe = shift @allfields;
	push @pfields, $name if !defined $recipe;
    }

    return @pfields;
}


sub virtual_fields {
    my $class = shift();

    my @allfields = $class->fields();
    my @vfields;
    while (@allfields) {
	my $name = shift @allfields;
	my $recipe = shift @allfields;
	push @vfields, $name, $recipe if defined $recipe;
    }

    return @vfields;
}


# Parses full-type strings such as those used on the RHS of
# display_fields() arrays, e.g. "c", "Lt", "Rn".  Returns an array of
# four elements:
#	0: whether the field is a link
#	1: whether the field is readonly
#	2: the field's core type
#	3: whether the field should be excluded at creation time.
# (It would make more sense if 2 and 3 were reversed, but existing
# code assumes the first three elements from before the fourth was
# added.)
#
sub analyse_type {
    my $_unused_this = shift();
    my($type, $field) = @_;

    return (undef, undef, $type) if ref $type;
    my $link = ($type =~ s/L//);
    my $readonly = ($type =~ s/R//);
    my $exclude = ($type =~ s/X//);
    # Special-case the fields that we know may never change
    $readonly = 1 if grep { $field eq $_ } qw(id tag);

    return ($link, $readonly, $type, $exclude);
}


# Returns name of CSS class to be used for displaying fields of the
# specified type.  ### Knows about what's in "style.css"
#
sub type2class {
    my $this = shift();
    my($type) = @_;

    return "enum" if ref($type) eq "ARRAY";
    return $type if grep { $type eq $_ } qw(t c n b);
    return "error";
}


sub create {
    my $class = shift();
    my($db, %maybe_data) = @_;

    my %data;
    foreach my $key (keys %maybe_data) {
	$data{$key} = $maybe_data{$key}
	    if $maybe_data{$key} ne "" &&
	    grep { $_ eq $key } $class->physical_fields();
    }

    my $table = $class->table();
    my $sql = "INSERT INTO " . $db->quote($table) .
	" (" . join(", ", map { $db->quote($_) } sort keys %data) . ") VALUES" .
	" (" . join(", ", map { sql_quote($data{$_}) } sort keys %data) . ")";
    $db->do($sql);
    my $id = $db->last_insert_id($table);
    die "can't get new record's ID" if !defined $id;

    return $db->find1($class, id => $id);
}


sub sql_quote {
    my($text) = @_;
    my $sq = "'";

    $text =~ s/$sq/''/g;
    return "'$text'";
}


# Returns a label to be used on-screen for the specified field
sub label {
    my $this = shift();
    my($field, $label) = @_;

    return $label if defined $label;
    my $map = $this->field_map();
    $label = $map->{$field};
    return $label if defined $label;

    # No explicit label passed, and none in config: use default rules
    $label = $field;
    $label =~ s/_/ /g;
    return ucfirst($label);
}


# Return the components needed to identify a linked-to object
sub link {
    my $this = shift();
    my($field) = @_;

    my %virtual = $this->virtual_fields();
    my $ref = $virtual{$field};
    return undef if !defined $ref;
    my($linkfield, $linkclass, $linkto) = @$ref;
    my $linkid = $this->field($linkfield);

    return ($linkclass, $linkto, $linkid, $linkfield);
}


# Returns the number of fields modified, dies on error
sub update {
    my $this = shift();
    my(%maybe_data) = @_;

    my %data;
    foreach my $key (keys %maybe_data) {
	$data{$key} = $maybe_data{$key}
	    if (!defined $this->field($key) ||
		$maybe_data{$key} ne $this->field($key));
    }

    return 0 if !%data;		# nothing to do
    my $sql = "UPDATE " . $this->quote($this->table()) . " SET " .
	join(", ", map { $this->quote($_) . " = " . sql_quote($data{$_}) } sort keys %data) .
	" WHERE " . $this->quote("id") . " = " . $this->id();

    $this->db()->do($sql);
    foreach my $key (keys %data) {
	$this->field($key, $data{$key});
    }

    return scalar keys %data;
}


sub delete {
    my $this = shift();

    my $sql = "DELETE FROM " . $this->quote($this->table()) .
	" WHERE " . $this->quote("id") . " = " . $this->id();

    $this->db()->do($sql);
    # Wow, that embarrasingly easy
}


sub field {
    my $this = shift();
    my($fieldname, $value) = @_;

    die "$this: request for system-function field '$fieldname'"
	if grep { $_ eq $fieldname } qw(table fields mandatory_fields
					physical_fields
					virtual_fields search_fields
					sort_fields display_fields
					fulldisplay_fields field_map
					field);

    if (grep { $_ eq $fieldname } $this->physical_fields()) {
	$this->{$fieldname} = $value if defined $value;
	return $this->{$fieldname};
    }

    my %virtual;
    eval { %virtual = $this->virtual_fields() };
    if (!defined $virtual{$fieldname}) {
	confess "$this: field `$fieldname' not defined";
    } elsif (defined $value) {
	die "can't set virtual field '$fieldname'='$value'";
    } else {
	return $this->virtual_field($fieldname);
    }
}


sub virtual_field {
    my $this = shift();
    my($fieldname) = @_;

    my %virtual = $this->virtual_fields();
    my $ref = $virtual{$fieldname};
    my($linkfield, $class, $linkto, $sortby, $valfield) = @$ref;

    my $value = $this->field($linkfield);
    return undef if !defined $value; # e.g. link-field in new record

    if (defined $sortby) {
	# Link is to multiple records
	my @obj = $this->db()->find($class, $sortby, $linkto, $value);
	#warn "$this->virtual_fields($fieldname) -> @obj";
	return [ @obj ];
    }

    # Link is to a single "parent" record
    my $obj = $this->db()->find1($class, $linkto, $value);
    if (!defined $obj) {
	# The link is broken!  The Dark Lord's reign begins!
	return "[$class:$linkto:$value]";
    }

    if (defined $valfield) {
	return $obj->field($valfield);
    } else {
	return $obj->render_name();
    }
}


sub AUTOLOAD {
    my $this = shift();

    my $class = ref $this || $this;
    use vars qw($AUTOLOAD);
    (my $fieldname = $AUTOLOAD) =~ s/.*:://;
    die "$class: request for field '$fieldname' on undefined object"
	if !defined $this;

    return $this->field($fieldname, @_);
}


sub DESTROY {} # Avoid warning from AUTOLOAD()


sub render {
    my $this = shift();
    my $class = ref($this);

    my $name;
    eval {
	$name = $this->tag();
    }; if ($@ || !$name) {
	undef $@;		### should this really be necessary?
	eval {
	    $name = $this->name();
	}; if ($@ || !$name) {
	    undef $@;		### should this really be necessary?
	    $name = undef;
	}
    }

    my $text = "$class " . $this->id();
    $text .= " ($name)" if defined $name;
    return $text;
}


sub render_name {
    my $this = shift();

    my $res;
    eval { $res = $this->name() };
    if (!$@ && defined $res) {
	#warn "returning name()='$res'";
	return $res;
    }
    eval { $res = $this->tag() };
    if (!$@ && defined $res) {
	#warn "returning tag()='$res'";
	return $res;
    }

    my $id = $this->id();
    if (defined $id) {
	#warn "returning id '$id'";
	return ref($this) . " " . $id;
    }

    #warn "returning new";
    return "[NEW]";
}


1;
