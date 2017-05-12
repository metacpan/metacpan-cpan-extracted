# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 62;
BEGIN { use_ok('Logfile::Access') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $log = new Logfile::Access;

ok ($log->parse(q{a1as20-p218.due.tli.de logname user [31/Mar/2001:23:14:46 +0200] "GET /g0010025.htm HTTP/1.0" 304 6543 "http://www.referer.de/persons.htm" "Mozilla/4.7 [de]C-CCK-MCD CSO 1.0  (Win98; U)"}), "parse()");

ok ($log->tld() eq "de", "tld()");
ok ($log->country_name() eq "Germany", "country_name()");
ok ($log->domain() eq "tli.de", "domain()");
ok ($log->remote_host() eq "a1as20-p218.due.tli.de", "remote_host()");

ok ($log->logname() eq "logname", "logname()");
ok ($log->user() eq "user", "user()");

ok ($log->date() eq "31/Mar/2001", "date()");
ok ($log->mday() eq "31", "mday()");
ok ($log->month() eq "Mar", "month()");
ok ($log->year() eq "2001", "year()");
ok ($log->time() eq "23:14:46", "time()");
ok ($log->hour() eq "23", "hour()");
ok ($log->minute() eq "14", "minute()");
ok ($log->second() eq "46", "second()");
ok ($log->offset() eq "+0200", "offset()");

ok ($log->method() eq "GET", "method()");
ok (! defined $log->scheme(), "scheme()");
ok (! defined $log->query_string(), "query_string()");
ok ($log->path() eq "/", "path()");
ok ($log->mime_type() eq "text/html", "mime_type()");
ok ($log->unescape_object() eq "/g0010025.htm", "unescape_object()");
ok ($log->escape_object() eq "%2Fg0010025.htm", "escape_object()");
ok ($log->object() eq "/g0010025.htm", "object()");
ok ($log->protocol() eq "HTTP/1.0", "protocol()");

ok ($log->response_code() eq "304", "response_code()");
ok ($log->content_length() eq "6543", "content_length()");
ok ($log->http_referer() eq "http://www.referer.de/persons.htm", "http_referer()");
ok ($log->http_user_agent() eq "Mozilla/4.7 [de]C-CCK-MCD CSO 1.0  (Win98; U)", "http_user_agent()");

ok ($log->parse(q{66.202.26.100 test1 test2 [21/Jan/2002:12:22:33 -0400] "PUT /path/g0010025.jpg?key=banana HTTP/1.1" 200 16543 "http://www.referer.de/" "Mozilla/4.7"}), "parse()");
ok ($log->class_a() eq "66.", "class_a()");
ok ($log->class_b() eq "66.202.", "class_b()");
ok ($log->class_c() eq "66.202.26.", "class_c()");

ok (! defined $log->tld(), "tld()");
ok (! defined $log->country_name(), "country_name()");
ok (! defined $log->domain(), "domain()");
ok ($log->remote_host() eq "66.202.26.100", "remote_host()");

ok ($log->logname() eq "test1", "logname()");
ok ($log->user() eq "test2", "user()");

ok ($log->date() eq "21/Jan/2002", "date()");
ok ($log->mday() eq "21", "mday()");
ok ($log->month() eq "Jan", "month()");
ok ($log->year() eq "2002", "year()");
ok ($log->time() eq "12:22:33", "time()");
ok ($log->hour() eq "12", "hour()");
ok ($log->minute() eq "22", "minute()");
ok ($log->second() eq "33", "second()");
ok ($log->offset() eq "-0400", "offset()");

ok ($log->method() eq "PUT", "method()");
ok (! defined $log->scheme(), "scheme()");
ok ($log->query_string() eq "key=banana", "query_string()");
ok ($log->path() eq "/path/", "path()");
ok ($log->mime_type() eq "image/jpeg", "mime_type()");
ok ($log->unescape_object() eq "/path/g0010025.jpg?key=banana", "unescape_object()");
ok ($log->escape_object() eq "%2Fpath%2Fg0010025.jpg%3Fkey%3Dbanana", "escape_object()");
ok ($log->object() eq "/path/g0010025.jpg?key=banana", "object()");
ok ($log->protocol() eq "HTTP/1.1", "protocol()");

ok ($log->response_code() eq "200", "response_code()");
ok ($log->content_length() eq "16543", "content_length()");
ok ($log->http_referer() eq "http://www.referer.de/", "http_referer()");
ok ($log->http_user_agent() eq "Mozilla/4.7", "http_user_agent()");
#ok ($log->parse(q{66.202.26.100 test1 test2 [21/Jan/2002:12:22:33 -0400] "PUT /path/g0010025.jpg?key=banana HTTP/1.1" 200 16543 "http://www.referer.de/" "Mozilla/4.7"}), "parse()");
