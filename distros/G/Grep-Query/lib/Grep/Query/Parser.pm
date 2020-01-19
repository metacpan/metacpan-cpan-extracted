package Grep::Query::Parser;

use strict;
use warnings;

our $VERSION = '1.009';
$VERSION = eval $VERSION;

use Carp;
our @CARP_NOT = qw(Grep::Query);

use Grep::Query::Parser::QOPS;
use Parse::RecDescent;
use IO::Scalar;
use Scalar::Util qw(blessed reftype looks_like_number);

my $PARSER;

sub parsequery
{
	my $query = shift;

	# we keep the actual parser as a singleton in case it's used multiple times
	#	
	if (!$PARSER)
	{
		local $/ = undef;
		my $grammar = <DATA>;
		local $Parse::RecDescent::skip = qr#(?ms:\s+|/\*.*?\*/)*#;
		$PARSER = Parse::RecDescent->new($grammar);
		die("Failed to parse query grammar") unless defined($PARSER);
	}

	# since diagnostics/errors during actual parsing go to STDERR, we use an in memory trap for that
	# so we can present it the way we want it
	#
	my $parsedQuery;
	my $fieldRefs = [];
	my $errholder = IO::Scalar->new();	
	{
		local *STDERR = $errholder;
		$parsedQuery = $PARSER->parsequery($query);
	}
	
	# if we didn't get a parse tree, the query syntax is probably wrong, so report that
	#
	if (!$parsedQuery)
	{
		# make sure we have some form of string, and make sure it doesn't end in a newline, since that
		# causes croak to drop the file/line information
		# 
		my $capturedError = "$errholder" || 'UNKNOWN ERROR';
		do {} while (chomp($capturedError));
		croak($capturedError) unless $parsedQuery;
	}

	# we need the parse tree in a somewhat simplified and predigested format for the actual ops
	#
	__preprocessParsedQuery($parsedQuery, $fieldRefs);

	# ensure that the query either uses field names for every test, or not at all
	#
	my $oldFieldRefCount = scalar(@$fieldRefs);
	if ($oldFieldRefCount)
	{
		@$fieldRefs = grep { defined($_) } @$fieldRefs;
		my $newFieldRefCount = scalar(@$fieldRefs);
		croak("Query must use field names for all matches or none") if ($newFieldRefCount && $newFieldRefCount != $oldFieldRefCount)
	}
	$fieldRefs = [ __uniq(@$fieldRefs) ];
	
	return ($parsedQuery, $fieldRefs);
}

# recursively dig down in the parse tree and simplify by removing items we don't really need,
# rename some to simpler forms, and predigest the tests
#
sub __preprocessParsedQuery
{
	my $parsedQuery = shift;
	my $fieldRefs = shift;
	
	my $r = reftype($parsedQuery);
	if ($r)
	{
		if ($r eq 'ARRAY')
		{
			foreach my $i (@$parsedQuery)
			{
				__preprocessParsedQuery($i, $fieldRefs);
			}
		}
		elsif ($r eq 'HASH')
		{
			delete($parsedQuery->{__RULE__});
			delete($parsedQuery->{lparen});
			
			foreach my $altk (grep(/^_alternation_/, keys(%$parsedQuery)))
			{
				my $alt = $parsedQuery->{$altk};
				delete($parsedQuery->{$altk});
				my $keep = 1;
				$keep = 0 if (ref($alt) eq 'ARRAY' && scalar(@$alt) == 0);
				$keep = 0 if (blessed($alt) && $alt->{rparen});
				if ($keep)
				{
					die("PRE-EXISTING '__ALT'?") if exists($parsedQuery->{__ALT});
					$parsedQuery->{__ALT} = $alt;
				}
			}
			
			foreach my $k (keys(%$parsedQuery))
			{
				# the actual tests needs to be predigested a bit - ensure the regexps are compiled, insert
				# subs that will do the actual comparisons etc.
				#
				if ($k eq 'field_op_value_test')
				{
					push(@$fieldRefs, $parsedQuery->{$k}->{field});
					my $op = $parsedQuery->{$k}->{op};
					if ($op eq 'true')
					{
						$parsedQuery->{$k}->{op} = eval "sub { 1 }";						
					}
					elsif ($op eq 'false')
					{
						$parsedQuery->{$k}->{op} = eval "sub { 0 }";						
					}
					elsif ($op =~ /^(?:regexp|=~)$/)
					{
						$parsedQuery->{$k}->{value} = __compileRx($parsedQuery->{$k}->{value});
						$parsedQuery->{$k}->{op} = __getAnonWithOp('=~');
					}
					elsif ($op =~ /^(?:eq|ne|[lg][te])$/)
					{
						$parsedQuery->{$k}->{op} = __getAnonWithOp($op);
					}
					elsif ($op =~ /^(?:[=!<>]=|<|>)$/)
					{
						my $possibleNumber = $parsedQuery->{$k}->{value};
						croak("Not a number for '$op': '$possibleNumber'") unless looks_like_number($possibleNumber);
						$parsedQuery->{$k}->{op} = __getAnonWithOp($op);
					}
					else
					{
						die("Unexpected op: '$op'");
					}
				}
				__preprocessParsedQuery($parsedQuery->{$k}, $fieldRefs);
			}
		}
	}

	return $parsedQuery;
}

# helpers
#
sub __uniq
{
	my %seen;
	grep( { !$seen{$_}++ } @_ );
}

sub __compileRx
{
	my $re = shift;
	
	my $cre;	
	if (! eval { $cre = qr/$re/ })
	{
		$@ =~ /^(.+)\sat\s/;
		croak("Bad regular expression:\n  $re\n  $1");
	}
	
	return($cre);
}

sub __getAnonWithOp
{
	my $op = shift;

	return eval "sub { defined(\$_[0]) ? \$_[0] $op \$_[1] : 0 }";
}

1;

__DATA__
## BEGIN GRAMMAR
##

<autotree: Grep::Query::Parser::QOPS>

parsequery:
		disj EOI { $item[1] }
	|	<error: Invalid query at offset $thisoffset: '$text'>

disj:
		conj ( or conj )(s?)

conj:
		unary ( and unary )(s?)

unary:
		not lparen disj ( rparen | <error> )
	|	lparen disj ( rparen | <error> )
	|	not field_op_value_test
	|	field_op_value_test

field_op_value_test:
		/
				(?:(?<field>[^.\s]+)\.)?(?<op>(?i)true|false)
			|	(?:(?<field>[^.\s]+)\.)?(?<op>(?i)regexp|=~|eq|ne|[lg][te]|[=!<>]=|<|>)\((?<value>[^)]*)\)								# allow paired '()' delimiters
			|	(?:(?<field>[^.\s]+)\.)?(?<op>(?i)regexp|=~|eq|ne|[lg][te]|[=!<>]=|<|>)\{(?<value>[^}]*)\}								# allow paired '{}' delimiters
			|	(?:(?<field>[^.\s]+)\.)?(?<op>(?i)regexp|=~|eq|ne|[lg][te]|[=!<>]=|<|>)\[(?<value>[^\]]*)\]								# allow paired '[]' delimiters
			|	(?:(?<field>[^.\s]+)\.)?(?<op>(?i)regexp|=~|eq|ne|[lg][te]|[=!<>]=|<|>)<(?<value>[^>]*)>								# allow paired '<>' delimiters
			|	(?:(?<field>[^.\s]+)\.)?(?<op>(?i)regexp|=~|eq|ne|[lg][te]|[=!<>]=|<|>)(?<delim>[^(){}[\]<>\s])(?<value>.*?)\g{delim}	# allow arbitrary delimiter
		/ix { bless( { field => $+{field}, op => lc($+{op}), value => $+{value} }, "Grep::Query::Parser::QOPS::$item[0]" ) }

or:
		/or|\|\|/i { 1 }

and:
		/and|&&/i { 1 }

not:
		/not|!/i { 1 }

lparen:
		'(' { 1 }
		
rparen:
		')' { 1 }
		
EOI:
		/^\Z/

## END GRAMMAR
##
