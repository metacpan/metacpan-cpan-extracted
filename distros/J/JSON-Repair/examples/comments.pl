#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Repair ':all';
my $rjson = <<'(RAW)';
/* Javascript-like comments are allowed */
{
  // single or double quotes allowed
  a : 'Larry',
  b : "Curly",
   
  // nested structures allowed like in JSON
  c: [
     {a:1, b:2},
  ],
   
  // like Perl, trailing commas are allowed
  d: "more stuff",
}
(RAW)
print repair_json ($rjson, verbose => undef);
