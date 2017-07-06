# DESCRIPTION

This plugin is for notifying a Slack channel that a release has gone out. Please
configure an Incoming WebHook in your organization's Slack Custom Integrations.

[https://teamname.slack.com/apps/manage/custom-integrations](https://teamname.slack.com/apps/manage/custom-integrations)

# ATTRIBUTES

## webhook\_url

The full webhook url from Slack

    [SlackNotify]
    webhook_url = https://hooks.slack.com/services/ABC123ZYX/098DEF456/wVu765GhI789TsR432jKl012

## channel

The channel or direct message used to notify. May list several times to notify
multiple channels. Slack Incoming Webhooks should be configured with a default
channel; thererfore, this is an optional attribute.

    [SlackNotify]
    channel = #general
    channel = @username

## username

The username to use instead of the default one confgured.

    [SlackNotify]
    username = me

## icon\_url

The icon\_url to use instead of the default one confgured.

    [SlackNotify]
    icon_url = https://en.gravatar.com/userimage/10000000/abcdef1234567890abcdef1234567890.jpg

## icon\_emoji

The icon\_emoji to use instead of the default one confgured.

    [SlackNotify]
    icon_emoji = :punch:

# METHODS/SUBROUTINES

## after\_release

Method to publish notification on Slack right after the 'release' process.

## mvp\_multivalue\_args
Internal, [Config::MVP](https://metacpan.org/pod/Config::MVP) related. Creates a multivalue argument.

## \_build\_message

Custom message for notification of release. To utilize this, this Moose class
should be subclassed and this method overwritten.

    package Dist::Zilla::Plugin::MySlackNotify;
    use Moose;
    extends 'Dist::Zilla::Plugin::SlackNotify;'
    sub _build_message {
        my $self = shift;
        return "Something has been released!";
    }

# CREDITS

This module is a rip off of [Dist::Zilla::Plugin::EmailNotify](https://metacpan.org/pod/Dist::Zilla::Plugin::EmailNotify). I even directly
use an internal method from it. Thanks Sawyer X!
