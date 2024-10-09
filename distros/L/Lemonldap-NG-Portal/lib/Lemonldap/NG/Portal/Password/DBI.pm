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
    return $self->check_password( $req, $pwd );
}

sub modifyPassword {
    my ( $self, $req, $pwd, %args ) = @_;
    my $userCol     = $args{useMail} ? $self->mailField : $self->pivot;
    my $passwordCol = $self->conf->{dbiAuthPasswordCol};
    my $table       = $self->conf->{dbiAuthTable};
    my $dynamicHash = $self->conf->{dbiDynamicHashEnabled} || 0;
    my $passwordsql;
    my $stored_value;

    if ( $dynamicHash == 1 ) {

        $passwordsql = "?";

        # Dynamic password hashes
        $stored_value =
          $self->get_dynamic_hash_new_password( $req, $self->dbh, $req->user,
            $pwd, $table, $userCol, $passwordCol );
    }
    else {
        # Static Password hash
        $passwordsql =
          $self->hash_password( "?", $self->conf->{dbiAuthPasswordHash} );
        $stored_value = $pwd;
    }

    eval {
        my $sth = $self->dbh->prepare(
            "UPDATE $table SET $passwordCol=$passwordsql WHERE $userCol=?");
        $sth->execute( $stored_value, $req->user );
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
