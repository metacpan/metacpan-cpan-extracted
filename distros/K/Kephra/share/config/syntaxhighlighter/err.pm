package syntaxhighlighter::err;
$VERSION = '0.01';

use Wx qw(wxSTC_LEX_ERRORLIST);

sub load{
 $_[0]->SetLexer( wxSTC_LEX_ERRORLIST );
 $_[0]->SetKeyWords(0,'');

 $_[0]->StyleSetSpec( 0,"fore:#000000");		# Default
 $_[0]->StyleSetSpec( 1,"fore:#ff0000");		# python Error
 $_[0]->StyleSetSpec( 2,"fore:#800080");		# gcc Error
 $_[0]->StyleSetSpec( 3,"fore:#808000");		# Microsoft Error
 $_[0]->StyleSetSpec( 4,"fore:#0000ff");		# command or return status
 $_[0]->StyleSetSpec( 5,"fore:#b06000");		# Borland error and warning messages
 $_[0]->StyleSetSpec( 6,"fore:#ff0000");		# perl error and warning messages
 $_[0]->StyleSetSpec( 7,"fore:#ff0000");		# .NET tracebacks
 $_[0]->StyleSetSpec( 8,"back:#ff0000");		# Lua error and warning messages
 $_[0]->StyleSetSpec( 9,"fore:#ff00ff");		# ctags
 $_[0]->StyleSetSpec(10,"fore:#007f00");		# diff changed !
 $_[0]->StyleSetSpec(11,"fore:#00007f");		# diff addition +
 $_[0]->StyleSetSpec(12,"fore:#007F7F");		# diff deletion -
 $_[0]->StyleSetSpec(13,"fore:#7f0000");		# diff message ---
 $_[0]->StyleSetSpec(14,"fore:#ff0000");		# PHP error
 $_[0]->StyleSetSpec(15,"fore:#ff0000");		# Essential Lahey Fortran 90 error
 $_[0]->StyleSetSpec(16,"fore:#ff0000");		# Intel Fortran Compiler error
 $_[0]->StyleSetSpec(17,"fore:#ff0000");		# Intel Fortran Compiler v8.0 error/warning
 $_[0]->StyleSetSpec(18,"fore:#ff0000");		# Absoft Pro Fortran 90/95 v8.2 error or warning
 $_[0]->StyleSetSpec(19,"fore:#ff0000");		# HTML Tidy
 $_[0]->StyleSetSpec(20,"fore:#ff0000");		# Java runtime stack trace
 $_[0]->StyleSetSpec(21,"fore:#000000");		# Text matched with find in files and message part of GCC errors
 $_[0]->StyleSetSpec(32,"fore:#B06000,small");	#
 $_[0]->StyleSetSpec(33,"fore:#000000,small");	# Ensures that spacing is not affected by line number styles

}

1;
