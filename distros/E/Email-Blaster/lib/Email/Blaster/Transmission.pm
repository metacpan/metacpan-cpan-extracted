
package Email::Blaster::Transmission;

use strict;
use warnings 'all';
use base 'Email::Blaster::Model';


__PACKAGE__->set_up_table("transmissions");

__PACKAGE__->has_many(
  events =>
    'Email::Blaster::Event' =>
      'transmission_id'
);

__PACKAGE__->has_many(
  recipients =>
    'Email::Blaster::Recipient' =>
      'transmission_id'
);

__PACKAGE__->has_many(
  sendlogs =>
    'Email::Blaster::Sendlog' =>
      'transmission_id'
);

1;# return true:

