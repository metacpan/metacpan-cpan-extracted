package Eval::Reversible;

our $AUTHORITY = 'cpan:GSG';
our $VERSION   = '0.90';

use v5.10;
use Moo;

use Types::Standard qw( Bool Str ArrayRef CodeRef );
use MooX::HandlesVia;

use Scalar::Util qw( blessed );

use namespace::clean;  # don't export the above

# Goes after namespace::clean, since we actually want to include this into our
# namespace
use Exporter 'import';

BEGIN {
    our @EXPORT_OK = qw( to_undo reversibly );
};

our $Current_Reversible;

=head1 NAME

Eval::Reversible - Evals with undo stacks

=head1 SYNOPSIS

    use Eval::Reversible;

    my $reversible = Eval::Reversible->new(
        failure_warning => "Undoing actions..",
    );

    $reversible->run_reversibly(sub {
        # Do something with a side effect
        open my $fh, '>', '/tmp/file' or die;

        # Specify how that side effect can be undone
        # (assuming '/tmp/file' did not exist before)
        $reversible->add_undo(sub { close $fh; unlink '/tmp/file' });

        operation_that_might_die($fh);
        operation_that_might_get_SIGINTed($fh);

        close $fh;
        unlink '/tmp/file';

        $reversible->clear_undo;
        $reversible->failure_warning("Wasn't quite finished yet...");

        another_operation_that_might_die;
        $reversible->add_undo(sub { foobar; });

        $reversible->disarm;

        # This could die without an undo stack
        another_operation_that_might_die;

        $reversible->arm;

        # Previous undo stack back in play
    });

    # Alternative caller
    Eval::Reversible->run_reversibly(sub {
        my $reversible = $_[0];

        $reversible->add_undo(...);
        ...
    });

    # Alternative function interface
    reversibly {
        to_undo { ... };
        die;
    } 'Failed to run code; undoing...';

=head1 DESCRIPTION

Run code and automatically reverse their side effects if the code fails.  This is done by
way of an undo stack.  By calling L</add_undo> right after a side effect, the effect is
undone on the event that the L</run_reversibly> sub dies.  For example:

    $reversible->run_reversibly(sub {
        print "hello\n";
        $reversible->add_undo(sub { print "goodbye\n" });
        die "uh oh\n" if $something_bad;
    });

This prints "hello" if C<$something_bad> is false.  If it's true, then both "hello" and
"goodbye" are printed and the exception "uh oh" is rethrown.

Upon failure, any code refs provided by calling L</add_undo> are executed in reverse
order.  Conceptually, we're unwinding the stack of side effects that C<$code> performed
up to the point of failure.

=head1 ATTRIBUTES

=head2 failure_warning

This is the message that will warn as soon as the operation failed.  After this, the undo
stack is unwound, and the exception is rethrown.  Default is no message.

=cut

has failure_warning => (
    is       => 'rw',
    isa      => Str,
    required => 0,
);

=head2 undo_stack

The undo stack, managed in LIFO order, as an arrayref of coderefs.

This attribute has the following handles, which is what you should really interact with:

=head3 add_undo

Adds another coderef to the undo stack via push.

=head3 pop_undo

Removes the last coderef and returns it via pop.

=head3 clear_undo

Clears all undo coderefs from the stack.  Handy if the undo stack needs to be cleared out
early if a "point of no return" has been reached prior the end of the L</run_reversibly>
code block.  Alternatively, L</disarm> could be used, but it doesn't clear the existing
stack.

=head3 is_undo_empty

Returns a boolean that indicates whether the undo stack is empty or not.

=cut

has undo_stack => (
    is       => 'ro',
    isa      => ArrayRef[CodeRef],
    required => 1,
    default  => sub { [] },
    handles_via => 'Array',
    handles  => {
        add_undo      => 'push',
        pop_undo      => 'pop',
        clear_undo    => 'clear',
        is_undo_empty => 'is_empty',
    },
);

=head2 armed

Boolean that controls if L</run_reversibly> code blocks will actually run the undo stack
upon failure.  Turned on by default, but this can be enabled and disabled at will before
or inside the code block.

Has the following handles:

=head3 arm

Arms the undo stack.

=head3 disarm

Disarms the undo stack.

=cut

# XXX: MooX::HandlesVia can't really handle write operations on non-refs.  So, we're
# faking the handles here.

has armed => (
    is       => 'rw',
    isa      => Bool,
    required => 0,
    default  => 1,
);

sub arm    { shift->armed(1) }
sub disarm { shift->armed(0) }

=head1 METHODS

=head2 run_reversibly

    $reversible->run_reversibly($code);
    Eval::Reversible->run_reversibly($code);

Executes a code reference (C<$code>) allowing operations with side effects to be
automatically reversed if C<$code> fails or is interrupted.  Automatically clears the
undo stack before the start of the code block.

Can be called as a class method, which will auto-create a new object, and pass it along
as the first parameter to C<$code>.

If C<$code> is interrupted with SIGINT, the side effects are undone and an
exception "SIGINT\n" is thrown.

=cut

sub run_reversibly {
    my ($self, $code) = @_;
    die "Cannot call run_reversibly without a code block!" unless $code;

    unless (blessed $self) {
        my $class = $self;
        $self = $class->new;
    }

    $self->clear_undo;

    # If disarmed, just run the code without eval
    unless ($self->armed) {
        $self->$code();
        return;
    }

    local $SIG{INT}  = sub { die "SIGINT\n"  };
    local $SIG{TERM} = sub { die "SIGTERM\n" };

    eval { $self->$code() };
    if ( my $exception = $@ ) {
        # Re-check this because it may change inside the code block
        if ($self->armed) {
            warn $self->failure_warning if $self->failure_warning;
            $self->run_undo;

            # Re-throw the exception, with commentary
            die "\nThe exception that caused rollback was: $exception";
        }
        else {
            # Just die like it wasn't even in an eval
            die $exception;
        }
    }
}

=head2 run_undo

    $reversible->run_undo;

Runs the undo stack thus far.  Always runs the bottom of the stack first (LIFO order).  A
finished run will clear out the stack via pop.

Can be called outside of L</run_reversibly> if the eval was successful, but the undo
stack still needs to be ran.

=cut

sub run_undo {
    my ($self) = @_;

    while (my $undo = $self->pop_undo) {
        eval { $self->$undo() };
        warn "Exception during undo: $@" if $@;
    }
}

1;

=head1 EXPORTABLE FUNCTIONS

Eval::Reversible also supports an exportable function interface.  Though its usage is
somewhat legacy, the functions are prototyped for reduced sigilla.

None of the functions are exported by default.

=head2 reversibly

    reversibly {
        ...
    } 'Failure message';

Creates a new localized Eval::Reversible object and calls L</run_reversibly> on it.  An
optional failure message can be added to the end of coderef.

=cut

sub reversibly (&;$) {
    my ($code, $fail_msg) = @_;
    die "Cannot call reversibly without a code block!" unless $code;

    local $Current_Reversible = __PACKAGE__->new;
    $Current_Reversible->failure_warning($fail_msg) if defined $fail_msg;
    $Current_Reversible->run_reversibly($code);
}

=head2 to_undo

    # Only inside of a reversibly block
    to_undo { rollback_everything };

Adds to the existing undo stack.  Dies if called outside of a L</reversibly> block.

=cut

sub to_undo (&) {
    my ($code) = @_;
    die "Cannot call to_undo without a code block!"           unless $code;
    die "Cannot call to_undo outside of an reversibly block!" unless $Current_Reversible;

    $Current_Reversible->add_undo($code);
}

=head1 SEE ALSO

L<Scope::Guard>, L<Data::Transactional>, L<Object::Transaction>.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Grant Street Group

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
