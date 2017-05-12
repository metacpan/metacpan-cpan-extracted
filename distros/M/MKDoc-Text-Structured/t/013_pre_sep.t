use warnings;
use strict;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use MKDoc::Text::Structured;

my $text = <<EOF;
   test
   
   test
EOF

my $res = MKDoc::Text::Structured::process ($text);
my @stuff = $res =~ /pre/g;
ok (2 == scalar @stuff);

1;

__END__
