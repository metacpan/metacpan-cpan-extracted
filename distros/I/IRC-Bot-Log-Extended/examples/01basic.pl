#!/usr/bin/perl -w

package IRC::Bot2;

use Moose;
extends 'IRC::Bot';
use IRC::Bot::Log::Extended;

after 'bot_start' => sub {
    my $self = shift;

    no warnings; 
    $IRC::Bot::log =  IRC::Bot::Log::Extended->new(
        Path          => $self->{'LogPath'},
        split_channel => 1,
        split_day     => 1,
    );
};

package main;

# Initialize new object
my $bot = IRC::Bot2->new(
    Debug    => 0,
    Nick     => 'Fayland_logger',
    Server   => 'irc.perl.org',
    Password => '',
    Port     => '6667',
    Username => 'Fayland_Logger',
    Ircname  => 'Fayland_Logger',
    Channels => [ '#moose', '#catalyst', '#dbix-class', '#tt' ],
    LogPath  => '/home/fayland/root/irclog/',
    NSPass   => 'nickservpass'
);

# Daemonize process
$bot->daemon();

# Run the bot
$bot->run();

1;