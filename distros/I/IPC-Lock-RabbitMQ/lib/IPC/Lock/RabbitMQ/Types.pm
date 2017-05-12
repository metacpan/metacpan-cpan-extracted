package IPC::Lock::RabbitMQ::Types;
use MooseX::Types -declare => [qw/
    Channel
    MQ
/];
use Moose::Util::TypeConstraints;
use namespace::clean -except => [qw/ import meta /];

class_type MQ, { class => 'AnyEvent::RabbitMQ' };

class_type 'Net::RabbitFoot';

coerce MQ, from 'Net::RabbitFoot', via { $_->{_ar} };

1;

=head1 NAME

IPC::Lock::RabbitMQ::Types - Type constraints for IPC::Lock::RabbitMQ.

=head1 DESCRIPTION

See L<IPC::Lock::RabbitMQ>

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<IPC::Lock::RabbitMQ>.

=cut
