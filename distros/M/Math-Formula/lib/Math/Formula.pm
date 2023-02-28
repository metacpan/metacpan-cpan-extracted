# Copyrights 2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
#!/usr/bin/env perl
#
# This code will be run incredabily fast, hence is tries to avoid copying etc.  It
# is not always optimally readible when your Perl skills are poor.

package Math::Formula;
use vars '$VERSION';
$VERSION = '0.13';


use warnings;
use strict;
use utf8;

use Log::Report 'math-formula';
use Scalar::Util qw/blessed/;

use Math::Formula::Token;
use Math::Formula::Type;


#--------------------------

sub new(%)
{	my ($class, $name, $expr, %self) = @_;
	$self{_name} = $name;
	$self{_expr} = $expr;
	(bless {}, $class)->init(\%self);
}

sub init($)
{	my ($self, $args) = @_;
	my $name = $self->{MSBE_name} = $args->{_name} or panic "every formular requires a name";

	my $expr    = $args->{_expr} or panic "every formular requires an expression";
	my $returns = $self->{MSBE_returns} = $args->{returns};

	if(ref $expr eq 'SCALAR')
	{	$expr = MF::STRING->new(undef, $$expr);
	}
	elsif(! ref $expr && $returns && $returns->isa('MF::STRING'))
	{	$expr = MF::STRING->new(undef, $expr);
	}

	$self->{MSBE_expr} = $expr;
	$self;
}

#--------------------------

sub name()       { $_[0]->{MSBE_name} }
sub expression() { $_[0]->{MSBE_expr} }
sub returns()    { $_[0]->{MSBE_returns} }


sub tree($)
{	my ($self, $expression) = @_;
	$self->{MSBE_ast} ||= $self->_build_ast($self->_tokenize($expression), 0);
}

# For testing only: to load a new expression without the need to create
# a new object.
sub _test($$)
{	my ($self, $expr) = @_;
	$self->{MSBE_expr} = $expr;
	delete $self->{MSBE_ast};
}

###
### PARSER
###

my $match_int   = MF::INTEGER->_match;
my $match_float = MF::FLOAT->_match;
my $match_name  = MF::NAME->_match;
my $match_date  = MF::DATE->_match;
my $match_time  = MF::TIME->_match;
my $match_dt    = MF::DATETIME->_match;
my $match_dur   = MF::DURATION->_match;

my $match_op    = join '|',
	qw{ // }, '[?*\/+\-#~.%]',
	qw{ =~ !~ <=> <= >= == != < > },  # order is important
	qw{ :(?![0-9][0-9]) (?<![0-9][0-9]): },
	( map "$_\\b", qw/ and or not xor exists like unlike cmp lt le eq ne ge gt/
	);

sub _tokenize($)
{	my ($self, $s) = @_;
	our @t = ();
	my $parens_open = 0;

	use re 'eval';  #XXX needed with newer than 5.16 perls?

	$s =~ m/ ^
	(?: \s*
	  (?| \# (?: \s [^\n\r]+ | $ ) \
		| ( true\b | false\b )	(?{ push @t, MF::BOOLEAN->new($+) })
		| ( \" (?: \\\" | [^"] )* \" )
							(?{ push @t, MF::STRING->new($+) })
		| ( \' (?: \\\' | [^'] )* \' )
							(?{ push @t, MF::STRING->new($+) })
		| ( $match_dur )	(?{ push @t, MF::DURATION->new($+) })
		| ( $match_op )		(?{ push @t, MF::OPERATOR->new($+) })
		| ( $match_name )	(?{ push @t, MF::NAME->new($+) })
		| ( $match_dt )		(?{ push @t, MF::DATETIME->new($+) })
		| ( $match_date )	(?{ push @t, MF::DATE->new($+) })
		| ( $match_time )	(?{ push @t, MF::TIME->new($+) })
		| ( $match_float )	(?{ push @t, MF::FLOAT->new($+) })
		| ( $match_int )	(?{ push @t, MF::INTEGER->new($+) })
		| \(				(?{ push @t, MF::PARENS->new('(', ++$parens_open) })
		| \)				(?{ push @t, MF::PARENS->new(')', $parens_open--) })
		| $
		| (.+)				(?{ error __x"expression '{name}', failed at '{where}'",
								name => $self->name, where => $+ })
	  )
	)+ \z /sxo;

	! $parens_open
		or error __x"expression '{name}', parenthesis do not match", name => $self->name;

	\@t;
}

sub _build_ast($$)
{	my ($self, $t, $prio) = @_;
	return shift @$t if @$t < 2;

  PROGRESS:
	while(my $first = shift @$t)
	{
#use Data::Dumper; $Data::Dumper::Indent = 0;
#warn "LOOP FIRST ", Dumper $first;
#warn "     MORE  ", Dumper $t;
		if($first->isa('MF::PARENS'))
		{	my $level = $first->level;

			my @nodes;
			while(my $node = shift @$t)
			{	last if $node->isa('MF::PARENS') && $node->level==$level;
				push @nodes, $node;
			}
			$first = $self->_build_ast(\@nodes, 0);
			redo PROGRESS;
		}

		if(ref $first eq 'MF::OPERATOR')  # unresolved operator
		{	my $op = $first->token;

			if($op eq '#' || $op eq '.')
			{	# Fragments and Methods are always infix, but their left-side arg
				# can be left-out.  As PREFIX, they would be RTL but we need LTR
				unshift @$t, $first;
				$first = MF::NAME->new('');
				redo PROGRESS;
			}

			my $next  = $self->_build_ast($t, $prio)
				or error __x"expression '{name}', monadic '{op}' not followed by anything useful",
				    name => $self->name, op => $op;

			$first = MF::PREFIX->new($op, $next);
			redo PROGRESS;
		}

		my $next = $t->[0]
			or return $first;   # end of expression

		ref $next eq 'MF::OPERATOR'
			or error __x"expression '{name}', expected infix operator but found '{type}'",
				name => $self->name, type => ref $next;

		my $op = $next->token;
		@$t or error __x"expression '{name}', infix operator '{op}' requires right-hand argument",
				name => $self->name, op => $op;

		my ($next_prio, $assoc) = MF::OPERATOR->find($op);

		return $first
			if $next_prio < $prio
			|| ($next_prio==$prio && $assoc==MF::OPERATOR::LTR);

		if($op eq ':')
		{	return $first;
		}

		shift @$t;    # apply the operator
		if($op eq '?')
		{	my $then  = $self->_build_ast($t, 0);
			my $colon = shift @$t;
			$colon && $colon->token eq ':'
				or error __x"expression '{name}', expected ':' in '?:', but got '{token}'",
					name => $self->name, token => ($next ? $colon->token : 'end-of-line');

			my $else = $self->_build_ast($t, $next_prio);
			$first = MF::TERNARY->new($op, $first, $then, $else);
			redo PROGRESS;
		}

		$first = MF::INFIX->new($op, $first, $self->_build_ast($t, $next_prio));
		redo PROGRESS;
	}
}

#--------------------------

sub evaluate($)
{	my ($self, $context, %args) = @_;
	my $expr   = $self->expression;

	my $result
	  = ref $expr eq 'CODE' ? $self->toType($expr->($context, $self, %args))
	  : ! blessed $expr     ? $self->tree($expr)->_compute($context, $self)
	  : $expr->isa('Math::Formula::Type') ? $expr
	  : panic;

	# For external evaluation calls, we must follow the request
	my $expect = $args{expect} || $self->returns;
	$result && $expect && ! $result->isa($expect) ? $result->cast($expect, $context) : $result;
}


my %_match = map { my $match = $_->_match; ( $_ => qr/^$match$/x ) }
	qw/MF::DATETIME MF::TIME MF::DATE MF::DURATION/;

sub toType($)
{	my ($self, $data) = @_;
	if(blessed $data)
	{	return $data if $data->isa('Math::Formula::Type');  # explicit type
		return MF::DATETIME->new(undef, $data) if $data->isa('DateTime');
		return MF::DURATION->new(undef, $data) if $data->isa('DateTime::Duration');
		return MF::FRAGMENT->new($data->name, $data) if $data->isa('Math::Formula::Context');
	}

	my $match = sub { my $type = shift; my $match = $type->_match; qr/^$match$/ };

	return 
		ref $data eq 'SCALAR'            ? MF::STRING->new($data)
	  : $data =~ /^[+-]?[0-9]+$/         ? MF::INTEGER->new(undef, $data)
	  : $data =~ /^[+-]?[0-9]+\./        ? MF::FLOAT->new(undef, $data)
	  : $data =~ /^(?:true|false)$/      ? MF::BOOLEAN->new($data)
	  : ref $data eq 'Regexp'            ? MF::REGEXP->new(undef, $data)
	  : $data =~ $_match{'MF::DATETIME'} ? MF::DATETIME->new($data)
	  : $data =~ $_match{'MF::TIME'}     ? MF::TIME->new($data)
	  : $data =~ $_match{'MF::DATE'}     ? MF::DATE->new($data)
	  : $data =~ $_match{'MF::DURATION'} ? MF::DURATION->new($data)
	  : $data =~ /^(['"]).*\1$/          ? MF::STRING->new($data)
	  : error __x"not an expression (string needs \\ ) for '{data}'", data => $data;
}

#--------------------------

1;
