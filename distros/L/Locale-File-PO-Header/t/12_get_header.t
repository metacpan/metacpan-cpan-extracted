#!perl -T

use strict;
use warnings;

use Test::More tests => 3 + 1;
use Test::NoWarnings;
use Test::Differences;
BEGIN {
    use_ok('Locale::File::PO::Header');
}

my $obj = Locale::File::PO::Header->new;

$obj->msgstr(<<'EOT');
Project-Id-Version: Testproject
Report-Msgid-Bugs-To: <bug@example.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Content-Transfer-Encoding: 8bit
X-Poedit-Language: German
X-Poedit-Country: GERMANY
X-Poedit-SourceCharset: utf-8
EOT

# read keys
eq_or_diff(
    $obj->item('Project-Id-Version'),
    'Testproject',
    'get 1 item of msgstr',
);

eq_or_diff(
    [
        $obj->items( qw(
            Project-Id-Version
            Report-Msgid-Bugs-To_address
            Content-Type
            extended
        ) )
    ],
    [
        'Testproject',
        'bug@example.org',
        'text/plain',
        [
            'X-Poedit-Language',
            'German',
            'X-Poedit-Country',
            'GERMANY',
            'X-Poedit-SourceCharset',
            'utf-8',
        ],
    ],
    'get some items of msgstr',
);
