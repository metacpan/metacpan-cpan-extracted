use strict;
use Test::More qw(no_plan);

BEGIN
{
    use_ok('HTTP::Response::OnDisk');
}

my @data = (
    [ 200, "ok", { content_type => 'text/html' }, "fuga" ],
);
my @files = ();
foreach my $data (@data) {
    my $response = HTTP::Response::OnDisk->new($data->[0], $data->[1], HTTP::Headers->new(%{$data->[2]}), $data->[3]);
    ok($response);
    isa_ok($response, 'HTTP::Response::OnDisk');
    is($response->code, $data->[0]);
    is($response->message, $data->[1]);
    is($response->content, $data->[3]);

    my %headers = %{ $data->[2] };
    while (my ($method, $value) = each %headers) {
        is($response->$method, $value);
    }

    push @files, $response->storage->filename;

    undef $response;
}

foreach my $filename (@files) {
    ok(! -f $filename);
}
