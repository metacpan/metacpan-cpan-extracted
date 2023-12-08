#!perl -T
use Test::More tests => 6;

use v5.10;
use strict;
use warnings;

use Locale::CLDR;

# deep recursion
my $locale = Locale::CLDR->new(language_id => 'und', region_id => 'AQ');
is ($locale->likely_subtag()->id(), 'und_Latn_AQ', 'Likely Subtag und_AQ');
diag $locale->region_name;
$locale = Locale::CLDR->new(language_id => 'und', region_id => 'BV');
is ($locale->likely_subtag()->id(), 'und_Latn_BV', 'Likely Subtag und_BV');
diag $locale->region_name;
$locale = Locale::CLDR->new(language_id => 'und', region_id => 'CP');
is ($locale->likely_subtag()->id(), 'und_Latn_CP', 'Likely Subtag und_CP');
diag $locale->region_name;
$locale = Locale::CLDR->new(language_id => 'und', region_id => 'GS');
is ($locale->likely_subtag()->id(), 'und_Latn_GS', 'Likely Subtag und_GS');
diag $locale->region_name;
$locale = Locale::CLDR->new(language_id => 'und', region_id => 'HM');
is ($locale->likely_subtag()->id(), 'und_Latn_HM', 'Likely Subtag und_HM');
diag $locale->region_name;
$locale = Locale::CLDR->new(language_id => 'und', region_id => 'AG');
is ($locale->likely_subtag()->id(), 'en_Latn_AG', 'Likely Subtag und_AG');
diag $locale->region_name;
