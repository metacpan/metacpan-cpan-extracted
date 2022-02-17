# -*- cperl -*-

use Test::More tests => 1 + 24 ;

BEGIN { use_ok( 'Lingua::PT::PLNbase' ); }

use utf8;

$i = 0;

  $i++;
  $/ = "\n\n";

  my $input = "";
  my $output = "";
  open T, "<:utf8", "t/tests2.tok" or die "Cannot open tests file";
  while(<T>) {
    chomp($input = <T>);
    chomp($output = <T>);

    my $tok2 = atomiza($input); # Braga
    is($tok2, $output, "$input");
#    exit if $i == 14;
  }
  close T;

1;


