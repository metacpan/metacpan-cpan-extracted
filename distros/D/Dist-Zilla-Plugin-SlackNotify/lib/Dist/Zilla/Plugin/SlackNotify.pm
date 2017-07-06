use strict;
use warnings;
package Dist::Zilla::Plugin::SlackNotify;
$Dist::Zilla::Plugin::SlackNotify::VERSION = '0.003';
# ABSTRACT: Publish a notification on Slack after release

use Moose;
with 'Dist::Zilla::Role::AfterRelease';

use JSON;
use LWP::UserAgent;
use Dist::Zilla::Plugin::EmailNotify;

use namespace::autoclean;

has webhook_url => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_webhook_url',
);

has channel => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    predicate => 'has_channel',
);

has username => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_username',
);

has icon_url => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_icon_url',
    clearer   => 'clear_icon_url',
);

has icon_emoji => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_icon_emoji',
);

has message => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,
);

sub mvp_multivalue_args { qw/channel/ }

sub after_release {
    my $self = shift;

    unless ( $self->has_webhook_url ) {
        $self->log( "No webhook_url configured, no notification sent" );
        return 1;
    }

    if ( $self->has_icon_url && $self->has_icon_emoji ) {
        $self->clear_icon_url;
        $self->log( "Both icon_url and icon_emoji set, will use icon_url" );
    }

    my $ua = LWP::UserAgent->new;
    my $res;
    for ( @{ $self->channel || [ undef ] } ) {
        my %payload;
        $payload{channel}    = $_ if $self->has_channel;
        $payload{username}   = $self->username if $self->has_username;
        $payload{icon_url}   = $self->icon_url if $self->has_icon_url;
        $payload{icon_emoji} = $self->icon_emoji if $self->has_icon_emoji;
        $payload{text}       = $self->message;

        $res = $ua->post( $self->webhook_url,
            'Content-Type' => 'application/json',
            Content        => encode_json( \%payload ),
        );
    }

    return $res->is_success;
}

sub _build_message {
    my $self = shift;

    my @message;

    my $name    = $self->zilla->name;
    my $version = $self->zilla->version;
    my $user    = $ENV{USER} ? "`$ENV{USER}`" : 'An unknown user';

    push @message, sprintf( "%s has released version %s of %s", $user, $version, $name );
    push @message, '';

    push @message, 'Changes:';
    push @message, map { "> $_" } $self->Dist::Zilla::Plugin::EmailNotify::extract_last_release( 'Changes' );
    push @message, '';

    my $res = $self->zilla->distmeta || die "Internal error";
    push @message, sprintf( "Homepage: %s", $res->{homepage} ) if $res->{homepage};

    my $repo = $res->{repository};
    push @message, sprintf( "Repository: %s", $repo->{web} ) if $repo->{web};

    push @message, '';
    push @message, "Authors:";
    push @message, map { "  - $_" } @{ $self->zilla->authors };

    return join( "\n", @message );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::SlackNotify - Publish a notification on Slack after release

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This plugin is for notifying a Slack channel that a release has gone out. Please
configure an Incoming WebHook in your organization's Slack Custom Integrations.

L<https://teamname.slack.com/apps/manage/custom-integrations>

=head1 ATTRIBUTES

=head2 webhook_url

The full webhook url from Slack

    [SlackNotify]
    webhook_url = https://hooks.slack.com/services/ABC123ZYX/098DEF456/wVu765GhI789TsR432jKl012

=head2 channel

The channel or direct message used to notify. May list several times to notify
multiple channels. Slack Incoming Webhooks should be configured with a default
channel; thererfore, this is an optional attribute.

    [SlackNotify]
    channel = #general
    channel = @username

=head2 username

The username to use instead of the default one confgured.

    [SlackNotify]
    username = me

=head2 icon_url

The icon_url to use instead of the default one confgured.

    [SlackNotify]
    icon_url = https://en.gravatar.com/userimage/10000000/abcdef1234567890abcdef1234567890.jpg

=head2 icon_emoji

The icon_emoji to use instead of the default one confgured.

    [SlackNotify]
    icon_emoji = :punch:

=head1 METHODS/SUBROUTINES

=head2 after_release

Method to publish notification on Slack right after the 'release' process.

=head2 mvp_multivalue_args
Internal, L<Config::MVP> related. Creates a multivalue argument.

=head2 _build_message

Custom message for notification of release. To utilize this, this Moose class
should be subclassed and this method overwritten.

    package Dist::Zilla::Plugin::MySlackNotify;
    use Moose;
    extends 'Dist::Zilla::Plugin::SlackNotify;'
    sub _build_message {
        my $self = shift;
        return "Something has been released!";
    }

=head1 CREDITS

This module is a rip off of L<Dist::Zilla::Plugin::EmailNotify>. I even directly
use an internal method from it. Thanks Sawyer X!

=head1 AUTHOR

Steven Leung <stvleung@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Steven Leung.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
