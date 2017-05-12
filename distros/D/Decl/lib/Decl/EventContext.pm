
package Decl::EventContext;

use warnings;
use strict;
use Decl::Semantics::Code;
use Text::ParseWords;
use Data::Dumper;

=head1 NAME

Decl::EventContext - base class implementing an event context in a declarative structure.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Each node in a C<Decl> structure that can respond to events can inherit from this class to get the proper machinery in place.

=head2 event_context_init()

Called during object creation to set up fields and such.

=cut

sub event_context_init {
   my $self = shift;
   
}



=head2 event_context()

Returns $self.

=cut

sub event_context { $_[0] }

=head2 register_event($event, $closure), do ($event)

Registers and fires closures by name.  This is the mechanism used by the 'on' tag in the core semantics.
This is actually a command-line interface; C<fire> runs the L<Text::ParseWords> C<parse_line> function on its
input, and gives the event closure any list elements that come after the first word.

=cut

sub register_event {
   my ($self, $event, $closure) = @_;
   
   $self->{e}->{$event} = $closure;
}
sub do {
   my ($self, $command) = @_;
   
   my @words = parse_line ('\s+', 0, $command);
   my $event = shift @words;
   
   my $e = $self->{e}->{$event};
   if ($e) {
      my $r = eval { &$e($self, @words) };
      print STDERR $@ if $@;   # TODO: centralized error handling.
      return $r;
   }
   if ($self->parent) {
      my $cx = $self->parent->event_context();
      return ($cx->do($command));
   }
}

=head2 make_event

Given the name of a C<Decl> event, finds the code referred to in its callable closure.

TODO: this is not covered by unit testing!

=cut

sub make_event {
   my ($self, $item) = @_;
   
   # Does the item have a body or children?  Then use Decl::Semantics::Code to build code for it.
   # Note: the flag $is_event registers the item as a named event, if it has a name.
   Decl::Semantics::Code::build_payload ($item, 1);
   return $item->{sub} if $item->{callable};

   # Does the item have an appropriately named 'on' handler?  Then build that and use it.
   # Search up the tree to inherit parents' 'on' handlers.
   for (my $cursor = $item; $cursor; $cursor = $cursor->parent()) {
      foreach ($cursor->nodes) {
         $_->build if $_->is('on');
         if ($_->is('on') and ($_->name eq $item->name) and $_->can('build') and my $handler = $_->build) {
            $self->register_event($item->name, $handler);
            return $handler;
         }
      }
   }
   
   # If all else fails, build a stub.
   my $closure = sub { print "event " . $item->name . "\n"; };
   $self->register_event($item->name, $closure);
   return $closure;
}


=head2 semantics()

Each event context can return a semantic handler.  For example, a form knows that its core semantics are "wx"; a Word document knows that
its core semantics are "ms-word", and so on.  The semantic handlers are a good place to put common functionality for a given semantic
domain, so they're useful in code snippets in a given context.

The default is to return the core semantics.

=cut

sub semantics {
   my $self = shift;
   $self->root()->semantic_handler('core');
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Decl::EventContext
