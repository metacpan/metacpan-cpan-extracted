use strict;
use warnings;
use Test::More;
use Exception::Reporter::Dumper::YAML;

sub ident { Exception::Reporter::Dumper::YAML->_ident_from($_[0]) }
is(
  ident("xyz"),
  "xyz",
  "basic ident",
);

my $str = <<'END';
can't compute fwds for xyz@example.com
-------                                                                         
Trace begun at /usr/pkg/lib/perl5/site_perl/5.8.0/Riddle/MDA.pm line 627        
END

is(
  ident($str),
  q{can't compute fwds for xyz@example.com},
  "multiline",
);


done_testing;
