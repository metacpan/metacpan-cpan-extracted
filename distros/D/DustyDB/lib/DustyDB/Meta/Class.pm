package DustyDB::Meta::Class;
our $VERSION = '0.06';

use Moose::Role;

use Scalar::Util qw( blessed reftype );

use DustyDB::FakeRecord;

=head1 NAME

DustyDB::Meta::Class - meta-class role for DustyDB::Record objects

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This provides a number of meta-class methods to the meta-class of DustyDB model objects, i.e., a class that uses L<DustyDB::Object> and does L<DustyDB::Record>. These methods provide lower level access to the database and should be used with caution. This part of the API is more likely to change as well.

=head1 ATTRIBUTES

=head2 primary_key

This is currently implemented as an attribute. This might change in the future. This assumes that the primary key will not change at runtime (which is probably a pretty good assumption).

=cut

has primary_key => (
    is       => 'rw',
    isa      => 'ArrayRef',
    lazy     => 1,
    required => 1,
    default  => sub {
        my $self  = shift;
        my @attr = values %{ $self->get_attribute_map };
        return [ grep { $_->does('DustyDB::Key') } @attr ];
    },
);

=head1 METHODS

=head2 load_object

  my $record = $meta->load_object( db => $db, key => [ %$key ] );

Load a record object from the given L<DustyDB> with the given key parameters.

=cut

sub load_object {
    my $meta   = shift;
    my %params = @_;
    my $db     = $params{db};
    my $key    = $params{key};

    $db->init_table($meta->name);
    my $keys = $meta->_build_key(@$key);
    my $que  = $meta->_build_que($keys);
    
    # Fetch the record from the database
    my $object = $db->table( $meta->name );
    for my $que_entry (@$que) {
        return unless ref $object and reftype $object eq 'HASH';

        if (defined $object->{$que_entry}) {
            $object = $object->{$que_entry};
        }

        else {
            return;
        }
    }

    # Bake the model
    return $meta->_build_object( db => $db, record => $object->export );
}

sub _build_object {
    my ($meta, %params) = @_;
    my $db     = $params{db};
    my $record = $params{record};

    for my $attr (values %{ $meta->get_attribute_map }) {

        # Load the value
        my $value;
        $value = $record->{ $attr->name } 
            if defined $record->{ $attr->name };

        # If this is another record, load it first
        if (ref $value and reftype $value eq 'HASH'
                and defined $value->{'class_name'}) {

            my $class_name = $value->{'class_name'};
            my $other_model = $db->model( $class_name );
            my $fake = DustyDB::FakeRecord->new(
                model      => $other_model,
                class_name => $class_name,
                key        => $value,
            );
            $record->{ $attr->name } = $fake;
        }

        # Otherwise try to decode if needed
        elsif (defined $value) {
            $record->{ $attr->name } = $attr->perform_decode( $value );
        }
    }

    # ... and serve
    return $meta->new_object( %$record, db => $db );
}

sub _build_key {
    my $meta = shift;
    my %keys;

    # We have a record that needs to be decomposed
    if (blessed $_[0] and $_[0]->isa($meta->name)) {
        for my $key (@{ $meta->primary_key }) {
            $keys{ $key->name } 
                = $key->perform_stringify($key->get_value($_[0]));
        }
    }

    # A single argument and a single column key
    elsif (@_ == 1 and @{ $meta->primary_key } == 1) {
        my $key = $meta->primary_key->[0];
        $keys{ $key->name } = $key->perform_stringify($_[0]);
    }
    
    # A multi-column key must be given with a hashref
    else {
        my %params = @_;
        for my $key (@{ $meta->primary_key }) {
            $keys{ $key->name } 
                = $key->perform_stringify($params{ $key->name });
        }
    }

    return \%keys;
}

sub _build_que {
    my $meta = shift;
    my $keys = shift;

    # Setup the lookup que
    my @que;
    for my $key (@{ $meta->primary_key }) {
        confess qq(cannot store when column "@{[ $key->name ]}" is undefined.\n)
            if not defined $keys->{ $key->name };
        push @que, $keys->{ $key->name };
    }

    return \@que;
}

=head2 save_object

  my $key = $meta->save_object( db => $db, record => $record );

This saves the given record (an object that does L<DustyDB::Record>) to the given L<DustyDB> database. This method returns a hash referece representing a key that can be used to retrieve the object later via:

  my $record = $meta->load_object( db => $db, key => [ %$key ] );

=cut

sub save_object {
    my $meta   = shift;
    my %params = @_;
    my $db     = $params{db};
    my $record = $params{record};

    # Bootstrap if we need to and setup the que
    $db->init_table($meta->name);
    my $keys = $meta->_build_key($record);
    my $que  = $meta->_build_que($keys);

    # Separate the last que for final work
    my $last_que = pop @$que;
    my $que_remaining = scalar @$que;

    # Locate the hash containing the last que
    my $object = $db->table( $meta->name );
    for my $que_entry (@$que) {
        if (defined $object->{$que_entry}) {

            if ($que_remaining == 0 
                    or (ref $object->{$que_entry} 
                        and reftype $object->{$que_entry} eq 'HASH')) {
                $object = $object->{$que_entry};
            }
            
            # overwrite previous non-hash fact with something more agreeable
            else {
                $object = $object->{$que_entry} = {}
            }
        }

        else {
            $object = $object->{$que_entry} = {};
        }

        $que_remaining--;
    }

    # Build a hash representing the data in the object
    my $hash = {};
    for my $attr (values %{ $meta->get_attribute_map }) {
        # TODO use a non-saved marker role instead of this crass hack
        next if $attr->name eq 'db';

        # Load the value itself
        my $value = $attr->perform_encode( $attr->get_value($record) );

        # Skip on undef since this can cause things to go amuck at load
        next unless defined $value;

        # If this is another record, just store the key
        if (blessed $value and $value->can('does') and $value->does('DustyDB::Record')) {
            $hash->{ $attr->name } = $value->meta->_build_key($value);
            $hash->{ $attr->name }{class_name} = $value->meta->name;
        }

        # Otherwise, store the thingy
        else {
            $hash->{ $attr->name } = $value;
        }
    }

    # Save to the last que location
    $object->{$last_que} = $hash;
    
    return $keys;
}

=head2 delete_object

  $meta->delete_object( db => $db, record => $record );

Delete the record instance from the database.

=cut

sub delete_object {
    my $meta   = shift;
    my %params = @_;
    my $db     = $params{db};
    my $record = $params{record};

    # Bootstrap and setup the que
    $db->init_table($meta->name);
    my $keys = $meta->_build_key($record);
    my $que  = $meta->_build_que($keys);
    
    # This is the final bit to delete
    my $last_que = pop @$que;

    # Find the place to delete from
    my $object = $db->table( $meta->name );
    for my $que_entry (@$que) {
        if (defined $object->{$que_entry}) {
            $object = $object->{$que_entry};
        }
        else {
            return; # didn't find it, skip it
        }
    }

    # Delete the record
    delete $object->{$last_que};

    # TODO This may leave a partial key dangling empty, some more clean-up
    # here might be a good idea.
}

=head2 list_all_objects

  my @records = $meta->list_all_objects( db => $db );

Fetches all the records for this object from the given L<DustyDB>.

=cut

sub list_all_objects {
    my ($meta, %params) = @_;
    my $db = $params{db};

    # Initialize the table in case it ain't
    $db->init_table( $meta->name );

    # Just return now if the table is empty
    my $table = $db->table( $meta->name );
    return () unless scalar %$table;

    # Setup the initial structure before delving deeper
    my @records = values %$table;
    my @primary_key = @{ $meta->primary_key };
    pop @primary_key;

    # For multi-attribute keys, delve deeper until we run out of keys
    for my $attr (@primary_key) {
        @records = map { defined $_ ? values %$_ : () } @records;
    }

    # Convert keys to records
    my @objects = map  { $meta->_build_object( db => $db, record => $_->export ) } 
                  grep { defined $_ } @records;

    return @objects;
}

1;