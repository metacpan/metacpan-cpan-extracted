use strict;
use warnings;
use utf8;
use Test::More;
use JKML;

is encode_jkml([]), '[]';
is encode_jkml({}), '{}';
is encode_jkml({a => 1}), '{"a"=>1}';
is encode_jkml(\1), 'true';
is encode_jkml(\0), 'false';
is encode_jkml("'"), q{"'"};
is encode_jkml(q{"}), q{"\""};
is encode_jkml(3.14), q{3.14};

done_testing;

