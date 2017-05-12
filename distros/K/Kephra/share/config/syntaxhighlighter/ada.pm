package syntaxhighlighter::ada;
$VERSION = '0.01';

sub load{

use Wx qw(wxSTC_LEX_ADA wxSTC_H_TAG);

 $_[0]->SetLexer( wxSTC_LEX_ADA );
 $_[0]->SetKeyWords(0,'abort abstract accept access aliased all array at begin body \
case constant declare delay delta digits do else elsif end entry exception exit for \
function generic goto if in is limited loop new null of others out package pragma \
private procedure protected raise range record renames requeue return reverse \
select separate subtype tagged task terminate then type until use when while with \
abs and mod not or rem xor');
# Keywords for operators in the last line

# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec( 0,"fore:#000000");				# Default
 $_[0]->StyleSetSpec( 1,"fore:#447744,bold");			# Keyword
 $_[0]->StyleSetSpec( 2,"fore:#3350ff");				# Identifiers
 $_[0]->StyleSetSpec( 3,"fore:#007f7f");				# Number
 $_[0]->StyleSetSpec( 4,"fore:#7f2020");				# Operators (delimiters)
 $_[0]->StyleSetSpec( 5,"fore:#208820");				# Character
 $_[0]->StyleSetSpec( 6,"fore:#882020,eolfilled");		# End of line where character is not closed
 $_[0]->StyleSetSpec( 7,"fore:#207474");				# String
 $_[0]->StyleSetSpec( 8,"fore:#209999,eolfilled");		# End of line where string is not closed
 $_[0]->StyleSetSpec( 9,"fore:#7F0000");				# Label
 $_[0]->StyleSetSpec(10,"fore:#aaaaaa");				# Comment
 $_[0]->StyleSetSpec(11,"fore:#FF0000");				# Illegal token
}

1;
