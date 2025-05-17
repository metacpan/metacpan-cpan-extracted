package Doubly;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.08';

require XSLoader;
XSLoader::load('Doubly', $VERSION);

1;

__END__

=head1 NAME

Doubly - Doubly linked lists

=head1 VERSION

Version 0.08

=cut

=head1 SYNOPSIS

	use Doubly;

	my $list = Doubly->new();

	$list->bulk_add(1..100000);

	$list->data; # 1;

	$list->length; # 100000;

	$list = $list->end;

	$list->data; # 100000;

	$list->prev->data; # 99999);

	$list->destroy(); # explicitly calling destroy is important

=head1 DESCRIPTION

This module provides access to a C-based doubly linked list for use in Perl. Unlike L<Doubly::Linked>, which constructs a Perl hash to simulate a linked list, this module implements a true C doubly linked list. As a result, when you inspect a L<Doubly> linked list variable, you'll only see a reference to the memory address (pointer) rather than the data stored at that location.

A doubly linked list is a type of linked list in which each node contains 3 parts, a data part and two addresses, one points to the previous node and one for the next node. It differs from the singly linked list as it has an extra pointer called previous that points to the previous node, allowing the traversal in both forward and backward directions.

=for html <img style="width:500px" src="https://raw.githubusercontent.com/ThisUsedToBeAnEmail/Doubly-Linked/master/doubly-linked.png" title="img-tag, local-dist" alt="Inlineimage" />

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new L<Doubly> Linked list. Optionally you can pass the value for the first item in the list else that will get set when you first call an insert* method.

	my $list = Doubly->new({ a => 1, b => 2, c => 3});

=head2 length

Returns the length of the linked list.

	my $length = $list->length;

=head2 data

Access the data for the current item in the list.

	$list->data;

=head2 start

Goto the start of the list.

	$list = $list->start;

=head2 is_start

returns true if the current item is the start of the list

	$list->is_start;

=head2 end

Goto the end of the list.

	$list = $list->end;

=head2 is_end

returns true if the current item is the end of the list

	$list->is_end;

=head2 next

Goto the next item in the list.

	$list = $list->next;

=head2 prev

Goto the previous item in the list.

	$list = $list->prev;

=head2 bulk_add

Bulk add items to the list, this internally calls insert_at_end and will keep the order you pass.

	$list->bulk_add(0..100000);

=head2 add

Alias for insert_at_end, it adds a new item to the end of the list.

	$list->add([qw/1 2 3/]);

=head2 insert

Insert a new item in the list based on the first match from the cb subroutine.

	$list->insert(sub { ref $_[0] eq 'HASH' }, { d => 4 });

=head2 insert_before

Insert a new item before the current item.

	$list->insert_before(100);

=head2 insert_after

Insert a new item after the current item.

	$list->insert_after(200);

=head2 insert_at_start

Insert a new item at the start of the list.

	$list->insert_at_start("start");

=head2 insert_at_end

Insert a new item at the end of the list.

	$list->insert_at_end("end");

=head2 insert_at_pos

Insert a new item by index from the start of the list.

	$list->insert_at_pos(2, "third");

=head2 remove

Remove the current item.

	$list->remove();

=head2 remove_from_start

Remove the first item from the list.

	$list->remove_from_start();

=head2 remove_from_end

Remove the last item from the list.

	$list->remove_from_end();

=head2 remove_from_pos

Remove an item by index from the list.

	$lst->remove_from_pos($index);

=head2 find

Itterate the list from the start until a match is found for the cb.

	$list = $list->find(sub { (ref $_[0] || "") eq 'HASH' && $_[0]->{a} == 1 ? 1 : 0 });


=head1 SUBROUTINES/METHODS

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-doubly at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Doubly>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Doubly


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Doubly>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Doubly>

=item * Search CPAN

L<https://metacpan.org/release/Doubly>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Doubly
