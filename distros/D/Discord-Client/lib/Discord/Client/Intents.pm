package Discord::Client::Intents;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.002';

# Keep Discord bit positions explicit, including gaps reserved by the protocol.
my %BITS = (
    GUILDS => 1 << 0,
    GUILD_MEMBERS => 1 << 1,
    GUILD_MODERATION => 1 << 2,
    GUILD_EXPRESSIONS => 1 << 3,
    GUILD_INTEGRATIONS => 1 << 4,
    GUILD_WEBHOOKS => 1 << 5,
    GUILD_INVITES => 1 << 6,
    GUILD_VOICE_STATES => 1 << 7,
    GUILD_PRESENCES => 1 << 8,
    GUILD_MESSAGES => 1 << 9,
    GUILD_MESSAGE_REACTIONS => 1 << 10,
    GUILD_MESSAGE_TYPING => 1 << 11,
    DIRECT_MESSAGES => 1 << 12,
    DIRECT_MESSAGE_REACTIONS => 1 << 13,
    DIRECT_MESSAGE_TYPING => 1 << 14,
    MESSAGE_CONTENT => 1 << 15,
    GUILD_SCHEDULED_EVENTS => 1 << 16,
    AUTO_MODERATION_CONFIGURATION => 1 << 20,
    AUTO_MODERATION_EXECUTION => 1 << 21,
    GUILD_MESSAGE_POLLS => 1 << 24,
    DIRECT_MESSAGE_POLLS => 1 << 25,
);

sub bits {
    my ( $class, @names ) = @_;

    # Validate names before combining their bits; repeated names remain idempotent.
    my $value = 0;
    for my $name (@names) {
        croak 'intent name must be a string' if !defined($name) || ref($name);
        croak "unknown Discord intent: $name" if !exists $BITS{$name};
        $value |= $BITS{$name};
    }
    return $value;
}

sub names { return sort keys %BITS }

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::Intents - Named Gateway intent bitmasks

=head1 SYNOPSIS

    use Discord::Client::Intents;

    # Combine named intents into a bitmask.
    my $intents = Discord::Client::Intents->bits('GUILDS', 'GUILD_MESSAGES');

=head1 DESCRIPTION

Maps L<Gateway intent names|https://docs.discord.com/developers/events/gateway#gateway-intents>
to bit values. Names are case-sensitive. Privileged intents must also be enabled
in the Developer Portal when required.

=head1 METHODS

=head2 bits

C<bits(names...)> returns the combined integer bitmask, or zero for no names.
Unknown names and non-string arguments throw.

=head2 names

Returns the supported intent names as a sorted list.

=head1 LICENSE

Apache License 2.0.

=cut
