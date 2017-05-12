package syntaxhighlighter::cpp;
$VERSION = '0.01';

sub load{
    use Wx qw(wxSTC_LEX_CPP wxSTC_H_TAG);
    my $cpp_keywords = 'and and_eq asm auto bitand bitor bool break \
case catch char class compl const const_cast continue \
default delete do double dynamic_cast else enum explicit export extern false float for \
friend goto if inline int long mutable namespace new not not_eq \
operator or or_eq private protected public \
register reinterpret_cast return short signed sizeof static static_cast struct switch \
template this throw true try typedef typeid typename union unsigned using \
virtual void volatile wchar_t while xor xor_eq';

# keywords2 is for highlighting user defined keywords or function calls or similar
# keywords3 is for doc comment keywords, highlighted in style 17
my $cpp_keywords3 = 'a addindex addtogroup anchor arg attention \
author b brief bug c class code date def defgroup deprecated dontinclude \
e em endcode endhtmlonly endif endlatexonly endlink endverbatim enum example exception \
f$ f[ f] file fn hideinitializer htmlinclude htmlonly \
if image include ingroup internal invariant interface latexonly li line link \
mainpage name namespace nosubgrouping note overload \
p page par param post pre ref relates remarks return retval \
sa section see showinitializer since skip skipline struct subsection \
test throw todo typedef union until \
var verbatim verbinclude version warning weakgroup $ @ \ & < > # { }';

     $_[0]->SetLexer(wxSTC_LEX_CPP);						# Set Lexers to use
     $_[0]->SetKeyWords(0,$cpp_keywords);
     $_[0]->SetKeyWords(2,$cpp_keywords3);
    
#    $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" );
    
     $_[0]->StyleSetSpec(0,"fore:#202020");					# White space
     $_[0]->StyleSetSpec(1,"fore:#aaaaaa");					# Comment
     $_[0]->StyleSetSpec(2,"fore:#bbbbbb)");				# Line Comment
     $_[0]->StyleSetSpec(3,"fore:#004000");					# Doc comment
     $_[0]->StyleSetSpec(4,"fore:#007f7f");					# Number
     $_[0]->StyleSetSpec(5,"fore:#000000,bold");			# Keywords
     $_[0]->StyleSetSpec(6,"fore:#555555,back:#ddeecc");	#  Doublequoted string
     $_[0]->StyleSetSpec(7,"fore:#555555,back:#eeeebb");	#  Single quoted string
     $_[0]->StyleSetSpec(8,"fore:#55ffff");					# UUIDs (only in IDL)
     $_[0]->StyleSetSpec(9,"fore:#228833");					# Preprocessor
     $_[0]->StyleSetSpec(10,"fore:#bb5577, bold");			# Operators
     $_[0]->StyleSetSpec(11,"fore:#334499");				# Identifiers (functions, etc.)
     $_[0]->StyleSetSpec(12,"fore:#228822");				# End of line where string is not closed
     $_[0]->StyleSetSpec(13,"fore:#339933");				# Verbatim strings for C#
     $_[0]->StyleSetSpec(14,"fore:#44aa44");				# Regular expressions for JavaScript
     $_[0]->StyleSetSpec(15,"fore:#55bb55");				# Doc Comment Line
     $_[0]->StyleSetSpec(17,"fore:#000000,back:#A0FFA0");	# Comment keyword
     $_[0]->StyleSetSpec(18,"fore:#000000,back:#F0E080");	# Comment keyword error
     # Braces are only matched in operator style     braces.cpp.style=10
     $_[0]->StyleSetSpec(32,"fore:#000000");				# Default
}

1;
