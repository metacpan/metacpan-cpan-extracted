package syntaxhighlighter::eiffel;
$VERSION = '0.01';

sub load{

use Wx qw(wxSTC_LEX_EIFFEL wxSTC_H_TAG);

 $_[0]->SetLexer( wxSTC_LEX_EIFFEL );				# Set Lexers to use
 $_[0]->SetKeyWords(0,'alias all and any as bit boolean \
check class character clone create creation current \
debug deferred div do double \
else elseif end ensure equal expanded export external \
false feature forget from frozen general \
if implies indexing infix inherit inspect integer invariant is \
language like local loop mod name nochange none not \
obsolete old once or platform pointer prefix precursor \
real redefine rename require rescue result retry \
select separate string strip then true undefine unique until \
variant void when xor');

# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec( 0,"fore:#000000");				# Default
 $_[0]->StyleSetSpec( 1,"fore:#447744");				# Line Comment
 $_[0]->StyleSetSpec( 2,"fore:#007f7f");				# Number
 $_[0]->StyleSetSpec( 3,"fore:#000077,bold");			# Keyword
 $_[0]->StyleSetSpec( 4,"fore:#208820");				# String
 $_[0]->StyleSetSpec( 5,"fore:#20bb20");				# Character
 $_[0]->StyleSetSpec( 6,"fore:#882020");				# Operators
 $_[0]->StyleSetSpec( 7,"fore:#777720");				# Identifier
 $_[0]->StyleSetSpec( 8,"fore:#209920,eolfilled");		# End of line where string is not closed

}

1;