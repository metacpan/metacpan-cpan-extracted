#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use LiBot;
use Getopt::Long;
use AE;
use Data::OptList;
use Pod::Usage;

my $config_file = 'config.pl';
my $help;
GetOptions(
    'c=s' => \$config_file,
    'h|help' => \$help,
) or pod2usage(1);
pod2usage(1) if $help;

my $bot = setup_bot();
my $server = $bot->run();

AE::cv->recv;

sub setup_bot {
    my $bot = LiBot->new();

    my $config = do $config_file or die "Cannot load $config_file";

    # load providers
    for (@{Data::OptList::mkopt($config->{providers})}) {
        $bot->load_provider($_->[0], $_->[1]);
    }

    # load handlers
    for (@{Data::OptList::mkopt($config->{handlers})}) {
        $bot->load_plugin('Handler', $_->[0], $_->[1]);
    }

    $bot;
}

__END__

=head1 NAME

libot.pl - The bot framework

=head1 SYNOPSIS

    % libot.pl -c config.pl

=head1 DESCRIPTION

LiBot is a pluggable lingr bot framework.

You can create your own plugins very easily.

=head1 CONFIGURATION

Here is a example configuration file for lingr bot:

    +{
        providers => [
            'Lingr' => {
                host => '127.0.0.1',
                port => 1199,
            },
        ],
        'handlers' => [
            Karma => {
                path => 'karma.bdb',
            },
            'LLEval',
            'IkachanForwarder' => {
                url => 'http://127.0.0.1:4979',
                channel => '#hiratara',
            },
            'PerldocJP',
            'URLFetcher',
            'CoreList',
        ],
    };

And you can use IRC!

    +{
        providers => [
            'IRC' => {
                server => 'chat.freenode.net',
                port => 6667,
            },
        ],
        'handlers' => [
            Karma => {
                path => 'karma.bdb',
            },
            'LLEval',
            'IkachanForwarder' => {
                url => 'http://127.0.0.1:4979',
                channel => '#hiratara',
            },
            'PerldocJP',
            'URLFetcher',
            'CoreList',
        ],
    };
