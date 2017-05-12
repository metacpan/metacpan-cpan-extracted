package Gearman::JobScheduler::Configuration;

#
# GJS default configuration
#

use strict;
use warnings;
use Modern::Perl "2012";

use Moose 2.1005;
use MooseX::Singleton;	# ->instance becomes available


# Arrayref of default Gearman servers to connect to
has 'gearman_servers' => (
	is => 'rw',
	isa => 'ArrayRef[Str]',
	default => sub { [ '127.0.0.1:4730' ] }
);

# Where should the worker put the logs
has 'worker_log_dir' => (
	is => 'rw',
	isa => 'Str',
	default => '/var/log/gjs/'
);

# Default email address to send the email from
has 'notifications_from_address' => (
	is => 'rw',
	isa => 'Str',
	default => 'gjs_donotreply@example.com'
);

# Notification email subject prefix
has 'notifications_subject_prefix' => (
	is => 'rw',
	isa => 'Str',
	default => '[GJS]'
);

# Emails that should receive notifications about failed jobs
has 'notifications_emails' => (
	is => 'rw',
	isa => 'ArrayRef[Str]',
	# No one gets no mail by default:
	default => sub { [] }
);

no Moose;    # gets rid of scaffolding

1;
