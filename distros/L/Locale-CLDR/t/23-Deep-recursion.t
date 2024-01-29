#!perl -T

use strict;
use warnings;

use Test::More tests => 7;
use ok 'Locale::CLDR';

# deep recursion
my $locale = Locale::CLDR->new(language_id => 'und', region_id => 'AQ');
is ($locale->likely_subtag()->id(), 'und_Latn_AQ', 'Likely Subtag und_AQ');
$locale = Locale::CLDR->new(language_id => 'und', region_id => 'BV');
is ($locale->likely_subtag()->id(), 'und_Latn_BV', 'Likely Subtag und_BV');
$locale = Locale::CLDR->new(language_id => 'und', region_id => 'CP');
is ($locale->likely_subtag()->id(), 'und_Latn_CP', 'Likely Subtag und_CP');
$locale = Locale::CLDR->new(language_id => 'und', region_id => 'GS');
is ($locale->likely_subtag()->id(), 'und_Latn_GS', 'Likely Subtag und_GS');
$locale = Locale::CLDR->new(language_id => 'und', region_id => 'HM');
is ($locale->likely_subtag()->id(), 'und_Latn_HM', 'Likely Subtag und_HM');
$locale = Locale::CLDR->new(language_id => 'und', region_id => 'AG');
is ($locale->likely_subtag()->id(), 'en_Latn_AG', 'Likely Subtag und_AG');