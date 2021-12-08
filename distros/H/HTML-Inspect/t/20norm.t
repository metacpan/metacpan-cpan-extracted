use warnings;

use strict;
use utf8;

use Log::Report;
use Test::More;

use HTML::Inspect::Normalize;
use HTML::Inspect::Util  qw(absolute_url);

# We can use 'set_base' to check much of the parsing

sub test_base($$$) {
   my ($from, $to, $explain) = @_;
   is scalar(set_page_base $from), $to, $explain;
}

sub test_norm($$$) {
   my ($from, $to, $explain) = @_;
   is scalar(normalize_url $from), $to, $explain;
}

### Blanks
test_base '  http://example.com',     'http://example.com/',      'leading blanks';
test_base 'http://example.com  ',     'http://example.com/',      'trailing blanks';
test_base ' http://example.com ',     'http://example.com/',      'both side blanks';

test_base "http://example.\rcom",     'http://example.com/',      'remove lf';
test_base "http://example.\ncom",     'http://example.com/',      'remove cr';
test_base "http://example.\tcom",     'http://example.com/',      'remove tab';
test_base "http://example.\x{0B}com", 'http://example.com/',      'remove vt';
test_base "http://example.\r\ncom",   'http://example.com/',      'remove crlf';
test_base "http://example.\n  com",   'http://example.com/',      'blanks following line fold';

### Fragment
test_base 'http://example.com#abc',   'http://example.com/',      'remove fragment';

### Reslash
test_base 'http://example.com\\ab\\c\\', 'http://example.com/ab/c/', 'reslash';

### Scheme
test_base 'http://example.com',       'http://example.com/',      'http';
test_base 'https://example.com',      'https://example.com/',     'https';
test_base 'HtTP://example.com',       'http://example.com/',      'schema in caps';
test_base '//example.com',            'https://example.com/',     'schema from default';

### Auth
test_base 'http://ab@exAmPle.cOm',    'http://ab@example.com/',   'username';
test_base 'http://ab:cd@exAmPle.cOm', 'http://ab:cd@example.com/','username + password';
test_base 'http://:cde@exAmPle.cOm',  'http://:cde@example.com/', 'password';

### Host
test_base 'http://exAmPle.cOm',       'http://example.com/',      'hostname in caps';
test_base 'http://',                  'http://localhost/',        'missing host';
test_base 'http:///',                 'http://localhost/',        'missing host 2';
test_base 'http://a.b.c.de.:80/f',    'http://a.b.c.de/f',        'hostname trailing dot';

### Port
test_base 'http://exAmPle.cOm:80',    'http://example.com/',      'remove default port';
test_base 'https://exAmPle.cOm:431',  'https://example.com/',     'remove default port';
test_base 'http://example.com:81',    'http://example.com:81/',   'keep other port';
test_base 'http://example.com:082',   'http://example.com:82/',   'remove leading zeros';
test_base 'http://example.com:',      'http://example.com/',      'accidental no port';
test_base 'http://:42',               'http://localhost:42/',     'missing host 3';

### PATH
test_base 'http://example.com/',      'http://example.com/',      'only root path';
test_base 'http://example.com/a',     'http://example.com/a',     'two level path';
test_base 'http://example.com/a/bc',  'http://example.com/a/bc',  'two level path';
test_base 'http://example.com/a/bc/', 'http://example.com/a/bc/', 'directory';
test_base 'http://example.com/a//c//', 'http://example.com/a/c/', 'doubled slashes';

test_base 'http://example.com/.',     'http://example.com/',      'useless dot';
test_base 'http://example.com/./',    'http://example.com/',      'useless dot 2';
test_base 'http://example.com/a/.',   'http://example.com/a/',    'dot keep /';
test_base 'http://example.com/./a/',  'http://example.com/a/',    'dot path removed';
test_base 'http://example.com/./a/././b', 'http://example.com/a/b','dot path removed multi';
test_base 'http://example.com/.;a',   'http://example.com/;a',    'dot with attribute';
test_base 'http://example.com/b/.;a', 'http://example.com/b/;a',  'dot with attribute';
test_base 'http://example.com/.?a',   'http://example.com/?a',    'dot with query';

test_base 'http://example.com/..',    'http://example.com/',      'leading dot-dot';
test_base 'http://example.com/../..', 'http://example.com/',      'leading dot-dot x2';
test_base 'http://example.com/../a',  'http://example.com/a',     'leading dot-dot with more';
test_base 'http://example.com/b/..',  'http://example.com/',      'trailing dot-dot';
test_base 'http://example.com/b/../c','http://example.com/c',     'intermediate dot-dot';
test_base 'http://example.com/b/../../c', 'http://example.com/c', 'too many interm dot-dot';
test_base 'http://www.example.com/a/c/../b/search', 'http://www.example.com/a/b/search', 'middle dot-dot';

test_base 'http://e.com/a/./b/.././../c', 'http://e.com/c',       'hard';

### PATH RELATIVE
set_page_base "http://a.bc";
test_norm '',                         'http://a.bc/',             'empty relative 1';
test_norm '/',                        'http://a.bc/',             'absolute empty 1';

set_page_base "http://a.bc/d?q";
test_norm '',                         'http://a.bc/d?q',          'empty relative 2';
test_norm '/',                        'http://a.bc/',             'absolute empty 2';
test_norm '/a',                       'http://a.bc/a',            'absolute addition';
test_norm '#f',                       'http://a.bc/d?q',          'some fragment';
test_norm '?p',                       'http://a.bc/d?p',          'change of query';
test_norm '../../e/',                 'http://a.bc/e/',           'postprocessing happens';

### QUERY
test_base 'http://e.com?q',           'http://e.com/?q',          'query as root';
test_base 'http://e.com/?a+b=%63',    'http://e.com/?a%20b=c',    'query hex encoding';
test_base 'http://e.com/?pythaγoras', 'http://e.com/?pytha%CE%B3oras', 'query unicode';
test_base 'http://e.com?a+b=%63&aγ&', 'http://e.com/?a%20b=c&a%CE%B3&', 'query multi';

### UNICODE
test_base 'http://e.com/μαρκ', 'http://e.com/%CE%BC%CE%B1%CF%81%CE%BA', 'unicode';

### HEX encoding
test_base 'http://e.com/a%6D%237%40%41', 'http://e.com/am%237%40A', 'rehex';
test_base 'http://e.com/%2F%25+%20 %3F', 'http://e.com/%2F%25%20%20%20%3F', 'rehex blanks';
test_base 'http://e.com/3,4!*',          'http://e.com/3,4!*',      'rehex keep safe chars';

### IDN
test_base 'http://müller.de/abc', 'http://xn--mller-kva.de/abc', 'idn';

### Test errors
my ($val, $rc, $err) = set_page_base 'http://aa.be/'.('f' x 3000);
ok !defined $val, 'got error 1: ' . ($val // 'undef');
is $rc,  'HIN_INPUT_TOO_LONG', 'rc';
is $err, 'Input url too long', 'err';

($val, $rc, $err) = set_page_base 'http://aa.be/%!!';
ok !defined $val, 'got error 2: ' . ($val // 'undef');
is $rc,   "HIN_ILLEGAL_HEX";
is $err,  "Illegal hexadecimal digit";

($val, $rc, $err) = set_page_base "http://a%00f.be/";
ok !defined $val, 'got error 3: ' . ($val // 'undef');
is $rc,   "HIN_CONTAINS_ZERO";
is $err,  "Illegal use of NUL byte";

($val, $rc, $err) = set_page_base 'tel:1123424';
ok !defined $val, 'got error 4: ' . ($val // 'undef');
is $rc,   "HIN_UNSUPPORTED_SCHEME";
is $err,  "Only http(s) is supported";

($val, $rc, $err) = set_page_base 'http://[0::a::c]/';
ok !defined $val, 'got error 5: ' . ($val // 'undef');
is $rc,   "HIN_IPV6_BROKEN";
is $err,  "The IPv6 host address incorrect";

($val, $rc, $err) = set_page_base 'http://[0::/';
ok !defined $val, 'got error 6: ' . ($val // 'undef');
is $rc,   "HIN_IPV6_UNTERMINATED";
is $err,  "The IPv6 host address is not terminated";

($val, $rc, $err) = set_page_base 'http://[0::]xxx/';
ok !defined $val, 'got error 7: ' . ($val // 'undef');
is $rc,   "HIN_IPV6_ENDS_INCORRECTLY";
is $err,  "The IPv6 host address terminated unexpectedly";

($val, $rc, $err) = set_page_base 'http://300.300.300.300/';
ok !defined $val, 'got error 8: ' . ($val // 'undef');
is $rc,   "HIN_IPV4_BROKEN";
is $err,  "The IPv4 host address incorrect";

($val, $rc, $err) = set_page_base 'http://aa.be:1a4/';
ok !defined $val, 'got error 9: ' . ($val // 'undef');
is $rc,   "HIN_PORT_NON_DIGIT";
is $err,  "The portnumber contains a non-digit";

($val, $rc, $err) = set_page_base 'http://aa.be:123456789/';
ok !defined $val, 'got error 10: ' . ($val // 'undef');
is $rc,   "HIN_PORT_NUMBER_TOO_HIGH";
is $err,  "The portnumber is out of range";

($val, $rc, $err) = set_page_base 'http://aa.be/%CE';        # missing follower
ok !defined $val, 'got error 11: ' . ($val // 'undef');
is $rc,   "HIN_INCORRECT_UTF8";
is $err,  "Incorrect UTF8 encoding, broken characters";

($val, $rc, $err) = set_page_base 'http://aa.be/%CE%B3%B3';  # extra follower
ok !defined $val, 'got error 12: ' . ($val // 'undef');
is $rc,   "HIN_INCORRECT_UTF8";
is $err,  "Incorrect UTF8 encoding, broken characters";


### Check ::Util::absolute_url()

{  local $SIG{__WARN__} = sub { };
   ok ! defined absolute_url('data:xyz', ''), 'data should not be taken';
}

done_testing;
