#!/usr/bin/perl
use strict;
use warnings;

use HTTP::Request::Webpush;
use LWP::UserAgent;

my $server_key = { public => 'BCAI00zPAbxEVU5w8D1kZXVs2Ro--FmpQNMOd0S0w1_5naTLZTGTYNqIt7d97c2mUDstAWOCXkNKecqgS4jARA8',
   private => 'M6xy5prDBhJNlOGnOkMekyAQnQSWKuJj1cD06SUQTow'};

my $send=HTTP::Request::Webpush->new();

$send->subscription('{"endpoint":"https://bn3p.notify.windows.com/w/?token=BQYAAACgmmGJB%2fT6GgtS%2bZsefznjZgOG1kd2d05B80MIiQ%2fn5JKOOjrE7Bep8JYJoqRiAW67%2fyoq69DRfLFaZHxhBiYbWh6HfdUd0SbAAwe6%2fvk0ClM0a4%2bEfX0fzUflmVix%2fV8uM1lFqVidtOLLs20lnWw%2bH5NshsmZDoCANpXCcQBWTUVc8cRAhgv8MFWTSCgRMLhfVTeuvbEpxVDX0NvmtyPIXUw8tnQ1kWRqVo0muezAgD7aRUikj3hOzYkfQ56sLaK8e%2fGFO6QPY7sQqdDUtFqLiWSlEVq6GqFe6jEUKl7J8JQSQkrepwCkS9ZcnXkFTUg%3d","expirationTime":null,"keys":{"p256dh":"BJf12N26ktxlIScwL_XEsGXpc_z9oSjyJJLreyKza3SrwUwmvOb1dAu5IvxDkA5P2e23EUTOJbDovMEx0ZB0Qrs","auth":"tovh9rG0Qz4dYfv3n778ng"}}');
$send->subject('mailto:esf@moller.cl');
$send->authbase64($server_key->{public}, $server_key->{private});
$send->content("Billy Jean's not my lover");
$send->encode;
$send->header('TTL' => '90');

my $ua = LWP::UserAgent->new;
my $response = $ua->request($send);

print $response->code();
print "\n";
print $response->decoded_content;
print $response->header('Location');
print "\n";
print $response->header('Link');


