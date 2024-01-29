package t::LogoutFail;

use constant beforeLogout => 'fail';
use constant init => 1;
use constant fail => 56; # PE_SOL_ERROR
use Mouse;

extends 'Lemonldap::NG::Portal::Main::Plugin';

1;
