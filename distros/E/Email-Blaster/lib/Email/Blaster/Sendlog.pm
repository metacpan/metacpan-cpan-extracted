
package Email::Blaster::Sendlog;

use strict;
use warnings 'all';
use base 'Email::Blaster::Model';

__PACKAGE__->set_up_table('sendlogs');

__PACKAGE__->has_a(
  transmission =>
    'Email::Blaster::Transmission' =>
      'transmission_id'
);

__PACKAGE__->has_many(
  events =>
    'Email::Blaster::Event' =>
      'sendlog_id'
);

1;# return true:

