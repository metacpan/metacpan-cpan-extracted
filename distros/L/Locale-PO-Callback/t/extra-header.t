#!/usr/bin/perl

use strict;
use warnings;
use Locale::PO::Callback;
use Test::More;

plan tests => 2;

my $rebuilt = undef;
my $silly = '';
my $filename = 't/demo.po';

my $expected_before = <<'EOF';
# Comments at the top of the file.
msgid ""
msgstr ""
"Project-Id-Version: Demo of a .po file\n"
"PO-Revision-Date: 1975-01-30 00:00 +0000\n"
"Last-Translator: Thomas Thurman <marnanel@cpan.org>\n"
"Language-Team: test <test@example.org>\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"

EOF

my $expected_after = <<'EOF';
# Comments at the top of the file.
msgid ""
msgstr ""
"Project-Id-Version: Demo of a .po file\n"
"PO-Revision-Date: 1975-01-30 00:00 +0000\n"
"Last-Translator: Thomas Thurman <marnanel@cpan.org>\n"
"Language-Team: test <test@example.org>\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Silly: (wombats)\n"

EOF

sub store_headers {
    my ($line) = @_;

    $rebuilt = $line unless $rebuilt;
}

use Data::Dumper;

my $rebuilder = Locale::PO::Callback::rebuilder(\&store_headers);
my $po = Locale::PO::Callback->new($rebuilder);
$po->read($filename);

is($rebuilt, $expected_before,
   "headers before insertion are as expected");

################################################################

sub add_header {
    my ($data) = @_;

    if ($data->{'type'} eq 'header') {
	$data->{'headers'}->{'silly'} = '(wombats)';
    }

    $rebuilder->($data);
}

$rebuilt = undef;

$po = Locale::PO::Callback->new(\&add_header);
$po->read($filename);

is($rebuilt, $expected_after,
   "headers after insertion are as expected");
