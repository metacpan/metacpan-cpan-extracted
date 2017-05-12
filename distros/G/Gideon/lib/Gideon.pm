package Gideon;
{
  $Gideon::VERSION = '0.0.3';
}
use Moose;
use Moose::Exporter;
use Gideon::Plugin::Cache;
use Gideon::Plugin::StrictMode;
use Gideon::Plugin::ResultSet;
use Gideon::Meta::Class::Trait::Persisted;
use Carp qw(croak);

#ABSTRACT: Data mapper for Moose classes an objects

my ($import) = Moose::Exporter->build_import_methods(
    class_metaroles => { class => ['Gideon::Meta::Class'] },
    also            => ['Moose'],
    install          => [ 'unimport', 'init_meta' ],
    base_class_roles => ['Gideon::Meta::Class::Trait::Persisted'],
);

sub import {
    my ( $class, %args ) = @_;

    if ( $args{driver} ) {

        my $driver = "Gideon::Driver::$args{driver}";
        eval "require $driver";
        croak "Can't load driver $args{driver}: $@" if $@;

        my $cache = Gideon::Plugin::Cache->new( next => $driver->new );
        my $strict = Gideon::Plugin::StrictMode->new( next => $cache );
        my $result_set = Gideon::Plugin::ResultSet->new( next => $strict );

        my $target = caller;
        no strict 'refs';
        *{"${target}::find"}     = sub { $result_set->find(@_) };
        *{"${target}::find_one"} = sub { $result_set->find_one(@_) };
        *{"${target}::update"}   = sub { $result_set->update(@_) };
        *{"${target}::remove"}   = sub { $result_set->remove(@_) };
        *{"${target}::save"}     = sub { $result_set->save(@_) };
        use strict 'refs';
    }

    @_ = ($class);
    goto &$import;
}

1;

__END__

=pod

=head1 NAME

Gideon - Data mapper for Moose classes an objects

=head1 VERSION

version 0.0.3

=head1 DESCRIPTION

Gideon's goal is to build a data access layer for your model and let you focus
on business logic. It's designed to support multiple backends and to be extended
to support other features not provided with the distribution.

Gideon is built on top of L<Moose> and depends on the L<Class::MOP> to
automagically build the data access interface for your objects

=head2 Getting Started

The best place to start is the L<Gideon::Manual>, also by looking at some of the
examples included in the distribution

=head1 NAME

Gideon = Data mapper for Moose classes an objects

=head1 VERSION

version 0.0.3

=head1 SYNOPSYS

  package Customer;
  use Gideon driver => 'DBI';

  has id => ( 
      is          => 'rw',
      isa         => 'Num', 
      traits      => [ 'Gideon::DBI::Column' ],
      primary_key => 1
  );

  has name => ( 
      is          => 'rw',
      isa         => 'Str', 
      traits      => [ 'Gideon::DBI::Column' ],
  );

  __PACKAGE__->meta->store('mydb:customers');

  package main;
  use DBI;
  use Gideon::Registry

  # Start-up code
  my $dbh = DBI->connect(...);
  Gideon::Registry->register_store( mydb => $dbh );
  
  # Application code
  my $first_customer = Customer->find_one( id => 1);
  my @all_custoemrs = Customer->find();

=head1 WARNING

B<This software is under heavy development, things may be broken and APIs
may change in the future until we reach v1.0.0>

=head1 BENEFITS

The following list is some of the benefits that Gideon provides

=over 4

=item Simple to use and setup

=item Multi-Backend support

=item Cache support

=item Simple interface for your objects

=item Extensible via plug-ins

=back

=head1 OBJECT INTERFACE

Once an object is setup to use Gideon the following methods are added: C<find>,
C<find_one>, C<save>, C<remove> and C<update>. Consumer of that class and/or
object use that interface to operate with your data store.

=head2 C<find( %opts )>

Used to find records matching a particular criteria expressed by the C<%opts>,
please refer to L<Gideon::Manual::Finding> to know more about the options.

  my @new_hires = Employee->find( started_at => { '>' => $last_moth } );
  
  # ... or ...
  my $new_hires = Employee->find( started_at => { '>' => $last_moth } );
  # This returns a Gideon::ResultSet and will not be retrieved until needed

=head2 C<find_one( %opts )>

Similar to find but only returns one record, this becomes handy, for example,
when retrieving an object by it's id.

  my $first_employee = Employee->find_one( id => 1 );

=head2 C<save()>

Save can be used to insert newly created object into the data store or to update
an specific record in the data store. For further details refer to 
L<Gideon::Manual::Creating>

   # Inserts a record
   my $new_emp = Employee->new( name => 'John', started_at => DateTime->now);
   $new_emp->save;

   # Updates a record
   my $emp = Employee->find_one( id => 3 );
   $emp->name('Doe');
   $emp->save;

=head2 C<remove([%filter])>

Remove can be used to remove an individual record (called on an instance) or
to remove a group of records (called on a class). Please refer to
L<Gideon::Manual::Removing> before using this method and make sure
you understand the differences when called into different contexts

  # Removing one record
  my $fist_employee = Employee->find_one( id => 1);
  $first_employee->remove;

  # Removing all records
  Employee->remove;

  # Removing all records with filter
  Employee->remove( id => { '>' => 10 });

=head2 C<update(%changes)>

Update can be used to update an individual record (called on an instance) or
to update a group of records (called on a class). Please refer to
L<Gideon::Manual::Updating> before using this method and make sure
you understand the differences when called into different contexts

  # Update one record
  Employee->find_one( id => 1)->update( name => 'John Doe');

  # Update all records
  Employee->update( name => 'John Doe' );

=head1 Getting Help

You can get help at C<#gideon> on L<irc://irc.perl.org/#gideon>

=head1 AUTHOR

Mariano Wahlmann, Gines Razanov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mariano Wahlmann, Gines Razanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
