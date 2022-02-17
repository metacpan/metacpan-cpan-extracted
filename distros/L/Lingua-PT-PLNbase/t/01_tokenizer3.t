# -*- cperl -*-

use Test::More tests => 1 + 1;

use Lingua::PT::PLNbase 'abbrev' => 't/tok3.abr';


ok(1);


$i = 0;

  $i++;
  $/ = "\n\n";

  my $input = "";
  my $output = "";
  open T,"<:utf8",  "t/tests3.tok" or die "Cannot open tests file";
  while(<T>) {
    chomp($input = <T>);
    chomp($output = <T>);


    my $tok2 = atomiza($input); # Braga
    is($tok2, $output);
  exit if $i == 14;
  }
  close T;

1;


