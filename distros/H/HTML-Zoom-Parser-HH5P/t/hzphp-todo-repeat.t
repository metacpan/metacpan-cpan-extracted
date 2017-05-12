use strictures 1;
use HTML::Zoom;
use Test::More skip_all => "Totally doesn't work yet";

my $z = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )->from_html(<<HTML);
<html>
<body>
<div id="foo"><p/></div>
</body>
</html>
HTML

my @list = qw(foo bar baz);
my $iter = sub { shift @list };

$z->select("#foo")->repeat(sub {
    my $e = $iter->() or return;
    return sub { $_->select("p")->replace_content($e) };
})->to_html;

ok 1;

done_testing;
