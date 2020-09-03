use strict;
use warnings;

use HTML::Parser ();
use Test::More tests => 3;

my @data;
my $p = HTML::Parser->new(api_version => 3);
$p->handler(default => \@data, '@{event, text, is_cdata}');
$p->parse(<<EOT)->eof;
<xmp><foo></xmp>x<plaintext><foo>
</plaintext>
foo
EOT

for (@data) {
    $_ = "" unless defined;
}

my $doc = join(":", @data);

#diag $doc;

is(
    $doc,
    "start_document:::start:<xmp>::text:<foo>:1:end:</xmp>::text:x::start:<plaintext>::text:<foo>
</plaintext>
foo
:1:end_document::"
);

@data = ();
$p->closing_plaintext('yep, emulate gecko');
$p->parse(<<EOT)->eof;
<plaintext><foo>
</plaintext>foo<b></b>
EOT

for (@data) {
    $_ = "" unless defined;
}

$doc = join(":", @data);

#diag $doc;

is(
    $doc, "start_document:::start:<plaintext>::text:<foo>
:1:end:</plaintext>::text:foo::start:<b>::end:</b>::text:
::end_document::"
);

@data = ();
$p->closing_plaintext('yep, emulate gecko (2)');
$p->parse(<<EOT)->eof;
<plaintext><foo>
foo<b></b>
EOT

$doc = join(":", map { defined $_ ? $_ : "" } @data);

is(
    $doc, "start_document:::start:<plaintext>::text:<foo>
foo<b></b>
:1:end_document::"
);
