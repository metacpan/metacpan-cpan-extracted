package syntaxhighlighter::css;
$VERSION = '0.01';

sub load{

use Wx qw(wxSTC_LEX_CSS wxSTC_H_TAG);

 $_[0]->SetLexer( wxSTC_LEX_CSS );         # Set Lexers to use
 $_[0]->SetKeyWords(0,' \
border border-bottom border-bottom-color border-bottom-style border-bottom-width \
border-color border-left border-left-color border-left-style border-left-width \
border-right border-right-color border-right-style border-right-width border-style \
border-top border-top-color border-top-style border-top-width border-width \
clear cursor display float position visibility \
height line-height max-height max-width min-height min-width width \
font font-family font-size font-size-adjust font-stretch font-style font-variant \
font-weight \
content counter-increment counter-reset quotes \
list-style list-style-image list-style-position list-style-type \
margin margin-bottom margin-left margin-right margin-top \
outline outline-color outline-style outline-width \
padding padding-bottom padding-left padding-right padding-top \
bottom clip left overflow right top vertical-align z-index \
border-collapse border-spacing caption-side empty-cells table-layout \
color direction letter-spacing text-align text-decoration text-indent \
text-transform unicode-bidi white-space word-spacing orphans marks page \
page-break-after page-break-before page-break-inside size widows \
azimuth cue cue-after cue-before elevation pause pause-after pause-before pitch \
pitch-range play-during richness speak speak-header speak-numeral speak-punctuation \
speech-rate stress voice-family volume ');

# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec( 0,"fore:#000000");                        # Default
 $_[0]->StyleSetSpec( 1,"fore:#2020ff");                        # HTML tag
 $_[0]->StyleSetSpec( 2,"fore:#3350ff");                        # Class
 $_[0]->StyleSetSpec( 3,"fore:#202020");                        # Pseudo class
 $_[0]->StyleSetSpec( 4,"fore:#202020");                        # Unknown Pseudo class
 $_[0]->StyleSetSpec( 5,"fore:#208820");                        # Operator
 $_[0]->StyleSetSpec( 6,"fore:#882020");                        # Identifier
 $_[0]->StyleSetSpec( 7,"fore:#202020");                        # Unknown Identifier
 $_[0]->StyleSetSpec( 8,"fore:#209999");                        # Value
 $_[0]->StyleSetSpec( 9,"fore:#888820");                        # Comment
 $_[0]->StyleSetSpec(10,"fore:#202020");                        # ID
 $_[0]->StyleSetSpec(11,"fore:#202020");                        # Important
 $_[0]->StyleSetSpec(12,"fore:#202020");                        # Directive (@)
 $_[0]->StyleSetSpec(13,"fore:#202020");                        # Double quoted strings
 $_[0]->StyleSetSpec(14,"fore:#202020");                        # Single quoted strings
}

1;
