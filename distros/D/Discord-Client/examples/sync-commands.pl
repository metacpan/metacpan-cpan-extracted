#!/usr/bin/env perl
use v5.26;
use strict;
use warnings;
use File::Spec;
use Scalar::Util qw(blessed);

# Validate deployment settings before constructing the example client.
my $guild_id = $ENV{TEST_GUILD_ID}
    or die "TEST_GUILD_ID is required for guild command deployment\n";

# Load one example's declarations without starting its Gateway connection.
my ($example) = @ARGV;
die "Usage: perl examples/sync-commands.pl EXAMPLE.pl\n"
    unless @ARGV == 1;
my $path = File::Spec->rel2abs($example);
die "Example file does not exist\n" unless -f $path;
my $bot = do $path;
die "Could not load example\n"
    unless blessed($bot) && $bot->isa('Discord::Client');

# Deployment replaces this application's commands in the selected test guild.
my $deployed = eval {
    $bot->commands->sync( scope => { guild_id => $guild_id } )->get;
    1;
};
my $deployment_error = $@;

# Close SDK resources even when deployment fails, preserving the original error.
my $closed = eval {
    $bot->close->get;
    1;
};
my $close_error = $@;
die $deployment_error unless $deployed;
die $close_error unless $closed;
