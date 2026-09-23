#!/usr/bin/env perl
# 03-list-chats.pl - load the chat list and print id and title of each chat
#
# Demonstrates: load_chats() paged until TDLib reports the list exhausted,
# chats collected through on_chat, and titles read back from the chat()
# cache. Uses the session created by 01-login.pl. A user account only:
# TDLib refuses to load a chat list for a bot.
#
# The database directory (default ./tdlib-db) holds the session: it is
# exactly as sensitive as a password.
#
# Environment:
#   TD_API_ID, TD_API_HASH  application credentials from https://my.telegram.org
#   TD_PHONE                phone number in international format
#   TD_DATABASE_DIRECTORY   optional, default ./tdlib-db
#
# Run: perl eg/03-list-chats.pl   (add -Mblib to run from a built checkout)

use strict;
use warnings;
use EV;
use EV::Telegram::TDLib;

sub env_or_die {
    my ($name, $hint) = @_;
    return $ENV{$name} // die "missing environment variable $name ($hint)\n";
}

my %seen;
my $td = EV::Telegram::TDLib->new(
    api_id             => env_or_die('TD_API_ID', 'api_id from https://my.telegram.org'),
    api_hash           => env_or_die('TD_API_HASH', 'api_hash from https://my.telegram.org'),
    database_directory => $ENV{TD_DATABASE_DIRECTORY} // 'tdlib-db',
    phone_number       => env_or_die('TD_PHONE', 'phone number in international format'),
    on_code            => sub {
        my ($info, $submit) = @_;
        print "code from Telegram: ";
        chomp(my $code = <STDIN>);
        $submit->($code);
    },
    on_chat  => sub { $seen{ $_[0]{id} } = 1 },
    on_error => sub { warn "tdlib: $_[0]\n" },
);

# a die inside a callback is contained and reported, not propagated, so it
# would leave the loop running and the script hanging: break out instead
my $status = 0;
sub fail {
    my ($what, $err) = @_;
    warn "$what: $err->{message}\n";
    $status = 1;
    EV::break;
    return 1;
}

$td->login(sub {
    my (undef, $err) = @_;
    return fail('login failed', $err) if $err;
    my $load;
    $load = sub {
        $td->load_chats(100, sub {
            my ($res, $err) = @_;
            return fail('load_chats failed', $err) if $err;
            return $load->() if $res;
            for my $id (sort { $a <=> $b } keys %seen) {
                my $chat = $td->chat($id) or next;
                printf "%d\t%s\n", $chat->{id}, $chat->{title};
            }
            $td->close(sub { EV::break });
        });
    };
    $load->();
});

EV::run;
exit $status;
