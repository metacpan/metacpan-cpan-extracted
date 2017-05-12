use warnings;
use strict;

package Jifty::DBI::Schema;

=head1 NAME

Jifty::DBI::Schema - Use a simple syntax to describe a Jifty table.

=head1 SYNOPSIS

    package MyApp::Model::Page;
    use Jifty::DBI::Schema;
    use Jifty::DBI::Record schema {
    # ... your columns here ...
    };

=cut

=head1 DESCRIPTION

Each Jifty Application::Model::Class module describes a record class
for a Jifty application.  Each C<column> statement sets out the name
and attributes used to describe the column in a backend database, in
user interfaces, and other contexts.  For example:

    column content =>
       type is 'text',
       label is 'Content',
       render as 'textarea';

defines a column called C<content> that is of type C<text>.  It will be
rendered with the label C<Content> (note the capital) and as a C<textarea> in
a HTML form.

Jifty::DBI::Schema builds a L<Jifty::DBI::Column>.  That class defines
other attributes for database structure that are not exposed directly
here.  One example of this is the "refers_to" method used to create
associations between classes.

It re-exports C<defer> and C<lazy> from L<Scalar::Defer>, for setting
parameter fields that must be recomputed at request-time:

    column name =>
        default is defer { Jifty->web->current_user->name };

See L<Scalar::Defer> for more information about C<defer>.

=cut

use Carp qw/croak carp/;
use Scalar::Defer;
use base qw(Class::Data::Inheritable);
__PACKAGE__->mk_classdata('TYPES' => {});

use Object::Declare (
    mapping => {
        column => sub { Jifty::DBI::Column->new({@_}) } ,
    },
    aliases => {
        default_value => 'default',
        available   => 'available_values',
        valid       => 'valid_values',
        render      => 'render_as',
        order       => 'sort_order',
        filters     => 'input_filters',
    },
    copula  => {
        is          => sub { return @_ if $#_;
                             my $typehandler = __PACKAGE__->TYPES->{$_[0]};
                             # XXX: when we have a type name
                             # convention, give a warning when it
                             # looks like a type name but not found
                             return ($_[0] => 1) unless $typehandler;
                             return $typehandler->();
        },
        are         => '',
        as          => '',
        ajax        => 'ajax_',
        refers_to   => sub { refers_to => @_ },
        references  => sub { refers_to => @_ },
    },
);
use Class::Data::Inheritable;
use UNIVERSAL::require ();

our @EXPORT = qw( defer lazy column schema by render_as since till literal);

sub by ($) { @_ }
sub render_as ($) { render as @_ }
sub since ($) { since is @_ }
sub till ($) { till is @_ }

sub literal($) {
    my $value = shift;
    return \$value;
}

our $SCHEMA;
our $SORT_ORDERS = {};

use Exporter::Lite ();
# TODO - This "sub import" is strictly here to catch the deprecated "length is 40".
#        Once the deprecation cycle is over we should take the SIGDIE swapping away
my $old_sig_die;

sub import {
    no warnings qw( uninitialized numeric );
    $old_sig_die ||= $SIG{__DIE__};
    $SIG{__DIE__} = \&filter_die unless $SIG{__DIE__} and $SIG{__DIE__} == \&filter_die;

    strict->import;
    warnings->import;

    goto &Exporter::Lite::import;
}

=head2 filter_die

=cut

sub filter_die {
    # Calling it by hand means we restore the old sighandler.
    $SIG{__DIE__} = $old_sig_die;
    if ($_[0] =~ /near "is (\d+)"/) {
        carp @_, << ".";

*********************************************************

 Due to an incompatible API change, the "length" field in
 Jifty::DBI columns has been renamed to "max_length":
 
     column foo =>
         length is $1;       # NOT VALID 

 Please write this instead:
 
     column foo =>
         max_length is $1    # VALID

 Sorry for the inconvenience.

**********************************************************


.
        exit 1;
    }
    elsif ($_[0] =~ /Undefined subroutine &Jifty::DBI::Schema::column|Can't locate object method "type" via package "(?:is|are)"/) {
        my $from = (caller)[0];
        $from =~ s/::Schema$//;
        my $base = $INC{'Jifty/Record.pm'} ? "Jifty::Record" : "Jifty::DBI::Record";

        no strict 'refs';
        carp @_, << ".";
*********************************************************

 Calling 'column' within a schema class is an error:
 
    package $from\::Schema;
    column foo => ...;        # NOT VALID

 Please write this instead:

    package $from;
    use Jifty::DBI::Schema;
    use @{[(${"$from\::ISA"} || [$base])->[0] || $base]} schema {
        column foo => ...;    # VALID
    };

 Sorry for the inconvenience.

*********************************************************
.
    }

    die @_;
}


=head1 FUNCTIONS

All these functions are exported.  However, if you use the C<schema> helper function,
they will be unimported at the end of the block passed to C<schema>.

=head2 schema

Takes a block with schema declarations.  Unimports all helper functions after
executing the code block.  Usually used at C<BEGIN> time via this idiom:

    use Jifty::DBI::Record schema { ... };

If your application subclasses C<::Record>, then write this instead:

    use MyApp::Record schema { ... };

=cut

=head2 column

DEPRECATED.  This method of defining columns will not work anymore.  Please
use the C<schema {}> method documented above.

=cut

sub schema (&) {
    my $code = shift;
    my $from = caller;

    my $new_code = sub {
        no warnings 'redefine';
        local *_ = sub { my $args = \@_; defer { _(@$args) } };
        $from->_init_columns;

        my @columns = &declare($code);

# Unimport all our symbols from the calling package,
            # except for "lazy" and "defer".
        foreach my $sym (@EXPORT) {
                next if $sym eq 'lazy' or $sym eq 'defer';

            no strict 'refs';
            undef *{"$from\::$sym"}
            if \&{"$from\::$sym"} == \&$sym;
        }

        foreach my $column (@columns) {
            next if !ref($column);
            _init_column($column);
        }

        $from->_init_methods_for_columns;
    };

    return ('-base' => $new_code);
}

use Hash::Merge ();

no warnings 'uninitialized';
use constant MERGE_PARAM_BEHAVIOUR => {
    SCALAR => {
            SCALAR => sub { CORE::length($_[1]) ? $_[1] : $_[0] },
            ARRAY  => sub { [ @{$_[1]} ] },
            HASH   => sub { $_[1] } },
    ARRAY => {
            SCALAR => sub { CORE::length($_[1]) ? $_[1] : $_[0] },
            ARRAY  => sub { [ @{$_[1]} ] },
            HASH   => sub { $_[1] } },
    HASH => {
            SCALAR => sub { CORE::length($_[1]) ? $_[1] : $_[0] },
            ARRAY  => sub { [ @{$_[1]} ] },
            HASH   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) } }
};

=head2 merge_params HASHREF HASHREF

Takes two hashrefs. Merges them together and returns the merged hashref.

    - Empty fields in subclasses don't override nonempty fields in superclass anymore.
    - Arrays don't merge; e.g. if parent class's valid_values is [1,2,3,4], and
      subclass's valid_values() is [1,2], they don't somehow become [1,2,3,4,1,2].

BUG: This should either be a private routine or factored out into Jifty::Util



=cut

sub merge_params {
    my $prev_behaviour = Hash::Merge::get_behavior();
    Hash::Merge::specify_behavior( MERGE_PARAM_BEHAVIOUR, "merge_params" );
    my $rv = Hash::Merge::merge(@_);
    Hash::Merge::set_behavior( $prev_behaviour );
    return $rv;
}


sub _init_column {
    my $column = shift;
    my $name   = $column->name;

    my $from = (caller(2))[0];
    if ($from =~ s/::Schema$// && $from !~ /Script/) {
        no strict 'refs';

        carp << "." unless $from->{_seen_column_warning}++;

*********************************************************

 Calling 'column' within a schema class is deprecated:
 
    package $from\::Schema;
    column $name => ...;        # NOT VALID

 Please write this instead:

    package $from;
    use Jifty::DBI::Schema;
    use @{[${"$from\::ISA"}[0] || "Jifty::DBI::Record"]} schema {
        column $name => ...;    # VALID
    };

 Sorry for the inconvenience.

*********************************************************
.
    }
    return _init_column_for($column, $from, @_);
}

sub _init_column_for {
    my $column = shift;
    my $from   = shift;
    my $name   = $column->name;

    croak "Base of schema class $from is not a Jifty::DBI::Record"
      unless UNIVERSAL::isa($from, "Jifty::DBI::Record");

    croak "Illegal column definition for column $name in $from"
      if grep {not UNIVERSAL::isa($_, "Jifty::DBI::Schema::Trait")} @_;

    $column->readable(!(delete $column->attributes->{unreadable}));
    $column->writable(!(delete $column->attributes->{immutable}));

    # XXX: deprecated
    $column->mandatory(1) if delete $column->attributes->{not_null};

    $column->sort_order($SORT_ORDERS->{$from}++)
        unless defined $column->sort_order;

    $column->input_filters($column->{input_filters} || []);
    $column->output_filters($column->{output_filters} || []);

    # Set up relationships to other records and collections
    if ( my $refclass = $column->refers_to ) {
        
        # Handle refers_to SomeCollection by 'foo'
        if (ref($refclass) eq 'ARRAY') {
            $column->by($refclass->[1]);
            $column->refers_to($refclass = $refclass->[0]);
        }

        # Load the class we reference
        unless (UNIVERSAL::isa($refclass, 'Jifty::DBI::Record') || UNIVERSAL::isa($refclass, 'Jifty::DBI::Collection')) {
            local $UNIVERSAL::require::ERROR;
            $refclass->require();
            die $UNIVERSAL::require::ERROR if ($UNIVERSAL::require::ERROR);
        }
        # A one-to-one or one-to-many relationship is requested
        if ( UNIVERSAL::isa( $refclass, 'Jifty::DBI::Record' ) ) {
            # Assume we refer to the ID column unless told otherwise
            $column->by('id') unless $column->by;

            my $by = $column->by;
            unless ( $column->type ) {
                # XXX, TODO: we must set column type to the same value
                # as column we refer to.
                #
                # my $referenced_column = $refclass->column( $by );
                # $column->type( $referenced_column->type );
                $column->type('integer');
            }

            # Handle *_id reference columns specially
            if ( $name =~ /(.*)_\Q$by\E$/ ) {
                my $aliased_as = $1;
                my $virtual_column = $from->add_column($aliased_as);

                # Clone ourselves into the virtual column
                %$virtual_column = %$column;

                # This column is now just the ID, the virtual holds the ref
                $column->refers_to(undef);

                # Note the original column
                $virtual_column->aliased_as($aliased_as);
                $virtual_column->alias_for_column($name);
                $virtual_column->virtual(1);

                # Create the helper methods for the virtual column too
                $from->_init_methods_for_column($virtual_column);
                $from->COLUMNS->{$aliased_as} = $virtual_column;
            } else {
                my $aliased_as = $name .'_'. $by;
                my $virtual_column = $from->add_column($aliased_as);

                # Clone ourselves into the virtual column
                %$virtual_column = %$column;

                # This column is now just the ID, the virtual holds the ref
                $virtual_column->refers_to(undef); $virtual_column->by(undef);

                # Note the original column
                $virtual_column->aliased_as($aliased_as);
                $virtual_column->alias_for_column($name);
                $virtual_column->virtual(1);

                # Create the helper methods for the virtual column too
                $from->_init_methods_for_column($virtual_column);
                $from->COLUMNS->{$aliased_as} = $virtual_column;
            }
        } elsif ( UNIVERSAL::isa( $refclass, 'Jifty::DBI::Collection' ) ) {
            $column->by('id') unless $column->by;
            $column->virtual('1');
        } else {
            warn "Error in $from: $refclass neither Record nor Collection. Perhaps it couldn't be loaded?";
        }
    } else {
        $column->type('varchar(255)') unless $column->type;
    }

    if (my $handler = $column->attributes->{_init_handler}) {
        $handler->($column, $from);
    }

    $from->COLUMNS->{$name} = $column;

    # Heuristics: If we are called through Jifty::DBI::Schema, 
    # then we know that we are going to initialize methods later
    # through the &schema wrapper, so we defer initialization here
    # to not upset column names such as "label" and "type".
    # (We may not *have* a caller(1) if the user is executing a .pm file.)
}

=head2 register_types

=cut

sub register_types {
    my $class = shift;
    while (my ($type, $sub) = splice(@_, 0, 2)) {
        $class->TYPES->{$type} = $sub;
    }
}

__PACKAGE__->register_types(
    boolean => sub {
        encode_on_select is 1,
        type is 'boolean',
        filters are qw(Jifty::DBI::Filter::Boolean),
        default is 'false',
        render_as 'Checkbox',
        _init_handler is sub {
            my ($column, $from) = @_;
            no strict 'refs';
            Class::Trigger::add_trigger($from, name => "canonicalize_" . $column->name, callback => sub {
                my ($self,$value) = @_;
                $self->_apply_output_filters(
                    column    => $column,
                    value_ref => \$value,
                );
                return $value;
            });
        },
    },
);

1;

__END__

=head2 references

Indicates that the column references an object or a collection of objects in another
class.  You may refer to either a class that inherits from L<Jifty::Record> by a primary
key in that class or to a class that inherits from L<Jifty::Collection>.

=head3 referencing a record

Correct usage is C<references Application::Model::OtherClass by 'column_name'>, where
Application::Model::OtherClass is a valid Jifty model, subclass of L<Jifty::Record>,
and C<'column_name'> is a distinct column of OtherClass. You can omit C<by 'column_name'>
and the column name 'id' will be used.

At this moment you must specify type of the column your self to match type of the column
you refer to.

You can name a column as combination of 'name' and 'by', for example:

    column user_name => references App::Model::User by 'name', type is 'varchar(64)';

Then user, user_name and respective setters will be generated. user method will return
object, user_name will return actual value. Note that if you're using some magic on load
for user records then to get real name of loaded record you should use C<< $record->user->name >>
instead.

In the above case name of the column in the DB will be 'user_name'. If you don't like
suffixes like '_id', '_name' and other in the DB then you can name column without suffix,
for example:

    column user => references App::Model::User by 'name', type is 'varchar(64)';

In this case name of the column in the DB will be 'user', accessors will be the same
as in above example.

=head3 referencing a collection

Correct usage is C<references Application::Model::OtherCollection by 'column_name'>, where
Application::Model::OtherCollection is a valid Jifty model, subclass of L<Jifty::Collection>,
and C<'column_name'> is a column of records in OtherCollection. In this case  C<by 'column_name'>
is not optional.

Columns that refers to a collection are virtual and can be changed. So such columns in a model
doesn't create real columns in the DB, but instead it's way to name collection of records that
refer to this records.

=head3 example

Simple model with users and multiple phone records per user:

    package TestApp::Model::User;
    use Jifty::DBI::Schema;
    use Jifty::DBI::Record schema {
        column name  => type is 'varchar(18)';
        ...
        column phones => references TestApp::Model::PhoneCollection by 'user';
    };

    package TestApp::Model::Phone;
    use Jifty::DBI::Schema;
    use Jifty::DBI::Record schema {
        column user  => references TestApp::Model::User by 'id',
            is mandatory;
        column type  => ...;
        column value => ...;
    };

From a user record you get his phones and do something:

    my $phones = $user->phones;
    while ( my $phone = $phones->next ) {
        ...
    }

From a phone record you can get its owner or change it:

    my $user_object = $phone->user;
    my $user_id = $phone->user_id;

    $phone->set_user( $new_owner_object );
    $phone->set_user( 123 );    # using id
    $phone->set_user_id( 123 ); # the same, but only using id

=head2 refers_to

Synonym for C<references>.

=cut

=head2 by

Helper for C<references>.  Used to specify what column name should be
used in the referenced model.  See the documentation for C<references>.

=head2 type

type passed to our database abstraction layer, which should resolve it
to a database-specific type.  Correct usage is C<type is 'text'>.

Currently type is passed directly to the database.  There is no
intermediary mapping from abstract type names to database specific
types.

The impact of this is that not all column types are portable between
databases.  For example blobs have different names between
mysql and postgres.

=head2 default

Give a default value for the column.  Correct usage is C<default is
'foo'>.

=head2 literal

Used for default values, to connote that they should not be quoted
before being supplied as the default value for the column.  Correct
usage is C<default is literal 'now()'>.

=head2 validator

Defines a subroutine which returns a true value only for valid values
this column can have.  Correct usage is C<validator is \&foo>.

=head2 immutable

States that this column is not writable.  This is useful for
properties that are set at creation time but not modifiable
thereafter, like 'created by'.  Correct usage is C<is immutable>.

=head2 unreadable

States that this column is not directly readable by the application
using C<< $record->column >>; this is useful for password columns and
the like.  The data is still accessible via C<< $record->_value('') >>.
Correct usage is C<is unreadable>.

=head2 max_length

Sets a maximum max_length to store in the database; values longer than
this are truncated before being inserted into the database, using
L<Jifty::DBI::Filter::Truncate>.  Note that this is in B<bytes>, not
B<characters>.  Correct usage is C<max_length is 42>.


=head2 mandatory

Mark as a required column.  May be used for generating user
interfaces.  Correct usage is C<is mandatory>.

=head2 not_null

Same as L</mandatory>.  This is deprecated.  Correct usage would be
C<is not_null>.

=head2 autocompleted

Mark as an autocompleted column.  May be used for generating user
interfaces.  Correct usage is C<is autocompleted>.

=head2 distinct

Declares that a column should only have distinct values.  This
currently is implemented via database queries prior to updates
and creates instead of constraints on the database columns
themselves. This is because there is no support for distinct
columns implemented in L<DBIx::DBSchema> at this time.  
Correct usage is C<is distinct>.

=head2 virtual

Used to declare that a column references a collection, which hides
it from many parts of Jifty. You probably do not want to set this manually,
use C<references> instead.

=head2 computed

Declares that a column is not backed by an actual column in the
database, but is instead computed on-the-fly using a method written by
the application author. Such columns cannot (yet) be used in searching,
sorting, and so on, only inspected on an individual record.

=head2 sort_order

Declares an integer sort value for this column. By default, Jifty will sort
columns in the order they are defined.

=head2 order

Alias for C<sort_order>.

=head2 input_filters

Sets a list of input filters on the data.  Correct usage is
C<input_filters are 'Jifty::DBI::Filter::DateTime'>.  See
L<Jifty::DBI::Filter>.

=head2 output_filters

Sets a list of output filters on the data.  Correct usage is
C<output_filters are 'Jifty::DBI::Filter::DateTime'>.  See
L<Jifty::DBI::Filter>.  You usually don't need to set this, as the
output filters default to the input filters in reverse order.

=head2 filters

Sets a list of filters on the data.  These are applied when reading
B<and> writing to the database.  Correct usage is C<filters are
'Jifty::DBI::Filter::DateTime'>.  See L<Jifty::DBI::Filter>.  In
actuality, this is the exact same as L</input_filters>, since output
filters default to the input filters, reversed.

=head2 since

What application version this column was last changed.  Correct usage
is C<since '0.1.5'>.

=head2 till

The version after this column was supported. The column is not available in
the version named, but would have been in the version immediately prior.

Correct usage is C<till '0.2.5'>. This indicates that the column is not available in version C<0.2.5>, but was available in C<0.2.4>. The value specified for L</since> must be less than this version.

=cut

sub till {
    _list( till => @_ );
}

=head2 valid_values

A list of valid values for this column. Jifty will use this to
automatically construct a validator for you.  This list may also be used to
generate the user interface.  Correct usage is C<valid_values are
qw/foo bar baz/>.

If you want to display different values than are stored in the DB 
you can pass a list of hashrefs, each containing two keys, display 
and value.

 valid_values are
  { display => 'Blue', value => 'blue' },
  { display => 'Red', value => 'red' }

=head2 valid

Alias for C<valid_values>.

=head2 label

Designates a human-readable label for the column, for use in user
interfaces.  Correct usage is C<label is 'Your foo value'>.

=head2 hints

A sentence or two to display in long-form user interfaces about what
might go in this column.  Correct usage is C<hints is 'Used by the
frobnicator to do strange things'>.

=head2 display_length

The displayed length of form fields. Though you may be able to fit
500 characters in the field, you would not want to display an HTML
form with a size 500 input box.

=head2 render_as

Used in user interface generation to know how to render the column.

The values for this attribute are the same as the names of the modules under
L<Jifty::Web::Form::Field>, i.e. 

=over 

=item * Button

=item * Checkbox

=item * Combobox

=item * Date

=item * Hidden

=item * InlineButton

=item * Password

=item * Radio

=item * Select

=item * Textarea

=item * Upload

=item * Unrendered

=back

You may also use the same names with the initial character in lowercase. 

The "Unrendered" may seem counter-intuitive, but is there to allow for
internal fields that should not actually be displayed.

If these don't meet your needs, you can write your own subclass of
L<Jifty::Web::Form::Field>. See the documentation for that module.

=head2 render

Alias for C<render_as>.

=head2 indexed

An index will be built on this column
Correct usage is C<is indexed>


=head1 EXAMPLE

=head1 AUTHOR

=head1 BUGS

=head1 SUPPORT

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
