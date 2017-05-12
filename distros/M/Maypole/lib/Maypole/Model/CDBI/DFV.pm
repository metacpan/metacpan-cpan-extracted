package Maypole::Model::CDBI::DFV;
use strict;

=head1 NAME

Maypole::Model::CDBI::DFV - Class::DBI::DFV model for Maypole.

=head1 SYNOPSIS

    package Foo;
    use 'Maypole::Application';

    Foo->config->model("Maypole::Model::CDBI::DFV");
    Foo->setup([qw/ Foo::SomeTable Foo::Other::Table /]);

    # Look ma, no untainting

    sub Foo::SomeTable::SomeAction : Exported {

        . . .

    }

=head1 DESCRIPTION

This module allows you to use Maypole with previously set-up
L<Class::DBI> classes that use Class::DBI::DFV;

Simply call C<setup> with a list reference of the classes you're going to use,
and Maypole will work out the tables and set up the inheritance relationships
as normal.

Better still, it will also set use your DFV profile to validate input instead
of CGI::Untaint. For teh win!!

=cut

use Data::FormValidator;
use Data::Dumper;

use Maypole::Config;
use Maypole::Model::CDBI::AsForm;

use base qw(Maypole::Model::CDBI::Base);

Maypole::Config->mk_accessors(qw(table_to_class _COLUMN_INFO));

=head1 METHODS

=head2 setup

  This method is inherited from Maypole::Model::Base and calls setup_database,
  which uses Class::DBI::Loader to create and load Class::DBI classes from
  the given database schema.

=head2 setup_database

  This method loads the model classes for the application

=cut

sub setup_database {
    my ( $self, $config, $namespace, $classes ) = @_;
    $config->{classes}        = $classes;
    foreach my $class (@$classes) {
      $namespace->load_model_subclass($class);
    }
    $namespace->model_classes_loaded(1);
    $config->{table_to_class} = { map { $_->table => $_ } @$classes };
    $config->{tables}         = [ keys %{ $config->{table_to_class} } ];
}

=head2 class_of

  returns class for given table

=cut

sub class_of {
    my ( $self, $r, $table ) = @_;
    return $r->config->{table_to_class}->{$table};
}

=head2 adopt

This class method is passed the name of a model class that represensts a table
and allows the master model class to do any set-up required.

=cut

sub adopt {
    my ( $self, $child ) = @_;
    if ( my $col = $child->stringify_column ) {
        $child->columns( Stringify => $col );
    }
}

=head2 check_params

  Checks parameters against the DFV profile for the class, returns the results
  of DFV's check.

  my $dfv_results = __PACKAGE__->check_params($r->params);

=cut

sub check_params {
  my ($class,$params) = @_;
  return Data::FormValidator->check($params, $class->dfv_profile);
}


=head1 Action Methods

Action methods are methods that are accessed through web (or other public) interface.

Inherited from L<Maypole::Model::CDBI::Base> except do_edit (below)

=head2 do_edit

If there is an object in C<$r-E<gt>objects>, then it should be edited
with the parameters in C<$r-E<gt>params>; otherwise, a new object should
be created with those parameters, and put back into C<$r-E<gt>objects>.
The template should be changed to C<view>, or C<edit> if there were any
errors. A hash of errors will be passed to the template.

=cut

sub do_edit : Exported {
  my ($class, $r, $obj) = @_;

  my $config   = $r->config;
  my $table    = $r->table;

  # handle cancel button hit
  if ( $r->params->{cancel} ) {
    $r->template("list");
    $r->objects( [$class->retrieve_all] );
    return;
  }


  my $errors;
  if ($obj) {
    ($obj,$errors) = $class->_do_update($r,$obj);
  } else {
    ($obj,$errors) = $class->_do_create($r);
  }

  # handle errors, if none, proceed to view the newly created/updated object
  if (ref $errors) {
    # pass errors to template
    $r->template_args->{errors} = $errors;
    # Set it up as it was:
    $r->template_args->{cgi_params} = $r->params;
    $r->template("edit");
  } else {
    $r->template("view");
  }

  $r->objects( $obj ? [$obj] : []);
}

sub _do_update {
  my ($class,$r,$obj) = @_;
  my $errors;
  my $dfv_results = Data::FormValidator->check($r->{params}, $class->dfv_profile);

  # handle dfv errors
  if ( $dfv_results->has_missing ) {   # missing fields
    foreach my $field ( $dfv_results->missing ) {
      $errors->{$field} = "$field is required";
    }
  }
  if ( $dfv_results->has_invalid ) {   # Print the name of invalid fields
    foreach my $field ( $dfv_results->invalid ) {
      $errors->{$field} =  "$field is invalid: " . $dfv_results->invalid( $field );
    }
  }


  my $this_class_params = {};


  # NG changes start here.
  # Code below fails to handle multi col PKs
  my @pks = $class->columns('Primary');

  foreach my $param ( $class->columns ) {
    # next if ($param eq $class->columns('Primary'));
    next if grep {/^${param}$/} @pks;

    my $value = $r->params->{$param};
    next unless (defined $value);
    $this_class_params->{$param} = ( $value eq '' ) ?  undef : $value;
  }

  # update or make other related (must_have, might_have, has_many  etc )
  unless ($errors) {
    foreach my $accssr ( grep ( !(exists $this_class_params->{$_}) , keys %{$r->{params}} ) ) {
      # get related object if it exists
      my $rel_meta = $class->related_meta('r',$accssr);
      if (!$rel_meta) {
	$r->warn("[_do_update] No relationship for $accssr in " . ref($class));
	next;
      }

      my $rel_type  = $rel_meta->{name};
      my $fclass    = $rel_meta->{foreign_class};
      my ($rel_obj,$errs);
      $rel_obj = $fclass->retrieve($r->params->{$accssr});
      # update or create related object
      ($rel_obj, $errs) = ($rel_obj)
	? $fclass->_do_update($r, $rel_obj)
	  : $obj->_create_related($accssr, $r->params);
      $errors->{$accssr} = $errs if ($errs);
    }
  }

  unless ($errors) {
    $obj->set( %$this_class_params );
    $obj->update;
  }

  return ($obj,$errors);
}

sub _do_create {
  my ($class,$r) = @_;
  my $errors;

  my $this_class_params = {};
  foreach my $param ( $class->columns ) {
    next if ($param eq $class->columns('Primary'));
    my $value = $r->params->{$param};
    next unless (defined $value);
    $this_class_params->{$param} = ( $value eq '' ) ?  undef : $value;
  }

  my $obj;

  my $dfv_results = Data::FormValidator->check($r->{params}, $class->dfv_profile);
  if ($dfv_results->success) {
    $obj = $class->create($this_class_params);
  } else {
    # handle dfv errors
    if ( $dfv_results->has_missing ) {   # missing fields
      foreach my $field ( $dfv_results->missing ) {
	$errors->{$field} = "$field is required";
      }
    }
    if ( $dfv_results->has_invalid ) {   # Print the name of invalid fields
      foreach my $field ( $dfv_results->invalid ) {
	$errors->{$field} =  "$field is invalid: " . $dfv_results->invalid( $field );
      }
    }
  }

  # Make other related (must_have, might_have, has_many  etc )
  unless ($errors) {
    foreach my $accssr ( grep ( !(exists $this_class_params->{$_}) , keys %{$r->{params}} ) ) {
      my ($rel_obj, $errs) = $obj->_create_related($accssr, $r->{params}{$accssr});
      $errors->{$accssr} = $errs if ($errs);
    }
  }
  return ($obj,$errors);
}


sub _create_related {
  # self is object or class, accssr is accssr to relationship, params are
  # data for relobject, and created is the array ref to store objs
  my ( $self, $accssr, $params )  = @_;
  $self->_croak ("Can't make related object without a parent $self object") unless (ref $self);
  my $created = [];
  my $rel_meta = $self->related_meta('r',$accssr);
  if (!$rel_meta) {
    $self->_carp("[_create_related] No relationship for $accssr in " . ref($self));
    return;
  }

  my $rel_type  = $rel_meta->{name};
  my $fclass    = $rel_meta->{foreign_class};

  my ($rel, $errs);

  # Set up params for might_have, has_many, etc
  if ($rel_type ne 'has_own' and $rel_type ne 'has_a') {
    # Foreign Key meta data not very standardized in CDBI
    my $fkey= $rel_meta->{args}{foreign_key} || $rel_meta->{foreign_column};
    unless ($fkey) { die " Could not determine foreign key for $fclass"; }
    my %data = (%$params, $fkey => $self->id);
    %data = ( %data, %{$rel_meta->{args}->{constraint} || {}} );
    ($rel, $errs) =  $fclass->_do_create(\%data);
  }
  else {
    ($rel, $errs) =  $fclass->_do_create($params);
    unless ($errs) {
      $self->$accssr($rel->id);
      $self->update;
    }
  }
  return ($rel, $errs);
}


=head2 do_delete

Inherited from Maypole::Model::CDBI::Base.

This action deletes records

=head2 do_search

Inherited from Maypole::Model::CDBI::Base.

This action method searches for database records.

=head2 list

Inherited from Maypole::Model::CDBI::Base.

The C<list> method fills C<$r-E<gt>objects> with all of the
objects in the class. The results are paged using a pager.

=cut

sub _column_info {
  my $class = shift;

  # get COLUMN INFO from DB
  $class->SUPER::_column_info() unless (ref $class->COLUMN_INFO);

  # update with required columns from DFV Profile
  my $profile = $class->dfv_profile;
  $class->required_columns($profile->{required});

  return $class->COLUMN_INFO;
}



=head1 SEE ALSO

L<Maypole::Model::Base>

L<Maypole::Model::CDBI::Base>

=head1 AUTHOR

Aaron Trevena.

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;


