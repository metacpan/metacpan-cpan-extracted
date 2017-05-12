
package My::Contact::Subscription;

use strict;
use warnings 'all';
use base 'Email::Blaster::Model';

__PACKAGE__->set_up_table('contact_subscriptions');

__PACKAGE__->has_a(
  contact =>
    'My::Contact' =>
      'contact_id'
);

__PACKAGE__->has_a(
  contact_list =>
    'My::Contact::List' =>
      'contact_list_id'
);

1;# return true:

