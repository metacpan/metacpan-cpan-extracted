package Go::Tokenize;
use warnings;
use strict;
use Carp;
use utf8;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/tokenize/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.02';

use Text::LineNumber;
use C::Tokenize qw!$comment_re!;

our $bt_string_re = qr!`[^`]*`!;
our $q_string_re = qr!"(\\"|[^"])*"!;
our $string_re = qr!(?:$bt_string_re|$q_string_re)!;

# https://golang.org/ref/spec#Keywords

# PAUSE thinks this is package switch without the newline
our @keywords = qw!
break        default      func         interface    select
case         defer        go           map          struct
chan         else         goto         package
switch
const        fallthrough  if           range        type
continue     for          import       return       var
!;

# https://golang.org/ref/spec#Operators_and_punctuation

our $operator_re;
{
# Perl makes an error message "Possible attempt to separate words with
# commas at lib/Go/Tokenize.pm line 40." See
# https://stackoverflow.com/questions/19573977/
no warnings 'qw';
my @operators = (qw@
+    &     +=    &=     &&    ==    !=    (    )
-    |     -=    |=     ||    <     <=    [    ]
*    ^     *=    ^=     <-    >     >=    {    }
/    <<    /=    <<=    ++    =     :=    ,    ;
%    >>    %=    >>=    --    !     ...   .    :
     &^          &^=
@);
$operator_re = make_re (@operators);
}

our $keyword_re = make_re (@keywords);

our $integer_re = qr!
    0
|
    [1-9][0-9_]*
|
    0[bB][01_]+
|
    0[oO]?[0-7_]+
|
    0[xX][0-9a-fA-F_]+
!x;

our $numeric_re = qr!
    u?int(?:8|16|32|64)?
|
    float(?:32|64)
|
    complex(?:64|128)
|
    byte
|
    rune
|
    uintptr
!x;

# https://perldoc.perl.org/perlre
# https://perldoc.perl.org/perlunicode
# https://golang.org/ref/spec#unicode_letter
# PropertyValueAliases.txt

# https://golang.org/ref/spec#Letters_and_digits

my $letter = qr!\p{L}|_!;

our $identifier_re = qr!$letter(?:$letter|\p{Nd})*!;

our $rune_re = qr!
    '(?:
	.
    |
	\\u(?:[0-9a-fA-F]{4})
    |
	\\U(?:[0-9a-fA-F]{8})
    |
	\\o(?:[0-7]{3})
    |
	\\x(?:[0-9a-fA-F]{2})
    |
	# https://golang.org/ref/spec#escaped_char
	\\[abfnrtv\\'"]
    )'!x;

our $whitespace_re = qr!\x20|\x09|\x0D|\x0A!;

our $go_re = qr!
    # Comment must go before everything else.
    (?<comment>$comment_re)
|
    # String must go before everything except comments.
    (?<string>$string_re)
|
    (?<keyword>$keyword_re)
|
    (?<operator>$operator_re)
|
    (?<integer>$integer_re)
|
    (?<numeric>$numeric_re)
|
    (?<identifier>$identifier_re)
|
    (?<whitespace>$whitespace_re)
!x;

our @types = (qw!
    comment
    identifier
    integer
    keyword
    numeric
    operator
    rune
    string
    whitespace
!);

sub tokenize
{
    my ($go) = @_;
    my $tln = Text::LineNumber->new ($go);
    my @tokens;
    while ($go =~ /($go_re)/g) {
	my %token;
	$token{contents} = $1;
	$token{end} = pos ($go);
	$token{start} = $token{end} - length ($token{contents}) + 1;
	for my $type (@types) {
	    if ($+{$type}) {
		$token{type} = $type;
		last;
	    }
	}
	$token{line} = $tln->off2lnr ($token{start});
	push @tokens, \%token;
    }
    return \@tokens;
}

sub make_re
{
    my @sorted = sort {length ($b) <=> length ($a) || $a cmp $b} @_;
    my @quoted = map {quotemeta ($_)} @sorted;
    my $re = join '|', @quoted;
    return $re;
}

1;
