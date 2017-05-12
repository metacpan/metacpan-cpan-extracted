
package My::Contact::List;

use strict;
use warnings 'all';
use base 'Email::Blaster::Model';

__PACKAGE__->set_up_table('contact_lists');

__PACKAGE__->has_many(
  contact_subscriptions =>
    'My::Contact::Subscription' =>
      'contact_list_id'
);

1;# return true:

