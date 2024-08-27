use strict;
use warnings;
use Test::More;

my $class;
{
  package ParserWithHighlightConfig;
  $class = __PACKAGE__;
  use Moo;
  extends 'Pod::Simple::XHTML';
  with 'Pod::Simple::Role::XHTML::WithHighlightConfig';
}

my $parser = $class->new;

$parser->output_string( \(my $output = '') );
my $pod = <<'END_POD';
  =head1 First Heading

  =for html <b>text</b>

  A paragraph.

  =for highlighter language=Perl

    my $var = foo();

  Another paragraph.

  =for highlighter

    Just a verbatim section

  =for highlighter language=javascript line_numbers=1 start_line=5 highlight=1,4-10,20

  Pargraph 3.

    Another verbatim section

  =for highlighter javascript

    Verbatim section with bare language

  =for highlighter line_numbers

    Bad line_numbers setting

  =for highlighter welp=5

    Invalid setting welp

  =cut
END_POD
$pod =~ s/^  //mg;
$parser->parse_string_document($pod);

like $output,
  qr{<b>text</b>},
  'html sections preserved';

like $output,
  qr{<pre><code class="language-perl">  my \$var = foo\(\);</code></pre>},
  'language config set in class';
like $output,
  qr{<pre><code>  Just a verbatim section</code></pre>},
  'empty language config resets settings';
like $output,
  qr{<pre data-start="5" data-line="1,4-10,20" class="line-numbers"><code class="language-javascript">  Another verbatim section</code></pre>},
  'start line, line numbers, highlight lines set properly';
like $output,
  qr{<pre><code class="language-javascript">  Verbatim section with bare language</code></pre>},
  'bare language';

{
  my $match = qr{(?:<dt>Around line (\d+):</dt>\s*<dd>\s*)?<p>Invalid empty line_numbers setting\.</p>};
  like $output, $match, 'errors for invalid line_numbers'
    and $output =~ $match
    and defined $1
    and is "$1", 27, 'error has correct line number';
}

{
  my $match = qr{(?:<dt>Around line (\d+):</dt>\s*<dd>\s*)?<p>Invalid setting (?:&quot;|")welp(?:&quot;|")\.</p>};
  like $output, $match, 'errors for invalid settings'
    and $output =~ $match
    and defined $1
    and is "$1", 31, 'error has correct line number';
}

done_testing;
