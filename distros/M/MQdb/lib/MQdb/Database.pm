# $Id: Database.pm,v 1.34 2009/05/30 01:57:14 severin Exp $
=pod
 
=head1 NAME - MQdb::Database
 
=head1 DESCRIPTION
 
Generalized handle on an DBI database handle. Used to provide
an instance which holds connection information and allows
a higher level get_connection/ disconnect logic that persists
above the specific DBI connections. Also provides a real object
for use with the rest of the toolkit.
 
=head1 SUMMARY

MQdb::Database provides the foundation of the MappedQuery system.  
Databases are primarily specified with a URL format.
The URL format includes specification of a driver so this single
method can select among the supported DBD drivers.  Currently the
system supports MYSQL, Oracle, and SQLite.
The URL also allows the system to provide the foundation for doing
federation of persisted objects.  Each DBObject contains a pointer
to the Database instance where it is stored.  With the database URL
and internal database ID, each object is defined in a global space.

Attributes of MQdb::Database
  driver   :  mysql, oracle, sqlite (default mysql)
  user     :  username if the database requires
  password :  password if the database requires
  host     :  hostname of the database server machine 
  port     :  IP port of the database if required 
              (mysql default is 3306)
  dbname   :  database/schema name on the database server
              for sqlite, this is the database file

Example URLS
  mysql://<user>:<pass>@<host>:<port>/<database_name>
  mysql://<host>:<port>/<database_name>
  mysql://<user>@<host>:<port>/<database_name>
  mysql://<host>/<database_name>
  oracle://<user>:<pass>@/<database_name>
  oracle://<user>:<pass>@<host>:<port>/<database_name>
  sqlite:///<database_file> 


=head1 CONTACT

Jessica Severin <jessica.severin@gmail.com>

=head1 LICENSE

 * Software License Agreement (BSD License)
 * MappedQueryDB [MQdb] toolkit
 * copyright (c) 2006-2009 Jessica Severin
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Jessica Severin nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

$VERSION=0.954;

package MQdb::Database;
use strict;
use DBI;
  
=head2 new

  Description: instance creation method
  Parameter  : a hash reference of options same as attribute methods
  Returntype : instance of this Class (subclass)
  Exceptions : none

=cut

=head2 new

  Description: instance creation method
  Returntype : instance of this Class (subclass)
  Exceptions : none

=cut

sub new {
  my ($class, @args) = @_;
  my $self = {};
  bless $self,$class;
  $self->init(@args);
  return $self;
}

=head2 init

  Description: initialization method which subclasses can extend
  Returntype : $self
  Exceptions : subclass dependent

=cut

sub init {
  my ($self, %params) = @_;
  
  $self->{'_uuid'}   = '';  #initially not set
  $self->{'_driver'} = 'mysql';
  $self->{'_host'}     = $params{'-host'};
  $self->{'_port'}     = $params{'-port'};
  $self->{'_user'}     = $params{'-user'};
  
  $self->{'_database'} = $params{'-database'} if(defined($params{'-database'}));
  $self->{'_database'} = $params{'-dbname'} if(defined($params{'-dbname'}));
  
  $self->{'_password'} = $params{'-pass'} if(defined($params{'-pass'}));
  $self->{'_password'} = $params{'-password'} if(defined($params{'-password'}));

  $self->{'_disconnect_count'} = 0;
  
  $self->_load_aliases;
  
  return $self;
}


=head2 new_from_url

  Description: primary instance creation method
  Parameter  : a string in URL format
  Returntype : instance of MQdb::Database
  Examples   : my $db = MQdb::Database->new_from_url("mysql://<user>:<pass>@<host>:<port>/<database_name>");
               e.g. mysql://<host>:<port>/<database_name>
               e.g. mysql://<user>@<host>:<port>/<database_name>
               e.g. mysql://<host>/<database_name>
               e.g. sqlite:///<database_file> 
  my $class = shift;
  Exceptions : none

=cut

sub new_from_url {
  #e.g. mysql://<user>:<pass>@<host>:<port>/<database_name>
  #e.g. mysql://<host>:<port>/<database_name>
  #e.g. mysql://<user>@<host>:<port>/<database_name>
  #e.g. mysql://<host>/<database_name>
  #e.g. sqlite:///<database_file> 
  my $class = shift;
  my $url = shift;
  my $pass = shift;

  my $self = {};
  bless $self, $class;

  return undef unless($url);
  
  $self->_load_aliases;
  
  my $driver = 'mysql';
  my $user = '';
  my $host = '';
  my $port = 3306;
  my $dbname = undef;
  my $path = '';
  my $discon = 0;
  my $species;
  my $type;
  my ($p, $p2, $p3);

  #print("FETCH $url\n");

  $p = index($url, "://");
  return undef if($p == -1);
  $driver = substr($url, 0, $p);
  $url    = substr($url, $p+3, length($url));

  #print ("db_url=$url\n");
  $p = index($url, "/");
  return undef if($p == -1);

  my $conn   = substr($url, 0, $p);
  $dbname    = substr($url, $p+1, length($url));
  my $params = undef;
  if(($p2=index($dbname, ";")) != -1) {
    $params = substr($dbname, $p2+1, length($dbname));
    $dbname = substr($dbname, 0, $p2);
  }
  if((($driver eq 'mysql') or ($driver eq 'oracle')) and ($p2=index($dbname, "/")) != -1) {
    $path   = substr($dbname, $p2+1, length($dbname));
    $dbname = substr($dbname, 0, $p2);
  }
  while($params) {
    my $token = $params;
    if(($p2=rindex($params, ";")) != -1) {
      $token  = substr($params, 0, $p2);
      $params = substr($params, $p2+1, length($params));
    } else { $params= undef; }
    if($token =~ /type=(.*)/) {
      $type = $1;
    }
    if($token =~ /discon=(.*)/) {
      $discon = $1;
    }
    if($token =~ /species=(.*)/) {
      $species = $1;
    }
  }
  $species=$host . "_" . $dbname unless(defined($species));

  #print("  conn=$conn\n  dbname=$dbname\n  path=$path\n");

  my($hostPort, $userPass);
  if(($p=index($conn, "@")) != -1) {
    $userPass = substr($conn,0, $p);
    $hostPort = substr($conn,$p+1,length($conn));

    if(($p2 = index($userPass, ':')) != -1) {
      $user = substr($userPass, 0, $p2);
      unless(defined($pass)) {
        $pass = substr($userPass, $p2+1, length($userPass));
      }
    } elsif(defined($userPass)) { $user = $userPass; }
  }
  else {
    $hostPort = $conn;
  }
  if(($p3 = index($hostPort, ':')) != -1) {
    $port = substr($hostPort, $p3+1, length($hostPort)) ;
    $host = substr($hostPort, 0, $p3);
  } else { $host=$hostPort; }

  #return undef unless($host and $dbname);
    
  unless(defined($pass)) { $pass = ''; }

  ($host,$port) = $self->_check_alias($host,$port);

  $self->{'_uuid'}     = ''; 
  $self->{'_driver'}   = $driver;
  $self->{'_host'}     = $host;
  $self->{'_port'}     = $port;
  $self->{'_database'} = $dbname;
  $self->{'_user'}     = $user;
  $self->{'_password'} = $pass;

  my $full_url = $self->full_url;
  
  return $self;
}

=head2 copy

  Description: makes a copy of the database configuration.
               New instance will have its own database connection 
  Returntype : instance of MQdb::Database

=cut

sub copy {
  my $self = shift;
  my $class = ref($self);
  my $copy = $class->new;
  
  $self->{'_uuid'}     = $self->uuid;
  $self->{'_driver'}   = $self->driver;
  $self->{'_host'}     = $self->host;
  $self->{'_port'}     = $self->port;
  $self->{'_user'}     = $self->user;
  $self->{'_password'} = $self->password;
  $self->{'_database'} = $self->dbname;

  return $copy;
}


=head2 dbc

  Description: connects to database and returns a DBI connection
  Returntype : DBI database handle
  Exceptions : none

=cut

sub dbc {
  my $self = shift;
  return $self->get_connection;
}

sub get_connection {
  my($self) = @_;

  my $dbc = $self->{"DB_CONNECTION"};

  if(defined($dbc)) {
    if($dbc->ping()) {
      return $dbc;
    } else {
      print STDERR "Failed Ping....\n";
      $dbc->disconnect();
    }
  }

  my $driver = $self->{'_driver'};
  my $host = $self->{'_host'};
  my $port = $self->{'_port'};
  my $database = $self->{'_database'};
  my $user = $self->{'_user'};
  my $password = $self->{'_password'};
  
  if($driver eq 'mysql') {
    my $dsn = "DBI:mysql:database=$database;host=$host;port=$port";
    $dbc = DBI->connect($dsn, $user, $password, {RaiseError=>1, AutoCommit=>1});
  }
  if($driver eq 'oracle') {
    my $dsn = "DBI:Oracle:" . $self->{'_database'};
    $dbc = DBI->connect($dsn, $user, $password, {RaiseError=>1, AutoCommit=>1});
  }
  if($driver eq 'sqlite') {
    my $dsn = "DBI:SQLite:dbname=/$database";
    $dbc = DBI->connect($dsn, $user, $password);
  }
  
  $self->{"DB_CONNECTION"} = $dbc;

  return $dbc
}


=head2 disconnect

  Description: disconnects handle from database, but retains object and 
               all information so that it can be reconnected again 
               at a later time.
  Returntype : none
  Exceptions : none

=cut

sub disconnect {
  my $self = shift;
  return unless($self->{'DB_CONNECTION'});
  
  my $dbc = $self->{'DB_CONNECTION'};
  if($dbc->{ActiveKids} != 0) {
     warn("Problem disconnect : kids=",$dbc->{Kids},
            " activekids=",$dbc->{ActiveKids},"\n");
     return 1;
  }
  $dbc->disconnect();
  $self->{'_disconnect_count'}++;
  $self->{'DB_CONNECTION'} = undef;
  #print("DISCONNECT\n");
  
  return $self;
}


sub DESTROY {
  my $self  = shift;
  #$self->disconnect();
}

#############################################
# attribute access methods (no setting)
#############################################

sub uuid {
  my $self = shift;
  return $self->{'_uuid'} = shift if(@_);
  return $self->{'_uuid'};
}

sub driver { return shift->{'_driver'}; }
sub host { return shift->{'_host'}; }
sub port { my $self=shift; return $self->{'_port'}; }
sub user { my $self=shift; return $self->{'_user'}; }
sub password { my $self=shift; return $self->{'_password'}; }
sub dbname { my $self=shift; return $self->{'_database'}; }
sub disconnect_count { my $self=shift; return $self->{'_disconnect_count'}; }

=head2 full_url

  Description: returns the URL of this database with user and password
  Returntype : string
  Exceptions : none

=cut

sub full_url {
  my $self = shift;
  my $full_url = sprintf("%s://%s:%s@%s:%s/%s", 
               $self->driver, 
               $self->user, 
               $self->password, 
               $self->host, 
               $self->port, 
               $self->dbname);
  #printf("  full_url : %s\n", $full_url);
  return $full_url;
}

=head2 url

  Description: returns URL of this database but without user:password
               used for global referencing and federation systems
  Returntype : string
  Exceptions : none

=cut

sub url {
  #no username or password in URL
  my $self = shift;
  return $self->{'_short_url'} if(defined($self->{'_short_url'}));
  my $url = $self->driver . "://";
  if($self->host) {
    if($self->port) { $url .= $self->host .":". $self->port; }
    else { $url .= $self->host; }
  }
  $url .= "/". $self->dbname;
  $self->{'_short_url'} = $url;
  return $self->{'_short_url'};
}

=head2 xml

  Description: returns XML of this database but without user:password
               used for global referencing and federation systems
  Returntype : string
  Exceptions : none

=cut

sub xml {
  #no username or password in URL
  my $self = shift;
  my $xml = sprintf("<database name=\"%s\" url=\"%s\" ", 
               $self->alias,
               $self->url);
  if($self->uuid) { $xml .= sprintf("uuid=\"%s\" ", $self->uuid); }
  $xml .= "/>";             
  return $xml;
}

sub alias {
  my $self = shift;
  $self->{'alias'} = shift if(@_);
  $self->{'alias'} = $self->dbname unless(defined($self->{'alias'}));
  return $self->{'alias'};
}

####################################################
#
# URL related methods
#
####################################################

sub _load_aliases {
  my $self = shift;

  $self->{'_aliases'} = {};
  return unless(defined($ENV{'HOME'}));
  
  my $alias_file = $ENV{'HOME'} . "/.mqdb_url_aliases";
  return unless(-e $alias_file);
  #print("found ALIAS file $alias_file\n");
  
  open (ALIASFP,$alias_file) || return;
  while(<ALIASFP>) {
    chomp;
    my($from, $to) = split(/\s+/);
    $self->{'_aliases'}->{$from} = $to;
  }
  close(ALIASFP);
}


sub _check_alias {
  my $self = shift;
  my $host = shift;
  my $port = shift;

  my $key = "$host:$port";
  my $alias = $self->{'_aliases'}->{$key};
  return ($host,$port) unless($alias);
  
  ($host,$port) = split(/:/, $alias);
  #print("translate alias $key into $host : $port\n");
  return ($host,$port);
}

#################################################
# high level wrappers for direct queries
#################################################

=head2 execute_sql

  Description    : executes SQL statement with external parameters and placeholders
  Example        : $db->execute_sql("insert into table1(id, value) values(?,?)", $id, $value);
  Parameter[1]   : sql statement string
  Parameter[2..] : optional parameters for the SQL statement
  Returntype     : none
  Exceptions     : none

=cut

sub execute_sql {
  my $self = shift;
  my $sql = shift;
  my @params = @_;
  
  if($self->driver eq 'sqlite') {
    $sql =~ s/INSERT ignore/INSERT or ignore/g;
  }
  my $dbc = $self->get_connection;  
  my $sth = $dbc->prepare($sql);
  eval { $sth->execute(@params); };
  if($@) {
    printf(STDERR "ERROR with query: %s\n", $sql);
    printf(STDERR "          params: ");
    foreach my $param (@params) { print(STDERR "'%s'  ", $param); }
    print(STDERR "\n");
  }
  $sth->finish;
}


=head2 do_sql

  Description    : executes SQL statement with "do" and no external parameters
  Example        : $db->do_sql("insert into table1(id, value) values(null,'hello world');");
  Parameter      : sql statement string with no external parameters
  Returntype     : none
  Exceptions     : none

=cut

sub do_sql {
  my $self = shift;
  my $sql = shift;
  
  if($self->driver eq 'sqlite') {
    $sql =~ s/INSERT ignore/INSERT or ignore/g;
    if(uc($sql) =~ /^UNLOCK TABLES/) { $sql = "END TRANSACTION;"; }
    if(uc($sql) =~ /^LOCK TABLE/) { $sql = "BEGIN TRANSACTION;"; }
    
  }
  my $dbc = $self->get_connection;  
  if(!($dbc->do($sql))) {
    printf(STDERR "WARNING with query: %s\n", $sql);
    #die;
  }
}

=head2 fetch_col_value

  Arg (1)    : $sql (string of SQL statement with place holders)
  Arg (2...) : optional parameters to map to the placehodlers within the SQL
  Example    : $value = $self->fetch_col_value($db, "select some_column from my_table where id=?", $id);
  Description: General purpose function to allow fetching of a single column from a single row.
  Returntype : scalar value
  Exceptions : none
  Caller     : within subclasses to easy development

=cut

sub fetch_col_value {
  my $self = shift;
  my $sql = shift;
  my @params = @_;

  my $dbc = $self->get_connection;
  my $sth = $dbc->prepare($sql);
  $sth->execute(@params);
  my ($value) = $sth->fetchrow_array();
  $sth->finish;
  return $value;
}

 
1;
