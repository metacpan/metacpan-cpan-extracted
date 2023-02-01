package Lemonldap::NG::Portal::Password::DBI;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_ERROR
  PE_PASSWORD_OK
);

extends qw(
  Lemonldap::NG::Portal::Lib::DBI
  Lemonldap::NG::Portal::Password::Base

);

our $VERSION = '2.0.16';

sub init {
    my ($self) = @_;
    $self->Lemonldap::NG::Portal::Password::Base::init
      and $self->Lemonldap::NG::Portal::Lib::DBI::init;
}

sub confirm {
    my ( $self, $req, $pwd ) = @_;
    return $self->check_password( $req->user, $pwd );
}

sub modifyPassword {
    my ( $self, $req, $pwd, %args ) = @_;
    my $userCol     = $args{useMail} ? $self->mailField : $self->pivot;
    my $passwordCol = $self->conf->{dbiAuthPasswordCol};
    my $table       = $self->conf->{dbiAuthTable};
    my $dynamicHash = $self->conf->{dbiDynamicHashEnabled} || 0;
    my $passwordsql;

    if ( $dynamicHash == 1 ) {

        # Dynamic password hashes
        $passwordsql =
          $self->dynamic_hash_new_password( $self->dbh, $req->user, $pwd,
            $table, $userCol, $passwordCol );
    }
    else {
        # Static Password hash
        $passwordsql =
          $self->hash_password( "?", $self->conf->{dbiAuthPasswordHash} );
    }

    eval {
        my $sth = $self->dbh->prepare(
            "UPDATE $table SET $passwordCol=$passwordsql WHERE $userCol=?");
        if ( $passwordsql =~ /.*\?.*/ ) {
            $sth->execute( $pwd, $req->user );
        }
        else {
            $sth->execute( $req->user );
        }
    };
    if ($@) {

        # If connection isn't available, error is displayed by dbh()
        $self->logger->error("DBI password modification error: $@")
          if ( $self->_dbh );
        return PE_ERROR;
    }
    else {
        return PE_PASSWORD_OK;
    }
}

1;
