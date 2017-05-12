#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

require Data::Dumper;
require Locale::File::PO::Header;

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

() = print
    "get 1 item of msgstr as scalar:\n",
    $obj->item('Project-Id-Version'),
    "\n";

my @items = $obj->items(
    qw(Project-Id-Version Report-Msgid-Bugs-To_address extended),
);
() = print
    "get 0 or many items of msgstr as array:\n",
    Data::Dumper->new([ \@items ], ['items'])->Indent(1)->Dump;

# $Id: 13_get_header.pl 602 2011-11-13 13:49:23Z steffenw $

__END__

Output:

get 1 item of msgstr as scalar:
Testproject
get 0 or many items of msgstr as array:
$items = [
  'Testproject',
  'bug@example.org',
  [
    'X-Poedit-Language',
    'German',
    'X-Poedit-Country',
    'GERMANY',
    'X-Poedit-SourceCharset',
    'utf-8'
  ]
];
