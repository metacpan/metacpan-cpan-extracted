use Test::More tests => 2;
use LWP::Simple::WithCache;
isnt($LWP::Simple::ua->{cache}->get_default_expires_in(), 86400, 'default_expires_in is NOT 1 day, could be 10 minutes or never');
$LWP::Simple::ua->{cache}->_set_default_expires_in(86400);
is($LWP::Simple::ua->{cache}->get_default_expires_in(), 86400, 'default_expires_in 1 day (customized)');
