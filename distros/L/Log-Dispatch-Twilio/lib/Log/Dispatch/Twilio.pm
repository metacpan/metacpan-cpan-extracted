package Log::Dispatch::Twilio;

use strict;
use warnings;
use base qw(Log::Dispatch::Output);
use HTTP::Status qw(:is);
use List::Util qw(min);
use POSIX qw(ceil);
use WWW::Twilio::API;

our $VERSION = '0.02';
our $MAX_TWILIO_LENGTH = 160;   # max length of SMS message allowed by Twilio

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = bless {}, $class;
    $self->_basic_init(@_);
    $self->_twilio_init(@_);
    return $self;
}

sub _twilio_init {
    my $self = shift;
    my %args = @_;

    # Grab and store required Twilio specific parameters
    foreach my $p (qw( account_sid auth_token from to )) {
        unless ($args{$p}) {
            die __PACKAGE__ . " requires '$p' parameter.\n";
        }
        $self->{$p} = $args{$p};
    }

    # Additional parameters
    my $max = $args{max_messages} || 1;
    if ($max <= 0) {
        die __PACKAGE__ . " requires 'max_messages' to be >= 1.\n";
    }
    $self->{max_messages} = $max;
}

sub log_message {
    my $self = shift;
    my %msg  = @_;

    my $twilio = WWW::Twilio::API->new(
        AccountSid => $self->{account_sid},
        AuthToken  => $self->{auth_token},
    );

    my @to_send = $self->_expand_message($msg{message});
    foreach my $entry (@to_send) {
        my $res = $twilio->POST('SMS/Messages',
            From => $self->{from},
            To   => $self->{to},
            Body => $entry,
        );

        unless ($res) {
            warn "Unable to send log message via Twilio; $!\n";
        }

        unless (is_success($res->{code})) {
            warn "Failed to send log message via Twilio; "
                . $res->{content} . "\n";
        }
    }
}

sub _expand_message {
    my $self = shift;
    my $msg  = shift;
    my $max  = $self->{max_messages};
    my @results;

    # If its a long message, *and* we're configured for multiple messages,
    # generate multiple messages.
    my $msg_length = length($msg);
    if (($max > 1) && ($msg_length > $MAX_TWILIO_LENGTH)) {
        # Figure out how many messages we're actually going to generate
        my $max_prefix_length = length("$max/$max: ");
        my $how_much          = $MAX_TWILIO_LENGTH - $max_prefix_length;
        my $num_messages      = min($max, ceil($msg_length / $how_much));

        # Create entries w/prefixes
        for my $idx (1 .. $max) {
            my $prefix = "$idx/$max: ";
            my $entry = substr($msg, 0, $how_much, '');
            $entry =~ s{^\s+|\s+$}{}g;  # trim leading/trailing ws
            push @results, $prefix . $entry;
        }
    }
    # Otherwise, its just a single message.
    else {
        my $entry = substr($msg, 0, $MAX_TWILIO_LENGTH, '');
        $entry =~ s{^\s+|\s+$}{}g;  # trim leading/trailing ws
        push @results, $entry;
    }

    return @results;
}

1;

=head1 NAME

Log::Dispatch::Twilio - Log output via Twilio SMS Message

=head1 SYNOPSIS

  use Log::Dispatch;

  my $logger = Log::Dispatch->new(
      outputs => [
          [ 'Twilio,
            min_level   => 'emergency',
            account_sid => '<your-twilio-account-sid>',
            auth_token  => '<your-twilio-auth-token>',
            from        => '<number-to-send-msg-from>',
            to          => '<number-to-send-msg-to>',
          ],
      ],
  );

=head1 DESCRIPTION

This module provides a C<Log::Dispatch> output that sends log messages via
Twilio.

While you probably don't want I<every> logged message from your application to
go out via Twilio, I find it particularly useful to set it up as part of my
C<Log::Dispatch> configuration for critical/emergency errors.  In the event
that something dire happens, I'll receive an SMS message through Twilio right
away.

=head2 Required Options

When adding Twilio output to your L<Log::Dispatch> configuration, the following
options are required:

=over

=item account_sid

Your Twilio "Account Sid".

=item auth_token

Your Twilio "Auth Token".

=item from

The telephone number from which the SMS messages will appear to be sent from.

This number must be a number attached to your Twilio account.

=item to

The telephone number to which the SMS messages will be sent to.

=back

=head2 Additional Options

=over

=item max_messages (default 1)

Maximum number of SMS messages that can be generated from a single logged
item.  Defaults to 1.

=back

=head1 METHODS

=over

=item new

Constructor.

Implemented as per the L<Log::Dispatch::Output> interface.

=item log_message

Logs message, by sending it as an SMS message to the configured number via the
Twilio API.

Implemented as per the L<Log::Dispatch::Output> interface.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2012, Graham TerMarsch.  All Rights Reserved.

This is free software, you can redistribute it and/or modify it under the
Artistic-2.0 license.

=head1 SEE ALSO

L<Log::Dispatch>,
L<http://www.twilio.com/>.

=cut
