package LiBot::Test::Handler;
use strict;
use warnings;
use utf8;
use LiBot;
use Test::More;
use re qw(is_regexp regexp_pattern);
use parent qw(Exporter);

our @EXPORT = qw(load_plugin test_message);

our $BOT = LiBot->new();

sub load_plugin {
    $BOT->load_plugin(@_);
}

sub test_message {
    my ($msg, $pattern) = @_;

    unless (ref $msg) {
        if ($msg =~ /\A<([^>]+)>\s+(.+)\z/) {
            $msg = LiBot::Message->new(
                nickname => $1,
                text     => $2,
            )
        }
    }

    $BOT->handle_message(sub {
        if (is_regexp($pattern)) {
            like($_[0], $pattern);
        } else {
            is($_[0], $pattern);
        }
    }, $msg);
}


1;
__END__

=head1 NAME

LiBot::Test::Handler - Testing utility for LiBot::Handler::*

=head1 SYNOPSIS

    use LiBot::Test::Handler;


=head1 DESCRIPTION

This module helps writing test case for LiBot.

