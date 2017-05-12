# $Id: SQL.pm,v 1.2 2003/01/16 19:41:31 lstein Exp $
package HTTPD::GroupAdmin::SQL;
use strict;
use DBI;
use Carp ();
use vars qw(@ISA $VERSION);
@ISA = qw(HTTPD::GroupAdmin);
$VERSION = (qw$Revision: 1.2 $)[1];

my %Default = (
	       HOST => "",                  #server hostname
               PORT => "",                  #server port
	       DB => "",                    #database name
	       USER => "", 	            #database login name	    
	       AUTH => "",                  #database login password
	       DRIVER => "mSQL",            #driver for DBI
	       GROUPTABLE => "",             #table with field names below
	       NAMEFIELD => "user",         #field for the name
	       GROUPFIELD => "group",       #field for the group
	       );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ } => $class;
    $self->_check(qw(DRIVER DB GROUPTABLE)); 
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

    my $source = sprintf("dbi:%s:%s",@{$self}{qw(DRIVER DB)});
    $source .= ":$self->{HOST}" if $self->{HOST};
    $source .= ":$self->{PORT}" if $self->{HOST} && $self->{PORT};
    $self->{'_DBH'} = DBI->connect($source,@{$self}{qw(USER AUTH)} )
	|| Carp::croak($DBI::errstr);

    return $old;
}

package HTTPD::GroupAdmin::SQL::_generic;
use vars qw(@ISA);
@ISA = qw(HTTPD::GroupAdmin::SQL);

sub add {
    my($self, $username, $groupname) = @_;
    return(0, "add_group: no user name!") unless $username;
    return(0, "add_group: no group!") unless $groupname;
    
    return(0, "user '$username' already exists in group '$groupname'") 
	if $self->exists($groupname,$username);

    my $statement = 
	$self->{GROUPTABLE} ne $self->{USERTABLE} ?
	    sprintf("INSERT into %s (%s,%s)\n VALUES ('%s','%s')\n",
		    @{$self}{ qw(GROUPTABLE NAMEFIELD GROUPFIELD) },
		    $username,$groupname) 
		:
            sprintf("UPDATE %s\n SET %s='%s'\n WHERE %s='%s'\n",
		    $self->{GROUPTABLE},$self->{GROUPFIELD},$groupname,
		    $self->{NAMEFIELD},$username);
		    
    print STDERR $statement if $self->debug;
    $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
    1;
}

sub exists {
    my ($self,$groupname,$username) = @_;
    return(0, "exists: no group!") unless $groupname;
    my $select = "$self->{GROUPFIELD}='$groupname'";
    $select = "$self->{GROUPFIELD} like '$groupname'"  if ($groupname =~ /%/);
    $select .= " AND $self->{NAMEFIELD}='$username'" if defined $username;
    my $statement = 
	sprintf("SELECT DISTINCT %s FROM %s WHERE %s",
		@{$self}{qw(GROUPFIELD GROUPTABLE)},
		$select);
    print STDERR $statement if $self->debug;
    my $sth = $self->{'_DBH'}->prepare($statement) || Carp::croak($DBI::errstr);
    $sth->execute || Carp::croak($DBI::errstr);
    my $result = $sth->rows;
    $sth->finish;
    return $result;
}

sub delete {
    my ($self,$username,$groupname) = @_;
    return(0, "delete: no username!") unless defined $username;

    # if the group table and the user table are the same, then
    # we do not remove the record -- otherwise everything else
    # disappears too!
    return 1 if $self->{GROUPTABLE} eq $self->{USERTABLE};

    $groupname = $self->{NAME} unless defined $groupname;
    my $select = "$self->{NAMEFIELD}='$username' AND $self->{GROUPFIELD}='$groupname'" if defined $groupname;
    my $statement = 
	sprintf("DELETE FROM %s WHERE %s = '%s' AND %s = '%s'",
		$self->{GROUPTABLE},
		$self->{NAMEFIELD},$username,
		$self->{GROUPFIELD},$groupname);
    print STDERR $statement if $self->debug;
    my $rv = $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
    return $rv;
}

sub remove {
    my ($self,$groupname) = @_;
    return(0, "remove: no groupname!") unless defined $groupname;
    my $statement = 
	sprintf("DELETE FROM %s WHERE %s = '%s'",
		@{$self}{qw(GROUPTABLE GROUPFIELD)},$groupname);
    print STDERR $statement if $self->debug;
    my $rv = $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
    return $rv;
}

sub list {
    my($self,$groupname) = @_;
    my $statement;
    if (defined $groupname) {
	$statement =
	    sprintf("SELECT DISTINCT %s FROM %s WHERE %s = '%s'",
		    @{$self}{qw(NAMEFIELD GROUPTABLE GROUPFIELD)},
		    $groupname);    
        if ($groupname =~ /%/)
        {
	  $statement =
	      sprintf("SELECT DISTINCT %s FROM %s WHERE %s like '%s'",
	 	    @{$self}{qw(NAMEFIELD GROUPTABLE GROUPFIELD)},
		    $groupname);    
        }
    } else {
	$statement =
	    sprintf("SELECT DISTINCT %s FROM %s",
		    @{$self}{qw(GROUPFIELD GROUPTABLE GROUPFIELD)});    
    }
    print STDERR $statement if $self->debug;

    my $sth = $self->{'_DBH'}->prepare($statement) || Carp::croak($DBI::errstr);
    $sth->execute || Carp::croak($DBI::errstr);

    my @result = ();
    while (my $a = $sth->fetchrow_arrayref) {
	push(@result,@$a);
    }
    return @result;
}

1;
