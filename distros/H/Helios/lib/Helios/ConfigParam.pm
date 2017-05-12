package Helios::ConfigParam;

use strict;
use warnings;
use base qw( Data::ObjectDriver::BaseObject );

our $VERSION = '2.00';

__PACKAGE__->install_properties({
               columns     => [qw(host worker_class param value)],
               datasource  => 'helios_params_tb',
           });



1;
__END__;
