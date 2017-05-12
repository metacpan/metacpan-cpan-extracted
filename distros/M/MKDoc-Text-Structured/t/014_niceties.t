use warnings;
use strict;
use Test::More 'no_plan';
use lib ('lib', '../lib');
use MKDoc::Text::Structured;

my $text = undef;


$text = MKDoc::Text::Structured::process ("'let's see if simple '' smart quotes work'");
is ($text, "<p>&lsquo;let's see if simple '' smart quotes work&rsquo;</p>");

$text = MKDoc::Text::Structured::process ("'' ''' '' ''''");
is ($text, "<p>'' ''' '' ''''</p>");


$text = MKDoc::Text::Structured::process ('"let"s see if simple "" smart quotes work"');
is ($text, '<p>&ldquo;let&quot;s see if simple &quot;&quot; smart quotes work&rdquo;</p>');

$text = MKDoc::Text::Structured::process ('"" """ "" """"');
is ($text, '<p>&quot;&quot; &quot;&quot;&quot; &quot;&quot; &quot;&quot;&quot;&quot;</p>');

$text = MKDoc::Text::Structured::process ('"<QUOT>"');
is ($text, '<p>&ldquo;&lt;QUOT&gt;&rdquo;</p>');

$text = MKDoc::Text::Structured::process ("This is a test: http://www.google.com/");
is ($text, '<p>This is a test: <a href="http://www.google.com/">http://www.google.com/</a></p>');

$text = MKDoc::Text::Structured::process ("this is cool -- because it should be an em-dash -- and I like it.");
is ($text, '<p>this is cool &mdash; because it should be an em-dash &mdash; and I like it.</p>');

$text = MKDoc::Text::Structured::process ("this is cool-- because it should be an em-dash --and I like it.");
unlike ($text, qr/\&/);

$text = MKDoc::Text::Structured::process ("this is cool - because it should be an en-dash - and I like it.");
is ($text, '<p>this is cool &ndash; because it should be an en-dash &ndash; and I like it.</p>');

$text = MKDoc::Text::Structured::process ("this is cool- because it should be an en-dash -and I like it.");
unlike ($text, qr/\&/);

$text = MKDoc::Text::Structured::process ("I wonder if this works...");
is ($text, '<p>I wonder if this works&hellip;</p>');

$text = MKDoc::Text::Structured::process ("... (...) ... .... ..");
is ($text, '<p>&hellip; (&hellip;) &hellip; .... ..</p>');

$text = MKDoc::Text::Structured::process ("ACLU(American Civil Liberties Union)");
is ($text, '<p><abbr title="American Civil Liberties Union">ACLU</abbr></p>');

$text = MKDoc::Text::Structured::process ('FART(Fat Australian "Red Tigers)');
is ($text, '<p><abbr title="Fat Australian &quot;Red Tigers">FART</abbr></p>');

$text = MKDoc::Text::Structured::process ('FART(Fat Australian "Red" Tigers)');
is ($text, '<p><abbr title="Fat Australian &ldquo;Red&rdquo; Tigers">FART</abbr></p>');

$text = MKDoc::Text::Structured::process ('FART(Fat Australian &<>Red Tigers)');
is ($text, '<p><abbr title="Fat Australian &amp;&lt;&gt;Red Tigers">FART</abbr></p>');

$text = MKDoc::Text::Structured::process ("ACLU (American Civil Liberties Union)");
is ($text, '<p><abbr title="American Civil Liberties Union">ACLU</abbr> (American Civil Liberties Union)</p>');

$text = MKDoc::Text::Structured::process ("(tm), (r), (c)! Roxor 10x2");
is ($text, '<p>&trade;, &reg;, &copy;! Roxor 10&times;2</p>');

$text = MKDoc::Text::Structured::process ("The RSS(RDF Site Summary) is the BBC(British Broadcasting Corporation).");
like ($text, qr#<p>The <abbr title="RDF Site Summary">RSS</abbr>#);
like ($text, qr#<abbr title="British Broadcasting Corporation">BBC</abbr>#);

$text = MKDoc::Text::Structured::process ("BBC(British Broadcasting
Corporation).");
like ($text, qr#<abbr title="British Broadcasting Corporation">BBC</abbr>#);

$text = MKDoc::Text::Structured::process (qq|'I' am 'here'|);
like ($text, qr#&lsquo;I&rsquo;#);
like ($text, qr#&lsquo;here&rsquo;#);

$text = MKDoc::Text::Structured::process (qq|"I" am "here"|);
like ($text, qr#&ldquo;I&rdquo;#);
like ($text, qr#&ldquo;here&rdquo;#);


__END__
