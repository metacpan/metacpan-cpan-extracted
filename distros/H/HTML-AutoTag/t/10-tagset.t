#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use HTML::AutoTag;

eval "use HTML::Tagset 3.20";
plan skip_all => "HTML::Tagset required" if $@;

plan tests => 174;

my ( @empty, %empty, @containers, %containers );
{   no warnings;
    @empty = (
        ( keys %HTML::Tagset::emptyElement ),
        ( keys %HTML::Tagset::optionalEndTag ),
    );
    %empty = map { $_ => undef } @empty;

    @containers = (
        ( keys %HTML::Tagset::optionalEndTag ),
        ( keys %HTML::Tagset::isPhraseMarkup ),
        ( keys %HTML::Tagset::isHeadElement ),
        ( keys %HTML::Tagset::isList ),
        ( keys %HTML::Tagset::isTableElement ),
        ( keys %HTML::Tagset::isFormElement ),
        ( keys %HTML::Tagset::isBodyElement ),
        ( keys %HTML::Tagset::isHeadOrBodyElement ),
        ( keys %HTML::Tagset::isKnown ),
    );
    %containers = map { $_ => undef } @containers;
}

my $auto = HTML::AutoTag->new( indent => '', sorted => 1 );

my @given;
push @given, $auto->tag( tag => $_ ) for sort keys %empty;
push @given, $auto->tag( tag => $_, cdata => '' ) for sort keys %containers;

for (sort keys %HTML::Tagset::linkElements) {
    my $attr = { map { $_ => 'value' } @{ $HTML::Tagset::linkElements{$_} } };
    push @given, $auto->tag( tag => $_, attr => $attr, cdata => '' );
}

for (sort keys %HTML::Tagset::boolean_attr) {
    my $thingy = $HTML::Tagset::boolean_attr{$_};
    my $attr = ref($thingy) eq 'HASH' ? $thingy : { $thingy => 1 };
    push @given, $auto->tag( tag => $_, attr => $attr, cdata => '' );
}

for (sort @given) {
    chomp( $_ );
    is "$_\n", <DATA>,  "correctly formed: $_";
}

__DATA__
<a href="value"></a>
<a></a>
<abbr></abbr>
<acronym></acronym>
<address></address>
<applet archive="value" code="value" codebase="value"></applet>
<applet></applet>
<area />
<area href="value"></area>
<area nohref="1"></area>
<area></area>
<b></b>
<base />
<base href="value"></base>
<base></base>
<basefont />
<basefont></basefont>
<bdo></bdo>
<bgsound />
<bgsound src="value"></bgsound>
<bgsound></bgsound>
<big></big>
<blink></blink>
<blockquote cite="value"></blockquote>
<blockquote></blockquote>
<body background="value"></body>
<body></body>
<br />
<br></br>
<button></button>
<caption></caption>
<center></center>
<cite></cite>
<code></code>
<col />
<col></col>
<colgroup></colgroup>
<dd />
<dd></dd>
<del cite="value"></del>
<del></del>
<dfn></dfn>
<dir compact="1"></dir>
<dir></dir>
<div></div>
<dl compact="1"></dl>
<dl></dl>
<dt />
<dt></dt>
<em></em>
<embed />
<embed pluginspage="value" src="value"></embed>
<embed></embed>
<fieldset></fieldset>
<font></font>
<form action="value"></form>
<form></form>
<frame />
<frame longdesc="value" src="value"></frame>
<frame></frame>
<frameset></frameset>
<h1></h1>
<h2></h2>
<h3></h3>
<h4></h4>
<h5></h5>
<h6></h6>
<head profile="value"></head>
<head></head>
<hr />
<hr noshade="1"></hr>
<hr></hr>
<html></html>
<i></i>
<iframe longdesc="value" src="value"></iframe>
<iframe></iframe>
<ilayer background="value"></ilayer>
<ilayer></ilayer>
<img />
<img ismap="1"></img>
<img longdesc="value" lowsrc="value" src="value" usemap="value"></img>
<img></img>
<input />
<input checked="1" disabled="1" readonly="1"></input>
<input src="value" usemap="value"></input>
<input></input>
<ins cite="value"></ins>
<ins></ins>
<isindex />
<isindex action="value"></isindex>
<isindex></isindex>
<kbd></kbd>
<label></label>
<layer background="value" src="value"></layer>
<legend></legend>
<li />
<li></li>
<link />
<link href="value"></link>
<link></link>
<listing></listing>
<map></map>
<menu compact="1"></menu>
<menu></menu>
<meta />
<meta></meta>
<multicol></multicol>
<nobr></nobr>
<noembed></noembed>
<noframes></noframes>
<nolayer></nolayer>
<noscript></noscript>
<object archive="value" classid="value" codebase="value" data="value" usemap="value"></object>
<object></object>
<ol compact="1"></ol>
<ol></ol>
<optgroup></optgroup>
<option selected="1"></option>
<option></option>
<p />
<p></p>
<param />
<param></param>
<plaintext></plaintext>
<pre></pre>
<q cite="value"></q>
<q></q>
<s></s>
<samp></samp>
<script for="value" src="value"></script>
<script></script>
<select multiple="1"></select>
<select></select>
<small></small>
<spacer />
<spacer></spacer>
<span></span>
<strike></strike>
<strong></strong>
<style></style>
<sub></sub>
<sup></sup>
<table background="value"></table>
<table></table>
<tbody></tbody>
<td background="value"></td>
<td nowrap="1"></td>
<td></td>
<textarea></textarea>
<tfoot></tfoot>
<th background="value"></th>
<th nowrap="1"></th>
<th></th>
<thead></thead>
<title></title>
<tr background="value"></tr>
<tr></tr>
<tt></tt>
<u></u>
<ul compact="1"></ul>
<ul></ul>
<var></var>
<wbr />
<wbr></wbr>
<xmp href="value"></xmp>
<xmp></xmp>
<~comment />
<~comment></~comment>
<~declaration />
<~directive></~directive>
<~literal />
<~literal></~literal>
<~pi />
<~pi></~pi>
