use strict;
use inc::Module::Install;

name        'IPC-PubSub';
license     'MIT';
all_from    'lib/IPC/PubSub.pm';

requires    'Storable';
requires    'Time::HiRes';
requires    'DBM::Deep' => '1.00';
requires    'Data::UUID';
requires    'Class::Accessor::Fast';

sign; WriteAll;
