use Test::More tests => 4;
use Test::Exception;
use File::Basename;
use Carp;
use strict;
use warnings;


use Lingua::YALI::LanguageIdentifier;


BEGIN { use_ok('Lingua::YALI::LanguageIdentifier') };
my $identifier = Lingua::YALI::LanguageIdentifier->new();

ok($identifier->add_language("ces", "eng") == 2, "adding two languages");

my $result = $identifier->identify_string("CPAN, the Comprehensive Perl Archive Network, is an archive of modules written in Perl.");
is($result->[0]->[0], 'eng', 'English must be detected');
is($result->[1]->[0], 'ces', 'Czech must not be detected');