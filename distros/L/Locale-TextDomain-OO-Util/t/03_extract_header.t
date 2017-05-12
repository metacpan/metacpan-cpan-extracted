#!perl -T

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    use_ok 'Locale::TextDomain::OO::Util::ExtractHeader';
}

my $extractor = Locale::TextDomain::OO::Util::ExtractHeader->instance;

eq_or_diff
    my $extract_ref = $extractor->extract_header_msgstr(<<'EOT'),
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1
X-Lexicon-Class: Foo::Bar
EOT
    {
        charset       => 'UTF-8',
        nplurals      => 2,
        plural        => 'n != 1',
        plural_code   => sub {},
        lexicon_class => 'Foo::Bar',
    },
    'extract_ok';

eq_or_diff
    {
        map {
            $_ => $extract_ref->{plural_code}->($_);
        } qw( 0 1 2 )
    },
    {
        0 => 1,
        1 => 0,
        2 => 1,
    },
    'run plural_code';

throws_ok
    sub { $extractor->extract_header_msgstr },
    qr{ \A \QHeader is not defined\E \b }xms,
    'no header';

throws_ok
    sub { $extractor->extract_header_msgstr(<<'EOT') },
Content-Type: text/plain; charset=UTF-8
EOT
    qr{ \A \QPlural-Forms not found in header\E \b }xms,
    'no plural forms';

throws_ok
    sub { $extractor->extract_header_msgstr(<<'EOT') },
Plural-Forms: nplurals=2; plural=n != 1;
EOT
    qr{ \A \QContent-Type with charset not found in header\E \b }xms,
    'no charset';
