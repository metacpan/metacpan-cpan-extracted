use strict;
use warnings;

package TestApp::Dispatcher;
use Jifty::Dispatcher -base;

before '/protected' => run {
     unless(Jifty->web->current_user->id) {
         Jifty->web->tangent(url => '/shibblogin');
     };
};

1;
