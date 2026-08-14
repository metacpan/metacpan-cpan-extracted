use warnings;
use Test::More;
use strict;
use Lemonldap::NG::Portal::Main::Request;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_PP_CHANGE_AFTER_RESET
  PE_PASSWORD_OK
  PE_BADCREDENTIALS
  PE_OK
);

require 't/test-lib.pm';

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel            => 'error',
            loginHistoryEnabled => 1,
            failedLoginNumber   => 20,
            successLoginNumber  => 20,
        }
    }
);

# Drive registerLogin() directly with a given authResult and return the
# resulting in-memory login history
sub classify {
    my ($authResult) = @_;
    my $req = Lemonldap::NG::Portal::Main::Request->new(
        { PATH_INFO => "", REQUEST_URI => "/" } );
    $req->sessionInfo(
        { uid => 'dwho', _whatToTrace => 'dwho', _utime => time } );
    $req->user('dwho');
    $req->authResult($authResult);
    $client->p->registerLogin($req);
    return $req->sessionInfo->{_loginHistory};
}

# A real authentication failure IS a failed login
my $h = classify(PE_BADCREDENTIALS);
is( scalar @{ $h->{failedLogin}  || [] }, 1, 'PE_BADCREDENTIALS -> failedLogin' );
is( scalar @{ $h->{successLogin} || [] }, 0, ' -> not in successLogin' );

# A successful authentication is a success login
$h = classify(PE_OK);
is( scalar @{ $h->{successLogin} || [] }, 1, 'PE_OK -> successLogin' );
is( scalar @{ $h->{failedLogin}  || [] }, 0, ' -> not in failedLogin' );

# "Change password after reset" must NOT be a failed login (#3634)
$h = classify(PE_PP_CHANGE_AFTER_RESET);
is( scalar @{ $h->{failedLogin} || [] },
    0, 'PE_PP_CHANGE_AFTER_RESET -> not a failed login' );

# Successful password change must NOT be a failed login (#3634)
$h = classify(PE_PASSWORD_OK);
is( scalar @{ $h->{failedLogin} || [] },
    0, 'PE_PASSWORD_OK -> not a failed login' );

clean_sessions();
done_testing();
