package Rdb::Country::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Rdb::Country;

sub object_class { 'Rdb::Country' }

__PACKAGE__->make_manager_methods('countries');

1;

