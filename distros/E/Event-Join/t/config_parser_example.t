use strict;
use warnings;
use Test::More tests => 1;

use Event::Join;

my $parsed_doc;
my $parser_state = Event::Join->new(
    events        => [qw/username password machine_name/],
    on_completion => sub { $parsed_doc = shift },
);

my @lines = (
    "password:bar\n",
    "username:foo\n",
    "machine_name:localhost\n",
);

while(!$parsed_doc && (my $line = shift @lines)){
    chomp $line;
    my ($k, $v) = split /:/, $line;
    $parser_state->send_event($k, $v);
}

is_deeply $parsed_doc, {
    username     => 'foo',
    password     => 'bar',
    machine_name => 'localhost',
}, 'doc parsed ok';
