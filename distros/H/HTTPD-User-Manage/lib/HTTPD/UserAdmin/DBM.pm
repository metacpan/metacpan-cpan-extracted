# $Id: DBM.pm,v 1.1.1.1 2001/02/20 03:33:50 lstein Exp $
package HTTPD::UserAdmin::DBM;
use HTTPD::UserAdmin ();
use Carp ();
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(HTTPD::UserAdmin);
$VERSION = (qw$Revision: 1.1.1.1 $)[1];

my %Default = (PATH => ".",
	       DB => ".htpasswd",
	       DBMF => "NDBM", 
	       FLAGS => "rwc",
	       MODE => 0644, 
	    );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ } => $class;
    $self->_dbm_init;
    $self->db($self->{DB}); 
    return $self;
}

sub DESTROY {
    local($^W)=0;
    $_[0]->_untie('_HASH');
    $_[0]->unlock;
}

sub add {
    my($self, $user, $passwd, @rest) = @_;
    return(0, "add_user: no user name!") unless $user;
    return(0, "add_user: no password!") unless $passwd;
    return(0, "user '$user' exists in $self->{DB}") 
	if $self->exists($user);

    local($^W) = 0; #shutup uninit warnings
    if (ref($rest[0]) eq 'HASH') {
	my $f = $rest[0];
	@rest = ();
	foreach (keys %{$f}) { push(@rest,"$_="._escape($f->{$_})); }
    }
    my $dlm = ":";
    $dlm = $self->{DLM} if defined $self->{DLM};
    my $pass = $self->encrypt($passwd);
    $self->{'_HASH'}{$user} = $pass . (@rest ? ($dlm . join($dlm,@rest)) : "");
    1;
}

sub fetch {
    my($self,$username,@fields) = @_;
    return(0, "fetch: no user name!") unless $username;
    return(0, "fetch: user '$username' doesn't exist") 
	unless my $val = $self->exists($username);
    my (%f);
    foreach (@fields) {
	grep($f{$_}++,ref($_) ? @$_ : $_);
    }
    my(@bits) = split(':',$val);
    if ($self->{ENCRYPT} eq 'MD5') {
	splice(@bits,0,3);
    } else {
	shift(@bits);
    }
    my %r;
    foreach (@bits) {
	my($n,$v) = split('=');
	$r{$n}=_unescape($v) if $f{$n};
    }
    return \%r;
}

# Extended _escape to process control characters too [CJD]
# sub _escape { $_=shift; s/([,=:])/uc sprintf("%%%02x",ord($1))/ge; return $_; }
sub _escape { $_=shift; s/([\000-\037,=:%])/uc sprintf("%%%02x",ord($1))/ge; return $_; }
sub _unescape { $_=shift; s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge; return $_; }

package HTTPD::UserAdmin::DBM::_generic;
use vars qw(@ISA);
@ISA = qw(HTTPD::UserAdmin::DBM HTTPD::UserAdmin);

1;

__END__



