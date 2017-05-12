# -*- cperl -*-

use warnings;
use strict;

use Test::More tests => 11;
use Lingua::FreeLing3::Document;
use Lingua::FreeLing3::Paragraph;
use Lingua::FreeLing3::Bindings;

my $doc = Lingua::FreeLing3::Document->new();

ok     $doc => 'Document is defined';
isa_ok $doc => 'Lingua::FreeLing3::Document';
isa_ok $doc => 'Lingua::FreeLing3::Bindings::document';

my $p1 = Lingua::FreeLing3::Paragraph->new();
my $p2 = Lingua::FreeLing3::Bindings::paragraph->new();

is $doc->length => 0;
$doc->push($p1, $p2);
is $doc->length => 2;

my @elems = $doc->paragraphs();

is scalar(@elems) => 2;
isa_ok $elems[0] => 'Lingua::FreeLing3::Paragraph';
isa_ok $elems[1] => 'Lingua::FreeLing3::Paragraph';

is $doc->paragraph(2) => undef;
isa_ok $doc->paragraph(0) => 'Lingua::FreeLing3::Paragraph';
isa_ok $doc->paragraph(1) => 'Lingua::FreeLing3::Paragraph';



