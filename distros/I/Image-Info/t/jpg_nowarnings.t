use strict;
use warnings;
use FindBin qw($RealBin);

use Test::More 'no_plan';

use Image::Info qw(image_info);

$^W = 1;
my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

{
  my $info = image_info("$RealBin/../img/test-rt133006.jpg");
  ok !$info->{error}, 'no error'
      or diag "Got Error: $info->{error}";
  is_deeply \@warnings, []; @warnings = ();
}
