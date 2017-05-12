use strict;
use warnings;

package Jifty::Plugin::Authentication::ModShibb::Dispatcher;
use Jifty::Dispatcher -base;

=head1 NAME

Jifty::Plugin::Authentication::ModShibb::Dispatcher - url dispatcher

=cut

# whitelist safe actions to avoid cross-site scripting
before '*' => run { Jifty->api->allow('ShibbLogout') };


# Login
before '/shibblogin' => run {
 #   set 'action' =>
 #       Jifty->web->new_action(
 #       class => 'ShibbLogin',
 #       moniker => 'shibbloginbox',
 #       );

  set 'next' => Jifty->web->request->continuation
      || Jifty::Continuation->new(
      request => Jifty::Request->new( path => "/" ) );
};

on '/shibblogin' => run {
        Jifty->web->new_action(
        class => 'ShibbLogin',
        moniker => 'shibbloginbox',
        )->run;

    if(Jifty->web->request->continuation) {
        Jifty->web->request->continuation->call;
     } else {
           redirect '/';
     }
};

# Logout
before '/shibblogout' => run {
    Jifty->web->request->add_action(
        class   => 'ShibbLogout',
        moniker => 'shibblogout',
    );
};

on '/shibblogout' => run {
   redirect '/';
};


1;
