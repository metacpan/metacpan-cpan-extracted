package Elive::DAO;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

our $VERSION = '1.37';

use parent 'Elive::DAO::_Base';

use YAML::Syck;
use Scalar::Util qw{weaken};
use Carp;
use Try::Tiny;
use URI;

use Elive::Util qw{1.37};

__PACKAGE__->mk_classdata('_entities' => {});
__PACKAGE__->mk_classdata('_aliases');
__PACKAGE__->mk_classdata('_derivable' => {});
__PACKAGE__->mk_classdata('_entity_name');
__PACKAGE__->mk_classdata('_primary_key' => []);
__PACKAGE__->mk_classdata('_params' => {});
__PACKAGE__->mk_classdata('collection_name');
__PACKAGE__->mk_classdata('_isa');

foreach my $accessor (qw{_db_data _deleted _is_copy}) {
    __PACKAGE__->has_metadata($accessor);
}

=head1 NAME

Elive::DAO - Abstract class for Elive Data Access Objects

=head1 DESCRIPTION

This is an abstract class for retrieving and managing objects mapped to a
datastore.

=cut

our %Stored_Objects;

sub BUILDARGS {
    my ($class, $raw, @args) = @_;

    warn "$class - ignoring arguments to new: @args\n"
	if @args;

    if (Elive::Util::_reftype($raw) eq 'HASH') {

	my $types = $class->property_types;

	my %cooked;

	my $aliases = $class->_get_aliases;

	foreach (keys %$raw) {

	    #
	    # apply any aliases
	    #

	    my $prop = (exists $aliases->{$_}
			? ($aliases->{$_}{to} or die "$class has malformed alias: $_")
			: $_);

	    my $value = $raw->{$_};
	    if (my $type = $types->{$prop}) {
		if (ref($value)) {
		    #
		    # inspect the item to see if we need to stringify an
		    # object to obtain a simple string. The property is
		    # likely to be a foreign key.
		    #
		    $value = Elive::Util::string($value, $type)
			unless Elive::Util::inspect_type($type)->is_ref;
		}		    
	    }
	    else {
		Carp::carp "$class: unknown property: $prop";
	    }

	    $cooked{$prop} = $value;
	}

	return \%cooked;
    }

    return $raw;
}

=head1 METHODS

=cut

sub stringify {
    my $class = shift;
    my $data = shift;

    $data = $class
	if !defined $data && ref $class;

    return $data
	unless $data && Elive::Util::_reftype($data);

    my @primary_key = $class->primary_key
	or return; # weak entity - e.g. Elive::StandardV2::ServerVersions

    my $types = $class->property_types;

    my $string = join('/', map {Elive::Util::_freeze($data->{$_},
						     $types->{$_})}
		      @primary_key);

    return $string;
}

=head2 entity_name

    my $entity_name = MyApp::Entity::User->entity_name
    ok($entity_name eq 'user');

=cut

sub entity_name {
    my $entity_class = shift;

    if (my $entity_name = shift) {

	#
	# Set our entity name. Register it in our parent
	#
	$entity_class->_entity_name(ucfirst($entity_name));

	my $entities = $entity_class->_entities;

	die "Entity $entity_name redeclared "
	    if exists $entities->{$entity_name};

	$entities->{lcfirst($entity_name)} = $entity_class;
    }

    return $entity_class->_entity_name;
}

=head2 collection_name

    my $collection_name = MyApp::Entity::User->collection_name
    ok($collection_name eq 'users');

=cut

# Class::Data::Inheritable property

# _alias, _get_aliases
#
#    MyApp::Entity::Meeting->_alias(requiredSeats => 'seats');
#
# Return or set data mappings.
#
# These methods assist with the handling of data inconsistancies that
# sometimes exist between freeze/thaw property names; or between versions.
# These are always trapped at the data level (_freeze & _thaw).
#

sub _alias {
    my ($entity_class, $from, $to, %opt) = @_;

    $from = lcfirst($from);
    $to = lcfirst($to);

    die 'usage: $entity_class->_alias(alias, prop, %opts)'
	unless ($entity_class
		&& $from && !ref($from)
		&& $to && !ref($to));

    my $aliases = $entity_class->_get_aliases;

    #
    # Set our entity name. Register it in our parent
    #
    die "$entity_class: attempted redefinition of alias: $from"
	if $aliases->{$from};

    die "$entity_class: can't alias $from it's already a property!"
	if $entity_class->meta->get_attribute($from);

    die "$entity_class: attempt to alias $from to non-existant property $to - check spelling and declaration order"
	unless $entity_class->meta->get_attribute($to);

    $opt{to} = $to;
    $aliases->{$from} = \%opt;

    return \%opt;
}

sub _get_aliases {
    my $entity_class = shift;

    my $aliases = $entity_class->_aliases;

    unless ($aliases) {
	$aliases = {};
	$entity_class->_aliases( $aliases );
    }

    return $aliases
}

=head2 id

    my @primary_vals = $entity_obj->id

Return primary key values.

=cut

sub id {
    my $self = shift;
    return map {$self->$_} ($self->primary_key );
}

=head2 primary_key

Setter/getter for primary key field(s) for this entity class

    my @pkey = MyApp::Entity::User->primary_key

=cut

sub primary_key {
    my ($entity_class, @pkey) = @_;

    $entity_class->_primary_key(\@pkey)
	if (@pkey);

    return @{$entity_class->_primary_key};
}

=head2 params

Setter/getter for parameter field(s) for this entity class

    Elive::Entity::User->params(loginName => 'Str');
    my %params = MyApp::Entity::User->params;

=cut

sub params {
    my ($entity_class, %params) = @_;

    $entity_class->_params(\%params)
	if (keys %params);

    return %{$entity_class->_params};
}

=head2 derivable

Setter/getter for derivable field(s) for this entity class

=cut

sub derivable {
    my ($entity_class, %derivable) = @_;

    $entity_class->_derivable(\%derivable)
	if (keys %derivable);

    return %{$entity_class->_derivable};
}

=head2 entities

    my $entities = Entity::Entity->entities

    print "user has entity class: $entities->{user}\n";
    print "meetingParticipant entity class has not been loaded\n"
        unless ($entities->{meetingParticipant});

Return has hash ref of all loaded entity names and classes

=cut

sub entities {
    my $entity_class = shift;

    return $entity_class->_entities;
}

sub _ordered_attribute_names {
    my $class = shift;

    my %order;
    my $rank;
    #
    # Put primary key fields at the top
    #
    foreach ($class->primary_key) {
	$order{$_} = ++$rank;
    }

    #
    # Sort remaining fields alphabetically
    #
    my @atts = $class->meta->get_attribute_list;

    foreach (sort @atts) {
	$order{$_} ||= ++$rank;
    }

    my @atts_sorted = sort {$order{$a} <=> $order{$b}} (keys %order);
    return @atts_sorted;
}

sub _ordered_attributes {
    my $class = shift;

    my $meta = $class->meta;

    return map {$meta->get_attribute($_) or die "$class: unknown attribute $_"} ($class->_ordered_attribute_names);
}

sub _cmp_col {
    my ($class, $data_type, $v1, $v2, %opt) = @_;

    #
    # Compare two values for a property 
    #

    return
	unless (defined $v1 && defined $v2);

    my $type_info = Elive::Util::inspect_type($data_type);
    my $array_type = $type_info->array_type;
    my $type = $type_info->elemental_type;
    my $cmp;

    if ($array_type || $type_info->is_struct) {
	#
	# Note shallow comparision of entities and arrays.
	#
	my $t = $array_type || $type;
	$cmp = $t->stringify($v1) cmp $t->stringify($v2);
    }
    elsif ($type =~ m{^Ref|Any}ix) {
	$cmp = YAML::Syck::Dump($v1) cmp YAML::Syck::Dump($v2);
    }
    else {
	#
	# Elemental comparision. Use normalised frozen values
	#
	$v1 = Elive::Util::_freeze($v1, $type);
	$v2 = Elive::Util::_freeze($v2, $type);

	if ($type =~ m{^(Str|Enum|HiResDate)}ix) {
	    #
	    # string comparision. works on simple strings and
	    # stringified entities. Also used for hires dates
	    # integer comparision may result in arithmetic overflow
	    #
	    $cmp = ($opt{case_insensitive}
		    ? uc($v1) cmp uc($v2)
		    : $v1 cmp $v2);
	}
	elsif ($type =~ m{^Bool}ix) {
	    # boolean comparison
	    $cmp = ($v1 eq 'true'? 1: 0) <=> ($v2 eq 'true'? 1: 0);
	}
	elsif ($type =~ m{^Int}ix) {
	    # int comparision
	    $cmp = defined $v1 && defined $v2 && $v1 <=> $v2;
	}
	else {
	    Carp::croak "class $class: unknown type: $type\n";
	}
    }

    warn YAML::Syck::Dump {cmp => {result =>$cmp,
			     class => $class,
			     data_type => "$data_type",
			     v1 => $v1,
			     v2 => $v2
		     }}
    if ($class->debug||0) >= 5;

    return $cmp;
}

=head2 properties

   my @properties = MyApp::Entity::User->properties;

Return the property accessor names for an entity

=cut

sub properties {
    my $class = shift;
    return map {$_->name} ($class->_ordered_attributes);
}

=head2 property_types

   my $user_types = MyApp::Entity::User->property_types;
   my $type_info = Elive::Util::inspect_type($user_types->{role})

Return a hashref of attribute data types.

=cut

sub property_types {
    my $class = shift;

    my @atts = $class->_ordered_attributes;

    return {
	map {$_->name => $_->type_constraint} @atts
    };
}

=head2 property_doco

    my $user_doc = MyApp::Entity::User->property_doc
    my $user_password_doco = $user_doc->{loginPassword}

Return a hashref of documentation for properties

=cut

sub property_doco {
    my $class = shift;

    my @atts = $class->_ordered_attributes;

    return {
	map {$_->name => $_->{documentation}} @atts
    };
}

=head2 stringify

Return a human readable string representation of an object. For database
entities, this is the primary key:

    if ($user_obj->stringify eq "11223344") {
        ....
    }

Arrays of sub-items evaluated, in a string context, to a semi-colon separated
string of the individual values sorted.

    my $group = Elive::Entity::Group->retrieve(98765);
    if ($group->members->stringify eq "11223344;2222222") {
         ....
    }

In particular meeting participants stringify to userId=role, e.g.

    my $participant_list = Elive::Entity::ParticipantList->retrieve(98765);
    if ($participant_list->participants->stringify eq "11223344=3;2222222=2") {
         ....
    }

=cut

=head2 connection

    my $default_connection = Elive::Entity::User->connection;
    my $connection = $entity_obj->connection;

Return a connection. Either the actual connection associated with a entity
instance, or the default connection that will be used.

=cut

=head2 disconnect

Disconnects and disassociates an Elluminate connection from this class. It is
recommended that you do this prior to exiting your program.

=cut

sub disconnect {
    my ($class, %opt) = @_;

    if (my $connection = $class->connection) {
	$connection->disconnect;
	$class->connection(undef);
    }

    return;
}

sub _restful_url {
    my $class = shift;
    my $connection = shift || $class->connection;
    my $path = shift;

    my $uri_obj = URI->new( $connection->url );
    $uri_obj->scheme('http');

    return join('/', $uri_obj->as_string,
		$class->entity_name,
		$path);
}

=head2 url

    my $url = $user->url

Abstract method to compute a restful url for an object instance. This will
include both the url of the connection string and the entity class name. It
is used internally to uniquely identify and cache objects across repositories.

=cut

sub url {
    my $self = shift;
    my $connection = shift || $self->connection;
    my $path = $self->stringify
	or return;
    return $self->_restful_url($connection, $path);
}

=head2 construct

    my $user = Entity::User->construct(
            {userId = 123456,
             loginName => 'demo_user',
             role => {
                 roleId => 1
               }
             },
             overwrite => 1,        # overwrite any unsaved changes in cache
             connection => $conn,   # connection to use
             copy => 1,             # return a simple blessed uncached object.
           );

Abstract method to construct a data mapped entity. A copy is made of the
data for use by the C<is_changed> and C<revert> methods.

=cut

sub construct {
    my ($class, $data, %opt) = @_;

    $data = $class->BUILDARGS($data) if $class->can('BUILDARGS');

    croak "usage: ${class}->construct( \\%data )"
	unless (Elive::Util::_reftype($data) eq 'HASH');

    do {
	my %unknown_properties;
	@unknown_properties{keys %$data} = undef;
	delete $unknown_properties{$_} for ($class->properties);
	my @unknown = sort keys %unknown_properties;
	carp "$class - unknown properties: @unknown" if @unknown;
    };

    warn YAML::Syck::Dump({class => $class, construct => $data})
	if (Elive->debug > 1);

    my $self;

    $self = Scalar::Util::blessed($data)
	? $data
	: $class->new($data);

    my $connection = delete $opt{connection} || $class->connection
	or die "not connected";

    my %primary_key_data = map {$_ => $data->{ $_ }} ($class->primary_key);

    foreach (keys %primary_key_data) {
	unless (defined $primary_key_data{ $_ }) {
	    die "can't construct $class without value for primary key field: $_";
	}
    }

    $self->_is_copy(1)
	if $opt{copy};

    my $data_copy = Elive::Util::_clone($self);
    return $self->__set_db_data($data_copy,
				connection => $connection,
				overwrite => $opt{overwrite},
	);
}

sub __set_db_data {
    my $struct = shift;
    my $data_copy = shift;
    my %opt = @_;

    my $connection = $opt{connection};

    my $type = Elive::Util::_reftype( $struct );

    if ($type) {

	if (Scalar::Util::blessed $struct
	    && $struct->can('_is_copy')) {

	    $opt{copy} ||=  $struct->_is_copy;

	    $struct->_is_copy(1)
		if $opt{copy};
	}  

	# recurse
	if ($type eq 'ARRAY') {
	    foreach (0 .. scalar(@$struct)) {
		$struct->[$_] = __set_db_data($struct->[$_], $data_copy->[$_], %opt)
		    if ref $struct->[$_];
	    }
	}
	elsif ($type eq 'HASH') {
	    foreach (sort keys %$struct) {
		$struct->{$_} = __set_db_data($struct->{$_}, $data_copy->{$_}, %opt)
		    if ref $struct->{$_};
	    }
	}
	else {
	    warn "don't know how to set db data for sub-type $type";
	}

	if (Scalar::Util::blessed $struct) {
	    if ($connection && $struct->can('connection')) {

		if (!$opt{copy}
		    && $struct->can('url')
		    && (my $obj_url = $struct->url($connection))
		    ) {

		    my $cache_access;

		    if (my $cached = $Stored_Objects{ $obj_url }) {
			$cache_access = 'reuse';
			#
			# Overwrite the cached object, then reuse it.
			#
			die "attempted overwrite of object with unsaved changes ($obj_url)"
			    if !$opt{overwrite} && $cached->is_changed;

			die "cache type conflict. $obj_url contains an ".ref($cached)." object, but requested ".ref($struct)
			    unless $cached->isa(ref($struct));


			%{$cached} = %{$struct};
			$struct = $cached;
		    }
		    else {
			$cache_access = 'init';
		    }

		    # rewrite, for benefit of 5.13.3
		    weaken ($Stored_Objects{$obj_url} = $struct);

		    if ($struct->debug >= 5) {
			warn YAML::Syck::Dump({opt => \%opt, struct => $struct, class => ref($struct), url => $obj_url, cache => $cache_access, ref1 => "$struct", ref2 => "$Stored_Objects{$obj_url}"});
		    }
		}

		$struct->connection( $connection );
	    }

	    if ($struct->can('_db_data')) {
		#
		# save before image from database
		#
		$data_copy->_db_data(undef)
		    if Scalar::Util::blessed($data_copy)
		    && $data_copy->can('_db_data');

		$struct->_db_data($data_copy);
	    }
	}
    }

    return $struct;
}

#
# _freeze - construct name/value pairs for database inserts or updates
#

sub _freeze {
    my $class = shift;
    my $db_data = shift;
    my %opt = @_;

    $db_data ||= $class if ref($class);
    $db_data ||= {};
    $db_data = Elive::Util::_clone( $db_data );

    my $property_types = $class->property_types || {};
    my %param_types = $class->params;

    $class->_canonicalize_properties( $db_data );

    foreach (keys %$db_data) {

	my $property = $property_types->{$_} || $param_types{$_};

	unless ($property) {
	    my @properties = $class->properties;
	    my @param_names = sort keys %param_types;
	    Carp::croak "$class: unknown property/parameter: $_: expected: ",join(',', @properties, @param_names);
	}

	my $type_info = Elive::Util::inspect_type($property);
	my $type = $type_info->elemental_type;
	my $is_array = $type_info->is_array;

	for ($db_data->{$_}) {

	    $_ = Elive::Util::_freeze($_, $is_array ? $property : $type);

	}
    }

    #
    # apply any freeze alias mappings
    #
    $class->__apply_freeze_aliases( $db_data )
	unless $opt{canonical};

    return $db_data;
}

sub _canonicalize_properties {
    my $class = shift;
    my $data = shift;

    my %aliases = $class->_to_aliases;

    for (grep {exists $data->{$_}} (keys %aliases)) {
	my $att = $aliases{$_};
	$data->{$att} = delete $data->{$_};
    }

    return $data;
}

sub __apply_freeze_aliases {
    my $class = shift;
    my $db_data = shift;

    my $aliases = $class->_get_aliases;

    foreach my $alias (keys %$aliases) {
	if ($aliases->{$alias}{freeze}) {
	    my $to = $aliases->{$alias}{to}
	    or die "malformed alias: $alias";
	    #
	    # Freeze with this alias
	    #
	    $db_data->{ $alias } = delete $db_data->{ $to }
	    if exists $db_data->{ $to };
	}
    }

    return $db_data;
}

# _find_entities()
#
#    my %entities = Elive::DAO::find_entities( $db_data );
#
# A utility function to locate entities in SOAP response data. This should be
# applied after unpacking and before thawing.

sub _find_entities {
    my $db_data = shift;

    return map {m{^(.*)(Adapter|Response)$}? ($1 => $_): ()} (keys %$db_data);
}

sub __dereference_adapter {
    my $class = shift;
    my $db_data = shift;
    my $path = shift;

    my $adapter_found;
    my $entity_data;

    if (Elive::Util::_reftype($db_data) eq 'HASH') {

	my %entities = _find_entities( $db_data );

	my $adapter = delete $entities{ $class->entity_name };

	if ($adapter) {
	    $entity_data = $db_data->{$adapter};
	    $$path .= $adapter;
	}

	my @unknown_entities = sort keys %entities;
	die "unexpected entities in response:: @unknown_entities"
	    if @unknown_entities;
    }

    return $entity_data || $db_data;
}

#
# _thaw - perform database to perl type conversions
#

sub _thaw {
    my $class = shift;
    my $db_data = shift;
    my $path = shift || '';

    $path .= '/';

    my $entity_data = __dereference_adapter( $class, $db_data, \$path);
    return unless defined $entity_data;

    my $ref_type = Elive::Util::_reftype($entity_data);
    die "thawing $class. expected $path to contain HASH data. found: $ref_type"
	unless $ref_type eq 'HASH';

    my %data;
    my @properties = $class->properties;
    my $aliases = $class->_get_aliases;

    #
    # Normalise:
    # 1. Entity names returned capitalised: 'LoginName' => 'loginName
    # 2. Primary key may be returned as Id, rather than <entity_name>Id
    # 3. Apply aliases.
    #
    my %prop_key_map = map {ucfirst($_) => $_} @properties;

    my @primary_key = $class->primary_key;

    $prop_key_map{Id} = lcfirst($primary_key[0])
	if @primary_key;

    foreach my $alias (keys %$aliases) {
	my $to = $aliases->{$alias}{to}
	or die "malformed alias: $alias";

	$prop_key_map{ ucfirst($alias) } = $to;
    }

    my $property_types = $class->property_types;

    foreach my $key (keys %$entity_data) {

	my $val = $entity_data->{ $key };
	my $prop_key = $prop_key_map{$key} || $key;
	$data{$prop_key} = $val;
    }

    foreach my $col (grep {defined $data{$_}} @properties) {

	my $property_type = $property_types->{$col};
	my $type_info = Elive::Util::inspect_type($property_type);
	my $type = $type_info->elemental_type;
	my $is_array = $type_info->is_array;
	my $is_struct = $type_info->is_struct;

	next unless $col && defined $data{$col};

	for my $val ($data{$col}) {

	    my $i = 0;

	    if ($is_array) {

		my $val_type = Elive::Util::_reftype($val) || 'Scalar';

		unless ($val_type eq 'ARRAY') {
		    #
		    # A single value deserialises to a simple
		    # struct. Coerce it to a one element array
		    #
		    $val = [$val];
		    warn "thawing $val_type coerced element into array for $col"
			if ($class->debug);
		}
	    }

	    foreach ($is_array? @$val: $val) {

		next unless defined;

		my $idx = $is_array? '['.$i.']': '';

		if ($is_struct) {

		    $_ = $type->_thaw($_, $path . $idx);

		}
		else {
		    $_ = Elive::Util::_thaw($_, $type);
		}
	    }

	    if ($is_array) {
		@$val = grep {defined $_} @$val;
	    }

	    #
	    # don't store null values, just omit the property.
	    # saves a heap of work in Moose/Mouse constraints
	    #
	    if (defined $val) {
		$data{$col} = $val;
	    }
	    else {
		delete $data{$col};
	    }
	} 
    }

    if ($class->debug) {
	warn "thawed: $class: ".YAML::Syck::Dump(
	    {db => $entity_data,
	     thawed => \%data}
	    );
    }
    
    return \%data;
}

sub _process_results {
    my ($class, $soap_results) = @_;

    #
    # Thaw our returned SOAP responses to reconstruct the data
    # image.
    #

    my @rows;

    foreach (@$soap_results) {

	my $row = $class->_thaw($_);

	push(@rows, $row);
    }

    return \@rows;
}

sub _readback_check {
    my ($class, $updates_raw, $rows, %opt) = @_;

    my $updates = $class->_freeze( $updates_raw, canonical => 1);

    warn YAML::Syck::Dump({class => $class, updates_raw => $updates_raw, updates => $updates})
	if ($class->debug >= 5);

    foreach my $row_raw (@$rows) {

	my $row = $class->_freeze( $row_raw, canonical => 1);

	warn YAML::Syck::Dump({row_raw => $row_raw, row => $row})
	    if ($class->debug >= 5);

	foreach ($class->properties) {
	    if (exists $updates->{$_} && exists $row->{$_}) {
		my $write_val = $updates->{$_};
		my $read_val = $row->{$_};

		if ($write_val ne $read_val) {

		    my $property_type = $class->property_types->{$_};

                    my $sent = Elive::Util::string($write_val, $property_type);
                    my $read = Elive::Util::string($read_val, $property_type);

                    unless ($sent eq $read) {
                        warn YAML::Syck::Dump({read => $read, sent => $sent, type => "$property_type"})
                            if ($class->debug >= 2);

                        croak "${class}: Update consistancy check failed on $_ (${property_type}), sent:$sent; read-back:$read";
                    }
		}
	    }
	}
    }

    return @$rows;
}

=head2 is_changed

Abstract method. Returns a list of properties that have been changed since the
entity was last retrieved or saved.

=cut

sub is_changed {
    my $self = shift;

    my @updated_properties;
    my $db_data = $self->_db_data;

    unless ($db_data) {
	#
	# not mapped to a stored data value. scratch object?, sub entity?
	#
	Carp::carp( ref($self)."->is_changed called on non-database object (".$self->stringify.")\n" );
	return;
    }

    my @props = $self->properties;
    my $property_types = $self->property_types;

    foreach my $prop (@props) {

	my $new = $self->$prop;
	my $old = $db_data->$prop;
	my $type = $property_types->{$prop};

	die (ref($self)." - attribute $prop contains tainted data")
	    if Elive::Util::_tainted($new) || Elive::Util::_tainted($old);

	if (defined ($new) != defined ($old)
	    || $self->_cmp_col($type, $new, $old)) {

	    push (@updated_properties, $prop);
	}
    }

    #
    # warn if we catch a primary key modification, after the fact
    #
    my %primary_key = map {$_ => 1} ($self->primary_key);
    my @primary_key_updates = grep { exists $primary_key{$_} } @updated_properties;
    foreach my $prop (@primary_key_updates) {

	my $type = $property_types->{$prop};
        my $old_str = Elive::Util::string($db_data->$prop => $type);
	my $new_str = Elive::Util::string($self->$prop => $type);

	Carp::carp( ref($self).": primary key field has been modified $prop: $old_str => $new_str" );
    }

    return @updated_properties;
}

=head2 set

    $obj->set(prop1 => val1, prop2 => val2 [,...])

Abstract method to assign values to entity properties.

=cut

sub set {
    my $self = shift;
    my %data = @_;

    croak "attempt to modify data in a deleted record"
	if ($self->_deleted);

    my %entity_column = map {$_ => 1} ($self->properties);
    my %primary_key = map {$_ => 1} ($self->primary_key);

    $self->_canonicalize_properties( \%data );
 
    foreach (keys %data) {

	unless ($entity_column{$_}) {
	    Carp::carp ((ref($self)||$self).": unknown property: $_");
	    next;
	}

	my $type = $self->property_types->{$_}
	   or die ((ref($self)||$self).": unable to determine property type for field: $_");

	if (exists $primary_key{ $_ }) {

	    my $old_val = $self->{$_};

	    if (defined $old_val && !defined $data{$_}) {
		die "attempt to delete primary key";
               }
	    elsif ($self->_cmp_col($type, $old_val, $data{$_})) {
		die "attempt to update primary key";
	    }
	}

	my $meta = $self->meta;
	my $attribute =  $meta->get_attribute($_);
	my $value = $data{$_};

	if (defined $value) {

	    if (ref($value)) {
		#
		# inspect the item to see if we need to stringify back to
		# a simpler type. For example we may have been passed an
		# object, rather than just its primary key.
		#
		$value = Elive::Util::string($value, $type)
		    unless  Elive::Util::inspect_type($type)->is_ref;
	    }

	    die (ref($self)." - attempt to set attribute $_ to tainted data")
		if Elive::Util::_tainted($value);

	    $self->$_($value);
	}
	else {

	    die ref($self).": attempt to delete required attribute: $_"
		if $attribute->is_required;

	    delete $self->{$_};
	}
    }

    return $self;
}

sub _readback {
    my ($class, $som, $sent_data, $connection, %opt) = @_;
    #
    # Inserts and updates normally return a copy of the entity after
    # an insert or update. Confirm that the output record contains
    # the updates and return it.

    my $results = $class->_get_results($som, $connection);
    #
    # Check that the return response has our inserts/updates
    #
    my $rows = $class->_process_results( $results );
    $class->_readback_check($sent_data, $rows, %opt);

    return @$rows;
}

sub _to_aliases {
    my $class = shift;

    my $aliases = $class->_get_aliases;

    my %aliased_to;

    foreach my $alias (keys %$aliases) {
	my $to = $aliases->{$alias}{to}
	or die "malformed alias: $alias";

	$aliased_to{$alias} = $to;
    }

    return %aliased_to;
}

=head2 insert

    my $new_user = Elive::Entity::User->insert(
             {loginName => 'demo_user',
              email => 'demo.user@test.org'}
             },
             connection => $con,   # connection to use,
             command => $cmd,      # soap command to use
             );

    print "inserted user with id: ".$new_user->userId."\n";

Abstract method to insert new entities. The primary key is generally not
required. It is generated for you and returned with the newly created object.

=cut

sub insert {
    my ($class, $_insert_data, %opt) = @_;

    my $connection = $opt{connection} || $class->connection
	or die "not connected";

    my %insert_data = %$_insert_data;
    my %params = %{delete $opt{param} || {}};

    my $data_params = $class->_freeze({%insert_data, %params});

    my $command = $opt{command} || 'create'.$class->entity_name;

    $connection->check_command($command => 'c');

    my $som = $connection->call($command, %$data_params);

    my @rows = $class->_readback($som, $_insert_data, $connection, %opt);

    my @objs = (map {$class->construct( $_, connection => $connection )}
		@rows);
    #
    # possibly return a list of recurring meetings.
    #
    return wantarray? @objs : $objs[0];
}

=head2 live_entity

    my $user_ref
      = Elive::Entity->live_entity('http://test.org/User/1234567890');

Returns a reference to an object in the Elive::Entity cache. 

=cut

sub live_entity {
    my $class = shift;
    my $url = shift;

    return $Stored_Objects{ $url };
}

=head2 live_entities

    my $live_entities = Elive::Entity->live_entities;

    my $user_ref = $live_entities->{'http://test.org/User/1234567890'};

Returns a reference to the Elive::Entity cache. 

=cut

sub live_entities {
    my $class = shift;
    return \%Stored_Objects;
}

=head2 update

Abstract method to update entities. The following commits outstanding changes
to the object.

    $obj->{foo} = 'Foo';  # change foo attribute directly
    $foo->update;         # save

    $obj->bar('Bar');     # change bar via its accessor
    $obj->update;         # save

Updates may also be passed as parameters:

    # change and save foo and bar. All in one go.
    $obj->update({foo => 'Foo', bar => 'Bar'});

This method can be called from the class level. You will need to
supply the primary key and all mandatory fields. 

=cut

sub update {
    my ($self, $_update_data, %opt) = @_;

    die "attempted to update deleted record"
	if ($self->_deleted);

    my %params = %{ $opt{param} || {} };
    my %primary_key = map {$_ => 1} ($self->primary_key);
    my %updates;

        if (! ref $self) {
	# class level update
	$opt{connection} ||= $self->connection
	    if $self->connection;
	$self = $self->construct( $_update_data, %opt);
	for (keys %$self) {
	    $updates{$_} = $self->$_;
	}
    }
    elsif ($_update_data) {

	croak 'usage: $obj->update( \%data )'
	    unless (Elive::Util::_reftype($_update_data) eq 'HASH');

	my %update_data = %{ $_update_data };
	#
	# sift out things which are included in the data payload, but should
	# be parameters.
	#
	my %param_names = $self->params;
	foreach (grep {exists $update_data{$_}} %param_names) {
	    my $val = delete $update_data{$_};
	    $params{$_} = $val unless exists $params{$_};
	}

	$self->set( %update_data)
	    if (keys %update_data);
    }

    #
    # Write only changed properties.
    #
    my @updated_properties = ($opt{changed}
			      ? @{$opt{changed}} 
			      : $self->is_changed);

    #
    # merge in pending updates to the current entity.
    #

    foreach (@updated_properties, keys %primary_key) {

	my $update_val = $self->$_;

	if (exists $primary_key{$_} ) {
	    my $type = $self->property_types->{$_};
	    my $db_val = $self->_db_data->$_;
	    croak 'primary key field $_ updated - refusing to save'
		if $self->_cmp_col($type, $db_val, $update_val);
	}

	$updates{$_} = $update_val;
    }

    my $command = $opt{command} || 'update'.$self->entity_name;

    $self->connection->check_command($command => 'u');

    my $data_frozen = $self->_freeze({%updates, %params});

    my $som = $self->connection->call($command, %$data_frozen);

    my $class = ref($self);

    my @rows = $class->_readback($som, \%updates, $self->connection, %opt);
    my $data = $rows[0];

    unless ($data && Elive::Util::_reftype($data) eq 'HASH') {

	warn "no data in update response - having to re-fetch (grrrr!)"
	    if $class->debug;

	$data = $class->retrieve( $self->stringify, raw => 1)
	    or die "unable to get update results";

	$class->_readback_check(\%updates, [$data], %opt);
    }

    #
    # refresh the object from the database read-back
    #
    my $obj = $self->construct($data, connection => $self->connection, overwrite => 1, copy => $self->_is_copy);

    unless ($obj->_refaddr eq $self->_refaddr) {
	warn $obj->url." (obj=$obj, self=$self) - not in cache, nor is it a copy."
	    unless $self->_is_copy;
	# clone the result
	%{$self} = %{ Elive::Util::_clone($obj) };
	$self->__set_db_data( Elive::Util::_clone($obj->_db_data), connection => $self->connection, copy => 1);
    }

    return $self;
}

=head2 list

    my $users = Elive::Entity::User->list(
		    filter => 'surname = smith',  # filter results (server side)
		    command => $cmd,              # soap command to use
		    connection => $connection,    # connection to use
		    raw => 1,                     # return unblessed data
                );

Abstract method to list entity objects.

=cut

sub list {
    my ($class, %opt) = @_;

    my @params = $opt{params}
        ? %{ $class->_freeze( delete $opt{params} ) }
	: ();

    if (my $filter = delete $opt{filter} ) {
	push( @params, filter => Elive::Util::_freeze($filter => 'Str') );
    }

    my $connection = $opt{connection} || $class->connection
	or die "no connection active";

    my $collection_name = $class->collection_name || $class->entity_name;

    die "misconfigured class $class - has neither a collection_name or entity_name"
	unless $collection_name;

    my $command = $opt{command} || 'list'.$collection_name;
    $connection->check_command($command => 'r');

    my $som = $connection->call($command, @params);

    my $results = $class->_get_results($som,$connection);

    my $rows = $class->_process_results( $results );

    return [
	map { $class->construct( $_, connection => $connection) }
	@$rows
	];
}

sub _fetch {
    my ($class, $db_query, %opt) = @_;

    $db_query ||= {};

    croak "usage: ${class}->_fetch( \\%query )"
	unless (Elive::Util::_reftype($db_query) eq 'HASH');

    my $connection = $opt{connection} || $class->connection
	or die "no connection active";

    my $command = $opt{command} || 'get'.$class->entity_name;

    warn "get: entity name for $class: ".$class->entity_name.", command: ".$command
	if $class->debug;

    $connection->check_command($command => 'r');

    my $db_query_frozen = $class->_freeze( $db_query );

    my $som = $connection->call($command, %{$db_query_frozen});

    my $results = $class->_get_results($som, $connection);

    my $rows = $class->_process_results( $results );
    return $rows if $opt{raw};
    #
    # 0 results => not found. Would be treated by readback as an error,
    # but perfectly valid here. Just means we didn't find a matching entity.
    #
    return []
	unless @$rows;

    $class->_readback_check($db_query, $rows, %opt);
    return [map {$class->construct( $_, connection => $connection )} @$rows];
}

=head2 retrieve

    my $user = Elive::Entity::User->retrieve(
                        $user_id,
                        reuse => 1,  # use cached data if present.
                        );
    

Abstract method to retrieve a single entity object by primary key.

=cut

sub retrieve {
    my ($class, $vals, %opt) = @_;

    $vals = [$vals]
	if $vals && Elive::Util::_reftype($vals) ne 'ARRAY';

    my @key_cols = $class->primary_key;

    for (my $n = 0; $n < @key_cols; $n++) {

	die "incomplete primary key value for: $key_cols[$n]"
	    unless defined ($vals->[$n]);
    }

    my $connection = $opt{connection} || $class->connection
	or die "not connected";

    if ($opt{reuse}) {
	#
	# Have we already got the object cached? If so return it
	#
	my %pkey;
	@pkey{$class->primary_key} = @$vals;

	my $obj_url = $class->_restful_url(
	    $connection,
	    $class->stringify(\%pkey)
	    );

	if ( my $cached = $class->live_entity($obj_url) ) {
	    die "cache type conflict. $obj_url contains an ".ref($cached)." object, but requested $class"
		unless $cached->isa($class);

	    warn "retrieve from cache $obj_url (".ref($cached).")"
		if $class->debug;

	    return $cached 
	}
    }
    #
    # need to fetch it
    #
    my $all = $class->_retrieve_all($vals, %opt);

    #
    # We've supplied a full primary key, so can expect 0 or 1 values
    # to be returned.
    #
    warn "${class}->retrieve([@$vals]) returned extraneous data - discarding\n"
	if (scalar @$all > 1);

    return $all->[0];
}

# _retrieve_all() - Retrieve entity objects by partial primary key.
#
#    my $participants
#          = Elive::Entity::ParticipantList->_retrieve_all($meeting_id)
#

sub _retrieve_all {
    my ($class, $vals, %opt) = @_;

    croak 'usage $class->_retrieve_all([$val,..],%opt)'
	unless Elive::Util::_reftype($vals) eq 'ARRAY';

    my @key_cols = $class->primary_key;
    my @vals = @$vals;

    my %fetch;

    while (@vals && @key_cols) {
	my $key = shift(@key_cols);
	my $val = shift(@vals);

	$fetch{$key} = $val
	    if (defined $val);
    }

    die "nothing to retrieve"
	unless (keys %fetch);

    return $class->_fetch(\%fetch, %opt);
}

=head2 delete

    $user_obj->delete;

    Elive::Entity::Session->delete(sessionId = 123456);

Abstract method to delete an entity.

=cut

sub delete {
    my ($self, %opt) = @_;

    my @primary_key = $self->primary_key;
    my @id;

    die "entity lacks a primary key - can't delete"
	unless (@primary_key > 0);

    if (ref($self)) {
	@id = $self->id;
    }
    elsif ($opt{ $primary_key[0] }) {
	# class level delete - primary key supplied in options
	@id = map { $opt{$_} } @primary_key;
    }
    else {
	die "can't determine primary key without object or @primary_key"
    }

    my @params = map {
	$_ => shift( @id );
    } @primary_key;

    my $command = $opt{command} || 'delete'.$self->entity_name;
    $self->connection->check_command($command => 'd');

    my $som = $self->connection->call($command, @params);

    my $results = $self->_get_results($som, $self->connection);
    my $rows = $self->_process_results($results);

    #
    # Umm, we did get a read-back of the record, but the contents
    # seem to be dubious. Perform cardinality checks, but don't do
    # write-back checks.
    #

    croak "Didn't receive a response for deletion: ".$self->entity_name
	unless @$rows;

    croak "Received multiple responses for deletion: ".$self->entity_name
	if (@$rows > 1);

    return $self->_deleted(1);
}

=head2 revert

    $user->revert                        # revert entire entity
    $user->revert(qw/loginName email/);  # revert selected properties

Abstract method to revert an entity to its last constructed value.

=cut

our $REVERTING;

sub revert {
    my ($self, @props) = @_;

    local( $REVERTING ) = 1;

    my $db_data = $self->_db_data
	or die "object doesn't have db-data!? - can't cope";

    @props = $self->is_changed
	unless @props;

    for (@props) {

	if (exists $db_data->{$_}) {
	    $self->{$_} = $db_data->{$_};
	}
	else {
	    delete $self->{$_};
	}
    }

    return $self;
}

sub _not_available {
    my $self = shift;

    croak "this operation is not available for ". $self->entity_name;
}

#
# Shared subtypes
#
BEGIN {

    subtype 'HiResDate'
	=> as 'Int'
	=> where {m{^-?\d+$}
               && (m{^0+$} || (length($_) > 10 && !m{-})
		   or Carp::carp "doesn't look like a hi-res date: $_")}
        => message {"invalid date: $_"};
}

sub can {
    my ($class, $method) = @_;

    my $subref = try { $class->SUPER::can($method) };

    unless ($subref) {

	my $aliases = try { $class->_aliases };

	if ($aliases && $aliases->{$method}
	    && (my $alias_to = $aliases->{$method}{to})) {
	    $subref =  $class->SUPER::can($alias_to);
	}
    }

    return $subref;
}

sub AUTOLOAD {
    my @class_path = split('::', ${Elive::DAO::AUTOLOAD});

    my $method = pop(@class_path);
    my $class = join('::', @class_path);

    die "Autoload Dispatch Error: ".${Elive::DAO::AUTOLOAD}
        unless $class && $method;

    if (my $subref = $class->can($method)) {
	no strict 'refs';
	*{$class.'::'.$method} = $subref;

	goto $subref;
    }
    else {
	Carp::croak $class.": unknown method $method";
    }
}

sub DEMOLISH {
    my ($self) = shift;
    my $class = ref($self);

    warn 'DEMOLISH '.$self->url.': db_data='.($self->_db_data||'(null)')."\n"
	if ($self->debug||0) >= 5;

    if (my $db_data = $self->_db_data) {
	if (!$REVERTING
	    && (my @changed = $self->is_changed)
	    && ! $self->_deleted) {
	    my $self_string = Elive::Util::string($self);
	    Carp::carp("$class $self_string destroyed without saving or reverting changes to: "
		 . join(', ', @changed));

	    warn YAML::Syck::Dump {self => $self, db_data => $db_data}
	    if ($self->debug||0) >= 6;
	}
	#
	# Destroy this objects data
	#
	$self->_db_data(undef);
    }
}

=head1 ADVANCED

=head2 Object Management

L<Elive::DAO> keeps a reference table to all current database objects. This
is primarily used to detect errors, such as destroying or overwriting objects
with unsaved changes.

You can also reuse objects from this cache by passing C<reuse =E<gt> 1> to the
C<fetch> method. 

    my $user = Elive::Entity::User->retrieve(11223344);
    #
    # returns the same reference, but refetches from the database
    #
    my $user_copy = Elive::Entity::User->retrieve(11223344);
    #
    # same as above, however don't refetch if we already have a copy
    #
    my $user_copy2 = Elive::Entity::User->retrieve(11223344, reuse => 1);

You can access the in-memory cache using the C<live_entity> and C<live_entities>
methods.

=head2 Entity Manipulation

All objects are simply blessed structures that contain data and nothing else.
You may choose to use the accessors, or work directly with the object data.

The following are all equivalent, and are all ok:

    my $p_list = Elive::Entity::ParticipantList->retrieve(98765);
    my $user = Elive::Entity::User->retrieve(11223344);

    $p_list->participants->add($user);
    push (@{ $p_list->participants        }, $user);
    push (@{ $p_list->{participants}      }, $user);
    push (@{ $p_list->get('participants') }, $user);

=cut

=head1 SEE ALSO

=over 4

=item L<Mouse> (base class) - Middle-weight L<Moose> like class system

=back

=cut

1;
