use strict;
use Test::More;

BEGIN
{
    eval "use DBD::SQLite; use IO::String; use XML::LibXML";
    if ($@) {
        plan(skip_all => "XML::LibXML, IO::String, or DBD::SQLite not installed");
    } else {
        plan(tests => 8);
    }

    use_ok("Gungho::Plugin::Statistics::Storage::SQLite");
    use_ok("Gungho::Plugin::Statistics::Format::XML");
}

my $storage = Gungho::Plugin::Statistics::Storage::SQLite->new();
$storage->setup;

for(1..10) {
    $storage->incr("active_requests");
}

is($storage->get("active_requests"), 10);

for(1..5) {
    $storage->decr("active_requests");
    $storage->incr("finished_requests");
}

is($storage->get("active_requests"), 5);
is($storage->get("finished_requests"), 5);

my $buf = '';
my $io = IO::String->new(\$buf);
my $format = Gungho::Plugin::Statistics::Format::XML->new();
$format->format($storage, $io);

ok($buf);
like($buf, qr{<ActiveRequests>5</ActiveRequests>});
like($buf, qr{<FinishedRequests>5</FinishedRequests>});

1;