use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;
use File::Basename;


use Lingua::YALI::LanguageIdentifier;


BEGIN { use_ok('Lingua::YALI::LanguageIdentifier') };
my $identifier = Lingua::YALI::LanguageIdentifier->new();

ok($identifier->add_language("ces", "eng") == 2, "adding two languages");

my $result_ces = $identifier->identify_file(dirname(__FILE__) . '/ces01.txt');
is($result_ces->[0]->[0], 'ces', 'Czech must be detected');
is($result_ces->[1]->[0], 'eng', 'Czech must be detected');

my $result_eng = $identifier->identify_file(dirname(__FILE__) . '/eng01.txt');
is($result_eng->[0]->[0], 'eng', 'English must be detected');
is($result_eng->[1]->[0], 'ces', 'English must be detected');
