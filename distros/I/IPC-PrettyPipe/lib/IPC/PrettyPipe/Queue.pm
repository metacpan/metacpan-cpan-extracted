package IPC::PrettyPipe::Queue;

# ABSTRACT: A simple queue

use Moo;

our $VERSION = '0.12';

use namespace::clean;


has elements => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { [] },
);

sub empty { !!!@{ $_[0]->elements } }

sub nelements { scalar @{ $_[0]->elements } }

sub push {

    my ( $self, $elem ) = ( shift, shift );

    die( "incompatible element\n" )
      unless $elem->does( 'IPC::PrettyPipe::Queue::Element' );

    my $elements = $self->elements;

    if ( @$elements ) {
        ## no critic (ProhibitAccessOfPrivateData)
        $elements->[-1]->_set_last( 0 );
        $elem->_set_last( 1 );
        $elem->_set_first( 0 );
    }
    else {

        $elem->_set_last( 1 );
        $elem->_set_first( 1 );

    }

    push @{$elements}, $elem;

    return;
}

1;

#
# This file is part of IPC-PrettyPipe
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory nelements

=head1 NAME

IPC::PrettyPipe::Queue - A simple queue

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  $q = IPC::PrettyPipe::Queue->new;

  $q->push( $elem );

  $elements = $q->elements;
  $is_q_empty = $q->empty;

=head1 DESCRIPTION

This module provides a simple queue for objects which perform the
B<L<IPC::PrettyPipe::Queue::Element>> role.  No object should be in more than
one queue at a time.

=head1 METHODS

The following methods are available:

=over

=item new

  $q = IPC::PrettyPipe::Queue->new;

Construct an empty queue.

=item push

  $q->push( $element );

Push the element on the end of the queue.  The element must perform
the B<L<IPC::PrettyPipe::Queue::Element>> role.

=item empty

  $is_q_empty = $q->empty;

Returns true if there are no elements in the queue.

=item elements

  $elements = $q->elements;

Returns an arrayref containing the queue's elements.

=item nelements

  $nelements = $q->nelements;

Returns the number of elements in the queue.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2014 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

   http://www.fsf.org/copyleft/gpl.html

=head1 AUTHOR

Diab Jerius E<lt>djerius@cfa.harvard.eduE<gt>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=IPC-PrettyPipe> or by
email to
L<bug-IPC-PrettyPipe@rt.cpan.org|mailto:bug-IPC-PrettyPipe@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/ipc-prettypipe>
and may be cloned from L<git://github.com/djerius/ipc-prettypipe.git>

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<IPC::PrettyPipe|IPC::PrettyPipe>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
