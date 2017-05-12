#!perl
use strict;

use Test::More tests => 971;

use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');

use HTML::Truncate;
use Encode;

ok( my $ht = HTML::Truncate->new(),
    "HTML::Truncate->new()" );

my $html = join('', <DATA>);
my $original_length = length($html);
is( $original_length, 972, "Test HTML is expected length." );


my $char_count = $original_length - 1;
while ( ( $char_count -= 3 ) > 0 )
{
    ok( $ht->chars($char_count), "Setting chars to $char_count" );

    ok( my $out = $ht->truncate($html), "Truncating HTML" );
    my $copy = $out;
    _strip_html($out);

    is( length($out), $char_count,
        "Length from character count matches expectation." );
    diag("TRUNC: " . $copy);
    diag('STRIP: ' . $out . "\n\n");
}


sub _strip_html {
    # Simple HTML stripper since we know the content is clean for it.
    $_[0] =~ s/\&(?=\S)[^;]+;/./g;
    $_[0] =~ s/<br\s*\/>/./g;
    $_[0] =~ s/<[^>]+>//g;
    $_[0] =~ s/\s\s+/ /g;
    $_[0] =~ s/\A\s+//g;
}

__DATA__
<a href="/yo-ho/blow/the/man.down"><img src="/img/whatever.png" alt="Whatever"
title="Whatever" name="Whatever" class="whatever" /></a>

<div id="piece">

<h2>About  the   &#147;author&#148;</h2>

<div id="whatever">
<p>
  <span class="date">
    11/20/2003
  </span>
  <b>Tags to <i>test</i> and check <tt>and</tt> such</b>.
</p>

<p>
  I think we can do this in a pretty straightforward fashion otherwise.
</p>

<p>
  It&#8217;s <a href="/wherever.html">a link</a> along with <a
     href="http://whatever.com/feat/embraces/why-i-took-the-pen-name.html">this</a>.
  I dislike <a
href="/wherever/20020403.html">formatting dummy <acronym title="hurtful, terrible, mean language">HTML</acronym></a>.
  15<span class="ord">th</span> generation Americans are sometimes decent fellows though gentlemen may differ.
</p>

<blockquote>
<p>
  Now you have plenty to test.
</p>
<cite>&#8212;Moo-cow-moo</cite>
</blockquote>

<p>
  <br /><br />Something else.

</p>

</div>

</div>
