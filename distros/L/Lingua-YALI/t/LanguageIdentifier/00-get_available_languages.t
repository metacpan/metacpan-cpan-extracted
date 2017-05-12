use strict;
use warnings;

use Test::More tests => 4;
use Lingua::YALI::LanguageIdentifier;
use Time::HiRes;

BEGIN { use_ok('Lingua::YALI::LanguageIdentifier') };
my $identifier = Lingua::YALI::LanguageIdentifier->new();

# retrieve language for the fist time
my $get_available1_begin = Time::HiRes::time();
my $languages1 = $identifier->get_available_languages();
my $get_available1_end = Time::HiRes::time();

my $languageCount1 = scalar @$languages1;
is($languageCount1, 122, "Language count");

# retrieve language for the second time
my $get_available2_begin = Time::HiRes::time();
my $languages2 = $identifier->get_available_languages();
my $get_available2_end = Time::HiRes::time();

my $languageCount2 = scalar @$languages2;
is($languageCount1, $languageCount2, "number of languages must be same as before");

# loading for the second time has to be shorter
my $get1 = $get_available1_end - $get_available1_begin;
my $get2 = $get_available2_end - $get_available2_begin;
#print STDERR "\n - $get1 - $get2 - \n";

ok($get2 < $get1, "loading for the second time has to be faster");



#$identifier->add_language("ces");

#$identifier->add_language("ces", "slk", "deu");

#$identifier->get_registred_languages();




