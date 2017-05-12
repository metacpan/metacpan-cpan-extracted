use strict;
use warnings;

package JiftyTest::Model::User;
our $VERSION = '0.07';

use Jifty::DBI::Schema;

use JiftyTest::Record schema {

  column account =>
    type            is    'text',
    label           is    'Login Identity',
                    is     mandatory;

# column password => 
#   type            is    'password',
#   label           is    'Password',
#                   is     mandatory;

  column email => 
    type            is    'text',
    label           is    'Email';

  column email_confirmed => 
    type            is    'boolean',
    label           is    'Email Confirmed';
                    is     mandatory;

  column privilege => 
    type            is    'text',
    label           is    'Privilege',
    valide_values   are   qw(admin user),
    default         is    "user";

};

# Your model-specific methods go here.
# use Jifty::Plugin::User::Mixin::Model::User;
use Jifty::Plugin::Authentication::Password::Mixin::Model::User;


sub current_user_can {
  my ($self, $type, %args) = @_;
  return 1;
}

1;

