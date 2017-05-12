package Helios::LogEntry;

use strict;
use warnings;
use base qw( Data::ObjectDriver::BaseObject );

our $VERSION = '2.00';

__PACKAGE__->install_properties({
               columns     => [qw(log_time host process_id jobid funcid job_class priority message)],
               datasource  => 'helios_log_tb',
           });



1;
__END__;
