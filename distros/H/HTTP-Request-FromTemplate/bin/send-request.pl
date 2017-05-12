#!/usr/bin/perl -w
use strict;
use HTTP::Request::FromTemplate;
use LWP::UserAgent;

=head1 NAME

send-request.pl - command line utility to send templated HTTP requests

=head1 SYNOPSIS

  send-request.pl my-request param1=value1 param2=value2 ...

=head1 LIMITATIONS

Due to the very simplicistic command line parsing,
it's not possible to pass nested structures or looped
structures. Write a real program for that.

=cut

my ($template,@values) = @ARGV;

my %values = map { /(.*?)=(.*)/ ? ($1, $2) : ($_,undef) } @values;

my $ua = LWP::UserAgent->new();
my $req = HTTP::Request::FromTemplate( template => $template )->process({ @values });
my $res = $ua->request($req);
print $res->as_string;
