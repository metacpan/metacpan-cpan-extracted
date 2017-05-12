use strict;
use Test::More;

use CGI;
use FormValidator::Simple;
FormValidator::Simple->import('NetAddr::MAC');

my $type = "NETADDR_MAC";

my $req = CGI->new;

my $checker = sub {
    my $mac = shift;

    $req->param( mac => $mac );

    my $result = FormValidator::Simple->check( $req => [
        mac => [ 'NOT_BLANK', $type ],
    ] );

    return $result->invalid('mac');
};

subtest 'positive' => sub {
    my $data = <<"";
10-00-5A-4D-BC-96
10-00-5a-4d-bc-96
10:00:5A:4D:BC:96
10005A4DBC96
1,6,10:00:5A:4D:BC:96
1000.5A4D.BC96
10-00-5A-4D-BC-96

    ok ! $checker->( $_ ), $_ for split /\n/o, $data;
};

subtest 'negative' => sub {
    my $data = <<"";
11:22:33:44:xx:55
1:1
11:22:33
192.168.0.1
blah

    is $checker->( $_ )->[0], $type, $_ for split /\n/o, $data;
};

done_testing;

__END__
