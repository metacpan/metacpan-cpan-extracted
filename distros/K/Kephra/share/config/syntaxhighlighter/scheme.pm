package syntaxhighlighter::scheme;
$VERSION = '0.01';

sub load{

use Wx qw(wxSTC_LEX_LISP wxSTC_H_TAG);

 $_[0]->SetLexer( wxSTC_LEX_LISP );
 $_[0]->SetKeyWords(0,'+ - * / = < > <= >= => \
abs acos and angle append apply asin assoc assoc assq assv atan \
begin boolean? \
caar cadr call-with-current-continuation call/cc \
call-with-input-file call-with-output-file call-with-values \
car cdr \
caar cadr cdar cddr \
caaar caadr cadar caddr cdaar cdadr cddar cdddr \
caaaar caaadr caadar caaddr cadaar cadadr caddar cadddr \
cdaaar cdaadr cdadar cdaddr cddaar cddadr cdddar cddddr \
case ceiling char->integer \
char-alphabetic? char-ci<=? char-ci<? char-ci=? char-ci>=? char-ci>? \
char-downcase char-lower-case? char-numeric? char-ready? \
char-upcase char-upper-case? char-whitespace? \
char<=? char<? char=? char>=? char>? char? \
close-input-port close-output-port complex? cond cons cos \
current-input-port current-output-port \
define define-syntax delay denominator display do dynamic-wind \
else eof-object? eq? equal? eqv? eval even? exact->inexact exact? \
exp expt \
floor for-each force \
gcd \
if imag-part inexact->exact inexact? input-port? integer->char integer? interaction-environment \
lambda lcm length let let* let-syntax letrec letrec-syntax \
list list->string list->vector list-ref list-tail list? load log \
magnitude make-polar make-rectangular make-string make-vector \
map max member memq memv min modulo \
negative? newline not null-environment null? number->string number? numerator \
odd? open-input-file open-output-file or output-port? \
pair? peek-char input-port? output-port? positive? procedure? \
quasiquote quote quotient \
rational? rationalize read read-char real-part real? remainder reverse round \
scheme-report-environment set! set-car! set-cdr! sin sqrt string \
string->list string->number string->symbol string-append \
string-ci<=? string-ci<? string-ci=? string-ci>=? string-ci>? \
string-copy string-fill! string-length string-ref string-set! \
string<=? string<? string=? string>=? string>? string? \
substring symbol->string symbol? syntax-rules \
transcript-off transcript-on truncate \
unquote unquote-splicing \
values vector vector->list vector-fill! vector-length vector-ref vector-set! vector? \
with-input-from-file with-output-to-file write write-char \
zero?');

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