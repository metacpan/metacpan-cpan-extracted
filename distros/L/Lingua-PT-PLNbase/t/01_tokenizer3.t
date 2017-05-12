# -*- cperl -*-

use Test::More tests => 1 + 1;
use POSIX qw(locale_h);
setlocale(LC_CTYPE, "pt_PT");

use Lingua::PT::PLNbase 'abbrev' => 't/tok3.abr';

use locale;

ok(1);

$a = '«·È';

$i = 0;
SKIP: {
  skip "not a good locale", 1 unless $a =~ m!^\w{3}$!;

  $i++;
  $/ = "\n\n";

  my $input = "";
  my $output = "";
  open T, "t/tests3.tok" or die "Cannot open tests file";
  while(<T>) {
    chomp($input = <T>);
    chomp($output = <T>);


    my $tok2 = atomiza($input); # Braga
    is($tok2, $output);
  exit if $i == 14;
  }
  close T;
}

1;


