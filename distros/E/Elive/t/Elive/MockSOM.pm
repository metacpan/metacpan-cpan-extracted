package t::Elive::MockSOM;
use warnings; use strict;

use parent qw{Class::Accessor};

__PACKAGE__->mk_accessors( qw{fault result paramsout} );

sub _pack_data {
    #
    # _freeze - construct name/value pairs for database inserts or updates
    #
    my $class = shift;
    my $data = shift;

    #
    # Assume a simple scalar is a primary key
    #
    my $adapter = ucfirst($class->entity_name.'Adapter');
    my $pkey = $class->_primary_key;

    if (!ref($data) && @$pkey) {
	return $adapter => {$pkey->[0] => $data};
    }

    die "can't handle packing of arrays for class $class"
	if ref($data) eq 'ARRAY';

    my %db_data = %$data;
    #
    # resolve any aliased properties
    #
    my $aliases = $class->_get_aliases;

    foreach my $alias (keys %$aliases) {
	if ($aliases->{$alias}{freeze}) {
	    my $to = $aliases->{$alias}{to}
	    or die "malformed alias: $alias";
	    $db_data{ $to } = delete $db_data{ $alias }
	    if exists $db_data{ $alias };
	}
    }

    my @properties = $class->properties;
    my $property_types =  $class->property_types || {};

    foreach my $prop (keys %db_data) {

	die "$class: unknown property $prop: expected: @properties"
	    unless exists $property_types->{$prop};

	my $property = $property_types->{$prop};

	my $type_info = Elive::Util::inspect_type( $property );
	my $type = $type_info->type;

	for ($db_data{$prop}) {
	    die "$class undefined property $prop"
		unless defined;

	    $_ = [split($type->separator, $_)]
		if ($type_info->is_array && !ref);

	    if ($type_info->is_struct && $type_info->elemental_type ne 'Elive::Entity::Group') {
		my ($adapter, $packed_data) = _pack_data($type_info->elemental_type, $_);
		$_ = {$adapter => $packed_data};
	    }
	}
    }

    my %data_out;

    foreach (keys %db_data) {
	$data_out{ucfirst($_)} = $db_data{$_};
    }

    return $adapter => \%data_out;
}

sub make_result {
    my $class = shift;
    my $entity_class = shift;
    my @data = @_;

    if ($entity_class->isa('Elive::Entity::User')) {
	foreach (@data) {
	    #
	    # return of passwords is supressed
	    #
	    $_->{loginPassword} = ''
		if defined $_->{loginPassword};
	}
    }

    my ($adapter, $packed_data) = _pack_data($entity_class, @data > 1? \@data: $data[0]);

    my $self = bless {}, $class;

    $self->result({$adapter => $packed_data});

    $self;
}

sub not_found {
    my $class = shift;

    my $self = bless {}, $class;
    $self->result('');

    $self;
}

########################################################################
package t::Elive::MockSOMFault;
use warnings; use strict;

use parent qw{Class::Accessor};

__PACKAGE__->mk_accessors( qw{faultstring result paramsout} );

1;
