# -*- cperl -*-

use Test::More tests => 1 + 9;

use POSIX qw(locale_h);
setlocale(LC_CTYPE, "pt_PT");
#setlocale(LC_CTYPE, "en_GB");
use locale;

BEGIN { use_ok( 'Lingua::PT::PLNbase' ); }

use utf8;

#exit;


$a = 'Çáé';

SKIP: {
  skip "not a good locale", 9 unless $a =~ m!^\w{3}$!;

  $/ = "\n\n";

  my $input = "";
  my $output = "";
  open T, "t/tests.tok" or die "Cannot open tests file";
  while(<T>) {
    chomp($input = <T>);
    chomp($output = <T>);

    my $tok1 = Lingua::PT::PLNbase::tokeniza($input); # Diana
    is($tok1, $output);

  }
  close T;
}

1;


