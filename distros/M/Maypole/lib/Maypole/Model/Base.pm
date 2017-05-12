package Maypole::Model::Base;
use strict;

use Maypole::Constants;
use attributes ();

# don't know why this is a global - drb
our %remember;

sub MODIFY_CODE_ATTRIBUTES {
    shift; # class name not used
    my ($coderef, @attrs) = @_;
    $remember{$coderef} = [$coderef, \@attrs];

    # previous version took care to return an empty array, not sure why, 
    # but shall cargo cult it until know better
    return; 
}

sub FETCH_CODE_ATTRIBUTES { @{ $remember{$_[1]}->[1] || [] } }

sub CLONE {
 # re-hash %remember
 for my $key (keys %remember) {
 my $value = delete $remember{$key};
 $key = $value->[0];
 $remember{$key} = $value;
 }
}

sub process {
    my ( $class, $r ) = @_;
    my $method = $r->action;

    $r->{template} = $method;
    my $obj = $class->fetch_objects($r);
    $r->objects([$obj]) if $obj;
    
    $class->$method( $r, $obj, @{ $r->{args} } );
}

sub list_columns {
    shift->display_columns;
}

sub display_columns {
    sort shift->columns;
}

=head1 NAME

Maypole::Model::Base - Base class for model classes

=head1 DESCRIPTION

This is the base class for Maypole data models. This is an abstract class
that defines the interface, and can't be used directly.

=head2 process

This is the engine of this module. Given the request object, it populates
all the relevant variables and calls the requested action.

Anyone subclassing this for a different database abstraction mechanism
needs to provide the following methods:

=head2 setup_database

    $model->setup_database($config, $namespace, @data)

Uses the user-defined data in C<@data> to specify a database- for
example, by passing in a DSN. The model class should open the database,
and create a class for each table in the database. These classes will
then be C<adopt>ed. It should also populate C<< $config->tables >> and
C<< $config->classes >> with the names of the classes and tables
respectively. The classes should be placed under the specified
namespace. For instance, C<beer> should be mapped to the class
C<BeerDB::Beer>.

=head2 class_of

    $model->class_of($r, $table)

This maps between a table name and its associated class.

=head2 fetch_objects

This class method is passed a request object and is expected to return an
object of the appropriate table class from information stored in the request
object.

=head2 adopt

This class method is passed the name of a model class that represensts a table
and allows the master model class to do any set-up required.

=head2 columns

This is a list of all the columns in a table. You may also override
see also C<display_columns>

=head2 table

This is the name of the table.

=cut 

sub class_of       { die "This is an abstract method" }
sub setup_database { die "This is an abstract method" }
sub fetch_objects { die "This is an abstract method" }

=head2 Actions

=over

=item do_edit

If there is an object in C<$r-E<gt>objects>, then it should be edited
with the parameters in C<$r-E<gt>params>; otherwise, a new object should
be created with those parameters, and put back into C<$r-E<gt>objects>.
The template should be changed to C<view>, or C<edit> if there were any
errors. A hash of errors will be passed to the template.

=cut

sub do_edit { die "This is an abstract method" }

=item list

The C<list> method should fill C<$r-E<gt>objects> with all of the
objects in the class. You may want to page this using C<Data::Page> or
similar.

=item edit

Empty Action.

=item view

Empty Action.

=item index

Empty Action, calls list if provided with a table.

=back

=cut

sub list : Exported {
    die "This is an abstract method";
}

sub view : Exported {
}

sub edit : Exported {
}

sub index : Exported {
    my ( $self, $r ) = @_;
    if ($r->table) {
	$r->template("list");
	return $self->list($r);
    } 
}

=pod

Also, see the exported commands in C<Maypole::Model::CDBI>.

=head1 Other overrides

Additionally, individual derived model classes may want to override the
following methods:

=head2 display_columns

Returns a list of columns to display in the model. By default returns
all columns in alphabetical order. Override this in base classes to
change ordering, or elect not to show columns.

=head2 list_columns

Same as display_columns, only for listings. Defaults to display_columns

=head2 column_names

Return a hash mapping column names with human-readable equivalents.

=cut

sub column_names {
    my $class = shift;
    map {
        my $col = $_;
        $col =~ s/_+(\w)?/ \U$1/g;
        $_ => ucfirst $col
    } $class->columns;
}

=head2 is_public

should return true if a certain action is supported, or false otherwise. 
Defaults to checking if the sub has the C<:Exported> attribute.

=cut

sub is_public {
    my ( $self, $action, $attrs ) = @_;
    my $cv = $self->can($action);
    warn "is_public failed . action is $action. self is $self" and return 0 unless $cv;

    my %attrs = (ref $attrs) ?  %$attrs : map {$_ => 1} $self->method_attrs($action,$cv) ;

    do {
	warn "is_public failed. $action not exported. attributes are : ", %attrs;
	return 0;
    } unless $attrs{Exported};
    return 1;
}


=head2 add_model_superclass

Adds model as superclass to model classes (if necessary)

=cut

sub add_model_superclass { return; }

=head2 method_attrs

Returns the list of attributes defined for a method. Maypole itself only
defines the C<Exported> attribute. 

=cut

sub method_attrs {
    my ($class, $method, $cv) = @_;
    
    $cv ||= $class->can($method);
    
    return unless $cv;
    
    my @attrs = attributes::get($cv);

    return @attrs;
}

=head2 related

This can go either in the master model class or in the individual
classes, and returns a list of has-many accessors. A brewery has many
beers, so C<BeerDB::Brewery> needs to return C<beers>.

=cut

sub related {
}

1;


=head1 SEE ALSO

L<Maypole>, L<Maypole::Model::CDBI>.

=head1 AUTHOR

Maypole is currently maintained by Aaron Trevena.

=head1 AUTHOR EMERITUS

Simon Cozens, C<simon#cpan.org>

Simon Flack maintained Maypole from 2.05 to 2.09

Sebastian Riedel, C<sri#oook.de> maintained Maypole from 1.99_01 to 2.04

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
