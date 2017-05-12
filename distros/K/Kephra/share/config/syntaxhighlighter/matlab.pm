package syntaxhighlighter::matlab;
$VERSION = '0.01';

use Wx qw(wxSTC_LEX_MATLAB);

sub load {
 $_[0]->SetLexer( wxSTC_LEX_MATLAB );
 $_[0]->SetKeyWords(0,'break case catch continue else elseif end for function \
global if otherwise persistent return switch try while');

 $_[0]->StyleSetSpec( 0,"fore:#000000");				# White space
 $_[0]->StyleSetSpec( 1,"fore:#aaaaaa");				# Comment
 $_[0]->StyleSetSpec( 2,"fore:#b06000,bold");			# Command
 $_[0]->StyleSetSpec( 3,"fore:#007f7f");				# Number
 $_[0]->StyleSetSpec( 4,"fore:#000077,bold");			# Keyword
 $_[0]->StyleSetSpec( 5,"fore:#f36600,back:#fffcff");	# String (5=single quoted, 8=double quoted)
 $_[0]->StyleSetSpec( 6,"fore:#800080");				# Operator
 $_[0]->StyleSetSpec( 7,"fore:#3355bb");				# Identifier
 $_[0]->StyleSetSpec( 8,"fore:#ee7b00,back:#fff8f8");	
}

1;
