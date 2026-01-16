package Doubly::Linked;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.13';

require XSLoader;
XSLoader::load('Doubly::Linked', $VERSION);

1;

__END__

=head1 NAME

Doubly::Linked - Doubly linked lists

=head1 VERSION

Version 0.13

=cut

=head1 SYNOPSIS

	use Doubly::Linked;

	my $list = Doubly::Linked->new();

	$list->insert_at_start(1);
	$list = $list->insert_at_end(2);
	$list->insert_after(3);

	$list = $list->start;
	$list = $list->next;
	$list = $list->prev;

	$list->data;
	$list->data($new_data);

	$list->remove;

	$list = $list->find(sub { return ... ? 1 : 0 });

	$list->destroy;

=head1 DESCRIPTION

A doubly linked list is a type of linked list in which each node contains 3 parts, a data part and two addresses, one points to the previous node and one for the next node. It differs from the singly linked list as it has an extra pointer called previous that points to the previous node, allowing the traversal in both forward and backward directions.

=for html <img style="width:500px" src="https://raw.githubusercontent.com/ThisUsedToBeAnEmail/Doubly-Linked/master/doubly-linked.png" title="img-tag, local-dist" alt="Inlineimage" />

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new L<Doubly::Linked> list. Optionally you can pass the value for the first item in the list else that will get set when you first call an insert* method.
	
	my $list = Doubly::Linked->new({ a => 1, b => 2, c => 3});

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

=head2 next

Goto the next item in the list.

	$list = $list->next;


=head2 prev

Goto the previous item in the list.

	$list = $list->prev;

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

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-doubly-linked at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Doubly-Linked>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Doubly::Linked


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Doubly-Linked>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Doubly-Linked>

=item * Search CPAN

L<https://metacpan.org/release/Doubly-Linked>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Doubly::Linked
