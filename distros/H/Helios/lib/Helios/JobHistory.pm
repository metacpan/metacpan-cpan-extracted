package Helios::JobHistory;

use strict;
use warnings;
use base qw( Data::ObjectDriver::BaseObject );

our $VERSION = '2.00';

__PACKAGE__->install_properties({
               columns     => [qw(jobid funcid arg uniqkey insert_time 
				                  run_after grabbed_until priority coalesce 
				                  complete_time exitstatus)],
               datasource  => 'helios_job_history_tb',
           });



1;
__END__;
