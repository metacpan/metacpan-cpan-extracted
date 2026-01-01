package IPC::Manager::Message;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;
use Time::HiRes qw/time/;
use Scalar::Util qw/blessed/;
use Test2::Util::UUID qw/gen_uuid/;

use Object::HashBase qw{
    <from
    <to
    <broadcast
    <stamp
    <id
    <content
};

sub init {
    my $self = shift;

    croak "'from' is a required attribute"    unless $self->{+FROM};
    croak "'content' is a required attribute" unless defined $self->{+CONTENT};

    croak "Message must either have a 'to' or 'broadcast' attribute" unless $self->{+TO} || $self->{+BROADCAST};

    $self->{+ID}    //= gen_uuid();
    $self->{+STAMP} //= time;
}

sub is_terminate {
    my $self = shift;

    my $content = $self->{+CONTENT} or return 0;
    return 0 unless ref($content) eq 'HASH';
    return 1 if $content->{terminate};
    return 0;
}

sub TO_JSON { +{%{$_[0]}} }

sub clone {
    my $self   = shift;
    my %params = @_;
    my $copy   = {%$self};
    delete $copy->{+ID};
    $copy = {%$copy, %params};
    return blessed($self)->new($copy);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Message - Messages sent between clients.

=head1 DESCRIPTION

This encapsulates messages sent between clients.

=head1 SYNOPSIS

    use IPC::Manager::Message;

    my $msg = IPC::Manager::Message->new(
        from      => 'con1',                 # No default, required
        to        => 'con2',                 # No default, required unless broadcast is true
        broadcast => 0,                      # Default 0
        stamp     => Time::HiRes::time(),    # Default to now
        id        => gen_uuid(),             # Default: new uuid
        content   => {hello => 'world'},     # No default, required
    );

Most of the time you will be using the send_message() interface to produce
these:

    $from_client->send_message($to_client => $content);

=head1 METHODS

=over 4

=item $client_name = $msg->from

Get the name of the 'from' client.

=item $client_name = $msg->to

Get the name of the 'to' client. May be undefined on broadcast messages.

=item $bool = $msg->broadcast

True if the message is/was intended for broadcast.

=item $stamp = $msg->stamp

Timestamp of the message.

=item $string = $msg->id

Message ID. If none was provided a new UUID is used.

=item $content = $msg->content

Message content. Should be a hashref or arrayref.

=item $bool = $msg->is_terminate

True if this is a termination message as sent when an L<IPC::Manager::Spawn> is
cleaning up an instance.

=item $content = $msg->TO_JSON

Used to turn the message into a raw hashref for JSON serialization.

=item $copy = $msg->clone(%overrides)

Create a copy of the message with a new ID, and any overrides specified.

=back

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
