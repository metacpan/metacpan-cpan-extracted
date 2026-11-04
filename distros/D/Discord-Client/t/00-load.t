use v5.26;
use warnings;
use Test2::V1;

# Every public module must load before the application supplies credentials.
my @packages = qw(
    Discord::Client
    Discord::Client::Intents
    Discord::Client::REST
    Discord::Client::REST::Error
    Discord::Client::Gateway
    Discord::Client::Gateway::Shards
    Discord::Client::Commands
    Discord::Client::Interaction
    Discord::Client::Interactions
    Discord::Client::HTTPInteractions
    Discord::Client::Interaction::Verifier
    Discord::Client::UI
    Discord::Client::Cache
    Discord::Client::Model
    Discord::Client::Model::Message
    Discord::Client::Model::Channel
    Discord::Client::Model::Guild
    Discord::Client::Model::User
    Discord::Client::Error
);

# Do not let credentials inherited from the shell hide load-time dependencies.
local $ENV{DISCORD_BOT_TOKEN};
local $ENV{DISCORD_PUBLIC_KEY};
for my $package (@packages) {
    my $file = $package =~ s{::}{/}gr;
    T2->is( T2->dies( sub { require "$file.pm" } ), undef, "$package loads without credentials" );
}

T2->done_testing;
