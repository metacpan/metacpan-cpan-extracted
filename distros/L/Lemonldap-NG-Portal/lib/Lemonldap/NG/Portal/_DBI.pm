##@file
# DBI common functions

##@class
# DBI common functions
package Lemonldap::NG::Portal::_DBI;

use DBI;
use base qw(Exporter);
use Lemonldap::NG::Portal::Simple;
use strict;

our @EXPORT = qw(dbh);

our $VERSION = '1.9.1';

## @method protected Lemonldap::NG::Portal::_DBI dbh(string dbiChain, string dbiUser, string dbiPassword)
# Create connection to database
# @param dbiChain DBI connection chain
# @param dbiUser DBI connection user
# @param dbiPassword DBI connection password
# @return dbh object
sub dbh {
    my $self        = shift;
    my $dbiChain    = shift;
    my $dbiUser     = shift;
    my $dbiPassword = shift;
    my $dbh;

    # Open connection to database
    eval {
        $dbh =
          DBI->connect_cached( $dbiChain, $dbiUser, $dbiPassword,
            { RaiseError => 1, },
          );
    };
    if ($@) {
        $self->lmLog( "DBI connection error: $@", 'error' );
        return 0;
    }

    $self->{_dbh} = $dbh;
    return $dbh;
}

## @method protected Lemonldap::NG::Portal::_DBI hash_password(string password, string hash)
# Return hashed password for use in SQL statement
# @param password clear password
# @param hash hash mechanism
# @return SQL statement string
sub hash_password {
    my $self     = shift;
    my $password = shift;
    my $hash     = shift;

    if ( $hash =~ /^(md5|sha|sha1|encrypt)$/i ) {
        $self->lmLog( "Using " . uc($hash) . " to hash password", 'debug' );
        return uc($hash) . "($password)";
    }
    else {
        $self->lmLog( "No valid password hash, using clear text for password",
            'warn' );
        return $password;
    }

}

## @method protected Lemonldap::NG::Portal::_DBI hash_password_for_select(string password, string hash)
# Return hashed password for use in SQL SELECT statement
# Call hash_password unless encrypt hash is choosen
# @param password clear password
# @param hash hash mechanism
# @return SQL statement string
sub hash_password_for_select {
    my $self        = shift;
    my $password    = shift;
    my $hash        = shift;
    my $passwordCol = $self->{dbiAuthPasswordCol};

    if ( $hash =~ /^encrypt$/i ) {
        return uc($hash) . "($password,$passwordCol)";
    }
    else {
        return $self->hash_password( $password, $hash );
    }
}

## @method protected Lemonldap::NG::Portal::_DBI check_password(ref dbh, string user, string password)
# Verify user and password with SQL SELECT
# @param dbh database handle
# @param user user
# @param password password
# @return boolean result
sub check_password {
    my $self        = shift;
    my $dbh         = shift;
    my $user        = shift || $self->{user};
    my $password    = shift || $self->{password};
    my $table       = $self->{dbiAuthTable};
    my $loginCol    = $self->{dbiAuthLoginCol};
    my $passwordCol = $self->{dbiAuthPasswordCol};

    # Password hash
    my $passwordsql =
      $self->hash_password_for_select( "?", $self->{dbiAuthPasswordHash} );

    my @rows = ();
    eval {
        my $sth = $dbh->prepare(
"SELECT $loginCol FROM $table WHERE $loginCol=? AND $passwordCol=$passwordsql"
        );
        $sth->execute( $user, $password );
        @rows = $sth->fetchrow_array();
    };
    if ($@) {
        $self->lmLog( "DBI error: $@", 'error' );
        return 0;
    }

    if ( @rows == 1 ) {
        $self->lmLog( "One row returned by SQL query", 'debug' );
        return 1;
    }
    else {
        $self->_sub( 'userError', "Bad password for $user" );
        return 0;
    }

}

## @method protected Lemonldap::NG::Portal::_DBI modify_password(string user, string password, string userCol, string passwordCol)
# Modify password with SQL UPDATE
# @param user user
# @param password password
# @param userCol optional user column
# @param passwordCol optional password column
# @return boolean result
sub modify_password {
    my $self        = shift;
    my $user        = shift;
    my $password    = shift;
    my $userCol     = shift || $self->{dbiAuthLoginCol};
    my $passwordCol = shift || $self->{dbiAuthPasswordCol};

    my $table = $self->{dbiAuthTable};

    # Password hash
    my $passwordsql = $self->hash_password( "?", $self->{dbiAuthPasswordHash} );

    eval {
        my $sth =
          $self->{_dbh}->prepare(
            "UPDATE $table SET $passwordCol=$passwordsql WHERE $userCol=?");
        $sth->execute( $password, $user );
    };
    if ($@) {
        $self->lmLog( "DBI password modification error: $@", 'error' );
        return 0;
    }

    return 1;
}

1;
