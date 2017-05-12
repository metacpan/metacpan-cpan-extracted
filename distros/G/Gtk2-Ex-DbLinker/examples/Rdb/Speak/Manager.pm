package Rdb::Speak::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Rdb::Speak;

sub object_class { 'Rdb::Speak' }

__PACKAGE__->make_manager_methods('speaks');

1;

