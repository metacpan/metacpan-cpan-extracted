# $Id: DBM.pm,v 1.1.1.1 1997/12/23 11:14:48 lstein Exp $
package HTTPD::GroupAdmin::DBM;
use vars qw(@ISA $DLM $VERSION);
use strict;
use Carp ();
@ISA = qw(HTTPD::GroupAdmin);
$VERSION = (qw$Revision: 1.1.1.1 $)[1];
$DLM = " ";

my %Default = (PATH => ".",
	       DB => ".htgroup",
	       DBMF => "NDBM", 
               NAME => "",
               FLAGS => "rwc",
	       MODE => 0644, 
	    );

sub new {
    my($class) = shift;
    my $self = bless {%Default, @_}, $class;
    $self->_dbm_init;
    $self->db($self->{DB}); 
    return $self;
}

DESTROY {
    local($^W)=0;
    $_[0]->_untie('_HASH');
    $_[0]->unlock;
}

sub add {
    my($self, $username, $group) = @_;
    $group = $self->{NAME} unless defined $group;
    return(0, "No group name!") unless defined $group;

    unless ($self->{'_HASH'}) {
 	$self->_tie('_HASH', $self->{DB});
    }
    if ($self->{'_HASH'}{$group}) {
	return (0, "'$username' already in '$group'") if
	    $self->{'_HASH'}{$group} =~ /(^|[$DLM]+)$username([$DLM]+|$)/;
    }
    #for that old .= bug, should be fixed now
    my $val = "";	
    if(defined $self->{'_HASH'}{$group}) {
	$val = $self->{'_HASH'}{$group} . $DLM;
    }
    $val .= $username;
    $self->{'_HASH'}{$group} = $val;
}

sub remove { 
    my($self,$group) = @_;
    $group = $self->{NAME} unless defined $group;
    delete $self->{'_HASH'}{$group};
    if($self->{NAME} eq $group) {
	delete $self->{NAME};
    }
    1;
}

sub list {
    return split(/[$DLM]+/, $_[0]->{'_HASH'}{$_[1]}) if $_[1];
    keys %{$_[0]->{'_HASH'}};
}

package HTTPD::GroupAdmin::DBM::_generic;
use vars qw(@ISA);
@ISA = qw(HTTPD::GroupAdmin::DBM);

1;

__END__

