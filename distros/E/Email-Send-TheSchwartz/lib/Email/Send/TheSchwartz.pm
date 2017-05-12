# $Id: TheSchwartz.pm 3 2007-05-04 01:54:52Z btrott $

package Email::Send::TheSchwartz;
use strict;

use Email::Address;
use Return::Value;

our $SCHWARTZ;
our $VERSION = '0.01';

sub is_available {
    return eval { require TheSchwartz };
}

sub send {
    my $class = shift;
    my($msg, %args) = @_;
    
    require TheSchwartz;
    if (keys %args) {
        $SCHWARTZ = eval { $args{_client} || TheSchwartz->new(%args) };
        return failure "$@" if $@;
    }
    return failure "Can't send to TheSchwartz unless client is initialized" 
        unless $SCHWARTZ;

    my $env_sender = (Email::Address->parse($msg->header('From')))[0]->address;

    my %to = map { $_->address => 1 }
             map { Email::Address->parse($msg->header($_)) }
             qw(To Cc Bcc);
    my @rcpts = keys %to;

    my $host;
    if (@rcpts == 1) {
        $rcpts[0] =~ /(.+)@(.+)$/;
        $host = lc($2) . '@' . lc($1);
    }

    my $handle;
    eval {
        my $job = TheSchwartz::Job->new(
            funcname => 'TheSchwartz::Worker::SendEmail',
            arg      => {
                env_from => $env_sender,
                rcpts    => \@rcpts,
                data     => $msg->as_string,
            },
            coalesce => $host,
        );
        $handle = $SCHWARTZ->insert($job);
    };

    return failure "Can't create job: $@" unless !$@ && $handle;

    return success "Message sent", prop => { handle => $handle };
}

1;
__END__

=head1 NAME

Email::Send::TheSchwartz - Send Messages using TheSchwartz

=head1 SYNOPSIS

    use Email::Send;

    my $mailer = Email::Send->new({ mailer => 'TheSchwartz' });
    $mailer->mailer_args([ databases => [ ... ] ]);
    $mailer->send($message);

=head1 DESCRIPTION

This mailer for C<Email::Send> uses C<TheSchwartz> to send a message via
the Schwartz reliable messaging system. The first invocation of C<send>
requires arguments used to initialize a new C<TheSchwartz> object (a list
of databases). Subsequent calls will remember the the first setting until
it is reset.

This module is only half of the solution to sending email via TheSchwartz;
all this module does is insert email jobs into the database. The other half
of the solution comes in L<TheSchwartz::Worker::SendEmail>, a worker
class for pulling jobs from the queue in the database, and connecting to
the remote servers to send the messages.

All return values from this package are true or false. If false, sending
has failed. If true, send succeeded. The return values are C<Return::Value>
objects, however, and contain more information on just what went wrong.

A successful return value also contains more information: it contains a
handle for the job that was inserted into the database (a
C<TheSchwartz::JobHandle> object). It can be accessed like this:

    my $return = $mailer->send($message);
    if ($return) {
        my $handle = $return->prop('handle');
        ...
    }

For more information on these return values, see L<Return::Value>.

=head1 LICENSE

C<Email::Send::TheSchwartz> is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, C<Email::Send::TheSchwartz> is Copyright
2007 Six Apart, cpan@sixapart.com. All rights reserved.

=cut
