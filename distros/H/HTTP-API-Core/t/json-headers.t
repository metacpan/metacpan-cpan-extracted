use strict;
use warnings;
use Test::More;

use HTTP::API::Core;

my @seen;
my $transport = sub {
    my ($method, $url, $opts) = @_;
    push @seen, { %{ $opts->{headers} } };
    return { status => 200, reason => 'OK', headers => {}, content => '{}' };
};

my $defaults = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    headers => {
        'Content-Type' => 'application/vnd.example+json',
        'Accept'       => 'application/vnd.example+json',
    },
    transport => $transport,
);
$defaults->post('/items', json => { ok => 1 });
is $seen[-1]{'Content-Type'}, 'application/vnd.example+json', 'client Content-Type wins over JSON default';
is $seen[-1]{Accept}, 'application/vnd.example+json', 'client Accept wins over JSON default';
ok !exists($seen[-1]{'content-type'}), 'does not add duplicate lowercase content-type';
ok !exists($seen[-1]{accept}), 'does not add duplicate lowercase accept';

my $request = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    transport => $transport,
);
$request->post('/items',
    headers => {
        'CONTENT-TYPE' => 'application/problem+json',
        'ACCEPT'       => 'application/problem+json',
    },
    json => { ok => 1 },
);
is $seen[-1]{'CONTENT-TYPE'}, 'application/problem+json', 'request Content-Type wins regardless of case';
is $seen[-1]{ACCEPT}, 'application/problem+json', 'request Accept wins regardless of case';
ok !exists($seen[-1]{'content-type'}), 'request does not gain duplicate content-type';
ok !exists($seen[-1]{accept}), 'request does not gain duplicate accept';

$request->post('/items', json => { ok => 1 });
is $seen[-1]{'content-type'}, 'application/json', 'JSON Content-Type still defaults when absent';
is $seen[-1]{accept}, 'application/json', 'JSON Accept still defaults when absent';

done_testing;
