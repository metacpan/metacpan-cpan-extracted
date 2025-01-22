package t::ChoiceHookPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);

use constant hook => { getAuthChoice => 'autoChoice', };

sub autoChoice {
    my ( $self, $req, $context ) = @_;

    # Pick a default choice for all users on a certain IP
    if ( $req->address eq "1.2.3.4" ) {
        $context->{choice} = "2_sql";
    }
    return PE_OK;
}

1;
