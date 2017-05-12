#!perl

use strict;
use warnings;
use Test::More tests => 5;
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

my $output = $df->readonly_form(
    scalarref => \$html
);
ok $output;

my $p = HTML::Parser->new(api_version => 3);
$p->handler(start => \&handle_start, "self, tagname, attr");
$p->parse($output);

sub handle_start {
    my ($p, $tagname, $attr) = @_;
    if ($tagname eq 'input' or $tagname eq 'textarea') {
        ok $attr->{readonly};
        $p->{readonly_count}++ if $attr->{readonly};
    }
}

is $p->{readonly_count}, 3;
