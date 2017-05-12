use strict;
use warnings;
use Test::More tests => 2;
use Event::Join;

my $done;
my $events;
my $joiner = Event::Join->new(
    events        => [qw/foo bar baz/],
    on_event      => sub { my ($e) = @_; $events->{$e}++ },
    on_completion => sub { $done = $_[0] },
);

isa_ok $joiner, 'Event::Join';

$joiner->send_event('foo');
is $events->{foo}, 1, 'on_event callback called';
