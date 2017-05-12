#!/usr/bin/env perl

use strict;
use warnings;

use MarpaX::Demo::JSONParser;

use Try::Tiny;

# ---------------------------

my($app_name) = 'MarpaX-Demo-JSONParser';
my($bnf_name) = shift || 'json.1.bnf'; # Or 'json.2.bnf'.
my($bnf_file) = "data/$bnf_name";
my($string)   = '{"test":"1.25e4"}';

my($message);
my($result);

# Use try to catch die.

try
{
	$message = '';
	$result  = MarpaX::Demo::JSONParser -> new(bnf_file => $bnf_file) -> parse($string);
}
catch
{
	$message = $_;
	$result  = 0;
};

print $result ? "Result: test => $$result{test}. Expect: 1.25e4. \n" : "Parse failed. $message";
