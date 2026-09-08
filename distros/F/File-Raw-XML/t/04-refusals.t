#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML;

# Every refusal the lexer makes, each with the message shape: the prefix,
# what, and either a byte offset with sixteen bytes of context or "at end
# of input". The message is the feature; assert on it, not on death.

sub refused {
    my ($bytes, @opts) = @_;
    my $ok = eval { File::Raw::XML::_lex($bytes, @opts); 1 };
    return $ok ? '' : $@;
}

sub refuses {
    my ($bytes, $re, $name, @opts) = @_;
    my $msg = refused($bytes, @opts);
    like($msg, qr/^File::Raw::XML: /, "$name: the prefix") or return;
    like($msg, $re, "$name: the reason and offset");
    # croak appends its " at FILE line N." to a message with no newline
    like($msg, qr/(?:at byte offset \d+ near ".*"|at end of input)(?: at \S+ line \d+\.)?\n?\z/,
         "$name: context or end of input");
}

# DOCTYPE, in every position
refuses(qq{<!DOCTYPE a><a/>},         qr/DOCTYPE.* at byte offset 0/,  'DOCTYPE before the root');
refuses(qq{<a><!DOCTYPE a></a>},      qr/DOCTYPE.* at byte offset 3/,  'DOCTYPE inside the root');
refuses(qq{<a/><!DOCTYPE a>},         qr/DOCTYPE.* at byte offset 4/,  'DOCTYPE after the root');
refuses(qq{<!DOCTYPE a [<!ENTITY x "y">]><a/>}, qr/DOCTYPE.* at byte offset 0/, 'DOCTYPE with an internal subset');
refuses(qq{<!ENTITY x "y"><a/>},      qr/DOCTYPE.* at byte offset 0/,  '<!ENTITY on its own');
refuses(qq{<a><!ELEMENT a ANY></a>},  qr/DOCTYPE.* at byte offset 3/,  '<!ELEMENT');
refuses(qq{<a><![INCLUDE[x]]></a>},   qr/DOCTYPE.* at byte offset 3/,  'a conditional section');
refuses(qq{<a><!x></a>},              qr/DOCTYPE.* at byte offset 3/,  'any other <!');

# encodings
refuses("\xFE\xFF\0<\0a\0/\0>",       qr/UTF-16 or UTF-32 byte order mark.* at byte offset 0/, 'UTF-16 BE with a BOM');
refuses("\xFF\xFE<\0a\0/\0>\0",       qr/UTF-16 or UTF-32 byte order mark/, 'UTF-16 LE with a BOM');
refuses("\0\0\xFE\xFF\0\0\0<",        qr/UTF-32 byte order mark/, 'UTF-32 BE with a BOM');
refuses("<\0a\0/\0>\0",               qr/UTF-16 without a byte order mark/, 'UTF-16 LE without a BOM');
refuses("\0<\0a\0/\0>",               qr/UTF-16 without a byte order mark/, 'UTF-16 BE without a BOM');
refuses(qq{<?xml version="1.0" encoding="ISO-8859-1"?><a/>}, qr/only the UTF-8 encoding is accepted at byte offset 0/, 'a declared ISO-8859-1');
refuses(qq{<?xml version="1.0" encoding="UTF-16"?><a/>},     qr/only the UTF-8 encoding/, 'a declared UTF-16');
refuses(qq{<?xml version="1.1"?><a/>},                        qr/only XML version 1.0 is accepted/, 'version 1.1');
refuses(qq{<?xml encoding="UTF-8"?><a/>},                     qr/must start with version/, 'a declaration without version');
refuses(qq{<?xml version="1.0"?},                             qr/unterminated XML declaration/, 'an unterminated declaration');
refuses(qq{<?xml version="1.0" standalone="maybe"?><a/>},     qr/malformed standalone/, 'standalone must be yes or no');

# the reserved PI target
refuses(qq{<a><?xml version="1.0"?></a>}, qr/reserved.* at byte offset 5/, '<?xml after offset 0');
refuses(qq{<a><?XML x?></a>},             qr/reserved/, '<?XML in another case');
refuses(qq{<a><?xMl x?></a>},             qr/reserved/, '<?xMl in a mixed case');
refuses(qq{<?XML version="1.0"?><a/>},    qr/reserved.* at byte offset 2/, 'even at offset 0, the wrong case is not a declaration');
refuses(qq{<a><?p?data?></a>},            qr/expected whitespace after a processing instruction target/, 'a PI target must be followed by whitespace or ?>');

# comments
refuses(qq{<a><!-- a -- b --></a>},  qr/-- is not allowed inside a comment at byte offset 10/, '-- inside a comment');
refuses(qq{<a><!-- a --->},          qr/-- is not allowed inside a comment/, 'a comment ending --->');

# content
refuses(qq{<a>]]></a>},              qr/\]\]> is not allowed in content at byte offset 3/, ']]> in text');
refuses(qq{<a>&foo;</a>},            qr/undeclared entity.* at byte offset 3/, 'an undeclared entity');
refuses(qq{<a>&nbsp;</a>},           qr/undeclared entity/, '&nbsp; is undeclared without a DTD');
refuses(qq{<a>&lt</a>},              qr/undeclared entity/, 'a reference without its semicolon');
refuses(qq{<a>&#;</a>},              qr/malformed character reference at byte offset 3/, '&#; with no digits');
refuses(qq{<a>&#x;</a>},             qr/malformed character reference/, '&#x; with no digits');
refuses(qq{<a>&#12a;</a>},           qr/malformed character reference/, 'a decimal reference with a hex digit');
refuses(qq{<a>&#x1G;</a>},           qr/malformed character reference/, 'a hex reference with a non-hex digit');
refuses(qq{<a>& b</a>},              qr/undeclared entity/, 'a bare ampersand');

# attributes
refuses(qq{<a b="<"/>},              qr/a literal < is not allowed in an attribute value at byte offset 6/, 'a literal < in an attribute value');
refuses(qq{<a b=1/>},                qr/expected a quoted attribute value at byte offset 5/, 'an unquoted attribute value');
refuses(qq{<a b/>},                  qr/expected = after an attribute name at byte offset 4/, 'an attribute with no value');
refuses(qq{<a b="1"c="2"/>},         qr/expected whitespace before an attribute at byte offset 8/, 'two attributes with no whitespace between');
refuses(qq{<a b="1" b="2"/>},        qr/attribute given twice at byte offset 9/, 'a duplicate attribute, at the second');
refuses(qq{<a b="1},                 qr/unterminated attribute value at byte offset 5/, 'an unterminated attribute value');
refuses(qq{<a b=},                   qr/unterminated attribute at byte offset 3/, 'an attribute cut off at its =');

# names
refuses(qq{<1a/>},                   qr/expected a name at byte offset 1/, 'a name starting with a digit');
refuses(qq{<a:b:c/>},                qr/one colon.* at byte offset 4/, 'two colons');
refuses(qq{<:a/>},                   qr/one colon.* at byte offset 1/, 'a leading colon');
refuses(qq{<a:/>},                   qr/one colon.* at byte offset 1/, 'a trailing colon');
refuses(qq{<a b:="1"/>},             qr/one colon/, 'a trailing colon on an attribute');
refuses(qq{<a ::b="1"/>},            qr/one colon/, 'a leading colon on an attribute');
refuses(qq{< a/>},                   qr/expected a name at byte offset 1/, 'whitespace after <');
refuses(qq{<a></ a>},                qr/expected a name at byte offset 5/, 'whitespace after </');

# unterminated constructs report where they began, or the end
refuses(qq{<a},                      qr/unterminated start tag at byte offset 0/, 'an unterminated start tag');
refuses(qq{<a b="1"},                qr/unterminated start tag at byte offset 0/, 'an unterminated start tag after an attribute');
refuses(qq{<a/},                     qr/expected \/> to close an empty element at byte offset 2/, 'a lone / in a tag');
refuses(qq{<a></a},                  qr/unterminated end tag at byte offset 3/, 'an unterminated end tag');
refuses(qq{<a><!-- x},               qr/unterminated comment at byte offset 3/, 'an unterminated comment');
refuses(qq{<a><![CDATA[x},           qr/unterminated CDATA section at byte offset 3/, 'an unterminated CDATA section');
refuses(qq{<a><?p x},                qr/unterminated processing instruction at byte offset 3/, 'an unterminated PI');
refuses(qq{<a>text},                 qr/^ok$/, 'text at end of input is the parser\'s problem, not the lexer\'s') if 0;
is(refused(qq{<a>text}), '', 'unclosed elements are the parser\'s problem; the lexer streams to EOF');

# max_bytes
is(refused(qq{<a/>}, 4), '', 'max_bytes exactly equal is accepted');
refuses(qq{<a/>}, qr/input exceeds max_bytes at byte offset 3/, 'max_bytes exceeded by one', 3);
is(refused(qq{<a/>}, 0), '', 'max_bytes 0 is no cap');

# the context never carries a raw NUL and never runs past sixteen bytes
{
    my $msg = refused("<a>\0" . ("x" x 40) . "</a>");
    unlike($msg, qr/\0/, 'a NUL in the input is rendered, not embedded');
    like($msg, qr/near "\\x00x{15}"/, 'and the context is sixteen input bytes');
}

done_testing;
