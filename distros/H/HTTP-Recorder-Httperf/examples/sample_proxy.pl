#!/usr/bin/perl
                                                                                                                                     
use HTTP::Proxy;
use HTTP::Recorder::Httperf;
                                                                                                                                     
my $proxy = HTTP::Proxy->new(port => 8888);
                                                                                                                                     
# create a new HTTP::Recorder::httperf object
my $agent = new HTTP::Recorder::Httperf;
                                                                                                                                     
# set the log file (optional)
$agent->file("httperf_session.txt");
                                                                                                                                     
# set HTTP::Recorder as the agent for the proxy
$proxy->agent( $agent );

#now put a blank line in that file to indicate a new sesison incase we are running this a second time
open(FILE, ">>httperf_session.txt") or die $!;
print FILE "\n#new session definition\n";
close(FILE);
                                                                                                                                     
# start the proxy
$proxy->start();
                                                                                                                                             
1;

