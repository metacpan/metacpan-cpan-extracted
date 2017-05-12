package syntaxhighlighter::pascal;
$VERSION = '0.01';

sub load {
use Wx qw(wxSTC_LEX_PASCAL wxSTC_H_TAG);

 $_[0]->SetLexer( wxSTC_LEX_PASCAL );         # Set Lexers to use
 $_[0]->SetKeyWords(0,'and array asm begin case cdecl class const constructor default \
destructor div do downto else end end. except exit exports external far file \
finalization finally for function goto if implementation in index inherited \
initialization inline interface label library message mod near nil not \
object of on or out overload override packed pascal private procedure program \
property protected public published raise read record register repeat resourcestring \
safecall set shl shr stdcall stored string then threadvar to try type unit \
until uses var virtual while with write xor');                     # Add new keyword.
# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec(0,"fore:#000000");				# White space
 $_[0]->StyleSetSpec(1,"fore:#aaaaaa)");				# Comment
 $_[0]->StyleSetSpec(2,"fore:#ff0000");				# Line Comment
 $_[0]->StyleSetSpec(3,"fore:#004000");				# Doc Comment
 $_[0]->StyleSetSpec(4,"fore:#007f7f");				# Number
 $_[0]->StyleSetSpec(5,"fore:#000077,bold");			# Keywords
 $_[0]->StyleSetSpec(6,"fore:#ee7b00,back:#fff8f8,italics");# Doublequoted string
 $_[0]->StyleSetSpec(7,"fore:#f36600,back:#f8fff8,italics");# Single quoted string
 $_[0]->StyleSetSpec(8,"fore:#007F7F");				# Symbols 
 $_[0]->StyleSetSpec(9,"fore:#7F7F00");				# Preprocessor
 $_[0]->StyleSetSpec(10,"fore:#aa9900,bold");			# Operators

 $_[0]->StyleSetSpec(14,"fore:#ffffff,back:#000000");		# Inline Asm

 $_[0]->StyleSetSpec(32,"fore:#800000");				# Default/Identifiers
 $_[0]->StyleSetSpec(34,"fore:#0000FF");				# Brace highlight
 $_[0]->StyleSetSpec(35,"fore:#FF0000");				# Brace incomplete highlight
}

1;