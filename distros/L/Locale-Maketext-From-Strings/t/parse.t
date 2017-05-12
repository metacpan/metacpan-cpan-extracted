use strict;
use warnings;
use Test::More;
use Locale::Maketext::From::Strings;

plan skip_all => 'Cannot read t/i18n/en.strings' unless -r 't/i18n/en.strings';

my $lang = Locale::Maketext::From::Strings->new->parse('t/i18n/en.strings');

is $lang->{hello_user}, 'Hello [sprintf,%s,_1]', 'hello_user';
is $lang->{sprintf}, "sample [sprintf,%s,_1] [sprintf,%d,_2] [sprintf,%.3f,_3] data", 'sprintf';
is $lang->{visit_count}, "this is your [sprintf,%d,_2] visit to our site", 'visit_count';
is $lang->{welcome_message}, "Welcome back, \nwe have missed you", 'welcome_message';

done_testing;
