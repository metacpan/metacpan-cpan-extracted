package syntaxhighlighter::batch;
$VERSION = '0.01';

use Wx qw(wxSTC_LEX_BATCH);

sub load{
 $_[0]->SetLexer( wxSTC_LEX_BATCH );
 $_[0]->SetKeyWords(0,'rem set if exist errorlevel for in do \
break call chcp cd chdir choice cls country ctty date del erase dir echo \
exit goto loadfix loadhigh mkdir md move path pause prompt rename ren \
rmdir rd shift time type ver verify vol \
com con lpt nul \
color copy defined else not start');

 $_[0]->StyleSetSpec( 0,"fore:#000000");		# Default
 $_[0]->StyleSetSpec( 1,"fore:#aaaaaa");		# Comment (rem or ::)
 $_[0]->StyleSetSpec( 2,"fore:#000077,bold");	# Keywords
 $_[0]->StyleSetSpec( 3,"fore:#ee7b00");		# Label (line beginning with ':')
 $_[0]->StyleSetSpec( 4,"fore:#7F007F");		# Hide command character ('@')
 $_[0]->StyleSetSpec( 5,"fore:#007090,bold");	# External commands
 $_[0]->StyleSetSpec( 6,"fore:#800080");		# Variable: %%x (x is almost whatever, except space and %), %n (n in [0-9]), %EnvironmentVar%
 $_[0]->StyleSetSpec( 7,"fore:#000000");		# Operator: * ? < > |

}

1;
