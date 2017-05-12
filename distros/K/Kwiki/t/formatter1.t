use lib 't', 'lib';
use strict;
use warnings;
use TestChunks;
use Kwiki;

my $hub = Kwiki->new->debug->load_hub(
    {
        css_class => 'Kwiki::CSS',
        formatter_class => 'Kwiki::Formatter',
        database_directory => '.',
    }
);

my $formatter = $hub->formatter;

for my $test ((test_chunks(qw(%%% <<<)))) {
    my $wiki_text = $test->chunk('%%%');
    my $expect_html = $test->chunk('<<<');
    my $got_html = $formatter->text_to_html($wiki_text);
    $got_html =~ s{^<div class="wiki">\n(.*)</div>\n\z}{$1}s;
    is($got_html, $expect_html);
}

__END__
%%%
visit SomePage or [forcedlink] (not [=code]) if you can, but avoid the negated !NotALink wherever possible, also, [a titled link TitledLink].
<<<
<p>
visit <a href="?SomePage" class="empty">SomePage</a> or <a href="?forcedlink" class="empty">forcedlink</a> &#40;not <tt>code</tt>&#41; if you can, but avoid the negated NotALink wherever possible, also, <a href="?TitledLink" class="empty">a titled link</a>.
</p>
%%%
Take a look at http://www.domain.com/dir/the%20page.html?this=isthe&query=string ! But don't check !http://www.negated.com/
<<<
<p>
Take a look at <a href="http://www.domain.com/dir/the%20page.html?this=isthe&#38;query=string">http://www.domain.com/dir/the%20page.html?this=isthe&#38;query=string</a> ! But don&#39;t check http://www.negated.com/
</p>
%%%
This is a [named link http://www.kwiki.org/] okay?
<<<
<p>
This is a <a href="http://www.kwiki.org/">named link</a> okay?
</p>
%%%
I wrote a letter to theman+theextra@the-machine.gov. I think it was last Tuesday.
<<<
<p>
I wrote a letter to <a href="mailto:theman+theextra@the-machine.gov">theman+theextra@the-machine.gov</a>. I think it was last Tuesday.
</p>
%%%
You should write to [Ingy ingy@spif-tastical-code.org] and tell him his code is Spiffy! Don't write to !refunds@irs.gov. test
<<<
<p>
You should write to <a href="mailto:ingy@spif-tastical-code.org">Ingy</a> and tell him his code is Spiffy! Don&#39;t write to refunds@irs.gov. test
</p>
%%%
Check out my awesome image http://www.kwiki.org/awesome-image.jpg because it's inline!
<<<
<p>
Check out my awesome image <img src="http://www.kwiki.org/awesome-image.jpg" /> because it&#39;s inline!
</p>
%%%
= Level One Header
=== Level Three Header
===== Level Five Header
======= Level Seven Header
== Trailing Equals =
== Trailing Equals Without Space=
==No Initial Space
<<<
<h1>Level One Header</h1>
<h3>Level Three Header</h3>
<h5>Level Five Header</h5>
======= Level Seven Header
<h2>Trailing Equals</h2>
<h2>Trailing Equals Without Space=</h2>
<p>
==No Initial Space
</p>
%%%
This is *strong*
<<<
<p>
This is <strong>strong</strong>
</p>
%%%
== A *Header*
<<<
<h2>A <strong>Header</strong></h2>
%%%
More *strong*
<<<
<p>
More <strong>strong</strong>
</p>
%%%
Use *==* for h2s.
<<<
<p>
Use <strong>==</strong> for h2s.
</p>
%%%
This is *strong
stuff* man
<<<
<p>
This is <strong>strong
stuff</strong> man
</p>
%%%
Paragraph one.
<<<
<p>
Paragraph one.
</p>
%%%
Paragraph one.

Paragraph two.
<<<
<p>
Paragraph one.

</p>
<p>
Paragraph two.
</p>
%%%
*this* /that/ _the other_
<<<
<p>
<strong>this</strong> <em>that</em> <u>the other</u>
</p>
%%%
this -- that --- the other
<<<
<p>
this &#8211; that &#8212; the other
</p>
%%%
a -- b --- -blat- c

-----

-- d

e ---

*I paused--- -then deleted- oops*
<<<
<p>
a &#8211; b &#8212; <del>blat</del> c

</p>
<hr />
<p>
&#8211; d

</p>
<p>
e &#8212;

</p>
<p>
<strong>I paused&#8212; <del>then deleted</del> oops</strong>
</p>
%%%
This is *strong*

This is not
<<<
<p>
This is <strong>strong</strong>

</p>
<p>
This is not
</p>
%%%
with *two* lines <&amp;> stuff.
<<<
<p>
with <strong>two</strong> lines &lt;&#38;amp;&gt; stuff.
</p>
%%%
This is a *paragraph* of /text/,
with two lines <&amp;> stuff.
<<<
<p>
This is a <strong>paragraph</strong> of <em>text</em>,
with two lines &lt;&#38;amp;&gt; stuff.
</p>
%%%
== Simple Header
    sub foo {
        ...
    }
-----
Another Paragraph.

* One
00 Foo
00 Bar /empha/
00 LinkInALink
 bar
* Two *strong*

=== Conclusion ======
We can /clearly/ see that the /WaflWay/
is /the *best* way/ to be.

xxx /*-[= pedantic ]-*/ _xxx_
<<<
<h2>Simple Header</h2>
<pre class="formatter_pre">sub foo {
    ...
}
</pre>
<hr />
<p>
Another Paragraph.

</p>
<ul>
<li>One</li>

<ol>
<li>Foo</li>
<li>Bar <em>empha</em></li>
<li><a href="?LinkInALink" class="empty">LinkInALink</a></li>
</ol></ul>
<pre class="formatter_pre">bar
</pre>
<ul>
<li>Two <strong>strong</strong></li>
</ul>

<h3>Conclusion</h3>
<p>
We can <em>clearly</em> see that the <em><a href="?WaflWay" class="empty">WaflWay</a></em>
is <em>the <strong>best</strong> way</em> to be.

</p>
<p>
xxx <em><strong><del><tt> pedantic </tt></del></strong></em> <u>xxx</u>
</p>
%%%
Okay, so there's this bug. I'll talk about a path to /etc/modules.autoload and then write some [=inline stuff].

Here's the second paragraph.

=== /usr/local
<<<
<p>
Okay, so there&#39;s this bug. I&#39;ll talk about a path to /etc/modules.autoload and then write some <tt>inline stuff</tt>.

</p>
<p>
Here&#39;s the second paragraph.

</p>
<h3>/usr/local</h3>
