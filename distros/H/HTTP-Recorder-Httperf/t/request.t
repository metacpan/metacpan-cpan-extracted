#!/usr/bin/perl -w
use strict;
use warnings;
use lib '/home/mpeters/development/HTTP-Recorder-Httperf-0.01/lib';
use HTTP::Recorder::Httperf;
use HTTP::Request;
use URI;
use Test::More tests => 35;

#create my agent and test
my $agent = HTTP::Recorder::Httperf->new();
is(ref($agent), 'HTTP::Recorder::Httperf', 'H::R::h creation test');

#test the default default_think
is($agent->default_think(), undef, 'default think time');

#now let's test the temp file name
is($agent->temp_file(), '.httperf_recorder_time', 'default temp file');
$agent->temp_file('my_temp_file.dat');
is($agent->temp_file(), 'my_temp_file.dat', 'default temp file');
$agent->temp_file('.httperf_recorder_time');

#now let's test the default burst_threshold
is($agent->burst_threshold(), 1, 'default burst_threshold');
$agent->burst_threshold('1.5');
is($agent->burst_threshold(), '1.5', 'default burst_threshold');


#set the file to be local to this test
my $file = 'test.txt';
$agent->file($file);
unlink('.httperf_recorder_time');
unlink($file);

my $content = qq(This is my\n "multiline" content.);
my $content_trans = qr(This is my\\<CR> \\"multiline\\" content\.);

my @test_requests = (
		{ method => 'GET', uri => 'http://www.google.com/search?hl=en&ie=UTF-8&q=test&btnG=Google+Search' },
		{ method => 'GET', uri => 'http://www.google.com/images/logo.gif', wait => 2 },
		{ method => 'HEAD', uri => 'http://www.google.com', wait => 2 },
		{ method => 'POST', uri => 'http://www.google.com/', content => $content, wait => 2 },
	);

#now let's loop over and log each request
my $count = 1;
foreach (@test_requests)
{
  #create a request to pass to the agent
  my $request1 = HTTP::Request->new($_->{method} => $_->{uri});
  $request1->content($content) if($_->{content});
  
  #now let's make sure that the agent handles the request ok
  my $request2 = $agent->modify_request($request1);
  #make sure the request comes back unmodified
  is($request1->method, $request2->method, "unmodified request $count: method");
  is($request1->uri, $request2->uri, "unmodified request $count: uri");
  is($request1->content, $request2->content, "unmodified request $count: content");

  #now let's examine the file
  open(FILE, $file) or die "Couldn't open $file: $!";
  my @lines = <FILE>;
  close(FILE) or die "Couldn't close $file: $!";
  #let's look at the last line
  my $line = $lines[$#lines];
  chomp($line);
  #now split it on single spaces
  my @line_parts = split(/ (?=\w)/, $line);
  my $uri = URI->new($_->{uri});
  my $path = $uri->path || '/';
  #the second one should be indented
  $path = "    $path" if($count == 2);
  $path = "$path?" . $uri->query if($uri->query());
  
  #test the path of this request log entry
  is($line_parts[0], $path, qq(session log $count: path));
  #test the method
  is($line_parts[1], "method=" . $request1->method, qq(session log $count: method));
  
  #if we are on the first or second one make sure there is no wait or content
  if($count == 2 || $count == 1)
  {
    is($line_parts[2], undef, qq(session log $count: contents));
    is($line_parts[3], undef, qq(session log $count: think));
  }
  #else if we are on the third one then test that there is a think and no contents
  elsif($count == 3) 
  {
    ok($line_parts[2] =~ /think=\d+/, qq(session log $count: think));
    is($line_parts[3], undef, qq(session log $count: contents));
  }
  #else if we are on the fourth one then test that there is a think and a contents
  elsif($count == 4) 
  {
    ok($line =~ $content_trans, qq(session log $count: contents));
    ok($line =~ /think=\d+/, qq(session log $count: think));
  }
  $count++;
  sleep($_->{wait}) if($_->{wait});
}

#test the new default_think 
$agent->default_think('1.0');
is($agent->default_think(), '1.0', 'changed think time');
unlink($file) or die "Couldn't unlink $file: $!";
unlink('.httperf_recorder_time') or 
  die "Couldn't unlink .httperf_recorder_time: $!";




