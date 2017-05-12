use warnings;
use strict;
use Test::More 'no_plan';
use lib ('lib', '../lib');
use MKDoc::Text::Structured;

my $text = <<EOF;
     test
   test
EOF

my $res = MKDoc::Text::Structured::process ($text);
my @stuff = $res =~ /pre/g;
ok (2 == scalar @stuff);


$text = <<EOF;
1. test
     test

   test
EOF
$res = MKDoc::Text::Structured::process ($text);
@stuff = $res =~ /pre/g;
ok (2 == scalar @stuff);

$text = <<EOF;
1. test

     test

   test
EOF
$res = MKDoc::Text::Structured::process ($text);
@stuff = $res =~ /pre/g;
ok (2 == scalar @stuff);

$text = <<EOF;
       b
 a = -----
       c

>        b
>  a = -----
>        c

1. some stuff

     some pre stuff

   2. some other stuff

EOF
$res = MKDoc::Text::Structured::process ($text);
1;

__END__
