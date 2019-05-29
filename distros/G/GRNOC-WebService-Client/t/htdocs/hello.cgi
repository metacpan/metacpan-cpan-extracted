#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/..";
use CGI;
use Helper;

my $cgi = new CGI;

my $counter_file = "$FindBin::Bin/../count.json";

if($cgi->param('status') && $cgi->param('method') && $cgi->param('max_retries')) {
    my $count = Helper::get_counter($counter_file);
    my $max_retries = $count->{'max_retries'};
    my $status = $cgi->param('status');
    if(  $max_retries  >= ( $cgi->param('max_retries') + 1 )) {
        print $cgi->header(-type => 'text/plain', -status => "200 OK");
    }
    else{
        Helper::increment_counter( $counter_file);
        print $cgi->header( -type => 'text/plain', -status => $status );
    }
}
elsif($cgi->param('status') && $cgi->param('method')) {
    my $status = $cgi->param('status');
    Helper::increment_counter( $counter_file );
    print $cgi->header(-type => "text/plain", -status => "$status");

}
elsif( $cgi->param('method')){
    print $cgi->header(-type => "text/plain");
    print "OK";
}
else{
    print $cgi->header(-type => "text/plain", -status => "404 Not Found");
    print "404 Not Found";
}

1;
