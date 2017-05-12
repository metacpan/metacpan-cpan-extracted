# $Id: netscape.pm,v 1.1.1.1 1998/01/13 12:57:53 lstein Exp $

# Define a subclass of DB_File that null-terminates strings
package DBNull_File;

require NDBM_File;
@ISA = qw(NDBM_File);

sub TIEHASH {
    my $pkg = shift;
    my $self = DB_File->TIEHASH(@_);
    return bless $self,$pkg;
}

sub EXISTS {
    my $self = shift;
    return $self->SUPER::EXISTS("$_[0]\0");
}

sub STORE {
    my $self = shift;
    return $self->SUPER::STORE("$_[0]\0","$_[1]\0");
}

sub FETCH {
    my $self = shift;
    my $h = $self->SUPER::FETCH("$_[0]\0");
    substr($h,-1,1)='' if $h;  #remove terminating null
    return $h;
}

sub FIRSTKEY {
    my $self = shift;
    my($a) = $self->SUPER::FIRSTKEY(@_);
    return undef unless defined($a);
    substr($a,-1,1)='';
    return $a;
}

sub NEXTKEY {
    my $self = shift;
    my($a) = $self->SUPER::NEXTKEY("$_[0]\0");
    return () unless defined($a);
    substr($a,-1,1)='';
    return $a;
}

sub DELETE {
    my $self = shift;
    $self->SUPER::DELETE("$_[0]\0");
}

sub CLEAR {
    my $self = shift;
    $self->SUPER::CLEAR(@_);
}

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY(@_);
}

package HTTPD::UserAdmin::DBM::netscape;
use Carp ();
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(HTTPD::UserAdmin::DBM);
$VERSION = (qw$Revision: 1.1.1.1 $)[1];

my %Default = (PATH => ".",
	       DB => ".htpasswd",
	       DBMF => "DBNull", 
	       FLAGS => "rwc",
	       MODE => 0644, 
	    );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ } => $class;
    $self->{DBMF} = 'DBNull';  # force null-terminated NDBM_File
    $self->_dbm_init;
    $self->db($self->{DB}); 
    return $self;
}

sub add {
    # deliberately get rid of additional info
    # since we don't understand Netscape format.
    my($self,$user,$passwd) = @_;
    $self->SUPER::add($user,$passwd);
}

sub update {
    my($self, $username, $passwd) = @_;
    $self->SUPER::update($username,$passwd);
}
	    
1;
