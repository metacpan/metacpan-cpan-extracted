use strict;
use warnings;

package TestApp::Model::User;
use Jifty::DBI::Schema;

use TestApp::Record schema {

column email =>
   type is 'varchar';

};

use Jifty::Plugin::OpenID::Mixin::Model::User;

sub name {
    my $self = shift;
    return $self->email;
}

1;

