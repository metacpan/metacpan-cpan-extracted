#!perl

use strict;
use warnings;
use utf8;
use Data::Dumper;
use Test::More tests => 5;

use Marketplace::Rakuten::Response;

# http://webservice.rakuten.de/documentation/howto/error

my $xml =<<XML;
<?xml version="1.0" encoding="utf-8"?>
<result>
  <success>-1</success>
  <errors>
    <error>
      <code>40</code>
      <message>Der benötigte Parameter "name" konnte nicht gefunden werden</message>
      <help>http://www.google.de</help>
    </error>
    <error>
      <code>40</code>
      <message>Der benötigte Parameter "price" konnte nicht gefunden werden</message>
      <help>http://www.google.de</help>
    </error>
  </errors>
</result>
XML

my $res = Marketplace::Rakuten::Response->new(content => $xml);

is_deeply($res->data,
          { 'errors' => {
                       'error' => [
                                   {
                                    'help' => 'http://www.google.de',
                                    'message' => "Der ben\x{f6}tigte Parameter \"name\" konnte nicht gefunden werden",
                                    'code' => '40'
                                   },
                                   {
                                    'code' => '40',
                                    'help' => 'http://www.google.de',
                                    'message' => "Der ben\x{f6}tigte Parameter \"price\" konnte nicht gefunden werden"
                                   }
                                  ]
                      },
          'success' => '-1'
          }, "Data parsed ok");

my $errors = $res->errors;
is_deeply($errors, [
                     {
                      'help' => 'http://www.google.de',
                      'message' => "Der ben\x{f6}tigte Parameter \"name\" konnte nicht gefunden werden",
                      'code' => '40',
                     },
                     {
                      'code' => '40',
                      'help' => 'http://www.google.de',
                      'message' => "Der ben\x{f6}tigte Parameter \"price\" konnte nicht gefunden werden"
                     }
                    ], "Errors ok");


$xml =<<XML;
<?xml version="1.0" encoding="utf-8"?>
<result>
  <success>-1</success>
  <errors>
    <error>
      <code>40</code>
      <message>Der benötigte Parameter "name" konnte nicht gefunden werden</message>
      <help>http://www.google.de</help>
    </error>
  </errors>
</result>
XML

$res = Marketplace::Rakuten::Response->new(content => $xml);


is_deeply($res->data,
          { 'errors' => {
                       'error' => [
                                   {
                                    'help' => 'http://www.google.de',
                                    'message' => "Der ben\x{f6}tigte Parameter \"name\" konnte nicht gefunden werden",
                                    'code' => '40'
                                   },
                                  ]
                      },
          'success' => '-1'
          }, "Data parsed ok with array forced");

$errors = $res->errors;
is_deeply($errors, [
                     {
                      'help' => 'http://www.google.de',
                      'message' => "Der ben\x{f6}tigte Parameter \"name\" konnte nicht gefunden werden",
                      'code' => '40',
                     },
                    ], "Errors ok");

like $res->error_string, qr/40/, "Error string ok";
