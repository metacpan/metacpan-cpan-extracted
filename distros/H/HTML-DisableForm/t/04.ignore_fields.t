#!perl

use strict;
use warnings;
use Test::More tests => 3;
use HTML::DisableForm;

my $df = HTML::DisableForm->new;
my $html = <<EOF;
<html>
<head><title>foobar</title></head>
<body>

<p>abcdefg</p>
<form>
<input type="text" name="foo" value="aaa" />
<textarea name="bar"></textarea>
<input type="submit" name="baz" />
</form>

</body>
</html>
EOF

my $output = $df->disable_form(
    scalarref     => \$html,
    ignore_fields => [qw/foo bar/],
);
ok $output;

my $p = HTML::Parser->new(api_version => 3);
$p->handler(start => \&handle_start, "self, tagname, attr");
$p->parse($output);

sub handle_start {
    my ($p, $tagname, $attr) = @_;
    if ($tagname eq 'input' or $tagname eq 'textarea') {
        if ($attr->{disabled}) {
            $p->{disabled_count}++ ;
            is $attr->{name}, 'baz';
        }
    }
}

is $p->{disabled_count}, 1;
