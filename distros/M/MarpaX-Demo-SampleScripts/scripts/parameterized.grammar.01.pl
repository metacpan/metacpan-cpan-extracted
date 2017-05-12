#!/usr/bin/env perl

use strict;
use diagnostics;
use open  qw(:std :utf8);    # Undeclared streams in UTF-8.

use Data::Dumper;
use Data::Section -setup;

use POSIX qw/EXIT_SUCCESS/;

use Marpa::R2;

# Author: Jean-Damien Durand.

# ------------------------------------------------

#
# Build grammar for "..." or '...'
#
our $parameterizedGrammar = ${__PACKAGE__->section_data('parameterizedGrammar')};
our $dquoteGrammar = $parameterizedGrammar;
our $squoteGrammar = $parameterizedGrammar;
$squoteGrammar =~ s/\$a/SQUOTE/g; $squoteGrammar =~ s/\$b/'/g;
$dquoteGrammar =~ s/\$a/DQUOTE/g; $dquoteGrammar =~ s/\$b/"/g;
our $DATA = ${__PACKAGE__->section_data('header')} . $squoteGrammar . $dquoteGrammar;
our $G = Marpa::R2::Scanless::G->new({source => \$DATA, bless_package => 'STRING'});

#
# Run tests
#

my($count) = 0;

foreach (eval ${__PACKAGE__->section_data('tests')}) {
	$count++;
    my ($state, $input) = @{$_};
    my $r = Marpa::R2::Scanless::R->new({grammar => $G});
    eval {$r->read(\$input);};
    my $valuep = $@ ? undef : $r->value;
    my $value = defined($valuep) ? ${$valuep} : undef;
    if (($state eq 'OK'   &&   defined($value)) ||
	($state eq 'Fail' && ! defined($value))) {
	print "TEST $count OK: Got '$state' for input: $input. Grammar value is " . ($value || 'undef') . ".\n";
    } else {
	print "TEST $count KO: Expected '$state' for input: $input. Grammar value is " . ($value || 'undef') . ".\n";
    }
}

exit EXIT_SUCCESS;

__DATA__

__[ header ]__
############################################################
#          NON-PARAMETERIZED PART OF THE GRAMMAR           #
############################################################
:default ::= action => ::first

:start ::= stringLiteralUnit

stringLiteralUnit ::= STRING_LITERAL_UNIT_DQUOTE
                    | STRING_LITERAL_UNIT_SQUOTE

BS         ~ '\'
H          ~ [a-fA-F0-9]
H_many     ~ H+
O          ~ [0-7]
ES         ~ BS ES_AFTERBS
ES_AFTERBS ~ ["'\?\\abfnrtv]
           | O
           | O O
           | O O O
           | 'x' H_many

__[ parameterizedGrammar ]__
############################################################
#            PARAMETERIZED PART OF THE GRAMMAR             #
############################################################
STRING_LITERAL_UNIT_$a       ~ LEX_$a STRING_LITERAL_INSIDE_$a_any LEX_$a
STRING_LITERAL_INSIDE_$a_any ~ STRING_LITERAL_INSIDE_$a*
STRING_LITERAL_INSIDE_$a     ~ [^$b\\]
STRING_LITERAL_INSIDE_$a     ~ ES

LEX_$a     ~ [$b]

__[ tests ]__
############################################################
#                        TESTS                             #
############################################################
(
['OK', q("X Z")],	# 1.
['OK', q('X Z')],	# 2.
['OK', q(" Z ")],	# 3.
['OK', q(' Z ')],	# 4.
['OK', q("")],		# 5. Double-quoted empty string.
['OK', q('')],		# 6. Single-quoted empty string.
['OK', q("'")],		# 7.
['OK', q("''")],	# 8.
['OK', q('"')],		# 9.
['OK', q('""')],	# 10.
['OK', q("\'")],	# 11.
['OK', q('\"')],	# 12.
['OK', q("\"")],	# 13.
['OK', q('\'')],	# 14.
['OK', q("A\rB")],	# 15.
['OK', q('A\rB')],	# 16.
['Fail', q(Δ Lady)],	# 17. UTF8.
['Fail', q( )],		# 18. Blank string.
['Fail', q()],		# 19. Empty string.
['Fail', q(")],		# 20. Unbalanced quotes.
['Fail', q(')],		# 21. Unbalanced quotes.
['Fail', q(A B)],	# 22. Unquoted string. Pre-preprocess by adding your own quotes, if possible.
)