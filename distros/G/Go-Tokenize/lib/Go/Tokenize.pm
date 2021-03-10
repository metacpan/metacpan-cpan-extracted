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
our $VERSION = '0.01';

use Text::LineNumber;
use C::Tokenize qw!$comment_re!;

our $bt_string_re = qr!`[^`]*`!;
our $q_string_re = qr!"(\\"|[^"])*"!;
our $string_re = qr!(?:$bt_string_re|$q_string_re)!;

# https://golang.org/ref/spec#Keywords

our @keywords = qw!
break        default      func         interface    select
case         defer        go           map          struct
chan         else         goto         package      switch
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
!x;

my @types = (qw!comment string keyword operator!);

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
