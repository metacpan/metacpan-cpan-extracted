package Mesos::Channel;
use Moo;
use Data::Dumper;
use Carp;
use strict;
use warnings;

=head1 NAME

Mesos::Channel

=head1 DESCRIPTION

The default channel implementation. This is an alias for Mesos::Channel::Pipe.

=cut

use Mesos::Channel::Pipe;
sub new { Mesos::Channel::Pipe->new( splice(@_, 1) ) }

1;
