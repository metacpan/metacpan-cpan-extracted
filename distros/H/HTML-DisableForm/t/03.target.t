#!perl

use strict;
use warnings;
use Test::More tests => 2;
use HTML::DisableForm;

my $df = HTML::DisableForm->new;
my $html = <<EOF;
<html>
<head><title>foobar</title></head>
<body>

<p>abcdefg</p>

<form name="me">
<input type="text" name="foo" value="aaa" />
<textarea name="bar"></textarea>
<input type="submit" name="baz" />
</form>

<form>
<input type="text" name="foo" value="aaa" />
<textarea name="bar"></textarea>
<input type="submit" name="baz" />
</form>

<form name="will_be_ignore">
<input type="text" name="foo" value="aaa" />
<textarea name="bar"></textarea>
<input type="submit" name="baz" />
</form>

</body>
</html>
EOF

my $output = $df->disable_form(
    scalarref    => \$html,
    target => 'me',
);
ok $output;

my $p = HTML::Parser->new(api_version => 3);
$p->handler(start => \&handle_start, "self, tagname, attr");
$p->parse($output);

sub handle_start {
    my ($p, $tagname, $attr) = @_;
    if ($tagname eq 'input' or $tagname eq 'textarea') {
        $p->{disabled_count}++ if $attr->{disabled};
    }
}

is $p->{disabled_count}, 3;
