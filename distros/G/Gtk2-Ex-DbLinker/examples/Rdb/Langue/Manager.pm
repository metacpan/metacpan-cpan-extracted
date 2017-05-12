package Rdb::Langue::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use Rdb::Langue;

sub object_class { 'Rdb::Langue' }

__PACKAGE__->make_manager_methods('langues');

1;

