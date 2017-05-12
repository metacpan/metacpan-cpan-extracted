#!perl
use strict;
use warnings;

use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');

use HTML::Truncate;


my $ht = HTML::Truncate->new( chars => 40 );

my $html = join('', <DATA>);

my $original_length = length($html);

my $out = $ht->truncate($html);
#    _strip_html( $out );

print $out, $/;
my $copy = $out;
_strip_html($copy);

print $copy, $/;

print length($copy), " == ", $ht->chars, $/;

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
