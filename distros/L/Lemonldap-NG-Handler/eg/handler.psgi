# Simple handler that can be used to replace llng-fastcgi-server to handler
# handler requests.
# See https://lemonldap-ng.org/documentation/<version>/highperfnginxhandler

require Lemonldap::NG::Handler::Server::Nginx;
Lemonldap::NG::Handler::Server::Nginx->run( {} );
