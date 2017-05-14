package Hopkins::Constants;

use strict;
use warnings;

=head1 NAME

Hopkins::Constants - hopkins constants

=head1 DESCRIPTION

Hopkins::Constants takes care of exporting subroutines to
the caller's namespace for any of the particular constants
used throughout the system.

=cut

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT =
qw/
	HOPKINS_ENQUEUE_OK
	HOPKINS_ENQUEUE_TASK_NOT_FOUND
	HOPKINS_ENQUEUE_TASK_STACK_LIMIT
	HOPKINS_ENQUEUE_QUEUE_FROZEN
	HOPKINS_ENQUEUE_QUEUE_UNAVAILABLE
	HOPKINS_ENQUEUE_DATETIME_INVALID
	HOPKINS_QUEUE_ALREADY_RUNNING
	HOPKINS_QUEUE_STARTED
	HOPKINS_QUEUE_NOT_FOUND
	HOPKINS_QUEUE_RUNNING
	HOPKINS_QUEUE_STATUS_IDLE
	HOPKINS_QUEUE_STATUS_RUNNING
	HOPKINS_QUEUE_STATUS_HALTED
/;

use constant HOPKINS_ENQUEUE_OK					=> 1;
use constant HOPKINS_ENQUEUE_TASK_NOT_FOUND		=> 2;
use constant HOPKINS_ENQUEUE_TASK_STACK_LIMIT	=> 3;
use constant HOPKINS_ENQUEUE_QUEUE_FROZEN		=> 4;
use constant HOPKINS_ENQUEUE_QUEUE_UNAVAILABLE	=> 5;
use constant HOPKINS_ENQUEUE_DATETIME_INVALID	=> 6;

use constant HOPKINS_QUEUE_ALREADY_RUNNING		=> 1;
use constant HOPKINS_QUEUE_STARTED				=> 2;
use constant HOPKINS_QUEUE_NOT_FOUND			=> 3;

use constant HOPKINS_QUEUE_STATUS_IDLE			=> 1;
use constant HOPKINS_QUEUE_STATUS_RUNNING		=> 2;
use constant HOPKINS_QUEUE_STATUS_HALTED		=> 3;

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

=cut

1;
