package Lemonldap::NG::Portal::Lib::LDAP;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Lib::Net::LDAP;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_LDAPERROR
  PE_USERNOTFOUND
  PE_BADCREDENTIALS
  PE_LDAPCONNECTFAILED
);

extends 'Lemonldap::NG::Common::Module';

our $VERSION = '2.0.15';

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

    # Build object and test LDAP connection
    $self->logger->debug(
        "Try to build new LDAP connection with: $self->{conf}->{ldapServer}");

    return undef
      unless (
        $ldap = Lemonldap::NG::Portal::Lib::Net::LDAP->new(
            { p => $self->{p}, conf => $self->{conf} }
        )
      );

    # Test connection
    my $msg = $ldap->bind;
    $self->logger->error( 'LDAP test has failed: ' . $msg->error )
      if $msg->code;

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

has findUserFilter => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        $_[0]->conf->{AuthLDAPFilter}
          || $_[0]->conf->{LDAPFilter}
          || '(&(uid=$user)(objectClass=inetOrgPerson))';
    }
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

    $self->validateLdap;
    return PE_LDAPCONNECTFAILED unless $self->ldap;
    return PE_LDAPERROR         unless $self->bind();

    my $mesg = $self->ldap->search(
        base   => $self->conf->{ldapBase},
        scope  => 'sub',
        filter => (
              $args{useMail}
            ? $self->mailFilter->($req)
            : $self->filter->($req)
        ),
        deref => $self->conf->{ldapSearchDeref} || 'find',
        attrs => $self->attrs,
    );
    if ( $mesg->code() != 0 ) {
        $self->logger->error(
            'LDAP Search error ' . $mesg->code . ": " . $mesg->error );
        return PE_LDAPERROR;
    }
    if ( $mesg->count() > 1 ) {
        $self->logger->error('More than one entry returned by LDAP directory');
        eval { $self->p->_authentication->setSecurity($req) };
        return PE_BADCREDENTIALS;
    }
    unless ( $req->data->{ldapentry} = $mesg->entry(0) ) {
        $self->userLogger->warn(
                "$req->{user} was not found in LDAP directory ("
              . $req->address
              . ")" );
        eval { $self->p->_authentication->setSecurity($req) };
        return PE_BADCREDENTIALS;
    }
    $req->data->{dn} = $req->data->{ldapentry}->dn();

    return PE_OK;
}

sub findUser {
    my ( $self, $req, %args ) = @_;
    my $plugin =
      $self->p->loadedModules->{"Lemonldap::NG::Portal::Plugins::FindUser"};
    my ( $searching, $excluding ) = $plugin->retreiveFindUserParams($req);
    eval { $self->p->_authentication->setSecurity($req) };
    return PE_OK unless scalar @$searching;

    $self->validateLdap;
    return PE_LDAPCONNECTFAILED unless $self->ldap;

    my $filter =
      $self->findUserFilter =~ /\bobjectClass=(\w+)\b/
      ? "(&(objectClass=$1)"
      : '(&';
    my $wildcard = $self->conf->{findUserWildcard};
    $self->logger->info("LDAP UserDB with wildcard ($wildcard)") if $wildcard;
    foreach (@$searching) {
        if ($wildcard) {
            $_->{value} =~ s/\Q$wildcard\E+/*/g;
        }
        else {
            $_->{value} =~ s/\Q*\E+//g;
        }
        $filter .= "($_->{key}=$_->{value})";
    }
    $filter .= "(!($_->{key}=$_->{value}))" foreach (@$excluding);
    $filter .= ')';
    $self->logger->debug("LDAP UserDB built filter: $filter");

    $self->bind();
    my $mesg = $self->ldap->search(
        base      => $self->conf->{ldapBase},
        scope     => 'sub',
        filter    => $filter,
        deref     => $self->conf->{ldapSearchDeref} || 'find',
        attrs     => $self->attrs,
        sizelimit => 50
    );

    if ( $mesg->code() != 0 ) {
        $self->logger->error(
            'LDAP Search error ' . $mesg->code . ": " . $mesg->error );
        return PE_LDAPERROR;
    }

    $self->logger->debug(
        'LDAP UserDB number of result(s): ' . $mesg->count() );
    if ( $mesg->count() ) {
        my $rank = int( rand( $mesg->count() ) );
        $self->logger->debug("Demo UserDB random rank: $rank");
        my $entry =
          ( $mesg->entry($rank)->dn() =~ /\b(?:uid|sAMAccountName)\x3d(.+?),/ )
          [0] || '';
        $self->userLogger->info("FindUser: LDAP UserDB returns $entry")
          if $entry;
        $req->data->{findUser} = $entry;
        return PE_OK;
    }

    return PE_USERNOTFOUND;
}

# Validate LDAP connection before use
sub validateLdap {
    my ($self) = @_;
    local $SIG{'PIPE'} = sub {
        $self->logger->info("Reconnecting to LDAP server due to broken socket");
    };

    unless ($self->ldap
        and $self->ldap->root_dse( attrs => ['supportedLDAPVersion'] ) )
    {
        $self->ldap->DESTROY if ( $self->ldap );
        $self->ldap( $self->newLdap );
    }
}

# Bind
sub bind {
    my $self = shift;

    $self->validateLdap;
    return undef unless $self->ldap;

    my $msg = $self->ldap->bind(@_);
    if ( $msg->code ) {
        $self->logger->error( $msg->error );
        return undef;
    }

    return 1;
}

1;
