package Kwiki::Notify::IRC;
use strict;
use warnings;

use lib 'lib';
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';

our $VERSION = '0.05';

const class_id    => 'notify_irc';
const class_title => 'Kwiki page edit notification via IRC';
const config_file => 'notify_irc.yaml';

sub register {
    my $registry = shift;
    $registry->add( hook => 'page:store', post => 'update' );
}

sub update {
    no warnings 'once';    # i use package variables below
    require POE::Component::IKC::ClientLite;
    my $remote = POE::Component::IKC::ClientLite::create_ikc_client(
        port    => $self->hub->config->notify_irc_daemon_port,
        ip      => $self->hub->config->notify_irc_daemon_host,
        name    => "Kwiki$$",
        timeout => 5,
        )
        or die $POE::Component::IKC::ClientLite::error;
    my $page = $self->pages->current;
    $page->title;
    $remote->post( 'notify_irc/update', $page );
}

__DATA__

=head1 NAME 

Kwiki::Notify::IRC - announce updates to your Kwiki on IRC channels

=head1 SYNOPSIS

 $ cd /path/to/kwiki
 $ kwiki -add Kwiki::Notify::IRC
 $ cat config/notify_irc.yaml >> config.yaml
 $ edit config.yaml
 $ perl notify-irc.pl

=head1 DESCRIPTION

This module allows you to notify your IRC channel(s) of updates to Kwik pages. The bot will announce what page was updated and by whom.

The module provides a F<notify-irc.pl> script that acts as a combination update daemon and IRC bot. This script must be run from your Kwiki installation directory.

=head2 Configuration Directives

=over 4

=item * notify_irc_daemon_host

=item * notify_irc_daemon_port

Defines the host and port that will be used for the IRC daemon. The defaults should be fine if you're running your Kwiki and F<notify_irc.pl> on the same machine.

=item * notify_irc_nickname

=item * notify_irc_ircname

Name settings. Note that the username is not configurable -- instead, it is set to the C<USER> environment variable.

=item * notify_irc_server_host

=item * notify_irc_server_port

What IRC server to connect to.

=item * notify_irc_server_channels

A comma-delimited list of channels to connect to.

=back

=head1 AUTHORS

Ian Langworth <ian@cpan.org>

=head1 SEE ALSO

L<Kwiki>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__config/notify_irc.yaml__
notify_irc_daemon_host:     localhost
notify_irc_daemon_port:     17212
notify_irc_nickname:        kwiki
notify_irc_ircname:         www.kwiki.org
notify_irc_server_host:     irc.example.net
notify_irc_server_port:     6667
notify_irc_server_channels: kwikibot, kwiki

__notify-irc.pl__
#!/usr/bin/perl
use warnings;
use strict;

use POE qw(
    Session
    Component::IRC
    Component::IKC::Server
    Component::IKC::Specifier
    );

use Term::ANSIColor qw(:constants);
sub msg (@) { print GREEN, BOLD, " * ", RESET, "@_\n" }
sub err (@) { print RED,   BOLD, " * ", RESET, "@_\n" }

msg 'loading configuration';
require YAML;
my $config = {
    %{ YAML::LoadFile('config/notify_irc.yaml') || {} },
    %{ YAML::LoadFile('config.yaml')            || {} },
};

msg 'creating daemon component';
POE::Component::IKC::Server->spawn(
    port => $config->{notify_irc_daemon_port},
    name => 'NotifyIRCBot',
);

msg 'creating irc component';
POE::Component::IRC->new('bot')
    or die "Couldn't create IRC POE session: $!";

msg 'creating kernel session';
POE::Session->create(
    inline_states => {
        _start           => \&bot_start,
        _stop            => \&bot_stop,
        irc_001          => \&bot_connected,
        irc_372          => \&bot_motd,
        irc_disconnected => \&bot_reconnect,
        irc_error        => \&bot_reconnect,
        irc_socketerr    => \&bot_reconnect,
        autoping         => \&bot_do_autoping,
        update           => \&update,
        _default         => $ENV{DEBUG} ? \&bot_default : sub { },
    }
);

msg 'starting the kernel';
POE::Kernel->run();
msg 'exiting';
exit 0;

sub bot_default
{
    my ( $event, $args ) = @_[ ARG0 .. $#_ ];
    err "unhandled $event";
    err "  - $_" foreach @$args;
    return 0;
}

sub update
{
    my ( $kernel, $heap, $page ) = @_[ KERNEL, HEAP, ARG0 ];
    eval {
        my $msg = sprintf( 'action update: %s by %s',
            $page->{title}, $page->{metadata}{edit_by} );
        $kernel->post( bot => ctcp => "#$_", $msg )
            foreach split /,\s+/, $config->{notify_irc_server_channels};
        msg sprintf( "$msg on %s", scalar localtime(time) );
    };
    err "update error: $@" if $@;
}

sub bot_start
{
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    msg "starting irc session";
    $kernel->alias_set('notify_irc');
    $kernel->call( IKC => publish => notify_irc => ['update'] );
    $kernel->post( bot => register => 'all' );
    $kernel->post(
        bot => connect => {
            Nick     => $config->{notify_irc_nickname},
            Ircname  => $config->{notify_irc_ircname},
            Username => $ENV{USER},
            Server   => $config->{notify_irc_server_host},
            Port     => $config->{notify_irc_server_port},
        }
    );
}

sub bot_stop
{
    msg "stopping bot";
}

sub bot_connected
{
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    foreach ( split /,\s+/, $config->{notify_irc_server_channels} )
    {
        msg "joining channel #$_";
        $kernel->post( bot => join => "#$_" );
    }
}

sub bot_motd
{
    msg '[motd] ' . $_[ARG1];
}

sub bot_do_autoping
{
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    $kernel->post( bot => userhost => $config->{notify_irc_nickname} )
        unless $heap->{seen_traffic};
    $heap->{seen_traffic} = 0;
    $kernel->delay( autoping => 300 );
}

sub bot_reconnect
{
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    err "reconnect: " . $_[ARG0];
    $kernel->delay( autoping => undef );
    $kernel->delay( connect  => 60 );
}

