use strict;
use warnings;
use Test::More;

use Locale::PO::Callback;

my $result='';
my $storer = sub { $result .= $_[0]; };
my $rebuilder = Locale::PO::Callback::rebuilder($storer);

my $po = Locale::PO::Callback->new($rebuilder);
$po->create_empty();

my @expected = (
    'msgid ""',
    'msgstr ""',
    '"Project-Id-Version: PACKAGE VERSION\n"',
    '"PO-Revision-Date: xxx\n"',
    '"Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"',
    '"Language-Team: LANGUAGE <LL@li.org>\n"',
    '"MIME-Version: 1.0\n"',
    '"Content-Type: text/plain; charset=UTF-8\n"',
    '"Content-Transfer-Encoding: 8bit\n"',
    );

my @result = split(/\n/, $result);

plan tests => scalar(@result)+1;

is(scalar(@result),
   scalar(@expected),
   "result is as long as expected");

for (my $i=0; $i<scalar(@result); $i++) {
    if ($expected[$i] =~ /^"po-revision-date/i) {
	isnt($expected[$i],
	     $result[$i],
	     "date changes");
    } else {
	is($expected[$i],
	   $result[$i],
	   $expected[$i]);
    }
}
