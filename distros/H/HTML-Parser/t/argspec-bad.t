use strict;
use warnings;

use HTML::Parser ();
use Test::More tests => 6;

my $p = HTML::Parser->new(api_version => 3);

sub test_error {
    my ($arg, $check_exp) = @_;
    my $error;
    {
        local $@;
        #<<<  do not let perltidy touch this
        $error = $@ || 'Error' unless eval {
            $p->handler(end => "end", $arg);
            1
        };
        #>>>
    }
    like($error, $check_exp);
}

test_error(q(xyzzy),           qr/^Unrecognized identifier xyzzy/);
test_error(q(tagname text),    qr/^Missing comma separator/);
test_error(q(tagname, "text),  qr/^Unterminated literal string/);
test_error(q(tagname, "t\\t"), qr/^Backslash reserved for literal string/);
test_error('"' . ("x" x 256) . '"',
    qr/^Literal string is longer than 255 chars/);

$p->handler(end => sub { is(length(shift), 255) }, '"' . ("x" x 255) . '"');
$p->parse("</x>");
