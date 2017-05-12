use Test::Most;

use Class::Load;
use Path::Tiny;

use CHI;
my $chi = CHI->new(driver => 'Memory', global => 1);

my @children = path("./lib/Google/Client")->children;

foreach my $child ( @children ) {
    next if $child->is_dir;
    my $basename = $child->basename('.pm');
    next if $basename eq 'Collection'; # Don't want to test the collection.
    my $client = "Google::Client::".$basename;
    my ($class_loaded, $error) = Class::Load::try_load_class($client);
    ok $class_loaded, "loaded client: $client";
    ok $client = $client->new(
        cache => $chi,
        cache_key => $basename . '-test-key'
    ), 'instantiated client';
    foreach my $role (qw/Google::Client::Role::FurlAgent Google::Client::Role::Token/) {
        ok $client->does($role), "$client implements $role";
    }
}

done_testing;
