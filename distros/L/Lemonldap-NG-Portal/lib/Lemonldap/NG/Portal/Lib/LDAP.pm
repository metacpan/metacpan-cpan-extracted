package Lemonldap::NG::Portal::Lib::LDAP;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Lib::Net::LDAP;
use Lemonldap::NG::Portal::Main::Constants
  qw(PE_OK PE_LDAPCONNECTFAILED PE_LDAPERROR PE_BADCREDENTIALS);

extends 'Lemonldap::NG::Common::Module';

our $VERSION = '2.0.0';

# PROPERTIES

has ldap => (
    is      => 'rw',
    lazy    => 1,
    builder => 'newLdap',
);

has attrs => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        return [
            values %{ $_[0]->{conf}->{exportedVars} },
            values %{ $_[0]->{conf}->{ldapExportedVars} }
        ];
    }
);

sub newLdap {
    my $self = $_[0];
    my $ldap;

    # Build object and test LDAP connexion
    unless (
        $ldap = Lemonldap::NG::Portal::Lib::Net::LDAP->new(
            { p => $self->{p}, conf => $self->{conf} }
        )
      )
    {
        $self->logger->error("LDAP initialization error: $@");
        return undef;
    }

    # Test connection
    my $msg = $ldap->bind;
    if ( $msg->code ) {
        $self->logger->error( 'LDAP test has failed: ' . $msg->error );
    }
    elsif ( $self->{conf}->{ldapPpolicyControl} and not $ldap->loadPP() ) {
        $self->logger->error("LDAP password policy error");
    }
    return $ldap;
}

has filter => (
    is      => 'rw',
    lazy    => 1,
    builder => 'buildFilter',
);

has mailFilter => (
    is      => 'rw',
    lazy    => 1,
    builder => 'buildMailFilter',
);

sub buildFilter {
    return $_[0]->_buildFilter( $_[0]->conf->{AuthLDAPFilter}
          || $_[0]->conf->{LDAPFilter}
          || '(&(uid=$user)(objectClass=inetOrgPerson))' );
}

sub buildMailFilter {
    my $f = $_[0]->conf->{mailLDAPFilter}
      || '(&(mail=$user)(objectClass=inetOrgPerson))';
    $f =~ s/\$mail\b/\$user/g;
    return $_[0]->_buildFilter($f);
}

sub _buildFilter {
    my ( $self, $filter ) = @_;
    my $conf = $self->{conf};
    $self->{p}->logger->debug("LDAP Search base: $_[0]->{conf}->{ldapBase}");
    $filter =~ s/"/\\"/g;
    $filter =~ s/\$(\w+)/".\$req->{sessionInfo}->{$1}."/g;
    $filter =~ s/\$req->\{sessionInfo\}->\{user\}/\$req->{user}/g;
    $filter =~
      s/\$req->\{sessionInfo\}->\{(_?password|mail)\}/\$req->{data}->{$1}/g;
    $self->{p}->logger->debug("LDAP transformed filter: $filter");
    $filter = "sub{my(\$req)=\$_[0];return \"$filter\";}";
    my $res = eval $filter;

    if ($@) {
        $self->error("Unable to build fiter: $@");
    }
    return $res;
}

# INITIALIZATION

sub init {
    my ($self) = @_;
    $self->ldap
      or $self->logger->error(
        "LDAP initialization has failed, but let's continue");
    $self->filter;
}

# RUNNING METHODS

sub getUser {
    my ( $self, $req, %args ) = @_;
    return PE_LDAPCONNECTFAILED unless $self->ldap and $self->bind();
    my $mesg = $self->ldap->search(
        base   => $self->conf->{ldapBase},
        scope  => 'sub',
        filter => (
              $args{useMail}
            ? $self->mailFilter->($req)
            : $self->filter->($req)
        ),
        defer => $self->conf->{ldapSearchDeref} || 'find',
        attrs => $self->attrs,
    );
    if ( $mesg->code() != 0 ) {
        $self->logger->error( 'LDAP Search error: ' . $mesg->error );
        return PE_LDAPERROR;
    }
    if ( $mesg->count() > 1 ) {
        $self->logger->error('More than one entry returned by LDAP directory');
        eval { $self->p->_authentication->setSecurity($req) };
        return PE_BADCREDENTIALS;
    }
    unless ( $req->data->{entry} = $mesg->entry(0) ) {
        $self->userLogger->warn("$req->{user} was not found in LDAP directory");
        eval { $self->p->_authentication->setSecurity($req) };
        return PE_BADCREDENTIALS;
    }
    $req->data->{dn} = $req->data->{entry}->dn();
    PE_OK;
}

# Test LDAP connection before trying to bind
sub bind {
    my $self = shift;
    unless ($self->ldap
        and $self->ldap->root_dse( attrs => ['supportedLDAPVersion'] ) )
    {
        $self->ldap->DESTROY if ( $self->ldap );
        $self->ldap( $self->newLdap );
    }
    return undef unless ( $self->ldap );
    my $msg = $self->ldap->bind(@_);
    if ( $msg->code ) {
        $self->logger->error( $msg->error );
        return undef;
    }
    return 1;
}

1;
