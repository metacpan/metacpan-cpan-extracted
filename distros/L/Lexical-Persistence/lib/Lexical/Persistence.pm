=head1 NAME

Lexical::Persistence - Persistent lexical variable values for arbitrary calls.

=head1 VERSION

version 1.023

=head1 SYNOPSIS

	#!/usr/bin/perl

	use Lexical::Persistence;

	my $persistence = Lexical::Persistence->new();
	foreach my $number (qw(one two three four five)) {
		$persistence->call(\&target, number => $number);
	}

	exit;

	sub target {
		my $arg_number;   # Argument.
		my $narf_x++;     # Persistent.
		my $_i++;         # Dynamic.
		my $j++;          # Persistent.

		print "arg_number = $arg_number\n";
		print "\tnarf_x = $narf_x\n";
		print "\t_i = $_i\n";
		print "\tj = $j\n";
	}

=head1 DESCRIPTION

Lexical::Persistence does a few things, all related.  Note that all
the behaviors listed here are the defaults.  Subclasses can override
nearly every aspect of Lexical::Persistence's behavior.

Lexical::Persistence lets your code access persistent data through
lexical variables.  This example prints "some value" because the value
of $x persists in the $lp object between setter() and getter().

	use Lexical::Persistence;

	my $lp = Lexical::Persistence->new();
	$lp->call(\&setter);
	$lp->call(\&getter);

	sub setter { my $x = "some value" }
	sub getter { print my $x, "\n" }

Lexicals with leading underscores are not persistent.

By default, Lexical::Persistence supports accessing data from multiple
sources through the use of variable prefixes.  The set_context()
member sets each data source.  It takes a prefix name and a hash of
key/value pairs.  By default, the keys must have sigils representing
their variable types.

	use Lexical::Persistence;

	my $lp = Lexical::Persistence->new();
	$lp->set_context( pi => { '$member' => 3.141 } );
	$lp->set_context( e => { '@member' => [ 2, '.', 7, 1, 8 ] } );
	$lp->set_context(
		animal => {
			'%member' => { cat => "meow", dog => "woof" }
		}
	);

	$lp->call(\&display);

	sub display {
		my ($pi_member, @e_member, %animal_member);

		print "pi = $pi_member\n";
		print "e = @e_member\n";
		while (my ($animal, $sound) = each %animal_member) {
			print "The $animal goes... $sound!\n";
		}
	}

And the corresponding output:

	pi = 3.141
	e = 2 . 7 1 8
	The cat goes... meow!
	The dog goes... woof!

By default, call() takes a single subroutine reference and an optional
list of named arguments.  The arguments will be passed directly to the
called subroutine, but Lexical::Persistence also makes the values
available from the "arg" prefix.

	use Lexical::Persistence;

	my %animals = (
		snake => "hiss",
		plane => "I'm Cartesian",
	);

	my $lp = Lexical::Persistence->new();
	while (my ($animal, $sound) = each %animals) {
		$lp->call(\&display, animal => $animal, sound => $sound);
	}

	sub display {
		my ($arg_animal, $arg_sound);
		print "The $arg_animal goes... $arg_sound!\n";
	}

And the corresponding output:

	The plane goes... I'm Cartesian!
	The snake goes... hiss!

Sometimes you want to call functions normally.  The wrap() method will
wrap your function in a small thunk that does the call() for you,
returning a coderef.

	use Lexical::Persistence;

	my $lp = Lexical::Persistence->new();
	my $thunk = $lp->wrap(\&display);

	$thunk->(animal => "squirrel", sound => "nuts");

	sub display {
		my ($arg_animal, $arg_sound);
		print "The $arg_animal goes... $arg_sound!\n";
	}

And the corresponding output:

	The squirrel goes... nuts!

Prefixes are the characters leading up to the first underscore in a
lexical variable's name.  However, there's also a default context
named underscore.  It's literally "_" because the underscore is not
legal in a context name by default.  Variables without prefixes, or
with prefixes that have not been previously defined by set_context(),
are stored in that context.

The get_context() member returns a hash for a named context.  This
allows your code to manipulate the values within a persistent context.

	use Lexical::Persistence;

	my $lp = Lexical::Persistence->new();
	$lp->set_context(
		_ => {
			'@mind' => [qw(My mind is going. I can feel it.)]
		}
	);

	while (1) {
		$lp->call(\&display);
		my $mind = $lp->get_context("_")->{'@mind'};
		splice @$mind, rand(@$mind), 1;
		last unless @$mind;
	}

	sub display {
		my @mind;
		print "@mind\n";
	}

Displays something like:

	My mind is going. I can feel it.
	My is going. I can feel it.
	My is going. I feel it.
	My going. I feel it.
	My going. I feel
	My I feel
	My I
	My

It's possible to create multiple Lexical::Persistence objects, each
with a unique state.

	use Lexical::Persistence;

	my $lp_1 = Lexical::Persistence->new();
	$lp_1->set_context( _ => { '$foo' => "context 1's foo" } );

	my $lp_2 = Lexical::Persistence->new();
	$lp_2->set_context( _ => { '$foo' => "the foo in context 2" } );

	$lp_1->call(\&display);
	$lp_2->call(\&display);

	sub display {
		print my $foo, "\n";
	}

Gets you this output:

	context 1's foo
	the foo in context 2

You can also compile and execute perl code contained in plain strings in a
a lexical environment that already contains the persisted variables.

	use Lexical::Persistence;

	my $lp = Lexical::Persistence->new();

	$lp->do( 'my $message = "Hello, world" );

	$lp->do( 'print "$message\n"' );

Which gives the output:

	Hello, world

If you come up with other fun uses, let us know.

=cut

package Lexical::Persistence;

use warnings;
use strict;

our $VERSION = '1.020';

use Devel::LexAlias qw(lexalias);
use PadWalker qw(peek_sub);

=head2 new

Create a new lexical persistence object.  This object will store one
or more persistent contexts.  When called by this object, lexical
variables will take on the values kept in this object.

=cut

sub new {
	my $class = shift;

	my $self = bless {
		context => { },
	}, $class;

	$self->initialize_contexts();

	return $self;
}

=head2 initialize_contexts

This method is called by new() to declare the initial contexts for a
new Lexical::Persistence object.  The default implementation declares
the default "_" context.

Override or extend it to create others as needed.

=cut

sub initialize_contexts {
	my $self = shift;
	$self->set_context( _ => { } );
}

=head2 set_context NAME, HASH

Store a context HASH within the persistence object, keyed on a NAME.
Members of the context HASH are unprefixed versions of the lexicals
they'll persist, including the sigil.  For example, this set_context()
call declares a "request" context with predefined values for three
variables: $request_foo, @request_foo, and %request_foo:

	$lp->set_context(
		request => {
			'$foo' => 'value of $request_foo',
			'@foo' => [qw( value of @request_foo )],
			'%foo' => { key => 'value of $request_foo{key}' }
		}
	);

See parse_variable() for information about how Lexical::Persistence
decides which context a lexical belongs to and how you can change
that.

=cut

sub set_context {
	my ($self, $context_name, $context_hash) = @_;
	$self->{context}{$context_name} = $context_hash;
}

=head2 get_context NAME

Returns a context hash associated with a particular context name.
Autovivifies the context if it doesn't already exist, so be careful
there.

=cut

sub get_context {
	my ($self, $context_name) = @_;
	$self->{context}{$context_name} ||= { };
}

=head2 call CODEREF, ARGUMENT_LIST

Call CODEREF with lexical persistence and an optional ARGUMENT_LIST,
consisting of name => value pairs.  Unlike with set_context(),
however, argument names do not need sigils.  This may change in the
future, however, as it's easy to access an argument with the wrong
variable type.

The ARGUMENT_LIST is passed to the called CODEREF through @_ in the
usual way.  They're also available as $arg_name variables for
convenience.

See push_arg_context() for information about how $arg_name works, and
what you can do to change that behavior.

=cut

sub call {
	my ($self, $sub, @args) = @_;

	my $old_arg_context = $self->push_arg_context(@args);

	my $pad = peek_sub($sub);
	while (my ($var, $ref) = each %$pad) {
		next unless my ($sigil, $context, $member) = $self->parse_variable($var);
		lexalias(
			$sub, $var, $self->get_member_ref($sigil, $context, $member)
		);
	}

	unless (defined wantarray) {
		$sub->(@args);
		$self->pop_arg_context($old_arg_context);
		return;
	}

	if (wantarray) {
		my @return = $sub->(@args);
		$self->pop_arg_context($old_arg_context);
		return @return;
	}

	my $return = $sub->(@args);
	$self->pop_arg_context($old_arg_context);
	return $return;
}

=head2 invoke OBJECT, METHOD, ARGUMENT_LIST

Invoke OBJECT->METHOD(ARGUMENT_LIST) while maintaining state for the
METHOD's lexical variables.  Written in terms of call(), except that
it takes OBJECT and METHOD rather than CODEREF.  See call() for more
details.

May have issues with methods invoked via AUTOLOAD, as invoke() uses
can() to find the method's CODEREF for call().

=cut

sub invoke {
	my ($self, $object, $method, @args) = @_;
	return unless defined( my $sub = $object->can($method) );
	$self->call($sub, @args);
}

=head2 wrap CODEREF

Wrap a function or anonymous CODEREF so that it's transparently called
via call().  Returns a coderef which can be called directly.  Named
arguments to the call will automatically become available as $arg_name
lexicals within the called CODEREF.

See call() and push_arg_context() for more details.

=cut

sub wrap {
	my ($self, $invocant, $method) = @_;

	if (ref($invocant) eq 'CODE') {
		return sub {
			$self->call($invocant, @_);
		};
	}

	# FIXME - Experimental method wrapper.
	# TODO - Make it resolve the method at call time.
	# TODO - Possibly make it generate dynamic facade classes.

	return sub {
		$self->invoke($invocant, $method, @_);
	};
}

=head2 prepare CODE

Wrap a CODE string in a subroutine definition, and prepend
declarations for all the variables stored in the Lexical::Persistence
default context.  This avoids having to declare variables explicitly
in the code using 'my'.  Returns a new code string ready for Perl's
built-in eval().  From there, a program may $lp->call() the code or
$lp->wrap() it.

Also see L</compile()>, which is a convenient wrapper for prepare()
and Perl's built-in eval().

Also see L</do()>, which is a convenient way to prepare(), eval() and
call() in one step.

=cut

sub prepare {
	my ($self, $code) = @_;

	# Don't worry about values because $self->call() will deal with them
	my $vars = join(
		" ", map { "my $_;" }
		keys %{ $self->get_context('_') }
	);

	# Declare the variables OUTSIDE the actual sub. The compiler will
	# pull any into the sub that are actually used. Any that aren't will
	# just get dropped at this point
	return "$vars sub { $code }";
}

=head2 compile CODE

compile() is a convenience method to prepare() a CODE string, eval()
it, and then return the resulting coderef.  If it fails, it returns
false, and $@ will explain why.

=cut

sub compile {
	my ($self, $code) = @_;
	return eval($self->prepare($code));
}

=head2 do CODE

do() is a convenience method to compile() a CODE string and execute
it.  It returns the result of CODE's execution, or it throws an
exception on failure.

This example prints the numbers 1 through 10.  Note, however, that
do() compiles the same code each time.

	use Lexical::Persistence;

	my $lp = Lexical::Persistence->new();
	$lp->do('my $count = 0');
	$lp->do('print ++$count, "\\n"') for 1..10;

Lexical declarations are preserved across do() invocations, such as
with $count in the surrounding examples.  This behavior is part of
prepare(), which do() uses via compile().

The previous example may be rewritten in terms of compile() and call()
to avoid recompiling code every iteration.  Lexical declarations are
preserved between do() and compile() as well:

	use Lexical::Persistence;

	my $lp = Lexical::Persistence->new();
	$lp->do('my $count = 0');
	my $coderef = $lp->compile('print ++$count, "\\n"');
	$lp->call($coderef) for 1..10;

do() inherits some limitations from PadWalker's peek_sub().  For
instance, it cannot alias lexicals within sub() definitions in the
supplied CODE string.  However, Lexical::Persistence can do this with
careful use of eval() and some custom CODE preparation.

=cut

sub do {
	my ($self, $code) = @_;

	my $sub = $self->compile( $code ) or die $@;
	$self->call( $sub );
}

=head2 parse_variable VARIABLE_NAME

This method determines whether VARIABLE_NAME should be persistent.  If
it should, parse_variable() will return three values: the variable's
sigil ('$', '@' or '%'), the context name in which the variable
persists (see set_context()), and the name of the member within that
context where the value is stored.  parse_variable() returns nothing
if VARIABLE_NAME should not be persistent.

parse_variable() also determines whether the member name includes its
sigil.  By default, the "arg" context is the only one with members
that have no sigils.  This is done to support the unadorned argument
names used by call().

This method implements a default behavior.  It's intended to be
overridden or extended by subclasses.

=cut

sub parse_variable {
	my ($self, $var) = @_;

	return unless (
		my ($sigil, $context, $member) = (
			$var =~ /^([\$\@\%])(?!_)(?:([^_]*)_)?(\S+)/
		)
	);

	if (defined $context) {
		if (exists $self->{context}{$context}) {
			return $sigil, $context, $member if $context eq "arg";
			return $sigil, $context, "$sigil$member";
		}
		return $sigil, "_", "$sigil$context\_$member";
	}

	return $sigil, "_", "$sigil$member";
}

=head2 get_member_ref SIGIL, CONTEXT, MEMBER

This method fetches a reference to the named MEMBER of a particular
named CONTEXT.  The returned value type will be governed by the given
SIGIL.

Scalar values are stored internally as scalars to be consistent with
how most people store scalars.

The persistent value is created if it doesn't exist.  The initial
value is undef or empty, depending on its type.

This method implements a default behavior.  It's intended to be
overridden or extended by subclasses.

=cut

sub get_member_ref {
	my ($self, $sigil, $context, $member) = @_;

	my $hash = $self->{context}{$context};

	if ($sigil eq '$') {
		$hash->{$member} = undef unless exists $hash->{$member};
		return \$hash->{$member};
	}

	if ($sigil eq '@') {
		$hash->{$member} = [ ] unless exists $hash->{$member};
	}
	elsif ($sigil eq '%') {
		$hash->{$member} = { } unless exists $hash->{$member};
	}

	return $hash->{$member};
}

=head2 push_arg_context ARGUMENT_LIST

Convert a named ARGUMENT_LIST into members of an argument context, and
call set_context() to declare that context.  This is how $arg_foo
variables are supported.  This method returns the previous context,
fetched by get_context() before the new context is set.

This method implements a default behavior.  It's intended to be
overridden or extended by subclasses.  For example, to redefine the
parameters as $param_foo.

See pop_arg_context() for the other side of this coin.

=cut

sub push_arg_context {
	my $self = shift;
	my $old_arg_context = $self->get_context("arg");
	$self->set_context( arg => { @_ } );
	return $old_arg_context;
}

=head2 pop_arg_context OLD_ARG_CONTEXT

Restores OLD_ARG_CONTEXT after a target function has returned.  The
OLD_ARG_CONTEXT is the return value from the push_arg_context() call
just prior to the target function's call.

This method implements a default behavior.  It's intended to be
overridden or extended by subclasses.

=cut

sub pop_arg_context {
	my ($self, $old_context) = @_;
	$self->set_context( arg => $old_context );
}

=head1 SEE ALSO

L<POE::Stage>, L<Devel::LexAlias>, L<PadWalker>,
L<Catalyst::Controller::BindLex>.

=head2 BUG TRACKER

https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=Lexical-Persistence

=head2 REPOSITORY

http://github.com/rcaputo/lexical-persistence
http://gitorious.org/lexical-persistence

=head2 OTHER RESOURCES

http://search.cpan.org/dist/Lexical-Persistence/

=head1 COPYRIGHT

Lexical::Persistence in copyright 2006-2013 by Rocco Caputo.  All
rights reserved.  Lexical::Persistence is free software.  It is
released under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Thanks to Matt Trout and Yuval Kogman for lots of inspiration.  They
were the demon and the other demon sitting on my shoulders.

Nick Perez convinced me to make this a class rather than persist with
the original, functional design.  While Higher Order Perl is fun for
development, I have to say the move to OO was a good one.

Paul "LeoNerd" Evans contributed the compile() and eval() methods.

The South Florida Perl Mongers, especially Jeff Bisbee and Marlon
Bailey, for documentation feedback.

irc://irc.perl.org/poe for support and feedback.

=cut

1;
