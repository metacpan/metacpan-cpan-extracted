# NAME

Gideon

# SYNOPSYS

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

# WARNING

__This software is under heavy development, things may be broken and APIs
may change in the future until we reach v1.0.0__

# DESCRIPTION

Gideon's goal is to build a data access layer for your model and let you focus
on business logic. It's designed to support multiple backends and to be extended
to support other features not provided with the distribution.

Gideon is built on top of [Moose](http://search.cpan.org/perldoc?Moose) and depends on the [Class::MOP](http://search.cpan.org/perldoc?Class::MOP) to
automagically build the data access interface for your objects

## Getting Started

The best place to start is the [Gideon::Manual](http://search.cpan.org/perldoc?Gideon::Manual), also by looking at some of the
examples included in the distribution

# BENEFITS

The following list is some of the benefits that Gideon provides

- Simple to use and setup
- Multi-Backend support
- Cache support
- Simple interface for your objects
- Extensible via plug-ins

# OBJECT INTERFACE

Once an object is setup to use Gideon the following methods are added: `find`,
`find_one`, `save`, `remove` and `update`. Consumer of that class and/or
object use that interface to operate with your data store.

## `find( %opts )`

Used to find records matching a particular criteria expressed by the `%opts`,
please refer to [Gideon::Manual::Finding](http://search.cpan.org/perldoc?Gideon::Manual::Finding) to know more about the options.

    my @new_hires = Employee->find( started_at => { '>' => $last_moth } );
    

    # ... or ...
    my $new_hires = Employee->find( started_at => { '>' => $last_moth } );
    # This returns a Gideon::ResultSet and will not be retrieved until needed

## `find_one( %opts )`

Similar to find but only returns one record, this becomes handy, for example,
when retrieving an object by it's id.

    my $first_employee = Employee->find_one( id => 1 );

## `save()`

Save can be used to insert newly created object into the data store or to update
an specific record in the data store. For further details refer to 
[Gideon::Manual::Creating](http://search.cpan.org/perldoc?Gideon::Manual::Creating)

    # Inserts a record
    my $new_emp = Employee->new( name => 'John', started_at => DateTime->now);
    $new_emp->save;

    # Updates a record
    my $emp = Employee->find_one( id => 3 );
    $emp->name('Doe');
    $emp->save;

## `remove([%filter])`

Remove can be used to remove an individual record (called on an instance) or
to remove a group of records (called on a class). Please refer to
[Gideon::Manual::Removing](http://search.cpan.org/perldoc?Gideon::Manual::Removing) before using this method and make sure
you understand the differences when called into different contexts

    # Removing one record
    my $fist_employee = Employee->find_one( id => 1);
    $first_employee->remove;

    # Removing all records
    Employee->remove;

    # Removing all records with filter
    Employee->remove( id => { '>' => 10 });

## `update(%changes)`

Update can be used to update an individual record (called on an instance) or
to update a group of records (called on a class). Please refer to
[Gideon::Manual::Updating](http://search.cpan.org/perldoc?Gideon::Manual::Updating) before using this method and make sure
you understand the differences when called into different contexts

    # Update one record
    Employee->find_one( id => 1)->update( name => 'John Doe');

    # Update all records
    Employee->update( name => 'John Doe' );

# Getting Help

You can get help at `#gideon` on [irc://irc.perl.org/\#gideon](irc://irc.perl.org/\#gideon)
