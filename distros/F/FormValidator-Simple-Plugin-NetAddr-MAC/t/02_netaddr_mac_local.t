use strict;
use Test::More;

use CGI;
use FormValidator::Simple;
FormValidator::Simple->import('NetAddr::MAC');

my $type = "NETADDR_MAC_LOCAL";

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
02aa.bbcc.2233
02aabbcc2233
02-aa-bb-cc-22-33
03:aa:cc:12:33:56
03aacc123356
02aa.bbcc.2233.abcd
02aabbcc2233abcd
02-aa-bb-cc-22-33-aa-bb
03:aa:cc:12:33:56:ab:cd
03aacc123356aadd

    ok ! $checker->( $_ ), $_ for split /\n/o, $data;
};

subtest 'negative' => sub {
    my $data = <<"";
00aa.bbcc.2233
00aabbcc2233
01-aa-bb-cc-22-33
00:aa:cc:12:33:56
00aacc123356
00aa.bbcc.2233.abcd
00aabbcc2233abcd
01-aa-bb-cc-22-33-aa-bb
00:aa:cc:12:33:56:ab:cd
00aacc123356aadd
11:22:33:44:xx:55
1:1
11:22:33
192.168.0.1
blah

    is $checker->( $_ )->[0], $type, $_ for split /\n/o, $data;
};

done_testing;

__END__
