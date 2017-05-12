use strict;
use warnings;
use Config;
use Test::More qw[no_plan];
use Lexical::select;

SKIP: {
  skip 'v5.8.0 and PerlIO required for these tests'
    unless $] >= 5.008 and $Config::Config{useperlio};

  my $mem;

  open my $fh, '>', \$mem or die "$!\n";

  {
    my $lex = lselect $fh;
    isa_ok( $lex, 'Lexical::select' );
    print "Something wicked\n";
  }

  close $fh;

  like( $mem, qr/Something wicked/, 'Stuff was printed to our handle' );
}
