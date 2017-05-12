#!/usr/bin/perl

use strict;
use warnings;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;
use Try::Tiny;

die 'ENV TEST_USERNAME is required' unless defined $ENV{TEST_USERNAME};
die 'ENV TEST_PASSWORD is required' unless defined $ENV{TEST_PASSWORD};

my $transport = Email::Sender::Transport::SMTP::TLS->new(
    host => 'smtp.gmail.com',
    port => 587,
    username => $ENV{TEST_USERNAME},
    password => $ENV{TEST_PASSWORD},
    helo => 'fayland.me',
);

use Email::Simple::Creator; # or other Email::
my $message = Email::Simple->create(
    header => [
        From    => $ENV{TEST_USERNAME},
        To      => 'fayland@gmail.com',
        Subject => 'TEST FROM Email::Sender::Transport::SMTP::TLS',
    ],
    body => 'Email::Sender::Transport::SMTP::TLS Email::Sender::Transport::SMTP::TLS.',
);

try {
    sendmail($message, { transport => $transport });
} catch {
    die "Error sending email: $_";
};

1;