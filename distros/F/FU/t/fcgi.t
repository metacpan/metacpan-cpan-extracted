use v5.36;
use Test::More;
use IO::Socket qw/AF_UNIX SOCK_STREAM PF_UNSPEC/;
use FU::XS;

my($f, $local, $remote);

sub start {
    ($local, $remote) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC);
    $f = FU::fcgi::new(fileno $local, 123);
}

sub record($id, $type, $data, $pad=undef) {
    $pad //= rand > 0.5 ? int rand(50) : 0;
    my $msg = pack('CCnnCC', 1, $type, $id, length($data), $pad, 0) . $data . ("\0"x$pad);
    die "Short write" if $remote->syswrite($msg, length($msg)) != length($msg);
}

sub begin($id=1, $role=1, $keep=0) {
    record $id, 1, "\0".chr($role).($keep?"\1":"\0")."\0\0\0\0\0"
}

sub iserr($code) {
    is $f->read_req({}, {}), $code;
}

sub isrec($hdr, $par, $code=0) {
    is $f->read_req(my $rhdr = {}, my $rpar = {}), $code;
    is_deeply $rhdr, $hdr;
    is_deeply $rpar, $par;
}

sub isrecv($data) {
    my($buf, $off) = ('', 0);
    $off += $remote->sysread($buf, length($data) - $off, $off) while $off < length $data;
    is $buf, $data;
}


start;
$remote->close;
iserr -7;

start;
begin;
$remote->close;
iserr -1;

start;
is $remote->syswrite("\0\0\0\0\0\0\0\0", 8), 8;
iserr -3;

start;
begin 1, 2;
record 1, 4, "";

start;
begin 3, 2, 1;
begin 1, 1, 1;
begin 2, 1, 1;
record 1, 4, "";
record 0, 10, "";
record 1, 5, "";
isrec {}, {body => ''};
isrecv "\1\3\0\3\0\x08\0\0"."\0\0\0\0\3\0\0\0"; # end request 3, unknown role
isrecv "\1\3\0\2\0\x08\0\0"."\0\0\0\0\1\0\0\0"; # end request 2, can't multiplex
isrecv "\1\x0b\0\0\0\x08\0\0"."\x0a\0\0\0\0\0\0\0"; # unknown type, 10

start;
begin;
record 1, 4, "\x0e\2C";
record 1, 4, "ONTENT_";
record 1, 4, "LENGTH";
record 1, 4, "1";
record 1, 4, "2\x80\x00";
record 1, 4, "\x00\x09";
record 1, 4, "\x80";
record 1, 4, "\x00\x00";
record 1, 4, "\x04HTTP_H_S";
record 1, 4, "T";
record 1, 4, "tes";
record 1, 4, "t";
record 1, 4, "";
record 1, 5, "012";
record 1, 5, "34567890";
record 1, 5, "1";
record 1, 5, "";
isrec {'content-length',12, 'h-st' => 'test'}, {body => '012345678901'};

start;
begin 5, 1, 1;
record 5, 4, "\x0e\x01CONTENT_LENGTH5\x0c\x05CONTENT_TYPEtext/";
record 5, 4, "\x0b\x04REMOTE_ADDRaddr\x0c\x05QUERY_STRINGquery";
record 5, 4, "\x0e\x04REQUEST_METHODPOST\x0b\x06REQUEST_URI/p\x81t\x55/";
record 5, 4, "";
record 5, 5, "hello";
record 5, 5, "";
isrec
    { 'content-length', 5, 'content-type', 'text/' },
    { ip => 'addr', body => 'hello', qs => 'query', path => "/p\x81t\x55/", method => 'POST' };
$f->print("Status: 200\r\n");
$f->print("Something else");
$f->flush;
isrecv "\1\6\0\5\0\x1b\0\0"."Status: 200\r\nSomething else";
isrecv "\1\6\0\5\0\0\0\0";
isrecv "\1\3\0\5\0\x08\0\0"."\0\0\0\0\0\0\0\0";
# Same connection:
begin;
record 1, 4, "\x00\x00\x06\x00HTTP_x\x00\x00";
record 1, 4, "";
record 1, 5, "";
isrec { x => '' }, { body => ''};

start;
begin;
record 1, 4, "\x40\x01this is too short";
record 1, 4, "";
iserr -3;

start;
begin;
record 1, 4, "\x01\x40this is too short";
record 1, 4, "";
iserr -3;

start;
begin;
record 1, 5, "";
iserr -3;

start;
begin;
record 1, 4, "\x0e\x03CONTENT_LENGTH123";
record 1, 4, "";
record 1, 5, "too short";
record 1, 5, "";
isrec {'content-length',123}, {body=>'too short'}, -6;

start;
begin;
record 1, 4, "\x0e\x00CONTENT_LENGTH";
record 1, 4, "";
record 1, 5, "";
isrec {'content-length',''}, {body=>''};

start;
begin;
record 1, 4, "\x80\x00\x01\x00\x00".('A'x256);
iserr -4;

start;
begin;
record 1, 4, "\x01\x80\x01\x00\x00".('A'x256);
iserr -4;

start;
begin;
record 1, 4, "";
record 0, 9, "\x0d\0FCGI_MAX_REQS\x0e\0FCGI_MAX_CONNS\2\3hi987\x0f\0FCGI_MPXS_CONNS";
record 1, 5, "";
isrec {}, {body => ''};
isrecv "\1\x0a\0\0\0\x37\0\0"."\x0d\3FCGI_MAX_REQS123\x0e\3FCGI_MAX_CONNS123\x0f\1FCGI_MPXS_CONNS0";

start;
begin;
record 1, 4, "\x0c\x05CONTENT_TYPEsomet";
record 1, 2, "";
isrec {'content-type','somet'}, {body => ''}, -6;

start;
begin;
record 1, 4, "\x0e\x05CONTENT_LENGTH65536";
record 1, 4, '';
if (!fork) {
    record 1, 5, 'A'x65535, 255;
    record 1, 5, 'B', 255;
    record 1, 5, '';
    exit;
}
isrec {'content-length',65536}, {body => ('A'x65535) . 'B'};
if (!fork) {
    $f->print('a');
    $f->print('b');
    $f->print('c');
    $f->print('D' x 65536);
    $f->print('e');
    $f->flush;
    exit;
}
isrecv "\1\6\0\1\xff\xff\0\0".'abc'.('D'x65532);
isrecv "\1\6\0\1\0\5\0\0".'DDDDe';
isrecv "\1\6\0\1\0\0\0\0";
isrecv "\1\3\0\1\0\x08\0\0"."\0\0\0\0\0\0\0\0";

done_testing;
