use strict;
use warnings;

use Test::More;
use List::Util 1.56;
use List::Util::MaybeXS;
use List::Util::PP;

is_deeply [sort @List::Util::MaybeXS::EXPORT], [sort @List::Util::EXPORT],
  'same exports as List::Util';
is_deeply [sort @List::Util::MaybeXS::EXPORT_OK], [sort @List::Util::EXPORT_OK],
  'same optional exports as List::Util';
is_deeply \%List::Util::MaybeXS::EXPORT_TAGS, \%List::Util::EXPORT_TAGS,
  'same export tags as List::Util';

is_deeply [sort @List::Util::PP::EXPORT], [sort @List::Util::EXPORT],
  'same PP exports as List::Util';
is_deeply [sort @List::Util::PP::EXPORT_OK], [sort @List::Util::EXPORT_OK],
  'same PP optional exports as List::Util';
is_deeply \%List::Util::PP::EXPORT_TAGS, \%List::Util::EXPORT_TAGS,
  'same PP export tags as List::Util';

for my $sub (List::Util::PP::uniq(sort(
    @List::Util::PP::EXPORT,
    @List::Util::PP::EXPORT_OK,
    (map @$_, values %List::Util::PP::EXPORT_TAGS),
))) {
  my ($pp, $xs) = do { no strict 'refs'; map \&{$_.'::'.$sub}, qw(List::Util::PP List::Util); };
  is prototype $pp, prototype $xs,
    "$sub prototype is correct";
}

done_testing;
