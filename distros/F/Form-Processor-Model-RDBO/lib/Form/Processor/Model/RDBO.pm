package Form::Processor::Model::RDBO;
use strict;
use warnings;
use base 'Form::Processor';
require UNIVERSAL::require;

our $VERSION = '0.02';

=head1 NAME

Form::Processor::Model::RDBO - Model class for Form Processor using
Rose::DB::Object

=head1 SYNOPSIS

Same API as in L<Form::Processor::Model::DBIC>. For more documentation and
examples see it. Here are written only L<Rose::DB::Object> special cases.

=head1 METHODS

=head2 manager_module

Defines the default name for Rose::DB::Object managers. You are free to override
this property if the name of your Manager module differs.

=cut

sub manager_module { 'Manager' }

=head2 init_item

This is called on the first call of $form->item. It also validates that the item
id matches /^\d+$/. Override this method in your form class (or form base class)
if your ids do not match that pattern.

=cut

sub init_item { 
    my $self = shift;
    my $item_id = $self->item_id;

    return unless defined $item_id;
    return unless $item_id =~ /^\d+$/;

    my $object = $self->object_class;

    return unless $object;
    return unless $object->isa('Rose::DB::Object');
    
    my ( $primary_key )  = ( $object->meta->primary_key_columns );
    return unless $primary_key;

    my $item = $object->new( $primary_key => $item_id );
    $item->load;

    $self->reset_params;

    return $item;
}

=head2 init_value

Populate $field->value with object ids from the Rose::DB::Object object. If the
column expands to more than one object then an array ref is set.

=cut

sub init_value {
    my ( $self, $field, $item ) = @_;

    my $column = $field->name;

    $item ||= $self->item;

    return $item->{$column} if ref($item) eq 'HASH';

    # Use "can" instead of "find_column" because could be a related column
    return unless $item && $item->isa('Rose::DB::Object') && $item->can( $column );

    # @options can be a collection of RDBO objects (has_many) or a 
    # RDBO objects get turned into IDs.  Should also check that it's not a compound
    # primary key.

    my @values =
      map { ref $_ && $_->isa( 'Rose::DB::Object' ) ? $_->id : $_ }
      $item->$column;

    return @values;

}

=head2 guess_field_type

Tries to guess field type of the passed column.  Currently only looks at RDBO
relationships. And returns the type 'Select' for 'one to one' or 'many to one'
relations and 'Text' in other cases.

=cut

sub guess_field_type
{
    my ( $self, $column ) = @_;
    my $object_meta = $self->object_class->meta;
    my $foreign_item ;
    my $r_type;

    if ( $foreign_item = $object_meta->foreign_key( $column ) ) {
        $r_type = $foreign_item->relationship_type;
    }
    elsif ( $foreign_item = $object_meta->relationship( $column ) ) {
        $r_type = $foreign_item->type;
    }
    else {
        $r_type = '';
    }

    my $guessed_field_type;
    if ( $r_type eq 'one to one' || $r_type eq 'many to one' ) {
        $guessed_field_type = 'Select';
    }
    else { $guessed_field_type = 'Text'; }

    return $guessed_field_type;
}

=head2 lookup_options

Tries to get options for the filed, derived from
L<Form::Processor::Field::Select> (e.g. Select and Multiple) from the database.
First, it asks foreign RDBO class if it can 'active_column'. Active columns is
used for labeling select fields.

    package Schema::RDBO::Current;
    use strict;
    use base qw(DB::Object);
    __PACKAGE__->meta->setup(
      foreign_keys =>
      [
        foreign_fk => {
          class => 'RDBO::ForeignTable'
        }
      ]
    );
    1;

    package Schema::RDBO::ForeignTable;
    use strict;
    use base qw(DB::Object);
    __PACKAGE__->meta->setup(
      columns => [
        qw/ id title  /
      ],
    );

    sub active_column { 'title' }

    1;

Value returned by active_column method is used in building sql. If not defined
it will be set to the default 'name'. If you want to have freedom how to set up
label and active_column is not enough, you can declare active_column_method
method that is called when labeling value as a method of retreived object.

    sub active_column_method {
      ucfirst $_[0]->title;
    }

If no active_column method was found it gets default 'name' value. If active
column exists in the foreign RDBO schema class, reference to array of key/value
pairs will be returned and the options for field will be filled automatically.
Otherwise it will return the empty array.

=cut

sub lookup_options { 
    my ( $self, $field ) = @_;
    my $object_class = $self->object_class;
    my $prefix = $self->name_prefix;

    my $field_name  = $field->name;
    $field_name =~ s/^$prefix\.//g if $prefix;

    my $field_type  = $field->type;
    # NOTE: "Multiple" is derived class from "Select".
    #       This code will work for all classes derived from "Select".
    return unless $field->isa( "Form::Processor::Field::Select" );
    return unless $object_class->isa('Rose::DB::Object');

    my $object_meta  = $object_class->meta;
    my $foreign_item;
    my $foreign_class;
    my $foreign_manager;

    $foreign_item = $object_meta->foreign_key($field_name);
    if ( !$foreign_item ) {
        $foreign_item = $object_meta->relationship($field_name);
    }
    return unless $foreign_item;

    if (
        $foreign_item->isa(
            'Rose::DB::Object::Metadata::Relationship::ManyToMany'
        )
      )
    {
        $foreign_class   = $foreign_item->foreign_class;
    } else {
        $foreign_class   = $foreign_item->class;
    }

    $foreign_manager = $foreign_class . '::' . $self->manager_module;

    # Trying to require Manager class
    $foreign_manager->require;
    if ( $@ ) {
        $foreign_manager = 'Rose::DB::Object::Manager';
        $foreign_manager->require or die "Unable to require $foreign_manager";
    }

    # Trying to determinate the active column the default value for
    # active_column is "name"
    my $active_column;
    if ( $foreign_class->can('active_column') ) {
        $active_column = $foreign_class->active_column;
    } elsif ( $self->can('active_column') ) {
        $active_column = $self->active_column;
    }

    # Check that active_column exists in foreign class columns list
    # If the active column does not exist in foreign class columns list
    # set it to '' (boolean false)
    #my @foreign_columns  = $foreign_class->meta->column_names;
    #$active_column = '' unless grep { $_ eq $active_column } @foreign_columns;
    # FIXME: can't simply check if column exists because relative column can be
    # specified: 't2.title'

    $active_column = "name" unless $active_column;

    my ( $primary_key )  = ( $foreign_class->meta->primary_key_column_names );

    my @options;
    # Fetch options only if active_column exists

    if ( $active_column ) {
        my %m_params = (
            'object_class' => $foreign_class,
            'select'       => [ $primary_key, $active_column ],
        );
        my $records = $foreign_manager->get_objects( %m_params);

        foreach my $r ( @$records ) {
            push @options,
              (
                  $r->$primary_key => $r->can( 'active_column_method' )
                ? $r->active_column_method()
                : $r->$active_column
              );
        }
    } else {
        warn 'active_column is undefined';
        @options = ();
    }
    
    return \@options;
}

=head2 update_from_form

Makes form validation and returns the filled RDBO item, filled by update_model.
It does not save the current item automatically. You should do this in your
code, after the call update_from_form.

=cut

sub update_from_form {
    my ( $self, $params ) = @_;
    return unless $self->validate( $params );
    return $self->update_model( $params );
}

=head2 update_model

Returns the new RDBO item, filled with passed form params. It does not save any
data to the database, just creates and fills new RDBO object.

=cut

sub update_model {
    my ( $self, $params ) = @_;

    my $item = $self->item;
    my $class = ref( $item ) || $self->object_class;

    my %fields = map { $_->name, $_ } grep { !$_->noupdate } $self->fields;

    $item = $class->new() unless $item;
    while ( my ( $name, $field ) = each %fields ) {
        if ( $item->can( $name ) ) {
            if (   !$field->isa( 'Form::Processor::Field::Select' )
                && defined $item->$name
                && defined $field->value )
            {
                next if $item->$name eq $field->value;
            }

            $item->$name( $field->value );
        }
    }

    return $item;
}

=head2 model_validate

Does simple validation of fields, that you specified as unique in your form
profile. You are free to override this method if you want to implement much
serious model validation.

=cut

sub model_validate
{
    my ($self) = @_;
    return unless $self->validate_unique;
    return 1;
}

=head2 validate_unique

Internal method. Does simple validation of fields, that you specified as unique
in your form profile.

=cut

sub validate_unique {
    my ( $self ) = @_;

    my $unique = $self->profile->{ unique } || return 1;

    my $item = $self->item;

    my $class = ref( $item ) || $self->object_class;

    my $found_error = 0;

    for my $field ( map { $self->field( $_ ) } @$unique ) {
        next if $field->errors;

        my $value = $field->value;
        next unless defined $value;

        my $name = $field->name;

        # unique means there can only be on in the database like it.
        my $match = $class->new( $name => $value );
        $match->load( speculative => 1 );
        next if $match->not_found;

        next if $self->items_same( $item, $match );

        $field->add_error( 'Value must be unique in the database' );
        $found_error++;
    }

    return !$found_error;
}

=head2 items_same

Internal method. Compares two RDBO items. Returns true, if the items are same.

=cut

sub items_same {
    my ( $self, $item1, $item2 ) = @_;

    # returns true if both are undefined
    return 1 if not defined $item1 and not defined $item2;

    # return false if either undefined
    return unless defined $item1 and defined $item2;

    return $self->primary_key( $item1 ) eq $self->primary_key( $item2 );
}

=head2 primary_key

Internal method. Returns the primary key of items. Joins compound primary key in
one string value. Used in method items_same.

=cut

sub primary_key {
    my ( $self, $item ) = @_;
    return join '|',
      $item->meta->table,
      map { $_ . '=' . ( $item->$_ || '.' ) } $item->meta->primary_key_columns;
}

1;

=head1 AUTHORS

    vti <vti@cpan.org>; 
    dzhariy <dzhariy@cpan.org>

=head1 CONTRIBUTORS

L<Form::Processor::Model::CDBI> written by Bill Moseley;
L<Form::Processor::Model::DBIC> ( Gerda Shank )

A big part of code and documentation from those two modules is adapted and
used for current Form::Processor::Model::RDBO.

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Form::Processor> 
L<Form::Processor::Model::CDBI> 
L<Form::Processor::Model::DBIC>
L<Catalyst::Plugin::Form::Processor>
L<Rose::Object>
L<Rose::DB::Object>
L<Rose::DB::Object::Tutorial>

=cut

1;
