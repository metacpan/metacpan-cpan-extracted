#!/usr/bin/env perl -w

use strict;
use File::Temp ();
use Jifty::DBI::Handle;

=head1 VARIABLES

=head2 @supported_drivers

Array of all supported DBD drivers.

=cut

our @supported_drivers = Jifty::DBI::Handle->supported_drivers;

=head2 @available_drivers

Array that lists only drivers from supported list
that user has installed.

=cut

our @available_drivers = Jifty::DBI::Handle->available_drivers;

=head1 FUNCTIONS

=head2 get_handle

Returns new DB specific handle. Takes one argument DB C<$type>.
Other arguments uses to construct handle.

=cut

sub get_handle
{
        my $type = shift;
        my $class = 'Jifty::DBI::Handle::'. $type;
        eval "require $class";
        die $@ if $@;
        my $handle;
        $handle = $class->new( @_ );
        return $handle;
}

=head2 handle_to_driver

Returns driver name which gets from C<$handle> object argument.

=cut

sub handle_to_driver
{
        my $driver = ref($_[0]);
        $driver =~ s/^.*:://;
        return $driver;
}

=head2 connect_handle

Connects C<$handle> object to DB.

=cut

sub connect_handle
{
        my $call = "connect_". lc handle_to_driver( $_[0] );
        return unless defined &$call;
        goto &$call;
}

=head2 connect_handle_with_driver($handle, $driver)

Connects C<$handle> using driver C<$driver>; can use this to test the
magic that turns a C<Jifty::DBI::Handle> into a C<Jifty::DBI::Handle::Foo>
on C<Connect>.

=cut

sub connect_handle_with_driver
{
        my $call = "connect_". lc $_[1];
        return unless defined &$call;
        @_ = $_[0];
        goto &$call;
}


our $SQLITE_FILENAME;
sub connect_sqlite
{
        my $handle = shift;
        (undef, $SQLITE_FILENAME ) = File::Temp::tempfile();
        return $handle->connect(
                driver => 'SQLite',
                database => $SQLITE_FILENAME);
}

sub connect_mysql
{
        my $handle = shift;
        return $handle->connect(
                driver => 'mysql',
                database => $ENV{'JDBI_TEST_MYSQL'},
                user => $ENV{'JDBI_TEST_MYSQL_USER'} || 'root',
                password => $ENV{'JDBI_TEST_MYSQL_PASS'} || '',
        );
}

sub connect_pg
{
        my $handle = shift;
        return $handle->connect(
                driver => 'Pg',
                database => $ENV{'JDBI_TEST_PG'},
                user => $ENV{'JDBI_TEST_PG_USER'} || 'postgres',
                password => $ENV{'JDBI_TEST_PG_PASS'} || '',
        );
}

sub connect_oracle
{
        my $handle = shift;
        return $handle->Connect(
                driver   => 'Oracle',
#                database => $ENV{'JDBI_TEST_ORACLE'},
                user     => $ENV{'JDBI_TEST_ORACLE_USER'} || 'test',
                password => $ENV{'JDBI_TEST_RACLE_PASS'} || 'test',
        );
}

=head2 disconnect_handle

Disconnects C<$handle> object.

=cut

sub disconnect_handle
{
        my $call = "disconnect_". lc handle_to_driver( $_[0] );
        return unless defined &$call;
        goto &$call;
}

=head2 disconnect_handle_with_driver($handle, $driver)

Disconnects C<$handle> using driver C<$driver>.

=cut

sub disconnect_handle_with_driver
{
        my $call = "disconnect_". lc $_[1];
        return unless defined &$call;
        @_ = $_[0];
        goto &$call;
}

sub disconnect_sqlite
{
        my $handle = shift;
        $handle->disconnect;
        unlink $SQLITE_FILENAME;
}

sub disconnect_mysql
{
        my $handle = shift;
        $handle->disconnect;

        # XXX: is there something we should do here?
}

sub disconnect_pg
{
        my $handle = shift;
        $handle->disconnect;

        # XXX: is there something we should do here?
}

=head2 should_test $driver

Checks environment for C<JDBI_TEST_*> variables.
Returns true if specified DB back-end should be tested.
Takes one argument C<$driver> name.

=cut

sub should_test
{
        my $driver = shift;
        return 1 if lc $driver eq 'sqlite';
        my $env = 'JDBI_TEST_'. uc $driver;
        return $ENV{$env};
}

=head2 has_schema $class { $driver | $handle }

Returns method name if C<$class> has schema for C<$driver> or C<$handle>.
If second argument is handle object then checks also for DB version
specific schemas, for example for MySQL 4.1.23 this function will check
next methods in the C<$class>: C<schema_mysql_4_1_23>, C<schema_mysql_4_1>,
C<schema_mysql_4> and C<schema_mysql>, but if second argument is C<$driver>
name then checks only for C<schema_mysql>.

Returns empty value if couldn't find method.

=cut

sub has_schema
{
        my ($class, $driver) = @_;
        unless( UNIVERSAL::isa( $driver, 'Jifty::DBI::Handle' ) ) {
                my $method = 'schema_'. lc $driver;
                $method = '' unless UNIVERSAL::can( $class, $method );
                return $method;
        } else {
                my $ver = $driver->database_version;
                return has_schema( $class, handle_to_driver( $driver ) ) unless $ver;

                my $method = 'schema_'. lc handle_to_driver( $driver );
                $ver =~ s/-.*$//;
                my @nums = grep $_, map { int($_) } split /\./, $ver;
                while( @nums ) {
                        my $m = $method ."_". join '_', @nums;
                        return $m if( UNIVERSAL::can( $class, $m ) );
                        pop @nums;
                }
                return has_schema( $class, handle_to_driver( $driver ) );
        }
}

=head2 init_schema

Takes C<$class> and C<$handle> or C<$driver> and inits schema
by calling method C<has_schema> returns of the C<$class>.
Returns last C<DBI::st> on success or last return value of the
SimpleQuery method on error.

=cut

sub init_schema
{
        my ($class, $handle) = @_;
        my $call = has_schema( $class, $handle );
        diag( "using '$class\:\:$call' schema for ". handle_to_driver( $handle ) ) if $ENV{TEST_VERBOSE};
        my $schema = $class->$call();
        $schema = ref( $schema )? $schema : [$schema];
        my $ret;
        foreach my $query( @$schema ) {
                $ret = $handle->simple_query( $query );
                return $ret unless UNIVERSAL::isa( $ret, 'DBI::st' );
        }
        return $ret;
}

=head2 cleanup_schema

Takes C<$class> and C<$handle> and cleanup schema by calling
C<cleanup_schema_$driver> method of the C<$class> if method exists.
Always returns undef.

=cut

sub cleanup_schema
{
        my ($class, $handle) = @_;
        my $call = "cleanup_schema_". lc handle_to_driver( $handle );
        return unless UNIVERSAL::can( $class, $call );
        my $schema = $class->$call();
        $schema = ref( $schema )? $schema : [$schema];
        foreach my $query( @$schema ) {
                eval { $handle->simple_query( $query ) };
        }
}

=head2 init_data

Takes a class to get data from and the handle, calls C<init_data>
method in the class, result is used to create new records of that
class. First row is used for columns names.

Example:

    init_data('TestApp::User', $handle);

    ...

    package TestApp::User;
    sub init_data { return (
        ['name', 'email'],

        ['ruz', 'ruz@localhost'],
        ...
    ) }

=cut

sub init_data
{
        my ($class, $handle) = @_;
        my @data = $class->init_data();
        my @columns = @{ shift @data };
        my $count = 0;
        foreach my $values ( @data ) {
                my %args;
                for( my $i = 0; $i < @columns; $i++ ) {
                        $args{ $columns[$i] } = $values->[$i];
                }
                my $rec = $class->new( handle => $handle );
                my $id = $rec->create( %args );
                die "Couldn't create record" unless $id;
                $count++;
        }
        return $count;
}

=head2 drop_table_if_exists

Takes a table name and handle. Drops the table in the DB if it exists.
Returns nothing interesting, shouldn't die.

=cut

sub drop_table_if_exists {
    my ($table, $handle) = @_;
    my $d = handle_to_driver( $handle );
    if ( $d eq 'Pg' ) {
        my ($exists) = $handle->dbh->selectrow_array(
            "select 1 from pg_tables where tablename = ?", undef, $table
        );
        $handle->simple_query("DROP TABLE $table") if $exists;
    }
    else {
        local $@;
        eval { $handle->simple_query("DROP TABLE IF EXISTS $table") };
    }
    return;
}

1;
