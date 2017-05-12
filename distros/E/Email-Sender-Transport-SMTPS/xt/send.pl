#!/usr/bin/perl

use strict;
use warnings;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTPS;
use Try::Tiny;

die 'ENV TEST_USERNAME is required' unless defined $ENV{TEST_USERNAME};
die 'ENV TEST_PASSWORD is required' unless defined $ENV{TEST_PASSWORD};

my $transport = Email::Sender::Transport::SMTPS->new(
    host => 'smtp.gmail.com',
    ssl  => 'starttls',
    sasl_username => $ENV{TEST_USERNAME},
    sasl_password => $ENV{TEST_PASSWORD},
    debug => 1
);

use Email::Simple::Creator;    # or other Email::
my $message = Email::Simple->create(
    header => [
        From    => $ENV{TEST_USERNAME},
        To      => 'fayland@gmail.com',
        Subject => 'TEST FROM Email::Sender::Transport::SMTPS',
    ],
    body => 'Email::Sender::Transport::SMTPS Email::Sender::Transport::SMTPS.',
);

try {
    sendmail( $message, { transport => $transport } );
}
catch {
    die "Error sending email: $_";
};

1;