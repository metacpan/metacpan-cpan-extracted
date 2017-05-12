use strict;
use warnings;
use Test::More tests => 4;
use lib 'lib';
use Forward::Routes;



#############################################################################
### namespace_to_name method

is (Forward::Routes::Resources->namespace_to_name('Admin'), 'admin');
is (Forward::Routes::Resources->namespace_to_name('Admin::Users'), 'admin_users');
is (Forward::Routes::Resources->namespace_to_name('NewAdmin'), 'new_admin');
is (Forward::Routes::Resources->namespace_to_name('NewAdmin::OldUser'), 'new_admin_old_user');

# TO DO: CORRECT ?
# is (Forward::Routes::Resources->namespace_to_name('NEWAdmin::OldUser'), 'n_e_w_admin_old_user');
