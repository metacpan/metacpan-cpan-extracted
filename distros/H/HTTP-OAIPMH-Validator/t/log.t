# Tests for HTTP::OAIPMH::Log
use strict;

use Test::More tests => 90;
use HTTP::OAIPMH::Log;
use JSON qw(decode_json);

my $log = HTTP::OAIPMH::Log->new;
ok( $log, "created new Log object" );

# add loggers
is( $log->fh, 0, "empty call" );
is( $log->fh(\*STDERR), 1, "stderr fh plain" );
is( $log->fh([\*STDERR]), 1, "stderr fh arrayref" );
is( $log->fh([\*STDERR,'json']), 1, "stderr fh arrayref with type" );
is( $log->fh, 1, "empty call, 1 set" );
is( $log->fh([\*STDERR],[\*STDOUT, 'json']), 2, "stderr fh, json" );
is( scalar(@{$log->filehandles}), 2, "2 loggers");

# logging
$log = $log->new;
ok( $log, "created new Log object" );
is( $log->total, 0, 'zero total' );
is( scalar(@{$log->log}), 0, "no entries" );

ok( $log->start('beginning'), "begin" );
is( scalar(@{$log->log}), 1, "1 entry" );
is( $log->log->[0][0], 'TITLE', "title entry" );
is( $log->log->[0][1], 'beginning', "content is beginning" );

ok( $log->request('http://example.com'), "request" );
ok( $log->request('http://example.com','GET'), "get request");
ok( $log->request('http://example.com','POST'), "post request");
ok( $log->request('http://example.com','POST','post=data'), "post request");
is( scalar(@{$log->log}), 5, "5 entries" );

ok( $log->note('inote'), "note" );

is( $log->total, 0, 'no pass+fail' );
ok( $log->fail('yu-so-bad'), "fail" );
is( $log->total, 1, '1 pass+fail' );
ok( $log->fail('very-bad','and here is why...'), "fail" );
is( $log->total, 2, '2 pass+fail' );

is( $log->num_warn, 0, "no warn" );
ok( $log->warn('be-careful'), "warn" );
ok( $log->warn('be-careful','very-careful'), "warn 2" );
is( $log->num_warn, 2, "2 warn" );
is( $log->total, 2, '2 pass+fail (warn not included in total)' );

is( $log->num_pass, 0, "no pass" );
ok( $log->pass('gud'), "pass" );
is( $log->num_pass, 1, "1 pass" );
is( $log->total, 3, '3 pass+fail' );

# _add method and on-the-fly output in markdown
my $str;
my $fh;
$log = HTTP::OAIPMH::Log->new;
ok( $log, "created new Log object" );
$str=''; open( $fh, '>', \$str);
is( $log->fh([$fh]), 1, "connected out to str" );
ok( $log->_add("ONE","SOME"), "_add ONE SOME" );
is( $str, "ONE:     SOME\n", "one line written" );

$log = HTTP::OAIPMH::Log->new;
ok( $log, "created new Log object" );
$str=''; open($fh, '>', \$str); 
is( $log->fh([$fh]), 1, "connected out to str" );
ok( $log->_add("TITLE","bingo"), "_add TITLE BINGO" );
is( $str, "\n### bingo\n\n", "bingo line written" );

$log = HTTP::OAIPMH::Log->new;
ok( $log, "created new Log object" );
$str=''; open($fh, '>', \$str); 
is( $log->fh([$fh]), 1, "connected out to str" );
ok( $log->_add("WARN","short"), "_add WARN short" );
is( $str, "WARN:    short\n", "WARN line written" );
ok( $log->_add("FAIL","short","more"), "_add FAIL short long" );
is( $str, "WARN:    short\nFAIL:    short more\n", "FAIL line written" );

$log = HTTP::OAIPMH::Log->new;
ok( $log, "created new Log object" );
$str=''; open($fh, '>', \$str); 
is( $log->fh([$fh]), 1, "connected out to str" );
ok( $log->_add("NOTE","one","two","three"), "_add NOTE one two three" );
is( $str, "NOTE:    one two three\n", "NOTE line written with all elements" );

# _add method and on-the-fly output in json
my $str;
my $fh;
$log = HTTP::OAIPMH::Log->new;
ok( $log, "created new Log object" );
$str=''; open( $fh, '>', \$str);
is( $log->fh([$fh,'json']), 1, "connected out to str, type json" );
ok( $log->_add("ONE","SOME"), "_add ONE SOME" );
my $j = decode_json($str);
is( $j->{'num'}, 1, 'num==1' );
is( $j->{'type'}, 'ONE', 'type==ONE' );
is( $j->{'msg'}, 'SOME', 'msg==SOME' );
ok( $j->{'timestamp'}, 'timestamp is True' );

# _add method and on-the-fly HTML output
$log = HTTP::OAIPMH::Log->new;
ok( $log, "created new Log object" );
$str=''; open( $fh, '>', \$str);
is( $log->fh([$fh,'html']), 1, "connected out to str, type html" );
ok( $log->_add("TITLE","A title"), "_add TITLE" );
ok( $str=~/<h3 class="oaipmh-log-title">/, 'title class' );
ok( $str=~/A title/, 'the title' );
$str=''; open( $fh, '>', \$str);
is( $log->fh([$fh,'html']), 1, "connected out to str, type html" );
ok( $log->_add("FAIL","Barf","more"), "_add FAIL" );
ok( $str=~/<div class="oaipmh-log-line/, 'line class' );
ok( $str=~/<span class="oaipmh-log-num/, 'num class' );
ok( $str=~/<span class="oaipmh-log-type">FAIL</, 'type class and content' );
ok( $str=~/<span class="oaipmh-log-msg">Barf more</, 'msg class and content' );

# Tests for log interrogration: failures() and last_match()
$log = HTTP::OAIPMH::Log->new;
ok( $log, "created new Log object" );
ok( $log->start("A title"), "add TITLE" );
ok( $log->request("request1"), "_add request1" );
ok( $log->pass("request1 pass1"), "_add request1 pass1" );
ok( $log->pass("request1 pass2"), "_add request1 pass2" );
ok( $log->note("request1 noteeee"), "_add request1 note" );
ok( $log->pass("request1 pass3"), "_add request1 pass3" );
is( $log->failures, '', 'no failures');
ok( $log->request("request2"), "_add request2" );
ok( $log->pass("request2 pass1"), "_add request2 pass1" );
ok( $log->note("request2 note"), "_add request2 note" );
ok( $log->fail("request2 fail1"), "_add request2 fail1" );
ok( $log->pass("request2 pass2"), "_add request2 pass2" );
ok( $log->fail("request2 fail2"), "_add request2 fail2" );
my $failures = $log->failures();
ok( $failures=~/## Failure summary/, "failures title"); 
ok( $failures=~/REQUEST:\s+request2\s+FAIL:\s+request2 fail1\s+FAIL:\s+request2 fail2/, 'correct fails');
is_deeply( $log->last_match(qr/fail1/), ['FAIL','request2 fail1']);
is_deeply( $log->last_match(qr/noteeee/), ['NOTE','request1 noteeee']);
is( $log->last_match(qr/no-match/), undef, 'no match -> empty return');