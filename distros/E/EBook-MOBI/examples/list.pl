#!/usr/bin/perl

use EBook::MOBI;

my $pod = <<END;

=head1 Content as Command

=over

=item * First item.

=item * Second item.

=item * Third item.

=back

=head1 Content as Textblock

=over

=item

First item.

=item

Second item.

=item

Third item.

=back

=head1 Content as Textblock with *

=over

=item *

First item.

=item *

Second item.

=item *

Third item.

=back

=head1 Content mixed as Command and Textblock

=over

=item * First item.

=item * Second item.

With additional Text.

=item * Third item.

With additional Text.
With additional Text.

=back

=head1 Nested List

=over

=item * First item.

=over

=item 1 First item.

=item 2 Second item.

=item 3 Third item.

=back

=item * Second item.

=item * Third item.

=back

=head1 No Items (Blockquote)

=over

First item.

Second item.

Third item.

=back

=head1 Nested Blockquote

=over

First item.

Second item.

=over

First.

Second.

Third.

=back

Third item.

=back

=head1 Nested List of Depth 5 !!!

=over

=item * First item.

=item * First item.

=item * First item.

=over

=item 1 One.

=item 2 Two.

=over

=item * A

=over

=item * First item.

=item * First item.

=item * First item.

=over

=item 1 One.

=item 2 Two.

=over

=item * A

=item * B

=item * C

=back

=item 3 Three.

=back

=item * Second item.

=item * Third item.

=back

=item * B

=item * C

=back

=item 3 Three.

=back

=item * Second item.

=item * Third item.

=back

=head1 Nested List with Blockquote

=over

=item 1 One.

=item 2 Two.

=over

A

B

C

=back

=item 3 Three.

=back

=head1 Nested Blockquote with List

=over

One.

Two.

=over

=item * A

=item * B

=item * C

=back

Three.

=back

=cut

END

my $book = EBook::MOBI->new();

# let's define a debug sub witch will be used by all modules
sub debug {
    my ($package, $filename, $line) = caller;
    print "$package\t$_[0]\n";
}

# pass the reference of the sub to our book
#$book->debug_on(\&debug);

# fill the book with meta info
$book->set_filename('List.mobi');
$book->set_title   ('A Test: List');
$book->set_author  ('Boris');
$book->set_encoding(':encoding(UTF-8)');

# fill the book with content
$book->add_content(data => $pod);

$book->make();
$book->print_mhtml();
$book->save();

