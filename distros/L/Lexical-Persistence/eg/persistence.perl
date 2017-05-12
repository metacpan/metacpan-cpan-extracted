#!/usr/bin/env perl

# An OO form of genlex.perl.  See Persistence.pm for the magic, or
# __END__ for sample output.

use warnings;
use strict;

use Lexical::Persistence;

# A handy target to show off persistence and not.

sub target {
	my $arg_number;   # Parameter.
	my $narf_x++;     # Persistent.
	my $_i++;         # Dynamic.
	my $j++;          # Persistent.

	print "  target arg_number($arg_number) narf_x($narf_x) _i($_i) j($j)\n";
}

### Create a context, and call something within it.

{
	print "The call() way:\n";

	my $persistence = Lexical::Persistence->new();

	foreach my $number (qw(one two three four five)) {
		$persistence->call(\&target, number => $number);
	}
}

### Create a context, and wrap a function call in it.  

{
	print "The wrap() way:\n";

	my $persistence = Lexical::Persistence->new();
	my $thunk = $persistence->wrap(\&target);

	foreach my $number (qw(one two three four five)) {
		$thunk->(number => $number);
	}
}

=for POE

### Subclass to handle some of POE's function call argument rules.

{
	package PoeLex;
	our @ISA = qw(Lexical::Persistence);

	# TODO - Make these lazy so the work isn't done every call?

	sub push_arg_context {
		my $self = shift;
		use POE::Session;
		my %param = map { $_ - ARG0, $_[$_] } (ARG0..$#_);

		my $old_arg_context = $self->get_context("arg");
		$self->set_context(arg => \%param);

		# Modify the catch-all context so it contains other arguments.

		my $catch_all = $self->get_context("_");
		@$catch_all{qw($kernel $heap $session $sender)} = @_[
			KERNEL, HEAP, SESSION, SENDER
		];

		return $old_arg_context;
	}
}

### Wrap a POE handler in PoeLex.

{
	print "Using POE:\n";

	use POE;
	spawn();
	POE::Kernel->run();

	sub spawn {
		my $persistence = PoeLex->new();

		my %heap;
		$persistence->set_context( heap => \%heap );

		POE::Session->create(
			heap => \%heap,
			inline_states => {
				_start => sub {
					$_[KERNEL]->yield(moo => 0);
				},
				moo => $persistence->wrap(\&handle_moo),
			},
		);
	}

	# Here's a sample handler with persistence.  $arg_0 has been aliased
	# to $_[ARG0].  $heap_foo has been aliased to $_[HEAP]{foo}.

	sub handle_moo {
		my $arg_0++;          # magic
		my $heap_foo++;       # more magic
		my ($kernel, $heap);  # also magic

		print "  moo: $arg_0 ... heap = $heap_foo ... heap b = $heap->{'$foo'}\n";
		$kernel->yield(moo => $arg_0) if $arg_0 < 10;
	}
}

=cut

exit;

__END__

The call() way:
  target arg_number(one) narf_x(1) _i(1) j(1)
  target arg_number(two) narf_x(2) _i(1) j(2)
  target arg_number(three) narf_x(3) _i(1) j(3)
  target arg_number(four) narf_x(4) _i(1) j(4)
  target arg_number(five) narf_x(5) _i(1) j(5)
The wrap() way:
  target arg_number(one) narf_x(1) _i(1) j(1)
  target arg_number(two) narf_x(2) _i(1) j(2)
  target arg_number(three) narf_x(3) _i(1) j(3)
  target arg_number(four) narf_x(4) _i(1) j(4)
  target arg_number(five) narf_x(5) _i(1) j(5)
Using POE:
  moo: 1 ... heap = 1 ... heap b = 1
  moo: 2 ... heap = 2 ... heap b = 2
  moo: 3 ... heap = 3 ... heap b = 3
  moo: 4 ... heap = 4 ... heap b = 4
  moo: 5 ... heap = 5 ... heap b = 5
  moo: 6 ... heap = 6 ... heap b = 6
  moo: 7 ... heap = 7 ... heap b = 7
  moo: 8 ... heap = 8 ... heap b = 8
  moo: 9 ... heap = 9 ... heap b = 9
  moo: 10 ... heap = 10 ... heap b = 10
