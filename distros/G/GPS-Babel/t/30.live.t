use strict;
use warnings;
use Test::More;
use GPS::Babel;

my $babel = GPS::Babel->new;
plan(
  $babel->get_exename
  ? ( tests => 2 )
  : ( skip_all => 'No gpsbabel found on path' )
);

eval {
  $SIG{__WARN__} = sub { die @_ };
  my $info = $babel->get_info;
};

ok !$@, "No errors, warnings";

like $babel->version, qr{^\d+ (?: \. \d+ )+$}x, "Version looks sane";

diag "Testing against ", $babel->get_exename, ", version: ",
 $babel->version, "\n";
