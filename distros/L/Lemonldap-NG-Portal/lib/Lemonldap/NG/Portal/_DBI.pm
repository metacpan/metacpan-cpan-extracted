##@file
# DBI common functions

##@class
# DBI common functions
package Lemonldap::NG::Portal::_DBI;

use DBI;
use MIME::Base64;
use base qw(Exporter);
use Lemonldap::NG::Portal::Simple;
use strict;

our @EXPORT = qw(dbh);

our $VERSION = '1.9.11';

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

## @method protected Lemonldap::NG::Portal::_DBI get_password(ref dbh, string user)
# Get password from database
# @param dbh database handler
# @param user user
# @return password
sub get_password {
    my $self        = shift;
    my $dbh         = shift;
    my $user        = shift || $self->{user};
    my $table       = $self->{dbiAuthTable};
    my $loginCol    = $self->{dbiAuthLoginCol};
    my $passwordCol = $self->{dbiAuthPasswordCol};

    my @rows = ();
    eval {
        my $sth =
          $dbh->prepare( "SELECT $passwordCol FROM $table WHERE $loginCol=?" );
        $sth->execute($user);
        @rows = $sth->fetchrow_array();
    };
    if ($@) {
        $self->lmLog( "DBI error while getting password: $@", 'error' );
        return "";
    }

    if ( @rows == 1 ) {
        $self->lmLog( "Successfully got password from database", 'debug' );
        return $rows[0];
    }
    else {
        $self->_sub( 'userError', "Unable to check password for $user" );
        return "";
    }
}

## @method protected Lemonldap::NG::Portal::_DBI hash_password_from_database
##  (ref dbh, string dbmethod, string dbsalt, string password)
# Hash the given password calling the dbmethod function in database
# @param dbh database handler
# @param dbmethod the database method for hashing
# @param salt the salt used for hashing
# @param password the password to hash
# @return hashed password
sub hash_password_from_database {

    # Remark: database function must get hexadecimal input
    # and send back hexadecimal output
    my $self     = shift;
    my $dbh      = shift;
    my $dbmethod = shift;
    my $dbsalt   = shift;
    my $password = shift;

    # convert password to hexa
    my $passwordh = unpack "H*", $password;

    my @rows = ();
    eval {
        my $sth = $dbh->prepare("SELECT $dbmethod('$passwordh$dbsalt')");
        $sth->execute();
        @rows = $sth->fetchrow_array();
    };
    if ($@) {
        $self->lmLog(
            "DBI error while hashing with '$dbmethod' hash function: $@",
            'error' );
        $self->_sub( 'userError', "Unable to check password" );
        return "";
    }

    if ( @rows == 1 ) {
        $self->lmLog(
"Successfully hashed password with $dbmethod hash function in database",
            'debug'
        );

        # convert salt to binary
        my $dbsaltb = pack 'H*', $dbsalt;

        # convert result to binary
        my $res = pack 'H*', $rows[0];

        return encode_base64( $res . $dbsaltb, '' );
    }
    else {
        $self->_sub( 'userError', "Unable to check password with '$dbmethod'" );
        return "";
    }

    # Return encode_base64(SQL_METHOD(password + salt) + salt)
    # attention : SQL_METHOD retourne un resultat en hexa
}

## @method protected Lemonldap::NG::Portal::_DBI get_salt(string dbhash)
# Return salt from salted hash password
# @param dbhash hash password
# @return extracted salt
sub get_salt {
    my $self   = shift;
    my $dbhash = shift;
    my $dbsalt;

    # get rid of scheme ({sha256})
    $dbhash =~ s/^\{[^}]+\}(.*)$/\1/;

    # get binary hash
    my $decoded = &decode_base64($dbhash);

    # get last 8 bytes
    $dbsalt = substr $decoded, -8;

    # get hexadecimal version of salt
    $dbsalt = unpack "H*", $dbsalt;

    return $dbsalt;
}

## @method protected Lemonldap::NG::Portal::_DBI gen_salt()
# Generate 8 bytes of hexadecimal random salt
# @return generated salt
sub gen_salt {
    my $self = shift;
    my $dbsalt;
    my @set = ( '0' .. '9', 'A' .. 'F' );

    $dbsalt = join '' => map $set[ rand @set ], 1 .. 16;

    return $dbsalt;
}

## @method protected Lemonldap::NG::Portal::_DBI dynamic_hash_password(ref dbh,
##  string user, string password, string table, string loginCol, string passwordCol)
# Return hashed password for use in SQL statement
# @param dbh database handler
# @param user connected user
# @param password clear password
# @param table authentication table name
# @param loginCol name of the row containing the login
# @param passwordCol name of the row containing the password
# @return hashed password
sub dynamic_hash_password {
    my $self        = shift;
    my $dbh         = shift;
    my $user        = shift;
    my $password    = shift;
    my $table       = shift;
    my $loginCol    = shift;
    my $passwordCol = shift;

    # Authorized hash schemes and salted hash schemes
    my @validSchemes = split / /, $self->{dbiDynamicHashValidSchemes};
    my @validSaltedSchemes = split / /,
      $self->{dbiDynamicHashValidSaltedSchemes};

    my $dbhash;      # hash currently stored in database
    my $dbscheme;    # current hash scheme stored in database
    my $dbmethod;    # static hash method corresponding to a database function
    my $dbsalt;      # current salt stored in database
    my $hash;        # hash to compute from user password

    # Search hash from database
    $self->lmLog( "Hash scheme is to be found in database", 'debug' );
    $dbhash =
      $self->get_password( $dbh, $user, $table, $loginCol, $passwordCol );

    # Get the scheme
    $dbscheme = $dbhash;
    $dbscheme =~ s/^\{([^}]+)\}.*/\1/;
    $dbscheme = "" if $dbscheme eq $dbhash;

    # no hash scheme => assume clear text
    if ( $dbscheme eq "" ) {
        $self->lmLog( "Password has no hash scheme", 'info' );
        return "?";

    }

    # salted hash scheme
    elsif ( grep( /^$dbscheme$/, @validSaltedSchemes ) ) {
        $self->lmLog(
            "Valid salted hash scheme: $dbscheme found for user $user",
            'info' );

        # extract non salted hash scheme
        $dbmethod = $dbscheme;
        $dbmethod =~ s/^s//i;

        # extract the salt
        $dbsalt = $self->get_salt($dbhash);
        $self->lmLog( "Get salt from password: $dbsalt", 'debug' );

        # Hash password with given hash scheme and salt
        $hash =
          $self->hash_password_from_database( $dbh, $dbmethod, $dbsalt,
            $password );
        $hash = "{$dbscheme}$hash";

        return "'$hash'";

    }

    # static hash scheme
    elsif ( grep( /^$dbscheme$/, @validSchemes ) ) {
        $self->lmLog( "Valid hash scheme: $dbscheme found for user $user",
            'info' );

        # Hash given password with given hash scheme and no salt
        $hash =
          $self->hash_password_from_database( $dbh, $dbscheme, "", $password );
        $hash = "{$dbscheme}$hash";

        return "'$hash'";
    }

    # no valid hash scheme
    else {
        $self->lmLog( "No valid hash scheme: $dbscheme for user $user",
            'error' );
        $self->_sub( 'userError', "Unable to check password for $user" );
        return "";
    }

}

## @method protected Lemonldap::NG::Portal::_DBI dynamic_hash_new_password(ref dbh,
##  string user, string password)
# Return hashed password for use in SQL statement
# @param dbh database handler
# @param user connected user
# @param password clear password
# @param dbscheme the scheme to use for hashing
# @return hashed password
sub dynamic_hash_new_password {
    my $self     = shift;
    my $dbh      = shift;
    my $user     = shift;
    my $password = shift;
    my $dbscheme = $self->{dbiDynamicHashNewPasswordScheme} || "";

    # Authorized hash schemes and salted hash schemes
    my @validSchemes = split / /, $self->{dbiDynamicHashValidSchemes};
    my @validSaltedSchemes = split / /,
      $self->{dbiDynamicHashValidSaltedSchemes};

    my $dbmethod;    # static hash method corresponding to a database function
    my $dbsalt;      # salt to generate for new hashed password
    my $hash;        # hash to compute from user password

    # no hash scheme => assume clear text
    if ( $dbscheme eq "" ) {
        $self->lmLog( "No hash scheme selected, storing password in clear text",
            'info' );
        return "?";

    }

    # salted hash scheme
    elsif ( grep( /^$dbscheme$/, @validSaltedSchemes ) ) {
        $self->lmLog( "Selected salted hash scheme: $dbscheme", 'info' );

        # extract non salted hash scheme
        $dbmethod = $dbscheme;
        $dbmethod =~ s/^s//i;

        # generate the salt
        $dbsalt = $self->gen_salt();
        $self->lmLog( "Generated salt: $dbsalt", 'debug' );

        # Hash given password with given hash scheme and salt
        $hash =
          $self->hash_password_from_database( $dbh, $dbmethod, $dbsalt,
            $password );
        $hash = "{$dbscheme}$hash";

        return "'$hash'";

    }

    # static hash scheme
    elsif ( grep( /^$dbscheme$/, @validSchemes ) ) {
        $self->lmLog( "Selected hash scheme: $dbscheme", 'info' );

        # Hash given password with given hash scheme and no salt
        $hash =
          $self->hash_password_from_database( $dbh, $dbscheme, "", $password );
        $hash = "{$dbscheme}$hash";

        return "'$hash'";
    }

    # no valid hash scheme
    else {
        $self->lmLog( "No selected hash scheme: $dbscheme is invalid",
            'error' );
        $self->_sub( 'userError', "Unable to store password for $user" );
        return "";
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
    my $dynamicHash = $self->{dbiDynamicHashEnabled} || 0;

    my $passwordsql;
    if ( $dynamicHash == 1 ) {

        # Dynamic password hashes
        $passwordsql =
          $self->dynamic_hash_password( $dbh, $user, $password, $table,
            $loginCol, $passwordCol );
    }
    else {
        # Static Password hashes
        $passwordsql =
          $self->hash_password_for_select( "?", $self->{dbiAuthPasswordHash} );
    }

    my @rows = ();
    eval {
        my $sth = $dbh->prepare(
"SELECT $loginCol FROM $table WHERE $loginCol=? AND $passwordCol=$passwordsql"
        );
        $sth->execute( $user, $password ) if $passwordsql =~ /.*\?.*/;
        $sth->execute($user) unless $passwordsql =~ /.*\?.*/;
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
    my $dynamicHash = $self->{dbiDynamicHashEnabled} || 0;

    my $passwordsql;
    if ( $dynamicHash == 1 ) {

        # Dynamic password hashes
        $passwordsql =
          $self->dynamic_hash_new_password( $self->{_dbh}, $user, $password,
            $table, $userCol, $passwordCol );
    }
    else {
        # Static Password hash
        $passwordsql =
          $self->hash_password( "?", $self->{dbiAuthPasswordHash} );
    }

    eval {
        my $sth =
          $self->{_dbh}->prepare(
            "UPDATE $table SET $passwordCol=$passwordsql WHERE $userCol=?");

        $sth->execute( $password, $user ) if $passwordsql =~ /.*\?.*/;
        $sth->execute($user) unless $passwordsql =~ /.*\?.*/;
    };
    if ($@) {
        $self->lmLog( "DBI password modification error: $@", 'error' );
        return 0;
    }

    return 1;
}

1;
