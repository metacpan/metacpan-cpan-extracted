use Test::More tests => 3;
use HTML::StickyQuery;

{
    my $s = HTML::StickyQuery->new;
    $s->sticky(
       file => './t/test2.html',
       param => {
	   SID => 'xyz',
	   foo => 'baz'
       }
    );
    like($s->output, qr/SID=xyz/);
    like($s->output, qr/foo=baz/);
}

{
    my $s = HTML::StickyQuery->new(keep_original => 0);
    $s->sticky(
       file => './t/test2.html',
       param => {SID => 'xyz'}
    );
    like($s->output, qr#<a href="\./test\.cgi\?SID=xyz">#);
}
