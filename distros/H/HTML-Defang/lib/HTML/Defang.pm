package HTML::Defang;

=head1 NAME

HTML::Defang - Cleans HTML as well as CSS of scripting and other executable contents, and neutralises XSS attacks.

=head1 SYNOPSIS

  my $InputHtml = "<html><body></body></html>";

  my $Defang = HTML::Defang->new(
    context => $Self,
    fix_mismatched_tags => 1,
    tags_to_callback => [ br embed img ],
    tags_callback => \&DefangTagsCallback,
    url_callback => \&DefangUrlCallback,
    css_callback => \&DefangCssCallback,
    attribs_to_callback => [ qw(border src) ],
    attribs_callback => \&DefangAttribsCallback,
    content_callback => \&ContentCallback,
  );

  my $SanitizedHtml = $Defang->defang($InputHtml);

  # Callback for custom handling specific HTML tags  
  sub DefangTagsCallback {
    my ($Self, $Defang, $OpenAngle, $lcTag, $IsEndTag, $AttributeHash, $CloseAngle, $HtmlR, $OutR) = @_;

    # Explicitly defang this tag, eventhough safe
    return DEFANG_ALWAYS if $lcTag eq 'br';

    # Explicitly whitelist this tag, eventhough unsafe
    return DEFANG_NONE if $lcTag eq 'embed';

    # I am not sure what to do with this tag, so process as HTML::Defang normally would
    return DEFANG_DEFAULT if $lcTag eq 'img';
  }

  # Callback for custom handling URLs in HTML attributes as well as style tag/attribute declarations
  sub DefangUrlCallback {
    my ($Self, $Defang, $lcTag, $lcAttrKey, $AttrValR, $AttributeHash, $HtmlR) = @_;

    # Explicitly allow this URL in tag attributes or stylesheets
    return DEFANG_NONE if $$AttrValR =~ /safesite.com/i;

    # Explicitly defang this URL in tag attributes or stylesheets
    return DEFANG_ALWAYS if $$AttrValR =~ /evilsite.com/i;
  }

  # Callback for custom handling style tags/attributes
  sub DefangCssCallback {
    my ($Self, $Defang, $Selectors, $SelectorRules, $Tag, $IsAttr) = @_;
    my $i = 0;
    foreach (@$Selectors) {
      my $SelectorRule = $$SelectorRules[$i];
      foreach my $KeyValueRules (@$SelectorRule) {
        foreach my $KeyValueRule (@$KeyValueRules) {
          my ($Key, $Value) = @$KeyValueRule;

          # Comment out any '!important' directive
          $$KeyValueRule[2] = DEFANG_ALWAYS if $Value =~ '!important';

          # Comment out any 'position=fixed;' declaration
          $$KeyValueRule[2] = DEFANG_ALWAYS if $Key =~ 'position' && $Value =~ 'fixed';
        }
      }
      $i++;
    }
  }

  # Callback for custom handling HTML tag attributes
  sub DefangAttribsCallback {
    my ($Self, $Defang, $lcTag, $lcAttrKey, $AttrValR, $HtmlR) = @_;

    # Change all 'border' attribute values to zero.
    $$AttrValR = '0' if $lcAttrKey eq 'border';

    # Defang all 'src' attributes
    return DEFANG_ALWAYS if $lcAttrKey eq 'src';

    return DEFANG_NONE;
  }

  # Callback for all content between tags (except <style>, <script>, etc)
  sub DefangContentCallback {
    my ($Self, $Defang, $ContentR) = @_;

    $$ContentR =~ s/remove this content//;
  }

=head1 DESCRIPTION

This module accepts an input HTML and/or CSS string and removes any executable code including scripting, embedded objects, applets, etc., and neutralises any XSS attacks. A whitelist based approach is used which means only HTML known to be safe is allowed through.

HTML::Defang uses a custom html tag parser. The parser has been designed and tested to work with nasty real world html and to try and emulate as close as possible what browsers actually do with strange looking constructs. The test suite has been built based on examples from a range of sources such as http://ha.ckers.org/xss.html and http://imfo.ru/csstest/css_hacks/import.php to ensure that as many as possible XSS attack scenarios have been dealt with.

HTML::Defang can make callbacks to client code when it encounters the following:

=over 4

=item *

When a specified tag is parsed

=item *

When a specified attribute is parsed

=item *

When a URL is parsed as part of an HTML attribute, or CSS property value.

=item *

When style data is parsed, as part of an HTML style attribute, or as part of an HTML <style> tag.

=back

The callbacks include details about the current tag/attribute that is being parsed, and also gives a scalar reference to the input HTML. Querying pos() on the input HTML should indicate where the module is with parsing. This gives the client code flexibility in working with HTML::Defang.

HTML::Defang can defang whole tags, any attribute in a tag, any URL that appear as an attribute or style property, or any CSS declaration in a declaration block in a style rule. This helps to precisely block the most specific unwanted elements in the contents(for example, block just an offending attribute instead of the whole tag), while retaining any safe HTML/CSS.

=cut

use Exporter;
our @ISA = ('Exporter');
%EXPORT_TAGS = (all => [qw(@FormTags DEFANG_NONE DEFANG_ALWAYS DEFANG_DEFAULT)]);
Exporter::export_ok_tags('all');

use 5.010;
use strict;
use warnings;

our $VERSION=1.06;

use constant DEFANG_NONE => 0;
use constant DEFANG_ALWAYS => 1;
use constant DEFANG_DEFAULT => 2;

use Encode;

my $HasScalarReadonly = 0;
BEGIN { eval "use Scalar::Readonly qw(readonly_on);" && ($HasScalarReadonly = 1); }

our @FormTags = qw(form input textarea select option button fieldset label legend multicol nextid optgroup);

# Some regexps for matching HTML tags + key=value attributes
my $AttrKeyStartLineRE = qr/(?:[^=<>\s\/\\]{1,}|[\/](?!\s*>))/;
my $AttrKeyRE = qr/(?<=[\s'"\/])$AttrKeyStartLineRE/;
my $AttrValRE = qr/[^>\s'"`][^>\s]*|'[^']*?'|"[^"]*?"|`[^`]*?`/;
my $AttributesRE = qr/(?:(?:$AttrKeyRE\s*)?(?:=\s*$AttrValRE\s*)?)*/;
my $TagNameRE = qr/[A-Za-z][A-Za-z0-9\#\&\;\:\!_-]*/;

my $StyleSelectors = qr/[^{}\s][^{}]{0,1024}?/;
my $StyleName = qr/[^:}\s][^:{}]*?/;
my $StyleValue = qr/[^;}\s][^;}]*|.*$/; 
my $StyleRule = qr/$StyleName\s*:\s*$StyleValue\s*/;
my $StyleRules = qr/\s*(?:$StyleRule)?(?:;\s*$StyleRule)*(?:;\s*)*/;
my $StyleMediaSelector = qr/\@media\b[^{]*/;
my $RECStyleMediaSelector = qr{\G(\s*)($StyleMediaSelector)(\{)(\s*)}so;
my $RECStyleNaked = qr/\G(\s*)()()()($StyleRules)()(\s*)/o;
my $RECStyleSelected = qr/\G(\s*)((?:$StyleSelectors)?)(\s*)(\{)($StyleRules)(\})(\s*)/o;

my $Fonts            = qr/["']?([A-Za-z0-9\s-]+)["']?/;
my $Alignments       = qr/(absbottom|absmiddle|all|autocentre|baseline|bottom|center|justify|left|middle|none|right|texttop|top)/;

my $Executables = '([^@]\.com|'.
                  '.*\.(exe|cmd|bat|pif|scr|sys|sct|lnk|dll'.
                  '|vbs?|vbe|hta|shb|shs|hlp|chm|eml|wsf|wsh|js'.
                  '|asx|wm.|mdb|mht|msi|msp|cpl|lib|reg))';
my $SrcBanStd      = qr/^([A-Za-z]*script|.*\&{|mocha|about|opera|mailto:|hcp:|\/(dev|proc)|\\|file|smb|cid:${Executables}(@|\?|$))/i;

my %Rules = 
(
  # Disallow unknown tags by default
  "_unknown"     => qr/.*/,
  "align"        => qr/^${Alignments}$/i,
  "alnum"        => qr/^[A-Za-z0-9_.-]+$/,
  "boolean"      => qr/^(0|1|true|yes|no|false)$/,
  "charset"      => qr/^[A-Za-z0-9_][A-Za-z0-9_.-]*$/,
  "class"        => qr/^[A-Za-z0-9_.:\s-]*$/,
  "color"        => qr/^#?[0-9A-Z]+$/i,
  "coords"       => qr/^(\d+,)+\d+$/i,
  "datetime"     => qr/^\d\d\d\d-\d\d-\d\d.{0,5}\d\d:\d\d:\d\d.{0,5}$/,
  "dir"          => qr/^(ltr|rtl)$/i,
  "empty"        => qr/^$/i,
  "eudora"       => qr/^(autourl)$/i,
  "font-face"    => qr/^((${Fonts})[,\s]*)+$/i,
  "form-enctype" => qr/^(application\/x-www-form-urlencoded|multipart\/form-data)$/i,
  "form-method"  => qr/^(get|post)$/i,
  "frame"        => qr/^(void|above|below|hsides|vsides|lhs|rhs|box|border)$/i,
  # href: Not javascript, vbs or vbscript
  "href"         => [ qr/^((?:[a-z]*script|mocha|opera|about|data|tcl)\s*:|.*\&\{|hcp|smb|\/dev\/|<)/i ],
  "usemap-href"  => qr/^#[A-Za-z0-9_.-]+$/,  # this is not really a href at all!
  "input-size"   => qr/^(\d{1,4})$/, # some browsers freak out with very large widgets
  "input-type"   => qr/^(button|checkbox|file|hidden|image|password|radio|readonly|reset|submit|text)$/i,
  "integer"      => qr/^(-|\+)?\d+$/,
  "number"       => qr/^(-|\+)?[\d.,]+$/,
  # language: Not javascript, vbs or vbscript
  "language"     => qr/^(XML)$/i, 
  "media"        => qr/^((screen|print|projection|braille|speech|all)[,\s]*)+$/i,
  "meta:name"    => qr/^(author|progid|originator|generator|keywords|description|content-type|pragma|expires)$/i,
  # mime-type: Not javascript
  "mime-type"    => qr/^(cite|text\/(plain|css|html|xml))$/i,
  "list-type"    => qr/^(none,a,i,upper-alpha,lower-alpha,upper-roman,lower-roman,decimal,disc,square,circle,round)$/i,
  # "rel"          => qr/^((copyright|author|stylesheet)\s*)+$/i,
  "rel"          => qr/^((copyright|author)\s*)+$/i, # XXX external stylesheets can contain scripting, so kill them
  "rules"        => qr/^(none|groups|rows|cols|all)$/i,
  "scope"        => qr/^(row|col|rowgroup|colgroup)$/i,
  "shape"        => qr/^(rect|rectangle|circ|circle|poly|polygon)$/i,
  # The following two are for URLs we expect to be auto-loaded by the browser,
  # because they are within a frame, image or something like that.
  # "src"          => qr/^([a-z]+):|^[\w\.\/\%]+$/i,
  "src"          => qr/^https?:\/\/|^[\w.\/%]+$/i,
  # "style"        => qr/^([A-Za-z0-9_-]+\\s*:\\s*(yes|no)|text-align\\s*:\\s*$alignments|((background|(background-|font-)?color)\\s*:\\s*(\\#?[A-Z0-9]+)?|((margin|padding|border)-(right|left)|tab-interval|height|width)\\s*:\\s*[\\d\\.]+(pt|px)|font(-family|-size|-weight|)\\s*:(\\s*[\\d\\.]+(pt|px)|\\s*$fonts)+)[;\\s]*)+\$/i, 
#  "style"        => qr/expression|eval|script:|mocha:|\&{|\@import|(?<!background-)position:|background-image/i, # XXX there are probably a million more ways to cause trouble with css!
  "style"        => qr/^.*$/s,
#kc In addition to this, we could strip all 'javascript:|expression|' etc. from all attributes(in attribute_cleanup())
  "stylesheet"   => [ qr/expression|eval|script:|mocha:|\&\{|\@import/i ], # stylesheets are forbidden if Embedded => 1.  css positioning can be allowed in an iframe.
  # NB see also `process_stylesheet' below
  "style-type"   => [ qr/script|mocha/i ],
  "size"         => qr/^[\+\-]?[\d.]+(px|%)?$/i,
  "target"       => qr/^[A-Za-z0-9_][A-Za-z0-9_.-]*$/,
  "base-href"    => qr/^https?:\/\/[\w.\/]+$/,
  "anything"     => qr/^.*$/, #[ 0, 0 ],
  "meta:content" => [ qr// ],
);

my %CommonAttributes =
(
  # Core attributes
  "class"     => "class",
  "id"        => "alnum",
  "name"      => "alnum",
  "style"     => "style",
  "accesskey" => "alnum",
  "tabindex"  => "integer",
  "title"     => "anything",
  # Language attributes
  "dir"       => "dir",
  "lang"      => "alnum",
  "language"  => "language",
  "longdesc"  => "anything",
  # Height, width, alignment, etc.
  "align"      => "align",
  "bgcolor"     => "color",
  "bottommargin" => "size",
  "clear"        => "align",
  "color"        => "color",
  "height"       => "size",
  "leftmargin"   => "size",
  "marginheight" => "size",
  "marginwidth"  => "size",
  "nowrap"       => "anything",
  "rightmargin"  => "size",
  "scroll"       => "boolean",
  "scrolling"    => "boolean",
  "topmargin"    => "size",
  "type"         => "mime-type",
  "valign"      => "align",
  "width"      => "size",
  "/"          => "empty",
);

my %ListAttributes =
(
  "compact" => "anything",
  "start"   => "integer",
  "type"    => "list-type",
);

my %TableAttributes =
(
  "axis"         => "alnum",
  "background"   => "src",
  "border"        => "number",
  "bordercolor"    => "color",
  "bordercolordark" => "color",
  "bordercolorlight" => "color",
  "padding"          => "integer",
  "spacing"          => "integer",
  "cellpadding"     => "integer",
  "cellspacing"    => "integer",
  "cols"          => "anything",
  "colspan"      => "integer",
  "char"         => "alnum",
  "charoff"      => "integer",
  "datapagesize" => "integer",
  "frame"        => "frame",
  "frameborder"  => "boolean",
  "framespacing" => "integer",
  "headers"      => "anything",
  "rows"         => "anything",
  "rowspan"      => "size",
  "rules"        => "rules",
  "scope"        => "scope",
  "span"         => "integer",
  "summary"      => "anything"
);

my %UrlRules = (
  "src"         => 1,
  "href"        => 1,
  "base-href"   => 1,
#  cite        => 1,
#  action      => 1,
);

my %Tags = (
  script => \&defang_script_tag,
  style => \&defang_style_tag,
  "html" => 100,
  #
  # Safe elements commonly found in the <head> block follow.
  #
  "head" => 2,
  "base" => 
  {
    "href"   => "base-href",
    "target" => "target",
  },
  # TODO: Deal with link below later
  #"link" => \$r_link,
  #      {
  #          "rel"     => "rel",
  #          "rev"     => "rel",
  #          "src"     => "src",
  #          "href"    => "src",       # Might be auto-loaded by the browser!!
  #          "charset" => "charset",
  #          "media"   => "media",
  #          "target"  => "target",
  #          "type"    => "mime-type",
  #      },
  "meta" =>
  {
    "_score"     => 2,
    "content"    => "meta:content",
    "http-equiv" => "meta:name",
    "name"       => "meta:name",
    "charset"    => "charset",
  },
  "title" => 2,
  #
  # Safe elements commonly found in the <body> block follow.
  #
  "body" => 
  {
    "_score"       => 2,
    "link"         => "color",
    "alink"        => "color",
    "vlink"        => "color",
    "background"   => "src",
    "nowrap"       => "boolean",
    "text"         => "color",
    "vlink"        => "color",
  },
  "a" =>
  {
    "charset"     => "charset",
    "coords"      => "coords",
    "href"        => "href",
    "shape"       => "shape", 
    "target"      => "target",
    "type"        => "mime-type",
    "eudora"      => "eudora",
    "notrack"     => "anything",
  },
  "address" => 1,
  "area" =>
  {
    "alt"    => "anything",
    "coords" => "coords",
    "href"   => "href",
    "nohref" => "anything",
    "shape"  => "shape", 
    "target" => "target",
  },
  "article" => 1,
  "applet" => 0,
  "basefont" =>
  {
    "face"   => "font-face",
    "family" => "font-face",
    "back"   => "color",
    "size"   => "number",
    "ptsize" => "number",
  },
  "bdo"     => 1,
  "bgsound" =>
  {
    "balance" => "integer",
    "delay"   => "integer",
    "loop"    => "alnum",
    "src"     => "src",
    "volume"  => "integer",
  },
  "blockquote" => 
  {
    "cite" => "href",
    "type" => "mime-type",
  },
  "br"      => 1,
  "button"  => # FORM
  {
    "type"     => "input-type",
    "disabled" => "anything",
    "value"    => "anything",
    "tabindex" => "number",
  },
  "caption" => 1,
  "center"  => 1,
  "col"     => \%TableAttributes,
  "colgroup" => \%TableAttributes,
  "comment" => 1,
  "dd"      => 1,
  "del"     =>
  {
    "cite"     => "href",
    "datetime" => "datetime",
  },
  "dir"   => \%ListAttributes,
  "div"   => 1,
  "dl"    => \%ListAttributes,
  "dt"    => 1,
  "embed" => 0,
  "fieldset" => 1, # FORM
  "font" =>
  {
    "face"   => "font-face",
    "family" => "font-face",
    "back"   => "color",
    "size"   => "number",
    "ptsize" => "number",
  },
  "footer" => 1,
  "form" => # FORM
  {
    "method"  => "form-method",
    "action"  => "href",
    "enctype" => "form-enctype",
    "accept"   => "anything",
    "accept-charset"   => "anything",
  },
  "header" => 1,
  "hr" =>
  {
    "size"    => "number",
    "noshade" => "anything",
  },
  "h1"     => 1,
  "h2"     => 1,
  "h3"     => 1,
  "h4"     => 1,
  "h5"     => 1,
  "h6"     => 1,
  "iframe" => 0,
  "ilayer" => 0,
  "img" =>
  {
    "alt"      => "anything",
    "border"   => "size",
    "dynsrc"   => "src",
    "hspace"   => "size",
    "ismap"    => "anything",
    "loop"     => "alnum",
    "lowsrc"   => "src",
    "nosend"   => "alnum",
    "src"      => "src",
    "start"    => "alnum",
    "usemap"   => "usemap-href",
    "vspace"   => "size",
  },
  "inlineinput" => 0,
  "input" => # FORM
  {
    "type"     => "input-type",
    "disabled" => "anything",
    "value"    => "anything",
    "maxlength" => "input-size",
    "size"     => "input-size",
    "readonly" => "anything",
    "tabindex" => "number",
    "checked"  => "anything",
    "accept"   => "anything",
    # for type "image":
    "alt"      => "anything",
    "border"   => "size",
    "dynsrc"   => "src",
    "hspace"   => "size",
    "ismap"    => "anything",
    "loop"     => "alnum",
    "lowsrc"   => "src",
    "nosend"   => "alnum",
    "src"      => "src",
    "start"    => "alnum",
    "usemap"   => "usemap-href",
    "vspace"   => "size",
  },
  "ins" =>
  {
    "cite" => "href",
    "datetime" => "datetime",
  },
  "isindex" => 0,
  "keygen"  => 0,
  "label"   => # FORM
  {
    "for"  => "alnum",
  },
  "layer"   => 0,
  "legend"  => 1, # FORM
  "li" => {
    "value" => "integer",
  },
  "listing"  => 0,
  "map"      => 1,
  "marquee"  => 0,
  "menu"     => \%ListAttributes,
  "multicol" => 0,
  "nextid"   => 0,
  "nobr"     => 0,
  "noembed"  => 1,
  "nolayer"  => 1,
  # Pretend our defang result is going into a non-scripting environment,
  #  even though javascript is likely enabled, so just defang all noscript tags
  "noscript" => 0,
  "noembed"  => 1,
  "object"   => 0,
  "ol"       => \%ListAttributes,
  "optgroup" => # FORM
  {
    "disabled" => "anything",
    "label"    => "anything",
  },
  "option"   => # FORM
  {
    "disabled" => "anything",
    "label"    => "anything",
    "selected" => "anything",
    "value"    => "anything",
  },
  "o:p"      => 1,
  "p"        => 1,
  "param"    => 0,
  "plaintext"=> 0,
  "pre"      => 1,
  "rt"       => 0,
  "ruby"     => 0,
  "section"  => 1,
  "select"   => # FORM
  {
    "disabled" => "anything",
    "multiple" => "anything",
    "size"     => "input-size",
    "tabindex" => "number",
  },
  "spacer"   => 0,
  "span"     => 1,
  "spell"    => 0,
  "sound" => 
  {
    "delay" => "number",
    "loop"  => "integer",
    "src"   => "src",
  },
  "table"  => \%TableAttributes,
  "tbody"  => \%TableAttributes,
  "textarea" => # FORM
  {
    "cols"     => "input-size",
    "rows"     => "input-size",
    "disabled" => "anything",
    "readonly" => "anything",
    "tabindex" => "number",
    "wrap"     => "anything",
  },
  "td"     => \%TableAttributes,
  "tfoot"  => \%TableAttributes,
  "th"     => \%TableAttributes,
  "thead"  => \%TableAttributes,
  "tr"     => \%TableAttributes,
  "ul"     => \%ListAttributes,
  "wbr"    => 1,
  "xml"    => 0,
  "xmp"    => 0,
  "x-html" => 0,
  "x-tab"  => 1,
  "x-sigsep" => 1,
  # Character formatting
  "abbr"   => 1,
  "acronym"=> 1,
  "big"    => 1, 
  "blink"  => 0, 
  "b"      => 1, 
  "cite"   => 1,
  "code"   => 1,
  "dfn"    => 1, 
  "em"     => 1,
  "i"      => 1, 
  "kbd"    => 1,
  "q"      => 1,
  "s"      => 1,
  "samp"   => 1,
  "small"  => 1, 
  "strike" => 1, 
  "strong" => 1, 
  "sub"    => 1, 
  "sup"    => 1, 
  "tt"     => 1, 
  "u"      => 1,
  "var"    => 1,
  #
  # Safe elements commonly found in the <frameset> block follow.
  #
  "frameset" => 0,
  "frame"    => 0,
  "noframes" => 1,
);

my %MathMLTags = (
  mi => 1,
  mn => 1,
  mo => 1,
  mtext => 1,
  mspace => 1,
  ms => 1,
  mglyph => 1,
  mrow => 1,
  mfrac => 1,
  msqrt => 1,
  mroot => 1,
  mstyle => 1,
  merror => 1,
  mpadded => 1,
  mphantom => 1,
  mfenced => 1,
  menclose => 1,
  msub => 1,
  msup => 1,
  msubsup => 1,
  munder => 1,
  mover => 1,
  munderover => 1,
  mmultiscripts => 1,
  mtable => 1,
  mtr => 1,
  mtd => 1,
  maligngroup => 1,
  malignmark => 1,
  mlabeledtr => 1,
  maction => 1,
);

# Some entity conversions for attributes
my $CtrlChars = qr/[\x00-\x08\x0b-\x1f]/;
my %EntityToChar = (quot => '"', apos => "'", amp => '&', 'lt' => '<', 'gt' => '>');
my %CharToEntity = ((reverse %EntityToChar), ' ' => '#x20', '/' => '#x2f', "\x09" => '#x09', "\x0a" => '#x0a');
my %QuoteRe = ('"' => qr/(["&<>\x09\x0a])/, "'" => qr/(['&<>\x09\x0a])/, "" => qr/(['"&<> \/\x09\x0a])/);

# When fixing mismatched tags, sometimes a close tag
#  shouldn't close all the way out
# For example, consider:
#   <table><tr><td><table><tr></td>
# A naive version would see the ending </td>, and thus
#  try to fix the mismatched tags by doing:
#   <table><tr><td><table><tr></tr></table></td>
# This is not what a browser does. So given a tag, we
#  give a list of closing tags which cause us to stop
#  and not close any more
my %MismatchedTagNest = (
  table => [ qw(tbody thead tfoot tr th td caption colgroup col) ],
  tbody => [ qw(tr th td) ],
  tr => [ qw(th td) ],
  font => [ '' ],
);
# Convert to hash of hashes
$_ = { map { $_ => 1 } @$_ } for values %MismatchedTagNest;

# If we see a table, we should expect to see a tbody
#  next. If not, we need to add it because the browser
#  will implicitly open it!
# For each tag, give list of tags that should follow. If
#  we don't find one of them following, we open a new
#  implicit tag of the first one in the list
#  eg. <table><td> -> <table><tr><td>
my %ImplicitOpenTags = (
  table => [ qw(tr tbody thead tfoot caption colgroup col) ],
  thead => [ qw(tr) ],
  tbody => [ qw(tr) ],
  tr => [ qw(td th) ],
);
# Convert to hash of hashes
$_ = { default => $_->[0], map { $_ => 1 } @$_ } for values %ImplicitOpenTags;

my %TableTags = map { $_ => 1 } qw(table tbody thead tfoot tr td th caption colgroup col);
my %BlockTags = map { $_ => 1 } qw(h1 h2 h3 h4 h5 h6 p div pre plaintext address blockquote center form table tbody thead tfoot tr td th caption colgroup col dl ul ol li fieldset);
my %InlineTags = map { $_ => 1 } qw(span abbr acronym q sub sup cite code em kbd samp strong var dfn strike b i u s tt small big nobr a font);
my %NestInlineTags = map { $_ => 1 } qw(span abbr acronym q sub sup cite code em kbd samp strong var dfn strike b i u s tt small big nobr);

# Default list of mismatched tags to track
my %MismatchedTags = (%BlockTags, %InlineTags);

=head1 CONSTRUCTOR

=over 4

=cut

=item I<HTML::Defang-E<gt>new(%Options)>

Constructs a new HTML::Defang object. The following options are supported:

=over 4

=item B<Options>

=over 4

=item B<tags_to_callback>

Array reference of tags for which a call back should be made. If a tag in this array is parsed, the subroutine tags_callback() is invoked.

=item B<attribs_to_callback>

Array reference of tag attributes for which a call back should be made. If an attribute in this array is parsed, the subroutine attribs_callback() is invoked.

=item B<tags_callback>

Subroutine reference to be invoked when a tag listed in @$tags_to_callback is parsed.

=item B<attribs_callback>

Subroutine reference to be invoked when an attribute listed in @$attribs_to_callback is parsed.

=item B<url_callback>

Subroutine reference to be invoked when a URL is detected in an HTML tag attribute or a CSS property.

=item B<css_callback>

Subroutine reference to be invoked when CSS data is found either as the contents of a 'style' attribute in an HTML tag, or as the contents of a <style> HTML tag.

=item B<content_callback>

Subroutine reference to be invoked when standard content between HTML tags in found.

=item B<fix_mismatched_tags>

This property, if set, fixes mismatched tags in the HTML input. By default, tags present in the default %mismatched_tags_to_fix hash are fixed. This set of tags can be overridden by passing in an array reference $mismatched_tags_to_fix to the constructor. Any opened tags in the set are automatically closed if no corresponding closing tag is found. If an unbalanced closing tag is found, that is commented out.

=item B<mismatched_tags_to_fix>

Array reference of tags for which the code would check for matching opening and closing tags. See the property $fix_mismatched_tags.

=item B<context>

You can pass an arbitrary scalar as a 'context' value that's then passed as the first parameter to all callback functions. Most commonly this is something like '$Self'

=item B<allow_double_defang>

If this is true, then tag names and attribute names which already begin
with the defang string ("defang_" by default) will have an additional
copy of the defang string prepended if they are flagged to be defanged
by the return value of a callback, or if the tag or attribute name
is unknown.

The default is to assume that tag names and attribute names beginning 
with the defang string are already made safe, and need no further
modification, even if they are flagged to be defanged by the
return value of a callback.  Any tag or attribute modifications made
directly by a callback are still performed.

=item B<delete_defang_content>

Normally defanged tags are turned into comments and prefixed by defang_,
and defanged styles are surrounded by /* ... */. If this is set to
true, then defanged content is deleted instead

=item B<Debug>

If set, prints debugging output.

=back

=back

=cut

sub new {
  my $Proto = shift;
  my $Class = ref($Proto) || $Proto;

  my %Opts = @_;

  my ($tags_to_callback, $attribs_to_callback, $empty_tags_to_collapse, $mismatched_tags_to_fix)
    = @Opts{qw(tags_to_callback attribs_to_callback empty_tags_to_collapse mismatched_tags_to_fix)};
  my %tags_to_callback;
  %tags_to_callback = map { $_ => 1 } @$tags_to_callback if $tags_to_callback;
  my %attribs_to_callback;
  %attribs_to_callback = map { $_ => 1 } @$attribs_to_callback if $attribs_to_callback;
  my %empty_tags_to_collapse;
  %empty_tags_to_collapse = map { $_ => 1 } @$empty_tags_to_collapse if $empty_tags_to_collapse;
  my %mismatched_tags_to_fix = %MismatchedTags;
  %mismatched_tags_to_fix = map { $_ => 1 } @$mismatched_tags_to_fix if $mismatched_tags_to_fix;

  my $Self = {
    defang_string => 'defang_',
    defang_re => qr/^defang_/,
    defang_default => ($Opts{defang_default} // DEFANG_DEFAULT),
    allow_double_defang => $Opts{allow_double_defang},
    tags_to_callback => \%tags_to_callback,
    tags_callback => $Opts{tags_callback},
    attribs_to_callback => \%attribs_to_callback,
    attribs_callback => $Opts{attribs_callback},
    url_callback => $Opts{url_callback},
    css_callback => $Opts{css_callback},
    content_callback => $Opts{content_callback},
    mismatched_tags_to_fix => \%mismatched_tags_to_fix,
    fix_mismatched_tags => $Opts{fix_mismatched_tags},
    context => $Opts{context},
    opened_tags => [],
    opened_tags_count => {},
    closed_into_block_tags => [],
    empty_tags_to_collapse => \%empty_tags_to_collapse,
    quiet => $Opts{quiet},
    delete_defang_content => $Opts{delete_defang_content},
    Debug => $Opts{Debug},
  };

  bless ($Self, $Class);
  return $Self;
}

=item I<HTML::Defang-E<gt>new_bodyonly(%Options)>

Constructs a new HTML::Defang object that has the following
implicit options

=over 4

=item B<fix_mismatched_tags = 1>

=item B<delete_defang_content = 1>

=item B<tags_to_callback = [ qw(html head link body meta title bgsound) ]>

=item B<tags_callback = { ... remove all above tags and related content ... }>

=item B<url_callback = { ... explicity DEFANG_NONE to leave everything alone ... }>

=back

Basically this is a easy way to remove all html boiler plate
content and return only the html body content.

=cut

sub new_bodyonly {
  return shift->new(
    fix_mismatched_tags => 1,
    delete_defang_content => 1,
    tags_to_callback => [ qw(html head link body meta title bgsound) ],
    tags_callback => sub {
      my (undef, $Defang, $Angle, $lcTag, $IsEndTag, $AttributeHash, $AttributesEnd, $HtmlR, $OutR) = @_;
      $$HtmlR =~ m{\G.*?(?=</title|</head)}gcis if $lcTag eq 'title' && !$IsEndTag;
      return DEFANG_ALWAYS;
    },
    url_callback => sub { return DEFANG_NONE; },
    @_
  );
}

=back

=cut

=head1 CALLBACK METHODS

=over 4

=cut

=item B<COMMON PARAMETERS>

A number of the callbacks share the same parameters. These common parameters are documented here. Certain variables may have specific meanings in certain callbacks, so be sure to check the documentation for that method first before referring this section.

=over 4

=item I<$context>

You can pass an arbitrary scalar as a 'context' value that's then passed as the first parameter to all callback functions. Most commonly this is something like '$Self'

=item I<$Defang>

Current HTML::Defang instance

=item I<$OpenAngle>

Opening angle(<) sign of the current tag.

=item I<$lcTag>

Lower case version of the HTML tag that is currently being parsed.

=item I<$IsEndTag>

Has the value '/' if the current tag is a closing tag.

=item I<$AttributeHash>

A reference to a hash containing the attributes of the current tag and
their values. Each value is a scalar reference to the value, rather
than just a scalar value. You can add attributes (remember to make it a
scalar ref, eg $AttributeHash{"newattr"} = \"newval"), delete attributes,
or modify attribute values in this hash, and any changes you make will
be incorporated into the output HTML stream.

The attribute values will have any entity references decoded before
being passed to you, and any unsafe values we be re-encoded back into
the HTML stream.

So for instance, the tag:

  <div title="&lt;&quot;Hi there &#x003C;">

Will have the attribute hash:

  { title => \q[<"Hi there <] }

And will be turned back into the HTML on output:

  <div title="&lt;&quot;Hi there &lt;">

=item I<$CloseAngle>

Anything after the end of last attribute including the closing HTML angle(>)

=item I<$HtmlR>

A scalar reference to the input HTML. The input HTML is parsed using
m/\G$SomeRegex/c constructs, so to continue from where HTML:Defang left,
clients can use m/\G$SomeRegex/c for further processing on the input. This
will resume parsing from where HTML::Defang left. One can also use the
pos() function to determine where HTML::Defang left off. This combined
with the add_to_output() method should give reasonable flexibility for
the client to process the input.

=item I<$OutR>

A scalar reference to the processed output HTML so far.

=back

=item I<tags_callback($context, $Defang, $OpenAngle, $lcTag, $IsEndTag, $AttributeHash, $CloseAngle, $HtmlR, $OutR)>

If $Defang->{tags_callback} exists, and HTML::Defang has parsed a tag preset in $Defang->{tags_to_callback}, the above callback is made to the client code. The return value of this method determines whether the tag is defanged or not. More details below.

=over 4

=item B<Return values>

=over 4

=item DEFANG_NONE

The current tag will not be defanged.

=item DEFANG_ALWAYS

The current tag will be defanged.

=item DEFANG_DEFAULT

The current tag will be processed normally by HTML:Defang as if there was no callback method specified.

=back

=back

=item I<attribs_callback($context, $Defang, $lcTag, $lcAttrKey, $AttrVal, $HtmlR, $OutR)>

If $Defang->{attribs_callback} exists, and HTML::Defang has parsed an attribute present in $Defang->{attribs_to_callback}, the above callback is made to the client code. The return value of this method determines whether the attribute is defanged or not. More details below.

=over 4

=item B<Method parameters>

=over 4

=item I<$lcAttrKey>

Lower case version of the HTML attribute that is currently being parsed.

=item I<$AttrVal>

Reference to the HTML attribute value that is currently being parsed.

See $AttributeHash for details of decoding.

=back

=item B<Return values>

=over 4

=item DEFANG_NONE

The current attribute will not be defanged.

=item DEFANG_ALWAYS

The current attribute will be defanged.

=item DEFANG_DEFAULT

The current attribute will be processed normally by HTML:Defang as if there was no callback method specified.

=back

=back

=item I<url_callback($context, $Defang, $lcTag, $lcAttrKey, $AttrVal, $AttributeHash, $HtmlR, $OutR)>

If $Defang->{url_callback} exists, and HTML::Defang has parsed a URL, the above callback is made to the client code. The return value of this method determines whether the attribute containing the URL is defanged or not. URL callbacks can be made from <style> tags as well style attributes, in which case the particular style declaration will be commented out. More details below.

=over 4

=item B<Method parameters>

=over 4

=item I<$lcAttrKey>

Lower case version of the HTML attribute that is currently being parsed. However if this callback is made as a result of parsing a URL in a style attribute, $lcAttrKey will be set to the string I<style>, or will be set to I<undef> if this callback is made as a result of parsing a URL inside a style tag.

=item I<$AttrVal>

Reference to the URL value that is currently being parsed.

=item I<$AttributeHash>

A reference to a hash containing the attributes of the current tag and their values. Each value is a scalar reference to the value, 
rather than just a scalar value. You can add attributes (remember to make it a scalar ref, eg $AttributeHash{"newattr"} = \"newval"), delete attributes, or modify attribute values in this hash, and any changes you make will be incorporated into the output HTML stream. Will be set to I<undef> if the callback is made due to URL in a <style> tag or attribute.

=back

=item B<Return values>

=over 4

=item DEFANG_NONE

The current URL will not be defanged.

=item DEFANG_ALWAYS

The current URL will be defanged.

=item DEFANG_DEFAULT

The current URL will be processed normally by HTML:Defang as if there was no callback method specified.

=back

=back

=item I<css_callback($context, $Defang, $Selectors, $SelectorRules, $lcTag, $IsAttr, $OutR)>

If $Defang->{css_callback} exists, and HTML::Defang has parsed a <style> tag or style attribtue, the above callback is made to the client code. The return value of this method determines whether a particular declaration in the style rules is defanged or not. More details below.

=over 4

=item B<Method parameters>

=over 4

=item I<$Selectors>

Reference to an array containing the selectors in a style tag or attribute.

=item I<$SelectorRules>

Reference to an array containing the style declaration blocks of all selectors in a style tag or attribute. Consider the below CSS:

  a { b:c; d:e}
  j { k:l; m:n}

The declaration blocks will get parsed into the following data structure:

  [
    [
      [ "b", "c", DEFANG_DEFAULT ],
      [ "d", "e", DEFANG_DEFAULT ]
    ],
    [
      [ "k", "l", DEFANG_DEFAULT ],
      [ "m", "n", DEFANG_DEFAULT ]
    ]
  ]

So, generally each property:value pair in a declaration is parsed into an array of the form

  ["property", "value", X]

where X can be DEFANG_NONE, DEFANG_ALWAYS or DEFANG_DEFAULT, and DEFANG_DEFAULT the default value. A client can manipulate this value to instruct HTML::Defang to defang this property:value pair.

DEFANG_NONE - Do not defang

DEFANG_ALWAYS - Defang the style:property value

DEFANG_DEFAULT - Process this as if there is no callback specified

=item I<$IsAttr>

True if the currently processed item is a style attribute. False if the currently processed item is a style tag.

=back

=back

=back

=cut

=head1 METHODS

=over 4

=item B<PUBLIC METHODS>

=over 4

=cut

=item I<defang($InputHtml, \%Opts)>

Cleans up $InputHtml of any executable code including scripting, embedded objects, applets, etc., and defang any XSS attacks.

=over 4

=item B<Method parameters>

=over 4

=item I<$InputHtml>

The input HTML string that needs to be sanitized.

=back

=back

Returns the cleaned HTML. If fix_mismatched_tags is set, any tags that appear in @$mismatched_tags_to_fix that are unbalanced are automatically commented or closed.

=cut
sub defang {
  my $Self = shift;

  my $I = shift;
  my $Opts = shift;

  my $Debug = $Self->{Debug};

  my $HeaderCharset = $Opts->{header_charset};
  warn("defang HeaderCharset=$HeaderCharset") if $Debug;
  my $FallbackCharset = $Opts->{fallback_charset};
  warn("defang FallbackCharset=$FallbackCharset") if $Debug;

  $Self->{Reentrant}++;

  # Output buffer
  local $Self->{OutR} = $Opts->{add_to_existing} ? $Self->{OutR} : \(my $O = "");
  my $OutR = $Self->{OutR};

# Get encoded characters
#  $Self->{Charset} = $Self->get_applicable_charset($_, $HeaderCharset, $FallbackCharset);
#  warn("defang Charset=$Self->{Charset}") if $Self->{Debug};

#  if ($Self->{Charset}) {
#    $I =~ s/(.)/chr(ord($1) & 127)/ge if $Self->{Charset} eq "US-ASCII";
#    my $Encoder = Encode::Encoder->new($I, $Self->{Charset});
#    $I = $Encoder->bytes($Self->{Charset});
#  }

  # We pass a ref to $I to each callback. It should
  #  never be modified because we use a m/\G.../gc loop
  #  on it. If possible, stop people modifying it
  readonly_on($I) if $HasScalarReadonly;

  # It seems regexp matching on perl unicode strings can be *way*
  #  slower than byte string (defang 1M email = 100 seconds unicode,
  #  5 seconds bytes).
  # So we're going to do a bit of a hack. Engaged "use bytes" to do
  #  byte matching everywhere, but since we know we'll be matching
  #  on correct boundaries to make up full code points in utf-8, we'll
  #  turn on the magic utf-8 flag again for those values
  my $UTF8Input = $Self->{UTF8Input} = Encode::is_utf8($I);

  # Force byte matching everywhere (see above)
  use bytes;

  Carp::cluck() if !defined $I;

  # Strip all NUL chars
  $I =~ s/\0//g;

  # This parser uses standard /\G.../gc matching, so have to be careful
  #  to not reset pos() on the string
  #
  # Previously we tried an "eating" parser (s/^.../, or /^.../ + substr),
  #  which in theory should be fast with perls internal string offset
  #  feature, but it seems offset doesn't work on unicode strings,
  #  so you end up with a slow parser because of string reallocations

  while (1) {

    # walk to next < (testing in 5.8.8 shows .*? is faster than [^<]* or [^<]*?)
    if ($I =~ m{\G(.*?)<}gcso) {

      my $Content = $1;

      # Call content callback if present
      $Self->{content_callback}->($Self->{context}, $Self, \$Content)
        if $Self->{content_callback};

      # Everything before tag goes into the output
      $$OutR .= $Content;

      # All tags default to open/close with </>
      my ($OpenAngle, $CloseAngle) = ('<', '>');
      my $IsEndTag = $I =~ m{\G/}gcso ? '/' : '';

      # It's a standard tag
      if ($I =~ m{\G($TagNameRE)}gcso) {

        my $Tag = $1;
        my $TagTrail = $I =~ m{\G([\s/]+)}gcso ? $1 : '';

        warn "defang IsEndTag=$IsEndTag Tag=$Tag" if $Debug;

        # Skip attribute parsing if none
        my @Attributes;
        goto NoParseAttributes if $I =~ m{\G>}gcso;

        # Pull off any trailing component after the tag
        # Now match all key=value attributes
        while ($I =~ m{\G(?:($AttrKeyStartLineRE)(\s*))?(?:(=\s*)($AttrValRE)(\s*))?}gcso) {

          last if !defined($1) && !defined($4);
          my ($Attribute, $AttrTrail, $Equals, $AttrVal, $AttrValTrail) = ($1, $2, $3, $4, $5);
          my ($AttrQuote, $AttrValWithoutQuote) = '';
          if (defined($4) && $4 =~ /^([`"']?)(.*)\1$/s) {
            # IE supports `, but nothing else does, turn it into "
            $AttrQuote = $1 eq '`' ? '"' : $1;
            $AttrValWithoutQuote = $2;
          }

          # Turn on utf-8 for things that might be
          Encode::_utf8_on($Attribute) if $UTF8Input;
          Encode::_utf8_on($AttrValWithoutQuote) if $UTF8Input;

          push @Attributes, [ $Attribute, $AttrTrail, $Equals, $AttrQuote, $AttrValWithoutQuote, $AttrQuote, $AttrValTrail ];
          warn "defang AttributeKey=$1 AttrQuote=$AttrQuote AttributeValue=$Attribute" if $Debug;
        }

        # Better be at end of attributes, or attach our own ending tag
        if ($I =~ m{\G(?:(\s*[/\\]*\s*(?:--)?\s*)?>|([\s/-]*))}gcs) {
          $CloseAngle = $1 ? $1 . '>' : ($2 ? $2 . '>' : '>');
        }

        NoParseAttributes:
        my $Defang = DEFANG_ALWAYS;

        my $lcTag = lc $Tag;
        my $TagOps = $Tags{$lcTag};

        # Process this tag
        if (!exists $Self->{tags_to_callback}->{$lcTag} && ref $TagOps eq "CODE") {

          warn "process_tag Found CODE reference" if $Debug;
          $Defang = $Self->${TagOps}($OutR, \$I, $TagOps, \$OpenAngle, $IsEndTag, $lcTag, $TagTrail, \@Attributes, \$CloseAngle);

        } else {

          warn "process_tag Found regular tag" if $Debug;
          $Defang = $Self->defang_attributes($OutR, \$I, $TagOps, \$OpenAngle, $IsEndTag, $lcTag, $TagTrail, \@Attributes, \$CloseAngle);

        }
        die "Callback reset pos on Tag=$Tag IsEndTag=$IsEndTag" if !defined pos($I);
        warn "defang Defang=$Defang" if $Debug;

        # Build tag content, because if we defang, we have to remove --'s within it

        # @Attributes can have unicode values, but we're within "use bytes", so it's flattened ok
        my $TagContent = $TagTrail . join("", grep { defined } map { @$_ } @Attributes);

        if ($Self->{fix_mismatched_tags} && ($Defang == DEFANG_NONE)) {
          if (!$IsEndTag) {
            $Defang = $Self->open_tag(0, $OutR, \$I, $lcTag, \$TagContent);
          } else {
            $Defang = $Self->close_tag(0, $OutR, \$I, $lcTag);
            goto SkipOutput if $Defang == DEFANG_ALWAYS;
          }
        }

        # defang unknown tags
        if ($Defang != DEFANG_NONE) {
          warn "defang Defanging $Tag" if $Debug;
          if ($Self->{delete_defang_content}) {
            $OpenAngle = $IsEndTag = $Tag = $TagContent = $CloseAngle = '';
          } else {
            $Tag = $Self->{defang_string} . $Tag
              if $Self->{allow_double_defang} || $Tag !~ $Self->{defang_re};
            $TagContent =~ s/--//g;
            $Tag =~ s/--//g;
            $OpenAngle =~ s/^</<!--/;
            $CloseAngle =~ s/>$/-->/;
          }
        }

        # And put it all back together into the output string
        $$OutR .= $OpenAngle . $IsEndTag . $Tag . $TagContent . $CloseAngle;
        SkipOutput:

      # It's a comment of some sort. We are looking for regular HTML comment, XML CDATA section
      } elsif ($I =~ m{\G(!)((?:\[CDATA\[|--)?)}gcis) {

        my ($Comment, $CommentDelim) = ($1, $2);
        warn "defang Comment=$Comment CommentDelim=$CommentDelim" if $Debug;

        # Find the appropriate closing delimiter
        my $IsCDATA = $CommentDelim eq "[CDATA[";
        my $ClosingCommentDelim = $IsCDATA ? "]]" : $CommentDelim;

        warn "defang ClosingCommentDelim=$ClosingCommentDelim" if $Debug;

        my ($CommentStartText, $CommentEndText) = ("--/*SC*/", "/*EC*/--");

        # Convert to regular HTML comment
        if (!$Self->{delete_defang_content}) {
          $$OutR .= $OpenAngle . $Comment . $CommentStartText;
        }

        # Find closing comment
        if ($I =~ m{\G(.*?)(\Q$ClosingCommentDelim\E!?\s*)(>)}gcis || $I =~ m{\G(.*?)(--)(>)}gcis) {

          my ( $StartTag, $CommentData, $ClosingTag, $CloseAngle ) =
            ( $CommentDelim, $1, $2, $3 );

          # Strip all HTML comment markers
          $StartTag =~ s/--//g;
          $CommentData =~ s/--//g;
          $ClosingTag =~ s/--//g;

          if (!$Self->{delete_defang_content}) {
            # Put it all into the output
            $$OutR .= $StartTag
              . $CommentData
              . $ClosingTag
              . $CommentEndText
              . $CloseAngle;
          }

        # No closing comment, so we add that
        } else {

          $I =~ m/\G(.*)$/gcs || die "Remainder of line match failed";
        
          my $Data = $1;
          $Data =~ s/--//g;
        
          # Output
          if (!$Self->{delete_defang_content}) {
            $$OutR .= $Data . $CommentEndText . ">";
          }

        }

      # XML processing instruction
      } elsif ($I =~ m{\G(\?)}gcs) {
        my ($Processing) = ($1);
        warn "defang XML processing instruction" if $Debug;
      
        my $Data;
        if ($I =~ m{\G(.*?\??)>}gcs) {
          $Data = $1;
        } else {
          $I =~ m{\G(.*)$}gcs;
          $Data = $1;
        }
      
        $Data =~ s{--}{}g;

        if (!$Self->{delete_defang_content}) {
          $$OutR .= $OpenAngle . '!--' . $Processing . $Data . '-->';
        }

      }
      # Some other thing starting with <, keep looking

      if (exists $Self->{TrackedAppendOutput}) {
        for (@{delete $Self->{TrackedAppendOutput}}) {
          $Self->open_tag(1, $OutR, \$I, $_->[0], \$_->[1], 1);
        }
      }
      if (exists $Self->{AppendOutput}) {
        $$OutR .= delete $Self->{AppendOutput};
      }
      if (exists $Self->{DelayedAppendOutput}) {
        $Self->defang(delete $Self->{DelayedAppendOutput}, { add_to_existing => 1 });
      }
      next;
    }
  
    # No tag found, just copy rest
    warn "defang OutputRemainder" if $Debug;
    $I =~ m/\G(.*)$/gcs;

    $$OutR .= $1 if $1;

    # Exit if we got here
    last;
  }

  # If not a recursive call, close mismatched tags
  if ($Self->{Reentrant}-- <= 1) {
    $Self->close_all_tags($OutR, \$I);
  }

  # Turn on utf-8 flag again
  Encode::_utf8_on($$OutR) if $UTF8Input;

  return $$OutR;
}

=item I<add_to_output($String)>

Appends $String to the output after the current parsed tag ends. Can be used by client code in callback methods to add HTML text to the processed output. If the HTML text needs to be defanged, client code can safely call HTML::Defang->defang() recursively from within the callback.

=over 4

=item B<Method parameters>

=over 4

=item I<$String>

The string that is added after the current parsed tag ends.

=back

=back

=back

=cut
sub add_to_output {
  # Callbacks call this method
  my $Self = shift;
  $Self->{AppendOutput} = '' if !defined $Self->{AppendOutput};
  $Self->{AppendOutput} .= shift;
}

sub defang_and_add_to_output {
  my $Self = shift;
  $Self->{DelayedAppendOutput} = '' if !defined $Self->{DelayedAppendOutput};
  $Self->{DelayedAppendOutput} .= shift;
}

sub track_and_add_tag_to_output {
  my $Self = shift;
  push @{$Self->{TrackedAppendOutput}}, shift;
}

=item B<INTERNAL METHODS>

Generally these methods never need to be called by users of the class, because they'll be called internally as the appropriate tags are 
encountered, but they may be useful for some users in some cases.

=over 4

=cut

=item I<defang_script_tag($OutR, $HtmlR, $TagOps, $OpenAngle, $IsEndTag, $Tag, $TagTrail, $Attributes, $CloseAngle)>

This method is invoked when a <script> tag is parsed. Defangs the <script> opening tag, and any closing tag. Any scripting content is also commented out, so browsers don't display them.

Returns 1 to indicate that the <script> tag must be defanged.

=over 4

=item B<Method parameters>

=over 4

=item I<$OutR>

A reference to the processed output HTML before the tag that is currently being parsed.

=item I<$HtmlR>

A scalar reference to the input HTML.

=item I<$TagOps>

Indicates what operation should be done on a tag. Can be undefined, integer or code reference. Undefined indicates an unknown tag to HTML::Defang, 1 indicates a known safe tag, 0 indicates a known unsafe tag, and a code reference indicates a subroutine that should be called to parse the current tag. For example, <style> and <script> tags are parsed by dedicated subroutines.

=item I<$OpenAngle>

Opening angle(<) sign of the current tag.

=item I<$IsEndTag>

Has the value '/' if the current tag is a closing tag.

=item I<$Tag>

The HTML tag that is currently being parsed.

=item I<$TagTrail>

Any space after the tag, but before attributes.

=item I<$Attributes>

A reference to an array of the attributes and their values, including any surrouding spaces. Each element of the array is added by 'push' calls like below.

  push @$Attributes, [ $AttributeName, $SpaceBeforeEquals, $EqualsAndSubsequentSpace, $QuoteChar, $AttributeValue, $QuoteChar, $SpaceAfterAtributeValue ];

=item I<$CloseAngle>

Anything after the end of last attribute including the closing HTML angle(>)

=back

=back

=cut
sub defang_script_tag {
  my $Self = shift;
  my ($OutR, $HtmlR, $TagOps, $OpenAngle, $IsEndTag, $lcTag, $TagTrail, $Attributes, $CloseAngle) = @_;
  warn "defang_script Processing <script> tag" if $Self->{Debug};

  if (!$IsEndTag) {

    # If we just parsed a starting <script> tag, find up to end tag
    #  There's all sort of possible mess around this:
    #   </script<foo> - not really an end tag
    #   </script foo="bar > yes, still in a attribute"> - a valid end tag
    #  For weird cases, we end script tag early and end up defanging script
    #  content as HTML content, which is still safe
    if ($$HtmlR =~ m{\G(.*?)(?=</script\b)}gcsi) {
      my $ScriptTagContents = $1;
      warn "defang_script ScriptTagContents $ScriptTagContents" if $Self->{Debug};
      if (!$Self->{delete_defang_content}) {
        $ScriptTagContents =~ s/<!--|-->|--//g;
        $ScriptTagContents = "<!-- " . $ScriptTagContents . " -->";
        $Self->add_to_output($ScriptTagContents);
      }
    }
  }

  # Also defang tag
  return DEFANG_ALWAYS;
}

sub defang_style_tag {
  my ($Self, $OutR, $HtmlR, $TagOps, $OpenAngle, $IsEndTag, $lcTag, $TagTrail, $Attributes, $CloseAngle) = @_;

  warn "defang_style_tag Tag=$lcTag IsEndTag=$IsEndTag" if $Self->{Debug};

  # Defang attributes
  my $Defang = $Self->defang_attributes($OutR, $HtmlR, $TagOps, $OpenAngle, $IsEndTag, $lcTag, $TagTrail, $Attributes, $CloseAngle);

  # Nothing to do if end tag
  return $Defang if $IsEndTag;

  # Do all style work in byte mode
  use bytes;

  my $Content = '';
  my $ClosingStyleTagPresent = 1;

  for ($$HtmlR) {
    if (m{\G(.*?)(?=</style\b)}gcis) {
      $Content = $1;

    # No ending style tag
    } elsif (m{\G([^<]*)}gcis) {
      $Content = $1;
      $ClosingStyleTagPresent = 0;
    }
  }

  # Handle any wrapping HTML comments. If no comments, we add
  my ($OpeningHtmlComment, $ClosingHtmlComment) = ('', '');
  $OpeningHtmlComment = $Content =~ s{^(\s*<!--)}{} ? $1 . " " : "<!-- ";
  $ClosingHtmlComment = $Content =~ s{(-->\s*)$}{} ? " " . $1 : " -->";

  # Check for large bogus style data with mostly HTML tags and blat it
  if (length $Content > 16384) {
    my $TagCount = 0;
    $TagCount++ while $Content =~ m{</?\w+\b[^>]*>}g;
    if ($TagCount > length($Content)/256) {
      $Content = '';
    }
  }

  my $StyleOut = $Self->defang_style_text($Content, $lcTag, 0, undef, $HtmlR, $OutR);

  $Self->add_to_output($OpeningHtmlComment . $StyleOut . $ClosingHtmlComment);
  $Self->add_to_output("</style>") if !$ClosingStyleTagPresent;

  return $Defang;
}

=item I<defang_style_text($Content, $lcTag, $IsAttr, $AttributeHash, $HtmlR, $OutR)>

Defang some raw css data and return the defanged content

=over 4

=item B<Method parameters>

=over 4

=item I<$Content>

The input style string that is defanged.

=item I<$IsAttr>

True if $Content is from an attribute, otherwise from a <style> block

=back

=back

=cut
sub defang_style_text {
  my ($Self, $Content, $lcTag, $IsAttr, $AttributeHash, $HtmlR, $OutR) = @_;

  # Clean up all comments, expand character escapes and such
  $Self->cleanup_style($Content, $IsAttr);

  # Style attributes can optionally have selector type elements, so we check whether we 
  # have a '{' in $Content: if yes, its style data with selector type elements
  my $Naked = $Content !~ m/\{/;
  warn "defang_style Naked=$Naked" if $Self->{Debug};

  # And suitably change the regex to match the data
  my $SelectorRuleRE = $Naked ? $RECStyleNaked : $RECStyleSelected;

  my (@Selectors, @SelectorRules, @ExtraData, @InMedia);

  # Now we parse the selectors and declarations
  while (1) {
    if ($Content =~ m{$RECStyleMediaSelector}sgco) {
      push @InMedia, $2;
      push @Selectors, $2;
      push @SelectorRules, "";
      push @ExtraData, [ $1, "", $3, "", $4 ];
    } elsif (@InMedia && $Content =~ m{\G(\s*)(\})(\s*)}sgc) {
      pop @InMedia;
      push @Selectors, "";
      push @SelectorRules, "";
      push @ExtraData, [ $1, "", "", $2, $3 ];
    } elsif ($Content =~ m{$SelectorRuleRE}sgc) {
      my ($Selector, $SelectorRule) = ($2, $5);
      last if $Selector eq '' && $SelectorRule =~ /^[;\s]*$/;
      $Selector = join("\000", @InMedia, $Selector) if @InMedia;
      push @Selectors, $Selector;
      push @SelectorRules, $SelectorRule;
      push @ExtraData, [ $1, $3, $4, $6, $7];
      warn "defang_style Selector=$Selector" if $Self->{Debug};
      warn "defang_style SelectorRule=$SelectorRule" if $Self->{Debug};

    # Just a large bunch of selectors and no rules, suck up and discard
    } elsif (!$Naked && $Content =~ m{\G\s*$StyleSelectors\s*$}sgc) {
    # Looks like an html tag, suck up and discard
    } elsif (!$Naked && $Content =~ m{\G(?:</?$TagNameRE(?:\s[^>\{\}]*)?>\s*)+}sgc) {

    # If content didn't match a rule, suck up whitespace
    } elsif ($Content =~ m{\G\s+}sgc) {
    # Or any non-whitespace, but try and sync to <...> tags
    } elsif ($Content =~ m{\G[^\s<]+}sgc || $Content =~ m{\G<+}sgc) {

    # Nothing matched, must be at end
    } else { last; }
  }

  # Check declaration elements for defanging
  $Self->defang_stylerule(\@Selectors, \@SelectorRules, $lcTag, $IsAttr, $AttributeHash, $HtmlR, $OutR);

  my $StyleOut = "";

  # Re-create the style data
  foreach my $Selector (@Selectors) {

    my $SelectorRule = shift @SelectorRules;
    my $Spaces = shift @ExtraData;
    my ($BeforeSelector, $AfterSelector, $OpenBrace, $CloseBrace, $AfterRule) = @$Spaces if $Spaces;
    ($BeforeSelector, $AfterSelector, $AfterRule) = ("", " ", "\n") unless $Spaces;
    ($OpenBrace, $CloseBrace) = ("{", "}") if !$Spaces && !$IsAttr;
  
    # Put back the rule together
    if (defined($Selector)) {
      $StyleOut .= $BeforeSelector if defined($BeforeSelector);
      $StyleOut .= $Selector =~ /\000/ ? (reverse split /\000/, $Selector)[0] : $Selector;
      $StyleOut .= $AfterSelector if defined($AfterSelector);
      $StyleOut .= $OpenBrace if defined($OpenBrace);
      $StyleOut .= $SelectorRule if defined($SelectorRule);
      $StyleOut .= $CloseBrace if defined($CloseBrace);
      $StyleOut .= $AfterRule if defined($AfterRule);
    }
  
  }

  warn "defang_style StyleOut=$StyleOut" if $Self->{Debug};

  return $StyleOut;
}

=item I<cleanup_style($StyleString)>

Helper function to clean up CSS data. This function directly operates on the input string without taking a copy.

=over 4

=item B<Method parameters>

=over 4

=item I<$StyleString>

The input style string that is cleaned.

=back

=back

=cut
sub cleanup_style {
  my $Self = shift;
  
  for ($_[0]) {
    my $UnicodeEntity = 0;
    # Expand unicode \ refs
    s{(?:\\)(0?[\da-f]{1,6});?}{
      my $V = (defined($1) && hex($1)) || undef;
      $UnicodeEntity = 1 if $V && $V > 127;
      $V && $V < 1_114_111 && $V != 65535 && !($V > 55295 && $V < 57344) ? chr($V) : ""
    }egi;
    # Remove all remaining invalid escapes TODO This probably is not correct. Backslashes are required to be left alone by the CSS syntax
    s/\\//g;

    # Second param is true if it's an attribute, which means these have already been done
    if (!$_[1]) {
      # Expand escapes
      s{&#(?:x(0?[\da-f]{1,6})|([\d]{1,7}));?}{
        my $V = (defined($1) && hex($1)) || (defined($2) && int($2)) || undef;
        $UnicodeEntity = 1 if $V && $V > 127;
        $V && $V < 1_114_111 && $V != 65535 && !($V > 55295 && $V < 57344) ? chr($V) : "";
      }egi;
      s/&(quot|apos|amp|lt|gt);?/$EntityToChar{lc($1)} || warn "no entity for: $1"/egi;
    }

    # Remove all CSS comments
    s{/\*.*?\*/}{}sg;

    # Remove any CSS imports
    s{(\@import[^;]+;?)}{}sg;

    # Have to upgrade string to unicode string if entity expansion
    #  resulted in non-ascii char
    utf8::upgrade($_) if $UnicodeEntity;

    warn "cleanup_style Content=$_" if $Self->{Debug};
  }

}

=item I<defang_stylerule($SelectorsIn, $StyleRules, $lcTag, $IsAttr, $AttributeHash, $HtmlR, $OutR)>

Defangs style data.

=over 4

=item B<Method parameters>

=over 4

=item I<$SelectorsIn>

An array reference to the selectors in the style tag/attribute contents.

=item I<$StyleRules>

An array reference to the declaration blocks in the style tag/attribute contents.

=item I<$lcTag>

Lower case version of the HTML tag that is currently being parsed.

=item I<$IsAttr>

Whether we are currently parsing a style attribute or style tag. $IsAttr will be true if we are currently parsing a style attribute.

=item I<$HtmlR>

A scalar reference to the input HTML.

=item I<$OutR>

A scalar reference to the processed output so far.

=back

=back

=cut
sub defang_stylerule {
  my ($Self, $SelectorsIn, $StyleRules, $lcTag, $IsAttr, $AttributeHash, $HtmlR, $OutR) = @_;

  my (@SelectorStyleKeyValues, %SelectorStyleKeyExtraData);

  my (@Selectors, @SelectorRules);

  foreach my $Selector (@$SelectorsIn) {

    warn "defang_stylerule Selector=$Selector" if $Self->{Debug};
    my $Rule = shift @$StyleRules;
    my (@SelectorRule, @KeyValueRules, %StyleKeyExtraData);

    # Split style declaration to basic elements
    while($Rule =~ s{^(\{?\s*)([^:]+?)(\s*:\s*)((?:)?)([^;\}]+)()?(\s*;?)(\s*\}?)}{}) {
      my ($KeyPilot, $Key, $Separator, $QuoteStart, $Value, $QuoteEnd, $ValueEnd, $ValueTrail) = ($1, $2, $3, $4, $5, $6, $7, $8);
      
      warn "defang_stylerule Key=$Key Value=$Value Separator=$Separator ValueEnd=$ValueEnd" if $Self->{Debug};
      # Store everything except style property and value in a hash
      $StyleKeyExtraData{lc $Key} = [$KeyPilot, $Separator, $QuoteStart, $QuoteEnd, $ValueEnd, $ValueTrail];
      my $DefangStyleRule = $Self->{defang_default};

      # If the style value has a URL in it and URL callback has been supplied, make a url_callback
      if ($Self->{url_callback}) {
        our $StartPos = 0;
        while ($Value =~ m/\G\s*url\(\s*((?:['"])?)(?{ $StartPos = pos; })(.*?)\1\s*\)/gci) {
          my ($UrlOrig, $Url) = $2 ? ($2, $2) : ('', '');
          my $EndPos = pos($Value);
          warn "defang_stylerule Url found in style property value. Url=$Url" if $Self->{Debug};
          my $lcAttrKey = $IsAttr ? "style" : undef;
          $DefangStyleRule = $Self->{url_callback}->($Self->{context}, $Self, $lcTag, $lcAttrKey, \$Url, $AttributeHash, $HtmlR, $OutR, lc $Key) if $Url;
          # Save back any changes
          warn "defang_stylerule After URL callback, Value=$Value DefangStyleRule=$DefangStyleRule" if $Self->{Debug};
          if ($UrlOrig) {
            substr($Value, $StartPos, length($UrlOrig), $Url);
            pos($Value) = $EndPos - length($UrlOrig) + length($Url);
          }
        }
      }

      # Save the style property, value and defang flag      
      push @KeyValueRules, [$Key, $Value, $DefangStyleRule];
      warn "defang_stylerule Key=$Key Value=$Value DefangStyleRule=$DefangStyleRule" if $Self->{Debug};

    }

    push (@SelectorRule, \@KeyValueRules);
    push (@Selectors, $Selector);
    push (@SelectorRules, \@SelectorRule);
    $SelectorStyleKeyExtraData{$Selector} = \%StyleKeyExtraData;

  }

  # If a CSS callback is supplied, we call that
  $Self->{css_callback}->($Self->{context}, $Self, \@Selectors, \@SelectorRules, $lcTag, $IsAttr, $OutR) if $Self->{css_callback};

  warn "defang_stylerule More selectors($#Selectors) than selector rules($#SelectorRules)" if $Self->{Debug} 
    && $#Selectors > $#SelectorRules;

  my $Counter = 0;
  foreach my $Selector (@Selectors) {

    my $SelectorRule = $SelectorRules[$Counter];
    my $ExtraData = $SelectorStyleKeyExtraData{$Selector};
    my $Rule;

    for (my $j = 0; $j < @$SelectorRule; $j++) {
      my $KeyValueRules = $SelectorRule->[$j];
      
      for (my $k = 0; $k < @$KeyValueRules; $k++) {
        my ($Key, $Value, $Defang) = @{$KeyValueRules->[$k]};

        my $v = ($ExtraData->{lc $Key} ||= []);
        my ($KeyPilot, $Separator, $QuoteStart, $QuoteEnd, $ValueEnd, $ValueTrail) = @$v;

        # Always need a separator
        $v->[1] //= ':';
        # If an intermediate style property-value pair doesn't have a terminating semi-colon, add it
        if ($k < @$KeyValueRules - 1) {
          $v->[4] .= ";" if !defined $v->[4] || $v->[4] !~ m/;/;
        }

      }
      
    }

    $Counter++;
  }
  
  $Counter = 0;
  foreach my $Selector (@Selectors) {
  
    $SelectorsIn->[$Counter] = $Selector if $SelectorsIn->[$Counter] && !$IsAttr;
    my $SelectorRule = $SelectorRules[$Counter];
    my $ExtraData = $SelectorStyleKeyExtraData{$Selector};
    my $Rule;
    
    foreach my $KeyRules (@$SelectorRule) {
    
      foreach my $KeyValueRule (@$KeyRules) {
      
        my ($Key, $Value, $Defang) = @$KeyValueRule;
        my $v = $ExtraData->{lc $Key};
        my ($KeyPilot, $Separator, $QuoteStart, $QuoteEnd, $ValueEnd, $ValueTrail) = @{$v || []};

        # Flag to defang if a url, expression or unallowed character found
        if ($Defang == DEFANG_DEFAULT) {
          $Defang = $Value =~ m{^\s*[a-z0-9%!"'`:()#\s.,\/+-]+\s*;?\s*$}i ? DEFANG_NONE : DEFANG_ALWAYS;
          $Defang = $Value =~ m{\burl\s*\(}i ? DEFANG_ALWAYS : $Defang;
          $Defang = $Value =~ m{\bexpression\s*\(}i ? DEFANG_ALWAYS : $Defang;
        }

        ($KeyPilot, $Key, $Separator, $QuoteStart, $Value, $QuoteEnd, $ValueEnd, $ValueTrail) =
          map { defined($_) ? $_ : "" }
            ($KeyPilot, $Key, $Separator, $QuoteStart, $Value, $QuoteEnd, $ValueEnd, $ValueTrail);
        
        # Comment out the style property-value pair if $Defang
        my $CommentDefang = 0;
        if ($Defang != DEFANG_NONE) {
          if ($Self->{delete_defang_content}) {
            $KeyPilot = $Key = $Separator = $QuoteStart = $Value = $QuoteEnd = $ValueEnd = $ValueTrail = '';
          } else {
            $CommentDefang = 1;
          }
        }

        # Put the rule together back
        if (defined($Key)) {
          my $RuleContent = join "", $Key, $Separator, $QuoteStart, $Value, $QuoteEnd, $ValueEnd;
          if ($CommentDefang) {
            # Strip any mismatched comment markers, then add our own
            $RuleContent =~ s{/\*}{}g;
            $RuleContent =~ s{\*/}{}g;
            $RuleContent = "/*" . $RuleContent . "*/";
          }
          $Rule .= join "", $KeyPilot, $RuleContent, $ValueTrail;
        }
          
        warn "defang_stylerule Rule=$Rule" if $Self->{Debug};

      }

    }

    # Modify the original array
    $StyleRules->[$Counter] = $Rule;
    $Counter++;
  }

}

=item I<defang_attributes($OutR, $HtmlR, $TagOps, $OpenAngle, $IsEndTag, $Tag, $TagTrail, $Attributes, $CloseAngle)>

Defangs attributes, defangs tags, does tag, attrib, css and url callbacks.

=over 4

=item B<Method parameters>

For a description of the method parameters, see documentation of defang_script_tag() method

=back

=cut
sub defang_attributes {
  my ($Self, $OutR, $HtmlR, $TagOps, $OpenAngle, $IsEndTag, $lcTag, $TagTrail, $Attributes, $CloseAngle) = @_;

  my $Debug = $Self->{Debug};

  my $DefangTag = $Self->{defang_default};
  my ($DefangTagUrlOverride, $DefangTagAttrOverride);

  # Create a key -> \value mapping of all attributes up front
  #  so we have a complete hash for each callback
  my %AttributeHash;
  for my $Attr (@$Attributes) {
    my ($AttrKey, $AttrValR) = ($Attr->[0], \$Attr->[4]);

    my $lcAttrKey = $Attr->[7] = lc($AttrKey // "");

    # Get the attribute value cleaned up
    $$AttrValR = $Self->cleanup_attribute($$AttrValR);
    warn "defang_attributes cleaned AttrVal=$$AttrValR" if $Debug;

    $AttributeHash{$lcAttrKey} = $AttrValR;
  }

  # Callback if the tag is in @$tags_to_callback
  if (exists($Self->{tags_to_callback}->{$lcTag})) {
    warn "defang_attributes Calling tags_callback for $lcTag" if $Debug;
    $DefangTag = $Self->{tags_callback}->($Self->{context}, $Self, $OpenAngle, $lcTag, $IsEndTag, \%AttributeHash, $CloseAngle, $HtmlR, $OutR);
  }

  # Now process each attribute
  foreach my $Attr (@$Attributes) {
    my ($lcAttrKey, $AttrKey, $AttrValR) = ($Attr->[7], $Attr->[0], \$Attr->[4]);

    warn "defang_attributes Tag=$lcTag lcAttrKey=$lcAttrKey AttrVal=$$AttrValR" if $Debug;

    my $AttribRule = "";
    if (ref($Tags{$lcTag}) eq 'HASH') {
      $AttribRule = $Tags{$lcTag}{$lcAttrKey};
    }

    my $DefangAttrib = $Self->{defang_default};

    $AttribRule ||= $CommonAttributes{$lcAttrKey};
    warn "defang_attributes AttribRule=$AttribRule" if $Debug;
    
    # If this is a URL type $AttrKey and URL callback method is supplied, make a url_callback
    if ($Self->{url_callback} && $AttribRule && exists($UrlRules{$AttribRule})) {
        warn "defang_attributes Making URL callback" if $Debug;
        ($DefangAttrib, $DefangTagUrlOverride) = $Self->{url_callback}->($Self->{context}, $Self, $lcTag, $lcAttrKey, $AttrValR, \%AttributeHash, $HtmlR, $OutR, { defang_attrib => $DefangAttrib, attrib_rule => $AttribRule });
        die "url_callback reset" if !defined pos($$HtmlR);
    }

    # We have a style attribute, so we call defang_style
    if ($lcAttrKey eq "style") {
      warn "defang_attributes Found style attribute, calling defang_style" if $Debug;
      $$AttrValR = $Self->defang_style_text($$AttrValR, $lcTag, 1, \%AttributeHash, $HtmlR, $OutR);
    }

    # If a attribute callback is supplied and its interested in this attribute, we make a attribs_callback
    if ($Self->{attribs_callback} && exists($Self->{attribs_to_callback}->{$lcAttrKey})) {
      warn "defang_attributes Making attribute callback for Tag=$lcTag AttrKey=$AttrKey" if $Debug;
      (my $DefangResult, $DefangTagAttrOverride) = $Self->{attribs_callback}->($Self->{context}, $Self, $lcTag, $lcAttrKey, $AttrValR, $HtmlR, $OutR);
      # Only use new result if not already DEFANG_ALWAYS from url_callback
      $DefangAttrib = $DefangResult if $DefangAttrib != DEFANG_ALWAYS;
    }

    # Check if the final attribute value needs defanging
    $DefangAttrib = $Self->defang_attribute_value($AttrValR, $AttribRule, $DefangAttrib);

    # Store the attribute defang flag
    $Attr->[8] = $DefangAttrib;

  }

  my @OutputAttributes;

  foreach my $Attr (@$Attributes) {
 
    my $lcAttr = $Attr->[7];

    # If the attribute is deleted don't output it
    unless ($AttributeHash{$lcAttr}) {
      warn "defang_attributes Marking attribute $lcAttr for deletion" if $Debug;
      next;
    }

    # And we attach the defang string here, if the attribute should be defanged
    # (attribute could be undef for buggy html, eg <ahref=blah>)
    if ($Attr->[8] != DEFANG_NONE) {
      if ($Self->{delete_defang_content}) {
        @$Attr = ('') x 7;
      } else {
        $Attr->[0] = $Self->{defang_string} . ($Attr->[0] || '')
          if $Self->{allow_double_defang} || ($Attr->[0] || '') !~ $Self->{defang_re};
      }
    }

    # Remove non-attribute values so they're not in the output
    splice(@$Attr, 7);

    # Requote specials in attribute value
    if (defined $Attr->[4]) {
      my $QuoteRe = $QuoteRe{$Attr->[3]} || $QuoteRe{""};
      $Attr->[4] =~ s/$CtrlChars//go; # strip ctrls
      $Attr->[4] =~ s/$QuoteRe/'&'.$CharToEntity{$1}.';'/eg;
    }

    # Add to attributes to output
    push @OutputAttributes, $Attr;

    # Remove all processed attributes in the hash, so we can track ones that we added
    delete $AttributeHash{$lcAttr};
  }

  # Append all remaining attribute keys (which must have been newly added attributes by 
  # the callback)and values in no particular order
  my $QuoteRe = $QuoteRe{'"'};
  while (my ($Key,$Value) = each %AttributeHash ) {
    my $Attr = [" " . $Key, "", "=", '"', $$Value, '"', ""];
    if (defined $Attr->[4]) {
      $Attr->[4] =~ s/$CtrlChars//g; # strip ctrls
      $Attr->[4] =~ s/$QuoteRe/'&'.$CharToEntity{$1}.';'/eg
    } else {
      @$Attr[2..6] = (undef) x 5;
    }
    push @OutputAttributes, $Attr;
  }

  # Replace attributes array with just the ones we want to output
  @$Attributes = @OutputAttributes;

  # If its a known tag, we whitelist it
  if ($DefangTag == DEFANG_DEFAULT && (my $TagOps = $Tags{$lcTag})) {
    $DefangTag = DEFANG_NONE;
  }
  # Unless we have overrides
  $DefangTag = DEFANG_ALWAYS
    if defined($DefangTagUrlOverride) && $DefangTagUrlOverride == DEFANG_ALWAYS;
  $DefangTag = DEFANG_ALWAYS
    if defined($DefangTagAttrOverride) && $DefangTagAttrOverride == DEFANG_ALWAYS;

  return $DefangTag;
}

sub defang_attribute_value {
  my ($Self, $AttrValR, $AttribRule, $DefangAttrib) = @_;

  my $Debug = $Self->{Debug};

  my $AttrValStripped = $Self->strip_attribute($$AttrValR);

  warn "defang_attribute_value AttrVal=$$AttrValR AttrValStripped=$AttrValStripped" if $Debug;

  if (($DefangAttrib == DEFANG_DEFAULT) && $AttribRule) {
    my $Rule = $Rules{$AttribRule};
    warn "defang_attributes AttribRule=$AttribRule Rule=$Rule" if $Debug;

    # We whitelist the attribute if the value matches the rule
    if (ref($Rule) eq "Regexp") {
      $DefangAttrib = ($AttrValStripped =~ $Rule) ? DEFANG_NONE : DEFANG_ALWAYS;
    }

    # Hack. Ref to array is a blacklist regexp
    if (ref($Rule) eq "ARRAY") {
      $DefangAttrib = ($AttrValStripped =~ $Rule->[0]) ? DEFANG_ALWAYS : DEFANG_NONE;
    }
    
  } elsif (!$AttribRule && $DefangAttrib != DEFANG_NONE)  {
    $DefangAttrib = DEFANG_ALWAYS;
  }

  warn "defang_attribute_value DefangAttrib=$DefangAttrib" if $Debug;

  return $DefangAttrib;
}

sub track_implicit_tags {
  my ($Self, $OutR, $HtmlR, $lcTag, $IsEndTag) = @_;

  my $OpenedTags = $Self->{opened_tags};
  return if !@$OpenedTags;

  # If just closing the last tag, nothing to do
  my $LastTag = $OpenedTags->[-1]->[0];

  # Are we expecting a particular tag based on last open tag?
  if (my $ImplicitTags = $ImplicitOpenTags{$LastTag}) {

    # We didn't get a tag we were expecting (eg <table><div> rather
    #  than <table><tbody><tr><td><div>), so insert opening tags recursively
    $LastTag = $lcTag;
    while ($ImplicitTags && (!$ImplicitTags->{$LastTag} || $IsEndTag)) {
      my $Tag = $ImplicitTags->{default};
      # Don't insert implicit tag if it's actually the one we actually just parsed
      last if !$IsEndTag && $Tag eq $lcTag;
      $Self->open_tag(1, $OutR, $HtmlR, $Tag, \"");
      $$OutR .= "<!-- $Tag implicit open due to $LastTag -->" unless $Self->{quiet};
      $LastTag = $Tag;
      $ImplicitTags = $ImplicitOpenTags{$LastTag};
    }
  }
}

sub track_in_to_block_tags {
  my ($Self, $OutR, $HtmlR, $lcTag) = @_;

  # If we've got a block tag, then close any inline tags
  #  before the block tag. We'll re-opened them again below
  if ($BlockTags{$lcTag} && !$TableTags{$lcTag}) {
    my ($OpenedTags, $ClosedIntoBlockTags, $Quiet)
      = @$Self{qw(opened_tags closed_into_block_tags quiet)};

    while (@$OpenedTags && $InlineTags{$OpenedTags->[-1]->[0]}) {
      push @$ClosedIntoBlockTags, my $POTD = $OpenedTags->[-1];
      $$OutR .= "<!-- close inline tag into block -->" unless $Quiet;
      $Self->close_tag(1, $OutR, $HtmlR, $POTD->[0], 1);
    }
  }
}

sub track_out_of_block_tags {
  my ($Self, $OutR, $HtmlR, $lcTag) = @_;

  my $ClosedIntoBlockTags = $Self->{closed_into_block_tags};
  return if !@$ClosedIntoBlockTags;

  # Re-open inline tags into this block

  # Peek ahead. If another block tag, don't do this
  return if $$HtmlR =~ m{\G(?=\s*</?($TagNameRE))}gc
    && $BlockTags{lc "$1"} && !$TableTags{lc "$1"};

  my ($SpanCount, $SpanAttrs) = (0, '');
  while (my $POTD = pop @$ClosedIntoBlockTags) {

    # Don't add more than 3 span tags with same attrs in a row
    if ($SpanCount < 3) {
      # Add after the current tag is output
      $Self->track_and_add_tag_to_output($POTD);
      $Self->add_to_output("<!-- reopen inline tag after block -->") unless $Self->{quiet};
    }
    $SpanCount = $POTD->[0] eq 'span' && $POTD->[1] eq $SpanAttrs ? $SpanCount+1 : 0;
    $SpanAttrs = $POTD->[1];
  }
}

sub open_tag {
  my ($Self, $AddOutput, $OutR, $HtmlR, $lcTag, $TagContentR, $NoBlockCheck) = @_;

  $Self->track_implicit_tags($OutR, $HtmlR, $lcTag, 0);
  $Self->track_in_to_block_tags($OutR, $HtmlR, $lcTag)
    unless $NoBlockCheck;

  # Track this tag that was opened (and all attributes, so we can re-open with the same if needed)
  if ($Self->{mismatched_tags_to_fix}->{$lcTag}) {
    push @{$Self->{opened_tags}}, [ $lcTag, $$TagContentR ];
    $Self->{opened_tags_count}->{$lcTag}++;
  }
  if ($AddOutput) {
    $$OutR .= "<${lcTag}${$TagContentR}>";
  }

  $Self->track_out_of_block_tags($OutR, $HtmlR, $lcTag)
    unless $NoBlockCheck;

  return DEFANG_NONE;
}

my %RECache;
sub close_tag {
  my ($Self, $AddOutput, $OutR, $HtmlR, $lcTag, $NoBlockCheck) = @_;

  my ($OpenedTags, $OpenedTagsCount, $Quiet)
    = @$Self{qw(opened_tags opened_tags_count quiet)};

  # If just closing the last tag, nothing to do
  if (@$OpenedTags && $OpenedTags->[-1]->[0] ne $lcTag) {
    $Self->track_implicit_tags($OutR, $HtmlR, $lcTag, 1);
  }

  $Self->track_in_to_block_tags($OutR, $HtmlR, $lcTag)
    unless $NoBlockCheck;

  # Check for correctly nested closing tags
  my $IsTagToFix = $Self->{mismatched_tags_to_fix}->{$lcTag};
  if ($IsTagToFix) {
    my ($Found, $ClosingTags) = (0, '');

    # Tag not even open, just defang it
    return DEFANG_ALWAYS if !$OpenedTagsCount->{$lcTag};

    # Check tag stack up to find mismatches
    while (@$OpenedTags) {
      my ($PreviousOpenedTag) = @{$OpenedTags->[-1]};

      if ($PreviousOpenedTag eq $lcTag) {
        $Found = 1;
        last;
      }

      # Check for tags that don't break out further
      if (my $NestList = $MismatchedTagNest{$PreviousOpenedTag}) {
        last if $NestList->{""} || $NestList->{$lcTag};
      }

      # Close this mismatched tag
      $$OutR .= "<!-- close mismatched tag -->" unless $Quiet;
      $Self->close_tag(1, $OutR, $HtmlR, $PreviousOpenedTag);
    }

    # Otherwise hit tag that stops breaking out, defang it
    if (!$Found) {
      return DEFANG_ALWAYS;
    }
  }

  my $Result = DEFANG_NONE;

  if ($IsTagToFix && $Self->{empty_tags_to_collapse}->{$lcTag}) {

    # Check if previous output is open tag, or just comments
    my $LastTagPos = rindex($$OutR, '<');
    while ($LastTagPos >= 0) {
      pos($$OutR) = $LastTagPos;
      my $RE = ($RECache{$lcTag} //= qr/\G<${lcTag}\b[^<>]*>\s*(?:<|$)/);
      if ($$OutR =~ /$RE/gc) {
        substr($$OutR, $LastTagPos) = '';
        ($AddOutput, $Result) = (0, DEFANG_ALWAYS);
        last;
      } elsif ($$OutR =~ /\G<!--(?!KEEP)[^<>]*-->\s*(?:<|$)/gc && $LastTagPos > 0) {
        $LastTagPos = rindex($$OutR, '<', $LastTagPos-1);
      } else {
        last;
      }
    }
  }

  if ($IsTagToFix) {
    if ($lcTag eq $Self->{opened_tags}->[-1]->[0]) {
      pop @{$Self->{opened_tags}};
      $Self->{opened_tags_count}->{$lcTag}--;
    } else {
      warn "Unexpected tag stack. Expected $lcTag, found " . $Self->{opened_tags}->[-1]->[0];
    }
  }
  if ($AddOutput) {
    $$OutR .= "</$lcTag>";
  }

  $Self->track_out_of_block_tags($OutR, $HtmlR, $lcTag)
    unless $NoBlockCheck;

  return $Result;
}

sub close_all_tags {
  my ($Self, $OutR, $HtmlR) = @_;

  my $RemainingClosingTags = '';

  my ($OpenedTags, $OpenedTagsCount, $Quiet)
    = @$Self{qw(opened_tags opened_tags_count quiet)};

  for (reverse @$OpenedTags) {
    $$OutR .= "<!-- close unclosed tag -->" unless $Quiet;
    $Self->close_tag(1, $OutR, $HtmlR, $_->[0]);
  }

  # Also clear implicit tags
  $Self->{opened_nested_tags} = [];

  if ($Self->{Debug}) {
    warn "Check all tags closed and counts zeroed";
    die "Not all tags closed" if grep { $_ > 0 } values %$OpenedTagsCount;
  }
}

=item I<cleanup_attribute($AttributeString)>

Helper function to cleanup attributes

=over 4

=item B<Method parameters>

=over 4

=item I<$AttributeString>

The value of the attribute.

=back

=back

=back

=back

=cut
sub cleanup_attribute {
  my ($Self, $AttrVal) = @_;

  return (undef, '') unless defined($AttrVal);

  # Create a "stripped" attribute value which removes all embedded whitespace and control characters

  # Substitute character entities with actual characters
  # - in HTML, &#xa; &#x0a; &#x000a; &#10; are all character codes
  # - in IE, &#xajavascript is same as &#xa;javascript
  # - avoid invalid chars + surrogate pairs
  my $UnicodeEntity = 0;
  $AttrVal =~ s{&#(?:x(0?[\da-f]{1,6})|([\d]{1,7}));?}{
    my $V = (defined($1) && hex($1)) || (defined($2) && int($2)) || undef;
    $UnicodeEntity = 1 if $V && $V > 127;
    $V && $V < 1_114_111 && $V != 65535 && !($V > 55295 && $V < 57344) ? chr($V) : "";
  }egi;

  # These get requoted when we output the attribute
  $AttrVal =~ s/&(quot|apos|amp|lt|gt);?/$EntityToChar{lc($1)} || warn "no entity for: $1"/egi;

  # Have to upgrade string to unicode string if entity expansion
  #  resulted in non-ascii char
  utf8::upgrade($AttrVal) if $UnicodeEntity;

  warn "cleanup_attribute AttrVal=$AttrVal" if $Self->{Debug};
  return $AttrVal;
}

sub strip_attribute {
  my ($Self, $AttrVal) = @_;

  # In JS, \u000a is unicode char (note &#x5c;&#x75;&#x30;&#x30;&#x37;&#x32; -> \u0072 -> r, so do HTML entities first)
  #  This can't be undone, so only do on stripped value
  $AttrVal =~ s/\\u(0?[\da-f]{1,6});?/defined($1) && hex($1) < 1_114_111 && hex($1) != 65535 && !(hex($1) > 55295 && hex($1) < 57344) ? chr(hex($1)) : ""/egi;

  # Also undo URL decoding for "stripped" value
  # (can't do this above, because it's non-reversible, eg "http://...?a=%25" => "http://...?a=?",
  #  how would we know which ? to requote when outputting?)
  $AttrVal =~ s/%([\da-f]{2})/chr(hex($1))/egi;
  $AttrVal =~ s/[\x00-\x19]+//g;
  $AttrVal =~ s/^[\x20]+//g; # http://ha.ckers.org/xss.html#XSS_Spaces_meta_chars

  return $AttrVal;
}

sub get_applicable_charset {

  my $Self = shift;
  local $_ = shift;
  my $Charset = shift;

  if(!$Charset) {
    # Look for <meta> tags
    my @MetaAttrs = /<meta[\s\/]+(${AttributesRE})/gi;

    for(@MetaAttrs) {
      my %Attrs;

      # Get attributes and their values
      while(s/(?:($AttrKeyStartLineRE)(\s*))?(?:(=\s*)($AttrValRE)(\s*))?//so) {
        last if !defined($1) && !defined($4);
        $Attrs{lc $1} = $4;
      }

      # Look for charset information
      if($Attrs{"content"}) {
        $Charset = $Attrs{"content"} =~ m/charset\s*=\s*([^\s;'"`]+)[\s;'"`]*/i ? $1 : $Charset;
      }
    }
  }

  # Return fallback charset if no header or meta charset found
  return $Charset ? $Charset : shift;
}

=head1 SEE ALSO

L<http://mailtools.anomy.net/>, L<http://htmlcleaner.sourceforge.net/>, I<HTML::StripScripts>, I<HTML::Detoxifier>, I<HTML::Sanitizer>, I<HTML::Scrubber>

=cut

=head1 AUTHOR

Kurian Jose Aerthail E<lt>cpan@kurianja.fastmail.fmE<gt>. Thanks to Rob Mueller E<lt>cpan@robm.fastmail.fmE<gt> for initial code, guidance and support and bug fixes.

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2013 by FastMail Pty Ltd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

