use strict;
use Test::More (tests => 93);

BEGIN
{
    use_ok("HTML::Parser::Stacked");
}

my $p = HTML::Parser::Stacked->new(
    start_h => [ [ \&collect_a, \&collect_img ], "self,tag,attr" ]
);
ok($p);
isa_ok($p, 'HTML::Parser::Stacked');

my $link_count = 0;
my $img_count = 0;
sub collect_a {
    my ($self, $tag, $attr) = @_;
    is(scalar @_, 3);
    isa_ok($self, "HTML::Parser::Stacked");
    is(ref $tag, '');
    isa_ok($attr, 'HASH');
    if ($tag eq 'a') {
         $link_count++;
    }
}
    
sub collect_img {
    my ($self, $tag, $attr) = @_;
    is(scalar @_, 3);
    isa_ok($self, "HTML::Parser::Stacked");
    is(ref $tag, '');
    isa_ok($attr, 'HASH');
    if ($tag eq 'img') {
         $img_count++;
    }
}

$p->parse(<<EOHTML);
<html>
<body>
    <a href="http://www.example.com">link1</a>
    <a href="http://www.example.com">link2</a>
    <a href="http://www.example.com">link3</a>
    <img src="http://www.example.com/image.gif">
    <img src="http://www.example.com/image.gif">
    <img src="http://www.example.com/image.gif">
    <img src="http://www.example.com/image.gif">
    <a href="http://www.example.com">link4</a>
    <img src="http://www.example.com/image.gif">
</body>
</html>
EOHTML
$p->eof;

is($link_count, 4);
is($img_count, 5);