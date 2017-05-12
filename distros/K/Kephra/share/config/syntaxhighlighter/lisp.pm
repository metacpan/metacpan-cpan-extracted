package syntaxhighlighter::lisp;
$VERSION = '0.01';

sub load{

    use Wx qw(wxSTC_LEX_LISP wxSTC_H_TAG);

    $_[0]->SetLexer( wxSTC_LEX_LISP );					# Set Lexers to use
    $_[0]->SetKeyWords(0,'not defun + - * / = < > <= >= princ
eval apply funcall quote identity function complement backquote lambda set setq setf
defun defmacro gensym make symbol intern symbol name symbol value symbol plist get
getf putprop remprop hash make array aref car cdr caar cadr cdar cddr caaar caadr cadar
caddr cdaar cdadr cddar cdddr caaaar caaadr caadar caaddr cadaar cadadr caddar cadddr
cdaaar cdaadr cdadar cdaddr cddaar cddadr cdddar cddddr cons list append reverse last nth
nthcdr member assoc subst sublis nsubst  nsublis remove length list length
mapc mapcar mapl maplist mapcan mapcon rplaca rplacd nconc delete atom symbolp numberp
boundp null listp consp minusp zerop plusp evenp oddp eq eql equal cond case and or let l if prog
prog1 prog2 progn go return do dolist dotimes catch throw error cerror break
continue errset baktrace evalhook truncate float rem min max abs sin cos tan expt exp sqrt
random logand logior logxor lognot bignums logeqv lognand lognor
logorc2 logtest logbitp logcount integer length nil');

# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec(32,"fore:#000000");				# Default
 $_[0]->StyleSetSpec( 0,"fore:#000000");				# White space
 $_[0]->StyleSetSpec( 1,"fore:#447744");				# Line Comment
 $_[0]->StyleSetSpec( 2,"fore:#007f7f");				# Number
 $_[0]->StyleSetSpec( 3,"fore:#000077,bold");			# Keyword

 $_[0]->StyleSetSpec( 6,"fore:#882020");				# String

 $_[0]->StyleSetSpec( 8,"fore:#209999,eolfilled");		# End of line where string is not closed
 $_[0]->StyleSetSpec( 9,"fore:#7F0000");				# Identifiers
 $_[0]->StyleSetSpec(10,"fore:#eecc99,bold");			# Operators

 $_[0]->StyleSetSpec(34,"fore:#0000FF,bold");			# Matched Operators
 $_[0]->StyleSetSpec(35,"fore:#FF0000,bold");			#
}

1;