# vim: filetype=perl :
use Test::More tests => 10;
use lib 't/lib';
use Test::MMS::Parser;

BEGIN {
   use_ok( 'MMS::Parser' );
}

my $parser = MMS::Parser->create();

my %tests_positive = (
   CRLF => [ "+\r\n" ],
   LWS  => [ "+ \t  ", "+\r\n   ", "-\r\n" ],
   TEXT => [ "+ciao a tutti", "-\x1F ciao" ],
   token => [ "+ciao_a_tutti", "- ciao a tutti", "-:ciao;atutti"],
);

while (my ($subname, $tref) = each %tests_positive) {
   foreach my $teststring (@$tref) {
      my $type = substr $teststring, 0, 1;
      $teststring = substr $teststring, 1;
      my $parsed = $parser->$subname($teststring);
      my $exp = ($type eq '+') ? $teststring : undef;
      is($parsed, $exp, "$subname ($type)");
   }
}
