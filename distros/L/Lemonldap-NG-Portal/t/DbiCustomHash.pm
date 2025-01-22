package t::DbiCustomHash;

use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_DONE);
use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant hook => {
    dbiVerifyPassword => 'check_password',
    dbiHashPassword   => 'hash_new_password',

};

sub check_password {
    my ( $self, $req, $candidate_password, $stored_salt, $result ) = @_;

    if ( $stored_salt =~ /^@@@/ ) {
        $result->{result} =
          ( $stored_salt eq ( '@@@' . uc($candidate_password) ) );
        return PE_DONE;
    }
    return PE_OK;
}

sub hash_new_password {
    my ( $self, $req, $scheme, $new_password, $result ) = @_;
    if ( $scheme eq "mycustom" ) {
        $result->{hashed_password} = ( '@@@' . uc($new_password) );
        return PE_DONE;
    }
    return PE_OK;
}

1;
