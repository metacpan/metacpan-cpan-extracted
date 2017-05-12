use Test::More;

BEGIN {
    #plan 'no_plan';
    plan tests => 9;
    use_ok("JavaScript::Autocomplete::Backend");
}


# mock CGI environment
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'hl=en&js=true&qu=al';

# new
my $ac = JavaScript::Autocomplete::Backend->new;
isa_ok($ac, "JavaScript::Autocomplete::Backend");

# query
my $q = $ac->query;
is ($q, 'al', "query");

# cgi
my $cgi = $ac->cgi;
isa_ok($cgi, "CGI");

# param
my $p = $ac->param("js");
is ($p, "true", "param");

# header
my $h = $ac->header;
is ($h, "Content-Type: text/html; charset=utf-8\r\n\r\n", "header");

# as_array
my $a = $ac->as_array([1,2,3]);
is ( $a, 'new Array("1", "2", "3")', 'as_array');

# no_js
my $n = $ac->no_js;
ok ( $n =~ /html/, 'no_js' );

# output
my $o = $ac->output("al", ["alice", "alfred"],[],[""]);
my $expected = qq{sendRPCDone(frameElement, "al", new Array("alice", "alfred"), new Array(), new Array(""));\n};
is ($o, $expected, 'output');
