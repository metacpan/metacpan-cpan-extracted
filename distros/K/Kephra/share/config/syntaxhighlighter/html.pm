package syntaxhighlighter::html;
$VERSION = '0.3';

sub load{
use Wx qw(wxSTC_LEX_HTML wxSTC_H_TAG);

 $_[0]->SetLexer( wxSTC_LEX_HTML );            # Set Lexers to HTML

 my $html_elements = 'a abbr acronym address applet area b base basefont
bdo big blockquote body br button caption center
cite code col colgroup dd del dfn dir div dl dt em
fieldset font form frame frameset h1 h2 h3 h4 h5 h6
head hr html i iframe img input ins isindex kbd label
legend li link map menu meta noframes noscript
object ol optgroup option p param pre q s samp
script select small span strike strong style sub sup
table tbody td textarea tfoot th thead title tr tt u ul
var xml xmlns';

my $html_attributes = 'abbr accept-charset accept accesskey action align alink
alt archive axis background bgcolor border
cellpadding cellspacing char charoff charset checked cite
class classid clear codebase codetype color cols colspan
compact content coords
data datafld dataformatas datapagesize datasrc datetime
declare defer dir disabled enctype event
face for frame frameborder
headers height href hreflang hspace http-equiv
id ismap label lang language leftmargin link longdesc
marginwidth marginheight maxlength media method multiple
name nohref noresize noshade nowrap
object onblur onchange onclick ondblclick onfocus
onkeydown onkeypress onkeyup onload onmousedown
onmousemove onmouseover onmouseout onmouseup
onreset onselect onsubmit onunload
profile prompt readonly rel rev rows rowspan rules
scheme scope selected shape size span src standby start style
summary tabindex target text title topmargin type usemap
valign value valuetype version vlink vspace width
text password checkbox radio submit reset
file hidden image';

 $_[0]->SetKeyWords(1,$html_elements.$html_attributes."public !doctype");  # Add new keyword.
 #$_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec(0,"fore:#000000");                # Text
 $_[0]->StyleSetSpec(1,"fore:#2222A0,bold");        # Tags
 $_[0]->StyleSetSpec(2,"fore:#ff0117");                # Unknown Tags
 $_[0]->StyleSetSpec(3,"fore:#007700");                # Attributes
 $_[0]->StyleSetSpec(4,"fore:#ff00B0");                # Unknown Attributes
 $_[0]->StyleSetSpec(5,"fore:#3399BB");                # Numbers
 $_[0]->StyleSetSpec(6,"fore:#ee7b00,back:#fff8f8");                        #  Doublequoted string
 $_[0]->StyleSetSpec(7,"fore:#f36600,back:#fffcff");                        #  Single quoted string 
 #$_[0]->StyleSetSpec(6,"fore:#2222A0,back:#eeeeff");    # Double quoted strings
 #$_[0]->StyleSetSpec(7,"fore:#2222A0,back:#eeeeff");    # Single quoted string
 $_[0]->StyleSetSpec(8,"fore:#ffbb55");                # Other inside tag
 $_[0]->StyleSetSpec(9,"fore:#bbbbbb");                # Comment
 $_[0]->StyleSetSpec(10,"fore:#cccc55,italic");            # Entities
 $_[0]->StyleSetSpec(11,"fore:#000000");                # XML style tag ends '/>'
 $_[0]->StyleSetSpec(12,"fore:#228822");                # XML identifier start '<?'
 $_[0]->StyleSetSpec(13,"fore:#339933");                # XML identifier end '?>'
 $_[0]->StyleSetSpec(14,"fore:#ffaa44");                # SCRIPT
 $_[0]->StyleSetSpec(15,"fore:#55bb55");                # ASP <% ... %>
 $_[0]->StyleSetSpec(16,"fore:#55bb55");                # ASP <% ... %>
 $_[0]->StyleSetSpec(17,"fore:#000000");                # CDATA
 $_[0]->StyleSetSpec(18,"fore:#000000");                # PHP
 $_[0]->StyleSetSpec(19,"fore:#2222A0");                # Unquoted values

 $_[0]->StyleSetSpec(21,"fore:#7F007F");                # SGML tags <! ... >
 $_[0]->StyleSetSpec(22,"fore:#800117");                # SGML command
 $_[0]->StyleSetSpec(23,"fore:#800117");                # SGML 1st param
 $_[0]->StyleSetSpec(24,"fore:#800117");                # SGML double string
 $_[0]->StyleSetSpec(25,"fore:#800117");                # SGML single string
 $_[0]->StyleSetSpec(26,"fore:#7F007F,bold");            # SGML error
 $_[0]->StyleSetSpec(27,"fore:#000000");                # SGML special (#xxxx type)
 $_[0]->StyleSetSpec(28,"fore:#000000");                # SGML entity
 $_[0]->StyleSetSpec(29,"fore:#000000");                # SGML comment
 $_[0]->StyleSetSpec(31,"fore:#000000");                # SGML block
 $_[0]->StyleSetSpec(34,"fore:#000000");                # Matched Operators
 $_[0]->StyleSetSpec(35,"fore:#000000");                # Matched Operators
                            # Embedded Javascript
 $_[0]->StyleSetSpec(40,"fore:#0000ff");                # JS Start - allows eol filled background to not start on same line as SCRIPT tag
 $_[0]->StyleSetSpec(41,"fore:#0000ff");
 $_[0]->StyleSetSpec(42,"fore:#0000ff");
 $_[0]->StyleSetSpec(43,"fore:#0000ff");
 $_[0]->StyleSetSpec(44,"fore:#0000ff");
 $_[0]->StyleSetSpec(45,"fore:#0000ff");
 $_[0]->StyleSetSpec(46,"fore:#0000ff");
 $_[0]->StyleSetSpec(47,"fore:#0000ff");
 $_[0]->StyleSetSpec(48,"fore:#0000ff");
 $_[0]->StyleSetSpec(49,"fore:#0000ff");
 $_[0]->StyleSetSpec(50,"fore:#0000ff");
 $_[0]->StyleSetSpec(51,"fore:#0000ff");
 $_[0]->StyleSetSpec(52,"fore:#0000ff");
                            # ASP Javascript
 $_[0]->StyleSetSpec(55,"fore:#000000");                # JS Start - allows eol filled background to not start on same line as SCRIPT tag
 $_[0]->StyleSetSpec(56,"fore:#000000");
 $_[0]->StyleSetSpec(57,"fore:#000000");
 $_[0]->StyleSetSpec(58,"fore:#000000");
 $_[0]->StyleSetSpec(59,"fore:#000000");
 $_[0]->StyleSetSpec(60,"fore:#000000");
 $_[0]->StyleSetSpec(61,"fore:#000000");
 $_[0]->StyleSetSpec(62,"fore:#000000");
 $_[0]->StyleSetSpec(63,"fore:#000000");
 $_[0]->StyleSetSpec(64,"fore:#000000");
 $_[0]->StyleSetSpec(65,"fore:#000000");
 $_[0]->StyleSetSpec(66,"fore:#000000");
 $_[0]->StyleSetSpec(67,"fore:#000000");  # JavaScript RegEx
 $_[0]->StyleSetSpec(68,"fore:#000000");
 $_[0]->StyleSetSpec(69,"fore:#000000");
 $_[0]->StyleSetSpec(70,"fore:#000000");
 $_[0]->StyleSetSpec(71,"fore:#000000");
 $_[0]->StyleSetSpec(72,"fore:#000000");
 $_[0]->StyleSetSpec(73,"fore:#000000");
 $_[0]->StyleSetSpec(74,"fore:#000000");
 $_[0]->StyleSetSpec(75,"fore:#000000");
 $_[0]->StyleSetSpec(76,"fore:#000000");
 $_[0]->StyleSetSpec(77,"fore:#000000");
 $_[0]->StyleSetSpec(78,"fore:#000000");
 $_[0]->StyleSetSpec(79,"fore:#000000");
 $_[0]->StyleSetSpec(80,"fore:#000000");
 $_[0]->StyleSetSpec(81,"fore:#000000");
 $_[0]->StyleSetSpec(82,"fore:#000000");
 $_[0]->StyleSetSpec(83,"fore:#000000");
 $_[0]->StyleSetSpec(84,"fore:#000000");
 $_[0]->StyleSetSpec(85,"fore:#000000");
 $_[0]->StyleSetSpec(86,"fore:#000000");
 $_[0]->StyleSetSpec(87,"fore:#000000");
 $_[0]->StyleSetSpec(88,"fore:#000000");
 $_[0]->StyleSetSpec(89,"fore:#000000");
 $_[0]->StyleSetSpec(90,"fore:#000000");
 $_[0]->StyleSetSpec(91,"fore:#000000");
 $_[0]->StyleSetSpec(92,"fore:#000000");
 $_[0]->StyleSetSpec(93,"fore:#000000");
 $_[0]->StyleSetSpec(94,"fore:#000000");
 $_[0]->StyleSetSpec(95,"fore:#000000");
 $_[0]->StyleSetSpec(96,"fore:#000000");
 $_[0]->StyleSetSpec(97,"fore:#000000");
 $_[0]->StyleSetSpec(98,"fore:#000000");
 $_[0]->StyleSetSpec(99,"fore:#000000");
 $_[0]->StyleSetSpec(100,"fore:#000000");
 $_[0]->StyleSetSpec(101,"fore:#000000");
 $_[0]->StyleSetSpec(102,"fore:#000000");
 $_[0]->StyleSetSpec(103,"fore:#000000");
 $_[0]->StyleSetSpec(104,"fore:#000000");
 $_[0]->StyleSetSpec(105,"fore:#000000");
 $_[0]->StyleSetSpec(106,"fore:#000000");
 $_[0]->StyleSetSpec(107,"fore:#000000");
 $_[0]->StyleSetSpec(108,"fore:#000000");
 $_[0]->StyleSetSpec(109,"fore:#000000");
 $_[0]->StyleSetSpec(110,"fore:#000000");
 $_[0]->StyleSetSpec(111,"fore:#000000");
 $_[0]->StyleSetSpec(112,"fore:#000000");
 $_[0]->StyleSetSpec(113,"fore:#000000");
 $_[0]->StyleSetSpec(114,"fore:#000000");
 $_[0]->StyleSetSpec(115,"fore:#000000");
 $_[0]->StyleSetSpec(116,"fore:#000000");
 $_[0]->StyleSetSpec(117,"fore:#000000");

 $_[0]->StyleSetSpec(118,"fore:#000033,back:#FFF8F8,eolfilled");    # PHP   Default
 $_[0]->StyleSetSpec(119,"fore:#007F00,back:#FFF8F8");            # Double quoted String
 $_[0]->StyleSetSpec(120,"fore:#009F00,back:#FFF8F8");            # Single quoted string
 $_[0]->StyleSetSpec(121,"fore:#7F007F,back:#FFF8F8,italics");        # Keyword
 $_[0]->StyleSetSpec(122,"fore:#CC9900,back:#FFF8F8");            # Number
 $_[0]->StyleSetSpec(123,"fore:#00007F,back:#FFF8F8,italics");        # Variable
 $_[0]->StyleSetSpec(124,"fore:#999999,back:#FFF8F8");            # Comment
 $_[0]->StyleSetSpec(125,"fore:#666666,back:#FFF8F8,italics");        # One line comment
 $_[0]->StyleSetSpec(126,"fore:#00007F,back:#FFF8F8,italics");        # PHP variable in double quoted string
 $_[0]->StyleSetSpec(127,"fore:#000000,back:#FFF8F8");            # PHP operator
}

1;