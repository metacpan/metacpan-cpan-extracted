use strict;
use warnings;

use Test::More;
use List::Util::MaybeXS;
use List::Util::PP;

plan tests => 3 + @List::Util::PP::EXPORT + @List::Util::PP::EXPORT_OK;

is_deeply [sort @List::Util::PP::EXPORT], [sort @List::Util::MaybeXS::EXPORT],
  'same PP exports as List::Util::MaybeXS';
is_deeply [sort @List::Util::PP::EXPORT_OK], [sort @List::Util::MaybeXS::EXPORT_OK],
  'same PP optional exports as List::Util::MaybeXS';
is_deeply \%List::Util::PP::EXPORT_TAGS, \%List::Util::MaybeXS::EXPORT_TAGS,
  'same PP export tags as List::Util::MaybeXS';

for my $sub (List::Util::PP::uniq(sort(
    @List::Util::PP::EXPORT,
    @List::Util::PP::EXPORT_OK,
    (map @$_, values %List::Util::PP::EXPORT_TAGS),
))) {
  no strict 'refs';
  ok defined &{'List::Util::MaybeXS::'.$sub},
    "$sub exists in MaybeXS";
}
