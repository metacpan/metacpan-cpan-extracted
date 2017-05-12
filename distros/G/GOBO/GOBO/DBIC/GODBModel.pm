=head1 GOBO::DBIC::GODBModel

This is the core GOBO::DBIC::GODBModel class. It is responsible for environment
and getting in all of the install-time DB meta data. Most other tasks
should be left to subclasses.

Testing for now:
perl -I /home/sjcarbon/local/src/svn/geneontology/go-moose t/connect.t

=cut

package GOBO::DBIC::GODBModel;

##
BEGIN {
  ##
}


## Bring in necessaries.
use utf8;
use strict;
use Data::Dumper;


=item new

Constr.

Takes a hashref like:

{ socket => 'foo'
  database => 'go_latest',
  host => 'localhost',
  port => '1234',
  user => 'foo',
  auth => 'bar' }

And/or check the environment for the similar variables (socket ->
GO_DBSOCKET, etc.)

Returns an array for connecting to the database for use with DBIx::Class.

NOTE: MySQL only.

=cut
sub new {

  ##
  my $class = shift;
  my $self = {};

  my $args = shift || {};

  ## Logging verbosity.
  $self->{VERBOSE} = 0;

  ## Complete the arg set with the environment if possible.
  my @envs = ('socket', 'name', 'host', 'port', 'user', 'auth');
  foreach my $env (@envs){
    if( defined $args->{$env} ){
      ## Incoming arg is preferable.
    }elsif( my $var = $ENV{'GO_DB' . uc($env)} ){
      $args->{$env} = $var;
    }else{
      ## Make it logically false otherwise.
      $args->{$env} = '';
    }
    #print STDERR "GOBO::DBIC::GODBModel::db_conestor::$env: ".$env.' is '.$args->{$env} . "\n";
  }

  ## Create the data necessary for the MySQL connection.
  my @mbuf = ();
  if( my $var = $args->{socket} ){ push @mbuf, 'mysql_socket=' . $var; }
  if( my $var = $args->{name} ){ push @mbuf, 'database=' . $var; }
  if( my $var = $args->{host} ){ push @mbuf, 'host=' . $var; }
  if( my $var = $args->{port} ){ push @mbuf, 'port=' . $var; }
  my $dsn ='dbi:mysql:' . join(';', @mbuf);

  #print STDERR "GOBO::DBIC::GODBModel::db_conestor::dsn: " . $dsn . "\n";

  ##
  my $retref = [];
  push @$retref, $dsn;

  ## Credentials after connection dsn--add them to the return.
  # $ENV{GO_DBPASS};
  push @$retref, $args->{user};
  push @$retref, $args->{auth};

  $self->{CONNECT_INFO} = $retref;
  $self->{SCHEMA} =
    GOBO::DBIC::GODBModel::Schema->connect(@{$self->{CONNECT_INFO}});

  bless $self, $class;
  return $self;
}


=item connection_info

Arguments: n/a
Returns: array ref for DBIC Schema connection.

=cut
sub connection_info {

  my $self = shift;
  return @{$self->{CONNECT_INFO}};
}


=item pull_env

Gets an environmental variable; tries lowercase, then uppercase.

Arguments: name string
Returns: value string

=cut
sub pull_env {

  my $self = shift;
  my $var = shift || undef;

  ## Default return value.
  my $retval = undef;

  ## Good arg?
  if ( defined $var && $var ){

    ## Is there something out there?
    my $almost_val = '';
    if( defined($ENV{$var}) ){
      $almost_val = $ENV{$var};
    }elsif( defined($ENV{uc($var)}) ){
      $almost_val = $ENV{uc($var)};
    }

    ## And id it non-empty?
    if( length($almost_val) ){
      $retval = $almost_val;
    }
  }

  return $retval;
}


=item verbose

Get/set verbose with 1 or 0.

Return 1 or 0;

=cut
sub verbose {

  my $self = shift;
  my $arg = shift;

  if( defined $arg ){
    if( $arg == 0 || $arg == 1 ){
      $self->{VERBOSE} = $arg;
    }
  }

  return $self->{VERBOSE};
}


=item kvetch

Prints a message to STDERR if VERBOSE is set.

Arguments: message string
Returns: t if message written, nil otherwise.

=cut
sub kvetch {

  my $self = shift;
  my $message = shift || '';

  if( $self->verbose() ){
    print STDERR "$message\n";
  }

  return $message;
}



1;
