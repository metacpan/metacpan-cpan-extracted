package Labyrinth::DBUtils;

use warnings;
use strict;

use vars qw($VERSION $AUTOLOAD);
$VERSION = '5.32';

=head1 NAME

Labyrinth::DBUtils - Database Manager for Labyrinth

=head1 SYNOPSIS

  use Labyrinth::DBUtils;

  my $dbi = Labyrinth::DBUtils->new({
                driver => 'CSV',
                file => '/var/www/mysite/db');
  sub errors { print STDERR "Error: $_[0], sql=$_[1]\n" }

  my @arr = $dbi->GetQuery('array','getTables');
  my @arr = $dbi->GetQuery('array','getTable',$bid);
  my @arr = $dbi->GetQuery('hash','getOneRow',
                {table=>'uds_build',field=>'bid'},$bid});

  my $id = $dbi->IDQuery('insertRow',$id,$name);
  $dbi->DoQuery('deleteRow',$id);
  $dbi->DoQuery('updateRow',{id=>$id,name=>$name});

  my $next = Iterator('array','getTables');
  my $row = $next->(); # returns an array ref

  my $next = Iterator('hash','getTables');
  my $row = $next->(); # returns a hash ref

  $value = $dbi->Quote($value);

=head1 DESCRIPTION

The DBUtils package is a further database interface layer, providing a
collection of control methods to initiate the database connection, handle
errors and a smooth handover from the program to the database drivers.

Reads and handles the SQL from the phrasebook, passing the statement and any
additional parameters through to the DBI onject.

=cut

# -------------------------------------
# Library Modules

use DBI;
#use DBD::mysql;

use Labyrinth::Audit;
use Labyrinth::Phrasebook;
use Labyrinth::Writer;

# -------------------------------------
# Variables

my %autosubs = map {$_ => 1} qw( driver database file host port user password );

# -------------------------------------
# The Public Interface Subs

=head2 CONSTRUCTOR

=over 4

=item new DBUtils({})

The Constructor method. Can be called with an anonymous hash,
listing the values to be used to connect to and handle the database.

Values in the hash can be

  logfile
  phrasebook (*)
  dictionary
  driver (*)
  database (+)
  dbfile (+)
  dbhost
  dbport
  dbuser
  dbpass
  autocommit

(*) These entries MUST exist in the hash.
(+) At least ONE of these must exist in the hash, and depend upon the driver.

Note that 'file' is for use with a flat file database, such as DBD::CSV.

=back

=cut

sub new {
    my ($self, $hash) = @_;
    my ($log,$pb) = (undef,undef);          # in case a log is not required

    my $logfile = $hash->{logfile};                     # mandatory
    my $phrasebook = $hash->{phrasebook};               # mandatory
    my $dictionary = $hash->{dictionary} || 'PROCS';    # optional

    # check we've got our mandatory fields
    Croak("$self needs a driver!")      unless($hash->{driver});
    Croak("$self needs a database/file!")
            unless($hash->{database} || $hash->{file});
    Croak("$self needs a phrasebook!")  unless($phrasebook);

    # check files exist and we can access them correctly
    Croak("$self cannot access phrasebook [$phrasebook]!")
            unless($phrasebook && -r $phrasebook);


    # initiate the phrasebook
    $pb = Labyrinth::Phrasebook->new($phrasebook);
    $pb->load($dictionary);

    # create an attributes hash
    my $dbv = {
        'driver'        => $hash->{driver},
        'database'      => $hash->{database},
        'file'          => $hash->{dbfile},
        'host'          => $hash->{dbhost},
        'port'          => $hash->{dbport},
        'user'          => $hash->{dbuser},
        'password'      => $hash->{dbpass},
        'log'           => $log,
        'pb'            => $pb,
    };

    $dbv->{autocommit} = $hash->{autocommit}    if(defined $hash->{autocommit});

    # create the object
    bless $dbv, $self;
    return $dbv;
}

=head2 PUBLIC INTERFACE METHODS

=over 4

=item GetQuery(type,key,<list>)

  type - 'array' or 'hash'
  key - hash key to sql in phrasebook
  <list> - optional additional values to be inserted into SQL placeholders

The function performs a SELECT statement, which returns either a list of lists,
or a list of hashes. The difference being that for each record, the field
values are listed in the order they are returned, or via the table column
name in a hash.

The first entry in <list> can be an anonymous hash, containing the placeholder
values to be interpolated by Class::Phrasebook.

Note that if the key is not found in the phrasebook, the function returns
with undef.

=cut

sub GetQuery {
    my ($dbv,$type,$key,@args) = @_;
    my ($hash,$sql);

    # retrieve the sql from the phrasebook,
    # inserting placeholders (if required)
    $hash = shift @args  if(ref($args[0]) eq "HASH");
    eval { $sql = $dbv->{pb}->get($key,$hash); };
    
    LogDebug("key=[$key], sql=[$sql], args[".join(",",map{$_ || ''} @args)."], err=$@");
    return ()   unless($sql);

    # if the object doesnt contain a reference to a dbh object
    # then we need to connect to the database
    $dbv = &_db_connect($dbv) if not $dbv->{dbh};

    # prepare the sql statement for executing
    my $sth = $dbv->{dbh}->prepare($sql);
    unless($sth) {
        LogError("err=".$dbv->{dbh}->errstr.", key=[$key], sql=[$sql], args[".join(",",map{$_ || ''} @args)."]");
        return ();
    }

    # execute the SQL using any values sent to the function
    # to be placed in the sql
    if(!$sth->execute(@args)) {
        LogError("err=".$sth->errstr.", key=[$key], sql=[$sql], args[".join(",",map{$_ || ''} @args)."]");
        return ();
    }

    my @result;
    # grab the data in the right way
    if ( $type eq 'array' ) {
        while ( my $row = $sth->fetchrow_arrayref() ) {
            push @result, [@{$row}];
        }
    } else {
        while ( my $row = $sth->fetchrow_hashref() ) {
            push @result, $row;
        }
    }

    # finish with our statement handle
    $sth->finish;
    # return the found datastructure
    return @result;
}

=item Iterator(type,key,<list>)

  type - 'array' or 'hash'
  key - hash key to sql in phrasebook
  <list> - optional additional values to be inserted into SQL placeholders

The function performs a SELECT statement, which returns a subroutine reference
which can then be used to obtain either a list of lists, or a list of hashes.
The difference being that for each record, the field values are listed in the
order they are returned, or via the table column name in a hash.

The first entry in <list> can be an anonymous hash, containing the placeholder
values to be interpolated by Class::Phrasebook.

Note that if the key is not found in the phrasebook, the function returns
with undef.

=cut

sub Iterator {
    my ($dbv,$type,$key,@args) = @_;
    my ($hash,$sql);

    # retrieve the sql from the phrasebook,
    # inserting placeholders (if required)
    $hash = shift @args  if(ref($args[0]) eq "HASH");
    eval { $sql = $dbv->{pb}->get($key,$hash); };

    LogDebug("key=[$key], sql=[$sql], args[".join(",",map{$_ || ''} @args)."], err=$@");
    return  unless($sql);

    # if the object doesnt contain a reference to a dbh object
    # then we need to connect to the database
    $dbv = &_db_connect($dbv) if not $dbv->{dbh};

    # prepare the sql statement for executing
    my $sth = $dbv->{dbh}->prepare($sql);
    unless($sth) {
        LogError("err=".$dbv->{dbh}->errstr.", sql=[$sql], args[".join(",",map{$_ || ''} @args)."]");
        return;
    }

    # execute the SQL using any values sent to the function
    # to be placed in the sql
    if(!$sth->execute(@args)) {
        LogError("err=".$sth->errstr.", sql=[$sql], args[".join(",",map{$_ || ''} @args)."]");
        return;
    }

    # grab the data in the right way
    if ( $type eq 'array' ) {
        return sub {
            if ( my $row = $sth->fetchrow_arrayref() ) { return $row; }
            else { $sth->finish; return; }
        }
    } else {
        return sub {
            if ( my $row = $sth->fetchrow_hashref() ) { return $row; }
            else { $sth->finish; return; }
        }
    }
}

=item DoQuery(key,<list>)

  key - hash key to sql in phrasebook
  <list> - optional additional values to be inserted into SQL placeholders

The function performs an SQL statement. If performing an INSERT statement that
returns an record id, this is returned to the calling function.

The first entry in <list> can be an anonymous hash, containing the placeholder
values to be interpolated by Class::Phrasebook.

Note that if the key is not found in the phrasebook, the function returns
with undef.

=cut

sub DoQuery {
    my ($dbv,$key,@args) = @_;
    my ($hash,$sql);

    # retrieve the sql from the phrasebook,
    # inserting placeholders (if required)
    $hash = shift @args  if(ref($args[0]) eq "HASH");
    eval { $sql = $dbv->{pb}->get($key,$hash); };

    LogDebug("key=[$key], sql=[$sql], args[".join(",",map{$_ || ''} @args)."], err=$@");
    return  unless($sql);

    $dbv->_doQuery($sql,0,@args);
}

=item IDQuery(key,<list>)

  key - hash key to sql in phrasebook
  <list> - optional additional values to be inserted into SQL placeholders

The function performs an SQL statement. If performing an INSERT statement that
returns an record id, this is returned to the calling function.

The first entry in <list> can be an anonymous hash, containing the placeholder
values to be interpolated by Class::Phrasebook.

Note that if the key is not found in the phrasebook, the function returns
with undef.

=cut

sub IDQuery {
    my ($dbv,$key,@args) = @_;
    my ($hash,$sql);

    # retrieve the sql from the phrasebook,
    # inserting placeholders (if required)
    $hash = shift @args  if(ref($args[0]) eq "HASH");
    eval { $sql = $dbv->{pb}->get($key,$hash); };

    LogDebug("key=[$key], sql=[$sql], args[".join(",",map{$_ || ''} @args)."], err=$@");
    return  unless($sql);

    return $dbv->_doQuery($sql,1,@args);
}

=item DoSQL(sql,<list>)

  sql - SQL statement
  <list> - optional additional values to be inserted into SQL placeholders

=cut

sub DoSQL {
    my ($dbv,$sql,@args) = @_;
    return  unless($sql);

    $dbv->_doQuery($sql,0,@args);
}

# _doQuery(key,idrequired,<list>)
#
#  key - hash key to sql in phrasebook
#  idrequired - true if an ID value is required on return
#  <list> - optional additional values to be inserted into SQL placeholders
#
#The function performs an SQL statement. If performing an INSERT statement that
#returns an record id, this is returned to the calling function.
#
#The first entry in <list> can be an anonymous hash, containing the placeholder
#values to be interpolated by Class::Phrasebook.
#
#Note that if the key is not found in the phrasebook, the function returns
#with undef.
#

sub _doQuery {
    my ($dbv,$sql,$idrequired,@args) = @_;
    my $rowid = undef;

    LogDebug("sql=[$sql], args[".join(",",map{$_ || ''} @args)."]");
    return $rowid   unless($sql);

    # if the object doesnt contain a refrence to a dbh object
    # then we need to connect to the database
    $dbv = &_db_connect($dbv) if not $dbv->{dbh};

    if($idrequired) {
        # prepare the sql statement for executing
        my $sth = $dbv->{dbh}->prepare($sql);
        unless($sth) {
            LogError("err=".$dbv->{dbh}->errstr.", sql=[$sql], args[".join(",",map{$_ || ''} @args)."]");
            return;
        }

        # execute the SQL using any values sent to the function
        # to be placed in the sql
        if(!$sth->execute(@args)) {
            LogError("err=".$sth->errstr.", sql=[$sql], args[".join(",",map{$_ || ''} @args)."]");
            return;
        }

        if($dbv->{driver} =~ /mysql/i) {
            $rowid = $dbv->{dbh}->{mysql_insertid};
        } else {
            my $row;
            $rowid = $row->[0]  if( $row = $sth->fetchrow_arrayref() );
        }

    } else {
        eval { $rowid = $dbv->{dbh}->do($sql, undef, @args) };
        if ( $@ ) {
            LogError("err=".$dbv->{dbh}->errstr.", sql=[$sql], args[".join(",",map{$_ || ''} @args)."]");
            return -1;
        }

        $rowid ||= 1;     # technically this should be the number of succesful rows
    }


    ## Return the rowid we just used
    return $rowid;
}

=item Quote(string)

  string - string to be quoted

The function performs a DBI quote operation, which will quote a string
according to the SQL rules.

=cut

sub Quote {
    my $dbv  = shift;
    return  unless($_[0]);

    # Cant quote with DBD::CSV
    return $_[0]    if($dbv->{driver} =~ /csv/i);

    # if the object doesnt contain a refrence to a dbh object
    # then we need to connect to the database
    $dbv = &_db_connect($dbv) if not $dbv->{dbh};

    $dbv->{dbh}->quote($_[0]);
}

# -------------------------------------
# The Get & Set Methods Interface Subs

=item Get & Set Methods

The following accessor methods are available:

  driver
  database
  file
  host
  port
  user
  password

All functions can be called to return the current value of the associated
object variable, or be called with a parameter to set a new value for the
object variable.

(*) Setting these methods will take action immediately. All other access
methods require a new object to be created, before they can be used.

Examples:

  my $database = db_database();
  db_database('another');

=cut

sub AUTOLOAD {
    no strict 'refs';
    my $name = $AUTOLOAD;
    $name =~ s/^.*:://;
    die "Unknown sub $AUTOLOAD\n"   unless($autosubs{$name});

    *$name = sub { my $dbv=shift; @_ ? $dbv->{$name}=shift : $dbv->{$name} };
    goto &$name;
}

# -------------------------------------
# The Private Subs
# These modules should not have to be called from outside this module

sub _db_connect {
    my $dbv  = shift;

    my $dsn =   'dbi:' . $dbv->{driver};
    my $ac  = defined $dbv->{autocommit} ? $dbv->{autocommit} : 1;

    if($dbv->{driver} =~ /ODBC/) {
        # all the info is in the Data Source repository

    } elsif($dbv->{driver} =~ /SQLite/) {
        $dsn .= ':dbname='  . $dbv->{database}  if $dbv->{database};
        $dsn .= ';host='    . $dbv->{host}      if $dbv->{host};
        $dsn .= ';port='    . $dbv->{port}      if $dbv->{port};

    } else {
        $dsn .= ':f_dir='   . $dbv->{file}      if $dbv->{file};
        $dsn .= ':database='. $dbv->{database}  if $dbv->{database};
        $dsn .= ';host='    . $dbv->{host}      if $dbv->{host};
        $dsn .= ';port='    . $dbv->{port}      if $dbv->{port};
    }

#   LogDebug("dsn=[$dsn] user[$dbv->{user}] password[$dbv->{password}]" );

    eval {
        $dbv->{dbh} = DBI->connect($dsn, $dbv->{user}, $dbv->{password},
                                { RaiseError => 1, AutoCommit => $ac });
    };

    Croak("Cannot connect to DB [$dsn]: $@")    if($@);
    return $dbv;
}

sub DESTROY {
    my $dbv = shift;
#   $dbv->{dbh}->commit     if defined $dbv->{dbh};
    $dbv->{dbh}->disconnect if defined $dbv->{dbh};
}

1;

__END__

=back

=head1 SEE ALSO

  DBI,
  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
