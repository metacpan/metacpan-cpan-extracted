#!/usr/bin/perl -w

package IRC::Bot::Log2;

use Moose;
extends 'IRC::Bot::Log::Extended';

augment pre_insert => sub {
    my ($self, $file_ref, $message_ref) = @_;
    
    # skip "[#catalyst 00:42] JOIN: Fayland"
    if ( $$message_ref =~ /\s+JOIN\:\s+(\S+)$/ ) {
        $$message_ref = '';
    }
    # skip "[#catalyst 03:33] Action: *GumbyNET2 cpan.testers: FAIL Catalyst-View-Jemplate-0.06 i386-linux-thread-multi 2.4.21-27.0.2.elsmp perl-5.8.6 fayland@gmail.com ("Fayland Lam") #2416326"
    if ( $$message_ref =~ /\s+cpan\.testers\:\s+FAIL/ ) {
        $$message_ref = '';
    }
};

package IRC::Bot2;

use Moose;
extends 'IRC::Bot';

after 'bot_start' => sub {
    my $self = shift;

    no warnings; 
    $IRC::Bot::log =  IRC::Bot::Log2->new(
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
    Channels => [ '#fayland' ],
    LogPath  => '/home/fayland/root/irclog/',
    NSPass   => 'nickservpass'
);

# Daemonize process
$bot->daemon();

# Run the bot
$bot->run();

1;
