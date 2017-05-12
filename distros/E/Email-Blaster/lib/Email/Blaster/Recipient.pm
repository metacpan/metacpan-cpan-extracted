
package Email::Blaster::Recipient;

use strict;
use warnings 'all';
use base 'Email::Blaster::Model';

__PACKAGE__->set_up_table('recipients');

__PACKAGE__->has_a(
  transmission =>
    'Email::Blaster::Transmission' =>
      'transmission_id'
);

1;# return true:

