use warnings;
use strict;
use Test::More 'no_plan';
use lib ('lib', '../lib');
use MKDoc::Text::Structured;

my $text = undef;

$text = MKDoc::Text::Structured::Inline::process_entities_only ("My (c) \" symbol \"shouldn't\" be *bold* -- or http://example.com/ 'linked'");
is ($text, 'My &copy; &quot; symbol &ldquo;shouldn\'t&rdquo; be *bold* &mdash; or http://example.com/ &lsquo;linked&rsquo;');

$text = MKDoc::Text::Structured::Inline::process_entities_only ('Stuff with " & < > in it');
is ($text, 'Stuff with &quot; &amp; &lt; &gt; in it');

__END__
