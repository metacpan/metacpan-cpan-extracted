use strict;
use warnings;
use Test::Base;

plan tests => 1 * blocks;
run_compare input => 'expected';

use HTML::StickyQuery::DoCoMoGUID;

sub filter {
    my $html = shift;
    my $guid = HTML::StickyQuery::DoCoMoGUID->new;
    $guid->sticky( scalarref => \$html );
}

__END__
===
--- input filter chomp
<form action="foo.cgi" method="post">
<input name="bar" />
</form>
--- expected chomp
<form action="foo.cgi?guid=ON" method="post">
<input name="bar" />
</form>
===
--- input filter chomp
<form action="foo.cgi" method="POST">
<input name="bar" />
</form>
--- expected chomp
<form action="foo.cgi?guid=ON" method="POST">
<input name="bar" />
</form>
===
--- input filter chomp
<form action="foo.cgi?foo=bar" method="post">
<input name="bar" />
</form>
--- expected chomp
<form action="foo.cgi?foo=bar&amp;guid=ON" method="post">
<input name="bar" />
</form>
===
--- input filter chomp
<form action="http://example.com/foo.cgi" method="post">
<input name="bar">
</form>
--- expected chomp
<form action="http://example.com/foo.cgi" method="post">
<input name="bar">
</form>
===
--- input filter chomp
<form action="#opps" method="post">
<input name="bar">
</form>
--- expected chomp
<form action="#opps" method="post">
<input name="bar">
</form>
