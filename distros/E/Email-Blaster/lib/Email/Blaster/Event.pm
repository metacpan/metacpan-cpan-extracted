
package Email::Blaster::Event;

use strict;
use warnings 'all';
use base 'Email::Blaster::Model';

__PACKAGE__->set_up_table('events');

__PACKAGE__->has_a(
  event_type =>
    'Email::Blaster::Event::Type' =>
      'event_type_id'
);

1;# return true:

