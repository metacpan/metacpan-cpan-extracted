
package My::Contact;

use strict;
use warnings 'all';
use base 'Email::Blaster::Model';

__PACKAGE__->set_up_table('contacts');

__PACKAGE__->has_many(
  contact_subscriptions =>
    'My::Contact::Subscription' =>
      'contact_id'
);

1;# return true:

