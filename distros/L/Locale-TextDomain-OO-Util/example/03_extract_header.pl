#!perl ## no critic (TidyCode)

use strict;
use warnings;

use Data::Dumper ();
use Locale::TextDomain::OO::Util::ExtractHeader;

our $VERSION = 0;

my $extractor = Locale::TextDomain::OO::Util::ExtractHeader->instance;

() = print {*STDOUT} Data::Dumper ## no critic (LongChainsOfMethodCalls)
    ->new(
        [
            $extractor->extract_header_msgstr(<<'EOT'),
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1
X-Lexicon-Class: Foo::Bar
EOT
        ],
        [ qw( extract ) ],
    )
    ->Indent(1)
    ->Quotekeys(0)
    ->Sortkeys(1)
    ->Useqq(1)
    ->Dump;

# $Id: 03_extract_header.pl 527 2014-10-18 11:01:51Z steffenw $

__END__

Output:

$extract = {
  charset => "UTF-8",
  lexicon_class => "Foo::Bar",
  nplurals => 2,
  plural => "n != 1",
  plural_code => sub { "DUMMY" }
};
