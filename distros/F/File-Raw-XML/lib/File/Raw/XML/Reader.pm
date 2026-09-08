package File::Raw::XML::Reader;

use 5.010;
use strict;
use warnings;

use File::Raw::XML ();    # one dist, one bootstrap: the class lives in its bundle
1;

__END__

=head1 NAME

File::Raw::XML::Reader - one event at a time, at a flat cost

=head1 SYNOPSIS

    use File::Raw::XML qw(:const);
    use File::Raw::XML::Reader;

    my $r = File::Raw::XML::Reader->new(profile => 'full');
    $r->feed($bytes);            # any number of times
    $r->feed('', 1);             # eof
    while (my $kind = $r->next) {
        if ($kind == FRX_START && $r->local eq 'Record') {
            my $doc = $r->subtree;
            ...
        }
    }

    my $r = File::Raw::XML::Reader->from_file($path, profile => 'full');
    while (defined(my $kind = $r->next)) { ... }

=head1 DESCRIPTION

A pull reader over the same parser the codec uses. Bytes go in through
C<feed>, events come out through C<next>, and the memory a reader holds
is the memory of one record: what a token allocates is released when the
end event of the record it belonged to has been consumed. A stream of a
million records costs what one costs.

Every well-formedness constraint the codec enforces is enforced here, on
the same offsets: a refusal dies from C<next>, C<feed> or C<subtree> with
the message the codec would give, the offset counted from the start of
the stream.

A reader is not shareable across interpreter threads.

=head1 METHODS

=head2 new(%options)

The options of L<File::Raw::XML/OPTIONS>, with two differences: C<id_attrs>
is accepted and ignored, because a reader builds no index, and
C<max_token_bytes> bounds the largest single token (a text run, a tag, a
comment, a DOCTYPE with its subset) the reader will hold while waiting
for its end. A token the input ends inside is retried whole when more
bytes arrive, so that bound is what keeps the retry linear; the default
is 16 MiB, and a text node larger than it cannot be streamed.

=head2 from_file($path, %options)

A reader that pulls from the file as C<next> needs bytes, in chunks of
64 KiB. The file is opened at once and read as the events are asked for.

=head2 feed($bytes, $eof)

Bytes from the stream, in any sizes; a true C<$eof> says these are the
last, and an empty string with C<$eof> ends a stream whose last bytes
were already fed. Under C<< profile => 'full' >> the first four bytes
choose the encoding as they do for the codec, and every later feed is
transcoded as it arrives; a feed may end inside a character.

=head2 next

The next event's kind: C<FRX_START>, C<FRX_END>, C<FRX_TEXT>,
C<FRX_COMMENT>, C<FRX_PI> or C<FRX_DOCTYPE>, constants from
L<File::Raw::XML>'s C<:const>. Returns 0 when the reader needs more bytes
and C<undef> when the document has ended, so a loop over a socket feeds on
0 and stops on C<undef>; a reader from C<from_file> reads its own bytes
and returns 0 only when the file is exhausted before the document is.

=head2 kind

The current event's kind, C<undef> before the first event.

=head2 name, local, ns, prefix

Of the current start or end event's element: the name as written, its
local part, its namespace name (empty when none) and its prefix (empty
when none). For a processing instruction C<name> and C<local> are the
target.

=head2 attrs, attr($local), attr_ns($ns, $local)

The current start event's attributes, as L<File::Raw::XML::Node> reports
them: C<attrs> is an arrayref of C<[ns, prefix, local, value]>, C<attr>
finds one by local name in any namespace, C<attr_ns> by namespace name
and local name, C<undef> for the namespace meaning any and the empty
string meaning none. Namespace declarations are never attributes.
Defaulted attributes from a DOCTYPE are present, as in the tree.

=head2 value

A text event's characters, a comment's body, a processing instruction's
data. Adjacent character data and CDATA sections are one text event, as
in the tree, except that text from an entity is its own event.

=head2 target

A processing instruction's target; C<undef> for any other event.

=head2 entity

For a text event, the name of the entity the text came from, C<undef>
when it came from the document itself. This is the boundary the tree
does not keep.

=head2 depth

The number of elements open at the current event, counting a start event's
own element: the root's start and end events are at depth 1, a child's at
depth 2. Text, comments and processing instructions report the depth of
the element they are in, 0 outside the root.

=head2 offset

The byte offset the current event began at, counted from the start of
the stream.

=head2 empty

True at a start event whose element was written C<< <a/> >>: no end event
follows it.

=head2 doctype

What L<File::Raw::XML::Document/doctype> returns, once the DOCTYPE has
been read; C<undef> before it and for a document without one.

=head2 subtree

At a start event, the element and everything under it as a
L<File::Raw::XML::Document> of its own, independent of the reader: the
namespace bindings in scope at the element are carried into it, so the
document canonicalises as the element would in place. The document
carries no ID index.

A reader fed by hand returns C<undef> when the fed bytes ended inside the
element; feed more and call C<subtree> again, not C<next>, until it
returns the document. A reader from C<from_file> reads its own bytes here
as it does in C<next>, so it never answers C<undef> for want of them.

=head2 capturing

True between a C<subtree> that returned C<undef> and the one that returns
the document.

=head2 done

True once C<next> has returned C<undef>.

=head1 SEE ALSO

L<File::Raw::XML>, L<File::Raw::XML::Document>, L<File::Raw::XML::Node>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
