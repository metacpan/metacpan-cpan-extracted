use strict;
use warnings;
use Config;
use Test::More qw[no_plan];
use Lexical::select;

SKIP: {
  skip 'v5.8.0 and PerlIO required for these tests'
    unless $] >= 5.008 and $Config::Config{useperlio};

  my $mem1; my $mem2;

  open my $fh1, '>', \$mem1 or die "$!\n";
  open my $fh2, '>', \$mem2 or die "$!\n";

  select $fh1;

  my $lex = lselect $fh2;
  isa_ok( $lex, 'Lexical::select' );
  print "Something wicked\n";
  $lex->restore();

  print "Something not wicked\n";

  close $fh1;
  close $fh2;

  like( $mem1, qr/Something not wicked/, 'Stuff was printed to original handle' );
  like( $mem2, qr/Something wicked/, 'Stuff was printed to our handle' );
}
