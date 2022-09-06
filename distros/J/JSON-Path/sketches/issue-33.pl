#!/usr/local/bin/perl

  use strict;
  use JSON::Path;
  local $JSON::Path::Safe = 0;
  use diagnostics;

  my $json   = '{ "phones": [ { "type" : "iPhone", "number": "(123rpar 456-7890" }, { "type" : "home", "number": "(123) 456-7890" } ] }';

  my $phone_number;
  $phone_number = '(123) 456-7890';  
#  $phone_number = '(123rpar 456-7890'; # <-- works, the above does not

  my $jpath   = JSON::Path->new( '$.phones.[?($_->{number} eq "' . "$phone_number" . '")].type');
  my @types = $jpath->values($json);
  print("Phone type is: $types[0]\n");
