#!/usr/bin/perl -w

# Term::ExprUI
# Scott Bronson
# 28 Jan 2003

package Term::ExprUI;

#
# This package overrides Term::GDBUI to add an expression parser.
# Term::GDBUI gets the command line first and, if it is valid, it
# uses it.  Else, the command is passed to a simple recursive
# descent parser for interpretation as an expression.
#
# If the user is typing an expression, we try to allow him to complete
# function calls and variable names.
#
# TODO get rid of the command-line interface.  It's too confusing
# to have both.  Make it 100% expression.
#

use strict;
use Term::GDBUI;

use vars qw(@ISA);
@ISA = qw(Term::GDBUI);

use vars qw($VERSION);
$VERSION = '0.81';


use POSIX qw(strtod);

=head1 NOTE

Term::ExprUI prevents the default method from being called.  This
is because, after the function lookup fails, instead of passing it
to the default method, it passes it to the expression evaluator.
This is not a bug.  It will go away in the future since the command
line will be removed entirely -- you will only have the expression
interface.

=head1 METHODS

=over 4

=item new

The new method takes all of the parameters that may be passed
to L<Term::GDBUI::new>, plus some or all of the following functions.
They allow you to maintain the symbol table in your application
in whatever format you desire.

=over 4

=item add_var NAME VAL

Called when the assignment operator is used.  Passes the name of the
variable to create and the value it should have.  Return value is
ignored.

=item get_var NAME

Called whenever a variable is used in the right-hand side of an
expression.  Takes the name of the variable, returns its value.

=item get_all_vars

Returns an arrayref of the names of all variables currently defined.
Used for command-line completion.  Takes no arguments.

=item get_function_cset

Returns a command set listing all known functions.  Used for both
displaying help and generating completions.  See Term::GDBUI for the
definition of a command set.  Take no arguments.

=item call_function NAME ARGS...

Calls a function.  Passed the name of the function to call, then
all the function's arguments.  Returns the function result.

=cut

sub new
{
	my $type = shift;

	my $self = new Term::GDBUI(
		blank_repeats_cmds => 1,
		keep_quotes => 1,
		token_chars => '=,[]()+-*/^',

		add_var => sub { },
		get_var => sub { undef },
		get_all_vars => sub { [] },
		get_function_cset => sub { {} },
		call_function =>  sub { },

		@_
		);

	bless $self, $type;
	return $self;
}


# Override completion function to add function and variable names.

sub complete
{
	my $self = shift;
	my $cmpl = shift;

	my $super = $self->SUPER::complete($cmpl);

	# This is kind of hackish (as if the rest of this file wasn't)
	# Readline has no concept of token_chars, so it requires all
	# completions to be surrounded by whitespace.  Therefore, if
	# the string to complete has token chars in it (i.e. '1+result')
	# we just tack the '1+' onto the front of all possible completions.
	# (I think readline has a better way of doing this, but I don't
	# know what it is)
	my $preop = '';
	my $tchrs = $self->{token_chars};
	if($cmpl->{str} =~ /^(.*[\Q$tchrs\E])[^\Q$tchrs\E]*$/) {
		$preop = $1;
	}

	if(!$cmpl->{cmd} || $cmpl->{argno} < 0) {
		$super ||= [];
		my @retval = ();
		# add known variables
		push @retval, @{$self->{get_all_vars}->()};
		# add known functions
		push @retval, keys %{$self->{get_function_cset}->()};

		push @$super, map { $preop.$_ } @retval;
	}

	return $super;
}


# override help call and help args to add our functions to the help topics.
# we just modify the cset stored in the params -- that way, it takes effect
# only for the duration of this call.  we don't modify the global commands.

sub help_call
{
	my $self = shift;
	my $cats = shift;
	my $parms = shift;

	my $cset = $parms->{cset};
	my $toadd = $self->{get_function_cset}->();

	for(keys %$cset) {
		$toadd->{$_} = $cset->{$_};
	}

	$parms->{cset} = $toadd;
	return $self->SUPER::help_call($cats, $parms, @_);
}


sub help_args
{
	my $self = shift;
	my $cats = shift;
	my $cmpl = shift;

	my $cset = $cmpl->{cset};
	my $toadd = $self->{get_function_cset}->();

	for(keys %$cset) {
		$toadd->{$_} = $cset->{$_};
	}

	$cmpl->{cset} = $toadd;
	return $self->SUPER::help_args($cats, $cmpl, @_);
}


# Can't use LLg or Parse::RecDescent because they both use their own
# lexers (right?).  We need to operate on tokens, not strings.  If
# anybody figures a way around this, I'd love to hear it!  I'm not
# real happy about having an entire recursived descent parser coded
# in this program...

sub parse
{
	my $self = shift;
	my $tok = shift;
	my $cur = shift;

	#
	# utility functions
	#

	local *bail = sub {
		# this routine is insane...  should be rewritten.
		my $msg = shift;
		my $toks = $self->{parser}->join_line($tok);
		my $incur = $#$tok;
		$incur = $cur if $cur < $incur;
		my @consumed_toks = $incur ? @$tok[0..$incur] : ();
		my $consumed_line = $self->{parser}->join_line(\@consumed_toks);
		my $spc = " " x length($consumed_line);
		# back up to the beginning of the last token
		$spc = substr($spc, length($tok->[$#$tok])) unless $incur == 0;
		defined $spc or print "UNDEFINED SPC2!\n";
		my $trim = length($toks)-40;
		if($trim > 0) {
			$toks = substr($toks, $trim);
			$spc = substr($spc, $trim);
		}
		#defined $toks or print "UNDEFINED TOKS!\n";
		#defined $spc or print "UNDEFINED SPC!\n";
		#print "tokens ('" . join(', ', @$tok) . "') cur=$cur incur=$incur\n";
		#print "consumed: ('" . join(', ', @consumed_toks) . "') incur=$incur\n";
		die "$toks\n" . "$spc^ $msg!\n";
	};

	local *next_token = sub {
		$cur += 1;
		$_ = $tok->[$cur];	# undef if we run out of tokens
	};

	# bails if it can't fetch the next token
	local *need_next_token = sub {
		next_token();
		bail("incomplete expression") unless defined $_;
	};

	local *prev_token = sub {
		$cur -= 1;
		$cur = 0 if $cur < 0;
		$_ = $tok->[$cur];
	};

	# uses the POSIX module so we support all number formats supported by Perl.
	local *isnum = sub {
		my $str = shift;
		my $save = $_;
		return undef unless defined($str) && length($str)>0;
		$! = 0;
		my ($num, $n_unparsed) = POSIX::strtod($str);
		$_ = $save;
		if(($str eq '') || ($n_unparsed != 0) || $!) {
			# print "Non-numeric input $str" . ($! ? ": $!\n" : "\n");
			return undef;
		}
		return 1;
	};

	# ensures argument is numeric
	local *numeric = sub {
		my $op = shift; $op = $_ unless defined $op;
		my $cc = shift; $cc = $cur unless defined $cc;
		unless(isnum($op)) {
			$cur = $cc;
			bail("need a number");
		}
	};


	#
	# grammar (assg is the entrypoint):
	#
	# assg ::= id=expr | expr
	# expr ::= term {+|- term}
	# term ::= fact {*|/ fact}
	# fact ::= valu {^ valu}
	# valu ::= id.(args) | id | (exp) | [args] | string | number
	# args ::= expr {, expr}
	#

	local *id = sub {
		my $more = shift || '';	# other legal chars
		if(/^[A-Za-z_][0-9A-Za-z_\Q$more\E]*$/) {
			next_token();
			return $tok->[$cur-1];
		}
		return undef;
	};

	local *assg = sub {
		my $id = id();
		if(defined $id) {
			if(defined($_) && $_ eq '=') {
				need_next_token();
			} else {
				# not an assignment.  back up and 
				# parse as an expression.
				prev_token();
				$id = undef;
			}
		}
		my $ex = expr();
		unless($cur == @$tok) {
			prev_token();
			bail("garbage after this token");
		}
		return ($id, $ex);
	};

	local *expr = sub {
		my $left = term();
		while(defined($_) && ($_ eq '+' || $_ eq '-')) {
			my $op = $_;
			need_next_token();
			my $right = term();
			numeric($left,$cur-2) && numeric($right);
			$left = ($op eq '+' ? $left + $right : $left - $right);
		}

		return $left;
	};

	local *term = sub {
		my $left = fact();
		while(defined($_) && ($_ eq '*' || $_ eq '/')) {
			my $op = $_;
			need_next_token();
			my $right = fact();
			numeric($left,$cur-2) && numeric($right);
			$left = ($op eq '*' ? $left * $right : $left / $right);
		}

		return $left;
	};

	local *fact = sub {
		my $left = valu();
		while(defined($_) && $_ eq '^') {
			my $op = $_;
			need_next_token();
			my $right = valu();
			numeric($left,$cur-2) && numeric($right);
			$left = $left ** $right;
		}

		return $left;
	};

	local *valu = sub {
		my $id = id('.');
		if(defined $id) {
			if(defined($_) && $_ eq '(') {		# function call
				need_next_token();
				my $args = args();
				defined($_) && $_ eq ')' or bail("expecting ')' after this token");
				next_token();
				return $self->{call_function}->($id, @$args);
			}
			my $val = $self->{get_var}->($id);
			return $val if defined $val;
			prev_token();
			bail("unknown command or variable");
		}

		if($_ eq '(') {			# parenthesized expression
			need_next_token();
			my $val = expr();
			$_ eq ')' or bail("expecting ')' after this token");
			next_token();
			return $val;
		}

		if($_ eq '[') {			# array
			need_next_token();
			my $val = args();
			$_ eq ']' or bail("expecting ']' after this token");
			next_token();
			return $val;
		}

		# string
		if(/^(["'])(.*)\1$/) {
			my $str = $2;
			next_token();
			return $str;
		}

		# decimal number
		if(isnum($_)) {
			next_token();
			return $tok->[$cur-1];
		}
		
		# binary / octal / hex
		if(/^0b[01]+$/ || /^0[o][0-7]+$/ || /^0[x][0-9A-Fa-f]+$/) {
			next_token();
			return oct($tok->[$cur-1]);
		}

		# don't throw an error if it's just a close token
		if($_ eq ')' || $_ eq ']') {
			return undef;
		}

		bail("could not parse '$_'");
	};

	local *args = sub {
		my $arr = [];
		for(;;) {
			my $expr = expr();
			push @$arr, $expr if defined $expr;
			last unless defined($_) && $_ eq ',';
			need_next_token();
		}
		return $arr;
	};


	# the actual parse function body:
	my @val = eval {
		$_ = $tok->[$cur];
		assg() if defined $_;
		};
	die $@ if $@ =~ /^Interrupt/;
	print $@ if $@;
	return @val;
}


# Override command call.  If the original call failed,
# we try to parse the command line as an expression.

sub call_command
{
	my $self = shift;
	my $parms = shift;

	# leave default behavior alone
	if($parms->{cmd}) {
		return $self->SUPER::call_cmd($parms);
	}

	my ($id, $val) = $self->parse($parms->{tokens}, 0);
	if(defined $val) {
		$id ||= 'result';
		$self->{add_var}->($id, $val);
		print Data::Dumper->Dump([$val], [$id]);
	}

	return $val;
}

1;

