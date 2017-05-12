use Test::More tests => 20;

# server
use_ok('Gantry::Server');

use_ok('Gantry::Build');

# utilities
use_ok('Gantry::Utils::DB');
use_ok('Gantry::Utils::SQL');
use_ok('Gantry::Utils::HTML');
use_ok('Gantry::Utils::CRUDHelp');
use_ok('Gantry::Utils::ModelHelper');
use_ok('Gantry::Utils::FormErrors');

# auth control models
use_ok('Gantry::Control::Model::auth_users');
use_ok('Gantry::Control::Model::auth_pages');
use_ok('Gantry::Control::Model::auth_groups');
use_ok('Gantry::Control::Model::auth_group_members');

# auth control handlers
use_ok('Gantry::Control::C::Access');
can_ok('Gantry::Control::C::Access', 'handler' );

use_ok('Gantry::Control::C::AuthenBase');
can_ok('Gantry::Control::C::AuthenBase', 'handler' );

use_ok('Gantry::Control::C::AuthzBase');
can_ok('Gantry::Control::C::AuthzBase', 'handler' );

use_ok('Gantry::Control::C::Authz::PageBasedBase');
can_ok('Gantry::Control::C::Authz::PageBasedBase', 'handler' );
