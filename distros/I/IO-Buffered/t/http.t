use strict;
use warnings;

use Test::More tests => 7;

use IO::Buffered;

my $buffer = new IO::Buffered(HTTP => 1);

# Handle WSDL request
my $get = "GET /soap.php?WSDL HTTP/1.0\x0d\x0a".
           "Host: localhost\x0d\x0a\x0d\x0a";

$buffer->write($get); 
if(my @records = $buffer->read()) {
    is_deeply(\@records, [$get], "Got get request");
} else {
    fail "Did not get back any records from read()";
}

is($buffer->read_last(), 0, "Empty result as we have nothing in the queue");
is($buffer->read(), 0, "Empty result as we have nothing in the queue");

# Handle WSDL request
my $post = 
    "POST /soap HTTP/1.1\r\n".
    "Host: localhost:1981\r\n".
    "Connection: Keep-Alive\r\n".
    "User-Agent: PHP-SOAP/5.2.5\r\n".
    "Content-Type: text/xml; charset=utf-8\r\n".
    "SOAPAction: \"http://soap.netlookup.dk/test/get_commits\"\r\n".
    "Content-Length: 264\r\n\r\n".
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n".
    "<SOAP-ENV:Envelope xmlns:SOAP-ENV=".
    "\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns1=\"".
    "http://soap.netlookup.dk/svn\">".
    "<SOAP-ENV:Body><ns1:get_commits><limit>0,30</limit></ns1:".
    "get_commits></SOAP-ENV:Body></SOAP-ENV:Envelope>";

$buffer->write($post); 
$buffer->write($post); 
if(my @records = $buffer->read()) {
    is_deeply(\@records, [$post, $post], "Got post request");
} else {
    fail "Did not get back any records from read()";
}

$post =~ /^(.+?\r\n\r\n)(.+)$/s;
my ($post_header, $post_data) = ($1, $2); 

my $buffer2 = new IO::Buffered(HTTP => 1, HeaderOnly => 1);
$buffer2->write($post); 
$buffer2->write($post); 
if(my @records = $buffer2->read()) {
    is_deeply(\@records, [$post_header], "Got post-header request");
} else {
    fail "Did not get back any records from read() on buffer2";
}

if(my @records = $buffer2->read(length($post_data))) {
    is_deeply(\@records, [$post_data, $post_header], "Got post-data request");
} else {
    fail "Did not get back any records from read() on buffer2";
}

if(my @records = $buffer2->read(length($post_data))) {
    is_deeply(\@records, [$post_data], "Got post-data request 2");
} else {
    fail "Did not get back any records from read() on buffer2";
}


