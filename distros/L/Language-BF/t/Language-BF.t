use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok('Language::BF') };

my $bf = Language::BF->new(<<EOC);
++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<
+++++++++++++++.>.+++.------.--------.>+.>.
EOC
$bf->run;

my $hello = "Hello World!";
is $bf->output, "$hello\n", $hello;

