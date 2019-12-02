# Copyright (c) 2010-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

package Math::ModInt::Event::Trap;

use 5.006;
use strict;
use warnings;
use Carp qw(carp croak);

# ----- class data -----

BEGIN {
    our @CARP_NOT = qw(Math::ModInt::Event);
    our $VERSION  = '0.012';
}

# Math::ModInt::Event::Trap=ARRAY(...)

# ........... index ...........   # ............ value ............
use constant F_TRAP_ID    => 0;   # instance ID, used as a weak ref
use constant NFIELDS      => 1;

# ARRAY, element of @handlers:

# ........... index ...........   # ............ value ............
use constant H_TRAP_ID    => 0;   # instance ID of trap (0 if static)
use constant H_EVENT      => 1;   # event to trap
use constant H_HANDLER    => 2;   # the handler coderef

my $unique   = 0;
my @handlers = ();

my %generic_handlers = (
    'ignore' => sub { 0 },
    'warn' =>
        sub {
            my ($event, @details) = @_;
            carp join q[: ], 'warning', $event->description, @details;
            return 0;
        },
    'die' =>
        sub {
            my ($event, @details) = @_;
            croak join q[: ], 'error', $event->description, @details;
        },
);

# ----- private subroutines -----

sub _discard_handler {
    my ($trap_id) = @_;
    my $hx = @handlers;
    while ($hx) {
        if ($trap_id == $handlers[--$hx]->[H_TRAP_ID]) {
            splice @handlers, $hx, 1;
            return;
        }
    }
}

sub _add_handler {
    my ($trap_id, $event, $handler) = @_;
    push @handlers, [$trap_id, $event, $handler];
}

sub _final_trap {
    my ($event, @details) = @_;
    croak join q[: ], $event->description, @details;
}

# ----- public methods -----

sub new {
    my ($class, $event, $handler) = @_;
    my $is_static = !defined wantarray;
    my $trap_id   = $is_static? 0: ++$unique;
    if (!ref $handler) {
        if (!$handler || !exists $generic_handlers{$handler}) {
            $event->UsageError->raise(
                'bad argument: generic trap type or coderef expected'
            );
        }
        $handler = $generic_handlers{$handler};
    }
    _add_handler($trap_id, $event, $handler);
    return if $is_static;
    return bless [$trap_id], $class;
}

sub DESTROY {
    my ($this) = @_;
    _discard_handler($this->[F_TRAP_ID]);
}

sub broadcast {
    my ($class, $event, @details) = @_;
    my $called = 0;
    foreach my $handler (reverse @handlers) {
        if ($event->isa(ref $handler->[H_EVENT])) {
            ++$called;
            last if !$handler->[H_HANDLER]->($event, @details);
        }
    }
    if (!$event->is_recoverable) {
        _final_trap($event, @details);
    }
    return $called;
}

1;

__END__

=head1 NAME

Math::ModInt::Event::Trap - catching events triggered by Math::ModInt

=head1 VERSION

This documentation refers to version 0.012 of Math::ModInt::Event::Trap.

=head1 SYNOPSIS

  # event consumer interface:

  use Math::ModInt::Event::Trap;

  sub my_handler {
      my ($event) = @_;
      # ... insert code here ...
      return 0;            # call no handler after this one
      return 1;            # continue calling subsequent handlers
  }

  $trap = Math::ModInt::Event::Trap->new($event, \&my_handler);
  $trap = Math::ModInt::Event::Trap->new($event, 'ignore');
  $trap = Math::ModInt::Event::Trap->new($event, 'warn');
  $trap = Math::ModInt::Event::Trap->new($event, 'die');

  undef $trap;              # discard this trap

  Math::ModInt::Event::Trap->new($event, \&my_handler);
  Math::ModInt::Event::Trap->new($event, 'ignore');
  Math::ModInt::Event::Trap->new($event, 'warn');
  Math::ModInt::Event::Trap->new($event, 'die');

  # event producer interface:

  Math::ModInt::Event::Trap->broadcast($event);

=head1 DESCRIPTION

This module is closely related to Math::ModInt::Event and should
in general not be directly accessed from application code.  Please
refer to L<Math::ModInt::Event> for a more user-friendly description
of both module's functionalities.

=head2 Class Methods

=over 4

=item I<new>

Constructor, takes an event object, and a handler coderef or a
generic handler name.  Returns the new trap object.

=item I<broadcast>

Notifies active event handlers of an event.  Takes an event, returns
the number of handlers called.

=back

=head1 EXPORT

Math::ModInt::Event::Trap has no exports.

=head1 DIAGNOSTICS

Standard warning handlers print C<"warning: "> and the short
description of the event (like C<"undefined result">) on stderr,
followed by a caller source code location.

Standard error handlers die with C<"error: "> and the short description
of the event (like C<"undefined result">).

=head1 SEE ALSO

=over 4

=item *

L<Math::ModInt::Event>

=item *

L<Math::ModInt>

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp@cozap.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2019 Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see LICENSE file).
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
