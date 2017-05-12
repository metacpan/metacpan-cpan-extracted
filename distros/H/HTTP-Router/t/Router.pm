package t::Router;

use Exporter 'import';
use Test::MockObject;

our @EXPORT = qw(create_request);

sub create_request {
    my $params = shift;
    my $req = Test::MockObject->new;
    while (my ($name, $value) = each %$params) {
        $req->set_always($name, $value);
    }
    $req;
}

1;
