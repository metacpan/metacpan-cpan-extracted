package Locale::MakePhrase::BackingStore::Database;
our $VERSION = 0.2;
our $DEBUG = 0;

=head1 NAME

Locale::MakePhrase::BackingStore::Database - Base-class for a
database driven backing store.

=head1 DESCRIPTION

This backing store is capable of loading language rules from a
database table, which conforms to the structure defined below.

It assumes that the database is configured to use unicode as the
text storage mechanism.

Unlike the file-based implementations, this module will hit the
database looking for language translations, every time the language
rules are requested.  This allows you to update the database (say
via a web interface), so that new translations are available
immediately.

=head1 TABLE STRUCTURE

The table structure can be created with the following SQL statement:

  CREATE TABLE some_table (
    key VARCHAR,
    language VARCHAR,
    expression VARCHAR,
    priority INTEGER,
    translation VARCHAR
  );

As you can see, there is not much to it.

Upon construction, this module will try to connect to the database
to confirm that the table exists and has a suitable structure.  If
it hasn't, this module will die.

=head1 API

The following methods are implemented:

=cut

use strict;
use warnings;
use utf8;
use Data::Dumper;
use DBI;
use base qw(Locale::MakePhrase::BackingStore);
use Locale::MakePhrase::Utils qw(die_from_caller);
our $default_host = 'localhost';
our $default_connect_options = {};
our $implicit_table_structure = "key,language,expression,priority,translation";
local $Data::Dumper::Indent = 1 if $DEBUG;

#--------------------------------------------------------------------------

=head2 $self new([...])

You will need to specify some of these options:

=over 2

=item C<table>

The name of the table that implements the table structure shown
above.  Note you can add more database fields if necessary; then by
overloading either C<get_query> or C<get_where>. you can make use of
the extra fields.

=item C<dbh>

You can supply a pre-connected L<DBI> handle, rather than supply the
connection parameters.

=item C<owned>

If you supply a database handle, you should specify whether you want
this module to take ownership of the handle.  If so, it will disconnect
the database handle on destruction.

=item C<driver>

The name of the DBI driver to use.

=item C<database>

The name of the database that we will connect to.

=item C<host>

=item C<port>

=item C<user>

=item C<password>

By specifying these four options (rather than the C<dbh>), this module
will connect to the database using these options.  Note that C<host>
and C<port> defaults to whatever the underlying driver uses, C<user>
and C<password> defaults to empty.

The defaults are used when you dont supply any connection parameters.

=item C<connect_options>

This option is simply a placeholder - it is up to the driver-specific
implementation to use this option.

=back

Notes: you must specify either the C<dbh> option, or suitable connection
options.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = bless {}, $class;

  # get options
  my %options;
  if (@_ > 1 and not(@_ % 2)) {
    %options = @_;
  } elsif (@_ == 1 and ref($_[0]) eq 'HASH') {
    %options = %{$_[0]};
  } elsif (@_ > 0) {
    die_from_caller("Invalid arguments passed to new()");
  }
  print STDERR "Arguments to ". ref($self) .": ". Dumper(\%options) if $DEBUG > 5;
  $self->{options} = \%options;

  # allow sub-class to control construction
  $self = $self->init();
  return undef unless $self;

  # connect to database
  my $dbh;
  if (exists $options{dbh} or exists $self->{dbh}) {
    # if user passed in a database handle, use it
    # check if we are meant to be the owner of id

    $dbh = (exists $options{dbh}) ? $options{dbh} : $self->{dbh};
    $self->{owned} = (exists $options{owned}) ? ($options{owned} ? 1 : 0) : (exists $self->{owned}) ? ($self->{owned} ? 1 : 0) : 0;

  } else {
    # otherwise, make a specific database handle.. and since we
    # constructed the database handle -> we definately need to destroy it

    $self->{driver} = (exists $options{driver}) ? $options{driver} : $self->{driver};
    $self->{database} = (exists $options{database}) ? $options{database} : $self->{database};
    $self->{host} = (exists $options{host}) ? $options{host} : (exists $self->{host}) ? $self->{host} : undef;
    $self->{port} = (exists $options{port}) ? $options{port} : (exists $self->{port}) ? $self->{port} : undef;
    $self->{user} = (exists $options{user}) ? $options{user} : (exists $self->{user}) ? $self->{user} : undef;
    $self->{password} = (exists $options{password}) ? $options{password} : (exists $self->{password}) ? $self->{password} : undef;
    $self->{connect_options} = (exists $options{connect_options}) ? $options{connect_options} : (exists $self->{connect_options}) ? $self->{connect_options} : $default_connect_options;

    die_from_caller("No 'database driver' specification") unless $self->{driver};
    die_from_caller("No 'database name' specification") unless $self->{database};

    $dbh = $self->_connect();
    $self->{owned} = 1;
  }

  # test database connection and the table structure
  die_from_caller("Database handle is not real?") unless (ref($dbh) and $dbh->can('ping') and $dbh->ping());
  $self->{table} = (exists $options{table}) ? $options{table} : $self->{table};
  die_from_caller("No 'datable table' specification") unless (defined $self->{table} and length $self->{table});
  $self->_test_table_structure($dbh);

  # all is good...
  $self->{dbh} = $dbh;
  return $self;
}

#--------------------------------------------------------------------------

=head2 $dbh dbh()

Returns the database connection handle

=cut

sub dbh { shift->{dbh} }

#--------------------------------------------------------------------------

=head2 void owned(boolean)

Set/get ownership of the database handle.

=cut

sub owned {
  my $self = shift;
  if (@_ > 0) {
    my $owned = shift;
    $self->{owned} = $owned ? 1 : 0;
  }
  return $self->{owned};
}

#--------------------------------------------------------------------------

=head2 \@rule_objs get_rules($contect,$key,\@languages)

Retrieve the translations from the database, using the selected languages.
The implementation will fetch the language rule properties each time
this is called, so that if the database gets updated, the next call will
use the new properties.

=cut

sub get_rules {
  my ($self,$context,$key,$languages) = @_;
  my $table = $self->{table};
  my $dbh = $self->{dbh};
  my @translations;

  # ensure connection is good...
  $dbh->ping() or $dbh = $self->_reconnect();

  # setup query
  my $qry = $self->get_query($table,$context,$languages);
  print STDERR "Using query: $qry\n" if $DEBUG > 4;
  my $sth = $dbh->prepare($qry);
  my $rv = $sth->execute($key);
  return undef unless (defined $rv and $rv > 0);
  my ($k,$language,$expression,$priority,$translation);
  $sth->bind_columns(\$k,\$language,\$expression,\$priority,\$translation);

  # make rules for each result
  while ($sth->fetch()) {
    push @translations, $self->make_rule(
      key => $key,
      language => $language,
      expression => $expression, 
      priority => $priority,
      translation => $translation
    );
  }

  print STDERR "Found translations:\n", Dumper(\@translations) if $DEBUG;
  return \@translations;
}

#--------------------------------------------------------------------------

=head2 $string get_query($table,$context,\@languages)

Under normal circumstances the generic SQL statement used by this module,
is suitable to be used to query the database.  However, in some cases you
may want to do something unusual...  By sub-classing this module, you can
create your own specific SQL statement.

=cut

sub get_query {
  my ($self,$table,$context,$languages) = @_;
  my $qry = join(' OR ', map("lower(language) = '$_'", @$languages) );
  $qry = "SELECT $implicit_table_structure FROM $table WHERE key = ? AND ($qry)";
  if ($context) {
    $qry .= " AND context = '$context'";
  } else {
    $qry .= " AND (context IS NULL OR context = '')";
  }
  my $custom = $self->get_where();
  $qry .= " AND $custom" if $custom;
  return $qry;
}

#--------------------------------------------------------------------------

=head2 $string get_where()

Under some circumstances the generic C<get_query()> command will generate
an SQL statement that is mostly correct, but needs minor adjustment.  By
overloading this method, you can _add to_ the existing SQL statement.

If you want to know what this does, you should probably read the source
code for this module.

=cut

sub get_where { "" }

#--------------------------------------------------------------------------
# The following methods are not part of the API - they are private.
#
# This means that everything above this code-break is allowed/designed
# to be overloaded.
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
#
# If this module created its own database handle (or the user wants
# this module to own the handle), we need to clean up on destruction
#
sub DESTROY {
  my $self = shift;
  if ($self->{owned} && $self->{dbh}) {
    $self->{dbh}->disconnect();
    delete $self->{dbh};
    delete $self->{owned};
  }
}

#--------------------------------------------------------------------------
#
# Connect to database using specified connection options
#
sub _connect {
  my ($self,$options) = @_;
  $options = $self unless $options;

  my $dsn = "dbi:".$options->{driver}.":dbname=". $options->{database} .";";
  $dsn .= "host=". $options->{host} .";" if $options->{host};
  $dsn .= "port=". $options->{port} .";" if $options->{port};
  my $user = $options->{user};
  my $password = $options->{password};
  my $connect_options = $options->{connect_options};

  # try connecting to database
  my $dbh;
  eval { $dbh = DBI->connect($dsn,$user,$password,$connect_options); };
  die_from_caller("Failed to connect to database:\n- dsn: $dsn\n- user: ". (defined $user ? $user : '') ."\n- password: ". (defined $password ? $password : '') ."\n- connect options: ". Dumper($connect_options) ."\nError info:\n$@\n") if ($@);

  if ($self != $options) {
    $self->{driver} = $options->{driver};
    $self->{database} = $options->{database};
    $self->{host} = $options->{host};
    $self->{port} = $options->{port};
    $self->{user} = $options->{user};
    $self->{connect_options} = $options->{connect_options};
    $self->{table} = $options->{table};
  }

  return $dbh;
}

#--------------------------------------------------------------------------
#
# Test the structure of the database table -> need to make sure that
# the table is capable of performing the table-lookups.
#
sub _test_table_structure {
  my ($self,$dbh) = @_;

  # make sure user specified table exists
  eval {
    my $qry = "SELECT 1 FROM ". $self->{table} ." LIMIT 1";
    my $sth = $dbh->prepare($qry);
    $sth->execute();
  };
  if ($@) {
    $dbh->disconnect() if ($self->{owned} and $dbh);
    die_from_caller("Table '". $self->{table} ."' doesn't exist");
  }

  # make sure user specified table has (at least) the minimum correct structure
  eval {
    my $qry = "SELECT $implicit_table_structure FROM ". $self->{table} ." LIMIT 1";
    my $sth = $dbh->prepare($qry);
    $sth->execute();
  };
  if ($@) {
    $dbh->disconnect() if ($self->{owned} and $dbh);
    die_from_caller("Table ". $self->{table} ." doesn't conform to implicit table structure: $implicit_table_structure");
  }
}

#--------------------------------------------------------------------------
#
# Sometimes the database will dissappear (possibly due to it re-starting...).
# As such, we need to reconnect to the database, as the current database handle
# is invalid.
#
sub _reconnect {
  my ($self) = @_;
  my $dbh = $self->{dbh};

  # Make sure that we own the database handle, and have enough information to reconnect
  die_from_caller("The database connection has failed for some reason... I cannot reconnect as I dont own the database handle...") unless $self->{owned};
  die_from_caller("The database connection has failed for some reason... I cannot reconnect as I dont have any database connection parameters") unless $self->{database};

  # cleanup handle
  $dbh->disconnect() if $dbh;
  $self->{dbh} = undef;

  # reconnect to database
  $dbh = $self->_connect();

  # test database table structure
  $self->_test_table_structure($dbh);

  # all is good...
  $self->{dbh} = $dbh;
  return $dbh;
}

1;
__END__
#--------------------------------------------------------------------------

=cut

