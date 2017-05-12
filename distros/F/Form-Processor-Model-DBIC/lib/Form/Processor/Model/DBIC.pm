package Form::Processor::Model::DBIC;

use base 'Form::Processor';
use Carp;

our $VERSION = '0.10001';

=head1 NAME

Form::Processor::Model::DBIC - Model class for Form Processor using DBIx::Class

=head1 SYNOPSIS

You need to create a form class, templates, and call F::P from a controller.

Create a Form, subclassed from Form::Processor::Model::DBIC

    package MyApp:Form::User;
    use strict;
    use base 'Form::Processor::Model::DBIC';

    # Associate this form with a DBIx::Class result class
    sub object_class { 'User' } # Where 'User' is the DBIC source_name 

    # Define the fields that this form will operate on
    # Field names must be column or relationship names in your
    # DBIx::Class result class
    sub profile {
        return {
            fields => {
                name        => {
                   type => 'Text',
                   label => 'Name:',
                   required => 1,
                   noupdate => 1,
                },
                age         => {
                    type => 'PosInteger',
                    label    => 'Age:',
                    required => 1,
                },
                sex         => {
                    type => 'Select',
                    label => 'Gender:',
                    required => 1,
                },
                birthdate   => '+MyApp::Field::Date', # customized field class
                hobbies     =>  {
                    type => 'Multiple',
                    size => 5,
                },
                address     => 'Text',
                city        => 'Text',
                state       => 'Select',
            },

            dependency => [
                ['address', 'city', 'state'],
            ],
        };

Then in your template:

For an input field:

   <p>
   [% f = form.field('address') %]
   <label class="label" for="[% f.name %]">[% f.label || f.name %]</label>
   <input type="text" name="[% f.name %]" id="[% f.name %]">
   </p>


For a select list provide a relationship name as the field name, or provide
an options_<field_name> subroutine in the form. (field attributes: sort_order, 
label_column, active_column). TT example:

   <p>
   [% f = form.field('sex') %]
   <label class="label" for="[% f.name %]">[% f.label || f.name %]</label>
   <select name="[% f.name %]">
     [% FOR option IN f.options %]
       <option value="[% option.value %]" [% IF option.value == f.value %]selected="selected"[% END %]>[% option.label | html %]</option>
     [% END %] 
   </select>
   </p>

For a complex, widget-based TT setup, see the examples directory in the
L<Catalyst::Plugin::Form::Processor> CPAN download.
 
Then in a Catalyst controller (with Catalyst::Controller::Form::Processor):

    package MyApp::Controller::User;
    use strict;
    use warnings;
    use base 'Catalyst::Controller::Form::Processor';

    # Create or edit
    sub edit : Local {
        my ( $self, $c, $user_id ) = @_;
        $c->stash->{template} = 'user/edit.tt'; 
        # Validate and insert/update database. Args = pk, form name
        return unless $self->update_from_form( $user_id, 'User' );
        # Form validated.
        $c->stash->{user} = $c->stash->{form}->item;
        $c->res->redirect($c->uri_for('profile'));
    }

With the Catalyst controller the schema is set from the model_name config
options, ($c->model($model_name)...), but it can also be set by passing 
in the schema on "new", or setting with $form->schema($schema). You can
also set a config values for whether or not to use FillInForm, and
the form namespace.


=head1 DESCRIPTION

This DBIC model will save form fields automatically to the database, will
retrieve selection lists from the database (with type => 'Select' and a 
fieldname containing a single relationship, or type => 'Multiple' and a
many_to_many pseudo-relationship), and will save the selected values (one value for 
'Select', multiple values in a mapping table for a 'Multiple' field). 

This package includes a working example using a SQLite database and a
number of forms. The templates are straightforward and unoptimized to
make it easier to see what they're doing.

=head1 METHODS

=head2 schema

The schema method is primarily intended for non-Catalyst users, so
that they can pass in their DBIx::Class schema object.

=cut

use Rose::Object::MakeMethods::Generic (
    scalar => [
        'schema'      => { interface => 'get_set_init' },
        'source_name' => {},
    ],
);

=head2 update_from_form

    my $validated = $form->update_from_form( $parameter_hash );

This is not the same as the routine called with $self->update_from_form. That
is a Catalyst plugin routine that calls this one. This routine updates or
creates the object from values in the form.

All fields that refer to columns and have changed will be updated. Field names
that are a single relationship will be updated. Any field names that are related 
to the class by "many_to_many" are assumed to have a mapping table and will be 
updated.  Validation is run unless validation has already been run.  
($form->clear might need to be called if the $form object stays in memory
between requests.)

The actual update is done in the C<update_model> method.  Your form class can
override that method (but don't forget to call SUPER) if you wish to do additional
database inserts or updates.  This is useful when a single form updates 
multiple tables, or there are secondary tables to update.

Returns false if form does not validate, otherwise returns 1.  Very likely dies on database errors.

=cut

sub update_from_form {
    my ( $self, $params ) = @_;
    return unless $self->validate($params);
    $self->schema->txn_do( sub { $self->update_model } );
    return 1;
}

=head2 model_validate

The place to put validation that requires database-specific lookups.
Subclass this method in your form.

=cut

sub model_validate {
    my ($self) = @_;
    return unless $self->validate_unique;
    return 1;
}

=head2 update_model

This is where the database row is updated. If you want to do some extra
database processing (such as updating a related table) this is the
method to subclass in your form.

This routine allows the use of non-database (non-column, non-relationship) 
accessors in your result source class. It identifies form fields as 1) column,
2) relationship, 3) other. Column and other fields are processed and update
is called on the row. Then relationships are processed.

If the row doesn't exist (no primary key or row object was passed in), then
a row is created using "create" and the fields identified as columns passed
in a hashref, followed by "other" fields and relationships.

=cut

sub update_model {
    my ($self) = @_;
    my $item   = $self->item;
    my $source = $self->source;

    # get a hash of all fields, skipping fields marked 'noupdate'
    my $prefix = $self->name_prefix;
    my %columns;
    my %multiple_m2m;
    my %other;
    my $field;
    my $value;

    # Save different flavors of fields into hashes for processing
    foreach $field ( $self->fields ) {
        next if $field->noupdate;
        my $name = $field->name;
        $name =~ s/^$prefix\.//g if $prefix;

        # If the field is flagged "clear" then set to NULL.
        $value = $field->clear ? undef : $field->value;
        if ( $source->has_relationship($name) ) {
            # If this is a relationship then may need to convert it to
            # a column name.  The common situation is where the column name
            # is "artist_id" but the belongs_to relation name is "artist"
            # where "artist" is what is used as the field name in the form.
            #
            # Another option would be to convert the $value into an object
            # as then can set the relationship like this $cd->artist_rel( $artist_object )
            ($name) = values %{ $source->relationship_info($name)->{cond} };
            $name =~ s{^self\.}{};
            $columns{$name} = $value;
        }
        elsif ( $source->has_column($name) ) {
            $columns{$name} = $value;
        }
        elsif ( $field->can('multiple') && $field->multiple == 1 ) {

            # didn't have a relationship and is multiple, so must be m2m
            $multiple_m2m{$name} = $value;
        }
        else    # neither a column nor a rel
        {
            $other{$name} = $value;
        }
    }

    # Handle database columns
    if ($item) {
        $self->updated_or_created('updated');
    }
    else {
        $item = $self->resultset->new_result( {} );
        $self->item($item);
        $self->updated_or_created('created');
    }
    for my $field_name ( keys %columns ) {
        $value = $columns{$field_name};
        my $cur = $item->$field_name;
        next unless $value || $cur;
        next if ( ( $value && $cur ) && ( $value eq $cur ) );
        $item->$field_name($value);
    }

    # set non-column, non-rel attributes
    for my $field_name ( keys %other ) {
        next unless $item->can($field_name);
        $item->$field_name( $other{$field_name} );
    }

    # update db
    if ( $item->in_storage ) {
        $item->update;
    }
    else {
        $item->insert;
    }

    # process Multiple field 'many_to_many' relationships
    if (%multiple_m2m) {

        for my $col_name ( keys %multiple_m2m ) {

            # Make sure the $col_name is a relation
            next unless $item->can($col_name);

            my $value = $multiple_m2m{$col_name};

            # Get a result source, primary key, and resultset
            # for the related many_to_many class
            my $f_source = $item->$col_name->result_source;
            my ($key)    = $f_source->primary_columns;
            my $f_rs     = $f_source->resultset;

            # And set.
            my $method = 'set_' . $col_name;
            my @objs = $f_rs->search( { $key => $value } );
            $item->$method(@objs);
        }
    }

    $self->reset_params;    # force reload of parameters from values
    return $item;
}


=head2 guess_field_type

This subroutine is only called for "auto" fields, defined like:
    return {
       auto_required => ['name', 'age', 'sex', 'birthdate'],
       auto_optional => ['hobbies', 'address', 'city', 'state'],
    };

Pass in a column and it will guess the field type and return it.

Currently returns:
    DateTimeDMYHM   - for a has_a relationship that isa DateTime
    Select          - for a has_a relationship
    Multiple        - for a has_many

otherwise:
    DateTimeDMYHM   - if the field ends in _time
    Text            - otherwise

Subclass this method to do your own field type assignment based
on column types. This routine returns either an array or type string. 

=cut

sub guess_field_type {
    my ( $self, $column ) = @_;
    my $source = $self->source;
    my @return;

    #  TODO: Should be able to use $source->column_info

    # Is it a direct has_a relationship?
    if (
        $source->has_relationship($column)
        && (
            $source->relationship_info($column)->{attrs}->{accessor} eq 'single'
            || $source->relationship_info($column)->{attrs}->{accessor} eq
            'filter' )
      )
    {
        my $f_class = $source->related_class($column);
        @return =
          $f_class->isa('DateTime')
          ? ('DateTimeDMYHM')
          : ('Select');
    }

    # Else is it has_many?
    elsif ($source->has_relationship($column)
        && $source->relationship_info($column)->{attrs}->{accessor} eq 'multi' )
    {
        @return = ('Multiple');
    }
    elsif ( $column =~ /_time$/ )    # ends in time, must be time value
    {
        @return = ('DateTimeDMYHM');
    }
    else                             # default: Text
    {
        @return = ('Text');
    }

    return wantarray ? @return : $return[0];
}

=head2 lookup_options

This method is used with "Single" and "Multiple" field select lists 
("single", "filter", and "multi" relationships).
It returns an array reference of key/value pairs for the column passed in.
The column name defined in $field->label_column will be used as the label.
The default label_column is "name".  The labels are sorted by Perl's cmp sort.

If there is an "active" column then only active values are included, except 
if the form (item) has currently selected the inactive item.  This allows
existing records that reference inactive items to still have those as valid select
options.  The inactive labels are formatted with brackets to indicate in the select
list that they are inactive.

The active column name is determined by calling:
    $active_col = $form->can( 'active_column' )
        ? $form->active_column
        : $field->active_column;

This allows setting the name of the active column globally if
your tables are consistantly named (all lookup tables have the same
column name to indicate they are active), or on a per-field basis.

The column to use for sorting the list is specified with "sort_order". 
The currently selected values in a Multiple list are grouped at the top
(by the Multiple field class).

=cut

sub lookup_options {
    my ( $self, $field ) = @_;

    my $field_name = $field->name;
    my $prefix     = $self->name_prefix;
    $field_name =~ s/^$prefix\.//g if $prefix;

    # if this field doesn't refer to a foreign key, return
    my $f_class;
    my $source;
    if ( $self->source->has_relationship($field_name) ) {
        $f_class = $self->source->related_class($field_name);
        $source  = $self->schema->source($f_class);
    }
    elsif ( $self->resultset->new_result( {} )->can("add_to_$field_name") ) {

        # Multiple field with many_to_many relationship
        $source =
          $self->resultset->new_result( {} )->$field_name->result_source;
    }
    return unless $source;

    my $label_column = $field->label_column;
    return unless $source->has_column($label_column);

    my $active_col =
        $self->can('active_column')
      ? $self->active_column
      : $field->active_column;

    $active_col = '' unless $source->has_column($active_col);
    my $sort_col = $field->sort_order;
    $sort_col = defined $sort_col
      && $source->has_column($sort_col) ? $sort_col : $label_column;

    my ($primary_key) = $source->primary_columns;

    # If there's an active column, only select active OR items already selected
    my $criteria = {};
    if ($active_col) {
        my @or = ( $active_col => 1 );

        # But also include any existing non-active
        push @or, ( "$primary_key" => $field->init_value )
          if $self->item && defined $field->init_value;
        $criteria->{'-or'} = \@or;
    }

    # get an array of row objects
    my @rows =
      $self->schema->resultset( $source->source_name )
      ->search( $criteria, { order_by => $sort_col } )->all;

    return [
        map {
            my $label = $_->$label_column;
            $_->id, $active_col && !$_->$active_col ? "[ $label ]" : "$label"
          } @rows
    ];
}

=head2 init_value

This method returns a field's value (for $field->value) with
either a scalar or an array ref from the object stored in $form->item.

This method is not called if a method "init_value_$field_name" is found 
in the form class - that method is called instead.
This allows overriding specific fields in your form class.

=cut
sub init_value {
    my ( $self, $field, $item ) = @_;

    my $name = $field->name;

    # Not sure a prefix is ever used.
    my $prefix = $self->name_prefix;
    $name =~ s/^$prefix\.//g if $prefix;

    # Fetch item if not passed in (should always be the case)
    $item ||= $self->item;
    return unless $item;

    # Our item may be an init object hash
    return $item->{$name} if ref($item) eq 'HASH';

    # Can we call the method on the object?
    return unless $item->isa('DBIx::Class') && $item->can($name);

    # Map any DBIC objects to their ids, but other objects (namely
    # DateTime objects) are passed as-is.  Many-to-many will be a list
    # of ids.
    return map { ref $_ && $_->isa('DBIx::Class') ? $_->id : $_ } $item->$name;

} ## end sub init_value



=head2 validate_unique

For fields that are marked "unique", checks the database for uniqueness.

   arraryref:
        unique => ['user_id', 'username']

   or hashref:
        unique => {
            username => 'That username is already taken',
        }

=cut

sub validate_unique {
    my ($self) = @_;

    my $unique      = $self->profile->{unique};
    my $item        = $self->item;
    my $rs          = $self->resultset;
    my $found_error = 0;
    my @unique_fields;
    my $error_message;
    if ( ref($unique) eq 'ARRAY' ) {
        @unique_fields = @$unique;
        $error_message = 'Value must be unique in the database';
    }
    if ( ref($unique) eq 'HASH' ) {
        @unique_fields = keys %$unique;
    }

    return 1 unless @unique_fields;
    for my $field ( map { $self->field($_) } @unique_fields ) {
        next if $field->errors;
        my $value = $field->value;
        next unless defined $value;
        my $name   = $field->name;
        my $prefix = $self->name_prefix;
        $name =~ s/^$prefix\.//g if $prefix;

        # unique means there can only be one in the database like it.
        my $count = $rs->search( { $name => $value } )->count;

        # not found, this one is unique
        next if $count < 1;

        # found this value, but it's the same row we're updating
        next
          if $count == 1
              && $self->item_id
              && $self->item_id ==
              $rs->search( { $name => $value } )->first->id;
        my $field_error =
             $field->unique_message
          || $error_message
          || $self->profile->{'unique'}->{$name};
        $field->add_error($field_error);
        $found_error++;
    }

    return $found_error;
}

=head2 init_item

This is called first time $form->item is called.
If using the Catalyst plugin, it sets the DBIx::Class schema from
the Catalyst context, and the model specified as the first part
of the object_class in the form. If not using Catalyst, it uses
the "schema" passed in on "new".

It then does:  

    return $self->resultset->find( $self->item_id );

It also validates that the item id matches /^\d+$/.  Override this method
in your form class (or form base class) if your ids do not match that pattern.

If a database row for the item_id is not found, item_id will be set to undef.

=cut

sub init_item {
    my $self = shift;

    my $item_id = $self->item_id or return;
    return unless $item_id =~ /^\d+$/;
    my $item = $self->resultset->find($item_id);
    $self->item_id(undef) unless $item;
    return $item;
}

=head2 init_schema

Initializes the DBIx::Class schema. User may override. Non-Catalyst
users should pass schema in on new:  
$my_form_class->new(item_id => $id, schema => $schema)

=cut

sub init_schema {
    my $self = shift;
    return if exists $self->{schema};
    if ( my $c = $self->user_data->{context} ) {

        # starts out <model>::<source_name>
        my $schema = $c->model( $self->object_class )->result_source->schema;

        # change object_class to source_name
        $self->source_name(
            $c->model( $self->object_class )->result_source->source_name );
        return $schema;
    }
    die "Schema must be defined for Form::Processor::Model::DBIC";
}

sub init_source_name {
    my $self = shift;
    return $self->object_class;
}

=head2 source

Returns a DBIx::Class::ResultSource object for this Result Class.

=cut

sub source {
    my ( $self, $f_class ) = @_;
    return $self->schema->source( $self->source_name || $self->object_class );
}

=head2 resultset

This method returns a resultset from the "object_class" specified
in the form, or from the foreign class that is retrieved from
a relationship.

=cut

sub resultset {
    my ( $self, $f_class ) = @_;
    return $self->schema->resultset( $self->source_name
          || $self->object_class );
}

=head2 build_form and _build_fields

These methods from Form::Processor are subclassed here to allow 
combining "required" and "optional" lists in one "fields" list, 
with "required" set like other field attributes.

=cut

sub build_form {
    my $self    = shift;
    my $profile = $self->profile;
    croak "Please define 'profile' method in subclass"
      unless ref $profile eq 'HASH';

    for my $group ( 'required', 'optional', 'fields' ) {
        my $required = 'required' eq $group;
        $self->_build_fields( $profile->{$group}, $required );
        my $auto_fields = $profile->{ 'auto_' . $group } || next;
        $self->_build_fields( $auto_fields, $required );
    }
}

sub _build_fields {
    my ( $self, $fields, $required ) = @_;
    return unless $fields;
    my $field;
    if ( ref($fields) eq 'ARRAY' ) {
        for (@$fields) {
            $field = $self->make_field( $_, 'Auto' ) || next;
            $field->required($required) unless ( exists $field->{required} );
            $self->add_field($field);
        }
        return;
    }
    while ( my ( $name, $type ) = each %$fields ) {
        $field = $self->make_field( $name, $type ) || next;
        $field->required($required) unless ( exists $field->{required} );
        $self->add_field($field);
    }
}

=head1 SEE ALSO

L<Form::Processor>
L<Form::Processor::Field>
L<Form::Processor::Model::CDBI>
L<Catalyst::Controller:Form::Processor>
L<Rose::Object>

=head1 AUTHOR

Gerda Shank, gshank@cpan.org

=head1 CONTRIBUTORS

Based on L<Form::Processor::Model::CDBI> written by Bill Moseley.

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
