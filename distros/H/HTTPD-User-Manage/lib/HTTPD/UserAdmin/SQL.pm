# $Id: SQL.pm,v 1.3 2007/01/23 16:18:56 lstein Exp $
package HTTPD::UserAdmin::SQL;
use DBI;
use Carp ();
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(HTTPD::UserAdmin);
$VERSION = (qw$Revision: 1.3 $)[1];

my %Default = (HOST => "",                  #server hostname
	       DB => "",                    #database name
	       USER => "", 	            #database login name	    
	       AUTH => "",                  #database login password
	       DRIVER => "mSQL",            #driver for DBI
	       USERTABLE => "",             #table with field names below
	       NAMEFIELD => "user",         #field for the name
	       PASSWORDFIELD => "password", #field for the password
	       );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ } => $class;
    $self->_check(qw(DRIVER DB USERTABLE)); 
    $self->db($self->{DB});	
    return $self;
}

sub DESTROY {
    my($self) = @_;
    $self->{'_DBH'}->disconnect;
}

sub db {
    my($self,$db) = @_;
    my $old = $self->{DB};
    return $old unless $db;
    $self->{DB} = $db; 

    if(defined $self->{'_DBH'}) {
	$self->{'_DBH'}->disconnect;
    }

    # LS 12/1/97 -- Be sure to use Msql-modules-1.1814 (at least).
    # Do NOT  use the older DBD-mSQL-0.65.
    # The connect() method changed.

    my $source = sprintf("dbi:%s:%s",@{$self}{qw(DRIVER DB)});
    $source .= ":$self->{HOST}" if $self->{HOST};
    $source .= ":$self->{PORT}" if $self->{HOST} and $self->{PORT};
    $self->{'_DBH'} = DBI->connect($source,@{$self}{qw(USER AUTH)} ) 
	|| Carp::croak($DBI::errstr);

    return $old;
}

package HTTPD::UserAdmin::SQL::_generic;
use vars qw(@ISA);
@ISA = qw(HTTPD::UserAdmin::SQL);

sub add {
    my($self, $username, $passwd, $other) = @_;
    return(0, "add_user: no user name!") unless $username;
    return(0, "add_user: no password!") unless $passwd;
    return(0, "user '$username' already exists!") 
	if $self->exists($username);

    my(%f) = ($self->{NAMEFIELD}=>$username,
	      $self->{PASSWORDFIELD}=>$self->encrypt($passwd));
    if ($other) {
	Carp::croak('Specify other fields as a hash ref for SQL databases')
	    unless ref($other) eq 'HASH';
	  foreach (keys %{$other}) {
	      $f{$_} = $other->{$_};
	  }
    }
    my $statement = 
	sprintf("INSERT into %s (%s)\n VALUES (%s)\n",
		$self->{USERTABLE},
		join(',',keys %f),
		join(',', map {$self->_is_string($_,$f{$_}) ? "'$f{$_}'" : $f{$_} } keys %f));

    print STDERR $statement if $self->debug;
    $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
    1;
}

sub exists {
    my($self, $username) = @_;
    my $statement = 
	sprintf("SELECT %s from %s WHERE %s='%s'\n",
		@{$self}{qw(PASSWORDFIELD USERTABLE NAMEFIELD)}, $username);
    print STDERR $statement if $self->debug;
    my $sth = $self->{'_DBH'}->prepare($statement);
    Carp::carp("Cannot prepare sth ($DBI::err): $DBI::errstr")
	unless $sth;
    $sth->execute || Carp::croak($DBI::errstr);
    my(@row) = $sth->fetchrow;
    $sth->finish;
    return $row[0];
}

sub delete {
    my($self, $username) = @_;
    my $statement = 
	sprintf("DELETE from %s where %s='%s'\n",
		@{$self}{qw(USERTABLE NAMEFIELD)}, $username);
    print STDERR $statement if $self->debug;
    $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
}

sub update {
    my($self, $username, $passwd,$other) = @_;
    return 0 unless $self->exists($username);

    my(%f);
    if ($other) {
	Carp::croak('Specify other fields as a hash ref for SQL databases')
	    unless ref($other) eq 'HASH';
	  foreach (keys %{$other}) {
	      $f{$_} = $other->{$_};
	  }
    }

    $f{$self->{PASSWORDFIELD}}=$self->encrypt($passwd) if $passwd;

    local $^W = 0; # can't stand this
    my $statement =
	sprintf("UPDATE %s SET %s\n WHERE %s = '%s'\n",
		$self->{USERTABLE},
		join(',', map {$_ . "=" . ($self->_is_string($_,$f{$_}) ? "'$f{$_}'" : $f{$_}) } keys %f),
		$self->{NAMEFIELD}, $username);
    print STDERR $statement if $self->debug;
    $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
}

sub list {
    my($self) = @_;
    my $statement = 
	sprintf("SELECT %s from %s\n",
		@{$self}{qw(NAMEFIELD USERTABLE)});
    print STDERR $statement if $self->debug;
    my $sth = $self->{'_DBH'}->prepare($statement);
    Carp::carp("Cannot prepare sth ($DBI::err): $DBI::errstr")
	unless $sth;
    $sth->execute || Carp::croak($DBI::errstr);
    my($user,@list);
    while($user = $sth->fetchrow) {
	push(@list, $user);
    }
    $sth->finish;
    return @list;
}

sub fetch {
    my($self,$username,@fields) = @_;
    return(0, "fetch: no user name!") unless $username;
    return(0, "fetch: user '$username' doesn't exist") 
	unless $self->exists($username);
    my (@f);
    foreach (@fields) {
	push(@f,ref($_) ? @$_ : $_);
    }
    push (@f,'*') unless @f;
    my $statement = 
	sprintf("SELECT %s FROM %s WHERE %s = '%s'",
		join(',',@f),
		@{$self}{qw/USERTABLE NAMEFIELD/},
		$username);
    print STDERR $statement if $self->debug;
    my $sth = $self->{'_DBH'}->prepare($statement);
    Carp::carp("Cannot prepare sth ($DBI::err): $DBI::errstr")
	unless $sth;
    $sth->execute || Carp::croak($DBI::errstr);
    my $result = $sth->fetchrow_hashref;
    $sth->finish;
    return $result;
}

sub _is_string {
    my ($self,$field_name,$field_value) = @_;
    $field_value ||= '';
    if ($self->{DRIVER} =~ /^msql$/i) {
	unless ($self->{'_TYPES'}) {
	    require Msql;
	    my $st = $self->{'_DBH'}->prepare("LISTFIELDS $self->{USERTABLE}") 
		|| Carp::croak($DBI::errstr);
	    $st->execute || Carp::croak($DBI::errstr);
	    my $types = $st->{msql_type};
	    foreach (@{$st->{NAME}}) {
		$self->{'_TYPES'}->{$_} = Msql::CHAR_TYPE() eq (shift @{$types});
	    }
	    $st->finish();
	}
	return $self->{'_TYPES'}->{$field_name};
    } else {
	return $field_value !~ /^[0-9.E-]+$/i;
    }
}

sub encrypt {
    my($self) = shift; 
    my($passwd) = "";
    my($scheme) = $self->{ENCRYPT} || "crypt";
    # not quite sure where we're at risk here...
    # $_[0] =~ /^[^<>;|]+$/ or Carp::croak("Bad password name"); $_[0] = $&;
    if (($self->{DRIVER} =~ /^mysql$/i) && ($scheme =~ /^MySQL(:?-Password)?$/i)) {
        my $statement = sprintf("SELECT password('%s')\n", $_[0]);
        print STDERR $statement if $self->debug;
        my $sth = $self->{'_DBH'}->prepare($statement);
        Carp::carp("Cannot prepare sth ($DBI::err): $DBI::errstr")
	    unless $sth;
        $sth->execute || Carp::croak($DBI::errstr);
        my(@row) = $sth->fetchrow;
        $sth->finish;
        $passwd = $row[0];
    } else {
	$passwd = $self->SUPER::encrypt(@_);
    }
    return $passwd;
}

1;

__END__

CREATE table auth_users (
    user char(40),
    password char(20)
)
   
