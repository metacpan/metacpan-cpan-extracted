use Test::More tests => 1;
use HTML::GenToc;

#===================================================

my $toc = new HTML::GenToc();

my $input = <<'HTML';
<html>
<head>
</head>
<body>
  <tochere>
  <h1>The Big Step 1</h1>
  The first heading text hoes here
  <h1>The Big Step 2</h1>
  This is the second heading text
    <h2>second header, first subheader</h2>
    Some subheader text here
    <h2>second header, second subheader</h2>
    Another piece of subheader text here
  <h1>The Big Step</h1>
  Third heading text
  <h1>The Big Step</h1>
  Fourth heading text; anchor above needed uniquifying
  <h1>The big Step</h1>
  Per http://www.w3.org/TR/REC-html40/struct/links.html#h-12.2.1, 
  "Anchor names must be unique within a document. Anchor names that differ only in case may not appear in the same document."
  <h1>The Big Step #6</h1>
  The number/hash sign is allowed in fragments; the fragment starts with the first hash.
  No spec as a reference for this, but the anchors work in Firefox 3 and IE 6.
  <h1>Calculation #7: 7/5>3 or &lt;2?</h1>
  Hash marks in fragments work, as well as '/' and '?' signs. &lt; and > are escaped.
  <h1>#8: start with a number (hash) [pound] {comment} sign</h1>
</body>
</html>
HTML

my $output;

=pod Test 1
--- 1. SEO-friendly anchors ---------------------------------------------------------
Anchors should be generated with SEO-friendly names, i.e. out of the entire
token text, instead of being numeric or reduced to the first word(s) of the token.
In the spirit of http://seo2.0.onreact.com/top-10-fatal-url-design-mistakes, compare:

  http://beachfashion.com/photos/Pamela_Anderson#In_red_swimsuit_in_Baywatch
    vs.
  http://beachfashion.com/photos/Pamela_Anderson#in

Which one speaks your language more, which one will you rather click?

The anchor names generated are compliant with XHTML1.0 Strict. Also, per the
HTML 4.01 spec, anchors that differ only in case may not appear in the same
document and anchor names should be restricted to ASCII characters.
=cut

$output = $toc->generate_toc(
    input => $input,
    inline => 1,
    toc_tag => 'tochere',
    toc_tag_replace => 1,
    to_string => 1,
);

my $good_output = <<'EOT';
<html>
<head>
</head>
<body>
  <h1>Table of Contents</h1>
<ul><li><a href="#The_Big_Step_1">The Big Step 1</a></li>
<li><a href="#The_Big_Step_2">The Big Step 2</a>
<ul><li><a href="#second_header.2C_first_subheader">second header, first subheader</a></li>
<li><a href="#second_header.2C_second_subheader">second header, second subheader</a></li>
</ul></li>
<li><a href="#The_Big_Step">The Big Step</a></li>
<li><a href="#The_Big_Step_3">The Big Step</a></li>
<li><a href="#The_big_Step_4">The big Step</a></li>
<li><a href="#The_Big_Step_.236">The Big Step #6</a></li>
<li><a href="#Calculation_.237:_7.2F5.3E3_or_.3C2.3F">Calculation #7: 7/5>3 or &lt;2?</a></li>
<li><a href="#start_with_a_number_.28hash.29_.5Bpound.5D_.7Bcomment.7D_sign">#8: start with a number (hash) [pound] {comment} sign</a></li>
</ul>

  <h1><a name="The_Big_Step_1">The Big Step 1</a></h1>
  The first heading text hoes here
  <h1><a name="The_Big_Step_2">The Big Step 2</a></h1>
  This is the second heading text
    <h2><a name="second_header.2C_first_subheader">second header, first subheader</a></h2>
    Some subheader text here
    <h2><a name="second_header.2C_second_subheader">second header, second subheader</a></h2>
    Another piece of subheader text here
  <h1><a name="The_Big_Step">The Big Step</a></h1>
  Third heading text
  <h1><a name="The_Big_Step_3">The Big Step</a></h1>
  Fourth heading text; anchor above needed uniquifying
  <h1><a name="The_big_Step_4">The big Step</a></h1>
  Per http://www.w3.org/TR/REC-html40/struct/links.html#h-12.2.1, 
  "Anchor names must be unique within a document. Anchor names that differ only in case may not appear in the same document."
  <h1><a name="The_Big_Step_.236">The Big Step #6</a></h1>
  The number/hash sign is allowed in fragments; the fragment starts with the first hash.
  No spec as a reference for this, but the anchors work in Firefox 3 and IE 6.
  <h1><a name="Calculation_.237:_7.2F5.3E3_or_.3C2.3F">Calculation #7: 7/5>3 or &lt;2?</a></h1>
  Hash marks in fragments work, as well as '/' and '?' signs. &lt; and > are escaped.
  <h1><a name="start_with_a_number_.28hash.29_.5Bpound.5D_.7Bcomment.7D_sign">#8: start with a number (hash) [pound] {comment} sign</a></h1>
</body>
</html>
EOT

is($output, $good_output, "(1) SEO-friendly anchors match");

