#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use HTTP::Request;
use HTTP::Request::AsCGI;

my $request = HTTP::Request->new( GET => 'http://www.host.com/' );
my $stdout;

{
    my $c = HTTP::Request::AsCGI->new($request)->setup;
    my $q = CGI->new;

    print $q->header,
          $q->start_html('Hello World'),
          $q->h1('Hello World'),
          $q->end_html;

    $stdout = $c->stdout;

    # enviroment and descriptors will automatically be restored when $c is destructed.
}

while ( my $line = $stdout->getline ) {
    print $line;
}
