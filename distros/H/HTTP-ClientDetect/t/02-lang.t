#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 62;
use File::Spec;
use Data::Dumper;

# fake a request

use Interchange6::Plugin::Interchange5::Request;
use HTTP::ClientDetect::Language;


my $lang_detect = HTTP::ClientDetect::Language->new(server_default => "hr_HR");

my %test_strings = (
                    'en,en-us;q=0.7,it;q=0.3' => 'en_US',
                    'en;q=0.1,en-us;q=0.5;q=0.7,it;q=0.8' => 'it_IT',
                    'en;q=0.1,en-us;q=0.5;q=0.7,it-it;q=0.8' => 'it_IT',
                    'en;q=0.1,en-us;q=0.5;hr-hr;q=0.7,it;q=0.8' => 'it_IT',
                    'just garbage' => 'hr_HR',
                    ',,,,,,,;;;,,,;;' => 'hr_HR',
                    'en-us;q=0.5;hr-hr;q=0.7,it;q=0.8,en' => 'en_US',
                    'en-us;q=0.5;hr-hr;q=0.7,it;q=0.8,en-gb' => 'en_GB',
                    'es' => 'es_ES',
                    'fr,fr-fr;q=0.7,it;q=0.3' => 'fr_FR',
                    # test taken from https://metacpan.org/source/YAPPO/HTTP-AcceptLanguage-0.02/t/01_languages.t
"en   \t , en;q=1., aaaaaaaaaaaaaaaaa, s.....dd, po;q=asda,
 ja \t   ;  \t   q \t =  \t  0.3, da;q=1.\t\t\t,  de;q=0." => 'en_US',
                    'en;q=0.4, ja;q=0.3, ja;q=0.45, en;q=0.42, ja;q=0.1' => 'ja',
                   );

foreach my $string (keys %test_strings) {
    my $expected = $test_strings{$string};
    my $env = {
               ACCEPT_LANGUAGE => $string,
              };
    my $request = Interchange6::Plugin::Interchange5::Request->new(env => $env);
    my $result = $lang_detect->language($request);
    is $result, $expected, "Expected $expected from $string, got $result";
    my $short_name = $expected;
    $short_name =~ s/^(.*)_(.*)$/$1/;
    is $lang_detect->language_short($request), $short_name, "Short name $short_name OK";
}


%test_strings = (
                    'en,en-us;q=0.7,it;q=0.3' => 'it',
                    'en;q=0.1,en-us;q=0.5;q=0.7,it;q=0.8' => 'it',
                    'en;q=0.1,en-us;q=0.5;q=0.7,it-it;q=0.8' => 'it',
                    'en;q=0.1,en-us;q=0.5;hr-hr;q=0.7,it;q=0.8' => 'it',
                    'just garbage' => 'hr',
                    ',,,,,,,;;;,,,;;' => 'hr',
                    'en-us;q=0.5;hr-hr;q=0.7,it;q=0.8,en' => 'it',
                    'en-us;q=0.5;hr-hr;q=0.7,it;q=0.8,en-gb' => 'it',
                    'es' => 'hr',
                    'fr,fr-fr;q=0.7,it;q=0.3' => 'it',
                    # test taken from https://metacpan.org/source/YAPPO/HTTP-AcceptLanguage-0.02/t/01_languages.t
"en   \t , en;q=1., aaaaaaaaaaaaaaaaa, s.....dd, po;q=asda,
 ja \t   ;  \t   q \t =  \t  0.3, da;q=1.\t\t\t,  de;q=0." => 'hr',
                    'en;q=0.4, ja;q=0.3, ja;q=0.45, en;q=0.42, ja;q=0.1' => 'hr',
                );
$lang_detect = HTTP::ClientDetect::Language
  ->new(server_default => "hr",
        available_languages => [qw/it hr/]
       );

foreach my $string (keys %test_strings) {
    my $expected = $test_strings{$string};
    my $env = {
               ACCEPT_LANGUAGE => $string,
              };
    my $request = Interchange6::Plugin::Interchange5::Request->new(env => $env);
    is $lang_detect->language_short($request), $expected, "Got $expected";
}

eval {
    $lang_detect->available_languages(['xx']);
};

ok $@, "Module crashes when garbage is passed to the accessors: $@";

eval {
    $lang_detect->server_default('xx');
};

ok $@, "Module crashes when garbage is passed to the accessors: $@";

$lang_detect->server_default('se');
$lang_detect->available_languages(['se']);

foreach my $string (keys %test_strings) {
    my $env = {
               ACCEPT_LANGUAGE => $string,
              };
    my $request = Interchange6::Plugin::Interchange5::Request->new(env => $env);
    is $lang_detect->language_short($request), 'se', "Returned the only avail";
    is $lang_detect->language($request), 'se', "Returned the only avail";
}

