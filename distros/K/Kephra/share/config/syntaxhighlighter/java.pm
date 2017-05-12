package syntaxhighlighter::java;
$VERSION = '0.01';

sub load{
use Wx qw(wxSTC_LEX_CPP wxSTC_H_TAG);
    my $java_keywords = 'abstract assert boolean break byte case catch char class \
const continue default do double else extends final finally float for future \
generic goto if implements import inner instanceof int interface long \
native new null outer package private protected public rest \
return short static super switch synchronized this throw throws \
transient try var void volatile while';

 $_[0]->SetLexer(wxSTC_LEX_CPP);						# Set Lexers to use
 $_[0]->SetKeyWords(0,$java_keywords);
# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" );

 $_[0]->StyleSetSpec(0,"fore:#202020");					# White space
 $_[0]->StyleSetSpec(1,"fore:#bbbbbb");					# Comment
 $_[0]->StyleSetSpec(2,"fore:#cccccc)");					# Line Comment
 $_[0]->StyleSetSpec(3,"fore:#004000");					# Doc comment
 $_[0]->StyleSetSpec(4,"fore:#007f7f");					# Number
 $_[0]->StyleSetSpec(5,"fore:#7788bb,bold");				# Keywords
 $_[0]->StyleSetSpec(6,"fore:#555555,back:#ddeecc");			#  Doublequoted string
 $_[0]->StyleSetSpec(7,"fore:#555555,back:#eeeebb");			#  Single quoted string
 $_[0]->StyleSetSpec(8,"fore:#55ffff");					# UUIDs (only in IDL)
 $_[0]->StyleSetSpec(9,"fore:#228833");					# Preprocessor
 $_[0]->StyleSetSpec(10,"fore:#bb7799,bold");				# Operators
 $_[0]->StyleSetSpec(11,"fore:#778899");					# Identifiers (functions, etc.)
 $_[0]->StyleSetSpec(12,"fore:#228822");					# End of line where string is not closed
 $_[0]->StyleSetSpec(13,"fore:#339933");					# Verbatim strings for C#
 $_[0]->StyleSetSpec(14,"fore:#44aa44");					# Regular expressions for JavaScript
 $_[0]->StyleSetSpec(15,"fore:#55bb55");					# Doc Comment Line
 $_[0]->StyleSetSpec(17,"fore:#000000,back:#A0FFA0");			# Comment keyword
 $_[0]->StyleSetSpec(18,"fore:#000000,back:#F0E080");          # Comment keyword error
 # Braces are only matched in operator style     braces.cpp.style=10
 $_[0]->StyleSetSpec(32,"fore:#000000");					# Default
}

1;
